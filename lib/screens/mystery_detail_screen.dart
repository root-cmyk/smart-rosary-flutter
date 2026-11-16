
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/icon_tile.dart';
import '../widgets/soft_card.dart';

class _RosaryStep {
  final String title;
  final String instruction;
  final String prayer;

  const _RosaryStep({
    required this.title,
    required this.instruction,
    this.prayer = '',
  });
}

class MysteryDetailScreen extends StatefulWidget {
  final String title;
  final String schedule;

  const MysteryDetailScreen({
    super.key,
    required this.title,
    required this.schedule,
  });

  @override
  State<MysteryDetailScreen> createState() =>
      _MysteryDetailScreenState();
}

class _MysteryDetailScreenState extends State<MysteryDetailScreen> {
  late final List<_RosaryStep> steps;
  late final String sessionId;

  int currentStep = 0;
  final Set<int> completedSteps = {};

  bool saving = false;
  bool rosaryCompleted = false;
  bool saveError = false;

  @override
  void initState() {
    super.initState();

    sessionId =
        'rosary_${DateTime.now().millisecondsSinceEpoch}';

    steps = _buildSteps();
  }

  static const signOfCross =
      'In the name of the Father, and of the Son, and of the Holy Spirit. Amen.';

  static const apostlesCreed =
      'I believe in God, the Father almighty, Creator of heaven and earth, '
      'and in Jesus Christ, His only Son, our Lord, who was conceived by '
      'the Holy Spirit, born of the Virgin Mary, suffered under Pontius '
      'Pilate, was crucified, died and was buried; He descended into hell; '
      'on the third day He rose again from the dead; He ascended into heaven, '
      'and is seated at the right hand of God the Father almighty; from there '
      'He will come to judge the living and the dead. I believe in the Holy '
      'Spirit, the holy Catholic Church, the communion of saints, the '
      'forgiveness of sins, the resurrection of the body, and life everlasting. Amen.';

  static const ourFather =
      'Our Father, who art in heaven, hallowed be thy name; thy kingdom come; '
      'thy will be done on earth as it is in heaven. Give us this day our daily '
      'bread, and forgive us our trespasses, as we forgive those who trespass '
      'against us; and lead us not into temptation, but deliver us from evil. Amen.';

  static const hailMary =
      'Hail Mary, full of grace, the Lord is with thee. Blessed art thou among '
      'women, and blessed is the fruit of thy womb, Jesus. Holy Mary, Mother '
      'of God, pray for us sinners, now and at the hour of our death. Amen.';

  static const gloryBe =
      'Glory be to the Father, and to the Son, and to the Holy Spirit, as it '
      'was in the beginning, is now, and ever shall be, world without end. Amen.';

  static const fatimaPrayer =
      'O my Jesus, forgive us our sins, save us from the fires of hell, lead '
      'all souls to Heaven, especially those in most need of Thy mercy. Amen.';

  static const hailHolyQueen =
      'Hail, Holy Queen, Mother of mercy, our life, our sweetness and our hope. '
      'To thee do we cry, poor banished children of Eve. To thee do we send up '
      'our sighs, mourning and weeping in this valley of tears. Turn then, most '
      'gracious advocate, thine eyes of mercy toward us, and after this our '
      'exile, show unto us the blessed fruit of thy womb, Jesus. O clement, '
      'O loving, O sweet Virgin Mary.';

  static const closingPrayer =
      'O God, whose only begotten Son, by His life, death and resurrection, '
      'has purchased for us the rewards of eternal life; grant, we beseech '
      'Thee, that meditating upon these mysteries of the most holy Rosary '
      'of the Blessed Virgin Mary, we may imitate what they contain and '
      'obtain what they promise, through the same Christ our Lord. Amen.';

