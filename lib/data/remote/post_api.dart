import 'package:dio/dio.dart';
import 'package:srs8/data/models/comment.dart';
import 'package:srs8/data/models/create_post_request.dart';
import 'package:srs8/data/models/post.dart';
import 'package:srs8/data/models/user.dart';
import 'package:retrofit/retrofit.dart';

part 'post_api.g.dart';

//виды запросов которые мы может использовать 

@RestApi()
abstract class PostApi {
  factory PostApi(Dio dio, {String? baseUrl}) = _PostApi;

  // 1. Список постов с пагинацией
  @GET('/posts')
  Future<List<Post>> getPosts(
    @Query('_page') int page,
    @Query('_limit') int limit,
  );

  // 2. Один пост
  @GET('/posts/{id}')
  Future<Post> getPost(@Path('id') int id);

  // 3. Посты конкретного пользователя  
  @GET('/posts')
  Future<List<Post>> getPostsByUser(
    @Query('userId') int userId,
    @Query('_page') int page,
    @Query('_limit') int limit,
  );

  // 4. Комментарии к посту
  @GET('/posts/{id}/comments')
  Future<List<Comment>> getComments(@Path('id') int postId);

  // 5. Создание поста (POST)
  @POST('/posts')
  Future<Post> createPost(@Body() CreatePostRequest request);

  // сортировка
  @GET('/users')
  Future<List<User>> getUsers();

  @GET('/users/{id}')
  Future<User> getUser(@Path('id') int id);
}