import 'package:flutter/material.dart';
import 'package:political_think/common/components/zapp_bar.dart';
import 'package:political_think/common/components/zscaffold.dart';
import 'package:political_think/common/components/ztext_button.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/views/profile/about.dart';
import 'package:url_launcher/url_launcher.dart';

class Issues extends StatelessWidget {
  const Issues({super.key});

  static const location = '/issues';

  @override
  Widget build(BuildContext context) {
    return ZScaffold(
      appBar: ZAppBar(showAppName: true),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Issues",
            style: context.h2,
          ),
          context.sf,
          const Text(
              "For issues or inquiries, please raise an issue on our GitHub repository, contact with us by email, or join our Discord server."),
          context.sf,
          const About(),
        ],
      ),
    );
  }
}
