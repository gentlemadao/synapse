import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:synapse/main.dart';

void main() {
  testWidgets('Smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: SynapseApp()));

    // Verify that the Bevy Viewport text exists in the UI
    expect(find.textContaining('Bevy Viewport'), findsOneWidget);
  });
}
