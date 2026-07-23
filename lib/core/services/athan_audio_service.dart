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

  AthanAudioService._internal();

  bool get isPlaying => _isPlaying;

  /// Play the specified athan audio file from assets.
  /// Example: 'assets/audio/adhan_abdulbasit.mp3'
  Future<void> playAthan(String audioAssetPath) async {
    if (_isPlaying) {
      await stopAthan();
    }

    try {
      _isPlaying = true;

      // Configure audio session to use alarm stream
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          usage: AndroidAudioUsage.alarm,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      ));

      await _player.setVolume(1.0);
      await _player.setAsset(audioAssetPath);

      // Listen for completion
      _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _isPlaying = false;
          _player.stop();
        }
      });

      await _player.play();
    } catch (e) {
      debugPrint('Error playing Athan: $e');
      _isPlaying = false;
    }
  }

  /// Stop the currently playing athan immediately.
  Future<void> stopAthan() async {
    _fadeTimer?.cancel();
    _isPlaying = false;
    await _player.stop();
  }

  /// Fade out the volume smoothly over the specified duration and then stop.
  Future<void> fadeOutAndStop(
      {Duration duration = const Duration(seconds: 3)}) async {
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
    _player.dispose();
  }
}
