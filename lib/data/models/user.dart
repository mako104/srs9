import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

/// Вложенная модель компании автора.
@JsonSerializable()
class Company {
  const Company({required this.name, this.catchPhrase, this.bs});

  final String name;
  final String? catchPhrase;
  final String? bs;

  factory Company.fromJson(Map<String, dynamic> json) =>
      _$CompanyFromJson(json);
  Map<String, dynamic> toJson() => _$CompanyToJson(this);
}

@JsonSerializable(explicitToJson: true)
class User {
  const User({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.phone,
    this.website,
    this.company,
  });

  final int id;
  final String name;
  final String username;
  final String email;
  final String? phone;
  final String? website;
  final Company? company;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}