import 'dart:io';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';
import 'firebase_options.dart';
import 'package:eth_toto_board_flutter/utilities/web3dartutil.dart';
import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:printing/printing.dart';
import 'dart:typed_data' show Uint8List;
import 'package:path_provider/path_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:eth_toto_board_flutter/boardmain.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:eth_toto_board_flutter/models/txreceipt.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:eth_toto_board_flutter/utilities/remote_config.dart';

class Output extends StatefulWidget {
  final List passedValue1;
  final int passedValue2;
  final String passedValue3;
  const Output({Key? key, required this.passedValue1, required this.passedValue2, required this.passedValue3}) : super(key: key);

  @override
  State<Output> createState() => _OutputState();
}

class _OutputState extends State<Output> {
  // To create a new Firebase Remote Config instance
  late FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  // Initialize the Web3DartHelper class from utility packages
  Web3DartHelper web3util = Web3DartHelper();
  late AnimationController controller;
  // References a node called txreceipts
  late final DatabaseReference _txReceiptRef;
  // The user's ID which is unique from the Firebase project
  String? userId = FirebaseAuth.instance.currentUser?.uid;
  // FutureBuilder helps in awaiting long-running operations in the Scaffold.
  // final Future<FirebaseApp> _future = Firebase.initializeApp();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initialSetup();
  }

  Future<void> initialSetup() async {
    await web3util.initState();
    // Firebase Initialize App Function
    FirebaseApp fapp = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    WidgetsFlutterBinding.ensureInitialized();
    // To fetch remote config from Firebase Remote Config
    RemoteConfigService remoteConfigService = RemoteConfigService();
    _remoteConfig = await remoteConfigService.setupRemoteConfig();
    // Create a DatabaseReference which references a node called dbRef
    _txReceiptRef = FirebaseDatabase.instanceFor(
        databaseURL: jsonDecode(_remoteConfig.getValue('Connection_Config')
            .asString())['Firebase']['Firebase_Database'], app: fapp).ref();
  }

  // AlertDialog Wiget
  void _showDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Transaction in Progress Alert!"),
          content: const Text("Transaction is still processing, Try again later."),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Function takes a txReceipt as a parameter and uses a DatabaseReference to save the JSON message to Realtime Database.
  Future<void> saveTxReceipt(TransactionReceipt txReceipt) async {
    await _txReceiptRef.child('txreceipts/$userId').push().set(txReceipt.toJson());
  }

  // Retrieving data from the given Realtime Database reference
  Future<void> printFirebase() async {
    await _txReceiptRef.child('txreceipts/$userId').once().then((DatabaseEvent snapshot) {
      debugPrint('Data1 : ${snapshot.toString()}');
    });
    await _txReceiptRef.child('txreceipts/$userId').once().then((DatabaseEvent snapshot) {
      Map<dynamic, dynamic> values = snapshot.toString() as Map;
      values.forEach((key, values){
        debugPrint(values);
      });
    });
  }

  // Updating data to Realtime FirebaseDatabase
  Future<void> updateData() async {
    String slotData = widget.passedValue1.toString();
    // Get transaction details as Class
    var txReceipt = await web3util.getTransactionDetails(widget.passedValue3);
    // HexEncoder convert a list of bytes to a string
    Uint8List? transactionHashBytes = txReceipt?.transactionHash;
    String transactionHash = hex.encode(transactionHashBytes!);
    int? transactionIndex = txReceipt?.transactionIndex.hashCode;
    // HexEncoder convert a list of bytes to a string
    Uint8List? blockHashBytes = txReceipt?.blockHash;
    String blockHash = hex.encode(blockHashBytes!);
    int? blockNum = txReceipt?.blockNumber.blockNum;
    String? from = txReceipt?.from.toString();
    String? to = txReceipt?.to.toString();
    int? cumulativeGasUsed = txReceipt?.cumulativeGasUsed.hashCode;
    int? gasUsed = txReceipt?.gasUsed.hashCode;
    bool? status = txReceipt?.status;
    String date = "${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())}(SGT)";
    int timestamp = DateTime.now().microsecondsSinceEpoch;

    // To save a txReceipt to Realtime Database.
    final _txReceipt = TransactionReceipt(slotData, transactionHash, transactionIndex, blockHash, blockNum, from, to, cumulativeGasUsed, gasUsed, status, date, timestamp);
    saveTxReceipt(_txReceipt);
  }

  // Uploading raw data to FirebaseStorage
  Future<void> uploadData() async {
    String myAddress = await web3util.getAddress();
    String txReceipt = 'Slot Numbers: ${widget.passedValue1.toString()}\n${await web3util.getTransactionDetails(widget.passedValue3)}';
    List<int> encoded = utf8.encode(txReceipt);
    Uint8List data = Uint8List.fromList(encoded);

    // To create a storage reference
    Reference storageRef = FirebaseStorage.instance.ref('txReceipts/$myAddress/${widget.passedValue3}.json');
    // Upload raw data
    await storageRef.putData(data);
    // // Get raw data
    // Uint8List? downloadedData = await _storageRef.getData();
    // // Print downloadedData
    // print(utf8.decode(downloadedData!));
  }

  // PDF Creation
  Future<void> receiptPDF() async {
    // Get transaction details as String
    String txReceiptStr = (await web3util.getTransactionDetails(widget.passedValue3)).toString();
    if(txReceiptStr.length<10) {
      _showDialog(context);
    } else if(txReceiptStr.length>200) {
      // Print an HTML document:
      await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async =>
          await Printing.convertHtml(
            format: format,
            html: '<html><body><p><h1>Slot Numbers: ${widget.passedValue1.toString()} <br> $txReceiptStr</h1></p></body></html>',
          ));
    }
  }

  // Write transaction info to json file
  Future<void> writeTransactionInfoJson() async {
    // Retrieve "AppData Directory" for Android and "NSApplicationSupportDirectory" for iOS
    final directory = await getApplicationDocumentsDirectory();
    // Fetch a json file
    File file = await File("${directory.path}/transactionInfoVault.json").create(recursive: true);
    // Get transaction block
    var transactionBlock = await web3util.getTransactionBlock(widget.passedValue3);
    // Convert json object to String data using json.encode() method
    String fileContent=json.encode({
      "blockNumber": transactionBlock,
      "transactionHash": widget.passedValue3
    });
    // Write to file using writeAsString which takes string argument
    await file.writeAsString(fileContent);
  }

  // Allows send emails from flutter using native platform functionality
  Future<void> sendEmail() async {
    // Get transaction details as String
    String txReceiptStr = (await web3util.getTransactionDetails(widget.passedValue3)).toString();

    final Email email = Email(
      body: 'Slot Numbers: ${widget.passedValue1.toString()} \n\n EtherScan: https://sepolia.etherscan.io/tx/${widget.passedValue3} \n\n $txReceiptStr',
      subject: 'Tx Receipt: ${widget.passedValue3}',
      // recipients: ['recipients@example.com'],
      // cc: ['cc@example.com'],
      // bcc: ['bcc@example.com'],
      // attachmentPaths: ['$file'],
      isHTML: false,
    );
    await FlutterEmailSender.send(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Blockchain Transacted Data'),
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          child: Column(children: <Widget>[
            Row(
              children: <Widget>[ Expanded(
                child: Text("\nNewly Stored Slot Numbers: ${widget.passedValue2}", textScaleFactor: 1.8),
              ),],
            ),
            Row(
              children: const <Widget>[ Expanded(
                child: Text(
                  "Newly Stored Slot Data: ",
                  textScaleFactor: 1.8,
                ),
              ),],
            ),
            Row(
              children: <Widget>[ Expanded(
                  child: ListView.builder (
                      primary: false,
                      shrinkWrap: true,
                      scrollDirection: Axis.vertical,
                      itemCount: widget.passedValue1.length,
                      // A Separate Function called from itemBuilder
                      itemBuilder: (BuildContext ctxt, int index) {
                        return Text("${index+1}: " + widget.passedValue1[index].toString(), textScaleFactor: 2.0);
                      }
                  )
              ),],
            ),
            Row(
              children: <Widget>[ Expanded(
                  child: RichText(
                      text: TextSpan(
                          children: [
                            const TextSpan(
                              style: TextStyle(color: Colors.black, fontSize: 20),
                              text: "\nTransaction Hash: ",
                            ),
                            TextSpan(
                                style: const TextStyle(color: Colors.blueAccent, fontSize: 15),
                                text: "Click here details in Etherscan",
                                recognizer: TapGestureRecognizer()..onTap =  () async{
                                  var url = "https://sepolia.etherscan.io/tx/${widget.passedValue3}";
                                  if (await canLaunchUrlString(url)) {
                                    await launchUrlString(url);
                                  } else {
                                    throw 'Could not launch $url';
                                  }
                                }
                            ),
                          ]
                      ))
              ),],
            ),
          ],),
        ),
        floatingActionButton: SpeedDial(
            icon: Icons.menu,
            backgroundColor: Colors.blueAccent,
            children: [
              SpeedDialChild(
                child: const Icon(Icons.print),
                label: 'Print Receipt',
                backgroundColor: Colors.blue,
                onTap: () async {
                  await receiptPDF();
                },
              ),
              SpeedDialChild(
                child: const Icon(Icons.email),
                label: 'Email Receipt',
                backgroundColor: Colors.blue,
                onTap: () async {
                  // Get transaction details as String
                  String txReceipt = (await web3util.getTransactionDetails(widget.passedValue3)).toString();
                  if(txReceipt.length<10) {
                    _showDialog(context);
                  } else if(txReceipt.length>200) {
                    await sendEmail();
                  }
                },
              ),
              SpeedDialChild(
                child: const Icon(Icons.menu_rounded ),
                label: 'Main',
                backgroundColor: Colors.blue,
                onTap: () async {
                  // Get transaction details as String
                  String txReceipt = (await web3util.getTransactionDetails(widget.passedValue3)).toString();
                  if(txReceipt.length<10) {
                    _showDialog(context);
                  } else if(txReceipt.length>200) {
                    await writeTransactionInfoJson();
                    await uploadData();
                    await updateData();
                    // Navigate to the main screen using a named route.
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const BoardMain(),),);
                  }
                },
              ),
            ]
        ),
    );
  }
}