import 'package:flutter/material.dart';
import 'package:political_think/common/components/zapp_bar.dart';
import 'package:political_think/common/components/zscaffold.dart';
import 'package:political_think/common/extensions.dart';

class Privacy extends StatelessWidget {
  const Privacy({super.key});

  static const location = '/privacy';

  @override
  Widget build(BuildContext context) {
    return ZScaffold(
      appBar: ZAppBar(showAppName: true),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Privacy Policy",
            style: context.h2,
          ),
          context.sf,
          Text(
            "Effective Date: Jan 1, 2025",
            style: context.h4,
          ),
          context.sh,
          const Text(
              "Welcome to Parliament (\"we,\" \"our,\" or \"us\"). Your privacy is critically important to us. This Privacy Policy explains how we collect, use, and share information about you when you use our app."),
          context.sf,
          Text(
            "1. Information We Collect",
            style: context.h3,
          ),
          context.sh,
          const Text(
              "We only collect your email address when you provide it to us directly during account creation or contact with our support team."),
          context.sf,
          Text(
            "2. How We Use Your Information",
            style: context.h3,
          ),
          context.sh,
          const Text(
              "We use your email address to:\n\n- Provide account-related notifications.\n\n- Respond to support requests and inquiries."),
          context.sf,
          Text(
            "3. Data Retention",
            style: context.h3,
          ),
          context.sh,
          const Text(
              "We retain your email address only for as long as necessary to provide our services or comply with legal obligations."),
          context.sf,
          Text(
            "4. Security",
            style: context.h3,
          ),
          context.sh,
          const Text(
              "We take reasonable measures to protect your email address from unauthorized access, use, or disclosure."),
          context.sf,
          Text(
            "5. Changes to This Privacy Policy",
            style: context.h3,
          ),
          context.sh,
          const Text(
              "We may update this Privacy Policy from time to time. If we make significant changes, we will notify you by updating the effective date or providing a prominent notice in the app."),
          context.sf,
          Text(
            "6. Contact Us",
            style: context.h3,
          ),
          context.sh,
          const Text(
              "If you have any questions or concerns about this Privacy Policy, please contact us at contact@parliament.foundation."),
        ],
      ),
    );
  }
}
