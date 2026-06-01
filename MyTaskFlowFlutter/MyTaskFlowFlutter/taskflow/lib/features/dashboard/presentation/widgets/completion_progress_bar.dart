import 'package:flutter/material.dart';

class CompletionProgressBar extends StatelessWidget {
  const CompletionProgressBar({super.key, required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final pct = (value.clamp(0.0, 1.0) * 100).toStringAsFixed(0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 600),
          builder: (context, v, _) => LinearProgressIndicator(
            key: const Key('completionProgressIndicator'),
            value: v,
            minHeight: 12,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$pct% completado',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
