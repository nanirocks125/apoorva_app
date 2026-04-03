// --- BOTTOM ACTION BAR ---
import 'package:flutter/material.dart';

class CheckoutBottomAction extends StatelessWidget {
  final double balance;
  final bool isProcessing;
  final bool canConfirm;
  final VoidCallback onConfirm;

  const CheckoutBottomAction({
    super.key,
    required this.balance,
    required this.isProcessing,
    required this.canConfirm,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final color = balance > 0
        ? Colors.red
        : (balance < 0 ? Colors.blue : Colors.green);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  balance > 0 ? 'Due' : 'Settled',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
                Text(
                  '₹${balance.abs().toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
                backgroundColor: canConfirm ? Colors.green : Colors.grey,
              ),
              onPressed: canConfirm && !isProcessing ? onConfirm : null,
              child: isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('CONFIRM SALE'),
            ),
          ],
        ),
      ),
    );
  }
}
