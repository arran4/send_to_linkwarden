import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:send_to_linkwarden/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('SendToLinkwardenApp initializes correctly', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const SendToLinkwardenApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Share entry sanitizes error message', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    // We can simulate an error sent from the platform channel to receive_sharing_intent
    // It listens on an EventChannel named 'receive_sharing_intent/events-media'

    await tester.pumpWidget(const SendToLinkwardenApp());
    await tester.pump();

    // Dispatch an error on the event channel
    tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'receive_sharing_intent/events-media',
      const StandardMethodCodec().encodeErrorEnvelope(
        code: 'ERROR',
        message: 'RAW_NATIVE_EXCEPTION_123_456',
      ),
      (ByteData? data) {},
    );

    // Using pump() instead of pumpAndSettle() because showing a SnackBar creates an animation that delays pumpAndSettle.
    // Also, we just need the frame to render the snackbar.
    await tester.pump();

    // It should not show the raw exception text
    expect(find.textContaining('RAW_NATIVE_EXCEPTION'), findsNothing);

    // It should show our sanitized error message
    expect(
      find.textContaining('Failed to receive shared link. Please try again.'),
      findsOneWidget,
    );
  });
}
