import 'package:flutter/material.dart';
import 'package:chatrizz/app/theme/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section(
              'Privacy Policy',
              'Effective Date: July 11, 2025',
            ),
            _section(
              '1. Introduction',
              'Welcome to ChatRizz ("we", "our", "us"). We respect your privacy and are committed to protecting your personal data. This Privacy Policy explains how we collect, use, and safeguard your information when you use our mobile application.',
            ),
            _section(
              '2. Information We Collect',
              'We may collect the following types of information:\n'
              '• Account Information: When you create an account, we collect your name, email address, and authentication credentials.\n'
              '• Usage Data: We collect information about how you use the app, including matches, messages, and AI interactions.\n'
              '• Device Information: We collect device identifiers, operating system version, and app version for analytics and crash reporting.\n'
              '• Media: If you upload screenshots or images for OCR analysis, we process them locally on your device using Google ML Kit.\n'
              '• Screen Content via Overlay: The optional floating overlay captures a screenshot of your screen only when you explicitly tap it. This screenshot is processed entirely on your device via OCR — no image data is ever uploaded or stored by us.',
            ),
            _section(
              '3. How We Use Your Information',
              'We use your information to:\n'
              '• Provide and improve our AI dating assistant features\n'
              '• Manage your account and preferences\n'
              '• Analyze app usage to improve user experience\n'
              '• Send important account notifications\n'
              '• Comply with legal obligations\n'
              '• Overlay feature: Capture and process on-screen text via OCR when you tap the floating overlay to generate AI conversation suggestions',
            ),
            _section(
              '4. App Permissions',
              'The overlay feature requires the following permissions:\n'
              '• Overlay/Draw over other apps: Allows a floating touch bubble to appear above other apps so you can access ChatRizz without leaving your messaging app.\n'
              '• Screen capture: When you tap the overlay, a screenshot of the current screen is temporarily captured for OCR processing.\n\n'
              'Important privacy guarantees:\n'
              '• The overlay does NOT monitor, record, or collect your screen activity continuously.\n'
              '• It activates ONLY when you manually tap the overlay bubble.\n'
              '• You can enable/disable the overlay at any time from the app settings.\n'
              '• No third-party services have access to your screen content.',
            ),
            _section(
              '5. Data Storage and Security',
              '• Your data is stored securely using Firebase and local device storage\n'
              '• We implement appropriate technical and organizational measures to protect your data\n'
              '• OCR processing happens entirely on your device using Google ML Kit — no screenshot image data leaves your phone\n'
              '• When using the overlay feature, the screenshot is captured temporarily in device memory, processed via on-device OCR, and immediately discarded\n'
              '• Only the extracted text from the screenshot is sent to our AI backend to generate suggestions\n'
              '• AI conversations are processed through our backend APIs',
            ),
            _section(
              '6. Third-Party Services',
              'We use the following third-party services:\n'
              '• Firebase (Authentication, Analytics, Crashlytics)\n'
              '• Google Mobile Ads (AdMob) for advertising\n'
              '• Google ML Kit for on-device text recognition\n'
              'Each service has its own privacy policy governing their use of your data.',
            ),
            _section(
              '7. Advertising',
              'We display ads via Google AdMob. AdMob may collect and use data for personalized advertising. You can opt out of personalized ads in your device settings.',
            ),
            _section(
              '8. Your Rights',
              'Depending on your location, you may have rights including:\n'
              '• Access to your personal data\n'
              '• Correction of inaccurate data\n'
              '• Deletion of your data\n'
              '• Restriction of processing\n'
              '• Data portability\n'
              '• Objection to processing\n'
              'Contact us to exercise these rights.',
            ),
            _section(
              '9. Data Retention',
              'We retain your data for as long as your account is active or as needed to provide services. You can request account deletion at any time.',
            ),
            _section(
              '10. Changes to This Policy',
              'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new policy in the app.',
            ),
            _section(
              '11. Contact Us',
              'If you have questions about this Privacy Policy, contact us at:\n'
              'Email: support@chatrizz.app\n'
              'Website: chatrizz.app',
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}