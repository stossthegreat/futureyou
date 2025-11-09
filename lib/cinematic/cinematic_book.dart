import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'audio_controller.dart';
import 'package:share_plus/share_plus.dart';

class CinematicBook extends StatefulWidget {
  final AudioController audioController;

  const CinematicBook({super.key, required this.audioController});

  @override
  State<CinematicBook> createState() => _CinematicBookState();
}

class _CinematicBookState extends State<CinematicBook> {
  bool _loading = true;
  String _bookContent = '';

  @override
  void initState() {
    super.initState();
    _compileBook();
  }

  Future<void> _compileBook() async {
    try {
      // Request compilation
      await ApiClient.compileBook();

      // Fetch latest book
      final response = await ApiClient.getLatestBook();

      if (response.success && response.data != null) {
        setState(() {
          _bookContent = response.data!['bodyMd'] as String;
          _loading = false;
        });
      } else {
        throw Exception('Failed to fetch book');
      }
    } catch (e) {
      debugPrint('❌ Book compilation failed: $e');
      setState(() {
        _bookContent = 'Your personal book will appear here...';
        _loading = false;
      });
    }
  }

  void _shareBook() {
    Share.share(_bookContent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'The Book of Purpose',
          style: TextStyle(
            color: Colors.black87,
            fontFamily: 'serif',
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _shareBook,
            icon: const Icon(Icons.share, color: Colors.black87),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Text(
                _bookContent,
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.8,
                  color: Colors.black87,
                  fontFamily: 'serif',
                ),
              ),
            ),
    );
  }
}
