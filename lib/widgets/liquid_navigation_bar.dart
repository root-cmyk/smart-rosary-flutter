
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RosaryDestination {
  final IconData icon;
  final String label;

  const RosaryDestination(this.icon, this.label);
}

class LiquidNavigationBar extends StatelessWidget {
  final int currentIndex;
  final List<RosaryDestination> destinations;
  final ValueChanged<int> onChanged;

  const LiquidNavigationBar({
    super.key,
    required this.currentIndex,
    required this.destinations,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final segmentWidth =
                constraints.maxWidth / destinations.length;

            return ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  height: 76,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.95),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: deepPurple.withValues(alpha: 0.12),
                        blurRadius: 28,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutBack,
                        left: currentIndex * segmentWidth + 5,
                        top: 5,
                        bottom: 5,
                        width: segmentWidth - 10,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF9878F2),
                                purple,
                                deepPurple,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: purple.withValues(alpha: 0.27),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: List.generate(destinations.length, (index) {
                          final destination = destinations[index];
                          final selected = currentIndex == index;

                          return Expanded(
                            child: Semantics(
                              button: true,
                              selected: selected,
                              label: destination.label,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(25),
                                onTap: () => onChanged(index),
                                child: AnimatedScale(
                                  scale: selected ? 1.04 : 1.0,
                                  duration:
                                      const Duration(milliseconds: 220),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        destination.icon,
                                        size: selected ? 24 : 23,
                                        color: selected
                                            ? Colors.white
                                            : muted,
                                      ),
                                      const SizedBox(height: 3),
                                      AnimatedDefaultTextStyle(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        style: TextStyle(
                                          fontSize: selected ? 11 : 10,
                                          fontWeight: selected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: selected
                                              ? Colors.white
                                              : muted,
                                        ),
                                        child: Text(destination.label),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}