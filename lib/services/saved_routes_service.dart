
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../services/route_planner_service.dart';

class SavedRoute {
  final int? id;
  final String date;
  final String fromStation;
  final String toStation;
  final PlannedRoute route;

  SavedRoute({
    this.id,
    required this.date,
    required this.fromStation,
    required this.toStation,
    required this.route,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'fromStation': fromStation,
      'toStation': toStation,
      'routeJson': jsonEncode(_routeToMap(route)),
    };
  }

  factory SavedRoute.fromMap(Map<String, dynamic> map) {
    return SavedRoute(
      id: map['id'],
      date: map['date'],
      fromStation: map['fromStation'],
      toStation: map['toStation'],
      route: _routeFromMap(jsonDecode(map['routeJson'])),
    );
  }

  static Map<String, dynamic> _routeToMap(PlannedRoute r) {
    return {
      'totalMinutes': r.totalMinutes,
      'totalFare': r.totalFare,
      'transfers': r.transfers,
      'legs': r.legs.map((l) => {
        'type': l.type.index,
        'line': l.line,
        'fromStation': l.fromStation,
        'toStation': l.toStation,
        'stops': l.stops,
        'estMinutes': l.estMinutes,
        'fare': l.fare,
        'transferNote': l.transferNote,
      }).toList(),
    };
  }

  static PlannedRoute _routeFromMap(Map<String, dynamic> m) {
    return PlannedRoute(
      totalMinutes: m['totalMinutes'] as int,
      totalFare: (m['totalFare'] as num).toDouble(),
      transfers: m['transfers'] as int,
      legs: (m['legs'] as List).map((l) => RouteLeg(
        type: LegType.values[l['type'] as int],
        line: l['line'],
        fromStation: l['fromStation'],
        toStation: l['toStation'],
        stops: l['stops'] as int,
        estMinutes: l['estMinutes'] as int,
        fare: (l['fare'] as num).toDouble(),
        transferNote: l['transferNote'],
      )).toList(),
    );
  }
}

class SavedRoutesService {
  static final SavedRoutesService _instance = SavedRoutesService._internal();
  factory SavedRoutesService() => _instance;
  SavedRoutesService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final path = join(await getDatabasesPath(), 'saved_routes.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE saved_routes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            fromStation TEXT,
            toStation TEXT,
            routeJson TEXT
          )
        ''');
      },
    );
  }

  Future<int> saveRoute(String from, String to, PlannedRoute route) async {
    final db = await database;
    final saved = SavedRoute(
      date: DateTime.now().toIso8601String(),
      fromStation: from,
      toStation: to,
      route: route,
    );
    return await db.insert('saved_routes', saved.toMap());
  }

  Future<List<SavedRoute>> getAllRoutes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('saved_routes', orderBy: 'date DESC');
    return maps.map((m) => SavedRoute.fromMap(m)).toList();
  }

  Future<void> deleteRoute(int id) async {
    final db = await database;
    await db.delete('saved_routes', where: 'id = ?', whereArgs: [id]);
  }
}
