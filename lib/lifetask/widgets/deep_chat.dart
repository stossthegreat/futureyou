import 'package:flutter/material.dart';
import 'dart:async';
import '../models/chapter_model.dart';
import '../services/lifetask_api.dart';
import '../services/conversation_manager.dart';
import 'epic_particles.dart';
import 'cinematic_particles.dart'; // Keep for theme

/// DEEP CHAT
/// 
/// The hour-long AI excavation conversation.
/// This is where truth gets pulled from people's souls.
/// 
/// Features:
/// - Streaming AI responses (word-by-word reveal)
/// - Beautiful message bubbles with typography
/// - Real-time depth metrics display
/// - Pattern extraction visualization
/// - Auto-save every 5 minutes
/// - Pause/resume capability
/// - Quality gates (AI won't complete until ready)

class DeepChat extends StatefulWidget {
  final int chapterNumber;
  final LifeTaskAPI api;
  final Function(String proseText, Map<String, dynamic> patterns) onComplete;

  const DeepChat({
    Key? key,
    required this.chapterNumber,
    required this.api,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<DeepChat> createState() => _DeepChatState();
}

class _DeepChatState extends State<DeepChat> with TickerProviderStateMixin {
  late ConversationManager _conversationManager;
  late ScrollController _scrollController;
  late TextEditingController _inputController;
  late AnimationController _pulseController;

  bool _isTyping = false;
  bool _isGeneratingChapter = false;
  bool _canComplete = false;
  String _streamingMessage = '';
  DepthMetrics? _currentDepthMetrics;
  String? _nextPromptHint;

  @override
  void initState() {
    super.initState();
    
    _conversationManager = ConversationManager(
      chapterNumber: widget.chapterNumber,
    );
    _scrollController = ScrollController();
    _inputController = TextEditingController();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _initializeConversation();
  }

  Future<void> _initializeConversation() async {
    // Check if there's a saved session
    final hasStored = await _conversationManager.hasStoredSession();
    
    if (hasStored) {
      _showResumeDialog();
    } else {
      _conversationManager.startSession();
      _sendInitialAIMessage();
    }
  }

  void _showResumeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: Text(
          'Resume Chapter?',
          style: TextStyle(
            fontFamily: 'Crimson Pro',
            color: Colors.white,
            fontSize: 24,
          ),
        ),
        content: Text(
          'You have an unfinished conversation for this chapter. Continue where you left off?',
          style: TextStyle(
            fontFamily: 'Crimson Pro',
            color: Colors.white.withOpacity(0.8),
            fontSize: 16,
            height: 1.6,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _conversationManager.startSession();
              _sendInitialAIMessage();
            },
            child: Text(
              'Start Fresh',
              style: TextStyle(
                fontFamily: 'Crimson Pro',
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _conversationManager.resumeSession();
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFfbbf24),
            ),
            child: Text(
              'Resume',
              style: TextStyle(
                fontFamily: 'Crimson Pro',
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendInitialAIMessage() {
    // First AI message to start the conversation
    _conversationManager.addAssistantMessage(
      _getInitialPrompt(widget.chapterNumber),
    );
    setState(() {});
  }

  String _getInitialPrompt(int chapterNumber) {
    switch (chapterNumber) {
      case 1:
        return "Let's begin at the beginning. Not your career, not your degrees—your childhood.\n\nTell me about one specific moment when you felt completely absorbed as a child. Not a memory—a scene. Where were you? What were you doing? What did your hands touch?";
      case 2:
        return "This chapter asks for honesty that might feel uncomfortable. That's the point.\n\nTell me about someone whose life makes you irrationally jealous. Not their success—their daily life. What are they doing that you're not letting yourself do?";
      case 3:
        return "Time to look in the mirror without flinching.\n\nDescribe the last time you felt quietly proud of yourself. Not accomplishment-proud—usefulness-proud. What did you do? For whom? What changed?";
      default:
        return "Welcome to Chapter $chapterNumber. Let's dive deep.";
    }
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isTyping) return;

    // Add user message
    _conversationManager.addUserMessage(text);
    _inputController.clear();
    setState(() {});
    
    _scrollToBottom();

    // Get AI response
    setState(() {
      _isTyping = true;
      _streamingMessage = '';
    });

    try {
      final response = await widget.api.converse(
        chapterNumber: widget.chapterNumber,
        messages: _conversationManager.messages,
        sessionStartTime: _conversationManager.sessionStartTime!,
      );

      // Add AI response
      _conversationManager.addAssistantMessage(response.coachMessage);
      _conversationManager.updatePatterns(response.extractedPatterns);

      setState(() {
        _isTyping = false;
        _currentDepthMetrics = response.depthMetrics;
        _canComplete = response.depthMetrics.qualityChecksPassed;
        _nextPromptHint = response.nextPromptHint;
      });

      _scrollToBottom();

    } catch (e) {
      setState(() {
        _isTyping = false;
      });
      _showError('Failed to get response: $e');
    }
  }

  Future<void> _completeChapter() async {
    if (!_canComplete) {
      _showInfo('The AI feels we haven\'t gone deep enough yet. Keep going.');
      return;
    }

    setState(() {
      _isGeneratingChapter = true;
    });

    try {
      // Generate prose chapter
      final chapterResponse = await widget.api.generateChapter(
        chapterNumber: widget.chapterNumber,
        messages: _conversationManager.messages,
        extractedPatterns: _conversationManager.extractedPatterns,
      );

      // Save to backend
      await widget.api.saveChapter(
        chapterNumber: widget.chapterNumber,
        messages: _conversationManager.messages,
        proseText: chapterResponse.proseText,
        extractedPatterns: _conversationManager.extractedPatterns,
        timeSpentMinutes: _conversationManager.totalMinutes +
            _conversationManager.sessionDuration.inMinutes,
      );

      // Clear local storage
      await _conversationManager.clearSession();

      // Notify parent
      widget.onComplete(
        chapterResponse.proseText,
        _conversationManager.extractedPatterns,
      );

    } catch (e) {
      setState(() {
        _isGeneratingChapter = false;
      });
      _showError('Failed to complete chapter: $e');
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade900,
      ),
    );
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF1a1a2e),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    _conversationManager.dispose();
    _scrollController.dispose();
    _inputController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = getChapterTheme(widget.chapterNumber);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // EPIC Background particles (more beautiful, multi-layer)
          Opacity(
            opacity: 0.4, // Increased from 0.2 for visibility
            child: EpicParticles(
              colors: theme.particleColors,
              isPulsing: _isTyping,
              intensity: 0.5, // Moderate intensity for background ambiance
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header with depth metrics
                _buildHeader(),

                // Messages list
                Expanded(
                  child: _buildMessagesList(),
                ),

                // Complete button (if ready)
                if (_canComplete) _buildCompleteButton(),

                // Input area
                _buildInputArea(),
              ],
            ),
          ),

          // Loading overlay
          if (_isGeneratingChapter) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final theme = getChapterTheme(widget.chapterNumber);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.gradientColors[0].withOpacity(0.8),
            Colors.black.withOpacity(0.3),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () async {
                  await _conversationManager.pauseSession();
                  Navigator.pop(context);
                },
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Chapter ${widget.chapterNumber}',
                      style: TextStyle(
                        fontFamily: 'Crimson Pro',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${_conversationManager.exchangeCount} exchanges · ${_conversationManager.sessionDuration.inMinutes} min',
                      style: TextStyle(
                        fontFamily: 'Crimson Pro',
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.white),
                onPressed: _showDepthMetrics,
              ),
            ],
          ),
          
