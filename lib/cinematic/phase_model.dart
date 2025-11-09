enum FuturePhase {
  call,
  conflict,
  mirror,
  mentor,
  task,
  path,
  promise;

  String get title {
    switch (this) {
      case FuturePhase.call:
        return 'Chapter I — The Call';
      case FuturePhase.conflict:
        return 'Chapter II — The Conflict';
      case FuturePhase.mirror:
        return 'Chapter III — The Mirror';
      case FuturePhase.mentor:
        return 'Chapter IV — The Mentor';
      case FuturePhase.task:
        return 'Chapter V — The Task';
      case FuturePhase.path:
        return 'Chapter VI — The Path';
      case FuturePhase.promise:
        return 'Chapter VII — The Promise';
    }
  }

  String get musicFile {
    switch (this) {
      case FuturePhase.call:
      case FuturePhase.mentor:
      case FuturePhase.path:
        return 'assets/cinema/music/hope.mp3';
      case FuturePhase.conflict:
      case FuturePhase.mirror:
        return 'assets/cinema/music/conflict.mp3';
      case FuturePhase.task:
      case FuturePhase.promise:
        return 'assets/cinema/music/promise.mp3';
    }
  }

  String get phaseId => name;
}

