
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OfflinePrayerDatabase {
  OfflinePrayerDatabase._();

  static final OfflinePrayerDatabase instance =
      OfflinePrayerDatabase._();

  static const String _databaseName = 'smart_rosary_offline.db';
  static const String _tableName = 'offline_prayers';
  static const int _databaseVersion = 1;

  Database? _database;

  // --------------------------------------------------
  // DATABASE INITIALIZATION
  // --------------------------------------------------

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    final databaseDirectory = await getDatabasesPath();

    final databasePath = path.join(
      databaseDirectory,
      _databaseName,
    );

    _database = await openDatabase(
      databasePath,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            prayer_id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            text TEXT NOT NULL DEFAULT '',
            category TEXT NOT NULL DEFAULT 'Other Prayers',
            language TEXT NOT NULL DEFAULT 'English',
            audio_path TEXT NOT NULL DEFAULT '',
            local_audio_path TEXT,
            published INTEGER NOT NULL DEFAULT 1,
            updated_at INTEGER,
            cached_at INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE INDEX idx_prayers_category
          ON $_tableName(category)
        ''');

        await db.execute('''
          CREATE INDEX idx_prayers_language
          ON $_tableName(language)
        ''');
      },
    );

    return _database!;
  }

  // --------------------------------------------------
  // DATE CONVERSION
  // --------------------------------------------------

  int? _convertDate(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.millisecondsSinceEpoch;
    }

    if (value is DateTime) {
      return value.millisecondsSinceEpoch;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return DateTime.tryParse(value)?.millisecondsSinceEpoch;
    }

    return null;
  }

  // --------------------------------------------------
  // SAVE ONE PRAYER
  // --------------------------------------------------

  Future<void> savePrayer(
    Map<String, dynamic> prayer, {
    DatabaseExecutor? executor,
  }) async {
    final db = executor ?? await database;

    final prayerId = prayer['id']?.toString().trim() ?? '';

    if (prayerId.isEmpty) {
      throw ArgumentError(
        'A prayer must have a valid Firestore document ID.',
      );
    }

    final existing = await db.query(
      _tableName,
      columns: ['local_audio_path'],
      where: 'prayer_id = ?',
      whereArgs: [prayerId],
      limit: 1,
    );

    final existingAudioPath = existing.isNotEmpty
        ? existing.first['local_audio_path'] as String?
        : null;

    final suppliedLocalPath =
        prayer['localAudioPath']?.toString();

    final localAudioPath =
        suppliedLocalPath?.isNotEmpty == true
            ? suppliedLocalPath
            : existingAudioPath;

    await db.insert(
      _tableName,
      {
        'prayer_id': prayerId,
        'title': prayer['title']?.toString() ?? 'Untitled prayer',
        'text': prayer['text']?.toString() ?? '',
        'category': prayer['category']?.toString() ??
            'Other Prayers',
        'language': prayer['language']?.toString() ?? 'English',
        'audio_path': prayer['audioPath']?.toString() ?? '',
        'local_audio_path': localAudioPath,
        'published': prayer['published'] == false ? 0 : 1,
        'updated_at': _convertDate(prayer['updatedAt']),
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --------------------------------------------------
  // SAVE ALL PUBLISHED PRAYERS
  // --------------------------------------------------

  Future<void> syncPublishedPrayers(
    List<Map<String, dynamic>> prayers,
  ) async {
    final db = await database;

    await db.transaction((transaction) async {
      final publishedIds = prayers
          .map((prayer) => prayer['id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();

      // Remove prayers that are no longer published.
      final existing = await transaction.query(
        _tableName,
        columns: ['prayer_id'],
      );

      for (final row in existing) {
        final id = row['prayer_id'] as String;

        if (!publishedIds.contains(id)) {
          await transaction.delete(
            _tableName,
            where: 'prayer_id = ?',
            whereArgs: [id],
          );
        }
      }

      // Save the latest published prayers.
      for (final prayer in prayers) {
        await savePrayer(
          prayer,
          executor: transaction,
        );
      }
    });
  }

  // --------------------------------------------------
  // GET ALL OFFLINE PRAYERS
  // --------------------------------------------------

  Future<List<Map<String, dynamic>>> getCachedPrayers() async {
    final db = await database;

    final results = await db.query(
      _tableName,
      where: 'published = ?',
      whereArgs: [1],
      orderBy: 'category COLLATE NOCASE ASC, title COLLATE NOCASE ASC',
    );

    return results.map((row) {
      return {
        'id': row['prayer_id'],
        'title': row['title'],
        'text': row['text'],
        'category': row['category'],
        'language': row['language'],
        'audioPath': row['audio_path'],
        'localAudioPath': row['local_audio_path'],
        'published': row['published'] == 1,
        'updatedAt': row['updated_at'],
        'cachedAt': row['cached_at'],
      };
    }).toList();
  }

  // --------------------------------------------------
  // GET ONE PRAYER
  // --------------------------------------------------

  Future<Map<String, dynamic>?> getCachedPrayer(
    String prayerId,
  ) async {
    final db = await database;

    final results = await db.query(
      _tableName,
      where: 'prayer_id = ? AND published = ?',
      whereArgs: [prayerId, 1],
      limit: 1,
    );

    if (results.isEmpty) return null;

    final row = results.first;

    return {
      'id': row['prayer_id'],
      'title': row['title'],
      'text': row['text'],
      'category': row['category'],
      'language': row['language'],
      'audioPath': row['audio_path'],
      'localAudioPath': row['local_audio_path'],
      'published': row['published'] == 1,
      'updatedAt': row['updated_at'],
      'cachedAt': row['cached_at'],
    };
  }

  // --------------------------------------------------
  // SAVE LOCAL AUDIO FILE PATH
  // --------------------------------------------------

  Future<void> setLocalAudioPath(
    String prayerId,
    String localPath,
  ) async {
    final db = await database;

    await db.update(
      _tableName,
      {
        'local_audio_path': localPath,
      },
      where: 'prayer_id = ?',
      whereArgs: [prayerId],
    );
  }

  // --------------------------------------------------
  // REMOVE LOCAL AUDIO REFERENCE
  // --------------------------------------------------

  Future<void> removeLocalAudioPath(
    String prayerId,
  ) async {
    final db = await database;

    await db.update(
      _tableName,
      {
        'local_audio_path': null,
      },
      where: 'prayer_id = ?',
      whereArgs: [prayerId],
    );
  }

  // --------------------------------------------------
  // CHECK IF AUDIO IS DOWNLOADED
  // --------------------------------------------------

  Future<bool> isAudioDownloaded(String prayerId) async {
    final prayer = await getCachedPrayer(prayerId);

    final localPath = prayer?['localAudioPath']?.toString();

    return localPath != null && localPath.isNotEmpty;
  }

  // --------------------------------------------------
  // DELETE ONE PRAYER
  // --------------------------------------------------

  Future<void> deletePrayer(String prayerId) async {
    final db = await database;

    await db.delete(
      _tableName,
      where: 'prayer_id = ?',
      whereArgs: [prayerId],
    );
  }

  // --------------------------------------------------
  // COUNT CACHED PRAYERS
  // --------------------------------------------------

  Future<int> getCachedPrayerCount() async {
    final db = await database;

    final result = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM $_tableName WHERE published = 1',
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  // --------------------------------------------------
  // CLOSE DATABASE
  // --------------------------------------------------

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
