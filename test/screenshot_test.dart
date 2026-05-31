import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:send_to_linkwarden/main.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Mock platform channels
    const MethodChannel('receive_sharing_intent/events-media')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      return null;
    });
    const MethodChannel('receive_sharing_intent/messages')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      return null;
    });
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'readAll') {
        return <String, String>{};
      }
      if (methodCall.method == 'read') {
        return null;
      }
      return null;
    });
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Generate screenshot golden', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;

    // Build our app and trigger a frame.
    await tester.pumpWidget(const SendToLinkwardenApp());
    await tester.pumpAndSettle();

    // The golden test will save the image to test/goldens/screenshot.png
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/screenshot.png'),
    );

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }, tags: 'golden');
}
