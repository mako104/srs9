import 'package:flutter/foundation.dart';
import 'package:srs8/core/error/app_exception.dart';
import 'package:srs8/data/models/user.dart';
import 'package:srs8/data/repositories/post_repository.dart';
import 'package:srs8/presentation/state/safe_notifier.dart';

enum LoadStatus { loading, success, error }

class UsersNotifier extends ChangeNotifier with SafeNotifier {
  UsersNotifier(this._repository);

  final PostRepository _repository;

  LoadStatus status = LoadStatus.loading;
  List<User> users = [];
  String? error;

  Future<void> load() async {
    status = LoadStatus.loading;
    error = null;
    notify();
    try {
      users = await _repository.getUsers();
      status = LoadStatus.success;
    } on AppException catch (e) {
      status = LoadStatus.error;
      error = e.message;
    }
    notify();
  }

  /// Пары «id → подпись» для выпадающих списков (запасной вариант, если /users недоступен).
  List<MapEntry<int, String>> get options => users.isNotEmpty
      ? users.map((u) => MapEntry(u.id, u.name)).toList()
      : List.generate(10, (i) => MapEntry(i + 1, 'Автор #${i + 1}'));
}