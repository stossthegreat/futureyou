/// THE 7 CINEMATIC CHAPTER OPENINGS
/// 
/// These are the most important 2-3 minutes of each chapter.
/// Not just text - CINEMA with TTS, music, particles, emotion.

class ChapterProse {
  final String title;
  final String subtitle;
  final String prose;
  final List<String> proseParagraphs;
  final int estimatedReadSeconds;

  const ChapterProse({
    required this.title,
    required this.subtitle,
    required this.prose,
    required this.proseParagraphs,
    required this.estimatedReadSeconds,
  });
}

/// CHAPTER 1: THE CALL
/// Theme: Awakening, Memory, Innocence
/// Emotion: Wonder + Nostalgia
/// Music: hope.mp3 (Brian Eno-style ambient)
/// Colors: Soft blues → Warm golds
const chapterOneProse = ChapterProse(
  title: 'Chapter I',
  subtitle: 'The Call',
  prose: '''The world is still.

It is the kind of stillness that feels like the moment before a truth arrives.

The air is cool enough that each breath has weight. Something inside you is awake before you are, a small pull you cannot name yet.

You stand in a place that feels both familiar and distant. You are not dreaming, yet nothing here behaves like the usual world. Light moves differently. Time feels slower.

You get the sense that if you listen carefully, something important is about to be said.

A question rises inside you that has no words, only a shape. It is the shape of longing. The shape of a life you have felt, but never fully stepped into. The shape of a version of yourself you keep glimpsing and losing again.

You are not being called by the world. You are being called by yourself. By the part of you that remembers who you used to be, before the noise, before the doubts, before the shortcuts that chipped pieces off your potential.

There is a crossroads here. One road is the familiar one with its patterns, comforts, and predictable frustrations. The other road is the one you do not trust yet, the one that asks more of you than anyone has ever asked.

The road that requires honesty. The road that requires courage.

You feel the call in your chest rather than your ears. A quiet tug. A whisper that says there is something you were meant to do, and you have waited long enough.

This is the beginning of the search for your life's task. Not a hobby. Not a goal. Not a job. The thing that sits beneath all of that. The thing the world becomes more vivid when you touch.

The particles float around you like ideas arriving before language.

You take a step forward. The call grows stronger.

Your story begins now.''',
  proseParagraphs: [
    'The world is still.',
    'It is the kind of stillness that feels like the moment before a truth arrives.',
    'The air is cool enough that each breath has weight. Something inside you is awake before you are, a small pull you cannot name yet.',
    'You stand in a place that feels both familiar and distant. You are not dreaming, yet nothing here behaves like the usual world. Light moves differently. Time feels slower.',
    'You get the sense that if you listen carefully, something important is about to be said.',
    'A question rises inside you that has no words, only a shape. It is the shape of longing. The shape of a life you have felt, but never fully stepped into. The shape of a version of yourself you keep glimpsing and losing again.',
    'You are not being called by the world. You are being called by yourself. By the part of you that remembers who you used to be, before the noise, before the doubts, before the shortcuts that chipped pieces off your potential.',
    'There is a crossroads here. One road is the familiar one with its patterns, comforts, and predictable frustrations. The other road is the one you do not trust yet, the one that asks more of you than anyone has ever asked.',
    'The road that requires honesty. The road that requires courage.',
    'You feel the call in your chest rather than your ears. A quiet tug. A whisper that says there is something you were meant to do, and you have waited long enough.',
    'This is the beginning of the search for your life\'s task. Not a hobby. Not a goal. Not a job. The thing that sits beneath all of that. The thing the world becomes more vivid when you touch.',
    'The particles float around you like ideas arriving before language.',
    'You take a step forward. The call grows stronger.',
    'Your story begins now.',
  ],
  estimatedReadSeconds: 90,
);

