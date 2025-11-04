import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design/tokens.dart';
import '../services/api_client.dart';
import '../widgets/simple_header.dart';

class VideoData {
  final int id;
  final String title;
  final String description;
  final String duration;
  final List<Color> thumbnailGradient;

  VideoData({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.thumbnailGradient,
  });
}

class DiscoveryPrompt {
  final IconData icon;
  final String text;

  DiscoveryPrompt({
    required this.icon,
    required this.text,
  });
}

class FutureYouScreen extends StatefulWidget {
  const FutureYouScreen({super.key});

  @override
  State<FutureYouScreen> createState() => _FutureYouScreenState();
}

class _FutureYouScreenState extends State<FutureYouScreen> {
  bool _chatExpanded = false;
  VideoData? _selectedVideo;
  final List<ChatMessage> _messages = [
    ChatMessage(
      id: '1',
      role: 'future',
      text: "Welcome. I'm here to help you discover your life's purpose. Let's start with something simple...",
      timestamp: DateTime.now(),
    ),
    ChatMessage(
      id: '2',
      role: 'future',
      text: "Close your eyes for a moment. When you were a child, what activity made you lose track of time?",
      timestamp: DateTime.now(),
    ),
  ];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  final List<VideoData> _videos = [
    VideoData(
      id: 1,
      title: 'The Funeral Exercise',
      description: 'Walk into your own funeral. What do you want them to say?',
      duration: '3:42',
      thumbnailGradient: [
        const Color(0x33FB7185),
        const Color(0x33A855F7),
      ],
    ),
    VideoData(
      id: 2,
      title: 'The Last Day',
      description: 'If today was your last, what would you regret not doing?',
      duration: '2:18',
      thumbnailGradient: [
        const Color(0x333B82F6),
        const Color(0x3306B6D4),
      ],
    ),
    VideoData(
      id: 3,
      title: 'Your Hero\'s Journey',
      description: 'What challenge is calling you to become more?',
      duration: '4:05',
      thumbnailGradient: [
        const Color(0x33F59E0B),
        const Color(0x33F97316),
      ],
    ),
  ];

