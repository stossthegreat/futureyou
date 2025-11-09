import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'audio_voice_controller.dart';

class CinematicBook extends StatefulWidget {
  final Map<String, String> chapters;
  final AudioVoiceController audioController;
  
  const CinematicBook({
    Key? key,
    required this.chapters,
    required this.audioController,
  }) : super(key: key);

  @override
  State<CinematicBook> createState() => _CinematicBookState();
}

class _CinematicBookState extends State<CinematicBook> {
  bool _isReading = false;
  String _fullBookMarkdown = '';

  @override
  void initState() {
    super.initState();
    _compileBook();
  }

  void _compileBook() {
    final buffer = StringBuffer();
    buffer.writeln('# Your Future-You Story\n');
    buffer.writeln('*A journey through purpose discovery*\n');
    buffer.writeln('---\n');
    
    for (final entry in widget.chapters.entries) {
      buffer.writeln('## ${entry.key}\n');
      buffer.writeln(entry.value);
      buffer.writeln('\n---\n');
    }
    
    buffer.writeln('\n*The End*\n');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}\n');
    
    _fullBookMarkdown = buffer.toString();
  }

  Future<void> _shareBook() async {
    try {
      await Share.share(
        _fullBookMarkdown,
        subject: 'My Future-You Story',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: $e')),
        );
      }
    }
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _fullBookMarkdown));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Book copied to clipboard!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _readAloud() {
    if (_isReading) {
      widget.audioController.stopSpeaking();
      setState(() {
        _isReading = false;
      });
    } else {
      setState(() {
        _isReading = true;
      });
      
      // Read all chapters
      final fullText = widget.chapters.values.join('\n\n');
      widget.audioController.speakText(
        fullText,
        onComplete: () {
          if (mounted) {
            setState(() {
              _isReading = false;
            });
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Your Book',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isReading ? Icons.stop : Icons.volume_up,
              color: Colors.white,
            ),
            onPressed: _readAloud,
            tooltip: _isReading ? 'Stop Reading' : 'Read Aloud',
          ),
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white),
            onPressed: _copyToClipboard,
            tooltip: 'Copy to Clipboard',
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _shareBook,
            tooltip: 'Share',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0A0A),
              Color(0xFF1A1A1A),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book title
              const Center(
                child: Text(
                  'Your Future-You Story',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'A journey through purpose discovery',
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              const Divider(color: Colors.white30),
              const SizedBox(height: 32),
              
              // All chapters
              ...widget.chapters.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SelectableText(
                      entry.value,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.8,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Divider(color: Colors.white30),
                    const SizedBox(height: 32),
                  ],
                );
              }).toList(),
              
              // End
              const Center(
                child: Text(
                  'The End',
                  style: TextStyle(
                    fontSize: 20,
                    fontStyle: FontStyle.italic,
                    color: Colors.white70,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Generated: ${DateTime.now().toString().split('.')[0]}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (_isReading) {
      widget.audioController.stopSpeaking();
    }
    super.dispose();
  }
}

