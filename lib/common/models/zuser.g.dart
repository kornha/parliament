// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'zuser.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ZUser _$ZUserFromJson(Map<String, dynamic> json) => ZUser(
      uid: json['uid'] as String,
    )
      ..displayName = json['displayName'] as String?
      ..email = json['email'] as String?
      ..phoneNumber = json['phoneNumber'] as String?
      ..photoURL = json['photoURL'] as String?
      ..did = json['did'] as String?
      ..interests = (json['interests'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList();

Map<String, dynamic> _$ZUserToJson(ZUser instance) => <String, dynamic>{
      'uid': instance.uid,
      'displayName': instance.displayName,
      'email': instance.email,
      'phoneNumber': instance.phoneNumber,
      'photoURL': instance.photoURL,
      'did': instance.did,
      'interests': instance.interests,
    };
