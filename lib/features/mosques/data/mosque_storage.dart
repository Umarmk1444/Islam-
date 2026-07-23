import 'package:shared_preferences/shared_preferences.dart';
import 'mosque_model.dart';

class MosqueStorage {
  static const String _favoritesKey = 'favorite_mosques';
  static const String _recentKey = 'recent_mosques';
  static const int _maxRecent = 10;

  Future<List<Mosque>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> items = prefs.getStringList(_favoritesKey) ?? [];
    return items.map((e) => Mosque.fromJson(e)).toList();
  }

  Future<void> toggleFavorite(Mosque mosque) async {
    final prefs = await SharedPreferences.getInstance();
    List<Mosque> favorites = await getFavorites();
    
    if (favorites.contains(mosque)) {
      favorites.remove(mosque);
    } else {
      mosque.isFavorite = true;
      favorites.add(mosque);
    }
    
    await prefs.setStringList(
      _favoritesKey, 
      favorites.map((e) => e.toJson()).toList()
    );
  }

  Future<List<Mosque>> getRecents() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> items = prefs.getStringList(_recentKey) ?? [];
    return items.map((e) => Mosque.fromJson(e)).toList();
  }

  Future<void> addRecent(Mosque mosque) async {
    final prefs = await SharedPreferences.getInstance();
    List<Mosque> recents = await getRecents();
    
    recents.removeWhere((m) => m.id == mosque.id); // Remove if exists to move to top
    recents.insert(0, mosque); // Add to top
    
    if (recents.length > _maxRecent) {
      recents = recents.sublist(0, _maxRecent);
    }
    
    await prefs.setStringList(
      _recentKey, 
      recents.map((e) => e.toJson()).toList()
    );
  }
}
