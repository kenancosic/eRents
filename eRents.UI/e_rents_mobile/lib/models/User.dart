import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class User {
  User(this.id, this.firstName, this.lastName, this.email, this.username,
      this.password, this.image);
  int? id;
  String? firstName;
  String? lastName;
  String? email;
  String? username;
  String? password;
  String? image;
}
