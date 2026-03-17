import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

FlutterSecureStorage getSecureStorage() {
  FlutterSecureStorage storage;
  if (Platform.isAndroid) {
    AndroidOptions getAndroidOptions() =>
        const AndroidOptions();
    storage = FlutterSecureStorage(aOptions: getAndroidOptions());
  } else {
    storage = const FlutterSecureStorage();
  }
  return storage;
}
