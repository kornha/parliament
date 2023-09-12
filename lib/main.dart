import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/consants.dart';
import 'package:political_think/firebase_options.dart';
import 'common/zrouter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  const bool local = true;

  if (local) {
    // FirebaseFirestore.instance.useFirestoreEmulator("localhost", 8080);
    await FirebaseAuth.instance.useAuthEmulator("localhost", 9099);
    // FirebaseFunctions.instanceFor(region: 'us-central1')
    //     .useFunctionsEmulator("localhost", 5001);
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var router = ZRouter.instance(ref);
    return MaterialApp.router(
      title: 'Political Think',
      routerConfig: router,
      theme: ThemeConstants.lightTheme,
      darkTheme: ThemeConstants.darkTheme,
      debugShowCheckedModeBanner: false,
    );
  }
}
