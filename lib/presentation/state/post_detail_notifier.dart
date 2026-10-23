import 'package:flutter/foundation.dart';
import 'package:srs8/core/error/app_exception.dart';
import 'package:srs8/data/models/comment.dart';
import 'package:srs8/data/models/post.dart';
import 'package:srs8/data/models/user.dart';
import 'package:srs8/data/repositories/post_repository.dart';
import 'package:srs8/presentation/state/safe_notifier.dart';
import 'package:srs8/presentation/state/users_notifier.dart';

class PostDetailNotifier extends ChangeNotifier with SafeNotifier {
  PostDetailNotifier(this._repository, this.post);

  final PostRepository _repository;
  Post post;

  LoadStatus commentsStatus = LoadStatus.loading;
  List<Comment> comments = [];
  String? commentsError;

  LoadStatus authorStatus = LoadStatus.loading;
  User? author;
  String? authorError;

  Future<void> load() async {
    await Future.wait([_loadPost(), loadComments(), loadAuthor()]);
  }

  Future<void> _loadPost() async {
    if (post.isLocal) return; // локального поста нет на сервере
    try {
      post = await _repository.getPost(post.id);
      notify();
    } on AppException {
      // Остаёмся с данными из списка.
    }
  }

  Future<void> loadComments() async {
    if (post.isLocal) {
      commentsStatus = LoadStatus.success;
      comments = [];
      notify();
      return;
    }
    commentsStatus = LoadStatus.loading;
    commentsError = null;
    notify();
    try {
      comments = await _repository.getComments(post.id);
      commentsStatus = LoadStatus.success;
    } on AppException catch (e) {
      commentsStatus = LoadStatus.error;
      commentsError = e.message;
    }
    notify();
  }

  Future<void> loadAuthor() async {
    authorStatus = LoadStatus.loading;
    authorError = null;
    notify();
    try {
      author = await _repository.getUser(post.userId);
      authorStatus = LoadStatus.success;
    } on AppException catch (e) {
      authorStatus = LoadStatus.error;
      authorError = e.message;
    }
    notify();
  }
}