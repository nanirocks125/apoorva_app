// --- DISCOUNT SELECTOR ---
import 'package:flutter/material.dart';

class DiscountSelector extends StatelessWidget {
  final double selectedPercent;
  final Function(double) onSelect;
  const DiscountSelector({
    super.key,
    required this.selectedPercent,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [0.0, 5.0, 10.0, 15.0, 20.0].map((pct) {
        return ChoiceChip(
          label: Text('${pct.toInt()}%'),
          selected: selectedPercent == pct,
          onSelected: (val) => val ? onSelect(pct) : null,
        );
      }).toList(),
    );
  }
}
