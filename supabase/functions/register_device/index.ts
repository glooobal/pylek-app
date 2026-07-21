import { serve } from "https://deno.land/std/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

interface DeviceBody {
  token: string;
  forecast_reminder_enabled: boolean;
}

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  let body: DeviceBody;
  try {
    body = await req.json();
  } catch {
    return new Response(
      JSON.stringify({ error: "Invalid JSON body" }),
      { status: 400, headers: { "Content-Type": "application/json" } },
    );
  }

  if (typeof body.token !== "string" || body.token.length === 0) {
    return new Response(
      JSON.stringify({ error: "Missing or invalid 'token'" }),
      { status: 400, headers: { "Content-Type": "application/json" } },
    );
  }

  if (typeof body.forecast_reminder_enabled !== "boolean") {
    body.forecast_reminder_enabled = true;
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { error } = await supabase.from("device_tokens").upsert(
    {
      token: body.token,
      forecast_reminder_enabled: body.forecast_reminder_enabled,
    },
    { onConflict: "token" },
  );

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  return new Response(JSON.stringify({ ok: true }), {
    headers: { "Content-Type": "application/json" },
  });
});
