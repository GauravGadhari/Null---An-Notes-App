import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:null_notes/screens/settings/ecosystem_app_store_sheet.dart';

void main() {
  testWidgets('show21DaysAppStoreSheet renders full Apple App Store UI', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => show21DaysAppStoreSheet(context),
                child: const Text('Open Sheet'),
              );
            },
          ),
        ),
      ),
    );

    // Tap button to open bottom sheet
    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    // Verify all core sections are rendered
    expect(find.text('21 Days of Habit'), findsWidgets);
    expect(find.text('Build lasting habits & routines'), findsOneWidget);
    expect(find.text('GET'), findsOneWidget);
    expect(find.text('4.9 ★'), findsOneWidget);
    expect(find.text('#1'), findsOneWidget);
    expect(find.text('PREVIEW'), findsOneWidget);
    expect(find.text('Streak Shields'), findsOneWidget);
    expect(find.text('Glanceable Widgets'), findsOneWidget);
    expect(find.text('Light Ecosystem Sync'), findsOneWidget);
    expect(find.text('Get 21 Days of Habit'), findsOneWidget);
  });
}
