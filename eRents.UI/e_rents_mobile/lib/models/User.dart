import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  int? id;
  String? firstName;
  String? lastName;
  String? email;
  String? username;
  String? password;
  String? image;
  User(this.id, this.firstName, this.lastName, this.email, this.username,
      this.password, this.image);

  // fromJson
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  // toJson
  Map<String, dynamic> toJson() => _$UserToJson(this);
}

