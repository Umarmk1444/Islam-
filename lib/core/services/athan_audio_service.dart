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
        debugPrint('Athan audio playback completed natively.');
        _isPlaying = false;
        await _player.stop();
        final session = await AudioSession.instance;
        await session.setActive(false);
      }
    });
  }

  bool get isPlaying => _isPlaying;

  Future<void> playAthan(String audioPath) async {
    if (_isPlaying) {
      debugPrint('Athan is already playing. Rejecting overlapping playback request.');
      return;
    }

    try {
      _isPlaying = true;

      // Request and configure audio session to explicitly manage audio focus
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

      // Attempt to activate the session
      if (await session.setActive(true)) {
        debugPrint('Audio focus gained successfully.');
      }

      await _player.setVolume(1.0);
      try {
        if (audioPath.startsWith('assets/')) {
          await _player.setAsset(audioPath);
        } else {
          await _player.setFilePath(audioPath);
        }
      } catch (assetError) {
        debugPrint('Failed to load asset $audioPath: $assetError. Falling back to default Adhan.');
        await _player.setAsset('assets/audio/adhan_abdulbasit.mp3');
      }

      // We wait for the stream listener we set up in the constructor to handle completion.
      // But since playAthan is awaited in the isolate to keep it alive, we should return a Future
      // that completes when the playback is truly done. We can listen to the stream locally for this, 
      // but only wait for completion or error, then cancel the local subscription.

      final completer = Completer<void>();
      StreamSubscription? localSub;
      
      localSub = _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed || state.processingState == ProcessingState.idle) {
           if (!completer.isCompleted) completer.complete();
        }
      });

      _player.play().catchError((e) async {
         debugPrint('Athan play error caught during playback: $e. Attempting fallback play.');
         try {
             await _player.setAsset('assets/audio/adhan_abdulbasit.mp3');
             await _player.play();
         } catch (fallbackErr) {
             debugPrint('CRITICAL: Fallback playback also failed: $fallbackErr');
             _isPlaying = false;
             await session.setActive(false);
             if (!completer.isCompleted) completer.complete();
         }
      });
      
      await completer.future;
      await localSub.cancel();

    } catch (e) {
      debugPrint('CRITICAL: Error playing Athan audio: $e');
      // Final desperation fallback
      try {
          await _player.setAsset('assets/audio/adhan_abdulbasit.mp3');
          await _player.play();
      } catch (_) {
          _isPlaying = false;
      }
    }
  }

  /// Stop the currently playing athan immediately.
  Future<void> stopAthan() async {
    _fadeTimer?.cancel();
    _isPlaying = false;
    try {
      await _player.stop();
      final session = await AudioSession.instance;
      await session.setActive(false);
    } catch (e) {
      debugPrint('Error stopping Athan: $e');
    }
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
