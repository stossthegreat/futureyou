import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design/tokens.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.baseDark1,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Privacy Policy',
          style: AppTextStyles.h2.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last updated: November 5, 2025',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.emerald.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                border: Border.all(
                  color: AppColors.emerald.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    LucideIcons.shield,
                    size: 32,
                    color: AppColors.emerald,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Your Privacy Matters',
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.emerald,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'We are committed to protecting your personal information and your right to privacy.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            _buildSection(
              '1. Information We Collect',
              'Account Information:\n'
              '• Display name and email address\n'
              '• Account preferences and settings\n\n'
              'Usage Data:\n'
              '• Habits and goals you create\n'
              '• Completion history and streaks\n'
              '• AI chat conversations\n'
              '• App interaction patterns\n\n'
              'Device Information:\n'
              '• Device type and operating system\n'
              '• App version and crash reports\n'
              '• IP address for security purposes',
            ),
            
            _buildSection(
              '2. How We Use Your Information',
              'We use your information to:\n\n'
              '• Provide and improve Future-You OS services\n'
              '• Generate personalized AI recommendations\n'
              '• Track your progress and calculate statistics\n'
              '• Send you daily briefs, letters, and nudges\n'
              '• Analyze usage patterns to enhance features\n'
              '• Ensure security and prevent fraud\n'
              '• Communicate service updates and support',
            ),
            
            _buildSection(
              '3. AI and Machine Learning',
              'Future-You OS uses AI to provide personalized experiences:\n\n'
              '• Your conversations with Future-You AI are processed to generate relevant responses\n'
              '• Habit data is analyzed to identify patterns and provide insights\n'
              '• All AI processing respects your privacy and is used solely to enhance your experience\n'
              '• We do not train AI models on your personal data without explicit consent',
            ),
            
            _buildSection(
              '4. Data Storage and Security',
              'We take data security seriously:\n\n'
              '• All data is encrypted in transit and at rest\n'
              '• Local data is stored securely on your device\n'
              '• Cloud syncing uses industry-standard encryption\n'
              '• We regularly audit our security practices\n'
              '• Access to user data is strictly limited to authorized personnel',
            ),
            
            _buildSection(
              '5. Data Sharing',
              'We do NOT sell your personal information. We may share data only in these limited circumstances:\n\n'
              '• Service Providers: Third-party services that help us operate the app (e.g., cloud hosting, analytics)\n'
              '• Legal Requirements: When required by law or to protect rights and safety\n'
              '• Business Transfers: In the event of a merger or acquisition\n\n'
              'All third parties are contractually obligated to protect your data.',
            ),
            
            _buildSection(
              '6. Your Rights',
              'You have the right to:\n\n'
              '• Access: Request a copy of your personal data\n'
              '• Correction: Update or correct your information\n'
              '• Deletion: Request deletion of your account and data\n'
              '• Export: Download your data in a portable format\n'
              '• Opt-out: Disable specific data collection features\n\n'
              'Contact support@futureyou-os.com to exercise these rights.',
            ),
            
            _buildSection(
              '7. Data Retention',
              'We retain your data as long as your account is active. Upon account deletion:\n\n'
              '• Personal data is deleted within 30 days\n'
              '• Anonymized usage statistics may be retained for service improvement\n'
              '• Backups are purged according to our retention schedule',
            ),
            
            _buildSection(
              '8. Children\'s Privacy',
              'Future-You OS is not intended for users under 13 years of age. We do not knowingly collect personal information from children. If you believe we have inadvertently collected such information, please contact us immediately.',
            ),
            
            _buildSection(
              '9. International Users',
              'Future-You OS is operated from the United States. If you are accessing the app from outside the US, please be aware that your information may be transferred to, stored, and processed in the US where our servers are located.',
            ),
            
            _buildSection(
              '10. Changes to Privacy Policy',
              'We may update this Privacy Policy from time to time. We will notify you of any material changes via email or in-app notification. Continued use of the app after changes constitutes acceptance of the updated policy.',
            ),
            
            _buildSection(
              '11. Contact Us',
              'If you have questions or concerns about this Privacy Policy, please contact us:\n\n'
              'Email: privacy@futureyou-os.com\n'
              'Website: www.futureyou-os.com/privacy\n\n'
              'We aim to respond to all privacy-related inquiries within 48 hours.',
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.glassBackground,
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                border: Border.all(
                  color: AppColors.glassBorder,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.lock,
                    color: AppColors.emerald,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Your data is encrypted and secure. We will never sell your personal information.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.h3.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.emerald,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            content,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

