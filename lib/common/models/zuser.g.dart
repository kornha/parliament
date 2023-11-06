// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'zuser.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ZUser _$ZUserFromJson(Map<String, dynamic> json) => ZUser(
      uid: json['uid'] as String,
    )
      ..email = json['email'] as String?
      ..phoneNumber = json['phoneNumber'] as String?
      ..photoURL = json['photoURL'] as String?
      ..username = json['username'] as String?;

Map<String, dynamic> _$ZUserToJson(ZUser instance) => <String, dynamic>{
      'uid': instance.uid,
      'email': instance.email,
      'phoneNumber': instance.phoneNumber,
      'photoURL': instance.photoURL,
      'username': instance.username,
    };
