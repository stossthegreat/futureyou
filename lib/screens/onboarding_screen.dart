import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design/tokens.dart';
import '../services/local_storage.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  final int _total = 7; // Updated from 6 to 7 for identity page
  final TextEditingController _lifeTaskController = TextEditingController();
  
  // Identity capture controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _burningQuestionController = TextEditingController();

  void _nextStep() {
    // Validate identity page before proceeding
    if (_step == 1) {
      if (_nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter your name'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      _saveIdentityToLocal();
    }
    
    if (_step < _total - 1) {
      setState(() => _step++);
    }
  }

  void _prevStep() {
    if (_step > 0) {
      setState(() => _step--);
    }
  }

  double get _progress => ((_step + 1) / _total) * 100;

  Future<void> _saveIdentityToLocal() async {
    await LocalStorageService.saveSetting('userName', _nameController.text.trim());
    await LocalStorageService.saveSetting('userAge', int.tryParse(_ageController.text) ?? 0);
    await LocalStorageService.saveSetting('burningQuestion', _burningQuestionController.text.trim());
  }

  @override
  void dispose() {
    _lifeTaskController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _burningQuestionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              const Color(0xFF09090B),
              Colors.black,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Top progress bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 6,
                color: const Color(0xFF27272A),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: MediaQuery.of(context).size.width * (_progress / 100),
                    decoration: BoxDecoration(
                      gradient: AppColors.emeraldGradient,
                    ),
                  ),
                ),
              ),
            ),

            // Main content
            SafeArea(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeOut,
                transitionBuilder: (child, animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.15, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: _buildPage(_step),
              ),
            ),

            // Bottom progress dots
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_total, (index) {
                  return GestureDetector(
                    onTap: () => setState(() => _step = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: index == _step ? 32 : 10,
                      height: 10,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: index == _step
                            ? AppColors.emerald
                            : const Color(0xFF3F3F46),
                        borderRadius: BorderRadius.circular(AppBorderRadius.full),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(int step) {
    switch (step) {
      case 0:
        return _buildAwakeningPage();
      case 1:
        return _buildIdentityPage(); // NEW: Identity capture
      case 2:
        return _buildMirrorPage();
      case 3:
        return _buildOSOPage();
      case 4:
        return _buildWhatIfPage();
      case 5:
        return _buildOathPage();
      case 6:
        return _buildPaywallPage();
      default:
        return Container();
    }
  }

  // PAGE 1: AWAKENING
  Widget _buildAwakeningPage() {
    return Center(
      key: const ValueKey(0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.emerald.withOpacity(0.1),
                border: Border.all(
                  color: AppColors.emerald.withOpacity(0.4),
                ),
                borderRadius: BorderRadius.circular(AppBorderRadius.full),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'AWAKENING',
                    style: AppTextStyles.captionSmall.copyWith(
                      color: AppColors.emerald,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    LucideIcons.sparkles,
                    size: 14,
                    color: AppColors.emerald,
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 600.ms),
            const SizedBox(height: 24),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Color(0xFF34D399),
                  Color(0xFF10B981),
                ],
              ).createShader(bounds),
              child: Text(
                'Every person has a calling — ',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideY(begin: 0.1, end: 0),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Color(0xFF34D399),
                  Color(0xFF10B981),
                ],
              ).createShader(bounds),
              child: const Text(
                'yours is waiting to be remembered.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 24),
            Text(
              'Future-You OS is an AI that helps you uncover who you really are, what truly matters, and builds the system to get you there.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _nextStep,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: AppColors.emeraldGradient,
                  borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.emerald.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Begin',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(LucideIcons.arrowRight, size: 20, color: Colors.black),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 800.ms, duration: 600.ms).scale(begin: const Offset(0.9, 0.9)),
          ],
        ),
      ),
    );
  }

  // PAGE 2: IDENTITY CAPTURE
  Widget _buildIdentityPage() {
    return Container(
      key: const ValueKey(1),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black, Color(0xFF0F1F0F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(LucideIcons.user, size: 64, color: AppColors.emerald)
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(delay: 200.ms),
              const SizedBox(height: 24),
              Text(
                'First, let me know you',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 48),
              
              // Name input
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  labelText: 'Your Name',
                  labelStyle: TextStyle(color: AppColors.emerald),
                  hintText: 'What should I call you?',
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.emerald.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.emerald, width: 2),
                  ),
                ),
              ).animate().slideY(begin: 0.2, delay: 400.ms),
              
              const SizedBox(height: 20),
              
              // Age input
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  labelText: 'Your Age',
                  labelStyle: TextStyle(color: AppColors.emerald),
                  hintText: 'How old are you?',
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.emerald.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.emerald, width: 2),
                  ),
                ),
              ).animate().slideY(begin: 0.2, delay: 500.ms),
              
              const SizedBox(height: 20),
              
              // Burning question input
              TextFormField(
                controller: _burningQuestionController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'One Burning Question',
                  labelStyle: TextStyle(color: AppColors.emerald),
                  hintText: 'What\'s the ONE thing you want to change?',
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.emerald.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.emerald, width: 2),
                  ),
                ),
              ).animate().slideY(begin: 0.2, delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }

  // PAGE 3: THE MIRROR
  Widget _buildMirrorPage() {
    return Center(
      key: const ValueKey(2),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.2,
                ),
                children: [
                  const TextSpan(text: 'Meet '),
                  TextSpan(
                    text: 'Future-You',
                    style: TextStyle(
                      foreground: Paint()
                        ..shader = const LinearGradient(
                          colors: [Color(0xFF34D399), Color(0xFF10B981)],
                        ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 24),
            Text(
              'The AI version of you who remembers everything you\'ve said you\'d become — and writes to you daily, guiding you with clarity and compassion.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _prevStep,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF18181B),
                      border: Border.all(color: const Color(0xFF27272A)),
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                    child: Row(
                      children: const [
                        Icon(LucideIcons.arrowLeft, size: 16, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Back', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _nextStep,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: AppColors.emeraldGradient,
                      borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.emerald.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: const [
                        Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(LucideIcons.arrowRight, size: 20, color: Colors.black),
                      ],
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
          ],
        ),
      ),
    );
  }

  // PAGE 4: THE OSO SYSTEM
  Widget _buildOSOPage() {
    return Center(
      key: const ValueKey(3),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'The OSO System',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.2,
              ),
            ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 16),
            Text(
              'An intelligent operating system that keeps you aligned with your Life\'s Task through three pillars:',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
            const SizedBox(height: 32),
            _buildOSOCard(
              icon: LucideIcons.calendarHeart,
              title: 'Morning Brief',
              description: 'AI-generated daily focus that reminds you of your identity, key habits, and commitments for the day.',
              delay: 300,
            ),
            const SizedBox(height: 16),
            _buildOSOCard(
              icon: LucideIcons.mail,
              title: 'Letters from Future-You',
              description: 'Deep, evolving letters that help you reflect on progress and reconnect with your deeper purpose.',
              delay: 400,
            ),
            const SizedBox(height: 16),
            _buildOSOCard(
              icon: LucideIcons.bellRing,
              title: 'Evening Nudge',
              description: 'Your nightly reflection — closes the loop, celebrates wins, and prepares you for tomorrow.',
              delay: 500,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _prevStep,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF18181B),
                      border: Border.all(color: const Color(0xFF27272A)),
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                    child: Row(
                      children: const [
                        Icon(LucideIcons.arrowLeft, size: 16, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Back', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _nextStep,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: AppColors.emeraldGradient,
                      borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.emerald.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: const [
                        Text(
                          'Next',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(LucideIcons.arrowRight, size: 20, color: Colors.black),
                      ],
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
            const SizedBox(height: 80), // Extra space for bottom dots
          ],
        ),
      ),
    );
  }

  Widget _buildOSOCard({
    required IconData icon,
    required String title,
    required String description,
    required int delay,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF09090B),
        border: Border.all(
          color: AppColors.emerald.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.xxl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.emerald),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms, duration: 600.ms).slideY(begin: 0.1, end: 0);
  }

  // PAGE 5: WHAT-IF ENGINE
  Widget _buildWhatIfPage() {
    return Center(
      key: const ValueKey(4),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'The What-If Engine',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.2,
              ),
            ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 16),
            Text(
              'An expert AI system that clarifies your goals and generates research-backed action plans — one click to turn them into habits.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF09090B),
                border: Border.all(
                  color: AppColors.emerald.withOpacity(0.3),
                ),
                borderRadius: BorderRadius.circular(AppBorderRadius.xxl),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(LucideIcons.flaskConical, size: 20, color: AppColors.emerald),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Example: What if I wanted to look younger?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'The system analyzes evidence and returns science-based levers you can commit instantly:',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildBulletPoint('Dermatology-backed skin protocol (SPF, retinoids, sleep).'),
                  _buildBulletPoint('Nutrition & supplement suggestions validated by studies.'),
                  _buildBulletPoint('Habit integration via your Morning Brief.'),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: AppColors.emeraldGradient,
                        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.emerald.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(LucideIcons.checkCircle2, size: 20, color: Colors.black),
                          SizedBox(width: 8),
                          Text(
                            'Commit to Habit',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _prevStep,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF18181B),
                      border: Border.all(color: const Color(0xFF27272A)),
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                    child: Row(
                      children: const [
                        Icon(LucideIcons.arrowLeft, size: 16, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Back', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _nextStep,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: AppColors.emeraldGradient,
                      borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.emerald.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: const [
                        Text(
                          'Next',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(LucideIcons.arrowRight, size: 20, color: Colors.black),
                      ],
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
            const SizedBox(height: 80), // Extra space for bottom dots
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: AppColors.textSecondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // PAGE 6: OATH
  Widget _buildOathPage() {
    return Center(
      key: const ValueKey(5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.2,
                ),
                children: [
                  const TextSpan(text: 'State your '),
                  TextSpan(
                    text: 'Life\'s Task',
                    style: TextStyle(
                      foreground: Paint()
                        ..shader = const LinearGradient(
                          colors: [Color(0xFF34D399), Color(0xFF10B981)],
                        ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 24),
            Text(
              'This is your guiding statement — Future-You will hold you to it, reminding you daily who you promised to become.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
            const SizedBox(height: 32),
            TextField(
              controller: _lifeTaskController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'My life\'s task is…',
                hintStyle: const TextStyle(color: Color(0xFF52525B)),
                filled: true,
                fillColor: Colors.black.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                  borderSide: const BorderSide(color: Color(0xFF27272A)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                  borderSide: const BorderSide(color: Color(0xFF27272A)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                  borderSide: const BorderSide(color: AppColors.emerald),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _nextStep,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: AppColors.emeraldGradient,
                  borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.emerald.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Seal Promise',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(LucideIcons.penTool, size: 20, color: Colors.black),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
          ],
        ),
      ),
    );
  }

  // PAGE 7: PAYWALL
  Widget _buildPaywallPage() {
    return Center(
      key: const ValueKey(6),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Choose Your Path',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.2,
              ),
            ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 16),
            Text(
              'Free users get standard tracking; premium unlocks the full AI OS experience.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
            const SizedBox(height: 32),
            _buildPricingCard(
              icon: LucideIcons.shieldCheck,
              title: 'Free',
              price: '\$0',
              features: [
                'Basic habit & task tracking',
                'No AI, no OS features',
                'Manual reflection diary',
              ],
              onTap: widget.onComplete,
              isPrimary: false,
              delay: 300,
            ),
            const SizedBox(height: 16),
            _buildPricingCard(
              icon: LucideIcons.crown,
              title: 'Premium Monthly',
              price: '\$9.99',
              subtitle: 'Full OSO AI System',
              features: [
                'Life\'s Task AI Discovery',
                'Morning Briefs, Letters, and Nudges',
                'What-If Engine Commit Feature',
              ],
              onTap: widget.onComplete,
              isPrimary: true,
              delay: 400,
            ),
            const SizedBox(height: 16),
            _buildPricingCard(
              icon: LucideIcons.creditCard,
              title: 'Yearly',
              price: '\$69.99',
              subtitle: 'Save ~40% vs monthly',
              features: [
                'All premium features',
                'Founder\'s badge & early releases',
                'Exclusive Future-You updates',
              ],
              onTap: widget.onComplete,
              isPrimary: false,
              delay: 500,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _prevStep,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF18181B),
                      border: Border.all(color: const Color(0xFF27272A)),
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                    child: Row(
                      children: const [
                        Icon(LucideIcons.arrowLeft, size: 16, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Back', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: widget.onComplete,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: AppColors.emeraldGradient,
                      borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.emerald.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: const [
                        Text(
                          'Enter the OS',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(LucideIcons.arrowRight, size: 20, color: Colors.black),
                      ],
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
            const SizedBox(height: 80), // Extra space for bottom dots
          ],
        ),
      ),
    );
  }

  Widget _buildPricingCard({
    required IconData icon,
    required String title,
    required String price,
    String? subtitle,
    required List<String> features,
    required VoidCallback onTap,
    required bool isPrimary,
    required int delay,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF09090B),
          border: Border.all(
            color: isPrimary
                ? AppColors.emerald.withOpacity(0.5)
                : const Color(0xFF27272A),
            width: isPrimary ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppBorderRadius.xxl),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppColors.emerald.withOpacity(0.2),
                    blurRadius: 40,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: isPrimary ? AppColors.emerald : Colors.white60),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isPrimary ? AppColors.emerald : Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              price,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTextStyles.captionSmall.copyWith(
                  color: AppColors.emerald.withOpacity(0.8),
                ),
              ),
            ],
            const SizedBox(height: 16),
            ...features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  feature,
                  style: AppTextStyles.caption.copyWith(
                    color: isPrimary ? Colors.white.withOpacity(0.8) : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: isPrimary ? AppColors.emeraldGradient : null,
                color: isPrimary ? null : const Color(0xFF18181B),
                border: isPrimary ? null : Border.all(color: const Color(0xFF27272A)),
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
              ),
              child: Text(
                isPrimary ? 'Start Monthly' : 'Continue Free',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isPrimary ? Colors.black : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay.ms, duration: 600.ms).slideY(begin: 0.1, end: 0);
  }
}
