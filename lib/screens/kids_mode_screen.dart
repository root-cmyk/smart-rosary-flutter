
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/kids_progress_service.dart';
import 'kids_rosary_guide_screen.dart';

class KidsModeScreen extends StatefulWidget {
  final VoidCallback onExitKidsMode;
  final String? parentUid;
  final String? childProfileId;

  const KidsModeScreen({
    super.key,
    required this.onExitKidsMode,
    this.parentUid,
    this.childProfileId,
  });

  @override
  State<KidsModeScreen> createState() => _KidsModeScreenState();
}

class _Palette {
  static const purple = Color(0xFF7654D6);
  static const purpleDark = Color(0xFF5B3BB5);
  static const purpleLight = Color(0xFF9476F2);
  static const ink = Color(0xFF34265D);
  static const muted = Color(0xFF81758F);
  static const background = Color(0xFFFFFBF4);
  static const lavender = Color(0xFFECE3FF);
  static const lavenderSoft = Color(0xFFF5F0FF);
  static const border = Color(0xFFEDE7F7);
  static const sun = Color(0xFFFFF0C9);
  static const sunDeep = Color(0xFFF2B531);
  static const mint = Color(0xFFE2F5E3);
  static const rose = Color(0xFFFFE6EC);
  static const sky = Color(0xFFE0F0FF);
  static const peach = Color(0xFFFFEBDC);
}

const List<Color> _lessonTints = [
  _Palette.lavender,
  _Palette.sky,
  _Palette.rose,
  _Palette.sun,
  _Palette.mint,
  _Palette.peach,
];

/// Only published lessons are shown to children.
/// Sorting is performed locally to avoid requiring a composite index.
Stream<QuerySnapshot<Map<String, dynamic>>> _publishedLessonsStream() {
  return FirebaseFirestore.instance
      .collection('kidsModules')
      .where('published', isEqualTo: true)
      .snapshots();
}

List<QueryDocumentSnapshot<Map<String, dynamic>>> _sortLessons(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
) {
  final sorted = [...docs];

  sorted.sort((a, b) {
    final aOrder = a.data()['order'];
    final bOrder = b.data()['order'];

    final aValue = aOrder is num ? aOrder : 0;
    final bValue = bOrder is num ? bOrder : 0;

    return aValue.compareTo(bValue);
  });

  return sorted;
}

String _lessonContent(Map<String, dynamic> data) {
  final content = data['content']?.toString().trim() ?? '';
  final storyText = data['storyText']?.toString().trim() ?? '';
  final intro = data['intro']?.toString().trim() ?? '';
  final description = data['description']?.toString().trim() ?? '';

  if (content.isNotEmpty) return content;
  if (storyText.isNotEmpty) return storyText;
  if (intro.isNotEmpty) return intro;
  if (description.isNotEmpty) return description;

  return 'Take a quiet moment to learn and pray.';
}

String _lessonEmoji(Map<String, dynamic> data) {
  final value = data['emoji'] ?? data['icon'];

  if (value != null && value.toString().trim().isNotEmpty) {
    return value.toString();
  }

  return '📚';
}

// ---------------------------------------------------------------------------
// Main Kids Mode shell
// ---------------------------------------------------------------------------

class _KidsModeScreenState extends State<KidsModeScreen> {
  int selectedTab = 0;

  KidsProgressService? progressService;
  bool loadingProgress = true;
  String? progressError;

  @override
  void initState() {
    super.initState();
    _initializeProgressService();
  }

