
import 'package:flutter/material.dart';

import '../services/prayer.dart';
import '../theme/app_theme.dart';
import '../widgets/icon_tile.dart';
import '../widgets/soft_card.dart';
import '../widgets/screen_header.dart';
import 'mystery_detail_screen.dart';
import 'prayer_detail_screen.dart';

class PrayScreen extends StatefulWidget {
  const PrayScreen({super.key});

  @override
  State<PrayScreen> createState() => _PrayScreenState();
}

class _PrayScreenState extends State<PrayScreen> {
  String selectedLanguage = 'All Languages';

  static const languages = [
    'All Languages',
    'English',
    'Luganda',
    'Runyankole',
    'Swahili',
  ];

  static const categoryOrder = [
    'Basic Prayers',
    'Rosary Mysteries',
    'Marian Prayers',
    'Other Prayers',
  ];

  static const mysteries = [
    (
      'Joyful Mysteries',
      'Monday & Saturday',
      Icons.wb_sunny_rounded,
      Color(0xFFFFF0D6),
      Color(0xFFC18A2F),
    ),
    (
      'Sorrowful Mysteries',
      'Tuesday & Friday',
      Icons.water_drop_rounded,
      Color(0xFFE5E9FF),
      Color(0xFF596AC5),
    ),
    (
      'Glorious Mysteries',
      'Wednesday & Sunday',
      Icons.auto_awesome_rounded,
      Color(0xFFECE1FF),
      Color(0xFF8056D8),
    ),
    (
      'Luminous Mysteries',
      'Thursday',
      Icons.light_mode_rounded,
      Color(0xFFFFF2B9),
      Color(0xFFB88C12),
    ),
  ];

  String _getPrayerId(Map<String, dynamic> prayer) {
    return prayer['id']?.toString() ??
        prayer['prayerId']?.toString() ??
        prayer['documentId']?.toString() ??
        '';
  }

