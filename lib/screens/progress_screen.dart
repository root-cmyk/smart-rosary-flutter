
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/soft_card.dart';
import '../widgets/screen_header.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _progressStream(
    String uid,
  ) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('prayerProgress')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _rosaryStream(
    String uid,
  ) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('rosaryProgress')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _prayersStream() {
    return FirebaseFirestore.instance
        .collection('prayers')
        .where('published', isEqualTo: true)
        .snapshots();
  }

  int _calculateStreak(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    final completedDates = <DateTime>{};

    for (final document in documents) {
      final data = document.data();

      if (data['completed'] != true) continue;

      final timestamp = data['completedAt'];

      if (timestamp is Timestamp) {
        final date = timestamp.toDate();

        completedDates.add(
          DateTime(date.year, date.month, date.day),
        );
      }
    }

    if (completedDates.isEmpty) return 0;

    final today = DateTime.now();
    final currentDay = DateTime(today.year, today.month, today.day);

    DateTime streakDay;

    if (completedDates.contains(currentDay)) {
      streakDay = currentDay;
    } else {
      final yesterday = currentDay.subtract(
        const Duration(days: 1),
      );

      if (!completedDates.contains(yesterday)) {
        return 0;
      }

      streakDay = yesterday;
    }

    int streak = 0;

    while (completedDates.contains(streakDay)) {
      streak++;
      streakDay = streakDay.subtract(
        const Duration(days: 1),
      );
    }

    return streak;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const SafeArea(
        child: Center(
          child: Text(
            'Please sign in to view your progress.',
            style: TextStyle(color: muted),
          ),
        ),
      );
    }

    return SafeArea(
      bottom: false,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _prayersStream(),
        builder: (context, prayersSnapshot) {
          if (prayersSnapshot.hasError) {
            return _buildError(
              'Unable to load published prayers.',
            );
          }

          if (!prayersSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: purple),
            );
          }

          final totalPrayers = prayersSnapshot.data!.docs.length;

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _progressStream(user.uid),
            builder: (context, progressSnapshot) {
              if (progressSnapshot.hasError) {
                return _buildError(
                  'Unable to load your learning progress.',
                );
              }

              if (!progressSnapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: purple),
                );
              }

              final progressDocuments = progressSnapshot.data!.docs;

              final completedDocuments = progressDocuments.where(
                (document) =>
                    document.data()['completed'] == true,
              ).toList();

              final learnedCount = completedDocuments.length;

              final percentage = totalPrayers == 0
                  ? 0.0
                  : (learnedCount / totalPrayers).clamp(0.0, 1.0);

              final percentageText =
                  '${(percentage * 100).round()}%';

              final streak = _calculateStreak(progressDocuments);

              final message = learnedCount == 0
                  ? 'Your journey starts here!'
                  : learnedCount >= totalPrayers && totalPrayers > 0
                      ? 'Amazing! You have learned every available prayer.'
                      : 'Keep going! Every prayer brings you closer.';

              return StreamBuilder<
                  QuerySnapshot<Map<String, dynamic>>>(
                stream: _rosaryStream(user.uid),
                builder: (context, rosarySnapshot) {
                  // Debugging is intentionally inside this StreamBuilder.
                  if (rosarySnapshot.hasError) {
                    debugPrint(
                      'ROSARY PROGRESS ERROR: ${rosarySnapshot.error}',
                    );

                    return _buildError(
                      'Unable to load your Rosary progress: '
                      '${rosarySnapshot.error}',
                    );
                  }

                  if (!rosarySnapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: purple,
                      ),
                    );
                  }

                  final completedRosaries = rosarySnapshot
                      .data!
                      .docs
                      .where(
                        (document) =>
                            document.data()['completed'] == true,
                      )
                      .length;

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                      22,
                      25,
                      22,
                      125,
                    ),
                    children: [
                      const ScreenHeader(
                        eyebrow: 'Every step matters',
                        title: 'My progress',
                        subtitle:
                            'Celebrate what you learn along the way.',
                      ),

                      const SizedBox(height: 25),

                      SoftCard(
                        padding: const EdgeInsets.all(23),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 155,
                              width: 155,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    height: 145,
                                    width: 145,
                                    child: CircularProgressIndicator(
                                      value: percentage,
                                      strokeWidth: 12,
                                      backgroundColor: lavender,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                        purple,
                                      ),
                                    ),
                                  ),

                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.auto_awesome_rounded,
                                        size: 27,
                                        color: purple,
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        percentageText,
                                        style: const TextStyle(
                                          fontSize: 29,
                                          fontWeight: FontWeight.w900,
                                          color: ink,
                                        ),
                                      ),
                                      const Text(
                                        'completed',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 18),

                            Text(
                              message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: ink,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),

                            const SizedBox(height: 7),

                            Text(
                              '$learnedCount of $totalPrayers published prayers learned.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: muted,
                                height: 1.5,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      const SectionTitle(
                        title: 'Learning overview',
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _ProgressTile(
                              icon: Icons.menu_book_rounded,
                              number: '$learnedCount',
                              label: 'Prayers learned',
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: _ProgressTile(
                              icon: Icons.library_books_rounded,
                              number: '$totalPrayers',
                              label: 'Published prayers',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _ProgressTile(
                              icon: Icons.favorite_rounded,
                              number: '$completedRosaries',
                              label: 'Rosaries completed',
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: _ProgressTile(
                              icon: Icons.local_fire_department_rounded,
                              number:
                                  '$streak ${streak == 1 ? 'day' : 'days'}',
                              label: 'Prayer learning streak',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      const SectionTitle(
                        title: 'Keep growing',
                      ),

                      const SizedBox(height: 12),

                      SoftCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.favorite_rounded,
                              color: purple,
                              size: 25,
                            ),

                            const SizedBox(width: 13),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Consistency is key',
                                    style: TextStyle(
                                      color: ink,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),

                                  const SizedBox(height: 5),

                                  const Text(
                                    'Learn a new prayer every day and build a stronger prayer habit.',
                                    style: TextStyle(
                                      color: muted,
                                      fontSize: 12,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: muted,
              size: 35,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressTile extends StatelessWidget {
  final IconData icon;
  final String number;
  final String label;

  const _ProgressTile({
    required this.icon,
    required this.number,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: purple,
            size: 23,
          ),
          const SizedBox(height: 14),
          Text(
            number,
            style: const TextStyle(
              fontSize: 23,
              color: ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: muted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
