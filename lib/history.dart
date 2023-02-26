import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eth_toto_board_flutter/boardmain.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:eth_toto_board_flutter/utilities/remote_config.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'firebase_options.dart';

class HistoryOutput extends StatefulWidget {
  const HistoryOutput({Key? key}) : super(key: key);
  @override
  State<HistoryOutput> createState() => _HistoryOutputState();
}

class _HistoryOutputState extends State<HistoryOutput> {
  // To create a new Firebase Remote Config instance
  late FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  // References a node called txreceipts
  // DatabaseReference? _txReceiptRef;
  late final DatabaseReference _txReceiptRef = FirebaseDatabase.instance.ref();
  // The user's ID which is unique from the Firebase project
  String? userId = FirebaseAuth.instance.currentUser?.uid;
  List<Map<dynamic, dynamic>> lists = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initialSetup();
  }

  Future<void> initialSetup() async {
    // Firebase Initialize App Function
    FirebaseApp fapp = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    WidgetsFlutterBinding.ensureInitialized();
    // To fetch remote config from Firebase Remote Config
    RemoteConfigService remoteConfigService = RemoteConfigService();
    _remoteConfig = await remoteConfigService.setupRemoteConfig();
    // To fetch remote config from Firebase Remote Config
    Map<String, dynamic> mapConnValues = json.decode(_remoteConfig.getValue("Connection_Config").asString());
    // Create a DatabaseReference which references a node called dbRef
    // _txReceiptRef = FirebaseDatabase.instanceFor(databaseURL: mapConnValues["Firebase"]["Firebase_Database"], app: fapp).ref();
  }

  @override
  Scaffold build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Slot Data History'),
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              FutureBuilder(
                  future: _txReceiptRef.child('txreceipts/$userId').orderByChild('timestamp').limitToLast(100).get(),
                  builder: (BuildContext context, AsyncSnapshot snapshot) {
                    if(snapshot.connectionState == ConnectionState.done) {
                      if(snapshot.data.value == null) {
                        return const Text('\n No History Transaction Data Existed.', textScaleFactor: 1.5, style: TextStyle(color: Colors.red));
                      } else {
                        // 'DataSnapshot' value != null
                        lists.clear();
                        Map<dynamic, dynamic> values = snapshot.data?.value;
                        values.forEach((key, values) {
                          lists.add(values);
                        });
                        return ListView.builder(
                            primary: false,
                            shrinkWrap: true,
                            itemCount: lists.length,
                            itemBuilder: (BuildContext context, int index) {
                              return Card(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text("Date: " + lists[index]["date"] + " , Transaction Status: " + lists[index]["status"].toString()),
                                    Text("Account: " + lists[index]["from"]),
                                    Text("SlotData: " + lists[index]["slotData"]),
                                    RichText(
                                        text: TextSpan(
                                            children: [
                                              const TextSpan(
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 14),
                                                text: "Transaction Hash: ",
                                              ),
                                              TextSpan(
                                                  style: const TextStyle(
                                                      color: Colors.blueAccent,
                                                      fontSize: 14),
                                                  text: '0x${lists[index]["transactionHash"]}',
                                                  recognizer: TapGestureRecognizer()
                                                    ..onTap = () async {
                                                      var url = "https://sepolia.etherscan.io/tx/0x${lists[index]["transactionHash"]}";
                                                      if (await canLaunchUrlString(url)) {
                                                        await launchUrlString(url);
                                                      } else {
                                                        throw 'Could not launch $url';
                                                      }
                                                    }
                                              ),
                                            ]
                                        )),
                                  ],
                                ),
                              );
                            });
                      }
                    }
                    // Display a Circular Progress Indicator if the data is not fetched
                    return const CircularProgressIndicator();
                  }),
            ]
          ),
        ),
        floatingActionButton: SpeedDial(
            icon: Icons.menu,
            backgroundColor: Colors.blueAccent,
            children: [
              SpeedDialChild(
                child: const Icon(Icons.menu_rounded),
                label: 'Main',
                backgroundColor: Colors.blue,
                onTap: () {
                  // Navigate to the main screen using a named route.
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const BoardMain(),),);
                },
              ),
            ]
        ),
    );
  }

}


