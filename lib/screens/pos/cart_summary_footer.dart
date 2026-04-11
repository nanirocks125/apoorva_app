import 'package:apoorva_app/screens/checkout/checkout_screen.dart';
import 'package:apoorva_app/screens/pos/pos_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../model/customer/customer.dart';

class CartSummaryFooter extends StatelessWidget {
  const CartSummaryFooter({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Provider నుండి కేవలం అవసరమైన డేటాని మాత్రమే 'watch' చేస్తున్నాం
    final provider = context.watch<PosProvider>();
    final cart = provider.cart;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // LEFT: ITEM COUNT & TOTAL PRICE
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${cart.totalItemsCount} ITEMS',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '₹${cart.totalPayable.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2D3436),
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),

          // RIGHT: CHECKOUT BUTTON
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(
                  0xFF00B894,
                ), // Clean Professional Green
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              // కార్ట్ ఖాళీగా ఉంటే బటన్ డిసేబుల్ అవుతుంది
              onPressed: cart.items.isEmpty
                  ? null
                  : () => _navigateToCheckout(context, provider),
              child: const Text(
                'PROCEED TO CHECKOUT',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // NAVIGATION LOGIC
  void _navigateToCheckout(BuildContext context, PosProvider provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          cart: provider.cart,
          orgId: provider.orgId,
          customer: Customer(
            name: provider.nameController.text,
            phone: provider.phoneController.text,
            lastPurchaseDate: DateTime.now(),
          ),
          activeDraftId: provider.activeDraftId,
        ),
      ),
    ).then((sold) {
      // ఒకవేళ సేల్ సక్సెస్ అయితే కార్ట్ క్లియర్ చేయాలి
      if (sold == true) {
        provider.clearCart();
      }
    });
  }
}
