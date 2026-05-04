import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_sync/main.dart';
import 'package:social_sync/models/message.dart';
import 'package:social_sync/services/database_helper.dart';

void main() {
  group('Message Detail Screen Test', () {
    setUp(() {
      DatabaseHelper.instance.resetTestMode();
    });

    testWidgets('loads existing message data in edit mode', (WidgetTester tester) async {
      await DatabaseHelper.instance.insertMessage(
        Message(
          title: 'Original Title',
          content: 'Original Content',
          imagePaths: [],
          createdAt: '2026',
        ),
      );

      await tester.pumpWidget(const SocialSyncApp());
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Tap the edit icon on the message card specifically
      await tester.tap(find.descendant(
        of: find.byType(Card),
        matching: find.byIcon(Icons.edit_note_rounded),
      ));
      await tester.pumpAndSettle();

      // In AddMessageScreen (Edit Mode)
      expect(find.text('Original Title'), findsOneWidget);
      expect(find.text('Original Content'), findsOneWidget);
      expect(find.text('Edit Message'), findsOneWidget);
    });

    testWidgets('displays the update button in edit mode', (WidgetTester tester) async {
      await DatabaseHelper.instance.insertMessage(
        Message(
          title: 'Checking Update',
          content: 'Content',
          imagePaths: [],
          createdAt: '2026',
        ),
      );

      await tester.pumpWidget(const SocialSyncApp());
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Tap the edit icon specifically in the card
      await tester.tap(find.descendant(
        of: find.byType(Card),
        matching: find.byIcon(Icons.edit_note_rounded),
      ));
      await tester.pumpAndSettle();

      // The button text is "UPDATE" when editMessage is not null
      expect(find.text('UPDATE'), findsOneWidget);
    });
  });
}
