import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:synapse/main.dart';

void main() {
  testWidgets('Smoke test', (WidgetTester tester) async {
    // Force a 1920x1080 widescreen desktop screen resolution during widget testing.
    // This allows testing genuine desktop layouts and verifying responsiveness
    // without fake constraints or miniature virtual screen issues.
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;

    // Reset view configuration back to default when test teardown runs
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: SynapseApp()));

    // Flush any pending delayed microtasks and scroll timers (e.g. console scroll)
    await tester.pump(const Duration(milliseconds: 100));

    // Verify that the Bevy Viewport text exists in the UI
    expect(find.textContaining('Bevy Viewport'), findsOneWidget);
  });
}
