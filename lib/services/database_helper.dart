import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/message.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  // Test Mode support for reliable automated testing
  static bool isTestMode = false;
  static final List<Message> _memoryMessages = [];

  void resetTestMode() {
    isTestMode = true;
    _memoryMessages.clear();
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('social_sync_v6.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    return await openDatabase(
      join(dbPath, filePath), 
      version: 1, 
      onCreate: (db, v) async {
        await db.execute('CREATE TABLE messages(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, content TEXT, imagePaths TEXT, sharedPlatforms TEXT, createdAt TEXT, isPosted INTEGER, isDeleted INTEGER, postedAt TEXT, deletedAt TEXT)');
      }
    );
  }

  Future<int> insertMessage(Message message) async {
    if (DatabaseHelper.isTestMode) {
      final m = Message(
        id: DatabaseHelper._memoryMessages.length + 1,
        title: message.title,
        content: message.content,
        imagePaths: message.imagePaths,
        createdAt: message.createdAt,
      );
      DatabaseHelper._memoryMessages.add(m);
      return m.id!;
    }
    final db = await database;
    return await db.insert('messages', message.toMap());
  }

  Future<int> updateMessage(Message m) async {
    if (DatabaseHelper.isTestMode) {
      final index = DatabaseHelper._memoryMessages.indexWhere((msg) => msg.id == m.id);
      if (index != -1) DatabaseHelper._memoryMessages[index] = m;
      return 1;
    }
    return (await database).update('messages', m.toMap(), where: 'id = ?', whereArgs: [m.id]);
  }

  Future<void> bulkUpdateStatus(List<int> ids, String action) async {
    final db = await database;
    String now = DateTime.now().toString();

    if (action == "delete_forever") {
      await db.delete('messages', where: 'id IN (${ids.join(',')})');
    } else {
      Map<String, dynamic> updateData = {};
      if (action == "trash") {
        updateData['isDeleted'] = 1;
        updateData['deletedAt'] = now;
      }
      if (action == "sync") {
        updateData['isPosted'] = 1;
        updateData['postedAt'] = now;
      }
      if (action == "restore") {
        updateData['isDeleted'] = 0;
        updateData['deletedAt'] = null;
      }

      await db.update('messages', updateData, where: 'id IN (${ids.map((_) => '?').join(',')})', whereArgs: ids);
    }
  }

  Future<List<Message>> getMessages(String filter, String search) async {
    if (DatabaseHelper.isTestMode) {
      return DatabaseHelper._memoryMessages.where((m) {
        bool matchFilter = true;
        if (filter == "posted") {
          matchFilter = m.isPosted == 1 && m.isDeleted == 0;
        } else if (filter == "not_posted") {
          matchFilter = m.isPosted == 0 && m.isDeleted == 0;
        } else if (filter == "deleted") {
          matchFilter = m.isDeleted == 1;
        } else {
          matchFilter = m.isDeleted == 0;
        }

        bool matchQuery = m.title.toLowerCase().contains(search.toLowerCase()) || 
                          m.content.toLowerCase().contains(search.toLowerCase());
        return matchFilter && matchQuery;
      }).toList();
    }
    final db = await database;
    List<String> conditions = [];
    List<dynamic> whereArgs = [];
    
    if (filter == "all") {
    } else if (filter == "deleted") {
      conditions.add("COALESCE(isDeleted, 0) = 1");
    } else if (filter == "posted") {
      conditions.add("COALESCE(isDeleted, 0) = 0 AND COALESCE(isPosted, 0) = 1");
    } else if (filter == "not_posted") {
      conditions.add("COALESCE(isDeleted, 0) = 0 AND COALESCE(isPosted, 0) = 0");
    }
    
    if (search.isNotEmpty) {
      conditions.add("(title LIKE ? OR content LIKE ?)");
      whereArgs.add('%$search%');
      whereArgs.add('%$search%');
    }
    
    String? whereClause = conditions.isEmpty ? null : conditions.join(" AND ");
    final res = await db.query('messages', where: whereClause, whereArgs: whereArgs, orderBy: 'id DESC');
    return res.map((json) => Message.fromMap(json)).toList();
  }

  Future<void> updateStatus(int id, String action, {List<String>? platforms}) async {
    if (isTestMode) {
      final index = _memoryMessages.indexWhere((m) => m.id == id);
      if (index != -1) {
        final m = _memoryMessages[index];
        _memoryMessages[index] = Message(
          id: m.id, title: m.title, content: m.content, imagePaths: m.imagePaths, createdAt: m.createdAt,
          isPosted: action == "sync" ? 1 : (action == "restore" ? 0 : m.isPosted),
          isDeleted: action == "trash" ? 1 : (action == "restore" ? 0 : m.isDeleted),
          sharedPlatforms: platforms ?? m.sharedPlatforms,
        );
      }
      return;
    }
    final db = await database;
    String now = DateTime.now().toString();
    if (action == "sync") {
      await db.update('messages', {
        'isPosted': 1, 
        'postedAt': now,
        if (platforms != null) 'sharedPlatforms': jsonEncode(platforms)
      }, where: 'id = ?', whereArgs: [id]);
    }
    if (action == "trash") await db.update('messages', {'isDeleted': 1, 'deletedAt': now}, where: 'id = ?', whereArgs: [id]);
    if (action == "restore") await db.update('messages', {'isDeleted': 0, 'deletedAt': null}, where: 'id = ?', whereArgs: [id]);
    if (action == "delete_forever") await db.delete('messages', where: 'id = ?', whereArgs: [id]);
  }
}