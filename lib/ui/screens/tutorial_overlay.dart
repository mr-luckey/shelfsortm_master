import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../providers/progress_provider.dart';
import '../widgets/common_widgets.dart';

class TutorialOverlay extends StatefulWidget {
  const TutorialOverlay({super.key});

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  int step = 0;

  static const steps = [
    (
      'Sort Challenge!',
      'Shelves are filled with mixed goods. Your job: group 3 identical items.'
    ),
    (
      'Move goods',
      'Tap a good, then tap an empty slot — or drag it. Use BUFFER shelves as space.'
    ),
    (
      'Match 3 to clear',
      'When one shelf holds 3 identical goods, they clear automatically!'
    ),
    (
      'Beat the clock',
      'Clear every good before time runs out. Freeze / Refresh help when stuck.'
    ),
    (
      'Think ahead',
      'Empty buffer shelves are your working space — never fill them randomly.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final current = steps[step];
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ).animate().fadeIn(),
            const SizedBox(height: 10),
            Text(
              current.$2,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, height: 1.4),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                if (step > 0)
                  TextButton(
                    onPressed: () => setState(() => step--),
                    child: const Text('Back'),
                  ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () async {
                    if (step < steps.length - 1) {
                      setState(() => step++);
                    } else {
                      await context.read<ProgressProvider>().markTutorialDone();
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
  }
}
