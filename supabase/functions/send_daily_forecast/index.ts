import { serve } from "https://deno.land/std/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

function base64UrlEncode(data: ArrayBuffer): string {
  return btoa(String.fromCharCode(...new Uint8Array(data)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

function pemToBinary(pem: string): ArrayBuffer {
  const b64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\s+/g, "");
  const raw = atob(b64);
  const buf = new Uint8Array(raw.length);
  for (let i = 0; i < raw.length; i++) buf[i] = raw.charCodeAt(i);
  return buf.buffer;
}

async function getAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const payload = {
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now,
  };

  const enc = new TextEncoder();
  const headerB64 = base64UrlEncode(enc.encode(JSON.stringify(header)));
  const payloadB64 = base64UrlEncode(enc.encode(JSON.stringify(payload)));
  const signingInput = `${headerB64}.${payloadB64}`;

  let key: CryptoKey;
  try {
    key = await crypto.subtle.importKey(
      "pkcs8",
      pemToBinary(sa.private_key),
      { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
      false,
      ["sign"],
    );
  } catch (e) {
    throw new Error(`Failed to import FCM private key: ${e}`);
  }

  const signature = await crypto.subtle.sign(
    { name: "RSASSA-PKCS1-v1_5" },
    key,
    enc.encode(signingInput),
  );

  const jwt = `${signingInput}.${base64UrlEncode(signature)}`;

  let resp: Response;
  try {
    resp = await fetch("https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion: jwt,
      }),
    });
  } catch (e) {
    throw new Error(`OAuth2 token request failed: ${e}`);
  }

  if (!resp.ok) {
    const body = await resp.text();
    throw new Error(`OAuth2 token response ${resp.status}: ${body}`);
  }

  const data = await resp.json();
  if (!data.access_token) {
    throw new Error("OAuth2 response missing access_token");
  }

  return data.access_token as string;
}

serve(async (_req) => {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: devices, error } = await supabase
    .from("device_tokens")
    .select("token")
    .eq("forecast_reminder_enabled", true);

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  if (!devices || devices.length === 0) {
    return new Response(JSON.stringify({ sent: 0 }), {
      headers: { "Content-Type": "application/json" },
    });
  }

  const saRaw = Deno.env.get("FCM_SERVICE_ACCOUNT");
  if (!saRaw) {
    return new Response(
      JSON.stringify({ error: "FCM_SERVICE_ACCOUNT secret not set" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  let sa: ServiceAccount;
  try {
    sa = JSON.parse(saRaw);
  } catch (e) {
    return new Response(
      JSON.stringify({ error: "FCM_SERVICE_ACCOUNT contains invalid JSON" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  let accessToken: string;
  try {
    accessToken = await getAccessToken(sa);
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    console.error("Failed to get access token:", msg);
    return new Response(
      JSON.stringify({ error: msg }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  const fcmUrl =
    `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`;

  const results = await Promise.allSettled(
    devices.map((d) => sendFcmMessage(fcmUrl, accessToken, d.token)),
  );

  const sent = results.filter(
    (r) => r.status === "fulfilled" && r.value,
  ).length;
  const failed = results.filter(
    (r) => r.status === "rejected" || (r.status === "fulfilled" && !r.value),
  ).length;

  return new Response(JSON.stringify({ sent, failed, total: devices.length }), {
    headers: { "Content-Type": "application/json" },
  });
});

async function sendFcmMessage(
  url: string,
  accessToken: string,
  deviceToken: string,
): Promise<boolean> {
  let resp: Response;
  try {
    resp = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify({
        message: {
          token: deviceToken,
          notification: {
            title: "Prognoza pylenia",
            body: "Sprawdź dzisiejszą prognozę pylenia w Twojej okolicy",
          },
          data: {
            type: "forecast_reminder",
          },
        },
      }),
    });
  } catch (e) {
    console.error(`FCM fetch failed for ${deviceToken}:`, e);
    return false;
  }

  if (!resp.ok) {
    const body = await resp.text();
    console.error(`FCM error ${resp.status} for ${deviceToken}: ${body}`);

    // Remove invalid tokens (404 = Unregistered, 400 = InvalidArgument)
    if (resp.status === 404 || resp.status === 400) {
      try {
        const supabase = createClient(
          Deno.env.get("SUPABASE_URL")!,
          Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
        );
        await supabase.from("device_tokens").delete().eq("token", deviceToken);
        console.log(`Removed invalid token: ${deviceToken}`);
      } catch (_) {
        // Non-fatal
      }
    }

    return false;
  }

  return true;
}
