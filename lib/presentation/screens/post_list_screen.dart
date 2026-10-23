import 'package:flutter/material.dart';
import 'package:srs8/data/models/post.dart';
import 'package:srs8/presentation/screens/create_post_screen.dart';
import 'package:srs8/presentation/screens/post_detail_screen.dart';
import 'package:srs8/presentation/state/post_list_notifier.dart';
import 'package:srs8/presentation/state/users_notifier.dart';
import 'package:srs8/presentation/widgets/post_card.dart';
import 'package:srs8/presentation/widgets/state_views.dart';
import 'package:provider/provider.dart';

class PostListScreen extends StatefulWidget {
  const PostListScreen({super.key});

  @override
  State<PostListScreen> createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  final _scroll = ScrollController();
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      context.read<PostListNotifier>().loadMore();
    }
  }

  Future<void> _openCreate() async {
    final pending = await Navigator.of(context).push<Future<CreateOutcome>>(
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );
    if (pending == null) return;
    final outcome = await pending;
    if (!mounted) return;

    if (outcome.isSuccess) {
      final p = outcome.serverPost!;
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Ответ сервера'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('id: ${p.id}'),
              Text('userId: ${p.userId}'),
              Text('title: ${p.title}'),
              Text('body: ${p.body}'),
              const SizedBox(height: 12),
              const Text(
                'JSONPlaceholder не сохраняет посты, поэтому пост добавлен '
                'в список только локально.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Не удалось создать пост: ${outcome.error}'),
          backgroundColor: Colors.pink.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = context.watch<PostListNotifier>();
    final users = context.watch<UsersNotifier>();

    return Scaffold(
      appBar: AppBar(title: const Text('Post Explorer')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: const Text('Новый пост'),
      ),
      body: Column(
        children: [
          _buildFilters(n, users),
          Expanded(child: _buildContent(n)),
        ],
      ),
    );
  }

  Widget _buildFilters(PostListNotifier n, UsersNotifier users) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _search,
            onChanged: n.setQuery,
            decoration: InputDecoration(
              hintText: 'Поиск по заголовку',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: n.query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _search.clear();
                        n.setQuery('');
                      },
                    ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              'Поиск идёт только среди загруженных постов (${n.loadedCount}), '
              'а не по всему набору данных',
              style: TextStyle(fontSize: 11, color: Colors.pink.shade700),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: DropdownButton<int?>(
                    value: n.userId,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Все авторы'),
                      ),
                      ...users.options.map(
                        (o) => DropdownMenuItem<int?>(
                          value: o.key,
                          child: Text(o.value, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: n.setUserId,
                  ),
                ),
              ),
              IconButton(
                tooltip: n.sortAscending
                    ? 'Сортировка по ID: по возрастанию'
                    : 'Сортировка по ID: по убыванию',
                onPressed: n.toggleSort,
                icon: Icon(
                  n.sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  color: Colors.pink,
                ),
              ),
              if (n.hasActiveFilters)
                TextButton(
                  onPressed: () {
                    _search.clear();
                    n.resetFilters();
                  },
                  child: const Text('Сбросить'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(PostListNotifier n) {
    switch (n.status) {
      case ListStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case ListStatus.error:
        return ErrorView(message: n.error ?? 'Ошибка', onRetry: n.retry);
      case ListStatus.success:
        final posts = n.visiblePosts;
        return Column(
          children: [
            if (n.fromCache && n.notice == null)
              const InfoBanner(
                text: 'Показаны сохранённые данные',
                icon: Icons.history,
              ),
            if (n.notice != null)
              InfoBanner(text: n.notice!, icon: Icons.wifi_off),
            if (n.isRefreshing) const LinearProgressIndicator(minHeight: 3),
            Expanded(
              child: RefreshIndicator(
                onRefresh: n.refresh,
                child: posts.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 40),
                          EmptyView(
                            message: n.query.trim().isEmpty
                                ? 'Постов пока нет'
                                : 'Среди загруженных постов ничего не найдено',
                            action: n.hasMore
                                ? TextButton(
                                    onPressed: n.loadMore,
                                    child: const Text('Загрузить ещё посты'),
                                  )
                                : null,
                          ),
                        ],
                      )
                    : ListView.builder(
                        controller: _scroll,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 90),
                        itemCount: posts.length + 1,
                        itemBuilder: (context, i) {
                          if (i < posts.length) {
                            final Post p = posts[i];
                            return PostCard(
                              post: p,
                              onTap: () => Navigator.of(context)
                                  .push(PostDetailScreen.route(p)),
                            );
                          }
                          return _ListFooter(n);
                        },
                      ),
              ),
            ),
          ],
        );
    }
  }
}

class _ListFooter extends StatelessWidget {
  const _ListFooter(this.n);
  final PostListNotifier n;

  @override
  Widget build(BuildContext context) {
    if (n.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (n.loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(n.loadMoreError!, textAlign: TextAlign.center),
            TextButton.icon(
              onPressed: n.loadMore,
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
            ),
          ],
        ),
      );
    }
    if (!n.hasMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: Text('Это все посты')),
      );
    }
    return Center(
      child: TextButton(
        onPressed: n.loadMore,
        child: const Text('Загрузить ещё'),
      ),
    );
  }
}