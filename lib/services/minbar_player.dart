import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../models/minbar_models.dart';
import 'minbar_download_service.dart';
import 'dart:developer' as dev;

class MinbarPlayer {
  static final AudioPlayer player = AudioPlayer();
  
  static final ValueNotifier<MinbarAudioItem?> currentItemNotifier = ValueNotifier<MinbarAudioItem?>(null);
  static final ValueNotifier<String?> currentAuthorNotifier = ValueNotifier<String?>(null);
  static final ValueNotifier<Duration?> sleepTimerNotifier = ValueNotifier<Duration?>(null);

  static List<MinbarAudioItem> _currentPlaylist = [];
  static Timer? _sleepTimer;

  static void init() {
    // Listen to index changes to update current item automatically
    player.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < _currentPlaylist.length) {
        currentItemNotifier.value = _currentPlaylist[index];
      }
    });
  }

  /// Play a single item or start a playlist
  static Future<void> playPlaylist(List<MinbarAudioItem> playlist, int initialIndex, String authorName) async {
    _currentPlaylist = List<MinbarAudioItem>.from(playlist);
    currentAuthorNotifier.value = authorName;
    currentItemNotifier.value = playlist[initialIndex];

    try {
      await player.stop();

      final audioSources = <AudioSource>[];
      for (var item in playlist) {
        final localPath = await MinbarDownloadService.instance.getLocalPath(item.id);
        
        final mediaItem = MediaItem(
          id: item.id,
          album: authorName,
          title: item.title,
        );

        if (localPath != null) {
          audioSources.add(AudioSource.uri(Uri.file(localPath), tag: mediaItem));
        } else {
          audioSources.add(AudioSource.uri(Uri.parse(item.url), tag: mediaItem));
        }
      }

      final concatenatingAudioSource = ConcatenatingAudioSource(
        children: audioSources,
      );

      await player.setAudioSource(
        concatenatingAudioSource,
        initialIndex: initialIndex,
      );
      
      await player.play();
    } catch (e) {
      dev.log("Error playing audio playlist: $e", name: 'MinbarPlayer');
    }
  }

  static Future<void> togglePlay() async {
    if (currentItemNotifier.value == null) return;
    try {
      if (player.playing) {
        await player.pause();
      } else {
        await player.play();
      }
    } catch (e) {
      dev.log("Error toggling play/pause: $e", name: 'MinbarPlayer');
    }
  }

  static Future<void> seek(Duration position) async {
    try {
      await player.seek(position);
    } catch (e) {
      dev.log("Error seeking: $e", name: 'MinbarPlayer');
    }
  }

  static Future<void> playNext() async {
    try {
      if (player.hasNext) {
        await player.seekToNext();
      }
    } catch (e) {
      dev.log("Error playing next: $e", name: 'MinbarPlayer');
    }
  }

  static Future<void> playPrevious() async {
    try {
      if (player.hasPrevious) {
        await player.seekToPrevious();
      }
    } catch (e) {
      dev.log("Error playing previous: $e", name: 'MinbarPlayer');
    }
  }

  static Future<void> setLoopMode(LoopMode mode) async {
    try {
      await player.setLoopMode(mode);
    } catch (e) {
      dev.log("Error setting loop mode: $e", name: 'MinbarPlayer');
    }
  }

  static void setCustomSleepTimer(Duration? duration) {
    _sleepTimer?.cancel();
    sleepTimerNotifier.value = duration;

    if (duration != null) {
      _sleepTimer = Timer(duration, () {
        stop();
        sleepTimerNotifier.value = null;
      });
    }
  }

  static Future<void> stop() async {
    try {
      await player.stop();
      _sleepTimer?.cancel();
      sleepTimerNotifier.value = null;
      currentItemNotifier.value = null;
      currentAuthorNotifier.value = null;
      _currentPlaylist.clear();
    } catch (e) {
      dev.log("Error stopping audio: $e", name: 'MinbarPlayer');
    }
  }
}
