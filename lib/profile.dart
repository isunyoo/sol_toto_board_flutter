import 'dart:convert';
import 'dart:collection';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jdenticon_dart/jdenticon_dart.dart';
import 'package:eth_toto_board_flutter/import.dart';
import 'package:eth_toto_board_flutter/boardmain.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:eth_toto_board_flutter/screens/login.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:eth_toto_board_flutter/models/inventory.dart';
import 'package:eth_toto_board_flutter/utilities/web3dartutil.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:eth_toto_board_flutter/utilities/authenticator.dart';

class ProfilePage extends StatefulWidget {
  final String passAddressValue;
  const ProfilePage({Key? key, required this.passAddressValue}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Selected Account Address
  late String _currentAddress = widget.passAddressValue;

  // Initialize the Web3DartHelper class from utility packages
  Web3DartHelper web3util = Web3DartHelper();

  // To fetch remote config from Firebase Remote Config
  late final RemoteConfig remoteConfig = RemoteConfig.instance;

  // Create a DatabaseReference which references a node called dbRef
  // late final DatabaseReference dbRef = FirebaseDatabase(
  //     databaseURL: jsonDecode(remoteConfig.getValue('Connection_Config')
  //         .asString())['Firebase']['Firebase_Database']).reference();
  late final DatabaseReference dbRef = FirebaseDatabase.instance.ref();

  // The user's ID which is unique from the Firebase project
  User? user = FirebaseAuth.instance.currentUser;

  // To access the snapshot.key from Vaults DataSnapshot to use a key below 'vaults/${user?.uid}'
  List<String> childSnapshotKeyList = [];

  // Logout Status
  bool _isSigningOut = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initialSetup();
  }

  Future<void> initialSetup() async {
    // Initialize web3utility
    await web3util.initState();
    // DatabaseReference, trigger that the user is online:
    // await dbRef.set(true);
  }

  // Display a snackbar notification widget
  static SnackBar customSnackBar({required String content}) {
    return SnackBar(
      backgroundColor: Colors.black,
      content: Text(
        content,
        style: const TextStyle(color: Colors.redAccent, letterSpacing: 0.5),
      ),
    );
  }

  // Retrieve and update account values
  Future<List<InventoryModel>> _getInventoryDetails() async {
    List<InventoryModel> inventoryList = [];
    List<Map<dynamic, dynamic>> accountList = [];
    // Get the key and value properties data from returning DataSnapshot vaults' values
    await dbRef.child('vaults/${user?.uid}').once().then((DatabaseEvent snapshotResult){
      if(snapshotResult.snapshot.value == null ) {
        accountList.clear();
      } else {
        final LinkedHashMap hashMapValue = snapshotResult.snapshot.value as LinkedHashMap;
        accountList.clear();
        childSnapshotKeyList.clear();
        Map<dynamic, dynamic> mapValues = hashMapValue;
        mapValues.forEach((key, mapValues) {
          accountList.add(mapValues);
          // Store each snapshot.key under own firebase UID:
          childSnapshotKeyList.add(key);
        });
      }
    });
    // Add vaults' inventoryList data with mapping InventoryModel class
    for(int i=0; i<accountList.length; i++){
      String address = accountList[i]['accountAddress'];
      String ethPrice = await web3util.getAccountEthBalance(address);
      String usdPrice = await web3util.getConvEthUSD(ethPrice);
      inventoryList.add(InventoryModel(accountAddress: address, ethValue: ethPrice, usdValue: usdPrice));
    }
    return inventoryList;
  }

  // Jdenticon Display Widget
  Widget _getCardWithIcon(String name) {
    final String rawSvg = Jdenticon.toSvg(name);
    return Card(
      child: Column(
        children: <Widget>[
          const SizedBox(
            height: 5.0,
          ),
          SvgPicture.string(
            rawSvg,
            fit: BoxFit.contain,
            height: 50,
            width: 50,
            color: Colors.lightBlueAccent,
          ),
        ],
      ),
    );}

