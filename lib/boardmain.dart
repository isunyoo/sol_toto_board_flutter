import 'dart:io';
import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:eth_toto_board_flutter/import.dart';
import 'package:eth_toto_board_flutter/history.dart';
import 'package:eth_toto_board_flutter/profile.dart';
import 'package:eth_toto_board_flutter/generate.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:eth_toto_board_flutter/utilities/web3dartutil.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BoardMain(),
    ),
  );
}

class BoardMain extends StatelessWidget {
  const BoardMain({Key? key}) : super(key: key);
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ethereum Toto(6/45)',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Blockchain Ethereum Lotto(6/45)\n[성재의 인생역전 대박꿈]'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Initialize the Web3DartHelper class from utility packages
  Web3DartHelper web3util = Web3DartHelper();
  int requestedGames = 1;
  var allArrayData=[];
  late String currentBlkNum='', storedBlkNum='', storedTxHash='', myAddress='', balanceEther='', balanceUsd='', arrayLength='';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initialSetup();
  }

  Future<void> initialSetup() async {
    // Initialize web3utility
    await web3util.initState();
    await readTransactionInfoJson();
    myAddress = await web3util.getAddress();
    // No account has imported yet in vault database
    if(myAddress == ''){
      // Navigate to the main screen using a named route.
      Navigator.push(context, MaterialPageRoute(builder: (context) => const ImportKey()));
    } else {
      // currentBlkNum = await web3util.getBlkNum();
      balanceEther = await web3util.getEthBalance();
      balanceUsd = await web3util.getConvUSD();
      arrayLength = await web3util.getArrayLength();
      allArrayData = await web3util.getAllArray();
      // arrayData = await web3util.getArray(1);
    }
    setState(() {
      // currentBlkNum;
      storedBlkNum;
      storedTxHash;
      myAddress;
      balanceEther;
      balanceUsd;
      arrayLength;
      allArrayData;
    });
  }

  // Read transaction info to json file
  Future<void> readTransactionInfoJson() async {
    // Retrieve "AppData Directory" for Android and "NSApplicationSupportDirectory" for iOS
    final directory = await getApplicationDocumentsDirectory();
    // Check if a file exists synchronously
    var fileExist = File("${directory.path}/transactionInfoVault.json").existsSync();
    // Fetch a json file
    File file = await File("${directory.path}/transactionInfoVault.json").create();
    if(!fileExist) {
      String fileContent=json.encode({
        "blockNumber": "0",
        "transactionHash": "0x"
      });
      // Write to file using dummy contents
      await file.writeAsString(fileContent);
    }
    // Read the file from the json file
    final contents = await file.readAsString();
    final jsonContents = await json.decode(contents);
    storedBlkNum = jsonContents['blockNumber'];
    storedTxHash = jsonContents['transactionHash'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Column(children: <Widget>[
          Row(
            children: const <Widget>[ Expanded(
              child: Text(
                "\nWallet Address:",
                textScaleFactor: 1.6,
              ),
            ),
            ],
          ),
          Row(
            children: <Widget>[ Expanded(
              child: Text(
                myAddress,
                textScaleFactor: 1.2,
              ),
            ),
            ],
          ),
          Row(
            children: <Widget>[ Expanded(
              child: Text(
                "Ethereum : $balanceEther [ETH] \nUSD : $balanceUsd [\$]",
                textScaleFactor: 1.6,
              ),
            ),
            ],
          ),
          // Row(
          //   children: <Widget>[ Expanded(
          //     child: Text(
          //       "Current BlockNum: $currentBlkNum",
          //       textScaleFactor: 1.6,
          //     ),
          //   ),
          //   ],
          // ),
          Row(
            children: <Widget>[ Expanded(
                child: RichText(
                    text: TextSpan(
                        children: [
                          const TextSpan(
                            style: TextStyle(color: Colors.black, fontSize: 23),
                            text: "\nCurrent Stored Slot Data \nat BlockChain ",
                          ),
                          TextSpan(
                              style: const TextStyle(color: Colors.blueAccent, fontSize: 20),
                              text: storedBlkNum,
                              recognizer: TapGestureRecognizer()..onTap =  () async{
                                var url = "https://sepolia.etherscan.io/tx/$storedTxHash";
                                if (await canLaunch(url)) {
                                  await launch(url);
                                } else {
                                  throw 'Could not launch $url';
                                }
                              }
                          ),
                        ]
                    ))
            ),],
          ),
          Row(
            children: <Widget>[ Expanded(
                child: ListView.builder (
                    primary: false,
                    shrinkWrap: true,
                    scrollDirection: Axis.vertical,
                    itemCount: allArrayData.length,
                    // A Separate Function called from itemBuilder
                    itemBuilder: (BuildContext ctxt, int index) {
                      return Text("${index+1}: " + allArrayData[index].toString(), textScaleFactor: 2.0);
                    }
                )
            ),],
          ),
          Row(
            children: const <Widget>[ Expanded(
              child: Text("\nHow Many New Games to play :", textScaleFactor: 1.5),
            )],
          ),
          Row(
            children: <Widget>[ Expanded(
                child: NumberPicker(
                  value: requestedGames,
                  minValue: 1,
                  maxValue: 10,
                  step: 1,
                  itemHeight: 50,
                  axis: Axis.vertical,
                  onChanged: (value) => setState(() => requestedGames = value),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.black26),
                  ),
                ),
            ),],
          ),
        ],),),
      floatingActionButton: SpeedDial(
          icon: Icons.menu,
          backgroundColor: Colors.blueAccent,
          children: [
            SpeedDialChild(
              child: const Icon(Icons.party_mode_sharp),
              label: 'Generate',
              backgroundColor: Colors.blue,
              onTap: () {
                // print(requestedGames);
                var randomSlots = web3util.generateSlots(requestedGames);
                Navigator.push(context, MaterialPageRoute(builder: (_) => GeneratedOutput(passedValue1: randomSlots),),);
              },
            ),
            SpeedDialChild(
              child: const Icon(Icons.archive),
              label: 'History',
              backgroundColor: Colors.blue,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryOutput(),),);
              },
            ),
            SpeedDialChild(
              child: const Icon(Icons.account_circle_sharp),
              label: 'Profile',
              backgroundColor: Colors.blue,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(passAddressValue: myAddress)));
              },
            ),
          ]),
    );
  }
}