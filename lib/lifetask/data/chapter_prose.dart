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

/// CHAPTER 4: THE MENTOR
/// Theme: Wisdom, Guidance, Future-You Voice
/// Emotion: Grounded + Inspired
/// Music: mentor.mp3 (Orchestral strings + choir)
/// Colors: Deep purples → Gold
const chapterFourProse = ChapterProse(
  title: 'Chapter IV',
  subtitle: 'The Mentor',
  prose: '''A voice arrives, but it feels like it is coming from inside your chest rather than the air.

It is older. It is you, years ahead. Not the broken version. The fulfilled one.

The future you speaks: "I have seen what you become when you commit to the right thing. The version of you I am is not built from luck. I am built from choices. I am built from the day you stopped pretending you did not know what mattered to you."

This voice is patient but firm.

"Your life shifts the moment you stop running from your task. The moment you stop negotiating with your potential. Your purpose is not hidden from you. It is the pattern that keeps returning. It is the skill you cannot stop improving. It is the problem you cannot stand to see unsolved. It is the kind of work that makes time disappear."

The mentor does not give you the answer. The mentor makes you remember that you already had it.

You feel the weight of years you have not yet lived guiding you toward years you will. This is not fantasy. This is recognition.

The path has always been there. You have just been looking past it, waiting for permission you do not need.''',
  proseParagraphs: [
    'A voice arrives, but it feels like it is coming from inside your chest rather than the air.',
    'It is older. It is you, years ahead. Not the broken version. The fulfilled one.',
    'The future you speaks: "I have seen what you become when you commit to the right thing. The version of you I am is not built from luck. I am built from choices. I am built from the day you stopped pretending you did not know what mattered to you."',
    'This voice is patient but firm.',
    '"Your life shifts the moment you stop running from your task. The moment you stop negotiating with your potential. Your purpose is not hidden from you. It is the pattern that keeps returning. It is the skill you cannot stop improving. It is the problem you cannot stand to see unsolved. It is the kind of work that makes time disappear."',
    'The mentor does not give you the answer. The mentor makes you remember that you already had it.',
    'You feel the weight of years you have not yet lived guiding you toward years you will. This is not fantasy. This is recognition.',
    'The path has always been there. You have just been looking past it, waiting for permission you do not need.',
  ],
  estimatedReadSeconds: 70,
);

/// CHAPTER 5: THE TASK
/// Theme: Decision, Diverging Paths, Clarity
/// Emotion: Determined + Focused
/// Music: task.mp3 (Drumbeat + forge sounds)
/// Colors: Orange → Amber → Fire
const chapterFiveProse = ChapterProse(
  title: 'Chapter V',
  subtitle: 'The Task',
  prose: '''A sentence forms like a key turning in a lock.

Your life's task is the intersection of three truths: What you cannot stop thinking about. What you do better than most without forcing it. What the world becomes better at the moment you touch it.

Your task is not vague. It is not abstract. It is specific. It is the work you are built for.

You feel something click into place. Not a surprise. A recognition. You have known this for a long time. This chapter gives you permission to admit it.

Three paths diverge before you. Each one is real. Each one is possible. The question is not which one is safe. The question is which one you would regret not taking.

Purpose means nothing without direction. Direction means nothing without choice. Choice means nothing without commitment.

You see the forge in front of you. The heat, the hammer, the sparks. This is where you shape what matters. This is where you stop waiting and start building.

The task is clear now. All that remains is the courage to begin.''',
  proseParagraphs: [
    'A sentence forms like a key turning in a lock.',
    'Your life\'s task is the intersection of three truths: What you cannot stop thinking about. What you do better than most without forcing it. What the world becomes better at the moment you touch it.',
    'Your task is not vague. It is not abstract. It is specific. It is the work you are built for.',
    'You feel something click into place. Not a surprise. A recognition. You have known this for a long time. This chapter gives you permission to admit it.',
    'Three paths diverge before you. Each one is real. Each one is possible. The question is not which one is safe. The question is which one you would regret not taking.',
    'Purpose means nothing without direction. Direction means nothing without choice. Choice means nothing without commitment.',
    'You see the forge in front of you. The heat, the hammer, the sparks. This is where you shape what matters. This is where you stop waiting and start building.',
    'The task is clear now. All that remains is the courage to begin.',
  ],
  estimatedReadSeconds: 60,
);