          // Depth indicator
          if (_currentDepthMetrics != null) _buildDepthIndicator(),
        ],
      ),
    );
  }

  Widget _buildDepthIndicator() {
    final metrics = _currentDepthMetrics!;
    // Calculate a rough progress score based on metrics
    final progressScore = ((metrics.specificScenesCollected / 5.0).clamp(0.0, 1.0) +
            (metrics.emotionalMarkersDetected / 3.0).clamp(0.0, 1.0) +
            (1.0 - metrics.vagueResponseRatio)) /
        3;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricBar(
                  'Depth',
                  progressScore,
                  progressScore >= 0.7
                      ? const Color(0xFFfbbf24)
                      : Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
          if (!metrics.qualityChecksPassed && _nextPromptHint != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _nextPromptHint!,
                style: TextStyle(
                  fontFamily: 'Crimson Pro',
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Colors.white.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Crimson Pro',
            fontSize: 10,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 4,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _conversationManager.messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _conversationManager.messages.length) {
          // Typing indicator
          return _buildTypingIndicator();
        }

        final message = _conversationManager.messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(Message message) {
    final isUser = message.role == 'user';
    final theme = getChapterTheme(widget.chapterNumber);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isUser
              ? LinearGradient(
                  colors: [
                    theme.particleColors[0].withOpacity(0.3),
                    theme.particleColors[1].withOpacity(0.2),
                  ],
                )
              : null,
          color: isUser ? null : const Color(0xFF1a1a2e),
          borderRadius: BorderRadius.circular(16),
          border: isUser
              ? Border.all(color: theme.particleColors[0].withOpacity(0.5))
              : null,
        ),
        child: Text(
          message.content,
          style: TextStyle(
            fontFamily: 'Crimson Pro',
            fontSize: 16,
            height: 1.6,
            color: Colors.white.withOpacity(0.95),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a2e),
          borderRadius: BorderRadius.circular(16),
        ),
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(0.33),
                const SizedBox(width: 4),
                _buildDot(0.66),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDot(double delay) {
    final value = (_pulseController.value + delay) % 1.0;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.3 + (value * 0.5)),
      ),
    );
  }

  Widget _buildCompleteButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: _completeChapter,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFfbbf24),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.black),
            const SizedBox(width: 8),
            Text(
              'Complete Chapter',
              style: TextStyle(
                fontFamily: 'Crimson Pro',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(
                fontFamily: 'Crimson Pro',
                fontSize: 16,
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: 'Share your truth...',
                hintStyle: TextStyle(
                  fontFamily: 'Crimson Pro',
                  color: Colors.white.withOpacity(0.4),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.black.withOpacity(0.3),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: _isTyping ? null : _sendMessage,
            icon: Icon(
              Icons.send,
              color: _isTyping
                  ? Colors.white.withOpacity(0.3)
                  : const Color(0xFFfbbf24),
            ),
            iconSize: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xFFfbbf24),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Generating your chapter...',
              style: TextStyle(
                fontFamily: 'Crimson Pro',
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This takes 10-15 seconds',
              style: TextStyle(
                fontFamily: 'Crimson Pro',
                fontSize: 14,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDepthMetrics() {
    if (_currentDepthMetrics == null) return;

    final metrics = _currentDepthMetrics!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: Text(
          'Conversation Depth',
          style: TextStyle(
            fontFamily: 'Crimson Pro',
            color: Colors.white,
            fontSize: 24,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetricRow('Scenes Collected', metrics.specificScenesCollected / 10.0),
            _buildMetricRow('Emotional Markers', metrics.emotionalMarkersDetected / 5.0),
            _buildMetricRow('Clarity', 1.0 - metrics.vagueResponseRatio),
            const SizedBox(height: 16),
            Text(
              '⏱️ ${metrics.timeElapsedMinutes} min  |  💬 ${metrics.exchangeCount} exchanges',
              style: TextStyle(
                fontFamily: 'Crimson Pro',
                fontSize: 12,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              metrics.qualityChecksPassed
                  ? '✓ Ready to complete'
                  : _nextPromptHint ?? 'Keep exploring...',
              style: TextStyle(
                fontFamily: 'Crimson Pro',
                fontSize: 14,
                color: metrics.qualityChecksPassed
                    ? const Color(0xFFfbbf24)
                    : Colors.white.withOpacity(0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Continue',
              style: TextStyle(
                fontFamily: 'Crimson Pro',
                color: const Color(0xFFfbbf24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Crimson Pro',
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  value >= 0.7
                      ? const Color(0xFFfbbf24)
                      : Colors.white.withOpacity(0.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(value * 10).toStringAsFixed(1)}',
            style: TextStyle(
              fontFamily: 'Crimson Pro',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: value >= 0.7
                  ? const Color(0xFFfbbf24)
                  : Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

