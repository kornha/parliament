import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'zuser.g.dart';

@JsonSerializable(explicitToJson: true)
class ZUser extends ChangeNotifier {
  final String uid;
  String? displayName;
  String? email;
  String? phoneNumber;
  String? photoURL;
  String? did;
  List<String>? interests = [];

  ZUser({required this.uid, listen = false});

  factory ZUser.fromJson(Map<String, dynamic> json) => _$ZUserFromJson(json);

  Map<String, dynamic> toJson() => _$ZUserToJson(this);
}
