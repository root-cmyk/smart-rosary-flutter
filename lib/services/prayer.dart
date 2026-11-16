
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'offline_prayer_database.dart';

class PrayerService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final OfflinePrayerDatabase _offlineDatabase =
      OfflinePrayerDatabase.instance;

  // =========================================================
  // FIREBASE DIAGNOSTICS
  // =========================================================

  void _checkFirebaseConnection() {
    final user = _auth.currentUser;

    print('========== SMART ROSARY FIREBASE ==========');
    print('PROJECT: ${_firestore.app.options.projectId}');
    print('AUTH UID: ${user?.uid ?? "NOT SIGNED IN"}');
    print('AUTH EMAIL: ${user?.email ?? "NONE"}');
    print('SIGNED IN: ${user != null}');
    print('===========================================');
  }

  // =========================================================
  // OFFLINE-FIRST PRAYER STREAM
  // =========================================================

  Stream<List<Map<String, dynamic>>> watchPublishedPrayers() async* {
    _checkFirebaseConnection();

    // STEP 1: Load locally saved prayers immediately.
    try {
      final cachedPrayers =
          await _offlineDatabase.getCachedPrayers();

      print(
        'SQLITE: ${cachedPrayers.length} prayers loaded',
      );

      yield cachedPrayers;
    } catch (error, stackTrace) {
      print('SQLITE LOAD ERROR: $error');
      print(stackTrace);

      yield <Map<String, dynamic>>[];
    }

    // STEP 2: Listen directly to the original Firestore query.
    try {
      print('FIRESTORE: Listening to published prayers...');

      final stream = _firestore
          .collection('prayers')
          .where('published', isEqualTo: true)
          .snapshots(includeMetadataChanges: true);

      await for (final snapshot in stream) {
        print(
          'FIRESTORE: ${snapshot.docs.length} prayers received',
        );

        print(
          'FROM CACHE: ${snapshot.metadata.isFromCache}',
        );

        // Convert Firestore documents into the exact format
        // expected by PrayScreen.
        final prayers = snapshot.docs.map((doc) {
          final data = doc.data();

          print(
            'PRAYER: ${doc.id} | '
            '${data['title'] ?? 'Untitled'}',
          );

          return <String, dynamic>{
            ...data,
            'id': doc.id,
          };
        }).toList();

        // IMPORTANT:
        // Display Firestore results immediately.
        // Do not wait for SQLite synchronization.
        yield prayers;

        // STEP 3: Update SQLite only when the snapshot
        // comes from the Firestore server.
        if (!snapshot.metadata.isFromCache) {
          try {
            await _offlineDatabase.syncPublishedPrayers(
              prayers,
            );

            print(
              'SQLITE: Successfully synchronized '
              '${prayers.length} prayers',
            );
          } catch (databaseError, databaseStack) {
            print(
              'SQLITE SYNCHRONIZATION ERROR: $databaseError',
            );
            print(databaseStack);

            // Firestore prayers have already been displayed.
            // A local database error must not hide them.
          }
        }
      }
    } catch (error, stackTrace) {
      print('');
      print('========== FIRESTORE PRAYER ERROR ==========');
      print('ERROR: $error');
      print('TYPE: ${error.runtimeType}');
      print(stackTrace);
      print('============================================');

      // Keep the locally saved prayers available.
      try {
        final cachedPrayers =
            await _offlineDatabase.getCachedPrayers();

        print(
          'OFFLINE FALLBACK: ${cachedPrayers.length} prayers',
        );

        yield cachedPrayers;
      } catch (offlineError) {
        print('OFFLINE FALLBACK ERROR: $offlineError');
      }
    }
  }

  // =========================================================
  // ONE-TIME PRAYER FETCH
  // =========================================================

  Future<List<Map<String, dynamic>>> getPublishedPrayers() async {
    _checkFirebaseConnection();

    try {
      print('FIRESTORE: Fetching prayers...');

      final snapshot = await _firestore
          .collection('prayers')
          .where('published', isEqualTo: true)
          .get(
            const GetOptions(source: Source.server),
          );

      final prayers = snapshot.docs.map((doc) {
        return <String, dynamic>{
          ...doc.data(),
          'id': doc.id,
        };
      }).toList();

      print(
        'FIRESTORE FETCH SUCCESS: ${prayers.length} prayers',
      );

      // Save server results locally.
      try {
        await _offlineDatabase.syncPublishedPrayers(prayers);
      } catch (error) {
        print('SQLITE SYNC ERROR: $error');
      }

      return prayers;
    } catch (error, stackTrace) {
      print('FIRESTORE FETCH ERROR: $error');
      print(stackTrace);

      // Return offline data if server access fails.
      return await _offlineDatabase.getCachedPrayers();
    }
  }
}
