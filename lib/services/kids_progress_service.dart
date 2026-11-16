
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Progress is isolated by child identity.
///
/// Independent child:
/// users/{childUid}/kidsProgress/main
///
/// Parent-managed child:
/// users/{parentUid}/kids/{childProfileId}/progress/main
///
/// Guided sessions are stored below the selected progress document.
class KidsProgressService {
  KidsProgressService._(this._ref);

  final DocumentReference<Map<String, dynamic>> _ref;

  factory KidsProgressService.independent(String uid) {
    return KidsProgressService._(
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('kidsProgress')
          .doc('main'),
    );
  }

  factory KidsProgressService.parentManaged({
    required String parentUid,
    required String childProfileId,
  }) {
    return KidsProgressService._(
      FirebaseFirestore.instance
          .collection('users')
          .doc(parentUid)
          .collection('kids')
          .doc(childProfileId)
          .collection('progress')
          .doc('main'),
    );
  }

factory KidsProgressService.forChild({
  required String uid,
  String? parentUid,
  String? childProfileId,
}) {
  if (parentUid != null &&
      parentUid.isNotEmpty &&
      childProfileId != null &&
      childProfileId.isNotEmpty) {
    return KidsProgressService.parentManaged(
      parentUid: parentUid,
      childProfileId: childProfileId,
    );
  }

  return KidsProgressService.independent(uid);
}



  factory KidsProgressService.forCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw StateError('No authenticated user for Kids Mode.');
    }

    return KidsProgressService.independent(user.uid);
  }

  Stream<KidsProgress> watch() {
    return _ref.snapshots().map(KidsProgress.fromMap);
  }

  Future<void> completeLesson(String lessonId) {
    return _completeOnce(
      field: 'completedLessons',
      id: lessonId,
      awardStars: 5,
    );
  }

  Future<void> completePrayer(String prayerDocumentId) {
    return _completeOnce(
      field: 'completedPrayers',
      id: prayerDocumentId,
      awardStars: 5,
      markPrayerDay: true,
    );
  }

  /// Records newly listened seconds from the guided player.
  /// Set completed=true only when the activity actually finishes.
  Future<void> recordGuidedPlayback({
    required String prayerDocumentId,
    required int listenedSecondsDelta,
    int? durationSeconds,
    bool completed = false,
  }) async {
    if (prayerDocumentId.trim().isEmpty) {
      throw ArgumentError.value(
        prayerDocumentId,
        'prayerDocumentId',
        'Must be a Firestore prayers document ID.',
      );
    }

    final delta =
        listenedSecondsDelta < 0 ? 0 : listenedSecondsDelta;

    final sessionRef =
        _ref.collection('guidedSessions').doc(prayerDocumentId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final progressSnapshot = await transaction.get(_ref);
      final sessionSnapshot = await transaction.get(sessionRef);

      final progress =
          progressSnapshot.data() ?? <String, dynamic>{};
      final session =
          sessionSnapshot.data() ?? <String, dynamic>{};

      final completedPrayers = List<String>.from(
        progress['completedPrayers'] ?? const <String>[],
      );

      final alreadyCompleted =
          session['completed'] == true ||
          completedPrayers.contains(prayerDocumentId);

      final award = completed && !alreadyCompleted;

      final stars = progress['stars'] is num
          ? (progress['stars'] as num).toInt()
          : 0;

      final listened = session['listenedSeconds'] is num
          ? (session['listenedSeconds'] as num).toInt()
          : 0;

      final sessionUpdate = <String, dynamic>{
        'prayerId': prayerDocumentId,
        'listenedSeconds': listened + delta,
        'completed': completed || alreadyCompleted,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastPlayedAt': FieldValue.serverTimestamp(),
      };

      if (durationSeconds != null && durationSeconds > 0) {
        sessionUpdate['durationSeconds'] = durationSeconds;
      }

      if (completed && !alreadyCompleted) {
        sessionUpdate['completedAt'] =
            FieldValue.serverTimestamp();
      }

      transaction.set(
        sessionRef,
        sessionUpdate,
        SetOptions(merge: true),
      );

      final progressUpdate = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (delta > 0 || completed) {
        progressUpdate['prayerDays'] =
            FieldValue.arrayUnion([_todayKey()]);
      }

      if (completed) {
        progressUpdate['completedPrayers'] =
            FieldValue.arrayUnion([prayerDocumentId]);
      }

      if (award) {
        progressUpdate['stars'] = stars + 5;
      }

      transaction.set(
        _ref,
        progressUpdate,
        SetOptions(merge: true),
      );
    });
  }

  Future<void> _completeOnce({
    required String field,
    required String id,
    required int awardStars,
    bool markPrayerDay = false,
  }) async {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(
        id,
        'id',
        'Cannot be empty.',
      );
    }

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(_ref);
      final data = snapshot.data() ?? <String, dynamic>{};

      final completed = List<String>.from(
        data[field] ?? const <String>[],
      );

      if (completed.contains(id)) return;

      final stars = data['stars'] is num
          ? (data['stars'] as num).toInt()
          : 0;

      final update = <String, dynamic>{
        field: FieldValue.arrayUnion([id]),
        'stars': stars + awardStars,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (markPrayerDay) {
        update['prayerDays'] =
            FieldValue.arrayUnion([_todayKey()]);
      }

      transaction.set(
        _ref,
        update,
        SetOptions(merge: true),
      );
    });
  }

  static String _todayKey() {
    final now = DateTime.now();

    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }
}

class KidsProgress {
  final int stars;
  final Set<String> completedLessons;
  final Set<String> completedPrayers;
  final Set<String> prayerDays;

  const KidsProgress({
    this.stars = 0,
    this.completedLessons = const {},
    this.completedPrayers = const {},
    this.prayerDays = const {},
  });

  factory KidsProgress.fromMap(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return KidsProgress.fromData(
      snapshot.data() ?? const <String, dynamic>{},
    );
  }

  factory KidsProgress.fromData(Map<String, dynamic> data) {
    Set<String> readSet(String key) {
      final value = data[key];

      if (value is Iterable) {
        return value.whereType<String>().toSet();
      }

      return <String>{};
    }

    return KidsProgress(
      stars: data['stars'] is num
          ? (data['stars'] as num).toInt()
          : 0,
      completedLessons: readSet('completedLessons'),
      completedPrayers: readSet('completedPrayers'),
      prayerDays: readSet('prayerDays'),
    );
  }

  bool get firstPrayerBadge => completedPrayers.isNotEmpty;

  bool get maryBadge => completedPrayers.length >= 2;

  bool get rosaryBadge => completedPrayers.length >= 4;

  bool get peacefulHeartBadge =>
      completedLessons.length >= 4 &&
      completedPrayers.length >= 3;

  int get badges => [
        firstPrayerBadge,
        maryBadge,
        rosaryBadge,
        peacefulHeartBadge,
      ].where((earned) => earned).length;
}
