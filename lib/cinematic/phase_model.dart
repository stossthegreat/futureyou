import 'package:flutter/material.dart';

enum FuturePhase {
  call,
  conflict,
  mirror,
  mentor,
  task,
  path,
  promise
}

extension FuturePhaseX on FuturePhase {
  String get apiName => {
        FuturePhase.call: 'call',
        FuturePhase.conflict: 'conflict',
        FuturePhase.mirror: 'mirror',
        FuturePhase.mentor: 'mentor',
        FuturePhase.task: 'task',
        FuturePhase.path: 'path',
        FuturePhase.promise: 'promise',
      }[this]!;

  String get title => {
        FuturePhase.call: 'Chapter I — The Call',
        FuturePhase.conflict: 'Chapter II — The Conflict',
        FuturePhase.mirror: 'Chapter III — The Mirror',
        FuturePhase.mentor: 'Chapter IV — The Mentor',
        FuturePhase.task: 'Chapter V — The Task',
        FuturePhase.path: 'Chapter VI — The Path',
        FuturePhase.promise: 'Chapter VII — The Promise',
      }[this]!;

  String get introText => {
        FuturePhase.call:
            'The world is still.\nIt is the kind of stillness that feels like the moment before a truth arrives.\nSomething inside you is awake before you are, a small pull you cannot name yet.\n\nThis is the beginning of the search for your life\'s task.',
        FuturePhase.conflict:
            'There is a truth you rarely say out loud.\nThe truth that you have been living beneath yourself.\n\nThis chapter exists to bring truth to the surface.\nTruth often feels like discomfort first.\nDiscomfort is the doorway to direction.',
        FuturePhase.mirror:
            'You stand before a surface that shows you more than your face.\nIt shows patterns. It shows habits. It shows the stories you tell yourself when no one is listening.\n\nThe mirror waits for your honesty.\nThis is the moment you meet yourself without the armour.',
        FuturePhase.mentor:
            'A voice arrives, but it feels like it is coming from inside your chest rather than the air.\nIt is older. It is you, years ahead. Not the broken version. The fulfilled one.\n\nThe mentor does not give you the answer.\nThe mentor makes you remember that you already had it.',
        FuturePhase.task:
            'A sentence forms like a key turning in a lock.\n\nYour life\'s task is the intersection of three truths:\n1. What you cannot stop thinking about\n2. What you do better than most without forcing it\n3. What the world becomes better the moment you touch it\n\nYou have known this for a long time.\nThis chapter gives you permission to admit it.',
        FuturePhase.path:
            'Purpose means nothing without direction.\nDirection means nothing without discipline.\nDiscipline means nothing without identity.\n\nThe path is where you turn understanding into movement.\n\nConsistency is the currency that buys the life you want.',
        FuturePhase.promise:
            'A final truth rises slowly, like light returning after darkness.\n\nYour future self speaks again, quieter now.\n\n"We kept the promise. Not in one grand moment. In small, relentless decisions."\n\nThis is the beginning. Not the end.',
      }[this]!;

  String get musicAsset => {
        FuturePhase.call: 'assets/cinema/music/hope.mp3',
        FuturePhase.conflict: 'assets/cinema/music/conflict.mp3',
        FuturePhase.mirror: 'assets/cinema/music/hope.mp3',
        FuturePhase.mentor: 'assets/cinema/music/hope.mp3',
        FuturePhase.task: 'assets/cinema/music/hope.mp3',
        FuturePhase.path: 'assets/cinema/music/hope.mp3',
        FuturePhase.promise: 'assets/cinema/music/promise.mp3',
      }[this]!;

  Color get gradientStart => {
        FuturePhase.call: const Color(0xFF0ea5e9),
        FuturePhase.conflict: const Color(0xFF0f172a),
        FuturePhase.mirror: const Color(0xFF1e293b),
        FuturePhase.mentor: const Color(0xFF7c3aed),
        FuturePhase.task: const Color(0xFFd97706),
        FuturePhase.path: const Color(0xFF059669),
        FuturePhase.promise: const Color(0xFFD4AF37),
      }[this]!;

  Color get gradientEnd => {
        FuturePhase.call: const Color(0xFF22d3ee),
        FuturePhase.conflict: const Color(0xFF1f2937),
        FuturePhase.mirror: const Color(0xFF334155),
        FuturePhase.mentor: const Color(0xFFa855f7),
        FuturePhase.task: const Color(0xFFf59e0b),
        FuturePhase.path: const Color(0xFF10b981),
        FuturePhase.promise: const Color(0xFFFFC857),
      }[this]!;
}
