import 'package:flutter_test/flutter_test.dart';
import 'package:send_to_linkwarden/integrations/secure_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  test(
    'getSecureStorage returns a FlutterSecureStorage instance without throwing',
    () {
      final storage = getSecureStorage();
      expect(storage, isA<FlutterSecureStorage>());
    },
  );
}