/// CHAPTER 2: THE CONFLICT
/// Theme: Darkness, Truth, Confrontation
/// Emotion: Discomfort + Liberation
/// Music: conflict.mp3 (Industrial ambient, Trent Reznor-style)
/// Colors: Dark crimson → Charcoal
const chapterTwoProse = ChapterProse(
  title: 'Chapter II',
  subtitle: 'The Conflict',
  prose: '''There is a truth you rarely say out loud.

The truth that you have been living beneath yourself.

You have learned how to appear strong, how to stay busy, how to push through days without asking why they repeat. You have carried expectations that were handed to you, not chosen. You have walked paths that were safer than they were fulfilling.

There is fatigue behind your eyes that comes from fighting the wrong battles. There is a hunger inside you that has been ignored for years.

When you are honest with yourself, you know the conflict is not between you and the world. It is between you and the version of yourself you were meant to become.

Every time you felt stuck, it was not because you lacked ability. It was because you were climbing ladders that leaned on the wrong walls. You were chasing goals that did not belong to you. You were trying to satisfy expectations that had nothing to do with your purpose.

This chapter exists to bring truth to the surface. Truth often feels like discomfort first. Discomfort is the doorway to direction.

The screen darkens. You feel the weight of decisions you avoided. The ghosts of opportunities you talked yourself out of. The moments you knew you were meant for more and stayed still anyway.

The conflict is simple and brutal. You know there is more in you than what you have been living.

The question is whether you will face that honestly.''',
  proseParagraphs: [
    'There is a truth you rarely say out loud.',
    'The truth that you have been living beneath yourself.',
    'You have learned how to appear strong, how to stay busy, how to push through days without asking why they repeat. You have carried expectations that were handed to you, not chosen. You have walked paths that were safer than they were fulfilling.',
    'There is fatigue behind your eyes that comes from fighting the wrong battles. There is a hunger inside you that has been ignored for years.',
    'When you are honest with yourself, you know the conflict is not between you and the world. It is between you and the version of yourself you were meant to become.',
    'Every time you felt stuck, it was not because you lacked ability. It was because you were climbing ladders that leaned on the wrong walls. You were chasing goals that did not belong to you. You were trying to satisfy expectations that had nothing to do with your purpose.',
    'This chapter exists to bring truth to the surface. Truth often feels like discomfort first. Discomfort is the doorway to direction.',
    'The screen darkens. You feel the weight of decisions you avoided. The ghosts of opportunities you talked yourself out of. The moments you knew you were meant for more and stayed still anyway.',
    'The conflict is simple and brutal. You know there is more in you than what you have been living.',
    'The question is whether you will face that honestly.',
  ],
  estimatedReadSeconds: 75,
);

/// CHAPTER 3: THE MIRROR
/// Theme: Reflection, Clarity, Self-Recognition
/// Emotion: Honest + Empowering
/// Music: mirror.mp3 (Crystal tones, singing bowls)
/// Colors: Silver → Ice blue → Pearl white
const chapterThreeProse = ChapterProse(
  title: 'Chapter III',
  subtitle: 'The Mirror',
  prose: '''You stand before a surface that shows you more than your face.

It shows patterns. It shows habits. It shows the stories you tell yourself when no one is listening.

The mirror does not accuse you. It reveals you.

You see the strengths you forget to acknowledge. The patterns you pretend you do not repeat. The fears that disguise themselves as logic. The dreams you minimize because admitting them would require courage you have been postponing.

Future You speaks softly here. Not as a critic, but as someone who knows exactly what you are capable of.

"You do not need to be perfect. You just need to tell the truth. Who are you when nobody is watching? What do you think about when your mind wanders? What pain shaped you? What desire keeps coming back no matter how many times you push it away?"

The mirror waits for your honesty.

The reflection becomes clearer as you tell the truth.

This is the moment you meet yourself without the armour.''',
  proseParagraphs: [
    'You stand before a surface that shows you more than your face.',
    'It shows patterns. It shows habits. It shows the stories you tell yourself when no one is listening.',
    'The mirror does not accuse you. It reveals you.',
    'You see the strengths you forget to acknowledge. The patterns you pretend you do not repeat. The fears that disguise themselves as logic. The dreams you minimize because admitting them would require courage you have been postponing.',
    'Future You speaks softly here. Not as a critic, but as someone who knows exactly what you are capable of.',
    '"You do not need to be perfect. You just need to tell the truth. Who are you when nobody is watching? What do you think about when your mind wanders? What pain shaped you? What desire keeps coming back no matter how many times you push it away?"',
    'The mirror waits for your honesty.',
    'The reflection becomes clearer as you tell the truth.',
    'This is the moment you meet yourself without the armour.',
  ],
  estimatedReadSeconds: 65,
);

/// Get prose for chapter number (1-7)
ChapterProse getChapterProse(int chapterNumber) {
  switch (chapterNumber) {
    case 1:
      return chapterOneProse;
    case 2:
      return chapterTwoProse;
    case 3:
      return chapterThreeProse;
    // TODO: Add chapters 4-7
    default:
      return chapterOneProse;
  }
}

