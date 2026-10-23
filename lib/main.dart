import 'package:flutter/material.dart';
import 'package:srs8/core/network/dio_client.dart';
import 'package:srs8/core/theme/app_theme.dart';
import 'package:srs8/data/local/post_cache.dart';
import 'package:srs8/data/remote/post_api.dart';
import 'package:srs8/data/repositories/post_repository.dart';
import 'package:srs8/presentation/screens/post_list_screen.dart';
import 'package:srs8/presentation/state/post_list_notifier.dart';
import 'package:srs8/presentation/state/users_notifier.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final dio = DioClient().dio; // единственный экземпляр Dio
  final repository = PostRepository(
    api: PostApi(dio),
    cache: PostCache(prefs),
  );

  runApp(PostExplorerApp(repository: repository));
}

class PostExplorerApp extends StatelessWidget {
  const PostExplorerApp({super.key, required this.repository});

  final PostRepository repository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<PostRepository>.value(value: repository),
        ChangeNotifierProvider(
          create: (_) => PostListNotifier(repository)..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => UsersNotifier(repository)..load(),
        ),
      ],
      child: MaterialApp(
        title: 'Post Explorer',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const PostListScreen(),
      ),
    );
  }
}