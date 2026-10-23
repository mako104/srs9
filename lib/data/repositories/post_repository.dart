import 'package:flutter/foundation.dart';
import 'package:srs8/core/error/app_exception.dart';
import 'package:srs8/data/local/post_cache.dart';
import 'package:srs8/data/models/comment.dart';
import 'package:srs8/data/models/create_post_request.dart';
import 'package:srs8/data/models/post.dart';
import 'package:srs8/data/models/user.dart';
import 'package:srs8/data/remote/post_api.dart';

/// Единственная точка доступа UI к данным: сервер + кэш + преобразование ошибок.
class PostRepository {
  PostRepository({required PostApi api, required PostCache cache})
      : _api = api,
        _cache = cache;

  final PostApi _api;
  final PostCache _cache;

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e, s) {
      final ex = AppException.from(e);
      if (kDebugMode) {
        debugPrint('[PostRepository] ${ex.type}: ${ex.technical ?? e}\n$s');
      }
      throw ex;
    }
  }

  Future<List<Post>> fetchPosts({
    required int page,
    int limit = 10,
    int? userId,
  }) =>
      _guard(() => userId == null
          ? _api.getPosts(page, limit)
          : _api.getPostsByUser(userId, page, limit));

  Future<Post> getPost(int id) => _guard(() => _api.getPost(id));

  Future<List<Comment>> getComments(int postId) =>
      _guard(() => _api.getComments(postId));

  Future<Post> createPost(CreatePostRequest request) =>
      _guard(() => _api.createPost(request));

  Future<List<User>> getUsers() => _guard(() => _api.getUsers());

  Future<User> getUser(int id) => _guard(() => _api.getUser(id));

  // ---- кэш ----
  Future<List<Post>> getCachedPosts({int? userId}) async =>
      _cache.readPosts(PostCache.keyFor(userId));

  Future<void> saveCachedPosts(List<Post> posts, {int? userId}) =>
      _cache.writePosts(PostCache.keyFor(userId), posts);

  Future<List<Post>> getLocalPosts() async =>
      _cache.readPosts(PostCache.localKey);

  Future<void> saveLocalPosts(List<Post> posts) =>
      _cache.writePosts(PostCache.localKey, posts);
}