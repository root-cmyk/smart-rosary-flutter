
import 'package:flutter/material.dart';

import '../services/prayer.dart';
import '../theme/app_theme.dart';
import '../widgets/icon_tile.dart';
import '../widgets/soft_card.dart';
import '../widgets/screen_header.dart';
import 'prayer_detail_screen.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  final TextEditingController searchController = TextEditingController();
  final PrayerService _prayerService = PrayerService();

  late Stream<List<Map<String, dynamic>>> _prayersStream;

  String searchQuery = '';
  String selectedLanguage = 'All Languages';
  String selectedCategory = 'All Categories';

  static const List<String> languages = [
    'All Languages',
    'English',
    'Luganda',
    'Runyankole',
    'Swahili',
  ];

  static const List<String> standardCategories = [
    'Basic Prayers',
    'Rosary Mysteries',
    'Marian Prayers',
    'Other Prayers',
  ];

  @override
  void initState() {
    super.initState();
    _prayersStream = _prayerService.watchPublishedPrayers();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _retryLoading() {
    setState(() {
      _prayersStream = _prayerService.watchPublishedPrayers();
    });
  }

  void _clearFilters() {
    searchController.clear();

    setState(() {
      searchQuery = '';
      selectedLanguage = 'All Languages';
      selectedCategory = 'All Categories';
    });
  }

  IconData _iconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'basic prayers':
        return Icons.menu_book_rounded;
      case 'rosary mysteries':
        return Icons.auto_awesome_rounded;
      case 'marian prayers':
        return Icons.local_florist_rounded;
      case 'other prayers':
        return Icons.favorite_rounded;
      default:
        return Icons.volunteer_activism_rounded;
    }
  }

  String _previewText(String text) {
    final cleaned = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (cleaned.isEmpty) {
      return 'Open to explore this prayer.';
    }

    if (cleaned.length <= 105) {
      return cleaned;
    }

    return '${cleaned.substring(0, 105).trim()}...';
  }

  List<String> _buildCategories(
    List<Map<String, dynamic>> prayers,
  ) {
    final categories = <String>{
      ...standardCategories,
      ...prayers
          .map((prayer) =>
              prayer['category']?.toString().trim() ?? '')
          .where((category) => category.isNotEmpty),
    };

    final result = categories.toList();

    result.sort((a, b) {
      final indexA = standardCategories.indexOf(a);
      final indexB = standardCategories.indexOf(b);

      if (indexA != -1 && indexB != -1) {
        return indexA.compareTo(indexB);
      }

      if (indexA != -1) return -1;
      if (indexB != -1) return 1;

      return a.toLowerCase().compareTo(b.toLowerCase());
    });

    return result;
  }

  List<Map<String, dynamic>> _filterPrayers(
    List<Map<String, dynamic>> prayers,
  ) {
    final filtered = prayers.where((prayer) {
      final title = prayer['title']?.toString() ?? '';
      final text = prayer['text']?.toString() ?? '';
      final category =
          prayer['category']?.toString() ?? 'Other Prayers';
      final language =
          prayer['language']?.toString() ?? 'English';

      final matchesSearch = searchQuery.isEmpty ||
          title.toLowerCase().contains(searchQuery) ||
          text.toLowerCase().contains(searchQuery) ||
          category.toLowerCase().contains(searchQuery) ||
          language.toLowerCase().contains(searchQuery);

      final matchesLanguage =
          selectedLanguage == 'All Languages' ||
              language.toLowerCase() ==
                  selectedLanguage.toLowerCase();

      final matchesCategory =
          selectedCategory == 'All Categories' ||
              category.toLowerCase() ==
                  selectedCategory.toLowerCase();

      return matchesSearch && matchesLanguage && matchesCategory;
    }).toList();

    filtered.sort((a, b) {
      final titleA = a['title']?.toString() ?? '';
      final titleB = b['title']?.toString() ?? '';

      return titleA.toLowerCase().compareTo(
            titleB.toLowerCase(),
          );
    });

    return filtered;
  }

  void _openPrayer(
    BuildContext context,
    Map<String, dynamic> prayer,
  ) {
    final title =
        prayer['title']?.toString() ?? 'Untitled prayer';

    final category =
        prayer['category']?.toString() ?? 'Other Prayers';

    final language =
        prayer['language']?.toString() ?? 'English';

    final prayerText =
        prayer['text']?.toString() ?? '';

    final audioPath =
        prayer['audioPath']?.toString() ?? '';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PrayerDetailScreen(
          title: title,
          description: '$category • $language',
          prayerText: prayerText,
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
            eyebrow: 'Grow in faith',
            title: 'Prayer library',
            subtitle: 'One prayer at a time, one day at a time.',
          ),

          const SizedBox(height: 22),

          // SEARCH
          TextField(
            controller: searchController,
            onChanged: (value) {
              setState(() {
                searchQuery = value.trim().toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: 'Search prayers by title or text...',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: muted,
              ),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        searchController.clear();

                        setState(() {
                          searchQuery = '';
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(19),
                borderSide: const BorderSide(
                  color: Color(0xFFF0ECF8),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(19),
                borderSide: const BorderSide(
                  color: Color(0xFFF0ECF8),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(19),
                borderSide: const BorderSide(
                  color: purple,
                  width: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // LIVE FIRESTORE PRAYER LIBRARY
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _prayersStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _ErrorCard(
                  onRetry: _retryLoading,
                );
              }

              if (snapshot.connectionState ==
                      ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(35),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: purple,
                    ),
                  ),
                );
              }

              final allPrayers = snapshot.data ?? [];

              final categories = _buildCategories(allPrayers);

              final filtered = _filterPrayers(allPrayers);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LIBRARY SUMMARY
                  SoftCard(
                    padding: const EdgeInsets.all(17),
                    child: Row(
                      children: [
                        const IconTile(
                          icon: Icons.menu_book_rounded,
                          background: lavender,
                          color: purple,
                          size: 47,
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your prayer library',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: ink,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${allPrayers.length} published prayers available',
                                style: const TextStyle(
                                  color: muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: lavender,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            '${allPrayers.length}',
                            style: const TextStyle(
                              color: deepPurple,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 23),

                  // LANGUAGE FILTER
                  const Text(
                    'Language',
                    style: TextStyle(
                      color: ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 8),

                  DropdownButtonFormField<String>(
                    initialValue: selectedLanguage,
                    isExpanded: true,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.translate_rounded,
                        color: Color(0xFF8056D8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFFF0ECF8),
                        ),
                      ),
                    ),
                    items: languages.map((language) {
                      return DropdownMenuItem<String>(
                        value: language,
                        child: Text(language),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedLanguage = value;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  // CATEGORY FILTER
                  const Text(
                    'Category',
                    style: TextStyle(
                      color: ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 8),

                  DropdownButtonFormField<String>(
                    initialValue: categories.contains(selectedCategory)
                        ? selectedCategory
                        : 'All Categories',
                    isExpanded: true,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.category_rounded,
                        color: Color(0xFF8056D8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFFF0ECF8),
                        ),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: 'All Categories',
                        child: Text('All Categories'),
                      ),
                      ...categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedCategory = value;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 24),

                  // RESULTS HEADER
                  Row(
                    children: [
                      Expanded(
                        child: SectionTitle(
                          title: 'Discover prayers',
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: lavender,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${filtered.length} found',
                          style: const TextStyle(
                            color: deepPurple,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 13),

                  // EMPTY STATE
                  if (filtered.isEmpty)
                    _EmptyState(
                      hasPrayers: allPrayers.isNotEmpty,
                      hasFilters: searchQuery.isNotEmpty ||
                          selectedLanguage != 'All Languages' ||
                          selectedCategory != 'All Categories',
                      onClear: _clearFilters,
                    )

                  // PRAYER LIST
                  else
                    ...filtered.map((prayer) {
                      final title =
                          prayer['title']?.toString() ??
                              'Untitled prayer';

                      final category =
                          prayer['category']?.toString() ??
                              'Other Prayers';

                      final language =
                          prayer['language']?.toString() ??
                              'English';

                      final prayerText =
                          prayer['text']?.toString() ?? '';

                      final audioPath =
                          prayer['audioPath']?.toString() ?? '';

                      final hasAudio = audioPath.isNotEmpty;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SoftCard(
                          padding: const EdgeInsets.all(13),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              _openPrayer(context, prayer);
                            },
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                IconTile(
                                  icon: hasAudio
                                      ? Icons.headphones_rounded
                                      : _iconForCategory(category),
                                  size: 51,
                                ),

                                const SizedBox(width: 13),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          color: ink,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),

                                      const SizedBox(height: 5),

                                      Text(
                                        '$category • $language',
                                        style: const TextStyle(
                                          color: muted,
                                          fontSize: 11,
                                        ),
                                      ),

                                      const SizedBox(height: 7),

                                      Text(
                                        _previewText(prayerText),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: muted,
                                          fontSize: 11,
                                          height: 1.5,
                                        ),
                                      ),

                                      const SizedBox(height: 9),

                                      Row(
                                        children: [
                                          if (hasAudio) ...[
                                            const Icon(
                                              Icons.headphones_rounded,
                                              size: 13,
                                              color: purple,
                                            ),
                                            const SizedBox(width: 4),
                                            const Text(
                                              'Audio available',
                                              style: TextStyle(
                                                color: purple,
                                                fontSize: 10,
                                                fontWeight:
                                                    FontWeight.w700,
                                              ),
                                            ),
                                          ] else ...[
                                            const Icon(
                                              Icons.menu_book_rounded,
                                              size: 13,
                                              color: muted,
                                            ),
                                            const SizedBox(width: 4),
                                            const Text(
                                              'Read prayer',
                                              style: TextStyle(
                                                color: muted,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const Padding(
                                  padding: EdgeInsets.only(top: 12),
                                  child: Icon(
                                    Icons.chevron_right_rounded,
                                    color: muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ERROR STATE
class _ErrorCard extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorCard({
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 43,
              color: muted,
            ),
            const SizedBox(height: 12),
            const Text(
              'Unable to load prayers',
              style: TextStyle(
                color: ink,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Check your internet connection and Firestore permissions, then try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: muted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 15),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// EMPTY STATE
class _EmptyState extends StatelessWidget {
  final bool hasPrayers;
  final bool hasFilters;
  final VoidCallback onClear;

  const _EmptyState({
    required this.hasPrayers,
    required this.hasFilters,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Padding(
        padding: const EdgeInsets.all(23),
        child: Column(
          children: [
            Icon(
              hasPrayers
                  ? Icons.search_off_rounded
                  : Icons.menu_book_rounded,
              size: 45,
              color: purple,
            ),
            const SizedBox(height: 13),
            Text(
              hasPrayers
                  ? 'No prayers match your filters.'
                  : 'No published prayers yet.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ink,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              hasPrayers
                  ? 'Try another search, language, or category.'
                  : 'Published prayers from the administrator will appear here.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: muted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            if (hasFilters) ...[
              const SizedBox(height: 13),
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.filter_alt_off_rounded),
                label: const Text('Clear all filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
