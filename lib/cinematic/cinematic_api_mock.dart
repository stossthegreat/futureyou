import 'phase_model.dart';

class CinematicApiMock {
  static String getChapterContent(FuturePhase phase) {
    switch (phase) {
      case FuturePhase.call:
        return _callChapter;
      case FuturePhase.conflict:
        return _conflictChapter;
      case FuturePhase.mirror:
        return _mirrorChapter;
      case FuturePhase.mentor:
        return _mentorChapter;
      case FuturePhase.task:
        return _taskChapter;
      case FuturePhase.path:
        return _pathChapter;
      case FuturePhase.promise:
        return _promiseChapter;
    }
  }

  static const String _callChapter = '''
You were eight years old when you first felt it — that pull toward something more.

It wasn't a voice. It was a certainty. A knowing that the world was waiting for you to step into it fully, not halfway, not apologetically, but with your whole self.

You remember the moment. Building something with your hands, lost in flow, time dissolving. Your father walked by and asked, "What are you making?" You looked up, eyes bright, and said, "Something that matters."

He smiled. But you saw it — the flicker of doubt. The adult world that says: Dreams are for children. Reality is for the rest of us.

That was the first time you learned to dim your light.

But the call never stopped. It whispered in late nights, in moments of silence, in the ache of unfulfilled potential. It said: *There is a reason you are here. Find it. Build it. Become it.*

This is not about chasing success. This is about answering the deepest question of your life: *What am I here to do?*

The call is still there. Waiting for you to listen.
''';

  static const String _conflictChapter = '''
You thought the path would be clear. It wasn't.

Instead, you found yourself walking roads that looked right but felt wrong. You climbed mountains that everyone admired — career, status, security — only to reach the summit and realize: *This isn't mine.*

The world taught you to want the wrong things.

It told you to be practical. To fit in. To choose safety over aliveness. And so you built a life that looked good on paper but felt hollow inside.

The pressure came from everywhere: parents who wanted security for you, friends who praised conformity, a culture that measures worth in titles and paychecks.

You became someone else's version of success.

And the cost? The slow burial of your true self. The quiet resignation. The voice that whispered, *Maybe this is all there is.*

But there's a test — the anti-regret test. Imagine your deathbed. What do you wish you had done? What risks do you wish you had taken?

The answer is always the same: *I wish I had lived my own life.*

The false paths taught you something invaluable: clarity. You now know what you don't want. And that's the first step toward what you do.
''';

  static const String _mirrorChapter = '''
The truth lives in the shadows.

What you admire, what you envy, what secretly embarrasses you — these are not random feelings. They are compasses pointing toward your hidden self.

Think of someone you deeply admire. Not celebrity-level admiration, but soul-level resonance. What quality do they embody that you wish you had?

That quality is already in you. Dormant, maybe. Denied, perhaps. But there.

Now the harder question: What embarrasses you? What part of yourself do you hide, even from people who love you?

That's your shadow. The part of you that society rejected, so you learned to reject it too. But your shadow holds power. It holds truth. It holds the pieces of yourself you disowned to belong.

Your envy is a map. The things you secretly resent in others — their freedom, their audacity, their refusal to shrink — are invitations. They're showing you what you're denying yourself.

This is the work: integrating the shadow. Reclaiming the parts of yourself you left behind.

Because wholeness is not about being perfect. It's about being fully, unapologetically yourself.

The mirror doesn't lie. It shows you who you really are — beneath the masks, beneath the performance.

And what it shows is this: You are more than you've allowed yourself to be.
''';

