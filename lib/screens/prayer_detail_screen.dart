
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:just_audio/just_audio.dart';

import '../theme/app_theme.dart';
import '../widgets/app_message.dart';
import '../widgets/icon_tile.dart';
import '../widgets/soft_card.dart';

class PrayerDetailScreen extends StatefulWidget {
  final String title;
  final String description;
  final String prayerText;
  final String audioPath;
  final String prayerId;

  const PrayerDetailScreen({
    super.key,
    required this.title,
    required this.description,
    this.prayerText = '',
    this.audioPath = '',
    this.prayerId = '',
  });

  @override
  State<PrayerDetailScreen> createState() =>
      _PrayerDetailScreenState();
}

class _PrayerDetailScreenState extends State<PrayerDetailScreen> {
  late final AudioPlayer _player;

  final ScrollController _prayerScrollController =
      ScrollController();

  late final List<String> _prayerWords;
  late final List<GlobalKey> _wordKeys;

  bool _loadingAudio = false;
  bool _audioReady = false;
  bool _savingProgress = false;
  bool _hasStartedPlayback = false;

  int _lastAutoScrolledWord = -1;

  String? _audioError;

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  String get _progressDocumentId {
    final suppliedId = widget.prayerId.trim();

    if (suppliedId.isNotEmpty) {
      return suppliedId;
    }

    final audio = widget.audioPath.trim();

    final source = audio.isNotEmpty
        ? audio
        : widget.title.trim().toLowerCase();

    final normalized = source
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    return normalized.isEmpty ? 'prayer' : normalized;
  }

  DocumentReference<Map<String, dynamic>>? get _progressReference {
    final user = _currentUser;

    if (user == null) return null;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('prayerProgress')
        .doc(_progressDocumentId);
  }

  @override
  void initState() {
    super.initState();

    _player = AudioPlayer();

    _prayerWords = widget.prayerText
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    _wordKeys = List.generate(
      _prayerWords.length,
      (_) => GlobalKey(),
    );
  }

