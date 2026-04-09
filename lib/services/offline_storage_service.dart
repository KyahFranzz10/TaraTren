import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class ScrapedAlert {
  final int? id;
  final String title;
  final String message;
  final DateTime timestamp;
  final String line;

  ScrapedAlert({
    this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.line,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'line': line,
    };
  }

  factory ScrapedAlert.fromMap(Map<String, dynamic> map) {
    return ScrapedAlert(
      id: map['id'],
      title: map['title'],
      message: map['message'],
      timestamp: DateTime.parse(map['timestamp']),
      line: map['line'],
    );
  }
}

class OfflineStorageService {
  static final OfflineStorageService _instance = OfflineStorageService._internal();
  factory OfflineStorageService() => _instance;
  OfflineStorageService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'tara_tren_alerts.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE alerts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            message TEXT,
            timestamp TEXT,
            line TEXT
          )
        ''');
      },
    );
  }

  Future<void> saveAlert(ScrapedAlert alert) async {
    final db = await database;
    await db.insert('alerts', alert.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ScrapedAlert>> getLatestAlerts({int limit = 5}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'alerts',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return List.generate(maps.length, (i) => ScrapedAlert.fromMap(maps[i]));
  }
}
