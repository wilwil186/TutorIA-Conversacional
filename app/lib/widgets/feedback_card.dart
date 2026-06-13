import 'package:flutter/material.dart';

import '../models.dart';

/// Feedback shown under a student message: correction cards + a grammar tip.
class FeedbackCard extends StatelessWidget {
  final List<Correction> corrections;
  final String? grammarTip;

  const FeedbackCard({super.key, required this.corrections, this.grammarTip});

  @override
  Widget build(BuildContext context) {
    const amber = Color(0xFFFFF6E5);
    const border = Color(0xFFFFCC66);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 2, bottom: 8, left: 8, right: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: amber,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final c in corrections) _CorrectionRow(correction: c),
          if (grammarTip != null && grammarTip!.isNotEmpty) ...[
            if (corrections.isNotEmpty) const Divider(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡 ', style: TextStyle(fontSize: 15)),
                Expanded(
                  child: Text(
                    grammarTip!,
                    style: const TextStyle(
                        fontSize: 14, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CorrectionRow extends StatelessWidget {
  final Correction correction;
  const _CorrectionRow({required this.correction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                correction.original,
                style: const TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: Colors.redAccent,
                  fontSize: 15,
                ),
              ),
              const Text('  →  ', style: TextStyle(fontSize: 15)),
              Text(
                correction.corrected,
                style: const TextStyle(
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            correction.explanation,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
