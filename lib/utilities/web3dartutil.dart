import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:convert/convert.dart';
import 'package:flutter/services.dart';
import 'package:web3dart/web3dart.dart' as web3;
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:eth_toto_board_flutter/utilities/key_encryption.dart';
import 'package:eth_toto_board_flutter/firebase_options.dart';

class Web3DartHelper {
  late Client httpClient;
  late web3.Web3Client ethClient;
  late String _privateKey;
  // Get DataSnapshot value lists
  List<Map<dynamic, dynamic>> lists = [];

  // To fetch remote config from Firebase Remote Config
  late FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;

  // Reference a node called dbRef
  late DatabaseReference dbRef = FirebaseDatabase.instance.ref();

  // The user's ID which is unique from the Firebase project
  User? userId1 = FirebaseAuth.instance.currentUser;
  String? userId2 = FirebaseAuth.instance.currentUser?.uid;

  @override
  Future<void> initState() async {
    // To fetch local config from assets
    // await dotenv.load(fileName: "assets/.env");

    // To fetch remote config from Firebase Remote Config
    Map<String, dynamic> mapConnValues = json.decode(remoteConfig.getValue("Connection_Config").asString());
    // debugPrint(mapConnValues["Sepolia"]["Sepolia_HTTPS"]);
    // debugPrint(mapConnValues["Firebase"]["Firebase_Database"]);

    // Initialize the httpClient and ethClient in the initState() method.
    // Client class is the interface for HTTP clients that take care of maintaining persistent connections
    httpClient = Client();
    // Web3Client class used for for sending requests over an HTTP JSON-RPC API endpoint to Ethereum clients
    // ethClient = Web3Client(dotenv.get('Ganache_HTTP'), httpClient);
    // ethClient = Web3Client(dotenv.get('Sepolia_HTTPS'), httpClient);
    // ethClient = web3.Web3Client(mapConnValues["Sepolia"]["Sepolia_HTTPS"], httpClient);
    // WebSocket stream channels
    ethClient = web3.Web3Client(mapConnValues["Sepolia"]["Sepolia_HTTPS"], httpClient, socketConnector: () {
      return IOWebSocketChannel.connect(mapConnValues["Sepolia"]["Sepolia_Websockets"]).cast<String>();
    });

    // Initialized default app
    FirebaseApp fapp = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // debugPrint('Initialized default app $fapp');

    // To fetch remote config from Firebase Remote Config
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 1)
    ));
    await remoteConfig.fetchAndActivate();

    // Create a DatabaseReference which references a node called dbRef
    // dbRef = FirebaseDatabase.instanceFor(databaseURL: mapConnValues["Firebase"]["Firebase_Database"], app: fapp).ref();
    // dbRef = FirebaseDatabase.instance.ref();
    print(userId1);
    print(userId1.runtimeType);
    print(userId2);
    print(userId2.runtimeType);
    final snapshot = await dbRef.child('vaults/$userId2').get();
    if (snapshot.exists) {
      print(snapshot.value);
    } else {
      print('No data available.');
    }

    // Retrieve current database snapshot on vaults for landing page
    lists = await getInitialVaultData();
    if(lists.isEmpty){
      // No account has imported yet in vault database
      _privateKey = '';
    } else {
      // Get PrivateKey Definition from firebaseDatabase Vaults data
      _privateKey = KeyEncrypt().getDecryption(lists[0]["encryptedPrivateKey"]);
      for (int i = 0; i < lists.length; i++) {
        debugPrint(lists[i]["encryptedPrivateKey"]);
        String encryptedPrivateKey = lists[i]["encryptedPrivateKey"];
        debugPrint(KeyEncrypt().getDecryption(encryptedPrivateKey));
      }
    }

    // String _encryptedPrivateKey = KeyEncrypt().getEncryptionKeyRing(_privateKey, 'my32lengthsupers');
    String encryptedPrivateKey = KeyEncrypt().getEncryption(_privateKey);
    debugPrint('Encrypted Key: $encryptedPrivateKey');
    // String _decryptedPrivateKey = KeyEncrypt().getDecryptionKeyRing(_encryptedPrivateKey, 'my32lengthsupers');
    String decryptedPrivateKey = KeyEncrypt().getDecryption(encryptedPrivateKey);
    debugPrint('Decrypted Key:  $decryptedPrivateKey');

    // Test for Tx Input Decode
    // await queryTransactedInput('0x411b37b45251982bf703cb60e84c6d1d7e03a243134dc459593c2bc9a82b50da');
  }

  // Get the key and value properties data from returning DataSnapshot vaults' values for landing page
  Future<List<Map>> getInitialVaultData() async {
    // Retrieve last one timestamp from vaults datasnapshot
    DataSnapshot snapshotResult = (await dbRef.child('vaults/$userId2').orderByChild('timestamp').limitToLast(1).once()).snapshot;
    if(snapshotResult.value == null ) {
      lists.clear();
      return lists;
    } else {
      final Object? hashMapValue = snapshotResult.value;
      lists.clear();
      Map<dynamic, dynamic>? mapValues = hashMapValue as Map?;
      mapValues?.forEach((key, mapValues) {
        lists.add(mapValues);
      });
      return lists;
    }
  }

  Future<String> getBlkNum() async {
    int blkNum = await ethClient.getBlockNumber();
    // print('Current Block Number: $_blkNum');
    return blkNum.toString();
  }

  Future<String> getAddress() async {
    if(_privateKey == ''){
      return '';
    } else {
      var credentials = web3.EthPrivateKey.fromHex(_privateKey);
      var myAddress = await credentials.extractAddress();
      debugPrint('myaddr11111$myAddress');
      return myAddress.toString();
    }
  }

  Future<String> getAccountAddress(String inputPrivateKey) async {
    try {
      var credentials = web3.EthPrivateKey.fromHex(inputPrivateKey);
      var myAddress = await credentials.extractAddress();
      return myAddress.toString();
    } on FormatException {
      return '';
    }
  }

  // Function to return Ethereum values
  Future<String> getEthBalance() async {
    var credentials = web3.EthPrivateKey.fromHex(_privateKey);
    var myAddress = await credentials.extractAddress();
    // print('address: $_address');
    // Get native balance
    var balanceObj = await ethClient.getBalance(myAddress);
    var balanceEther = balanceObj.getValueInUnit(web3.EtherUnit.ether);
    // print('balance before transaction: ${balanceObj.getInWei} wei (${balanceObj.getValueInUnit(EtherUnit.ether)} ether)');
    return balanceEther.toStringAsFixed(4);
  }

  Future<String> getAccountEthBalance(String myAddress) async {
    // Get native balance
    var balanceObj = await ethClient.getBalance(web3.EthereumAddress.fromHex(myAddress));
    var balanceEther = balanceObj.getValueInUnit(web3.EtherUnit.ether);
    // print('balance before transaction: ${balanceObj.getInWei} wei (${balanceObj.getValueInUnit(EtherUnit.ether)} ether)');
    return balanceEther.toStringAsFixed(4);
  }

  // Functions for reading the smart contract and submitting a transaction.
  Future<web3.DeployedContract> loadContract() async {
    String abiCode = await rootBundle.loadString("assets/TotoSlots.json");
    // String contractAddress = dotenv.get('Development_Contract_Address');
    String contractAddress = remoteConfig.getString('Sepolia_Contract_Address');
    final contract = web3.DeployedContract(web3.ContractAbi.fromJson(abiCode, "TotoSlots"), web3.EthereumAddress.fromHex(contractAddress));
    return contract;
  }

  // Function to decode input data from txhash which has transacted previously
  // Future<List> queryTransactedInput(String txhash) async {
  Future<void> queryTransactedInput(String txhash) async {
    var tx = await ethClient.getTransactionByHash(txhash);
    debugPrint(tx.toString());
    debugPrint(tx.runtimeType.toString());
    debugPrint(tx.input.toString());
    debugPrint(hex.encode(tx.input));
    debugPrint(tx.input.runtimeType.toString());  // Uint8List
    web3.DeployedContract totoContract = await loadContract();
    // List funcParams = totoContract.decode_function_input(tx["input"]); // Python Function
    // var funcParams = totoContract.event('saveTotoSlotsData').decodeResults(List<String> topics, String data);
    // print(funcParams);

    // // Extracting some functions and events that we'll need later
    // final txTotoEvent = totoContract.event('saveTotoSlotsData');
    // // Listen for the saveTotoSlotsData event when it's emitted by the contract process
    // final subscription = ethClient
    //     .events(FilterOptions.events(contract: totoContract, event: txTotoEvent))
    //     .take(1)
    //     .listen((event) {
    //       final decoded = txTotoEvent.decodeResults(event.topics!, event.data!);
    //       print(decoded);
    // final from = decoded[0] as EthereumAddress;
    // final to = decoded[1] as EthereumAddress;
    // final value = decoded[2] as BigInt;
    // final input = decoded[3] as BigInt;
    // print('$from sent $value MetaCoins to $to input $input');
    // });
    // await subscription.asFuture();
    // await subscription.cancel();
    // await ethClient.dispose();
  }
  // https://github.com/simolus3/web3dart/blob/development/example/contracts.dart
  // https://issueexplorer.com/issue/simolus3/web3dart/168
  // https://Sepolia.etherscan.io/address/0x82d85cF1331F9410F84D0B2aaCF5e2753a5afa82

  // The submit() function essentially signs and sends a transaction to the blockchain network from web3dart library.
  Future<String> submit(String functionName, List<dynamic> args) async {
    web3.EthPrivateKey credentials = web3.EthPrivateKey.fromHex(_privateKey);
    web3.DeployedContract contract = await loadContract();
    final ethFunction = contract.function(functionName);
    final result = await ethClient.sendTransaction(credentials,
        web3.Transaction.callContract(
            contract: contract,
            function: ethFunction,
            parameters: args,
            nonce: await ethClient.getTransactionCount(await credentials.extractAddress(), atBlock: const web3.BlockNum.pending()),
            maxGas: 6000000
        ),
        chainId: 11155111 // 11155111:Sepolia, 1337:Development
    );
    await ethClient.dispose();
    return result;
  }

  Future<String> submitTotoSlotsData(String functionName, String issuerUID, String issuerName, String issuerEmail, List<dynamic> slotsData, String issuerTime) async {
    web3.EthPrivateKey credentials = web3.EthPrivateKey.fromHex(_privateKey);
    web3.DeployedContract contract = await loadContract();
    final ethFunction = contract.function(functionName);
    final result = await ethClient.sendTransaction(credentials,
        web3.Transaction.callContract(
            contract: contract,
            function: ethFunction,
            parameters: [await credentials.extractAddress(), issuerUID, issuerName, issuerEmail, slotsData, issuerTime],
            // gasPrice: EtherAmount.fromUnitAndValue(EtherUnit.gwei, 20),
            nonce: await ethClient.getTransactionCount(await credentials.extractAddress(), atBlock: const web3.BlockNum.pending()),
            maxGas: 6000000
        ),
        chainId: 11155111 // 11155111:Sepolia, 1337:Development
    );
    await ethClient.dispose();
    return result;
  }

  Future<String> pushArrayData(List<dynamic> args) async {
    // Conversion BigInt Array
    List<dynamic> bigIntsList = [];
    for(var row=0; row<args.length; row++){
      List<BigInt> bigNumberList=[];
      for(var column=0; column<args[row].length; column++){
        // print(args[row][column]);
        bigNumberList.add(BigInt.from(args[row][column]));
      }
      bigIntsList.add(bigNumberList);
    }
    try {
      // Transaction of array_pushData
      var transactionHash = await submit("array_pushData", [bigIntsList]);
      // Hash of the transaction record return(String)
      return transactionHash;
    } catch(e) {
      // print(e);
      return '';
    }
  }

  Future<String> saveArrayData(String issuerUID, String issuerName, String issuerEmail, List<dynamic> slotsData, String issuerTime) async {
    // Conversion BigInt Array
    List<dynamic> bigIntsList = [];
    for(var row=0; row<slotsData.length; row++){
      List<BigInt> bigNumberList=[];
      for(var column=0; column<slotsData[row].length; column++){
        // print(args[row][column]);
        bigNumberList.add(BigInt.from(slotsData[row][column]));
      }
      bigIntsList.add(bigNumberList);
    }
    try {
      // Transaction of setTotoSlotsData
      var transactionHash = await submitTotoSlotsData("setTotoSlotsData", issuerUID, issuerName, issuerEmail, bigIntsList, issuerTime);
      // Hash of the transaction record return(String)
      return transactionHash;
    } catch(e) {
      // print(e);
      return '';
    }
  }

  Future<String> addData(int num) async {
    // uint in smart contract means BigInt
    var bigNum = BigInt.from(num);
    // Transaction of array_pushData
    var transactionHash = await submit("addData", [bigNum]);
    // Hash of the transaction record return(String)
    return transactionHash;
  }

  // The query() function stores the result using the Web3Client call method, which Calls a function defined in the smart contract and returns it's result.
  Future<List<dynamic>> query(String functionName, List<dynamic> args) async {
    final contract = await loadContract();
    final ethFunction = contract.function(functionName);
    final data = await ethClient.call(contract: contract, function: ethFunction, params: args);
    return data;
  }

  Future<String> getArrayLength() async {
    // Transaction of array_getLength
    List<dynamic> result = await query("array_getLength", []);
    // Returns list of results, in this case a list with only the array length
    var arrayLength = result[0].toString();
    return arrayLength;
  }

  Future<List<dynamic>> getArray(int index) async {
    // uint in smart contract means BigInt
    var bigIndex = BigInt.from(index);
    // Transaction of array_getArray
    List<dynamic> result = await query("array_getArray", [bigIndex]);
    // Returns list of results, in this case a list with only the array[index]
    var arrayData = result[0];
    return arrayData;
  }

  Future<List<dynamic>> getAllArray() async {
    // Transaction of array_popAllData
    List<dynamic> result = await query("array_popAllData", []);
    // Returns list of results, in this case a list with all the arrays
    var allArrayData = result[0];
    return allArrayData;
  }

  // Get transaction details receipt
  // Future<String> getTransactionDetails(String transactionHash) async {
  Future<web3.TransactionReceipt?> getTransactionDetails(String transactionHash) async {
    var transactionInfo = await ethClient.getTransactionReceipt(transactionHash);
    // return(transactionInfo.toString());
    return(transactionInfo);
  }

  // Get transaction block
  Future<String> getTransactionBlock(String transactedHash) async {
    var transactionInfo = await ethClient.getTransactionReceipt(transactedHash);
    if (transactionInfo == null) {
      return '';
    }
    return transactionInfo.blockNumber.toString();
  }

  List<dynamic> generateSlots(int maxRows) {
    // Requested rows(length) x 6 columns(matrix)
    int maxColumns = 6;
    // Define min and max value inclusive
    int min = 1, max = 45;

    Random random = Random();
    var randomSlots=[];
    for(var row=0; row<maxRows; row++){
      List<int> numberList=[];
      for(var column=0; numberList.length<maxColumns; column++){
        int randomNumber = min + random.nextInt(max - min);
        if(!numberList.contains(randomNumber)) {
          numberList.add(randomNumber);
        }
        numberList.sort();
      }
      randomSlots.add(numberList);
    }
    // print(randomSlots.runtimeType);
    return randomSlots;
  }

  // Function to return USD conversion values
  Future<String> getConvUSD() async {
    num balanceUSD;
    var balanceEther = await getEthBalance();
    // Make a network request
    Response response = (await get(Uri.parse(remoteConfig.getString('ETH_Price_URL'))));
    // If the server did return a 200 OK response then parse the JSON.
    if (response.statusCode == 200) {
      // print(jsonDecode(response.body)["USD"]);
      // Get the current USD price of cryptocurrency conversion from API URL
      balanceUSD = double.parse(balanceEther) * jsonDecode(response.body)["USD"];
    } else {
      // If the server did not return a 200 OK response then throw an exception.
      throw Exception('Failed to load API');
    }
    // String roundedX = balanceUSD.toStringAsFixed(2);
    return balanceUSD.toStringAsFixed(2);
  }

  Future<String> getConvEthUSD(String balanceEther) async {
    num balanceUSD;
    // Make a network request
    Response response = (await get(Uri.parse(remoteConfig.getString('ETH_Price_URL'))));
    // If the server did return a 200 OK response then parse the JSON.
    if (response.statusCode == 200) {
      // print(jsonDecode(response.body)["USD"]);
      // Get the current USD price of cryptocurrency conversion from API URL
      balanceUSD = double.parse(balanceEther) * jsonDecode(response.body)["USD"];
    } else {
      // If the server did not return a 200 OK response then throw an exception.
      throw Exception('Failed to load API');
    }
    // String roundedX = balanceUSD.toStringAsFixed(2);
    return balanceUSD.toStringAsFixed(2);
  }

}