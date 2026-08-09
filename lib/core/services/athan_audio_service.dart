// lib/core/services/athan_audio_service.dart
// ─────────────────────────────────────────────────────────────────────────────
// AthanAudioService — foreground (in-app) Athan playback only.
//
// Background / killed-app Athan is now handled entirely by the native
// AthanForegroundService (Kotlin), which uses MediaPlayer + WakeLock.
//
// This service is used when the user is actively in the app and wants to
// preview an Athan or when the app is in the foreground when a prayer fires.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

class AthanAudioService {
  static final AthanAudioService _instance = AthanAudioService._internal();
  factory AthanAudioService() => _instance;

  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Timer? _fadeTimer;
  StreamSubscription? _stateSubscription;

  AthanAudioService._internal() {
    _stateSubscription = _player.playerStateStream.listen((state) async {
      if (state.processingState == ProcessingState.completed) {
        debugPrint('[AthanAudioService] Playback completed naturally.');
        _isPlaying = false;
        await _player.stop();
        try {
          final session = await AudioSession.instance;
          await session.setActive(false);
        } catch (_) {}
      }
    });
  }

  bool get isPlaying => _isPlaying;

  /// Plays the Athan audio in-app (foreground only).
  ///
  /// [audioPath] can be:
  ///  - An asset path: "assets/audio/Takbir_mishary_alafasy.mp3"
  ///  - An absolute file path: "/data/user/0/.../adhan_mishary.mp3"
  ///
  /// [durationSeconds] optionally caps playback. 0 or null = play full file.
  Future<void> playAthan(String audioPath, {int? durationSeconds}) async {
    if (_isPlaying) {
      debugPrint('[AthanAudioService] Already playing. Ignoring request.');
      return;
    }

    try {
      _isPlaying = true;

      // Configure audio session for alarm-priority playback
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.sonification,
          usage: AndroidAudioUsage.alarm,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      ));

      if (await session.setActive(true)) {
        debugPrint('[AthanAudioService] Audio focus gained.');
      }

      await _player.setVolume(1.0);

      // Load audio source
      bool loaded = false;
      try {
        if (audioPath.startsWith('assets/')) {
          await _player.setAsset(audioPath);
        } else {
          await _player.setFilePath(audioPath);
        }
        loaded = true;
      } catch (e) {
        debugPrint('[AthanAudioService] Failed to load $audioPath: $e. Using default.');
        try {
          await _player.setAsset('assets/audio/Takbir_mishary_alafasy.mp3');
          loaded = true;
        } catch (e2) {
          debugPrint('[AthanAudioService] Default asset also failed: $e2');
        }
      }

      if (!loaded) {
        _isPlaying = false;
        await session.setActive(false);
        return;
      }

      // Completer that resolves when playback finishes
      final completer = Completer<void>();
      StreamSubscription? localSub;

      localSub = _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (!completer.isCompleted) completer.complete();
        }
      });

      _player.play().catchError((e) async {
        debugPrint('[AthanAudioService] Play error: $e');
        _isPlaying = false;
        await session.setActive(false);
        if (!completer.isCompleted) completer.complete();
      });

      // Optional duration cap
      if (durationSeconds != null && durationSeconds > 0) {
        final fadeOutAt = durationSeconds > 2 ? durationSeconds - 2 : durationSeconds;
        Timer(Duration(seconds: fadeOutAt), () {
          if (_isPlaying) fadeOutAndStop();
        });
      }

      await completer.future;
      await localSub.cancel();
      _isPlaying = false;

    } catch (e) {
      debugPrint('[AthanAudioService] Critical error: $e');
      _isPlaying = false;
      try {
        final session = await AudioSession.instance;
        await session.setActive(false);
      } catch (_) {}
    }
  }

  /// Stop the Athan immediately.
  Future<void> stopAthan() async {
    _fadeTimer?.cancel();
    _isPlaying = false;
    try {
      await _player.stop();
      final session = await AudioSession.instance;
      await session.setActive(false);
    } catch (e) {
      debugPrint('[AthanAudioService] Error stopping: $e');
    }
  }

  /// Smoothly fade out over [duration] then stop.
  Future<void> fadeOutAndStop({Duration duration = const Duration(seconds: 2)}) async {
    if (!_isPlaying) return;

    const stepDuration = Duration(milliseconds: 100);
    final steps = duration.inMilliseconds ~/ stepDuration.inMilliseconds;
    if (steps <= 0) {
      await stopAthan();
      return;
    }

    final volumeStep = _player.volume / steps;
    _fadeTimer?.cancel();
    _fadeTimer = Timer.periodic(stepDuration, (timer) async {
      final newVolume = _player.volume - volumeStep;
      if (newVolume <= 0.05) {
        timer.cancel();
        await stopAthan();
      } else {
        await _player.setVolume(newVolume);
      }
    });
  }

  void dispose() {
    _fadeTimer?.cancel();
    _stateSubscription?.cancel();
    _player.dispose();
  }
}
