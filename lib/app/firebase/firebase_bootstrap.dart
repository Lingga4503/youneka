import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_runtime_options.dart';

class AppFirebaseBootstrap {
  AppFirebaseBootstrap._();

  static FirebaseApp? _app;
  static Object? _error;
  static StackTrace? _stackTrace;
  static bool _didAttemptInitialization = false;

  static FirebaseApp? get app => _app;
  static bool get isConfigured =>
      AppFirebaseRuntimeOptions.currentPlatform != null || _supportsNativeConfig;
  static bool get isInitialized => _app != null;
  static Object? get error => _error;

  static String? get statusMessage {
    if (isInitialized) return null;
    if (!isConfigured) {
      return 'Firebase AI Logic belum dikonfigurasi untuk build ini.';
    }
    if (_error != null) {
      return 'Firebase gagal diinisialisasi. Periksa FIREBASE_* dan App Check.';
    }
    return null;
  }

  static Future<void> ensureInitialized() async {
    if (_didAttemptInitialization) return;
    _didAttemptInitialization = true;

    final options = AppFirebaseRuntimeOptions.currentPlatform;

    try {
      if (Firebase.apps.isNotEmpty) {
        _app = Firebase.app();
      } else if (options != null) {
        _app = await Firebase.initializeApp(options: options);
      } else if (_supportsNativeConfig) {
        _app = await Firebase.initializeApp();
      } else {
        return;
      }
      await _activateAppCheck(_app!);
    } catch (e, st) {
      _error = e;
      _stackTrace = st;
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: e,
          stack: st,
          library: 'firebase_bootstrap',
          context: ErrorDescription('while bootstrapping Firebase'),
        ),
      );
    }
  }

  static bool get _supportsNativeConfig {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return true;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return false;
    }
  }

  static Future<void> _activateAppCheck(FirebaseApp app) async {
    final appCheck = FirebaseAppCheck.instanceFor(app: app);

    if (kIsWeb) {
      if (kDebugMode) {
        await appCheck.activate(providerWeb: WebDebugProvider());
        return;
      }

      final siteKey = AppFirebaseRuntimeOptions.webRecaptchaSiteKey;
      if (siteKey.isEmpty) return;

      await appCheck.activate(providerWeb: ReCaptchaV3Provider(siteKey));
      return;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        await appCheck.activate(
          providerAndroid: kDebugMode
              ? const AndroidDebugProvider()
              : const AndroidPlayIntegrityProvider(),
        );
        return;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        await appCheck.activate(
          providerApple: kDebugMode
              ? const AppleDebugProvider()
              : const AppleAppAttestWithDeviceCheckFallbackProvider(),
        );
        return;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return;
    }
  }

  static String? debugDescription() {
    if (_error == null) return null;
    final errorLine = _error.toString();
    final stackLine = _stackTrace == null ? '' : '\n$_stackTrace';
    return '$errorLine$stackLine';
  }
}
