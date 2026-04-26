import 'dart:async';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import '../services/remote_config_service.dart';

class RemoteConfigProvider extends ChangeNotifier {
  final RemoteConfigService _svc = RemoteConfigService.instance;
  StreamSubscription<RemoteConfigUpdate>? _sub;

  bool get aiHubEnabled => _svc.aiHubEnabled;

  RemoteConfigProvider() {
    // Activate new values as they arrive and notify listeners so UI updates
    // without a restart.
    _sub = _svc.onConfigUpdated.listen((_) async {
      await FirebaseRemoteConfig.instance.activate();
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