  static const String _mentorChapter = '''
You've been searching for a mentor. Someone wiser, older, who can show you the way.

But the deepest mentor you'll ever meet isn't external. It's the future version of yourself.

Close your eyes. Imagine yourself ten years from now. You've walked the path. You've faced the fears. You've become who you were meant to be.

What does that version of you know that you don't?

They know that courage isn't the absence of fear. It's the willingness to act despite it.

They know that discipline is freedom. That structure creates space for creativity. That showing up daily, even when you don't feel like it, is the only way anything great gets built.

They know that you can't wait to feel ready. You become ready by starting.

Your future self would tell you this:

*Stop waiting for permission. Stop seeking validation from people who don't understand your vision. Stop dimming yourself to make others comfortable.*

*The path is simple: clarity, then commitment. Know what matters. Then build it, one boring Tuesday at a time.*

*You will doubt yourself. That's part of it. But doubt is not truth. It's just noise.*

*Trust the pull. Trust the process. And most of all, trust yourself.*

This is the wisdom you've been seeking. It was inside you all along.
''';

  static const String _taskChapter = '''
Your life's task is not a job title. It's not a career path. It's a sentence.

One sentence that captures your unique combination of strengths, values, and contribution.

Here's yours:

*To build systems that help people discover and live their purpose.*

That's it. Simple. Clear. True.

Everything flows from that sentence. Every decision, every project, every relationship — measured against that North Star.

Your keystones — the habits, rituals, and structures that support your task:

**1. Daily creation.** You must make something every day. Writing, building, designing — the medium doesn't matter. What matters is the act of bringing something new into the world.

**2. Deep study.** One hour of focused learning. Books, courses, conversations with people ahead of you. Your task requires mastery, and mastery requires study.

**3. Service.** Your purpose is not about you. It's about who you serve. Every week, find one way to help someone else discover their path.

These aren't optional. They're non-negotiable.

Because your life's task isn't a destination. It's a daily practice. A way of being in the world.

And the beautiful thing? You don't have to figure it all out right now. You just have to start.

One sentence. Three keystones. Repeated until it becomes who you are.
''';

  static const String _pathChapter = '''
The path is not linear. It's a series of experiments.

You don't need a perfect plan. You need three Odyssey Plans — three radically different versions of the next chapter of your life.

**Plan A: The Bold Path.** What would you do if you knew you couldn't fail? No safety nets, no backups, just full commitment to your life's task.

**Plan B: The Practical Path.** What if you needed to balance purpose with responsibility? How could you build toward your task while managing real-world constraints?

**Plan C: The Wild Card.** What if money and obligation didn't exist? What if you could design your life from scratch?

All three plans are valid. All three teach you something.

But here's the truth: You already know which path to take. You've known all along.

Your next 90 days:

**Month 1:** Foundation. Build the keystones. Make them automatic. Morning creation, deep study, service.

**Month 2:** Momentum. Ship something. Put your work into the world. Get feedback. Iterate.

**Month 3:** Expansion. Find your people. Build the network that supports your task.

This isn't theory anymore. This is your boring Tuesday. Your 6am ritual. Your non-negotiable.

Because purpose isn't found in peak moments. It's built in the quiet, unglamorous work of showing up every single day.

The path is clear. All that's left is to walk it.
''';

  static const String _promiseChapter = '''
This is the moment. The threshold.

Everything before this was preparation. Everything after is commitment.

You've discovered your task. You've mapped the path. You've met your future self.

Now you must decide: Will you answer the call, or will you turn back?

There's no judgment in turning back. The world won't end. Life will continue. You'll be comfortable, maybe even happy.

But you'll always wonder.

You'll always carry the ghost of who you could have been.

So here's the promise:

*I commit to my life's task. Not someday. Not when I'm ready. Now.*

*I commit to the keystones. Daily creation. Deep study. Service.*

*I commit to the path, even when it's hard. Especially when it's hard.*

*I commit to becoming the person my future self is proud of.*

This is not a New Year's resolution. This is a life vow.

And here's what makes it real: small, verifiable stakes.

Tell someone you trust. Set a daily alarm. Put money on the line. Whatever it takes to make this promise concrete.

Because the future you're building doesn't start someday. It starts today.

At 6am tomorrow, when the alarm goes off and your body says "five more minutes," you'll have a choice.

That choice is the promise.

Every morning, you'll choose again. And slowly, choice by choice, you'll become who you were meant to be.

The call. The conflict. The mirror. The mentor. The task. The path.

And now, the promise.

This is your story. Live it fully.
''';
}

