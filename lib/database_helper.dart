import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class Folder {
  int? id;
  String name;
  String? previewImage;
  DateTime createdAt;

  Folder({
    this.id,
    required this.name,
    this.previewImage,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'previewImage': previewImage,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Folder.fromMap(Map<String, dynamic> map) {
    return Folder(
      id: map['id'],
      name: map['name'],
      previewImage: map['previewImage'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

class CardItem {
  int? id;
  String name;
  String suit;
  String imageUrl;
  String? imageBytes; // optional base64 image data
  int? folderId; // nullable = unassigned
  DateTime createdAt;

  CardItem({
    this.id,
    required this.name,
    required this.suit,
    required this.imageUrl,
    this.imageBytes,
    this.folderId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'suit': suit,
      'imageUrl': imageUrl,
      'imageBytes': imageBytes,
      'folderId': folderId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CardItem.fromMap(Map<String, dynamic> map) {
    return CardItem(
      id: map['id'],
      name: map['name'],
      suit: map['suit'],
      imageUrl: map['imageUrl'],
      imageBytes: map['imageBytes'],
      folderId: map['folderId'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

class DatabaseHelper {
  static const _databaseName = "folders_cards.db";
  static const _databaseVersion = 1;

  static const folderTable = 'folders';
  static const cardTable = 'cards';

  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Folder table
    await db.execute('''
      CREATE TABLE $folderTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        previewImage TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Card table
    await db.execute('''
      CREATE TABLE $cardTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        suit TEXT NOT NULL,
        imageUrl TEXT NOT NULL,
        imageBytes TEXT,
        folderId INTEGER,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (folderId) REFERENCES $folderTable (id) ON DELETE SET NULL
      )
    ''');
  }

  // Folder methods
  Future<List<Folder>> getAllFolders() async {
    final db = await database;
    final maps = await db.query(folderTable, orderBy: 'createdAt DESC');
    return maps.map((m) => Folder.fromMap(m)).toList();
  }

  Future<Folder?> getFolder(int id) async {
    final db = await database;
    final maps =
        await db.query(folderTable, where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isNotEmpty) {
      return Folder.fromMap(maps.first);
    }
    return null;
  }

  // Card methods
  Future<List<CardItem>> getAllCards() async {
    final db = await database;
    final maps = await db.query(cardTable, orderBy: 'createdAt DESC');
    return maps.map((m) => CardItem.fromMap(m)).toList();
  }

  Future<List<CardItem>> getCardsByFolder(int folderId) async {
    final db = await database;
    final maps = await db.query(
      cardTable,
      where: 'folderId = ?',
      whereArgs: [folderId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((m) => CardItem.fromMap(m)).toList();
  }

  Future<List<CardItem>> getUnassignedCards() async {
    final db = await database;
    final maps = await db.query(
      cardTable,
      where: 'folderId IS NULL',
      orderBy: 'createdAt DESC',
    );
    return maps.map((m) => CardItem.fromMap(m)).toList();
  }

  Future<int> insertCard(CardItem card) async {
    final db = await database;
    return await db.insert(cardTable, card.toMap());
  }

  Future<int> updateCard(CardItem card) async {
    final db = await database;
    return await db.update(
      cardTable,
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  Future<int> deleteCard(int id) async {
    final db = await database;
    return await db.delete(cardTable, where: 'id = ?', whereArgs: [id]);
  }
}
