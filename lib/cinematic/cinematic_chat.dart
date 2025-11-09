import 'package:flutter/material.dart';
import 'phase_model.dart';
import '../services/api_client.dart';

class CinematicChat extends StatefulWidget {
  final FuturePhase phase;
  final Function(List<Map<String, String>>) onComplete;

  const CinematicChat({
    super.key,
    required this.phase,
    required this.onComplete,
  });

  @override
  State<CinematicChat> createState() => _CinematicChatState();
}

class _CinematicChatState extends State<CinematicChat> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startConversation();
  }

  Future<void> _startConversation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiClient.enginePhaseStart(
        phase: widget.phase.apiName,
      );

      if (response.success && response.data != null) {
        final coachMsg = response.data!['coach'] as String?;
        if (coachMsg != null) {
          setState(() {
            _messages.add({'role': 'coach', 'text': coachMsg});
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Phase start failed: $e');
      // Fallback
      setState(() {
        _messages.add({
          'role': 'coach',
          'text':
              'Tell me about your experience with ${widget.phase.title.toLowerCase()}.'
        });
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });

    _controller.clear();

    try {
      final response = await ApiClient.enginePhaseStart(
        phase: widget.phase.apiName,
        scenes: _messages,
      );

      if (response.success && response.data != null) {
        final coachMsg = response.data!['coach'] as String?;
        final shouldGenerate =
            response.data!['shouldGenerateChapter'] as bool? ?? false;

        if (coachMsg != null) {
          setState(() {
            _messages.add({'role': 'coach', 'text': coachMsg});
          });
        }

        if (shouldGenerate) {
          // Phase complete!
          widget.onComplete(_messages);
          return;
        }
      }
    } catch (e) {
      debugPrint('❌ Message send failed: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Messages
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              final isCoach = msg['role'] == 'coach';
              return Align(
                alignment:
                    isCoach ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  decoration: BoxDecoration(
                    color: isCoach
                        ? Colors.white.withOpacity(0.1)
                        : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    msg['text']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Input
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(color: Colors.white),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Share your thoughts...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide:
                            BorderSide(color: Colors.white.withOpacity(0.2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide:
                            BorderSide(color: Colors.white.withOpacity(0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _sendMessage(_controller.text),
                  icon: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

