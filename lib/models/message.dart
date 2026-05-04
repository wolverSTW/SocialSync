import 'dart:convert';

class Message {
  final int? id;
  final String title;
  final String content;
  final List<String> imagePaths;
  final List<String> sharedPlatforms;
  final String createdAt;
  final String? postedAt;
  final String? deletedAt;
  final int isPosted; // 0: Draft, 1: Synced
  final int isDeleted; // 0: Active, 1: Trash

  Message({
    this.id, required this.title, required this.content,
    required this.imagePaths, required this.createdAt,
    this.sharedPlatforms = const [],
    this.postedAt, this.deletedAt,
    this.isPosted = 0, this.isDeleted = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id, 'title': title, 'content': content,
      'imagePaths': jsonEncode(imagePaths),
      'sharedPlatforms': jsonEncode(sharedPlatforms),
      'createdAt': createdAt,
      'postedAt': postedAt, 'deletedAt': deletedAt,
      'isPosted': isPosted, 'isDeleted': isDeleted,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      imagePaths: map['imagePaths'] != null 
          ? List<String>.from(jsonDecode(map['imagePaths'])) 
          : [],
      sharedPlatforms: map['sharedPlatforms'] != null
          ? List<String>.from(jsonDecode(map['sharedPlatforms']))
          : [],
      createdAt: map['createdAt'] ?? '',
      postedAt: map['postedAt'],
      deletedAt: map['deletedAt'],
      isPosted: map['isPosted'] ?? 0,
      isDeleted: map['isDeleted'] ?? 0,
    );
  }
}