import 'dart:async';
import 'dart:convert';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_database/firebase_database.dart';
import 'screens/login.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseApp fapp = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('Initialized default app $fapp');
  callFirebaseRemoteConfig();
  // callFirebaseDatabase();
  runApp(const MyApp());
}

Future<void> callFirebaseRemoteConfig() async {
  // To fetch remote config from Firebase Remote Config
  late final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
  await remoteConfig.setConfigSettings(RemoteConfigSettings(
    fetchTimeout: const Duration(minutes: 1),
    minimumFetchInterval: const Duration(hours: 1),
  ));
  await remoteConfig.fetchAndActivate();
  Map<String, dynamic> mapValues = json.decode(remoteConfig.getValue("Connection_Config").asString());
  debugPrint(mapValues["Sepolia"]["Sepolia_HTTPS"]);
  debugPrint(mapValues["Firebase"]["Firebase_Database"]);
}

Future<void> callFirebaseDatabase() async {
  FirebaseApp fapp = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseDatabase database = FirebaseDatabase.instanceFor(app: fapp, databaseURL: "https://eth-toto-board-default-rtdb.asia-southeast1.firebasedatabase.app");
  DatabaseEvent event = await database.ref().once();
  // print("Result : ${event.snapshot.value}");
  print("Result : ${event.snapshot.child('txreceipts/WpWTlpZG5SYTdAlTZMGBwZPBszD2').value}");
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      // Initialize FlutterFire
        future: Firebase.initializeApp(),
        builder: (context, snapshot) {
          return MaterialApp(
            title: 'Blockchain Ethereum Lotto(6/45)',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(primarySwatch: Colors.cyan),
            home: const LoginPage(),
          );
        }
    );
  }
}