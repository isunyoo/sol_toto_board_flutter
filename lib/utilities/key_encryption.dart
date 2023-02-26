// https://medium.com/flutter-community/keep-and-encrypt-data-with-flutter-efea5e8aa97e
import 'package:encrypt/encrypt.dart';

class KeyEncrypt {

  // Activate the AES Symmetric encrypt with keyring input
  String getEncryptionKeyRing(String privateKey, String passphrase) {
    // Gets a key from the given keyRing
    final key = Key.fromUtf8(passphrase);
    final iv = IV.fromLength(8);
    // To remove padding, pass null to the padding named parameter on the constructor(No/zero padding):
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc, padding: null));
    final encryptedPrivateKey = encrypter.encrypt(privateKey, iv: iv);

    return encryptedPrivateKey.base64;
  }

  // Activate the AES Symmetric decrypt with keyring input
  String getDecryptionKeyRing(String encryptedPrivateKey, String passphrase) {
    final key = Key.fromUtf8(passphrase);
    final iv = IV.fromLength(8);
    // To remove padding, pass null to the padding named parameter on the constructor(No/zero padding):
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc, padding: null));
    // To decrypt with keyRing
    final decryptedPrivateKey = encrypter.decrypt(Encrypted.from64(encryptedPrivateKey), iv: iv);

    return decryptedPrivateKey;
  }

  // Activate the AES Symmetric encrypt without passphrase input
  String getEncryption(String privateKey) {
    final key = Key.fromLength(32);
    final iv = IV.fromLength(16);
    final encrypter = Encrypter(AES(key, padding: null));
    final _encryptedPrivateKey = encrypter.encrypt(privateKey, iv: iv);

    return _encryptedPrivateKey.base64;
  }

  // Activate the AES Symmetric decrypt without passphrase input
  String getDecryption(String encryptedPrivateKey) {
    final key = Key.fromLength(32);
    final iv = IV.fromLength(16);
    final encrypter = Encrypter(AES(key, padding: null));
    final _decryptedPrivateKey = encrypter.decrypt(Encrypted.from64(encryptedPrivateKey), iv: iv);

    return _decryptedPrivateKey;
  }

}