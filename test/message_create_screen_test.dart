import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_sync/main.dart';
import 'package:social_sync/services/database_helper.dart';

void main() {
  group('Message Create Screen Test', () {
    setUp(() {
      DatabaseHelper.instance.resetTestMode();
    });

    testWidgets('displays input fields for Headline and Body', (WidgetTester tester) async {
      await tester.pumpWidget(const SocialSyncApp());
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_circle_outline_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Headline / Title'), findsOneWidget);
      expect(find.text('Message Body'), findsOneWidget);
    });

    testWidgets('shows attachment buttons for Camera and Gallery', (WidgetTester tester) async {
      await tester.pumpWidget(const SocialSyncApp());
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_circle_outline_rounded));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);
      expect(find.byIcon(Icons.photo_library_rounded), findsOneWidget);
    });

    testWidgets('allows text entry for new messages', (WidgetTester tester) async {
      await tester.pumpWidget(const SocialSyncApp());
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_circle_outline_rounded));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Headline / Title'), 'Hello World');
      expect(find.text('Hello World'), findsOneWidget);
    });
  });
}
