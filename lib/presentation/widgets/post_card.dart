import 'package:flutter/material.dart';
import 'package:srs8/data/models/post.dart';

class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post, required this.onTap});

  final Post post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Colors.pink.shade100,
          foregroundColor: Colors.pink.shade900,
          child: post.isLocal
              ? const Icon(Icons.edit_note)
              : Text('${post.id}', style: const TextStyle(fontSize: 12)),
        ),
        title: Text(post.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(post.body, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: [
                _Chip('Автор ${post.userId}'),
                if (post.isLocal) const _Chip('создан локально'),
                if (post.isPending) const _Chip('отправляется…'),
              ],
            ),
          ],
        ),
        trailing: post.isPending
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.pink.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.pink.shade200),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: Colors.pink.shade800),
      ),
    );
  }
}