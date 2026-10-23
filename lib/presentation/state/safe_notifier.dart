import 'package:flutter/foundation.dart';

/// Не даёт вызвать notifyListeners после dispose (например, ответ пришёл после закрытия экрана).
mixin SafeNotifier on ChangeNotifier {
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void notify() {
    if (!_disposed) notifyListeners();
  }
}