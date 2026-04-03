// --- BILL SUMMARY CARD ---
import 'package:flutter/material.dart';

class BillSummaryCard extends StatelessWidget {
  final double totalMrp; // Sum of all items' sticker prices
  final double totalDiscountOnMRP;
  final double additionalDiscount; // Discount from the % chips
  final double netTotal;
  final TextEditingController roundOffController;

  const BillSummaryCard({
    super.key,
    required this.totalMrp,
    required this.totalDiscountOnMRP,
    required this.additionalDiscount,
    required this.netTotal,
    required this.roundOffController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // 1. Total MRP
          _summaryRow('Total MRP', '₹${totalMrp.toStringAsFixed(2)}'),

          // 2. Individual Item Discounts
          if (totalDiscountOnMRP > 0)
            _summaryRow(
              'Item Discounts',
              '- ₹${totalDiscountOnMRP.toStringAsFixed(2)}',
              color: Colors.green.shade700,
            ),

          if (additionalDiscount > 0) const Divider(height: 24, thickness: 1),

          if (additionalDiscount > 0)
            // 3. Subtotal (MRP - Item Discounts)
            _summaryRow(
              'Subtotal',
              '₹${(totalMrp - totalDiscountOnMRP).toStringAsFixed(2)}',
              size: 13,
            ),

          // 4. Additional Discount (From Chips)
          if (additionalDiscount > 0)
            _summaryRow(
              'Additional Discount',
              '- ₹${additionalDiscount.toStringAsFixed(2)}',
              color: Colors.green.shade700,
            ),

          const Divider(height: 24, thickness: 1),
          _summaryRow(
            'Bill Amount',
            '₹${(totalMrp - totalDiscountOnMRP - additionalDiscount).toStringAsFixed(2)}',
          ),

          // 5. Round-off Input
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Round-off',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: roundOffController,
                  textAlign: TextAlign.right,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 6. Final Net Total
          _summaryRow(
            'NET TOTAL',
            '₹${netTotal.toStringAsFixed(2)}',
            isBold: true,
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String val, {
    bool isBold = false,
    double size = 14,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: size,
              color: isBold ? null : Colors.grey.shade700,
            ),
          ),
          Text(
            val,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: size,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
