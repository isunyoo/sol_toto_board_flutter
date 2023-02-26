class VaultContentModel {
  final int timestamp;
  final String accountAddress;
  final String encryptedPrivateKey;

  VaultContentModel({
    required this.timestamp,
    required this.accountAddress,
    required this.encryptedPrivateKey
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'timestamp': timestamp,
    'accountAddress': accountAddress,
    'encryptedPrivateKey': encryptedPrivateKey
  };
}