import 'package:cloud_firestore/cloud_firestore.dart';

/// Live reader for the existing admin portal `prayers` collection.
class PrayerContentService {
  PrayerContentService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _prayers =>
      _firestore.collection('prayers');

  Stream<List<PrayerContent>> watchPublished() {
    return _prayers
        .where('published', isEqualTo: true)
        .snapshots()
        .map(_mapAndSort);
  }

  Stream<List<PrayerContent>> watchCategory(String category) {
    return watchPublished().map(
      (items) => items
          .where((item) =>
              item.category.trim().toLowerCase() ==
              category.trim().toLowerCase())
          .toList(growable: false),
    );
  }

  Stream<List<PrayerContent>> watchGuided() {
    return watchPublished().map(
      (items) => items.where((item) => item.hasAudio).toList(growable: false),
    );
  }

  Stream<List<String>> watchCategories() {
    return watchPublished().map((items) {
      final categories = items
          .map((item) => item.category.trim())
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList();
      categories.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return categories;
    });
  }

  List<PrayerContent> _mapAndSort(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final items = snapshot.docs
        .map(PrayerContent.fromFirestore)
        .toList();
    items.sort((a, b) {
      if (a.createdAt == null && b.createdAt == null) {
        return a.title.compareTo(b.title);
      }
      if (a.createdAt == null) return 1;
      if (b.createdAt == null) return -1;
      return b.createdAt!.compareTo(a.createdAt!);
    });
    return items;
  }
}

class PrayerContent {
  const PrayerContent({
    required this.id,
    required this.title,
    required this.category,
    required this.language,
    required this.published,
    this.audioPath,
    this.audioFileName,
    this.audioContentType,
    this.createdAt,
    this.updatedAt,
    this.text,
  });

  /// Canonical content ID: the Firestore document ID from `prayers`.
  final String id;
  final String title;
  final String category;
  final String language;
  final bool published;
  final String? audioPath;
  final String? audioFileName;
  final String? audioContentType;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Optional future field; current admin form does not create prayer text.
  final String? text;

  bool get hasAudio => audioPath != null && audioPath!.trim().isNotEmpty;

  factory PrayerContent.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    DateTime? dateValue(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }

    String? stringValue(dynamic value) {
      if (value is String && value.trim().isNotEmpty) return value.trim();
      return null;
    }

    return PrayerContent(
      id: document.id,
      title: (data['title'] as String? ?? '').trim(),
      category: (data['category'] as String? ?? '').trim(),
      language: (data['language'] as String? ?? '').trim(),
      published: data['published'] == true,
      audioPath: stringValue(data['audioPath']),
      audioFileName: stringValue(data['audioFileName']),
      audioContentType: stringValue(data['audioContentType']),
      createdAt: dateValue(data['createdAt']),
      updatedAt: dateValue(data['updatedAt']),
      text: stringValue(data['text'] ?? data['content'] ?? data['body']),
    );
  }
}
