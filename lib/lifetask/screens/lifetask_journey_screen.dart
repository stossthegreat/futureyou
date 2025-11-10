import 'package:flutter/material.dart';
import '../models/chapter_model.dart';
import '../widgets/cinematic_particles.dart';
import 'chapter_screen.dart';

/// LIFE'S TASK DISCOVERY JOURNEY
/// 
/// Main navigation screen showing 7 chapters
/// Beautiful, immersive, inspiring

// 🔧 DEBUG MODE: Set to true to unlock all chapters for testing
const bool DEBUG_UNLOCK_ALL_CHAPTERS = true; // TODO: Set to false before release

class LifeTaskJourneyScreen extends StatefulWidget {
  const LifeTaskJourneyScreen({Key? key}) : super(key: key);

  @override
  State<LifeTaskJourneyScreen> createState() => _LifeTaskJourneyScreenState();
}

class _LifeTaskJourneyScreenState extends State<LifeTaskJourneyScreen> {
  late List<Chapter> chapters;

  @override
  void initState() {
    super.initState();
    chapters = getInitialChapters();
    
    // DEBUG: Unlock all chapters for testing
    if (DEBUG_UNLOCK_ALL_CHAPTERS) {
      chapters = chapters.map((c) => c.copyWith(
        status: ChapterStatus.available,
      )).toList();
      print('🔧 DEBUG MODE: All chapters unlocked for testing');
    }
    
    // TODO: Load saved progress from local storage
  }

  void _openChapter(Chapter chapter) {
    print('🚪 Opening Chapter ${chapter.number} - Status: ${chapter.status}');
    
    if (chapter.status == ChapterStatus.locked) {
      _showLockedDialog(chapter);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChapterScreen(chapter: chapter),
      ),
    ).then((updatedChapter) {
      if (updatedChapter != null && updatedChapter is Chapter) {
        setState(() {
          final index = chapters.indexWhere((c) => c.number == updatedChapter.number);
          if (index != -1) {
            chapters[index] = updatedChapter;
            
            // Unlock next chapter if current completed
            if (updatedChapter.status == ChapterStatus.completed &&
                index + 1 < chapters.length) {
              chapters[index + 1] = chapters[index + 1].copyWith(
                status: ChapterStatus.available,
              );
            }
          }
        });
        // TODO: Save progress to local storage
      }
    });
  }

  void _showLockedDialog(Chapter chapter) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: Text(
          'Chapter Locked',
          style: TextStyle(
            fontFamily: 'Crimson Pro',
            color: Colors.white,
            fontSize: 24,
          ),
        ),
        content: Text(
          'Complete the previous chapters to unlock ${chapter.subtitle}.',
          style: TextStyle(
            fontFamily: 'Crimson Pro',
            color: Colors.white.withOpacity(0.8),
            fontSize: 16,
            height: 1.6,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Understood',
              style: TextStyle(
                fontFamily: 'Crimson Pro',
                color: const Color(0xFFfbbf24),
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = chapters.where((c) => c.status == ChapterStatus.completed).length;
    final progress = completedCount / chapters.length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background particles (subtle)
          Opacity(
            opacity: 0.3,
            child: CinematicParticles(
              theme: chapterOneTheme,
              intensity: 0.3,
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'The Life\'s Task Discovery',
                        style: TextStyle(
                          fontFamily: 'Crimson Pro',
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: const Color(0xFFfbbf24).withOpacity(0.3),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Seven Chapters · $completedCount of ${chapters.length} Complete',
                        style: TextStyle(
                          fontFamily: 'Crimson Pro',
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: Colors.white.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFFfbbf24),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Chapters list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: chapters.length,
                    itemBuilder: (context, index) {
                      return _buildChapterCard(chapters[index]);
                    },
                  ),
                ),

                // Bottom info
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Each chapter takes 1-2 hours. This is deep work.',
                    style: TextStyle(
                      fontFamily: 'Crimson Pro',
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterCard(Chapter chapter) {
    final theme = getChapterTheme(chapter.number);
    final isLocked = chapter.status == ChapterStatus.locked;
    final isCompleted = chapter.status == ChapterStatus.completed;
    final isInProgress = chapter.status == ChapterStatus.inProgress;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: GestureDetector(
        onTap: () => _openChapter(chapter),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isLocked
                  ? [
                      Colors.grey.shade900,
                      Colors.grey.shade800,
                    ]
                  : theme.gradientColors.length >= 2
                      ? [
                          theme.gradientColors[0].withOpacity(0.6),
                          theme.gradientColors[1].withOpacity(0.4),
                        ]
                      : [
                          const Color(0xFF1a1a2e),
                          const Color(0xFF16213e),
                        ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCompleted
                  ? const Color(0xFFfbbf24)
                  : isInProgress
                      ? theme.particleColors[0]
                      : Colors.white.withOpacity(0.1),
              width: isCompleted || isInProgress ? 2 : 1,
            ),
            boxShadow: [
              if (!isLocked)
                BoxShadow(
                  color: theme.particleColors[0].withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                // Chapter number circle
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isLocked
                        ? Colors.grey.shade700
                        : theme.particleColors[0].withOpacity(0.3),
                    border: Border.all(
                      color: isLocked
                          ? Colors.grey.shade600
                          : theme.particleColors[0],
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: isLocked
                        ? Icon(Icons.lock, color: Colors.grey.shade500, size: 28)
                        : isCompleted
                            ? const Icon(Icons.check, color: Color(0xFFfbbf24), size: 32)
                            : Text(
                                '${chapter.number}',
                                style: TextStyle(
                                  fontFamily: 'Crimson Pro',
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                  ),
                ),

                const SizedBox(width: 20),

                // Chapter info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chapter.title,
                        style: TextStyle(
                          fontFamily: 'Crimson Pro',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: isLocked
                              ? Colors.grey.shade600
                              : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        chapter.subtitle,
                        style: TextStyle(
                          fontFamily: 'Crimson Pro',
                          fontSize: 18,
                          color: isLocked
                              ? Colors.grey.shade700
                              : Colors.white.withOpacity(0.8),
                        ),
                      ),
                      if (isInProgress) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${chapter.timeSpentMinutes} min · In Progress',
                          style: TextStyle(
                            fontFamily: 'Crimson Pro',
                            fontSize: 14,
                            color: theme.particleColors[0],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (isCompleted) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Completed · ${chapter.timeSpentMinutes} min',
                          style: TextStyle(
                            fontFamily: 'Crimson Pro',
                            fontSize: 14,
                            color: const Color(0xFFfbbf24),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  isLocked ? Icons.lock_outline : Icons.arrow_forward_ios,
                  color: isLocked
                      ? Colors.grey.shade600
                      : Colors.white.withOpacity(0.6),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