  List<String> _mysteryNames() {
    if (widget.title == 'Joyful Mysteries') {
      return [
        'The Annunciation',
        'The Visitation',
        'The Nativity of Jesus',
        'The Presentation of Jesus',
        'The Finding of Jesus in the Temple',
      ];
    }

    if (widget.title == 'Sorrowful Mysteries') {
      return [
        'The Agony in the Garden',
        'The Scourging at the Pillar',
        'The Crowning with Thorns',
        'The Carrying of the Cross',
        'The Crucifixion of Jesus',
      ];
    }

    if (widget.title == 'Glorious Mysteries') {
      return [
        'The Resurrection of Jesus',
        'The Ascension of Jesus',
        'The Descent of the Holy Spirit',
        'The Assumption of Mary',
        'The Coronation of Mary',
      ];
    }

    return [
      'The Baptism of Jesus',
      'The Wedding at Cana',
      'The Proclamation of the Kingdom of God',
      'The Transfiguration',
      'The Institution of the Eucharist',
    ];
  }

  List<_RosaryStep> _buildSteps() {
    final result = <_RosaryStep>[
      const _RosaryStep(
        title: 'Sign of the Cross',
        instruction: 'Begin your Rosary by making the Sign of the Cross.',
        prayer: signOfCross,
      ),
      const _RosaryStep(
        title: 'Apostles’ Creed',
        instruction: 'Pray the Apostles’ Creed while holding the crucifix.',
        prayer: apostlesCreed,
      ),
      const _RosaryStep(
        title: 'Our Father',
        instruction: 'Pray the Our Father.',
        prayer: ourFather,
      ),
      const _RosaryStep(
        title: 'Three Hail Marys',
        instruction:
            'Pray three Hail Marys for an increase in faith, hope and charity.',
        prayer: hailMary,
      ),
      const _RosaryStep(
        title: 'Glory Be',
        instruction: 'Give glory to the Holy Trinity.',
        prayer: gloryBe,
      ),
    ];

    final mysteries = _mysteryNames();

    for (int i = 0; i < mysteries.length; i++) {
      result.add(
        _RosaryStep(
          title: 'Decade ${i + 1}: ${mysteries[i]}',
          instruction:
              'Take a moment to meditate on this mystery. '
              'Reflect on the life of Jesus and Mary.',
        ),
      );

      result.add(
        const _RosaryStep(
          title: 'Our Father',
          instruction: 'Pray one Our Father to begin this decade.',
          prayer: ourFather,
        ),
      );

      result.add(
        const _RosaryStep(
          title: 'Ten Hail Marys',
          instruction:
              'Pray ten Hail Marys while meditating on this mystery. '
              'You can count each prayer using your Rosary beads.',
          prayer: hailMary,
        ),
      );

      result.add(
        const _RosaryStep(
          title: 'Glory Be',
          instruction: 'Pray the Glory Be.',
          prayer: gloryBe,
        ),
      );

      result.add(
        const _RosaryStep(
          title: 'Fatima Prayer',
          instruction: 'Pray the Fatima Prayer.',
          prayer: fatimaPrayer,
        ),
      );
    }

    result.addAll([
      const _RosaryStep(
        title: 'Hail Holy Queen',
        instruction: 'Conclude the five decades with the Hail Holy Queen.',
        prayer: hailHolyQueen,
      ),
      const _RosaryStep(
        title: 'Closing Prayer',
        instruction: 'Offer this closing prayer.',
        prayer: closingPrayer,
      ),
      const _RosaryStep(
        title: 'Sign of the Cross',
        instruction: 'Finish by making the Sign of the Cross.',
        prayer: signOfCross,
      ),
    ]);

    return result;
  }

