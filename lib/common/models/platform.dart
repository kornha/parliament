import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:political_think/common/components/profile_icon.dart';
import 'package:political_think/common/constants.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/util/utils.dart';

part 'platform.g.dart';

@JsonSerializable(explicitToJson: true)
class Platform {
  final String plid;
  final String url;
  final String? photoURL;

  double? avgReplies;
  double? avgReposts;
  double? avgLikes;
  double? avgBookmarks;
  double? avgViews;

  @JsonKey(fromJson: Utils.timestampFromJson, toJson: Utils.timestampToJson)
  Timestamp createdAt;
  @JsonKey(fromJson: Utils.timestampFromJson, toJson: Utils.timestampToJson)
  Timestamp updatedAt;

  Platform({
    required this.plid,
    required this.url,
    required this.createdAt,
    required this.updatedAt,
    this.avgReplies,
    this.avgReposts,
    this.avgLikes,
    this.avgBookmarks,
    this.avgViews,
    this.photoURL,
  });

  factory Platform.fromJson(Map<String, dynamic> json) =>
      _$PlatformFromJson(json);

  Map<String, dynamic> toJson() => _$PlatformToJson(this);

  // Used for special icons instead of the default photo
  Widget getIcon(double size) {
    if (url == "x.com") {
      return Icon(
        FontAwesomeIcons.xTwitter,
        size: size,
        color: Palette.green,
      );
    }
    return ProfileIcon(
      url: photoURL,
      radius: size / 2,
      showIfNull: false,
    );
  }
}
