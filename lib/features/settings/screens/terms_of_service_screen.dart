import 'package:flutter/material.dart';
import 'package:chatrizz/app/theme/app_colors.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section(
              'Terms of Service',
              'Effective Date: July 11, 2025',
            ),
            _section(
              '1. Acceptance of Terms',
              'By downloading, installing, or using ChatRizz ("the App"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree, do not use the App.',
            ),
            _section(
              '2. Description of Service',
              'ChatRizz is an AI-powered dating assistant that helps users manage matches, generate conversation suggestions, analyze chat screenshots, and provides a floating overlay feature for quick AI suggestions while messaging in other apps. The App uses artificial intelligence to provide personalized advice.',
            ),
            _section(
              '3. User Accounts',
              '• You must be 18 years or older to use the App.\n'
              '• You are responsible for maintaining the confidentiality of your account credentials.\n'
              '• You agree to provide accurate, current, and complete information during registration.\n'
              '• We reserve the right to suspend or terminate accounts that violate these Terms.',
            ),
            _section(
              '4. Subscriptions and Payments',
              '• The App offers optional premium subscriptions (Plus and Pro) with additional features.\n'
              '• Subscriptions are billed through Google Play / Apple App Store and auto-renew unless cancelled.\n'
              '• Refunds are handled according to the respective store\'s policies.\n'
              '• We reserve the right to modify subscription prices with prior notice.',
            ),
            _section(
              '5. User Content',
              '• You retain ownership of content you create (matches, messages, notes).\n'
              '• You grant us a license to process your content to provide the App\'s features.\n'
              '• You must not upload illegal, offensive, or infringing content.\n'
              '• We may remove content that violates these Terms.',
            ),
            _section(
              '6. AI Features',
              '• AI-generated suggestions are for entertainment and assistance purposes only.\n'
              '• We do not guarantee the accuracy, appropriateness, or effectiveness of AI responses.\n'
              '• You are solely responsible for any messages you send based on AI suggestions.',
            ),
            _section(
              '7. Prohibited Activities',
              'You agree not to:\n'
              '• Use the App for illegal or unauthorized purposes\n'
              '• Reverse engineer, decompile, or attempt to extract source code\n'
              '• Interfere with the App\'s servers or networks\n'
              '• Harass, abuse, or harm other users\n'
              '• Use automated systems to access the App',
            ),
            _section(
              '8. Intellectual Property',
              'The App and its original content, features, and functionality are owned by ChatRizz and are protected by international copyright, trademark, and other intellectual property laws.',
            ),
            _section(
              '9. Disclaimer of Warranties',
              'THE APP IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.',
            ),
            _section(
              '10. Limitation of Liability',
              'TO THE MAXIMUM EXTENT PERMITTED BY LAW, WE SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, OR ANY LOSS OF PROFITS, DATA, OR USE, ARISING FROM YOUR USE OF THE APP.',
            ),
            _section(
              '11. Termination',
              'We may terminate or suspend your access to the App immediately, without prior notice, for conduct that we believe violates these Terms or is harmful to other users, us, or third parties.',
            ),
            _section(
              '12. Governing Law',
              'These Terms shall be governed by the laws of India, without regard to conflict of law principles.',
            ),
            _section(
              '13. Changes to Terms',
              'We may modify these Terms at any time. Continued use of the App after changes constitutes acceptance of the new Terms.',
            ),
            _section(
              '14. Contact Us',
              'If you have questions about these Terms, contact us at:\n'
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