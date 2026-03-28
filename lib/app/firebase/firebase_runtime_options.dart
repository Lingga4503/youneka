import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class AppFirebaseRuntimeOptions {
  AppFirebaseRuntimeOptions._();

  static const String apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const String projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const String messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const String appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const String androidAppId = String.fromEnvironment(
    'FIREBASE_ANDROID_APP_ID',
  );
  static const String iosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');
  static const String macosAppId = String.fromEnvironment(
    'FIREBASE_MACOS_APP_ID',
  );
  static const String webAppId = String.fromEnvironment('FIREBASE_WEB_APP_ID');
  static const String storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );
  static const String authDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
  );
  static const String measurementId = String.fromEnvironment(
    'FIREBASE_MEASUREMENT_ID',
  );
  static const String androidClientId = String.fromEnvironment(
    'FIREBASE_ANDROID_CLIENT_ID',
  );
  static const String iosClientId = String.fromEnvironment(
    'FIREBASE_IOS_CLIENT_ID',
  );
  static const String iosBundleId = String.fromEnvironment(
    'FIREBASE_IOS_BUNDLE_ID',
  );
  static const String webRecaptchaSiteKey = String.fromEnvironment(
    'FIREBASE_APPCHECK_RECAPTCHA_SITE_KEY',
  );

  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String mentorAiModel = String.fromEnvironment(
    'MENTOR_AI_MODEL',
    defaultValue: 'gemini-2.5-flash',
  );

  static bool get hasFirebaseCoreValues =>
      apiKey.isNotEmpty &&
      projectId.isNotEmpty &&
      messagingSenderId.isNotEmpty &&
      _resolvedAppId.isNotEmpty;

  static FirebaseOptions? get currentPlatform {
    if (!hasFirebaseCoreValues) return null;
    return FirebaseOptions(
      apiKey: apiKey,
      appId: _resolvedAppId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      storageBucket: _emptyToNull(storageBucket),
      authDomain: kIsWeb ? _emptyToNull(authDomain) : null,
      measurementId: kIsWeb ? _emptyToNull(measurementId) : null,
      androidClientId: _emptyToNull(androidClientId),
      iosClientId: _emptyToNull(iosClientId),
      iosBundleId: _emptyToNull(iosBundleId),
    );
  }

  static String get _resolvedAppId {
    if (kIsWeb) {
      return _firstNonEmpty([webAppId, appId]);
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _firstNonEmpty([androidAppId, appId]);
      case TargetPlatform.iOS:
        return _firstNonEmpty([iosAppId, appId]);
      case TargetPlatform.macOS:
        return _firstNonEmpty([macosAppId, iosAppId, appId]);
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return appId;
    }
  }

  static String _firstNonEmpty(List<String> values) {
    for (final value in values) {
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  static String? _emptyToNull(String value) {
    if (value.isEmpty) return null;
    return value;
  }
}
