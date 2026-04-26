import 'dart:async';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../utils/app_logger.dart';

class RemoteConfigService {
  static final RemoteConfigService instance = RemoteConfigService._();
  RemoteConfigService._();

  static const String _tag = 'RemoteConfigService';
  static const String aiHubEnabledKey = 'ai_hub_enabled';

  final FirebaseRemoteConfig _rc = FirebaseRemoteConfig.instance;

  bool get aiHubEnabled => _rc.getBool(aiHubEnabledKey);

  Stream<RemoteConfigUpdate> get onConfigUpdated => _rc.onConfigUpdated;

  Future<void> initialize() async {
    try {
      await _rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        // 1-hour minimum between fetches — respects Firebase quota (200 req/day per app instance)
        minimumFetchInterval: const Duration(hours: 1),
      ));
      await _rc.setDefaults({aiHubEnabledKey: false});
      await _rc.fetchAndActivate();
      AppLogger.debug('RemoteConfig fetched — ai_hub_enabled=$aiHubEnabled', _tag);
    } catch (e, st) {
      AppLogger.error('RemoteConfig init failed, using defaults', _tag, e, st);
    }
  }
}
