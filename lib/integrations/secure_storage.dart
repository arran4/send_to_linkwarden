import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Returns a configured FlutterSecureStorage instance.
///
/// On Android, it configures specific options.
/// On Web, secure storage relies on window.localStorage or similar mechanisms
/// which requires the app to be served from a secure origin (HTTPS or localhost)
/// for security context APIs (like window.crypto) to function.
FlutterSecureStorage getSecureStorage() {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return const FlutterSecureStorage(aOptions: AndroidOptions());
  }
  return const FlutterSecureStorage();
}
