import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  Future<void> initialize() async {
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(seconds: 10),
    ));
    
    await _remoteConfig.setDefaults(const {
      'max_journals_displayed': 10,
      'max_keywords_displayed': 10,
    });
    
    try {
      await _remoteConfig.fetchAndActivate();
    } catch (_) {
      // Ignore network errors on init
    }
  }

  int get maxJournals => _remoteConfig.getInt('max_journals_displayed');
  int get maxKeywords => _remoteConfig.getInt('max_keywords_displayed');

  Future<void> refresh() async {
    await _remoteConfig.fetchAndActivate();
  }
}
