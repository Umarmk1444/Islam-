import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:developer' as dev;
import '../../models/minbar_models.dart';

class DownloadsDatabase {
  DownloadsDatabase._internal();
  static final DownloadsDatabase instance = DownloadsDatabase._internal();
  factory DownloadsDatabase() => instance;

  static const String _kDbName = 'minbar_downloads.db';
  static const String _kLogName = 'DownloadsDatabase';
  
  Database? _db;

  Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final docDir = await getApplicationDocumentsDirectory();
    final dbDir = Directory(p.join(docDir.path, 'databases'));

    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }

    final dbPath = p.join(dbDir.path, _kDbName);

    return await openDatabase(
      dbPath,
      version: 2, // Upgraded to version 2
      onCreate: _createDb,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          dev.log('Upgrading downloads table to v2 (dropping old data)...', name: _kLogName);
          await db.execute('DROP TABLE IF EXISTS downloads');
          await _createDb(db, newVersion);
        }
      },
    );
  }

  Future<void> _createDb(Database db, int version) async {
    dev.log('Creating downloads table v2...', name: _kLogName);
    await db.execute('''
      CREATE TABLE downloads (
        id TEXT PRIMARY KEY,
        local_path TEXT NOT NULL,
        title TEXT NOT NULL,
        author_id TEXT NOT NULL,
        author_name TEXT NOT NULL,
        category_id TEXT NOT NULL
      )
    ''');
  }

  /// Returns the local path if the item is downloaded, else null.
  Future<String?> getLocalPath(String id) async {
    final db = await database;
    final rows = await db.query(
      'downloads',
      columns: ['local_path'],
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isNotEmpty) {
      final path = rows.first['local_path'] as String;
      // Double check if file still actually exists on disk
      if (await File(path).exists()) {
        return path;
      } else {
        // Cleanup ghost entry
        await deleteDownloadRecord(id);
      }
    }
    return null;
  }

  /// Mark an item as downloaded by saving its metadata
  Future<void> saveDownloadRecord({
    required MinbarAudioItem track,
    required String localPath,
    required String authorName,
    required String categoryId,
  }) async {
    final db = await database;
    await db.insert(
      'downloads',
      {
        'id': track.id,
        'local_path': localPath,
        'title': track.title,
        'author_id': track.authorId,
        'author_name': authorName,
        'category_id': categoryId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    dev.log('Saved download record for ${track.id} at $localPath', name: _kLogName);
  }

  /// Delete a download record from the database
  Future<void> deleteDownloadRecord(String id) async {
    final db = await database;
    
    // First try to delete the physical file if it exists
    final rows = await db.query('downloads', columns: ['local_path'], where: 'id = ?', whereArgs: [id]);
    if (rows.isNotEmpty) {
      final path = rows.first['local_path'] as String;
      final file = File(path);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (e) {
          dev.log('Error deleting physical file: $e', name: _kLogName);
        }
      }
    }

    await db.delete(
      'downloads',
      where: 'id = ?',
      whereArgs: [id],
    );
    dev.log('Deleted download record for $id', name: _kLogName);
  }

  /// Get all downloaded IDs
  Future<List<String>> getAllDownloadedIds() async {
    final db = await database;
    final rows = await db.query('downloads', columns: ['id']);
    return rows.map((row) => row['id'] as String).toList();
  }

  /// Get all complete download records (for Downloads Screen)
  Future<List<Map<String, dynamic>>> getAllDownloads() async {
    final db = await database;
    final rows = await db.query('downloads');
    
    // Double check existence of each file to avoid showing ghost files
    List<Map<String, dynamic>> validDownloads = [];
    for (var row in rows) {
      final path = row['local_path'] as String;
      if (await File(path).exists()) {
        validDownloads.add(row);
      } else {
        await deleteDownloadRecord(row['id'] as String);
      }
    }
    return validDownloads;
  }
}