  Future<void> _initializeProgressService() async {
    try {
      if (widget.parentUid != null &&
          widget.childProfileId != null) {
        // Parent is using a selected child profile.
        progressService = KidsProgressService.parentManaged(
          parentUid: widget.parentUid!,
          childProfileId: widget.childProfileId!,
        );
      } else {
        final user = FirebaseAuth.instance.currentUser;

        if (user == null) {
          throw StateError('No authenticated user for Kids Mode.');
        }

        final userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        final userData =
            userSnapshot.data() ?? <String, dynamic>{};

        final parentUid = userData['parentUid']?.toString();
        final childProfileId =
            userData['childProfileId']?.toString();

        if (parentUid != null &&
            parentUid.isNotEmpty &&
            childProfileId != null &&
            childProfileId.isNotEmpty) {
          // Parent-created child signed in independently.
          progressService = KidsProgressService.parentManaged(
            parentUid: parentUid,
            childProfileId: childProfileId,
          );
        } else {
          // Independently registered child.
          progressService =
              KidsProgressService.independent(user.uid);
        }
      }
    } catch (error) {
      progressError = error.toString();
    }

    if (!mounted) return;

    setState(() {
      loadingProgress = false;
    });
  }

  static const destinations = [
    (Icons.home_rounded, 'Home'),
    (Icons.menu_book_rounded, 'Learn'),
    (Icons.favorite_rounded, 'Pray'),
    (Icons.emoji_events_rounded, 'Rewards'),
  ];

