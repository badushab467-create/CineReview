import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';

class StorageService {
  static const String _favKey = 'favorites_v1';

  // Toggle favorite status
  static Future<bool> toggleFavorite(Movie movie) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favs = prefs.getStringList(_favKey) ?? [];
    
    int index = favs.indexWhere((m) => jsonDecode(m)['id'] == movie.id);
    bool isNowFavorite = false;
    
    if (index >= 0) {
      favs.removeAt(index);
    } else {
      favs.add(jsonEncode(movie.toJson()));
      isNowFavorite = true;
    }
    
    await prefs.setStringList(_favKey, favs);
    return isNowFavorite;
  }

  // Check if a movie is favorited
  static Future<bool> isFavorite(int movieId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favs = prefs.getStringList(_favKey) ?? [];
    return favs.any((m) => jsonDecode(m)['id'] == movieId);
  }

  // Get all favorited movies
  static Future<List<Movie>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favs = prefs.getStringList(_favKey) ?? [];
    return favs.map((m) => Movie.fromJson(jsonDecode(m))).toList();
  }

  // Get all saved reviews (combining rating, comment, and movie info into one object)
  static Future<List<Map<String, dynamic>>> getAllReviews() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('review_'));
    
    List<Map<String, dynamic>> allReviews = [];
    for (var key in keys) {
      final data = prefs.getString(key);
      if (data != null) {
        try {
          final reviewObj = jsonDecode(data);
          allReviews.add({
            'movieId': int.parse(key.replaceFirst('review_', '')),
            'rating': reviewObj['rating'] ?? 0.0,
            'comment': reviewObj['comment'] ?? '',
            'timestamp': reviewObj['timestamp'] ?? '',
            'movieTitle': reviewObj['movieTitle'] ?? 'Unknown Movie',
            'posterPath': reviewObj['posterPath'] ?? '',
          });
        } catch (_) {}
      }
    }
    return allReviews;
  }
}
