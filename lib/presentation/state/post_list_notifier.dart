import 'package:flutter/foundation.dart';
import 'package:srs8/core/error/app_exception.dart';
import 'package:srs8/data/models/create_post_request.dart';
import 'package:srs8/data/models/post.dart';
import 'package:srs8/data/repositories/post_repository.dart';
import 'package:srs8/presentation/state/safe_notifier.dart';

enum ListStatus { loading, success, error }

/// Результат создания поста.
class CreateOutcome {
  const CreateOutcome.success(this.serverPost) : error = null;
  const CreateOutcome.failure(this.error) : serverPost = null;

  final Post? serverPost;
  final String? error;

  bool get isSuccess => serverPost != null;
}

class PostListNotifier extends ChangeNotifier with SafeNotifier {
  PostListNotifier(this._repository);

  static const pageSize = 10;

  final PostRepository _repository;

  // Раздельные состояния для разных операций (а не один isLoading).
  ListStatus status = ListStatus.loading; // первичная загрузка
  bool isLoadingMore = false; // подгрузка страницы
  bool isRefreshing = false; // обновление с сервера (в т.ч. фоновое)
  bool fromCache = false; // показаны сохранённые данные
  bool hasMore = true;
  String? error; // ошибка первичной загрузки
  String? loadMoreError; // ошибка подгрузки
  String? notice; // не удалось обновить, показан кэш

  // Фильтры
  int? userId;
  String query = '';
  bool sortAscending = true;

  List<Post> _serverPosts = [];
  final List<Post> _localPosts = [];
  int _page = 0;
  int _generation = 0; // защита от «устаревших» ответов

  int get loadedCount => _serverPosts.length;
  bool get hasActiveFilters =>
      userId != null || query.trim().isNotEmpty || !sortAscending;

  /// Локальные посты сверху, затем серверные (поиск + сортировка по ID).
  List<Post> get visiblePosts {
    final q = query.trim().toLowerCase();
    bool matches(Post p) => q.isEmpty || p.title.toLowerCase().contains(q);

    final local = _localPosts
        .where((p) => (userId == null || p.userId == userId) && matches(p));
    final server = _serverPosts.where(matches).toList()
      ..sort((a, b) =>
          sortAscending ? a.id.compareTo(b.id) : b.id.compareTo(a.id));
    return [...local, ...server];
  }

  Future<void> init() async {
    _localPosts
      ..clear()
      ..addAll(await _repository.getLocalPosts());
    await _loadFirstPage();
  }

  Future<void> retry() => _loadFirstPage();

  /// Pull-to-refresh.
  Future<void> refresh() => _loadFirstPage(useCache: false);

  Future<void> _loadFirstPage({bool useCache = true}) async {
    final gen = ++_generation;
    _page = 0;
    hasMore = true;
    isLoadingMore = false;
    loadMoreError = null;
    error = null;
    notice = null;

    if (useCache) {
      final cached =
          await _repository.getCachedPosts(userId: userId);
      if (gen != _generation) return;
      _serverPosts = cached;
      fromCache = cached.isNotEmpty;
      status = cached.isNotEmpty ? ListStatus.success : ListStatus.loading;
    }
    isRefreshing = true;
    notify();

    try {
      final fresh = await _repository.fetchPosts(
        page: 1,
        limit: pageSize,
        userId: userId,
      );
      if (gen != _generation) return;
      _serverPosts = fresh;
      _page = 1;
      hasMore = fresh.length >= pageSize;
      fromCache = false;
      status = ListStatus.success;
      await _repository.saveCachedPosts(fresh, userId: userId);
    } on AppException catch (e) {
      if (gen != _generation) return;
      if (_serverPosts.isEmpty) {
        status = ListStatus.error;
        error = e.message;
      } else {
        // Последний успешный результат не удаляем.
        status = ListStatus.success;
        fromCache = true;
        _page = (_serverPosts.length / pageSize).ceil();
        hasMore = _serverPosts.length % pageSize == 0;
        notice = '${e.message} Показаны сохранённые данные.';
      }
    }
    isRefreshing = false;
    notify();
  }

  Future<void> loadMore() async {
    // Защита от повторной загрузки одной и той же страницы.
    if (isLoadingMore || isRefreshing || !hasMore) return;
    if (status != ListStatus.success) return;

    final gen = _generation;
    final next = _page + 1;
    isLoadingMore = true;
    loadMoreError = null;
    notify();

    try {
      final items = await _repository.fetchPosts(
        page: next,
        limit: pageSize,
        userId: userId,
      );
      if (gen != _generation) return;
      final existing = _serverPosts.map((p) => p.id).toSet();
      _serverPosts = [
        ..._serverPosts,
        ...items.where((p) => !existing.contains(p.id)),
      ];
      _page = next;
      hasMore = items.length >= pageSize;
      await _repository.saveCachedPosts(_serverPosts, userId: userId);
    } on AppException catch (e) {
      if (gen != _generation) return;
      loadMoreError = e.message;
    }
    isLoadingMore = false;
    notify();
  }

  // ---- фильтры ----
  Future<void> setUserId(int? id) async {
    if (id == userId) return;
    userId = id;
    _resetListForNewFilter();
    await _loadFirstPage();
  }

  void setQuery(String value) {
    query = value;
    notify();
  }

  void toggleSort() {
    sortAscending = !sortAscending;
    notify();
  }

  Future<void> resetFilters() async {
    final hadUser = userId != null;
    query = '';
    sortAscending = true;
    userId = null;
    if (hadUser) {
      _resetListForNewFilter();
      await _loadFirstPage();
    } else {
      notify();
    }
  }

  void _resetListForNewFilter() {
    // Старые результаты не должны смешиваться с новыми.
    _serverPosts = [];
    fromCache = false;
    status = ListStatus.loading;
    notify();
  }

  // ---- создание поста (Optimistic UI) ----
  Future<CreateOutcome> createPost(CreatePostRequest request) async {
    final tempId = -DateTime.now().microsecondsSinceEpoch;
    final temp = Post(
      userId: request.userId,
      id: tempId,
      title: request.title,
      body: request.body,
      isLocal: true,
      isPending: true,
    );

    // 1. Показываем пост сразу, до ответа сервера.
    _localPosts.insert(0, temp);
    notify();

    try {
      final serverPost = await _repository.createPost(request);
      // 2. Успех: снимаем пометку «отправляется».
      final i = _localPosts.indexWhere((p) => p.id == tempId);
      if (i != -1) _localPosts[i] = temp.copyWith(isPending: false);
      await _repository.saveLocalPosts(
        _localPosts.where((p) => !p.isPending).toList(),
      );
      notify();
      return CreateOutcome.success(serverPost);
    } on AppException catch (e) {
      // 3. Ошибка: откатываем изменение.
      _localPosts.removeWhere((p) => p.id == tempId);
      notify();
      return CreateOutcome.failure(e.message);
    }
  }
}