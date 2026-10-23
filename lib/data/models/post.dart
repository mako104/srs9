import 'package:json_annotation/json_annotation.dart';

part 'post.g.dart';

@JsonSerializable()
class Post {
  const Post({
    required this.userId,
    required this.id,
    required this.title,
    required this.body,
    this.isLocal = false,
    this.isPending = false,
  });

  final int userId;
  final int id;
  final String title;
  final String body;

  /// Пост создан локально (JSONPlaceholder его не хранит).
  @JsonKey(defaultValue: false)
  final bool isLocal;

  /// Пост отправляется на сервер (Optimistic UI). В JSON не попадает.
  @JsonKey(includeFromJson: false, includeToJson: false)
  final bool isPending;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
  Map<String, dynamic> toJson() => _$PostToJson(this);

  Post copyWith({bool? isLocal, bool? isPending}) => Post(
        userId: userId,
        id: id,
        title: title,
        body: body,
        isLocal: isLocal ?? this.isLocal,
        isPending: isPending ?? this.isPending,
      );
}