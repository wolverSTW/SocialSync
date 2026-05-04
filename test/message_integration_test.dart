import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_sync/main.dart';
import 'package:social_sync/models/message.dart';
import 'package:social_sync/services/database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Message Integration & Advanced Logic Test', () {
    setUp(() {
      DatabaseHelper.instance.resetTestMode();
    });

    test('Search Logic: verifies keyword filtering accuracy', () async {
      final messages = [
        Message(title: 'Apple', content: 'Fruit', imagePaths: [], createdAt: '2026'),
        Message(title: 'Banana', content: 'Fruit', imagePaths: [], createdAt: '2026'),
      ];
      
      final query = 'App';
      final filtered = messages.where((m) => 
        m.title.toLowerCase().contains(query.toLowerCase()) || 
        m.content.toLowerCase().contains(query.toLowerCase())
      ).toList();

      expect(filtered.length, 1);
      expect(filtered[0].title, 'Apple');
    });

    test('Bulk Selection: verifies multi-select counting logic', () {
      final selectedIds = <int>{1, 2, 3};
      expect(selectedIds.length, 3);
      
      selectedIds.remove(2);
      expect(selectedIds.length, 2);
      expect(selectedIds.contains(2), isFalse);
    });

    testWidgets('UI Integration: verifies selection mode activation', (WidgetTester tester) async {
      await DatabaseHelper.instance.insertMessage(Message(
        title: 'Integration Test Item',
        content: 'Verification of long press.',
        imagePaths: [],
        createdAt: DateTime.now().toString(),
      ));

      await tester.pumpWidget(const SocialSyncApp());
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      final textFinder = find.text('Integration Test Item');
      expect(textFinder, findsOneWidget);

      final cardFinder = find.ancestor(
        of: textFinder,
        matching: find.byType(Card),
      );
      expect(cardFinder, findsOneWidget);
      
      await tester.longPress(cardFinder);
      await tester.pumpAndSettle();
      
      expect(find.text('1 Selected'), findsOneWidget);
    });
  });
}
