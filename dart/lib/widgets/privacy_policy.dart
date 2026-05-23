import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      appBar: AppBar(
        title: const Text('LEGAL DISCLOSURE',
            style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('1. Privacy Policy',
                'Your privacy is important to us. Retro Fun Crate is a standalone game collection. We do not collect, store, or share any personal data, location information, or device identifiers. All game progress is stored locally on your device.'),
            _buildSection('2. Terms of Service',
                'By using Retro Fun Crate, you agree to use the application for personal, non-commercial entertainment only. All game assets and code are provided "as-is" without warranty of any kind.'),
            _buildSection('3. Data Collection',
                'We do not include tracking or analytics SDKs. No personal information is harvested or transmitted to external servers.'),
            _buildSection('4. Permissions',
                'The app requires minimal permissions to run games locally. No internet access or storage permissions are used for data harvesting.'),
            _buildSection('5. Children\'s Privacy',
                'Our games are suitable for all ages. We do not knowingly collect information from children.'),
            _buildSection('6. Contact Us',
                'For questions regarding these policies, please contact us at wuser8849@gmail.com'),
            const SizedBox(height: 40),
            Center(
              child: Text(
                'Last Updated: April 2026',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
                color: Colors.cyanAccent,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
                color: Colors.white70, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}