  void _openPrayer(Map<String, dynamic> prayer, String category) {
    final title =
        prayer['title']?.toString() ?? 'Untitled prayer';

    final language =
        prayer['language']?.toString() ?? 'English';

    final text = prayer['text']?.toString() ?? '';

    final audioPath =
        prayer['audioPath']?.toString() ?? '';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PrayerDetailScreen(
          prayerId: _getPrayerId(prayer),
          title: title,
          description: '$category • $language',
          prayerText: text,
          audioPath: audioPath,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 25, 22, 125),
        children: [
          const ScreenHeader(
            eyebrow: 'A moment of peace',
            title: 'Let us pray',
            subtitle:
                'Slow down, breathe, and spend time with God.',
          ),

          const SizedBox(height: 24),

          // Welcome banner
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(27),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF7E60D8),
                  Color(0xFF4F329D),
                ],
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 30,
                ),
                SizedBox(height: 17),
                Text(
                  'A little prayer,\na lot of love.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 9),
                Text(
                  'Choose a set of mysteries or a prayer below.',
                  style: TextStyle(
                    color: Color(0xFFE9E0FF),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 26),

          // Rosary mysteries
          const SectionTitle(title: 'The four mysteries'),
          const SizedBox(height: 12),

          ...mysteries.map((mystery) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SoftCard(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MysteryDetailScreen(
                        title: mystery.$1,
                        schedule: mystery.$2,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconTile(
                        icon: mystery.$3,
                        background: mystery.$4,
                        color: mystery.$5,
                        size: 54,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              mystery.$1,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: ink,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              mystery.$2,
                              style: const TextStyle(
                                color: muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 15,
                        color: muted,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 18),

          // Published prayer library
          const SectionTitle(title: 'Prayer library'),
          const SizedBox(height: 6),
          const Text(
            'Explore prayers published by your Smart Rosary administrator.',
            style: TextStyle(
              color: muted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),

          // Language filter
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.translate_rounded,
                      color: Color(0xFF8056D8),
                    ),
                    SizedBox(width: 9),
                    Text(
                      'Choose prayer language',
                      style: TextStyle(
                        color: ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedLanguage,
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF5F1FF),
                    contentPadding:
                        const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: languages.map((language) {
                    return DropdownMenuItem<String>(
                      value: language,
                      child: Text(language),
                    );
                  }).toList(),
                  onChanged: (language) {
                    if (language != null) {
                      setState(() {
                        selectedLanguage = language;
                      });
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Live published prayer library
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: PrayerService().watchPublishedPrayers(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const SoftCard(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Unable to load prayers. Check your connection, '
                      'Firebase configuration, and Firestore permissions.',
                      style: TextStyle(color: muted),
                    ),
                  ),
                );
              }

              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final allPrayers = snapshot.data ?? [];

              final prayers = allPrayers.where((prayer) {
                final language =
                    prayer['language']?.toString() ?? 'English';

                return selectedLanguage == 'All Languages' ||
                    language.toLowerCase() ==
                        selectedLanguage.toLowerCase();
              }).toList();

              if (prayers.isEmpty) {
                return SoftCard(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.menu_book_rounded,
                          size: 38,
                          color: Color(0xFF8056D8),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          allPrayers.isEmpty
                              ? 'No published prayers yet.'
                              : 'No published prayers in $selectedLanguage.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Published prayers will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Group prayers by category.
              final Map<String, List<Map<String, dynamic>>>
                  grouped = {};

              for (final prayer in prayers) {
                final category =
                    prayer['category']?.toString().trim();

                final categoryName =
                    category == null || category.isEmpty
                        ? 'Other Prayers'
                        : category;

                grouped.putIfAbsent(categoryName, () => []);
                grouped[categoryName]!.add(prayer);
              }

              // Standard categories first, custom categories after.
              final categories = grouped.keys.toList()
                ..sort((a, b) {
                  final indexA = categoryOrder.indexOf(a);
                  final indexB = categoryOrder.indexOf(b);

                  final orderA = indexA == -1
                      ? categoryOrder.length
                      : indexA;

                  final orderB = indexB == -1
                      ? categoryOrder.length
                      : indexB;

                  if (orderA != orderB) {
                    return orderA.compareTo(orderB);
                  }

                  return a.toLowerCase().compareTo(
                        b.toLowerCase(),
                      );
                });

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: categories.map((category) {
                  final categoryPrayers = grouped[category]!;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: SectionTitle(
                                title: category,
                              ),
                            ),
                            Text(
                              '${categoryPrayers.length} '
                              '${categoryPrayers.length == 1 ? 'prayer' : 'prayers'}',
                              style: const TextStyle(
                                color: muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        ...categoryPrayers.map((prayer) {
                          final title =
                              prayer['title']?.toString() ??
                                  'Untitled prayer';

                          final language =
                              prayer['language']?.toString() ??
                                  'English';

                          final audioPath =
                              prayer['audioPath']?.toString() ?? '';

                          final hasAudio = audioPath.isNotEmpty;

                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: 10,
                            ),
                            child: SoftCard(
                              child: InkWell(
                                borderRadius:
                                    BorderRadius.circular(16),
                                onTap: () => _openPrayer(
                                  prayer,
                                  category,
                                ),
                                child: Row(
                                  children: [
                                    IconTile(
                                      icon: hasAudio
                                          ? Icons.headphones_rounded
                                          : Icons.menu_book_rounded,
                                      background:
                                          const Color(0xFFECE1FF),
                                      color:
                                          const Color(0xFF8056D8),
                                      size: 50,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: const TextStyle(
                                              fontWeight:
                                                  FontWeight.w800,
                                              color: ink,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            language,
                                            style: const TextStyle(
                                              color: muted,
                                              fontSize: 11,
                                            ),
                                          ),
                                          if (hasAudio) ...[
                                            const SizedBox(height: 5),
                                            const Row(
                                              children: [
                                                Icon(
                                                  Icons.headphones_rounded,
                                                  size: 13,
                                                  color:
                                                      Color(0xFF8056D8),
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Audio available',
                                                  style: TextStyle(
                                                    color:
                                                        Color(0xFF8056D8),
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 14,
                                      color: muted,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
