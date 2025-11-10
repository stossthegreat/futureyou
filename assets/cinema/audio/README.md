# Cinematic Audio Assets

## TTS Narration (ElevenLabs)

Place your ElevenLabs-generated TTS audio files here:

- `chapter_1_call.mp3` - The Call narration
- `chapter_2_conflict.mp3` - The Conflict narration
- `chapter_3_mirror.mp3` - The Mirror narration
- `chapter_4_mentor.mp3` - The Mentor narration
- `chapter_5_task.mp3` - The Task narration
- `chapter_6_path.mp3` - The Path narration
- `chapter_7_promise.mp3` - The Promise narration

## Background Music

- `hope.mp3` - Hopeful, awakening (Chapters 1, 4, 7)
- `conflict.mp3` - Dark, introspective (Chapter 2)
- `reflection.mp3` - Thoughtful, contemplative (Chapters 3, 5, 6)

## Format Requirements

- **Format**: MP3 or M4A
- **Sample Rate**: 44.1kHz recommended
- **Bitrate**: 128kbps or higher
- **Mono/Stereo**: Either (mono recommended for voice)

## Usage in Flutter

```dart
import 'package:audioplayers/audioplayers.dart';

final player = AudioPlayer();
await player.play(AssetSource('cinema/audio/chapter_1_call.mp3'));
```

