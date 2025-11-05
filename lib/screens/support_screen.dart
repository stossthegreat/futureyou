import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../design/tokens.dart';
import '../widgets/glass_card.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  void _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@futureyou-os.com',
      query: 'subject=Future-You OS Support Request',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

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
          'Help & Support',
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
            // Quick help cards
            GlassCard(
              child: Column(
                children: [
                  const Icon(
                    LucideIcons.messageCircle,
                    size: 48,
                    color: AppColors.emerald,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'We\'re Here to Help!',
                    style: AppTextStyles.h3.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Get answers to common questions or reach out to our support team.',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            _buildContactCard(
              'Email Support',
              'Get help via email',
              LucideIcons.mail,
              'support@futureyou-os.com',
              _launchEmail,
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            Text(
              'Frequently Asked Questions',
              style: AppTextStyles.h3.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            _buildFAQ(
              'How do I create a habit?',
              'Go to the Planner tab, tap "Add New", select "Habit", and fill in the details like title, time, and repeat days. Tap "Create" to save it.',
            ),
            
            _buildFAQ(
              'What is the What-If tab?',
              'The What-If tab provides science-backed goal plans from Harvard, Stanford, and NIH research. You can commit to any goal for 21 days with one tap, and it automatically creates habit cards in your Planner and Home tabs.',
            ),
            
            _buildFAQ(
              'How do I mark a habit as complete?',
              'On the Home tab, tap the checkbox next to any habit to mark it done for today. Your streak will increase automatically.',
            ),
            
            _buildFAQ(
              'What are Letters, Nudges, and Briefs?',
              'These are AI-generated messages from your Future-You:\n\n'
              '• Letters: Deep reflections on your journey\n'
              '• Nudges: Quick reminders to stay on track\n'
              '• Briefs: Daily summaries and motivation\n\n'
              'You can view them all in the Reflections tab.',
            ),
            
            _buildFAQ(
              'How does the Mirror feature work?',
              'The Mirror tab analyzes your behavior patterns and shows you insights about yourself. It uses AI to help you understand your habits, strengths, and areas for growth.',
            ),
            
            _buildFAQ(
              'Can I edit or delete a habit?',
              'Yes! Go to the Planner tab, switch to the "Manage" view, and long-press any habit to see options for editing or deleting it.',
            ),
            
            _buildFAQ(
              'What\'s the difference between Free and Premium?',
              'Free: Basic habit tracking, task management, and limited AI features\n\n'
              'Premium (\$9.99/month): Unlimited What-If planning, unlimited AI conversations, voice mentors, smart forecasts, and advanced analytics.',
            ),
            
            _buildFAQ(
              'How do I cancel my subscription?',
              'Go to Settings → Subscription → Manage Subscription. You can cancel anytime, and you\'ll retain Premium access until the end of your billing period.',
            ),
            
            _buildFAQ(
              'Is my data secure?',
              'Yes! All your data is encrypted in transit and at rest. We use industry-standard security practices and never sell your personal information. See our Privacy Policy for full details.',
            ),
            
            _buildFAQ(
              'How do I export my data?',
              'Go to Settings → Data & Privacy → Export Data. Your habits and progress will be exported as a JSON file that you can save or transfer.',
            ),
            
            _buildFAQ(
              'The app crashed or has a bug. What should I do?',
              'Please email us at support@futureyou-os.com with:\n'
              '• Device model and OS version\n'
              '• App version (found in Settings → About)\n'
              '• Steps to reproduce the issue\n\n'
              'We typically respond within 24 hours.',
            ),
            
            _buildFAQ(
              'Can I use Future-You OS offline?',
              'Yes! All core features work offline. Habits, tasks, and your completion history are stored locally on your device. AI features require an internet connection.',
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.emerald.withOpacity(0.3),
                    AppColors.cyan.withOpacity(0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                border: Border.all(
                  color: AppColors.emerald.withOpacity(0.4),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    LucideIcons.heart,
                    size: 32,
                    color: Colors.black,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Still need help?',
                    style: AppTextStyles.h3.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Email us at support@futureyou-os.com\nWe typically respond within 24 hours.',
                    style: AppTextStyles.body.copyWith(
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
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
  
  Widget _buildContactCard(
    String title,
    String subtitle,
    IconData icon,
    String value,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppColors.emeraldGradient,
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              ),
              child: Icon(
                icon,
                color: Colors.black,
                size: 28,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.emerald,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.externalLink,
              size: 20,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFAQ(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                  ),
                  child: const Icon(
                    LucideIcons.helpCircle,
                    size: 16,
                    color: AppColors.emerald,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    question,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(left: 34),
              child: Text(
                answer,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

