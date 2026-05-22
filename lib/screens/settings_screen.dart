import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pylek/components/app_icons.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _sendFeedback() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'jakubgorzny@icloud.com',
      query: Uri.encodeFull(
        'subject=Opinia o Pyłku &body=Wpisz tutaj swoją opinię...',
      ),
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Feedback",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onBackground,
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _sendFeedback,
              icon: Icon(AppIcons.of(context, AppIconKind.mail)),
              label: const Text("Wyślij feedback"),
            ),
          ],
        ),
      ),
    );
  }
}