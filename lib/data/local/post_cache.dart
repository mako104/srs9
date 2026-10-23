import 'dart:convert';

import 'package:srs8/data/models/post.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PostCache {
  PostCache(this._prefs);

  static const localKey = 'local_posts';
  static String keyFor(int? userId) => 'posts_cache_${userId ?? 'all'}';

  final SharedPreferences _prefs;

  List<Post> readPosts(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Post.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Повреждённый кэш не должен ронять приложение.
      return [];
    }
  }

  Future<void> writePosts(String key, List<Post> posts) async {
    final raw = jsonEncode(posts.map((p) => p.toJson()).toList());
    await _prefs.setString(key, raw);
  }
}