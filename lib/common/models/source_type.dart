import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

enum SourceType { article, x }

extension SourceTypeExtension on SourceType {
  IconData get icon {
    switch (this) {
      case SourceType.x:
        return FontAwesomeIcons.xTwitter;
      default:
        return FontAwesomeIcons.newspaper;
    }
  }
}
