import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:political_think/common/components/logo.dart';
import 'package:political_think/common/components/zdivider.dart';
import 'package:political_think/common/components/ztext_button.dart';
import 'package:political_think/common/extensions.dart';
import 'package:url_launcher/url_launcher.dart';

class About extends StatefulWidget {
  const About({super.key});

  @override
  State<About> createState() => _AboutState();
}

class _AboutState extends State<About> {
  String? _version;
  final FocusNode _selectableTextFocusNode = FocusNode();

  @override
  void dispose() {
    _selectableTextFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_version == null) {
      PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
        setState(() {
          _version = packageInfo.version;
        });
      });
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const LogoName(),
        Align(
          alignment: Alignment.center,
          child: Text(
            _version ?? "",
            style: context.l.copyWith(color: context.surfaceColorBright),
          ),
        ),
        const ZDivider(type: DividerType.TERTIARY),
        SelectableText.rich(
          TextSpan(
            text: 'email: contact@parliament.foundation',
            style: TextStyle(color: context.primaryColor),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                Clipboard.setData(
                  const ClipboardData(text: "contact@parliament.foundation"),
                );
                context.showToast("email copied");
              },
          ),
          focusNode: _selectableTextFocusNode, // Assign the focus node here
        ),
        const ZDivider(type: DividerType.TERTIARY),
        ZTextButton(
          type: ZButtonTypes.wide,
          backgroundColor: context.surfaceColor,
          onPressed: () {
            final Uri url = Uri.parse(
                "https://github.com/kornha/parliament?tab=readme-ov-file#whitepaper");
            launchUrl(url);
          },
          child: const Text("Read Our Whitepaper"),
        ),
        context.stq,
        ZTextButton(
          type: ZButtonTypes.wide,
          backgroundColor: context.surfaceColor,
          onPressed: () {
            final Uri url = Uri.parse(
                "https://github.com/kornha/parliament?tab=readme-ov-file#parliament");
            launchUrl(url);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(FontAwesomeIcons.github),
              context.sh,
              const Text("View Repository"),
            ],
          ),
        ),
        const ZDivider(type: DividerType.TERTIARY),
        ZTextButton(
          type: ZButtonTypes.wide,
          backgroundColor: const Color.fromRGBO(114, 137, 218, 1),
          foregroundColor: context.onSurfaceColor,
          onPressed: () {
            final Uri url = Uri.parse("https://discord.com/invite/HhdBKsK9Pq");
            launchUrl(url);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(FontAwesomeIcons.discord),
              context.sh,
              const Text("Join Our Discord"),
            ],
          ),
        ),
      ],
    );
  }
}
