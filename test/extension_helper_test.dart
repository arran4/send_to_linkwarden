import 'package:flutter_test/flutter_test.dart';
import 'package:send_to_linkwarden/util/extension_helper.dart';

void main() {
  test(
    'getCurrentTabUrl returns null when not running in extension context',
    () async {
      // In a test environment, extension_helper_stub.dart is imported
      // unless dart.library.js_interop is available.
      // Either way, it should not crash and should return null.
      final url = await getCurrentTabUrl();
      expect(url, isNull);
    },
  );
}
