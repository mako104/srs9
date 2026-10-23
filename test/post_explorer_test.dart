import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:srs8/core/error/app_exception.dart';
import 'package:srs8/data/local/post_cache.dart';
import 'package:srs8/data/models/comment.dart';
import 'package:srs8/data/models/create_post_request.dart';
import 'package:srs8/data/models/post.dart';
import 'package:srs8/data/models/user.dart';
import 'package:srs8/data/remote/post_api.dart';
import 'package:srs8/data/repositories/post_repository.dart';
import 'package:srs8/presentation/state/post_list_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakePostApi implements PostApi {
  int getPostsCalls = 0;
  int? lastUserId;
  Object? error;
  Completer<void>? gate;

  List<Post> _make(int page, int limit, int? userId) => List.generate(limit, (i) {
        final id = (page - 1) * limit + i + 1;
        return Post(
          userId: userId ?? ((id - 1) ~/ 10) + 1,
          id: id,
          title: 'Post title $id',
          body: 'Body $id',
        );
      });

  @override
  Future<List<Post>> getPosts(int page, int limit) async {
    getPostsCalls++;
    lastUserId = null;
    if (error != null) throw error!;
    if (gate != null) await gate!.future;
    return _make(page, limit, null);
  }

  @override
  Future<List<Post>> getPostsByUser(int userId, int page, int limit) async {
    getPostsCalls++;
    lastUserId = userId;
    if (error != null) throw error!;
    return _make(page, limit, userId);
  }

  @override
  Future<Post> getPost(int id) async =>
      Post(userId: 1, id: id, title: 'Post title $id', body: 'Body $id');

  @override
  Future<List<Comment>> getComments(int postId) async => [];

  @override
  Future<List<User>> getUsers() async => [];

  @override
  Future<User> getUser(int id) async => throw UnimplementedError();

  @override
  Future<Post> createPost(CreatePostRequest request) async {
    if (error != null) throw error!;
    return Post(
      userId: request.userId,
      id: 101,
      title: request.title,
      body: request.body,
    );
  }
}

Future<(PostRepository, FakePostApi)> _setup() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final api = FakePostApi();
  return (PostRepository(api: api, cache: PostCache(prefs)), api);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('JSON', () {
    test('1. JSON -> Post', () {
      final post = Post.fromJson({
        'userId': 1,
        'id': 2,
        'title': 'Заголовок',
        'body': 'Текст',
      });
      expect(post.id, 2);
      expect(post.userId, 1);
      expect(post.title, 'Заголовок');
      expect(post.isLocal, false);
    });

    test('2. Post -> JSON', () {
      const post = Post(userId: 1, id: 2, title: 't', body: 'b');
      expect(post.toJson(), {
        'userId': 1,
        'id': 2,
        'title': 't',
        'body': 'b',
        'isLocal': false,
      });
    });
  });

  group('PostRepository', () {
    test('3. успешная загрузка постов', () async {
      final (repo, _) = await _setup();
      final posts = await repo.fetchPosts(page: 1, limit: 10);
      expect(posts.length, 10);
      expect(posts.first.id, 1);
    });

    test('4. ошибка сервера -> AppException(server)', () async {
      final (repo, api) = await _setup();
      final options = RequestOptions(path: '/posts');
      api.error = DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: options, statusCode: 500),
      );

      await expectLater(
        repo.fetchPosts(page: 1),
        throwsA(
          isA<AppException>()
              .having((e) => e.type, 'type', AppExceptionType.server),
        ),
      );
    });
  });

  group('PostListNotifier', () {
    test('5. фильтрация по заголовку и по автору', () async {
      final (repo, api) = await _setup();
      final n = PostListNotifier(repo);
      await n.init();

      n.setQuery('title 10');
      expect(n.visiblePosts.length, 1);
      expect(n.visiblePosts.first.id, 10);

      n.setQuery('');
      await n.setUserId(2);
      expect(api.lastUserId, 2);
      expect(n.visiblePosts.every((p) => p.userId == 2), true);
    });

    test('6. защита от дублирующейся загрузки страницы', () async {
      final (repo, api) = await _setup();
      final n = PostListNotifier(repo);
      await n.init();
      expect(api.getPostsCalls, 1);

      api.gate = Completer<void>();
      final f1 = n.loadMore();
      final f2 = n.loadMore(); // повторный вызов должен быть проигнорирован
      api.gate!.complete();
      await Future.wait([f1, f2]);

      expect(api.getPostsCalls, 2);
      final ids = n.visiblePosts.map((p) => p.id).toList();
      expect(ids.length, 20);
      expect(ids.toSet().length, 20); // без дубликатов
    });

    test('7. Optimistic UI: при ошибке пост откатывается', () async {
      final (repo, api) = await _setup();
      final n = PostListNotifier(repo);
      await n.init();
      final before = n.visiblePosts.length;

      api.error = DioException(
        requestOptions: RequestOptions(path: '/posts'),
        type: DioExceptionType.connectionError,
      );
      final outcome = await n.createPost(
        const CreatePostRequest(
          title: 'Новый заголовок',
          body: 'Достаточно длинный текст',
          userId: 1,
        ),
      );

      expect(outcome.isSuccess, false);
      expect(n.visiblePosts.length, before);
    });
  });

  group('Dio mock adapter', () {
    test('8. POST /posts без реального интернета', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://jsonplaceholder.typicode.com'));
      final adapter = DioAdapter(dio: dio);
      const data = {
        'title': 'Hello title',
        'body': 'Body of the post',
        'userId': 1,
      };
      adapter.onPost(
        '/posts',
        (server) => server.reply(201, {...data, 'id': 101}),
        data: data,
      );

      final api = PostApi(dio);
      final result = await api.createPost(
        const CreatePostRequest(
          title: 'Hello title',
          body: 'Body of the post',
          userId: 1,
        ),
      );
      expect(result.id, 101);
      expect(result.title, 'Hello title');
    });
  });
}