  List<Widget> get pages {
    final service = progressService!;

    return [
      _KidsHomePage(
        progressService: service,
        parentUid: widget.parentUid,
        childProfileId: widget.childProfileId,
      ),
      _KidsLearnPage(progressService: service),
      _KidsPrayPage(progressService: service),
      _KidsRewardsPage(progressService: service),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.background,
      body: Stack(
        children: [
          const Positioned(
            top: -70,
            right: -60,
            child: IgnorePointer(
              child: _Blob(
                size: 220,
                color: Color(0xFFF1E9FF),
              ),
            ),
          ),
          const Positioned(
            top: 260,
            left: -90,
            child: IgnorePointer(
              child: _Blob(
                size: 190,
                color: Color(0xFFFFF3D6),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildPageContent()),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildPageContent() {
    if (loadingProgress) {
      return const Center(
        child: CircularProgressIndicator(
          color: _Palette.purple,
        ),
      );
    }

    if (progressError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: _Palette.purple,
                size: 42,
              ),
              const SizedBox(height: 12),
              const Text(
                'Could not load your progress.',
                style: TextStyle(
                  color: _Palette.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                progressError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _Palette.muted),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  setState(() {
                    loadingProgress = true;
                    progressError = null;
                  });
                  _initializeProgressService();
                },
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOutCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.02),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(selectedTab),
        child: pages[selectedTab],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
      child: Row(
        children: [

          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
  //  HEADER

              ],
            ),
          ),
          Tooltip(
            message: 'Parent area',
            child: Semantics(
              button: true,
              label: 'Parent area',
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _showParentDialog,
                child: Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _Palette.border),
                  ),
                  child: const Icon(
                    Icons.family_restroom_rounded,
                    color: _Palette.ink,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: _Palette.border),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F34265D),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Row(
            children: List.generate(destinations.length, (index) {
              final selected = selectedTab == index;
              final destination = destinations[index];

              return Expanded(
                child: Semantics(
                  button: true,
                  selected: selected,
                  label: destination.$2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      setState(() => selectedTab = index);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      constraints: const BoxConstraints(minHeight: 60),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? _Palette.lavender
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedScale(
                            scale: selected ? 1.12 : 1,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              destination.$1,
                              size: 28,
                              color: selected
                                  ? _Palette.purple
                                  : const Color(0xFF9B91AD),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            destination.$2,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: selected
                                  ? _Palette.purple
                                  : const Color(0xFF6E6382),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Future<void> _showParentDialog() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        icon: Container(
          height: 64,
          width: 64,
          decoration: const BoxDecoration(
            color: _Palette.lavender,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.family_restroom_rounded,
            color: _Palette.purple,
            size: 36,
          ),
        ),
        title: const Text(
          'Parent area',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _Palette.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: const Text(
          'Would you like to leave Kids Mode and return to the regular app?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _Palette.muted,
            height: 1.4,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Stay here'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _Palette.purple,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Exit Kids Mode'),
          ),
        ],
      ),
    );

    if (shouldExit == true && mounted) {
      widget.onExitKidsMode();
    }
  }
}

// ---------------------------------------------------------------------------
// Artwork
// ---------------------------------------------------------------------------

class _KidsIllustration extends StatelessWidget {
  final String asset;
  final double height;

  const _KidsIllustration({
    required this.asset,
  }) : height = 120;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/kids/$asset',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) {
        return const Icon(
          Icons.auto_awesome_rounded,
          color: _Palette.purple,
          size: 42,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Bible stories
// ---------------------------------------------------------------------------

class _BibleStoryCard extends StatelessWidget {
  final String title;
  final String description;
  final String imageUrl;
  final String storyText;
  final String activity;
  final Color tint;

  const _BibleStoryCard({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.storyText,
    required this.activity,
    required this.tint,
  });

  void _openStory(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, controller) {
          return Container(
            decoration: const BoxDecoration(
              color: _Palette.background,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: _Palette.border,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                if (imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.network(
                      imageUrl,
                      height: 190,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        height: 150,
                        color: tint,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.auto_stories_rounded,
                          color: _Palette.purple,
                          size: 54,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: const TextStyle(
                    color: _Palette.ink,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    color: _Palette.muted,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                if (storyText.trim().isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const _SectionTitle('THE STORY'),
                  const SizedBox(height: 8),
                  Text(
                    storyText,
                    style: const TextStyle(
                      color: _Palette.ink,
                      fontSize: 15,
                      height: 1.7,
                    ),
                  ),
                ],
                if (activity.trim().isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _Palette.sun,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'LET’S TRY THIS',
                          style: TextStyle(
                            color: _Palette.ink,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          activity,
                          style: const TextStyle(
                            color: _Palette.ink,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      semanticLabel: '$title. $description. Open story.',
      onTap: () => _openStory(context),
      child: Container(
        width: 190,
        height: 235,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _Palette.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D34265D),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 112,
              width: double.infinity,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(18),
              ),
              clipBehavior: Clip.antiAlias,
              child: imageUrl.isEmpty
                  ? const Icon(
                      Icons.auto_stories_rounded,
                      color: _Palette.purple,
                      size: 48,
                    )
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.auto_stories_rounded,
                        color: _Palette.purple,
                        size: 48,
                      ),
                    ),
            ),
            const SizedBox(height: 9),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _Palette.ink,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 3),
            Expanded(
              child: Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _Palette.muted,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Home page
// ---------------------------------------------------------------------------

class _KidsHomePage extends StatefulWidget {
  final KidsProgressService progressService;
  final String? parentUid;
  final String? childProfileId;

  const _KidsHomePage({
    required this.progressService,
    this.parentUid,
    this.childProfileId,
  });

  @override
  State<_KidsHomePage> createState() => _KidsHomePageState();
}

class _KidsHomePageState extends State<_KidsHomePage> {
  late Future<String> _childNameFuture;

  @override
  void initState() {
    super.initState();
    _childNameFuture = _loadChildName();
  }

  Future<String> _loadChildName() async {
    final db = FirebaseFirestore.instance;
    final user = FirebaseAuth.instance.currentUser;

    String? parentUid = widget.parentUid;
    String? childProfileId = widget.childProfileId;

    // If the child logged in independently, check whether this
    // account belongs to a parent-managed child profile.
    if (parentUid == null || childProfileId == null) {
      if (user != null) {
        final userSnapshot =
            await db.collection('users').doc(user.uid).get();

        final userData =
            userSnapshot.data() ?? <String, dynamic>{};

        parentUid ??= userData['parentUid']?.toString();
        childProfileId ??=
            userData['childProfileId']?.toString();
      }
    }

    Map<String, dynamic>? profileData;

    // Parent-managed profile.
    if (parentUid != null &&
        parentUid.isNotEmpty &&
        childProfileId != null &&
        childProfileId.isNotEmpty) {
      final childSnapshot = await db
          .collection('users')
          .doc(parentUid)
          .collection('kids')
          .doc(childProfileId)
          .get();

      profileData = childSnapshot.data();
    }

    // Independent child or fallback to the signed-in user's profile.
    if ((profileData == null || profileData.isEmpty) &&
        user != null) {
      final userSnapshot =
          await db.collection('users').doc(user.uid).get();

      profileData = userSnapshot.data();
    }

    final data = profileData ?? <String, dynamic>{};

    final possibleName = data['name'] ??
        data['displayName'] ??
        data['childName'] ??
        data['firstName'] ??
        user?.displayName;

    if (possibleName != null &&
        possibleName.toString().trim().isNotEmpty) {
      return possibleName.toString().trim();
    }

    return 'Little Star';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<KidsProgress>(
      stream: widget.progressService.watch(),
      builder: (context, snapshot) {
        final progress = snapshot.data ?? const KidsProgress();

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            FutureBuilder<String>(
              future: _childNameFuture,
              builder: (context, nameSnapshot) {
                final childName = nameSnapshot.data ?? 'Little Star';

                return Text(
                  'Hello, $childName! ⭐',
                  style: const TextStyle(
                    color: _Palette.ink,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                );
              },
            ),
            const SizedBox(height: 6),
            const Text(
              'Ready for a little moment with God?',
              style: TextStyle(
                color: _Palette.muted,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: const LinearGradient(
                  colors: [
                    _Palette.purpleLight,
                    _Palette.purpleDark,
                  ],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x40654AC4),
                    blurRadius: 22,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'YOUR NEXT ADVENTURE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Guided Rosary Journey',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Learn the Rosary one little prayer at a time. Listen, follow the words, and earn stars as you go.',
                    style: TextStyle(
                      color: Color(0xFFF0E9FF),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _Palette.purple,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => KidsRosaryGuideScreen(
                            progressService: widget.progressService,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Start Rosary journey'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    emoji: '⭐',
                    title: 'My stars',
                    value: '${progress.stars}',
                    color: _Palette.sun,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniStat(
                    emoji: '🙏',
                    title: 'Prayer days',
                    value: '${progress.prayerDays.length}',
                    color: _Palette.mint,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const _SectionTitle('Bible story adventures'),
            const SizedBox(height: 12),
            const SizedBox(
              height: 250,
              child: _StoryPreviewStrip(),
            ),
            const SizedBox(height: 22),
            const _SectionTitle('Your progress'),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _publishedLessonsStream(),
              builder: (context, lessonSnapshot) {
                final totalLessons = lessonSnapshot.hasData
                    ? lessonSnapshot.data!.docs.length
                    : 0;

                return _ProgressRow(
                  label: 'Lessons completed',
                  value: progress.completedLessons.length,
                  total: totalLessons,
                  color: _Palette.purple,
                  trackColor: _Palette.lavender,
                );
              },
            ),
            const SizedBox(height: 12),
            _ProgressRow(
              label: 'Prayers completed',
              value: progress.completedPrayers.length,
              total: 7,
              color: const Color(0xFF3F8FE0),
              trackColor: _Palette.sky,
            ),
            const SizedBox(height: 18),
            const _PreviewNote(
              'Your stars and progress are saved to your account.',
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Stories strip
// ---------------------------------------------------------------------------

class _StoryPreviewStrip extends StatelessWidget {
  const _StoryPreviewStrip();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('kidsStories')
          .where('published', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _EmptyPanel(
            icon: Icons.cloud_off_rounded,
            message: 'We could not load the stories.',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: _Palette.purple,
            ),
          );
        }

        final docs = _sortLessons(snapshot.data?.docs ?? []);

        if (docs.isEmpty) {
          return const _EmptyPanel(
            icon: Icons.auto_stories_rounded,
            message:
                'No published stories yet. Publish a story in the admin dashboard to see it here.',
          );
        }

        return ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: docs.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final data = docs[index].data();

            return _BibleStoryCard(
              title: (data['title'] ?? 'Untitled story').toString(),
              description: (data['description'] ?? '').toString(),
              imageUrl: (data['imageUrl'] ?? '').toString(),
              storyText: (data['storyText'] ?? '').toString(),
              activity: (data['activity'] ?? '').toString(),
              tint: _lessonTints[index % _lessonTints.length],
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Learn page - dynamically loaded from Firestore
// ---------------------------------------------------------------------------

class _KidsLearnPage extends StatelessWidget {
  final KidsProgressService progressService;

  const _KidsLearnPage({
    required this.progressService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<KidsProgress>(
      stream: progressService.watch(),
      builder: (context, progressSnapshot) {
        final progress =
            progressSnapshot.data ?? const KidsProgress();

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _publishedLessonsStream(),
          builder: (context, lessonSnapshot) {
            if (lessonSnapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: const [
                  _PageHeading(
                    emoji: '📚',
                    title: 'Let’s learn!',
                    subtitle:
                        'Discover prayers one little step at a time.',
                  ),
                  SizedBox(height: 24),
                  _EmptyPanel(
                    icon: Icons.cloud_off_rounded,
                    message:
                        'We could not load the lessons. Please check your connection and try again.',
                  ),
                ],
              );
            }

            if (lessonSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: _Palette.purple,
                ),
              );
            }

            final lessons =
                _sortLessons(lessonSnapshot.data?.docs ?? []);

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                const _PageHeading(
                  emoji: '📚',
                  title: 'Let’s learn!',
                  subtitle:
                      'Discover prayers one little step at a time.',
                ),
                const SizedBox(height: 18),
                _ProgressRow(
                  label: 'Lessons completed',
                  value: progress.completedLessons.length,
                  total: lessons.length,
                  color: _Palette.purple,
                  trackColor: _Palette.lavender,
                ),
                const SizedBox(height: 16),
                if (lessons.isEmpty)
                  const _EmptyPanel(
                    icon: Icons.menu_book_rounded,
                    message:
                        'No lessons are available yet. New lessons will appear here when they are published.',
                  )
                else
                  for (var i = 0; i < lessons.length; i++)
                    _ProgressLessonCard(
                      number: i + 1,
                      data: lessons[i].data(),
                      completed: progress.completedLessons
                          .contains(lessons[i].id),
                      tint: _lessonTints[i % _lessonTints.length],
                      onTap: () {
                        final data = lessons[i].data();

                        _openKidsActivity(
                          context,
                          service: progressService,
                          id: lessons[i].id,
                          title: (data['title'] ??
                                  'Untitled lesson')
                              .toString(),
                          emoji: _lessonEmoji(data),
                          isLesson: true,
                          contentOverride: _lessonContent(data),
                        );
                      },
                    ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ProgressLessonCard extends StatelessWidget {
  final int number;
  final Map<String, dynamic> data;
  final bool completed;
  final Color tint;
  final VoidCallback onTap;

  const _ProgressLessonCard({
    required this.number,
    required this.data,
    required this.completed,
    required this.tint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = (data['title'] ?? 'Untitled lesson').toString();
    final description =
        (data['description'] ?? '').toString();
    final imageUrl = (data['imageUrl'] ?? '').toString();
    final language = (data['language'] ?? '').toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _Pressable(
        semanticLabel: 'Open $title',
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.antiAlias,
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.auto_stories_rounded,
                          color: _Palette.purple,
                          size: 34,
                        ),
                      )
                    : Center(
                        child: Text(
                          _lessonEmoji(data),
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LESSON $number',
                      style: const TextStyle(
                        color: _Palette.purple,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _Palette.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _Palette.ink,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (language.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        language,
                        style: const TextStyle(
                          color: _Palette.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                completed
                    ? Icons.check_circle_rounded
                    : Icons.play_circle_fill_rounded,
                color:
                    completed ? Colors.green : _Palette.purple,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pray page
// ---------------------------------------------------------------------------

class _KidsPrayPage extends StatelessWidget {
  final KidsProgressService progressService;

  const _KidsPrayPage({
    required this.progressService,
  });

  static const prayers = [
    (
      'sign_of_cross',
      '✝️',
      'Sign of the Cross',
      'Begin with love',
      _Palette.lavender,
    ),
    (
      'our_father',
      '🤍',
      'Our Father',
      'The prayer Jesus taught us',
      _Palette.sky,
    ),
    (
      'hail_mary',
      '🌹',
      'Hail Mary',
      'A prayer to Mary',
      _Palette.rose,
    ),
    (
      'joyful_mysteries',
      '☀️',
      'Joyful Mysteries',
      'Monday and Saturday',
      _Palette.sun,
    ),
    (
      'sorrowful_mysteries',
      '💧',
      'Sorrowful Mysteries',
      'Tuesday and Friday',
      _Palette.sky,
    ),
    (
      'glorious_mysteries',
      '✨',
      'Glorious Mysteries',
      'Wednesday and Sunday',
      _Palette.lavender,
    ),
    (
      'luminous_mysteries',
      '💛',
      'Luminous Mysteries',
      'Thursday',
      _Palette.peach,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<KidsProgress>(
      stream: progressService.watch(),
      builder: (context, snapshot) {
        final progress = snapshot.data ?? const KidsProgress();

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const _PageHeading(
              emoji: '🙏',
              title: 'Let’s pray',
              subtitle:
                  'Find a quiet moment and pray with your heart.',
            ),
            const SizedBox(height: 18),
            _ProgressRow(
              label: 'Prayers completed',
              value: progress.completedPrayers.length,
              total: prayers.length,
              color: const Color(0xFF3F8FE0),
              trackColor: _Palette.sky,
            ),
            const SizedBox(height: 18),
            const _SectionTitle('Little prayers and Rosary'),
            const SizedBox(height: 12),
            for (final prayer in prayers)
              _ProgressPrayerCard(
                data: prayer,
                completed:
                    progress.completedPrayers.contains(prayer.$1),
                onTap: () => _openKidsActivity(
                  context,
                  service: progressService,
                  id: prayer.$1,
                  title: prayer.$3,
                  emoji: prayer.$2,
                  isLesson: false,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ProgressPrayerCard extends StatelessWidget {
  final (String, String, String, String, Color) data;
  final bool completed;
  final VoidCallback onTap;

  const _ProgressPrayerCard({
    required this.data,
    required this.completed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: _Pressable(
        semanticLabel: 'Open ${data.$3}',
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _Palette.border),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: data.$5,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Text(
                  data.$2,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.$3,
                      style: const TextStyle(
                        color: _Palette.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      data.$4,
                      style: const TextStyle(
                        color: _Palette.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                completed
                    ? Icons.check_circle_rounded
                    : Icons.arrow_forward_ios_rounded,
                color:
                    completed ? Colors.green : _Palette.purple,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Rewards page
// ---------------------------------------------------------------------------

class _KidsRewardsPage extends StatelessWidget {
  final KidsProgressService progressService;

  const _KidsRewardsPage({
    required this.progressService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<KidsProgress>(
      stream: progressService.watch(),
      builder: (context, snapshot) {
        final progress = snapshot.data ?? const KidsProgress();

        final badgeTitles = [
          'First Prayer Star',
          'Mary’s Little Helper',
          'Rosary Explorer',
          'Peaceful Heart',
        ];

        final badgeDescriptions = [
          'Complete your first prayer.',
          'Learn the Hail Mary.',
          'Complete all four mysteries.',
          'Complete lessons and prayers.',
        ];

        const badgeEmojis = ['⭐', '🌹', '📿', '🕊️'];

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const _PageHeading(
              emoji: '🏆',
              title: 'My little rewards',
              subtitle:
                  'Celebrate the time you spend learning and praying.',
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: _Palette.sun,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  Text(
                    '⭐ ${progress.stars} stars',
                    style: const TextStyle(
                      color: _Palette.ink,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ProgressRow(
                    label: 'Badges collected',
                    value: progress.badges,
                    total: 4,
                    color: _Palette.sunDeep,
                    trackColor: Colors.white,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Badges'),
            const SizedBox(height: 12),
            _TwoColumn(
              children: List.generate(4, (i) {
                final earned = [
                  progress.firstPrayerBadge,
                  progress.maryBadge,
                  progress.rosaryBadge,
                  progress.peacefulHeartBadge,
                ][i];

                return _EarnedBadgeCard(
                  emoji: badgeEmojis[i],
                  title: badgeTitles[i],
                  subtitle: badgeDescriptions[i],
                  earned: earned,
                );
              }),
            ),
            const SizedBox(height: 18),
            const _SectionTitle('Journeys'),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _publishedLessonsStream(),
              builder: (context, lessonSnapshot) {
                final totalLessons = lessonSnapshot.hasData
                    ? lessonSnapshot.data!.docs.length
                    : 0;

                return _ProgressRow(
                  label: 'Learn the prayers',
                  value: progress.completedLessons.length,
                  total: totalLessons,
                  color: _Palette.purple,
                  trackColor: _Palette.lavender,
                );
              },
            ),
            const SizedBox(height: 14),
            _ProgressRow(
              label: 'Complete prayers',
              value: progress.completedPrayers.length,
              total: 7,
              color: const Color(0xFF3F8FE0),
              trackColor: _Palette.sky,
            ),
            const SizedBox(height: 14),
            _ProgressRow(
              label: 'Prayer days',
              value: progress.prayerDays.length,
              total: 7,
              color: Colors.green,
              trackColor: _Palette.mint,
            ),
          ],
        );
      },
    );
  }
}

class _EarnedBadgeCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool earned;

  const _EarnedBadgeCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.earned,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: earned ? _Palette.sunDeep : _Palette.border,
          width: earned ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 35),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _Palette.ink,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _Palette.muted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          _SoonPill(
            label: earned ? 'Earned' : 'Locked',
            background:
                earned ? _Palette.mint : _Palette.lavenderSoft,
            foreground:
                earned ? Colors.green.shade800 : _Palette.purple,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Activity completion
// ---------------------------------------------------------------------------

Future<void> _openKidsActivity(
  BuildContext context, {
  required KidsProgressService service,
  required String id,
  required String title,
  required String emoji,
  required bool isLesson,
  String? contentOverride,
}) async {
  final content = <String, String>{
    'sign_of_cross':
        'In the name of the Father, and of the Son, and of the Holy Spirit. Amen.\n\nTouch your forehead, chest, left shoulder, then right shoulder as you say the words.',
    'our_father':
        'Our Father, who art in heaven, hallowed be thy name; thy kingdom come; thy will be done on earth as it is in heaven.\n\nGive us this day our daily bread; and forgive us our trespasses, as we forgive those who trespass against us; and lead us not into temptation, but deliver us from evil. Amen.',
    'hail_mary':
        'Hail Mary, full of grace, the Lord is with thee. Blessed art thou among women, and blessed is the fruit of thy womb, Jesus. Holy Mary, Mother of God, pray for us sinners, now and at the hour of our death. Amen.',
    'jesus_children':
        'People brought children to Jesus. His disciples tried to send them away, but Jesus welcomed the children and blessed them. Jesus showed that every child is precious to God.',
    'garden_eden':
        'God created a beautiful garden called Eden. He made trees, rivers, plants and animals. Creation reminds us to thank God and care for the world.',
    'joyful_mysteries':
        'The Joyful Mysteries: The Annunciation; The Visitation; The Nativity; The Presentation; The Finding of Jesus in the Temple.',
    'sorrowful_mysteries':
        'The Sorrowful Mysteries: The Agony in the Garden; The Scourging at the Pillar; The Crowning with Thorns; The Carrying of the Cross; The Crucifixion.',
    'glorious_mysteries':
        'The Glorious Mysteries: The Resurrection; The Ascension; The Descent of the Holy Spirit; The Assumption of Mary; The Coronation of Mary.',
    'luminous_mysteries':
        'The Luminous Mysteries: The Baptism of Jesus; The Wedding at Cana; The Proclamation of the Kingdom; The Transfiguration; The Institution of the Eucharist.',
  };

  final progress = await service.watch().first;

  final completed = isLesson
      ? progress.completedLessons.contains(id)
      : progress.completedPrayers.contains(id);

  if (!context.mounted) return;

  final displayContent =
      contentOverride != null && contentOverride.trim().isNotEmpty
          ? contentOverride
          : content[id] ?? 'Take a quiet moment to learn and pray.';

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(28),
      ),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 48),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _Palette.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight:
                      MediaQuery.of(sheetContext).size.height * 0.48,
                ),
                child: SingleChildScrollView(
                  child: Text(
                    displayContent,
                    style: const TextStyle(
                      color: _Palette.ink,
                      fontSize: 16,
                      height: 1.65,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: completed
                    ? null
                    : () async {
                        try {
                          if (isLesson) {
                            await service.completeLesson(id);
                          } else {
                            await service.completePrayer(id);
                          }

                          if (sheetContext.mounted) {
                            Navigator.pop(sheetContext);
                          }

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Completed! You earned 5 stars. ⭐',
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (sheetContext.mounted) {
                            ScaffoldMessenger.of(sheetContext)
                                .showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Could not save progress: $e',
                                ),
                              ),
                            );
                          }
                        }
                      },
                icon: Icon(
                  completed
                      ? Icons.check_circle
                      : Icons.star_rounded,
                ),
                label: Text(
                  completed
                      ? 'Already completed'
                      : 'Mark complete · Earn 5 stars',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _Palette.purple,
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

class _Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final String semanticLabel;

  const _Pressable({
    required this.child,
    required this.onTap,
    required this.semanticLabel,
  });

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) {
      setState(() => _pressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: ExcludeSemantics(child: widget.child),
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;

  const _Blob({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _Palette.ink,
        fontWeight: FontWeight.w900,
        fontSize: 20,
      ),
    );
  }
}

class _PageHeading extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;

  const _PageHeading({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 72,
          width: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _Palette.border),
          ),
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 38),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _Palette.ink,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _Palette.muted,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PreviewNote extends StatelessWidget {
  final String text;

  const _PreviewNote(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _Palette.lavenderSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: _Palette.purple,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: _Palette.muted,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoonPill extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _SoonPill({
    this.label = 'Soon',
    this.background = _Palette.lavenderSoft,
    this.foreground = _Palette.purple,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String emoji;
  final String title;
  final String value;
  final Color color;

  const _MiniStat({
    required this.emoji,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: _Palette.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    height: 1.1,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    color: _Palette.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TwoColumn extends StatelessWidget {
  final List<Widget> children;

  const _TwoColumn({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    for (var i = 0; i < children.length; i += 2) {
      final second =
          i + 1 < children.length ? children[i + 1] : null;

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: children[i]),
                const SizedBox(width: 12),
                Expanded(
                  child: second ?? const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(children: rows);
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;
  final Color trackColor;

  const _ProgressRow({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
    required this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0
        ? 0.0
        : (value / total).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: _Palette.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              '$value / $total',
              style: const TextStyle(
                color: _Palette.ink,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 14,
            backgroundColor: trackColor,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyPanel({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _Palette.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: _Palette.purple,
            size: 36,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _Palette.muted,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