  @override
  void dispose() {
    _prayerScrollController.dispose();
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _prepareAndPlayAudio() async {
    if (_loadingAudio) return;

    if (widget.audioPath.trim().isEmpty) {
      setState(() {
        _audioError = 'No audio has been uploaded for this prayer.';
      });
      return;
    }

    setState(() {
      _loadingAudio = true;
      _audioError = null;
    });

    try {
      if (_audioReady) {
        if (_player.playing) {
          await _player.pause();
        } else {
          if (_player.processingState ==
              ProcessingState.completed) {
            await _player.seek(Duration.zero);
          }

          _hasStartedPlayback = true;
          _lastAutoScrolledWord = -1;

          await _player.play();
        }

        return;
      }

      final user = _currentUser;

      if (user == null) {
        throw Exception(
          'Please sign in to listen to this prayer.',
        );
      }

      final firebaseToken = await user.getIdToken();

      if (firebaseToken == null || firebaseToken.isEmpty) {
        throw Exception(
          'Could not verify your sign-in. Please sign in again.',
        );
      }

      final response =
          await Supabase.instance.client.functions.invoke(
        'get-prayer-audio-url',
        body: {
          'path': widget.audioPath,
        },
        headers: {
          'Authorization': 'Bearer $firebaseToken',
        },
      );

      if (response.status < 200 || response.status >= 300) {
        throw Exception(
          'Could not get permission to play this audio.',
        );
      }

      final data = response.data;

      if (data is! Map || data['signedUrl'] is! String) {
        throw Exception(
          'The audio service returned an invalid response.',
        );
      }

      final signedUrl = data['signedUrl'] as String;

      if (signedUrl.isEmpty) {
        throw Exception(
          'No playable audio URL was returned.',
        );
      }

      await _player.setUrl(signedUrl);

      if (!mounted) return;

      setState(() {
        _audioReady = true;
        _hasStartedPlayback = true;
        _lastAutoScrolledWord = -1;
      });

      await _player.play();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _audioError = error
            .toString()
            .replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingAudio = false;
        });
      }
    }
  }

  Future<void> _markAsLearned() async {
    if (_savingProgress) return;

    final user = _currentUser;

    if (user == null) {
      showMessage(
        context,
        'Please sign in to save your learning progress.',
      );
      return;
    }

    final reference = _progressReference;

    if (reference == null) return;

    setState(() {
      _savingProgress = true;
    });

    try {
      final existing = await reference.get();

      if (existing.exists &&
          existing.data()?['completed'] == true) {
        if (mounted) {
          showMessage(
            context,
            'You have already learned this prayer.',
          );
        }
        return;
      }

      await reference.set({
        'prayerId': _progressDocumentId,
        'prayerTitle': widget.title,
        'description': widget.description,
        'completed': true,
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      showMessage(
        context,
        'Wonderful! You have completed ${widget.title}.',
      );
    } catch (error) {
      if (!mounted) return;

      showMessage(
        context,
        'Could not save your progress. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingProgress = false;
        });
      }
    }
  }

  // Estimates the current spoken word using audio position.
  // Exact synchronization requires word-level audio timestamps.
  int _getCurrentWordIndex(
    Duration position,
    Duration duration,
  ) {
    if (!_hasStartedPlayback ||
        duration.inMilliseconds <= 0 ||
        _prayerWords.isEmpty) {
      return -1;
    }

    final progress = position.inMilliseconds /
        duration.inMilliseconds;

    return (progress * _prayerWords.length)
        .floor()
        .clamp(0, _prayerWords.length - 1);
  }

  Widget _buildHighlightedPrayer(String content) {
    if (content.trim().isEmpty) {
      return const Text(
        'The administrator has not added the prayer text yet.',
        style: TextStyle(
          color: ink,
          height: 1.8,
          fontSize: 15,
        ),
      );
    }

    if (_prayerWords.isEmpty) {
      return Text(
        content,
        style: const TextStyle(
          color: ink,
          height: 1.8,
          fontSize: 15,
        ),
      );
    }

    return StreamBuilder<Duration>(
      stream: _player.positionStream,
      initialData: Duration.zero,
      builder: (context, positionSnapshot) {
        final position =
            positionSnapshot.data ?? Duration.zero;

        return StreamBuilder<Duration?>(
          stream: _player.durationStream,
          builder: (context, durationSnapshot) {
            final duration =
                durationSnapshot.data ?? Duration.zero;

            final currentWordIndex = _getCurrentWordIndex(
              position,
              duration,
            );

            if (currentWordIndex >= 0 &&
                currentWordIndex != _lastAutoScrolledWord) {
              _lastAutoScrolledWord = currentWordIndex;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;

                final wordContext =
                    _wordKeys[currentWordIndex].currentContext;

                if (wordContext != null) {
                  Scrollable.ensureVisible(
                    wordContext,
                    alignment: 0.45,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                  );
                }
              });
            }

            return Wrap(
              spacing: 4,
              runSpacing: 10,
              children: List.generate(
                _prayerWords.length,
                (index) {
                  final isHighlighted =
                      index == currentWordIndex;

                  return Container(
                    key: _wordKeys[index],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isHighlighted
                          ? purple.withValues(alpha: 0.20)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(5),
                      border: isHighlighted
                          ? Border.all(
                              color: purple.withValues(alpha: 0.65),
                              width: 1,
                            )
                          : null,
                    ),
                    child: Text(
                      _prayerWords[index],
                      style: TextStyle(
                        color: isHighlighted ? deepPurple : ink,
                        height: 1.8,
                        fontSize: 15,
                        fontWeight: isHighlighted
                            ? FontWeight.w900
                            : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAudioPlayer() {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.headphones_rounded,
                color: purple,
                size: 23,
              ),
              SizedBox(width: 9),
              Text(
                'Listen to this prayer',
                style: TextStyle(
                  color: ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              StreamBuilder<PlayerState>(
                stream: _player.playerStateStream,
                builder: (context, snapshot) {
                  final isPlaying =
                      snapshot.data?.playing ?? false;

                  return IconButton.filled(
                    onPressed: _loadingAudio
                        ? null
                        : _prepareAndPlayAudio,
                    icon: _loadingAudio
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                          ),
                    style: IconButton.styleFrom(
                      backgroundColor: purple,
                      foregroundColor: Colors.white,
                    ),
                  );
                },
              ),

              const SizedBox(width: 10),

              Expanded(
                child: StreamBuilder<Duration>(
                  stream: _player.positionStream,
                  builder: (context, positionSnapshot) {
                    final position =
                        positionSnapshot.data ?? Duration.zero;

                    return StreamBuilder<Duration?>(
                      stream: _player.durationStream,
                      builder: (context, durationSnapshot) {
                        final duration =
                            durationSnapshot.data ?? Duration.zero;

                        final maxMs = duration.inMilliseconds;
                        final positionMs = position.inMilliseconds;

                        final sliderValue = maxMs > 0
                            ? positionMs.clamp(0, maxMs).toDouble()
                            : 0.0;

                        return Column(
                          children: [
                            Slider(
                              value: sliderValue,
                              max: maxMs > 0
                                  ? maxMs.toDouble()
                                  : 1.0,
                              onChanged:
                                  _audioReady && maxMs > 0
                                      ? (value) {
                                          _player.seek(
                                            Duration(
                                              milliseconds:
                                                  value.round(),
                                            ),
                                          );
                                        }
                                      : null,
                            ),

                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(position),
                                  style: const TextStyle(
                                    color: muted,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  _formatDuration(duration),
                                  style: const TextStyle(
                                    color: muted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          StreamBuilder<PlayerState>(
            stream: _player.playerStateStream,
            builder: (context, snapshot) {
              final state = snapshot.data;

              if (state?.processingState ==
                  ProcessingState.buffering) {
                return const LinearProgressIndicator(
                  color: purple,
                );
              }

              if (state?.processingState ==
                  ProcessingState.completed) {
                return TextButton.icon(
                  onPressed: () async {
                    await _player.seek(Duration.zero);

                    _hasStartedPlayback = true;
                    _lastAutoScrolledWord = -1;

                    await _player.play();
                  },
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Play again'),
                );
              }

              return const SizedBox.shrink();
            },
          ),

          if (_audioError != null) ...[
            const SizedBox(height: 8),
            Text(
              _audioError!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
            TextButton.icon(
              onPressed: _prepareAndPlayAudio,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressButton() {
    final reference = _progressReference;

    if (reference == null) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _markAsLearned,
          icon: const Icon(Icons.check_circle_outline_rounded),
          label: const Text('Mark as learned'),
          style: FilledButton.styleFrom(
            backgroundColor: purple,
            padding: const EdgeInsets.all(16),
          ),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: reference.snapshots(),
      builder: (context, snapshot) {
        final learned =
            snapshot.data?.data()?['completed'] == true;

        if (learned) {
          return SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: null,
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text('Prayer learned'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE7F5EC),
                foregroundColor: const Color(0xFF27834B),
                disabledBackgroundColor:
                    const Color(0xFFE7F5EC),
                disabledForegroundColor:
                    const Color(0xFF27834B),
                padding: const EdgeInsets.all(16),
              ),
            ),
          );
        }

        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _savingProgress
                ? null
                : _markAsLearned,
            icon: _savingProgress
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.check_circle_outline_rounded,
                  ),
            label: Text(
              _savingProgress
                  ? 'Saving progress...'
                  : 'Mark as learned',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: purple,
              padding: const EdgeInsets.all(16),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.prayerText.trim();
    final hasAudio = widget.audioPath.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        title: const Text('Prayer lesson'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _prayerScrollController,
                padding: const EdgeInsets.fromLTRB(
                  24,
                  16,
                  24,
                  24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: IconTile(
                        icon: Icons.auto_stories_rounded,
                        size: 90,
                      ),
                    ),

                    const SizedBox(height: 28),

                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: ink,
                      ),
                    ),

                    const SizedBox(height: 9),

                    Text(
                      widget.description,
                      style: const TextStyle(color: muted),
                    ),

                    if (hasAudio) ...[
                      const SizedBox(height: 24),
                      _buildAudioPlayer(),
                    ],

                    const SizedBox(height: 24),

                    const Text(
                      'Prayer',
                      style: TextStyle(
                        color: ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 12),

                    SoftCard(
                      child: SizedBox(
                        width: double.infinity,
                        child: _buildHighlightedPrayer(content),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                24,
                8,
                24,
                16,
              ),
              child: _buildProgressButton(),
            ),
          ],
        ),
      ),
    );
  }
}
