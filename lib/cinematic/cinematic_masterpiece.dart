import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'phase_model.dart';
import 'audio_controller.dart';
import '../services/api_client.dart';

class CinematicMasterpiece extends StatefulWidget {
  const CinematicMasterpiece({super.key});

  @override
  State<CinematicMasterpiece> createState() => _CinematicMasterpieceState();
}

class _CinematicMasterpieceState extends State<CinematicMasterpiece>
    with TickerProviderStateMixin {
  late final AudioController _audioController;
  late final AnimationController _particleController;
  late final AnimationController _textController;
  late final AnimationController _sceneController;
  
  int _currentPhase = 0;
  CinematicState _state = CinematicState.opening;
  
  // Conversation state
  final List<Map<String, String>> _conversation = [];
  final TextEditingController _inputController = TextEditingController();
  bool _isAIThinking = false;
  
  // Chapter state
  String? _generatedChapter;
  int _visibleChars = 0;
  
  @override
  void initState() {
    super.initState();
    _audioController = AudioController();
    _audioController.init();
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    _textController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _sceneController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _startCinematicExperience();
  }

  void _startCinematicExperience() async {
    // Fade in from black
    await Future.delayed(const Duration(milliseconds: 500));
    _sceneController.forward();
    
    // Start music
    final phase = FuturePhase.values[_currentPhase];
    _audioController.playMusic(phase.musicAsset);
    
    // Show opening scene
    setState(() {
      _state = CinematicState.phaseIntro;
    });
    
    await Future.delayed(const Duration(seconds: 3));
    _startPhaseIntro();
  }

  void _startPhaseIntro() async {
    final phase = FuturePhase.values[_currentPhase];
    
    // Animate text reveal
    _textController.reset();
    _textController.forward();
    
    // Start TTS
    _audioController.speak(phase.introText);
    
    // Wait for intro to complete
    await Future.delayed(const Duration(seconds: 8));
    
    setState(() {
      _state = CinematicState.coaching;
    });
    
    _startAICoaching();
  }

  void _startAICoaching() async {
    final phase = FuturePhase.values[_currentPhase];
    
    setState(() {
      _isAIThinking = true;
    });
    
    try {
      // Call real AI coaching
      final response = await ApiClient.enginePhaseStart(
        phase: phase.apiName,
        scenes: _conversation,
      );
      
      if (response.success && response.data != null) {
        final coachMsg = response.data!['coach'] as String?;
        if (coachMsg != null) {
          setState(() {
            _conversation.add({'role': 'coach', 'text': coachMsg});
            _isAIThinking = false;
          });
          
          // Speak the coaching message
          _audioController.speak(coachMsg);
        }
      }
    } catch (e) {
      // Fallback coaching message
      setState(() {
        _conversation.add({
          'role': 'coach',
          'text': _getFallbackCoachingMessage(phase),
        });
        _isAIThinking = false;
      });
    }
  }

  String _getFallbackCoachingMessage(FuturePhase phase) {
    switch (phase) {
      case FuturePhase.call:
        return "Tell me about a moment in your childhood when you felt most alive. A specific scene. Where were you? What were you doing? What did it feel like?";
      case FuturePhase.conflict:
        return "What's the gap between who you are now and who you know you could become? What's been holding you back from that version of yourself?";
      case FuturePhase.mirror:
        return "When you're completely honest with yourself, what patterns do you see? What strengths do you downplay? What fears disguise themselves as logic?";
      case FuturePhase.mentor:
        return "Imagine your wisest, most fulfilled future self. What would they tell you about the path ahead? What do they know that you're still learning?";
      case FuturePhase.task:
        return "What's the work that doesn't feel like work? What problems can't you help but solve? What makes time disappear when you're doing it?";
      case FuturePhase.path:
        return "What would your ideal Tuesday look like? Not someday, but the Tuesday that would make you feel most alive and purposeful?";
      case FuturePhase.promise:
        return "What promise are you ready to make to yourself? What commitment would honor who you're becoming?";
    }
  }

  void _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    
    setState(() {
      _conversation.add({'role': 'user', 'text': text});
      _isAIThinking = true;
    });
    
    _inputController.clear();
    
    try {
      final phase = FuturePhase.values[_currentPhase];
      final response = await ApiClient.enginePhaseStart(
        phase: phase.apiName,
        scenes: _conversation,
      );
      
      if (response.success && response.data != null) {
        final coachMsg = response.data!['coach'] as String?;
        final shouldGenerate = response.data!['shouldGenerateChapter'] as bool? ?? false;
        
        if (coachMsg != null) {
          setState(() {
            _conversation.add({'role': 'coach', 'text': coachMsg});
          });
          
          _audioController.speak(coachMsg);
        }
        
        if (shouldGenerate || _conversation.length >= 8) {
          // Phase complete - generate chapter
          _generateChapter();
          return;
        }
      }
    } catch (e) {
      debugPrint('❌ Coaching failed: $e');
    }
    
    setState(() {
      _isAIThinking = false;
    });
  }

  void _generateChapter() async {
    setState(() {
      _state = CinematicState.generating;
    });
    
    try {
      final phase = FuturePhase.values[_currentPhase];
      final transcript = _conversation
          .map((msg) => '${msg['role']}: ${msg['text']}')
          .join('\n\n');
      
      final response = await ApiClient.generateChapter(
        phase: phase.apiName,
        title: phase.title,
        body: transcript,
      );
      
      if (response.success && response.data != null) {
        final chapter = response.data!['chapter'];
        setState(() {
          _generatedChapter = chapter['bodyMd'] as String;
          _state = CinematicState.chapter;
        });
        
        _startChapterReveal();
      }
    } catch (e) {
      // Fallback chapter
      setState(() {
        _generatedChapter = _generateFallbackChapter();
        _state = CinematicState.chapter;
      });
      
      _startChapterReveal();
    }
  }

  String _generateFallbackChapter() {
    final phase = FuturePhase.values[_currentPhase];
    final userResponses = _conversation
        .where((msg) => msg['role'] == 'user')
        .map((msg) => msg['text'])
        .join(' ');
    
    return """# ${phase.title}

The conversation reveals something profound about who you are becoming.

${userResponses.isNotEmpty ? 'In your words: "$userResponses"' : ''}

This chapter of your journey speaks to the deeper truth that has been waiting for recognition. The path ahead becomes clearer not through grand revelations, but through honest acknowledgment of what has always been true.

Your story continues to unfold, one authentic moment at a time.""";
  }

  void _startChapterReveal() async {
    if (_generatedChapter == null) return;
    
    // Reset and start typing animation
    setState(() {
      _visibleChars = 0;
    });
    
    // Animate chapter text
    for (int i = 0; i <= _generatedChapter!.length; i++) {
      await Future.delayed(const Duration(milliseconds: 20));
      if (mounted) {
        setState(() {
          _visibleChars = i;
        });
      }
    }
    
    // Start TTS for chapter
    _audioController.speak(_generatedChapter!);
    
    // Show next button after delay
    await Future.delayed(const Duration(seconds: 3));
    setState(() {
      _state = CinematicState.chapterComplete;
    });
  }

  void _nextPhase() {
    if (_currentPhase < FuturePhase.values.length - 1) {
      setState(() {
        _currentPhase++;
        _state = CinematicState.phaseIntro;
        _conversation.clear();
        _generatedChapter = null;
        _visibleChars = 0;
      });
      
      _startPhaseIntro();
    } else {
      _completeJourney();
    }
  }

  void _completeJourney() {
    // Navigate to book compilation
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => _BookCompletionScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final phase = FuturePhase.values[_currentPhase];
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _sceneController,
        builder: (context, child) {
          return Opacity(
            opacity: _sceneController.value,
            child: Stack(
              children: [
                // Animated background
                _buildAnimatedBackground(phase),
                
                // Particle effects
                _buildParticleEffects(),
                
                // Main content
                SafeArea(
                  child: _buildMainContent(phase),
                ),
                
                // Phase indicator
                _buildPhaseIndicator(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedBackground(FuturePhase phase) {
    return AnimatedContainer(
      duration: const Duration(seconds: 2),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topLeft,
          radius: 1.5,
          colors: [
            phase.gradientStart.withOpacity(0.6),
            phase.gradientEnd.withOpacity(0.4),
            Colors.black.withOpacity(0.8),
            Colors.black,
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
    );
  }

  Widget _buildParticleEffects() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _particleController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              50 * _particleController.value,
              30 * _particleController.value,
            ),
            child: Opacity(
              opacity: 0.4,
              child: Lottie.asset(
                'assets/cinema/anims/particles.json',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(); // Fallback if Lottie fails
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainContent(FuturePhase phase) {
    switch (_state) {
      case CinematicState.opening:
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
        
      case CinematicState.phaseIntro:
        return _buildPhaseIntro(phase);
        
      case CinematicState.coaching:
        return _buildCoachingInterface(phase);
        
      case CinematicState.generating:
        return _buildGeneratingInterface();
        
      case CinematicState.chapter:
      case CinematicState.chapterComplete:
        return _buildChapterDisplay(phase);
    }
  }

  Widget _buildPhaseIntro(FuturePhase phase) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedBuilder(
            animation: _textController,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * _textController.value),
                child: Opacity(
                  opacity: _textController.value,
                  child: Text(
                    phase.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'serif',
                      height: 1.2,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 40),
          AnimatedBuilder(
            animation: _textController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1 - _textController.value)),
                child: Opacity(
                  opacity: _textController.value,
                  child: Text(
                    phase.introText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      height: 1.8,
                      fontFamily: 'serif',
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 2000.ms);
  }

  Widget _buildCoachingInterface(FuturePhase phase) {
    return Column(
      children: [
        // Conversation
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: _conversation.length,
            itemBuilder: (context, index) {
              final msg = _conversation[index];
              final isCoach = msg['role'] == 'coach';
              
              return Align(
                alignment: isCoach ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                  ),
                  decoration: BoxDecoration(
                    color: isCoach
                        ? Colors.white.withOpacity(0.15)
                        : phase.gradientEnd.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    msg['text']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0);
            },
          ),
        ),
        
        // AI thinking indicator
        if (_isAIThinking)
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
                const SizedBox(width: 16),
                const Text(
                  'Your coach is reflecting...',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        
        // Input
        if (!_isAIThinking)
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Share your thoughts...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  backgroundColor: phase.gradientEnd,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildGeneratingInterface() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          const Text(
            'Crafting your personal chapter...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This may take a moment as we weave your story',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms);
  }

  Widget _buildChapterDisplay(FuturePhase phase) {
    if (_generatedChapter == null) return Container();
    
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Personal Chapter',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w600,
              fontFamily: 'serif',
            ),
          ).animate().fadeIn(duration: 800.ms),
          
          const SizedBox(height: 32),
          
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                _generatedChapter!.substring(0, _visibleChars),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  height: 1.8,
                  fontFamily: 'serif',
                ),
              ),
            ),
          ),
          
          if (_state == CinematicState.chapterComplete)
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: _nextPhase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: phase.gradientEnd,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: Text(
                  _currentPhase < FuturePhase.values.length - 1
                      ? 'Continue Journey →'
                      : 'Complete Your Book →',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8)),
            ),
        ],
      ),
    );
  }

  Widget _buildPhaseIndicator() {
    return Positioned(
      top: 50,
      left: 24,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Text(
          'Chapter ${_currentPhase + 1} of ${FuturePhase.values.length}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ).animate().fadeIn(duration: 1000.ms),
    );
  }

  @override
  void dispose() {
    _audioController.dispose();
    _particleController.dispose();
    _textController.dispose();
    _sceneController.dispose();
    _inputController.dispose();
    super.dispose();
  }
}

enum CinematicState {
  opening,
  phaseIntro,
  coaching,
  generating,
  chapter,
  chapterComplete,
}

class _BookCompletionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.auto_stories,
              size: 80,
              color: Color(0xFFD4AF37),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your Book of Purpose',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
                fontFamily: 'serif',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Seven chapters of your journey have been compiled',
              style: TextStyle(
                fontSize: 18,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // Navigate to book view
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text(
                'Read Your Book',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
