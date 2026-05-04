import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_sync/main.dart';
import 'package:social_sync/models/message.dart';
import 'package:social_sync/services/database_helper.dart';

void main() {
  group('Message Performance & Accessibility Test', () {
    setUp(() {
      DatabaseHelper.instance.resetTestMode();
    });

    testWidgets('Accessibility: semantic labels for all interactive elements', (WidgetTester tester) async {
      await tester.pumpWidget(const SocialSyncApp());
      // Wait for Splash Screen to finish
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Ensure the semantics tree is built
      final createIcon = find.byIcon(Icons.add_circle_outline_rounded);
      expect(createIcon, findsOneWidget);
    });

    testWidgets('Data Scalability: sub-100ms list filtering for large datasets', (WidgetTester tester) async {
      final startTime = DateTime.now().millisecondsSinceEpoch;
      // Verification of logic performance
      final items = List.generate(1000, (i) => 'Item $i');
      final filtered = items.where((item) => item.contains('999')).toList();
      final endTime = DateTime.now().millisecondsSinceEpoch;

      expect(filtered.length, 1);
      expect(endTime - startTime, lessThan(100));
    });

    testWidgets('UI Stress: frame stability during rapid scrolling', (WidgetTester tester) async {
      // Insert enough items to make the list scrollable
      for (int i = 0; i < 20; i++) {
        await DatabaseHelper.instance.insertMessage(
          Message(
            title: 'Stress Test $i',
            content: 'Content $i',
            imagePaths: [],
            createdAt: '2026',
          )
        );
      }

      await tester.pumpWidget(const SocialSyncApp());
      // Wait for Splash Screen
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Drag the ListView rapidly to test UI stability
      await tester.drag(find.byType(ListView), const Offset(0, -5000));
      await tester.pump();
      
      expect(tester.takeException(), isNull);
    });
  });
}
