// https://betterprogramming.pub/hide-your-passwords-e9154bbb8db4
// https://pub.dev/packages/flutter_string_encryption
// https://gist.github.com/Andrious/51ab198ad6128b55a70d6b1bc32f8136#file-remote_config-dart
// https://pub.dev/packages/firebase_remote_config/example
// https://tsvillain.medium.com/update-flutter-app-remotely-using-firebase-remote-config-69aadba275f7
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {

  late final FirebaseRemoteConfig _remoteConfig;

  Future<void> initState() async {
    // Using zero duration to force fetching from remote server.
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(fetchTimeout: const Duration(seconds: 10), minimumFetchInterval: Duration.zero));
    // Fetching and activating
    await _remoteConfig.fetchAndActivate();
  }

  Future<FirebaseRemoteConfig> setupRemoteConfig() async {
    await Firebase.initializeApp();
    final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.ensureInitialized();
    // To force fetching from remote server.
    await remoteConfig.setConfigSettings(RemoteConfigSettings(fetchTimeout: const Duration(seconds: 10), minimumFetchInterval: const Duration(hours: 0)));
    // Fetching and activating
    await remoteConfig.fetchAndActivate();
    RemoteConfigValue(null, ValueSource.valueStatic);
    return remoteConfig;
  }

}