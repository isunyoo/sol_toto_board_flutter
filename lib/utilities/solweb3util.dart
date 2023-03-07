import 'package:flutter/services.dart';
import 'package:solana_web3/programs/system.dart';
import 'package:solana_web3/solana_web3.dart' as web3;
import 'package:firebase_remote_config/firebase_remote_config.dart';

class Web3SolHelper {

  late final cluster;
  late final connection;

  // To fetch remote config from Firebase Remote Config
  late FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;

  Future<void> initState() async {
    // Create a connection to the devnet cluster.
    cluster = web3.Cluster.devnet;
    connection = web3.Connection(cluster);
    print('Creating accounts...\n');
  }

  // Transfer tokens from one wallet to another.
  Future<void> transferToken() async {
    // Create a wallet to transfer tokens from.
    final wallet1 = web3.Keypair.generateSync();
    final address1 = wallet1.publicKey;

    // Credit the wallet that will be sending the tokens.
    await connection.requestAirdropAndConfirmTransaction(
      address1,
      web3.solToLamports(2).toInt(),
    );

    // Create a wallet to transfer tokens to.
    final wallet2 = web3.Keypair.generateSync();
    final address2 = wallet2.publicKey;

    // Check the account balances before making the transfer.
    final balance = await connection.getBalance(address1);
    print('Account $address1 has an initial balance of $balance lamports.');
    print('Account $address2 has an initial balance of 0 lamports.\n');

    // Create a System Program instruction to transfer 1 SOL from [address1] to [address2].
    final transaction = web3.Transaction();
    transaction.add(
      SystemProgram.transfer(
        fromPublicKey: address1,
        toPublicKey: address2,
        lamports: web3.solToLamports(1),
      ),
    );

    // Send the transaction to the cluster and wait for it to be confirmed.
    print('Send(1 SOL) and confirm transaction...\n');
    await connection.sendAndConfirmTransaction(
      transaction,
      signers: [wallet1], // Fee payer + transaction signer.
    );

    // Check the updated account balances.
    final balance1 = await connection.getBalance(address1);
    final balance2 = await connection.getBalance(address2);
    print('Account $address1 has an updated balance of $balance1 lamports.');
    print('Account $address2 has an updated balance of $balance2 lamports.');
  }

}