  final List<DiscoveryPrompt> _discoveryPrompts = [
    DiscoveryPrompt(icon: LucideIcons.lightbulb, text: 'What don\'t you like?'),
    DiscoveryPrompt(icon: LucideIcons.heart, text: 'What makes you feel most alive?'),
    DiscoveryPrompt(icon: LucideIcons.target, text: 'What did you get lost in as a child?'),
    DiscoveryPrompt(icon: LucideIcons.trendingUp, text: 'What would you do if money wasn\'t an issue?'),
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _inputController.text.trim();
    if (message.isEmpty) return;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      text: message,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
      _inputController.clear();
    });

    _scrollToBottom();

    try {
      final result = await ApiClient.sendChatMessageV2(message);

      if (result.success && result.data != null) {
        final aiMessage = result.data!['message'] as String;

        final responseMessage = ChatMessage(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          role: 'future',
          text: aiMessage,
          timestamp: DateTime.now(),
        );

        setState(() {
          _messages.add(responseMessage);
          _isLoading = false;
        });

        debugPrint('✅ Chat response received');
      } else {
        setState(() {
          _isLoading = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Chat failed'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('❌ Chat error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send message'),
          backgroundColor: AppColors.error,
        ),
      );
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _openChatWithPrompt(String prompt) {
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      text: prompt,
      timestamp: DateTime.now(),
    );

    final aiResponse = ChatMessage(
      id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
      role: 'future',
      text: 'Great question to explore. Take your time and really think about this...',
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _messages.add(aiResponse);
      _chatExpanded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              const SimpleHeader(),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeroSection(),
                        const SizedBox(height: AppSpacing.xl),
                        _buildVisualizationVideos(),
                        const SizedBox(height: AppSpacing.xl),
                        _buildDiscoveryPrompts(),
                        const SizedBox(height: AppSpacing.xl),
                        _buildStartSessionButton(),
                        const SizedBox(height: 150), // Bottom padding for nav
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Video player overlay
          if (_selectedVideo != null) _buildVideoPlayerOverlay(),

          // AI chat overlay
          if (_chatExpanded) _buildChatOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppBorderRadius.xxl),
        gradient: LinearGradient(
          colors: [
            AppColors.emerald.withOpacity(0.1),
            AppColors.emerald.withOpacity(0.05),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.emerald.withOpacity(0.2),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.emerald.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppBorderRadius.full),
              border: Border.all(
                color: AppColors.emerald.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  LucideIcons.brain,
                  size: 16,
                  color: AppColors.emerald,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Life Purpose Discovery',
                  style: AppTextStyles.captionSmall.copyWith(
                    color: AppColors.emerald,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                AppColors.textPrimary,
                AppColors.textSecondary,
              ],
            ).createShader(bounds),
            child: Text(
              'Who do you want to become?',
              style: AppTextStyles.h1.copyWith(
                fontSize: 28,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Through guided reflection and powerful visualization exercises, we\'ll uncover what truly matters to you and design your life\'s direction.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textTertiary,
              height: 1.5,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildVisualizationVideos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Visualization Exercises',
          style: AppTextStyles.bodySemiBold.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ..._videos.asMap().entries.map((entry) {
          final index = entry.key;
          final video = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _buildVideoCard(video, index),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildVideoCard(VideoData video, int index) {
    return GestureDetector(
      onTap: () => setState(() => _selectedVideo = video),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppBorderRadius.xl),
          gradient: LinearGradient(
            colors: video.thumbnailGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: AppColors.emerald.withOpacity(0.2),
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              child: const Icon(
                LucideIcons.play,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    video.description,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              video.duration,
              style: AppTextStyles.captionSmall.copyWith(
                color: AppColors.textQuaternary,
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: (index * 100).ms).fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildDiscoveryPrompts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Start Questions',
          style: AppTextStyles.bodySemiBold.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ..._discoveryPrompts.asMap().entries.map((entry) {
          final index = entry.key;
          final prompt = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: GestureDetector(
              onTap: () => _openChatWithPrompt(prompt.text),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.glassBackground,
                  borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                  border: Border.all(
                    color: AppColors.emerald.withOpacity(0.2),
                  ),
                ),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppBorderRadius.md),
                        border: Border.all(
                          color: AppColors.emerald.withOpacity(0.2),
                        ),
                      ),
                      child: Icon(
                        prompt.icon,
                        size: 20,
                        color: AppColors.emerald,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        prompt.text,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate(delay: (index * 80).ms).fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildStartSessionButton() {
    return GestureDetector(
      onTap: () => setState(() => _chatExpanded = true),
      child: Container(
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
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.messageCircle,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  'Start Deep Discovery Session',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const Icon(
              LucideIcons.chevronRight,
              color: Colors.white,
              size: 24,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildVideoPlayerOverlay() {
    return GestureDetector(
      onTap: () => setState(() => _selectedVideo = null),
      child: Container(
        color: Colors.black.withOpacity(0.95),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping content
            child: _VideoPlayer(
              video: _selectedVideo!,
              onClose: () => setState(() => _selectedVideo = null),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildChatOverlay() {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          // Chat header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.emerald.withOpacity(0.2),
                ),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deep Discovery Session',
                        style: AppTextStyles.h3.copyWith(
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_messages.where((m) => m.role == 'user').length} insights captured',
                        style: AppTextStyles.captionSmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => setState(() => _chatExpanded = false),
                    icon: const Icon(
                      LucideIcons.x,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message, index);
              },
            ),
          ),

          // Loading indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.glassBackground,
                      borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                      border: Border.all(
                        color: AppColors.emerald.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.emerald,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Thinking...',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Input area - positioned just above nav tabs
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              100, // Extra space above nav tabs
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              border: Border(
                top: BorderSide(
                  color: AppColors.emerald.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.glassBackground,
                        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                        border: Border.all(
                          color: AppColors.emerald.withOpacity(0.2),
                        ),
                      ),
                      child: TextField(
                        controller: _inputController,
                        style: AppTextStyles.body,
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: 'Share what\'s on your mind...',
                          hintStyle: AppTextStyles.body.copyWith(
                            color: AppColors.textQuaternary,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.md,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppColors.emeraldGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.emerald.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        LucideIcons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildMessageBubble(ChatMessage message, int index) {
    final isUser = message.role == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: isUser ? AppColors.emeraldGradient : null,
                color: isUser ? null : AppColors.glassBackground,
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                border: Border.all(
                  color: isUser
                      ? AppColors.emerald.withOpacity(0.3)
                      : AppColors.emerald.withOpacity(0.2),
                ),
              ),
              child: Text(
                message.text,
                style: AppTextStyles.body.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: (index * 50).ms).fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }
}

// Video player component
class _VideoPlayer extends StatefulWidget {
  final VideoData video;
  final VoidCallback onClose;

  const _VideoPlayer({
    required this.video,
    required this.onClose,
  });

  @override
  State<_VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<_VideoPlayer> with SingleTickerProviderStateMixin {
  bool _playing = true;
  double _progress = 0.0;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    // Simulate video progress
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 50));
      if (_playing && mounted && _progress < 100) {
        setState(() {
          _progress += 0.5;
        });
        return true;
      }
      return false;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(AppBorderRadius.xxl),
        border: Border.all(
          color: AppColors.emerald.withOpacity(0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Video area
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppBorderRadius.xxl),
                ),
                gradient: LinearGradient(
                  colors: widget.video.thumbnailGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppBorderRadius.xxl),
                      ),
                      color: Colors.black.withOpacity(0.4 * (1 - _pulseController.value * 0.3)),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.video.title,
                            style: AppTextStyles.h2,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            widget.video.description,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          GestureDetector(
                            onTap: () => setState(() => _playing = !_playing),
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                _playing ? LucideIcons.pause : LucideIcons.play,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Controls
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => setState(() => _playing = !_playing),
                      icon: Icon(
                        _playing ? LucideIcons.pause : LucideIcons.play,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _progress = 0),
                      icon: const Icon(
                        LucideIcons.rotateCcw,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.glassBackground,
                          borderRadius: BorderRadius.circular(AppBorderRadius.full),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _progress / 100,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: AppColors.emeraldGradient,
                              borderRadius: BorderRadius.circular(AppBorderRadius.full),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      widget.video.duration,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'After watching, reflect on the questions that emerge',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: widget.onClose,
                      child: Text(
                        'Close',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.emerald,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