  // QRCode Display Widget
  Widget _qrContentWidget() {
    return  Container(
      color: const Color(0xFFFFFFFF),
      child: SingleChildScrollView(
        child:  Column(
          children: <Widget>[
            Row(
              children: <Widget>[ Expanded(
                child: Text("\n Name: ${user?.displayName}", textScaleFactor: 1.5),
              ),],
            ),
            Row(
              children: <Widget>[ Expanded(
                child: Text(" Email: ${user?.email}", textScaleFactor: 1.5),
              ),],
            ),
            Row(
              children: <Widget>[
                Padding(padding: const EdgeInsets.all(5.0),
                  child: _getCardWithIcon(_currentAddress),
                ),
                const Padding(padding: EdgeInsets.all(5.0),
                  child: Text("\nSelected Account Address: ", textScaleFactor: 1.5),
                ),
              ],
            ),
            Row(
              children: <Widget>[ Expanded(
                child: Text(" $_currentAddress\n", textScaleFactor: 1.2),
              ),],
            ),
            Center(
                child: QrImage(
                  data: _currentAddress,
                  version: QrVersions.auto,
                  size: 200,
                  gapless: false,
                )
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[ Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(elevation: 3),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _currentAddress)).then((value) {
                        final snackBar = SnackBar(
                          content: const Text('Copied to Clipboard'),
                          action: SnackBarAction(
                            label: 'Undo',
                            onPressed: () {
                              Clipboard.setData(const ClipboardData(text: ''));
                            },
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      });
                    },
                    child: const Text('Copy Address', style: TextStyle(color: Colors.white)),
                  )
              ),],
            ),
            Row(
              children: const <Widget>[ Expanded(
                child: Text(
                  "\n My Stored Accounts: ",
                  textScaleFactor: 1.2,
                ),
              ),],
            ),
            // Account Inventory in firebase vaults
            _getAccountVaults(),
          ],
        ),
      ),
    );
  }

  // Account Vaults Display Widget
  Column _getAccountVaults() {
    return
      Column(
          children: <Widget>[
            FutureBuilder(
                future: _getInventoryDetails(),
                builder: (BuildContext context, AsyncSnapshot snapshotResult) {
                  if(snapshotResult.connectionState == ConnectionState.done) {
                    if(!snapshotResult.hasData) {
                      return const Text('\n No Account Data has existed.', textScaleFactor: 1.5, style: TextStyle(color: Colors.red));
                    } else {
                      // 'DataSnapshot' value != null
                      return ListView.builder(
                          primary: false,
                          shrinkWrap: true,
                          itemCount: snapshotResult.data.length,
                          itemBuilder: (BuildContext context, int index) {
                            InventoryModel inventory = snapshotResult.data[index];
                            return Card(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  RichText(
                                      text: TextSpan(
                                          children: [
                                            TextSpan(style: const TextStyle(color: Colors.black, fontSize: 14), text: "${index + 1}. Address: "),
                                            TextSpan(
                                                style: const TextStyle(color: Colors.blueAccent, fontSize: 14),
                                                text: inventory.accountAddress,
                                                recognizer: TapGestureRecognizer()..onTap = () {
                                                  setState(() {
                                                    _currentAddress = inventory.accountAddress;
                                                    // Get the latest timestamp for vaults' account address
                                                    int _timestamp = DateTime.now().microsecondsSinceEpoch;
                                                    // Update timestamp on vaults database by snapshot.key
                                                    dbRef.child('vaults/${user?.uid}').child(childSnapshotKeyList[index]).update({'timestamp': _timestamp});
                                                    // Notify to load another account address
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      customSnackBar(
                                                        content: 'Account($_currentAddress) has changed successfully.',
                                                      ),
                                                    );
                                                  });
                                                }
                                            ),
                                          ]
                                      )),
                                  Text("Ethereum: " +inventory.ethValue+" [ETH]"+" , USD: " +inventory.usdValue+" [\$]"),
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
      );
  }

  @override
  Widget build(BuildContext context) {
    // No account has imported yet in vault database
    if(_currentAddress == '') {
      // The delay to route BoardMain Page Scaffold
      Future.delayed(const Duration(milliseconds: 100)).then((_) {
        // Navigate to the main screen using a named route.
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ImportKey()));
      });
    }
    // SigningOut Status Parameter
    _isSigningOut;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet Account Information'),
        automaticallyImplyLeading: false,
      ),
      // QRCode Display Widget Function
      body: _qrContentWidget(),
      floatingActionButton: SpeedDial(
          icon: Icons.menu,
          backgroundColor: Colors.blueAccent,
          children: [
            SpeedDialChild(
              child: const Icon(Icons.vpn_key_rounded),
              label: 'Import Key',
              backgroundColor: Colors.blue,
              onTap: () {
                // Navigate to the main screen using a named route.
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ImportKey()));
              },
            ),
            SpeedDialChild(
              child: const Icon(Icons.exit_to_app),
              label: 'Logout',
              backgroundColor: Colors.blue,
              onTap: () async {
                setState(() {
                  _isSigningOut = true;
                });
                // Create an OnDisconnect instance for your ref and set to false and the Firebase backend will then only set the value on your ref to false, when your client goes offline.
                OnDisconnect onDisconnect = dbRef.onDisconnect();
                // await onDisconnect.set(false);
                // LogOut Function Call
                await FireAuth.signOutWithGoogle(context: context);
                setState(() {
                  _isSigningOut = false;
                });
                // Navigate Push Replacement which will not going back and return back to the LoginPage
                Navigator.of(context).popUntil((route) => route.isFirst);
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext context) => const LoginPage()));
              },
            ),
            SpeedDialChild(
              child: const Icon(Icons.menu_rounded),
              label: 'Main',
              backgroundColor: Colors.blue,
              onTap: () {
                // Navigate to the main screen using a named route.
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BoardMain(),),);
              },
            ),
          ]),
    );
  }
}