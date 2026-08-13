import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../models/muezzin_model.dart';

class MuezzinManager {
  static final MuezzinManager _instance = MuezzinManager._internal();
  factory MuezzinManager() => _instance;
  MuezzinManager._internal();

  List<MuezzinModel> _muezzins = [];
  List<String> _favorites = [];

  List<MuezzinModel> get muezzins => _muezzins;
  List<String> get favorites => _favorites;

  Future<void> init() async {
    final String jsonString = await rootBundle.loadString('assets/muezzins.json');
    final List<dynamic> jsonList = json.decode(jsonString);
    _muezzins = jsonList.map((json) => MuezzinModel.fromJson(json)).toList();

    final prefs = await SharedPreferences.getInstance();
    _favorites = prefs.getStringList('muezzin_favorites') ?? [];
  }

  bool isFavorite(String id) => _favorites.contains(id);

  Future<void> toggleFavorite(String id) async {
    if (_favorites.contains(id)) {
      _favorites.remove(id);
    } else {
      _favorites.add(id);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('muezzin_favorites', _favorites);
  }

  Future<String> getAudioPath(MuezzinModel muezzin) async {
    if (muezzin.isLocal) {
      return muezzin.url;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${muezzin.id}.mp3');
      if (await file.exists()) {
        return file.path;
      }
      // If it's remote but not downloaded, we must return a failure or default.
      // This path is returned when attempting to play.
      return 'android.resource://com.umer.quranzone/raw/takbir_mishary_alafasy';
    }
  }

  Future<bool> isDownloaded(MuezzinModel muezzin) async {
    if (muezzin.isLocal) return true;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${muezzin.id}.mp3');
    return await file.exists();
  }

  Future<void> downloadMuezzin(MuezzinModel muezzin, Function(double) onProgress) async {
    if (muezzin.isLocal) return;

    final dir = await getApplicationDocumentsDirectory();
    final savePath = '${dir.path}/${muezzin.id}.mp3';
    
    final dio = Dio();
    try {
      await dio.download(
        muezzin.url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
      );
    } catch (e) {
      // Clean up corrupt file
      final file = File(savePath);
      if (await file.exists()) await file.delete();
      rethrow;
    }
  }

  Future<void> deleteDownload(MuezzinModel muezzin) async {
    if (muezzin.isLocal) return;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${muezzin.id}.mp3');
    if (await file.exists()) {
      await file.delete();
    }
  }
}
