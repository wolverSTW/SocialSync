import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_sync/main.dart';
import 'package:social_sync/services/database_helper.dart';

void main() {
  group('Message List Screen Test', () {
    setUp(() {
      DatabaseHelper.instance.resetTestMode();
    });

    testWidgets('displays the application title on launch', (WidgetTester tester) async {
      await tester.pumpWidget(const SocialSyncApp());
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('Social Sync'), findsOneWidget);
    });

    testWidgets('shows the search bar for message filtering', (WidgetTester tester) async {
      await tester.pumpWidget(const SocialSyncApp());
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // The SearchBar uses Icons.search
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('displays filter chips for different message states', (WidgetTester tester) async {
      await tester.pumpWidget(const SocialSyncApp());
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // The labels in MessageFeedScreen are All, Draft, Synced, Trash
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Draft'), findsOneWidget);
      expect(find.text('Synced'), findsOneWidget);
      expect(find.text('Trash'), findsOneWidget);
    });

    testWidgets('navigates to create screen when add button is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(const SocialSyncApp());
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Tap on the "Create" tab/button in BottomNavigationBar
      await tester.tap(find.byIcon(Icons.add_circle_outline_rounded));
      await tester.pumpAndSettle();

      // Should show the AddMessageScreen
      expect(find.text('Create New Message'), findsOneWidget);
      expect(find.text('CREATE'), findsOneWidget);
    });
  });
}
