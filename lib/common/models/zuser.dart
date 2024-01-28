import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:political_think/common/chat/chat_types/flutter_chat_types.dart'
    as ct;
import 'package:political_think/common/models/vote.dart';

part 'zuser.g.dart';

@JsonSerializable()
class ZUser {
  final String uid;
  String? email;
  String? phoneNumber;
  String? photoURL;
  String? username;

  ZUser({required this.uid});

  factory ZUser.fromJson(Map<String, dynamic> json) => _$ZUserFromJson(json);

  Map<String, dynamic> toJson() => _$ZUserToJson(this);

  ct.User toChatUser() {
    return ct.User(
      id: uid,
      firstName: username,
      imageUrl: photoURL,
    );
  }
}
