import 'package:flutter/material.dart';
import 'package:srs8/data/models/post.dart';
import 'package:srs8/data/repositories/post_repository.dart';
import 'package:srs8/presentation/state/post_detail_notifier.dart';
import 'package:srs8/presentation/state/users_notifier.dart';
import 'package:srs8/presentation/widgets/state_views.dart';
import 'package:provider/provider.dart';

class PostDetailScreen extends StatelessWidget {
  const PostDetailScreen({super.key});

  static Route<void> route(Post post) => MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (_) =>
              PostDetailNotifier(context.read<PostRepository>(), post)..load(),
          child: const PostDetailScreen(),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final n = context.watch<PostDetailNotifier>();
    final post = n.post;

    return Scaffold(
      appBar: AppBar(title: const Text('Пост')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.isLocal)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Создан локально',
                        style: TextStyle(
                          color: Colors.pink.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Text(
                    post.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(post.body),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _authorCard(n),
          const SizedBox(height: 16),
          Text(
            'Комментарии',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _comments(n, context),
        ],
      ),
    );
  }

  Widget _authorCard(PostDetailNotifier n) {
    switch (n.authorStatus) {
      case LoadStatus.loading:
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        );
      case LoadStatus.error:
        return ErrorView(message: n.authorError ?? '', onRetry: n.loadAuthor);
      case LoadStatus.success:
        final a = n.author!;
        return Card(
          color: Colors.pink.shade50,
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.pink,
              foregroundColor: Colors.white,
              child: Icon(Icons.person),
            ),
            title: Text(a.name),
            subtitle: Text(
              '${a.email}${a.company != null ? '\n${a.company!.name}' : ''}',
            ),
            isThreeLine: a.company != null,
          ),
        );
    }
  }

  Widget _comments(PostDetailNotifier n, BuildContext context) {
    switch (n.commentsStatus) {
      case LoadStatus.loading:
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        );
      case LoadStatus.error:
        return ErrorView(
          message: n.commentsError ?? '',
          onRetry: n.loadComments,
        );
      case LoadStatus.success:
        if (n.comments.isEmpty) {
          return const EmptyView(message: 'Комментариев нет');
        }
        return Column(
          children: n.comments
              .map(
                (c) => Card(
                  color: Colors.white,
                  child: ListTile(
                    title: Text(c.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          c.email,
                          style: TextStyle(
                            color: Colors.pink.shade700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(c.body),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
    }
  }
}