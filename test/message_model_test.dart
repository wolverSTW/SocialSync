import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_sync/models/message.dart';

void main() {
  group('Message Model Test', () {
    test('creates a Message with required fields', () {
      final message = Message(
        title: 'Test Title',
        content: 'Test Content',
        imagePaths: [],
        createdAt: DateTime.now().toString(),
      );

      expect(message.title, 'Test Title');
      expect(message.content, 'Test Content');
      expect(message.isPosted, 0);
      expect(message.isDeleted, 0);
    });

    test('creates a Message with all fields', () {
      final message = Message(
        id: 1,
        title: 'Title',
        content: 'Content',
        imagePaths: ['path1', 'path2'],
        createdAt: '2026-04-28',
        isPosted: 1,
        isDeleted: 0,
      );

      expect(message.id, 1);
      expect(message.title, 'Title');
      expect(message.imagePaths, ['path1', 'path2']);
      expect(message.isPosted, 1);
    });

    test('toMap() returns correct map for database', () {
      final message = Message(
        id: 1,
        title: 'Title',
        content: 'Content',
        imagePaths: ['path1', 'path2'],
        createdAt: '2026-04-28',
        isPosted: 1,
      );

      final map = message.toMap();
      expect(map['id'], 1);
      expect(map['title'], 'Title');
      // The model uses jsonEncode for lists
      expect(map['imagePaths'], jsonEncode(['path1', 'path2']));
      expect(map['isPosted'], 1);
    });

    test('fromMap() constructs Message correctly from database', () {
      final map = {
        'id': 1,
        'title': 'Title',
        'content': 'Content',
        // Provide JSON encoded string as the database would
        'imagePaths': jsonEncode(['path1', 'path2']),
        'createdAt': '2026-04-28',
        'isPosted': 1,
        'isDeleted': 0,
      };

      final message = Message.fromMap(map);
      expect(message.id, 1);
      expect(message.title, 'Title');
      expect(message.imagePaths, ['path1', 'path2']);
      expect(message.isPosted, 1);
    });

    test('fromMap() handles null imagePaths gracefully', () {
      final map = {
        'id': 1,
        'title': 'No Images',
        'content': 'Content',
        'imagePaths': null,
        'createdAt': '2026-04-28',
        'isPosted': 0,
        'isDeleted': 0,
      };

      final message = Message.fromMap(map);
      expect(message.imagePaths, isEmpty);
    });

    test('toMap() then fromMap() round-trips correctly', () {
      final original = Message(
        title: 'Round Trip',
        content: 'Check',
        imagePaths: ['a', 'b'],
        createdAt: '2026',
      );

      final map = original.toMap();
      final restored = Message.fromMap(map);

      expect(restored.title, original.title);
      expect(restored.content, original.content);
      expect(restored.imagePaths, original.imagePaths);
    });
  });
}
