import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/theme/app_colors.dart';
import '../../providers/progress_provider.dart';
import '../widgets/common_widgets.dart';

class TutorialOverlay extends StatefulWidget {
  const TutorialOverlay({super.key});

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  static const steps = [
    (
      'Sort Challenge!',
      'Cabinets hold goods in DEPTH — front items hide what\'s behind them.'
    ),
    (
      'Move to empty slots',
      'Tap a front good, then tap an EMPTY slot. You can\'t drop onto a filled slot.'
    ),
    (
      'Match 3 fronts',
      'When one shelf shows 3 identical fronts, they clear and hidden goods slide forward!'
    ),
    (
      'Don\'t lock the board',
      'If every slot is filled you lose. Keep empty shelves as working space.'
    ),
    (
      'Beat the clock',
      'Clear every layer before time runs out. Freeze / Refresh / Hammer help.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => _TutorialStepCubit(),
      child: BlocBuilder<_TutorialStepCubit, int>(
        builder: (context, step) {
          final current = steps[step];
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MiaAvatar(size: 72, mood: 'thinking'),
                  const SizedBox(height: 12),
                  Text(
                    'Step ${step + 1} / 5',
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    current.$1,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ).animate().fadeIn(),
                  const SizedBox(height: 10),
                  Text(
                    current.$2,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      if (step > 0)
                        TextButton(
                          onPressed: () =>
                              context.read<_TutorialStepCubit>().back(),
                          child: const Text('Back'),
                        ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () async {
                          if (step < steps.length - 1) {
                            context.read<_TutorialStepCubit>().next(steps.length);
                          } else {
                            await context
                                .read<ProgressProvider>()
                                .markTutorialDone();
                            if (context.mounted) Navigator.pop(context);
                          }
                        },
                        child: Text(
                          step < steps.length - 1 ? 'Next' : 'Start Sorting',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TutorialStepCubit extends Cubit<int> {
  _TutorialStepCubit() : super(0);

  void back() {
    if (state > 0) emit(state - 1);
  }

  void next(int total) {
    if (state < total - 1) emit(state + 1);
  }
}
