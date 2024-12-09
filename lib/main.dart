import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/ztheme.dart';
import 'package:political_think/firebase_options.dart';
import 'package:political_think/sharing.dart';
import 'common/zrouter.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

void main() async {
  usePathUrlStrategy();

  // gorouter recommends not using since top of stack is not always deeplinkable
  // but otherwise its not swipeable on iOS
  GoRouter.optionURLReflectsImperativeAPIs = true;

  await dotenv.load(fileName: ".env");

  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  const bool local = false;

  if (local) {
    FirebaseFirestore.instance.useFirestoreEmulator("localhost", 8080);
    await FirebaseAuth.instance.useAuthEmulator("localhost", 9099);
    FirebaseFunctions.instanceFor(region: 'us-central1')
        .useFunctionsEmulator("localhost", 5001);
  }

  runApp(
    const ProviderScope(
      child: Sharing(child: Parliament()),
    ),
  );
}

class Parliament extends ConsumerWidget {
  const Parliament({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var router = ZRouter.instance(ref);
    return MaterialApp.router(
      title: 'Parliament',
      routerConfig: router,
      theme: ZTheme.lightTheme,
      darkTheme: ZTheme.darkTheme,
      builder: FToastBuilder(),
      debugShowCheckedModeBanner: false,
    );
  }
}