/// CHAPTER 6: THE PATH
/// Theme: Commitment, Ritual, Daily Practice
/// Emotion: Resolved + Peaceful
/// Music: path.mp3 (Acoustic guitar + nature)
/// Colors: Deep greens → Earth tones
const chapterSixProse = ChapterProse(
  title: 'Chapter VI',
  subtitle: 'The Path',
  prose: '''Purpose means nothing without discipline. Direction means nothing without ritual. Identity means nothing without practice.

The path is where you turn understanding into movement.

You see a map forming around you, built from small, sacred commitments. Tuesdays at 10. Mornings at 7. Thirty minutes of study. Forty minutes of training. A daily creative push. A weekly reflection that resets your compass. A monthly challenge that forces growth.

These are not tasks. These are rituals. Each one is a brick in the life you are building.

The path is not linear. It curves. It climbs. It asks more of you than you knew you had. But it is yours. Every step is chosen. Every choice compounds.

You plant a seed here. Not for harvest tomorrow, but for shade ten years from now. This is the patience of purpose. This is the faith of mastery.

The path is simple. Not easy. Simple. Consistency is the currency that buys the life you want.

You step forward. The ground is solid. The direction is clear. The journey has begun.''',
  proseParagraphs: [
    'Purpose means nothing without discipline. Direction means nothing without ritual. Identity means nothing without practice.',
    'The path is where you turn understanding into movement.',
    'You see a map forming around you, built from small, sacred commitments. Tuesdays at 10. Mornings at 7. Thirty minutes of study. Forty minutes of training. A daily creative push. A weekly reflection that resets your compass. A monthly challenge that forces growth.',
    'These are not tasks. These are rituals. Each one is a brick in the life you are building.',
    'The path is not linear. It curves. It climbs. It asks more of you than you knew you had. But it is yours. Every step is chosen. Every choice compounds.',
    'You plant a seed here. Not for harvest tomorrow, but for shade ten years from now. This is the patience of purpose. This is the faith of mastery.',
    'The path is simple. Not easy. Simple. Consistency is the currency that buys the life you want.',
    'You step forward. The ground is solid. The direction is clear. The journey has begun.',
  ],
  estimatedReadSeconds: 70,
);

/// CHAPTER 7: THE PROMISE
/// Theme: Legacy, Continuation, Infinite Horizon
/// Emotion: Transcendent + Hopeful
/// Music: promise.mp3 (Piano + orchestra swell)
/// Colors: Golden hour → Dawn → Infinite sky
const chapterSevenProse = ChapterProse(
  title: 'Chapter VII',
  subtitle: 'The Promise',
  prose: '''A final truth rises slowly, like light returning after darkness.

Your future self speaks again, quieter now. "We kept the promise. Not in one grand moment. In small, relentless decisions. In the days we felt strong and the days we felt nothing at all. We did not become who we wanted to be. We became who we decided to be."

You feel the weight of everything clicking together. The call. The conflict. The mirror. The mentor. The task. The path. All of it leads to the promise.

A life lived on purpose. A life aligned. A life that feels like it fits.

The horizon stretches endlessly. Not because the journey ends, but because it continues. Every day a new choice. Every week a new chapter. Every year a deeper mastery.

This is not the end. This is the beginning you have been searching for.

You look ahead and see not a destination, but a direction. Not a finish line, but a rhythm. Not perfection, but progress that never stops.

The sun rises. The birds take flight. The world wakes to possibility.

Your story begins now.''',
  proseParagraphs: [
    'A final truth rises slowly, like light returning after darkness.',
    'Your future self speaks again, quieter now. "We kept the promise. Not in one grand moment. In small, relentless decisions. In the days we felt strong and the days we felt nothing at all. We did not become who we wanted to be. We became who we decided to be."',
    'You feel the weight of everything clicking together. The call. The conflict. The mirror. The mentor. The task. The path. All of it leads to the promise.',
    'A life lived on purpose. A life aligned. A life that feels like it fits.',
    'The horizon stretches endlessly. Not because the journey ends, but because it continues. Every day a new choice. Every week a new chapter. Every year a deeper mastery.',
    'This is not the end. This is the beginning you have been searching for.',
    'You look ahead and see not a destination, but a direction. Not a finish line, but a rhythm. Not perfection, but progress that never stops.',
    'The sun rises. The birds take flight. The world wakes to possibility.',
    'Your story begins now.',
  ],
  estimatedReadSeconds: 75,
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
    case 4:
      return chapterFourProse;
    case 5:
      return chapterFiveProse;
    case 6:
      return chapterSixProse;
    case 7:
      return chapterSevenProse;
    default:
      return chapterOneProse;
  }
}

