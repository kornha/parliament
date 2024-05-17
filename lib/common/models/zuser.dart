import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:political_think/common/chat/chat_types/flutter_chat_types.dart'
    as ct;
import 'package:political_think/common/models/vote.dart';
import 'package:political_think/common/models/zsettings.dart';

part 'zuser.g.dart';

@JsonSerializable(explicitToJson: true)
class ZUser {
  final String uid;
  int elo;
  String? email;
  String? phoneNumber;
  String? photoURL;
  String? username;
  bool isAdmin;
  ZSettings settings;

  ZUser({
    required this.uid,
    this.elo = 1500,
    this.isAdmin = false,
    this.settings = const ZSettings(),
  });

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