  Future<void> _saveProgress({bool completed = false}) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() => saveError = true);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sign in to save your Rosary progress.',
            ),
          ),
        );
      }
      return;
    }

    setState(() {
      saving = true;
      saveError = false;
    });

    try {
      final reference = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('rosaryProgress')
          .doc(sessionId);

      await reference.set({
        'sessionId': sessionId,
        'mysteryTitle': widget.title,
        'schedule': widget.schedule,
        'completedSteps': completedSteps.toList()..sort(),
        'totalSteps': steps.length,
        'currentStep': currentStep,
        'completed': completed,
        'startedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (completed)
          'completedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted && completed) {
        setState(() => rosaryCompleted = true);
      }
    } catch (error) {
      if (mounted) {
        setState(() => saveError = true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to save progress: $error'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Future<void> _completeCurrentStep() async {
    if (completedSteps.contains(currentStep)) return;

    setState(() {
      completedSteps.add(currentStep);
    });

    await _saveProgress();

    if (!mounted) return;

    if (currentStep < steps.length - 1) {
      setState(() {
        currentStep++;
      });

      await _saveProgress();
    } else {
      await _saveProgress(completed: true);

      if (!mounted) return;

      if (rosaryCompleted) {
        _showCompletionDialog();
      }
    }
  }

  void _previousStep() {
    if (currentStep == 0) return;

    setState(() {
      currentStep--;
    });
  }

  Future<void> _nextStep() async {
    if (currentStep >= steps.length - 1) return;

    if (!completedSteps.contains(currentStep)) {
      await _completeCurrentStep();
    } else {
      setState(() {
        currentStep++;
      });

      await _saveProgress();
    }
  }

  void _showCompletionDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.celebration_rounded,
            color: purple,
            size: 48,
          ),
          title: const Text('Rosary completed!'),
          content: const Text(
            'Congratulations! You have completed all five decades '
            'and the closing prayers. May God bless you.',
            textAlign: TextAlign.center,
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: purple,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Finish'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final step = steps[currentStep];
    final progress = completedSteps.length / steps.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guided Rosary'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IconTile(
                icon: Icons.favorite_rounded,
                size: 65,
              ),

              const SizedBox(height: 18),

              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  color: ink,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                widget.schedule,
                style: const TextStyle(color: muted),
              ),

              const SizedBox(height: 22),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your Rosary journey',
                    style: TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${completedSteps.length}/${steps.length} steps',
                    style: const TextStyle(
                      color: purple,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 9),

              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 9,
                  backgroundColor: lavender,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(purple),
                ),
              ),

              const SizedBox(height: 22),

              Expanded(
                child: SingleChildScrollView(
                  child: SoftCard(
                    padding: const EdgeInsets.all(21),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STEP ${currentStep + 1} OF ${steps.length}',
                          style: const TextStyle(
                            color: purple,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),

                        const SizedBox(height: 13),

                        Text(
                          step.title,
                          style: const TextStyle(
                            color: ink,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          step.instruction,
                          style: const TextStyle(
                            color: muted,
                            height: 1.6,
                            fontSize: 13,
                          ),
                        ),

                        if (step.prayer.isNotEmpty) ...[
                          const SizedBox(height: 22),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(17),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F1FF),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(
                              step.prayer,
                              style: const TextStyle(
                                color: ink,
                                fontSize: 14,
                                height: 1.8,
                              ),
                            ),
                          ),
                        ],

                        if (step.title.startsWith('Decade')) ...[
                          const SizedBox(height: 20),
                          const Row(
                            children: [
                              Icon(
                                Icons.self_improvement_rounded,
                                color: purple,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Take your time to meditate before continuing.',
                                  style: TextStyle(
                                    color: purple,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],

                        if (completedSteps.contains(currentStep)) ...[
                          const SizedBox(height: 20),
                          const Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: Colors.green,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Step completed',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              if (saveError)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Your progress may not have been saved. '
                    'Check your connection and sign-in.',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 11,
                    ),
                  ),
                ),

              if (saving)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: LinearProgressIndicator(
                    color: purple,
                    backgroundColor: lavender,
                  ),
                ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: currentStep == 0 || saving
                          ? null
                          : _previousStep,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(15),
                      ),
                      child: const Text('Previous'),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: saving || rosaryCompleted
                          ? null
                          : completedSteps.contains(currentStep)
                              ? _nextStep
                              : _completeCurrentStep,
                      icon: Icon(
                        currentStep == steps.length - 1
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                      ),
                      label: Text(
                        currentStep == steps.length - 1
                            ? 'Finish Rosary'
                            : completedSteps.contains(currentStep)
                                ? 'Next step'
                                : 'Complete step',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: purple,
                        padding: const EdgeInsets.all(15),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
