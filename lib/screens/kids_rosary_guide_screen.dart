
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/kids_progress_service.dart';

class KidsRosaryGuideScreen extends StatefulWidget {
  final KidsProgressService progressService;

  const KidsRosaryGuideScreen({
    super.key,
    required this.progressService,
  });

  @override
  State<KidsRosaryGuideScreen> createState() =>
      _KidsRosaryGuideScreenState();
}

class _KidsRosaryGuideScreenState
    extends State<KidsRosaryGuideScreen> {
  static const Color _purple = Color(0xFF7654D6);
  static const Color _ink = Color(0xFF34265D);
  static const Color _muted = Color(0xFF81758F);
  static const Color _lavender = Color(0xFFECE3FF);

  // Exact Firestore document IDs.
  static const String _signOfCrossId = 'U50zq31DGmdnXpe7IGTA';
  static const String _apostlesCreedId = 'LMkGez4laPIuIhcTkdEX';
  static const String _ourFatherId = 'pO5WZfDhDXJqYi0RIwxt';
  static const String _hailMaryId = '02IcfSiuBbHeBJkN73gc';
  static const String _gloryBeId = 'rYcXJyau0V3ZgI8Lq22x';
  static const String _fatimaId = 'o94rmb1UUtt8xUnwtHTd';
  static const String _hailHolyQueenId = 'KVjghqjXjmnIiuFD6ZTA';

  // This uploaded recording is titled "O My Jesus".
  static const String _oMyJesusAudioId = '9nkg9gIzKMc8wWh4AEp7';

  late final AudioPlayer _player;
  late List<_RosaryStep> _steps;

  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  List<Map<String, dynamic>> _currentPrayerDocs = [];

  String _selectedMysteryKey = 'joyful';
  int _stepIndex = 0;
  int _repeatIndex = 1;
  int _activeWordIndex = -1;

  bool _requestingAudio = false;
  bool _audioLoaded = false;

  String? _audioError;

  Duration _audioPosition = Duration.zero;
  Duration? _audioDuration;

  _RosaryStep get _step => _steps[_stepIndex];

  @override
  void initState() {
    super.initState();

    _player = AudioPlayer();
    _steps = _buildRosarySteps(_selectedMysteryKey);

    _positionSubscription =
        _player.positionStream.listen(_updateActiveWord);

    _durationSubscription =
        _player.durationStream.listen((duration) {
      if (!mounted) return;
      setState(() => _audioDuration = duration);
    });

    _playerStateSubscription =
        _player.playerStateStream.listen((state) {
      if (!mounted) return;

      if (state.processingState == ProcessingState.completed) {
        final prayer = _matchingPrayer(_currentPrayerDocs);
        final words = _words(_displayText(prayer));

        setState(() {
          _activeWordIndex =
              words.isEmpty ? -1 : words.length - 1;
          _audioLoaded = true;
        });
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  List<_RosaryStep> _buildRosarySteps(String mysteryKey) {
    final steps = <_RosaryStep>[
      _RosaryStep(
        id: 'sign_of_cross',
        title: 'Sign of the Cross',
        emoji: '✝️',
        kind: 'Opening prayer',
        prayerId: _signOfCrossId,
        text: 'In the name of the Father, and of the Son, '
            'and of the Holy Spirit. Amen.',
        lesson: 'Begin by making the Sign of the Cross. '
            'Touch your forehead, your chest, your left shoulder, '
            'and your right shoulder as you pray.',
      ),
      _RosaryStep(
        id: 'apostles_creed',
        title: 'Apostles’ Creed',
        emoji: '📜',
        kind: 'Profession of faith',
        prayerId: _apostlesCreedId,
        text: '',
        lesson: 'The Creed is a short summary of what Catholics '
            'believe. Take your time and listen carefully.',
      ),
      _RosaryStep(
        id: 'our_father_opening',
        title: 'Our Father',
        emoji: '🤍',
        kind: 'Opening prayer',
        prayerId: _ourFatherId,
        text: '',
        lesson: 'Jesus taught this prayer to his disciples. '
            'We pray it with trust in our loving Father.',
      ),
    ];

    for (var i = 1; i <= 3; i++) {
      steps.add(
        _RosaryStep(
          id: 'opening_hail_mary_$i',
          title: 'Hail Mary',
          emoji: '🌹',
          kind: 'Opening prayer · $i of 3',
          prayerId: _hailMaryId,
          text: '',
          lesson: 'Offer this Hail Mary for an increase '
              'in faith, hope, and love.',
        ),
      );
    }

    steps.add(
      _RosaryStep(
        id: 'opening_glory_be',
        title: 'Glory Be',
        emoji: '✨',
        kind: 'Opening prayer',
        prayerId: _gloryBeId,
        text: '',
        lesson: 'Give glory to the Father, the Son, '
            'and the Holy Spirit.',
      ),
    );

    const mysteries = [
      (
        'joyful',
        'Joyful Mysteries',
        '☀️',
        'Monday and Saturday',
        [
          'The Annunciation',
          'The Visitation',
          'The Nativity',
          'The Presentation of Jesus in the Temple',
          'The Finding of Jesus in the Temple',
        ]
      ),
      (
        'sorrowful',
        'Sorrowful Mysteries',
        '💧',
        'Tuesday and Friday',
        [
          'The Agony of Jesus in the Garden',
          'The Scourging at the Pillar',
          'The Crowning with Thorns',
          'The Carrying of the Cross',
          'The Crucifixion',
        ]
      ),
      (
        'glorious',
        'Glorious Mysteries',
        '👑',
        'Wednesday and Sunday',
        [
          'The Resurrection',
          'The Ascension',
          'The Descent of the Holy Spirit',
          'The Assumption of Mary',
          'The Coronation of Mary',
        ]
      ),
      (
        'luminous',
        'Luminous Mysteries',
        '💛',
        'Thursday',
        [
          'The Baptism of Jesus in the Jordan',
          'The Wedding at Cana',
          'The Proclamation of the Kingdom of God',
          'The Transfiguration',
          'The Institution of the Eucharist',
        ]
      ),
    ];

    final mysterySet =
        mysteries.firstWhere((item) => item.$1 == mysteryKey);

    for (var decade = 0; decade < 5; decade++) {
      final mysteryName = mysterySet.$5[decade];
      final prefix = '${mysterySet.$1}_${decade + 1}';

      steps.add(
        _RosaryStep(
          id: '${prefix}_mystery',
          title: 'Mystery ${decade + 1}: $mysteryName',
          emoji: mysterySet.$3,
          kind: '${mysterySet.$2} · ${decade + 1} of 5',
          prayerId: '',
          text: '',
          lesson: 'Pause and think about $mysteryName. '
              'What can this mystery teach you about Jesus and his love?',
          isReflection: true,
        ),
      );

      steps.add(
        _RosaryStep(
          id: '${prefix}_our_father',
          title: 'Our Father',
          emoji: '🤍',
          kind: 'Decade ${decade + 1} · Opening prayer',
          prayerId: _ourFatherId,
          text: '',
          lesson: 'Begin this decade with the Our Father.',
        ),
      );

      steps.add(
        _RosaryStep(
          id: '${prefix}_hail_mary',
          title: 'Hail Mary',
          emoji: '🌹',
          kind: 'Decade ${decade + 1} · 10 prayers',
          prayerId: _hailMaryId,
          text: '',
          lesson: 'Pray each Hail Mary slowly while thinking '
              'about the mystery.',
          repeatCount: 10,
        ),
      );

      steps.add(
        _RosaryStep(
          id: '${prefix}_glory_be',
          title: 'Glory Be',
          emoji: '✨',
          kind: 'Decade ${decade + 1} · Closing prayer',
          prayerId: _gloryBeId,
          text: '',
          lesson: 'Give thanks to the Holy Trinity.',
        ),
      );

      steps.add(
        _RosaryStep(
          id: '${prefix}_fatima',
          title: 'Fatima Prayer',
          emoji: '🕊️',
          kind: 'Decade ${decade + 1} · Optional traditional prayer',
          prayerId: _fatimaId,
          audioPrayerId: _oMyJesusAudioId,
          text: '',
          lesson: 'This prayer is traditionally said after each decade.',
        ),
      );
    }

    steps.add(
      _RosaryStep(
        id: 'hail_holy_queen',
        title: 'Hail, Holy Queen',
        emoji: '🌹',
        kind: 'Closing prayer',
        prayerId: _hailHolyQueenId,
        text: '',
        lesson: 'We ask Mary to pray for us and lead us closer to Jesus.',
      ),
    );

    steps.add(
      _RosaryStep(
        id: 'closing_sign_of_cross',
        title: 'Sign of the Cross',
        emoji: '✝️',
        kind: 'Finish your Rosary',
        prayerId: _signOfCrossId,
        text: '',
        lesson: 'You have reached the end of this Rosary journey. '
            'Make the Sign of the Cross.',
      ),
    );

    return steps;
  }

  Map<String, dynamic>? _prayerById(
    List<Map<String, dynamic>> prayers,
    String? id,
  ) {
    if (id == null || id.isEmpty) return null;

    for (final prayer in prayers) {
      if (prayer['_id']?.toString() == id) {
        return prayer;
      }
    }

    return null;
  }

  Map<String, dynamic>? _matchingPrayer(
    List<Map<String, dynamic>> prayers,
  ) {
    return _prayerById(prayers, _step.prayerId);
  }

  String _displayText(Map<String, dynamic>? prayer) {
    final stored =
        prayer?['text'] ?? prayer?['content'] ?? prayer?['body'];

    if (stored is String && stored.trim().isNotEmpty) {
      return stored.trim();
    }

    return _step.text;
  }

  List<String> _words(String text) {
    return text
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
  }

  void _updateActiveWord(Duration position) {
    _audioPosition = position;

    final prayer = _matchingPrayer(_currentPrayerDocs);
    final text = _displayText(prayer);
    final words = _words(text);

    if (words.isEmpty) return;

    int index = -1;

    final timings =
        prayer?['wordTimings'] ?? prayer?['word_timestamps'];

    if (timings is List && timings.isNotEmpty) {
      for (var i = 0; i < timings.length && i < words.length; i++) {
        final item = timings[i];

        if (item is! Map) continue;

        final start = item['start'] ??
            item['startSeconds'] ??
            item['start_seconds'];

        final end = item['end'] ??
            item['endSeconds'] ??
            item['end_seconds'];

        if (start is! num) continue;

        final endValue = end is num ? end : start;

        if (position.inMilliseconds >= start * 1000 &&
            position.inMilliseconds <= endValue * 1000) {
          index = i;
          break;
        }
      }
    }

    // Fallback when exact word timestamps are not stored.
    // Words are distributed evenly over the audio duration.
    if (index < 0) {
      final totalMs = _audioDuration?.inMilliseconds ?? 0;

      if (totalMs > 0) {
        index = ((position.inMilliseconds / totalMs) * words.length)
            .floor()
            .clamp(0, words.length - 1)
            .toInt();
      }
    }

    if (mounted && index != _activeWordIndex) {
      setState(() => _activeWordIndex = index);
    }
  }

  Future<void> _playPrayer(
    Map<String, dynamic>? prayer,
  ) async {
    // Most prayers use their own document for audio.
    // Fatima uses the separately uploaded O My Jesus recording.
    final audioPrayer = _step.audioPrayerId == null
        ? prayer
        : _prayerById(
            _currentPrayerDocs,
            _step.audioPrayerId,
          );

    final path = audioPrayer?['audioPath'];

    if (path is! String || path.trim().isEmpty) {
      setState(() {
        _audioError = 'Audio has not been uploaded for this prayer yet.';
      });
      return;
    }

    setState(() {
      _requestingAudio = true;
      _audioError = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('Please sign in again to play prayer audio.');
      }

      final token = await user.getIdToken();

      final response = await Supabase.instance.client.functions.invoke(
        'get-prayer-audio-url',
        headers: {
          'Authorization': 'Bearer ${token ?? ''}',
        },
        body: {
          'path': path,
        },
      );

      final data = response.data;

      final result = data is Map<String, dynamic>
          ? data
          : data is Map
              ? Map<String, dynamic>.from(data)
              : <String, dynamic>{};

      final signedUrl = result['signedUrl'];

      if (signedUrl is! String || signedUrl.isEmpty) {
        throw Exception('The audio service did not return a playback URL.');
      }

      await _player.stop();
      await _player.setUrl(signedUrl);

      _audioPosition = Duration.zero;

      if (mounted) {
        setState(() {
          _activeWordIndex = -1;
          _audioLoaded = true;
        });
      }

      await _player.play();
    } catch (error) {
      if (mounted) {
        setState(() {
          _audioError = error
              .toString()
              .replaceFirst('Exception: ', '');
          _audioLoaded = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _requestingAudio = false);
      }
    }
  }

  Future<void> _togglePlayback(
    Map<String, dynamic>? prayer,
  ) async {
    if (_requestingAudio) return;

    if (_player.playing) {
      await _player.pause();
      return;
    }

    if (_audioLoaded) {
      await _player.play();
      return;
    }

    await _playPrayer(prayer);
  }

  Future<void> _stopAndResetAudio() async {
    await _player.stop();

    _audioPosition = Duration.zero;
    _audioDuration = null;

    if (mounted) {
      setState(() {
        _activeWordIndex = -1;
        _audioLoaded = false;
        _audioError = null;
      });
    }
  }

  Future<void> _goNext() async {
    if (_step.repeatCount > 1 &&
        _repeatIndex < _step.repeatCount) {
      await _stopAndResetAudio();

      if (mounted) {
        setState(() => _repeatIndex++);
      }

      return;
    }

    await _markStepComplete();

    if (_stepIndex < _steps.length - 1) {
      await _stopAndResetAudio();

      if (!mounted) return;

      setState(() {
        _stepIndex++;
        _repeatIndex = 1;
      });
    } else {
      _showFinished();
    }
  }

  Future<void> _goPrevious() async {
    if (_step.repeatCount > 1 && _repeatIndex > 1) {
      await _stopAndResetAudio();

      if (mounted) {
        setState(() => _repeatIndex--);
      }

      return;
    }

    if (_stepIndex == 0) return;

    await _stopAndResetAudio();

    if (!mounted) return;

    setState(() {
      _stepIndex--;
      _repeatIndex =
          _step.repeatCount > 1 ? _step.repeatCount : 1;
    });
  }

  Future<void> _markStepComplete() async {
    if (_step.isReflection) return;

    try {
      await widget.progressService.completePrayer(_step.id);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save this step: $error'),
          ),
        );
      }
    }
  }

  void _showFinished() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rosary journey complete! ⭐'),
        content: const Text(
          'Wonderful work. You have finished this guided Rosary journey.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: const Text('Finish'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_stepIndex + 1) / _steps.length;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFBF4),
        foregroundColor: _ink,
        elevation: 0,
        title: const Text(
          'Guided Rosary',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('prayers')
            .where('published', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          _currentPrayerDocs = snapshot.data?.docs
                  .map((doc) => {
                        ...doc.data(),
                        '_id': doc.id,
                      })
                  .toList() ??
              [];

          final prayer = _matchingPrayer(_currentPrayerDocs);
          final text = _displayText(prayer);
          final words = _words(text);

          final audioPrayer = _step.audioPrayerId == null
              ? prayer
              : _prayerById(
                  _currentPrayerDocs,
                  _step.audioPrayerId,
                );

          final hasAudio =
              (audioPrayer?['audioPath'] ?? '').toString().isNotEmpty;

          return SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'MYSTERY SET',
                              style: TextStyle(
                                color: _muted,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          DropdownButton<String>(
                            value: _selectedMysteryKey,
                            underline: const SizedBox.shrink(),
                            borderRadius: BorderRadius.circular(14),
                            items: const [
                              DropdownMenuItem(
                                value: 'joyful',
                                child: Text('Joyful'),
                              ),
                              DropdownMenuItem(
                                value: 'sorrowful',
                                child: Text('Sorrowful'),
                              ),
                              DropdownMenuItem(
                                value: 'glorious',
                                child: Text('Glorious'),
                              ),
                              DropdownMenuItem(
                                value: 'luminous',
                                child: Text('Luminous'),
                              ),
                            ],
                            onChanged: (value) async {
                              if (value == null) return;

                              await _stopAndResetAudio();

                              if (!mounted) return;

                              setState(() {
                                _selectedMysteryKey = value;
                                _steps = _buildRosarySteps(value);
                                _stepIndex = 0;
                                _repeatIndex = 1;
                              });
                            },
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'STEP ${_stepIndex + 1} OF ${_steps.length}',
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            '${(progress * 100).round()}%',
                            style: const TextStyle(
                              color: _purple,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 9,
                          backgroundColor: _lavender,
                          color: _purple,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF9476F2),
                                Color(0xFF5B3BB5),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Column(
                            children: [
                              Text(
                                _step.emoji,
                                style: const TextStyle(fontSize: 48),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _step.kind.toUpperCase(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFEDE5FF),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _step.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              if (_step.repeatCount > 1) ...[
                                const SizedBox(height: 10),
                                Text(
                                  'Hail Mary $_repeatIndex of ${_step.repeatCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFFEDE7F7),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'LET’S LEARN',
                                style: TextStyle(
                                  color: _purple,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _step.lesson,
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                              if (text.isNotEmpty) ...[
                                const SizedBox(height: 18),
                                const Divider(height: 1),
                                const SizedBox(height: 16),
                                const Text(
                                  'SAY THE PRAYER',
                                  style: TextStyle(
                                    color: _purple,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildHighlightedPrayer(words),
                              ],
                            ],
                          ),
                        ),
                        if (!_step.isReflection) ...[
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _requestingAudio || !hasAudio
                                ? null
                                : () => _togglePlayback(prayer),
                            icon: _requestingAudio
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    _player.playing
                                        ? Icons.pause_rounded
                                        : Icons.volume_up_rounded,
                                  ),
                            label: Text(
                              _requestingAudio
                                  ? 'Preparing audio…'
                                  : !hasAudio
                                      ? 'Audio not available'
                                      : _player.playing
                                          ? 'Pause prayer audio'
                                          : _audioLoaded
                                              ? 'Resume prayer audio'
                                              : 'Listen to prayer',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _purple,
                              side: const BorderSide(color: _lavender),
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(17),
                              ),
                            ),
                          ),
                          if (!hasAudio)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                'You can still read and practise this prayer. '
                                'Audio has not been uploaded for it yet.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _muted,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          if (_audioError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _audioError!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          if (hasAudio && _audioDuration != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Column(
                                children: [
                                  LinearProgressIndicator(
                                    value: _audioDuration!.inMilliseconds > 0
                                        ? (_audioPosition.inMilliseconds /
                                                _audioDuration!.inMilliseconds)
                                            .clamp(0.0, 1.0)
                                        : 0,
                                    backgroundColor: _lavender,
                                    color: _purple,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${_formatDuration(_audioPosition)} / '
                                    '${_formatDuration(_audioDuration!)}',
                                    style: const TextStyle(
                                      color: _muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Color(0xFFEDE7F7)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              _stepIndex == 0 && _repeatIndex == 1
                                  ? null
                                  : _goPrevious,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            foregroundColor: _purple,
                          ),
                          child: const Text('Back'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: _goNext,
                          style: FilledButton.styleFrom(
                            backgroundColor: _purple,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            _step.repeatCount > 1 &&
                                    _repeatIndex < _step.repeatCount
                                ? 'Next Hail Mary'
                                : _stepIndex == _steps.length - 1
                                    ? 'Finish Rosary'
                                    : 'Continue',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildHighlightedPrayer(List<String> words) {
    if (words.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 4,
      runSpacing: 8,
      children: [
        for (var i = 0; i < words.length; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: i == _activeWordIndex
                  ? const Color(0xFFFFE59A)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              words[i],
              style: TextStyle(
                color: _ink,
                fontSize: 17,
                height: 1.6,
                fontWeight: i == _activeWordIndex
                    ? FontWeight.w900
                    : FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

class _RosaryStep {
  final String id;
  final String title;
  final String emoji;
  final String kind;
  final String prayerId;
  final String? audioPrayerId;
  final String text;
  final String lesson;
  final int repeatCount;
  final bool isReflection;

const _RosaryStep({
  required this.id,
  required this.title,
  required this.emoji,
  required this.kind,
  required this.prayerId,
  required this.text,
  required this.lesson,
  this.audioPrayerId,
  this.repeatCount = 1,
  this.isReflection = false,
});
}
