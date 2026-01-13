// Basic Flutter widget test for KumbhSaathi App

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kumbh_saathi/app.dart';

void main() {
  testWidgets('App initializes and displays home screen', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: KumbhSaathiApp()));

    // Verify that KumbhSaathi title is displayed
    expect(find.text('KumbhSaathi'), findsOneWidget);
  });
}
