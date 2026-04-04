// 🚀 REFACTORED CALCULATOR COMPONENT
import 'package:apoorva_app/model/cart/cart_item.dart';
import 'package:apoorva_app/model/category/category.dart';
import 'package:apoorva_app/screens/pos/pos_provider.dart';
import 'package:flutter/material.dart';

enum DiscountType { percentage, amount }

class ItemPriceCalculator extends StatefulWidget {
  final PosProvider provider;
  final Category? category;
  final CartItem? existingItem;
  final int? index;

  const ItemPriceCalculator({
    super.key,
    required this.provider,
    this.category,
    this.existingItem,
    this.index,
  });

  @override
  State<ItemPriceCalculator> createState() => _ItemPriceCalculatorState();
}

class _ItemPriceCalculatorState extends State<ItemPriceCalculator> {
  late TextEditingController _priceController;
  late TextEditingController _discountInputController;
  DiscountType _discountType = DiscountType.percentage;

  double get _discountValue {
    final double sticker = double.tryParse(_priceController.text) ?? 0.0;
    final double discountVal =
        double.tryParse(_discountInputController.text) ?? 0.0;

    if (_discountType == DiscountType.percentage) {
      return sticker * (discountVal / 100);
    }
    return discountVal; // Amount mode లో అదే డిస్కౌంట్ వాల్యూ
  }

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: widget.existingItem?.mrp.toStringAsFixed(0) ?? '',
    );

    // ఒకవేళ ఎగ్జిస్టింగ్ ఐటమ్ ఉంటే, దాని డిస్కౌంట్ ని పర్సంటేజ్ లోనే ఉంచుదాం ప్రస్తుతానికి
    _discountInputController = TextEditingController(
      text: widget.existingItem?.discountPercent.toStringAsFixed(0) ?? '0',
    );
  }

  double get _finalPrice {
    final double sticker = double.tryParse(_priceController.text) ?? 0.0;
    final double discountVal =
        double.tryParse(_discountInputController.text) ?? 0.0;

    if (_discountType == DiscountType.percentage) {
      return sticker * (1 - (discountVal / 100));
    } else {
      return (sticker - discountVal).clamp(0, sticker); // మైనస్ లోకి వెళ్లకుండా
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFFFF5733);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Text(
                widget.existingItem != null
                    ? 'Edit ${widget.category?.name}'
                    : 'New ${widget.category?.name}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 20),

              // 1. STICKER PRICE FIELD
              TextField(
                controller: _priceController,
                autofocus: true,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Sticker Price',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 20),

              // 2. DISCOUNT TYPE SEGMENTED BUTTON (iOS Style Feel)
              SegmentedButton<DiscountType>(
                segments: const [
                  ButtonSegment(
                    value: DiscountType.percentage,
                    label: Text('Percentage (%)'),
                    icon: Icon(Icons.percent),
                  ),
                  ButtonSegment(
                    value: DiscountType.amount,
                    label: Text('Amount (₹)'),
                    icon: Icon(Icons.currency_rupee),
                  ),
                ],
                selected: {_discountType},
                onSelectionChanged: (Set<DiscountType> newSelection) {
                  setState(() {
                    _discountType = newSelection.first;
                    _discountInputController
                        .clear(); // Switch అయినప్పుడు క్లియర్ చేయడం ఉత్తమం
                  });
                },
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: themeColor.withOpacity(0.1),
                  selectedForegroundColor: themeColor,
                  side: BorderSide(color: themeColor.withOpacity(0.5)),
                ),
              ),

              if (_discountType == .amount) const SizedBox(height: 10),
              // 3. DYNAMIC DISCOUNT INPUT
              if (_discountType == .amount)
                TextField(
                  controller: _discountInputController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Discount Amount (₹)',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => FocusScope.of(context).unfocus(),
                ),

              const SizedBox(height: 10),

              // 4. QUICK PERCENT CHIPS (Show only in percentage mode)
              if (_discountType == DiscountType.percentage)
                Wrap(
                  spacing: 8,
                  children: [0.0, 5.0, 10.0, 20.0]
                      .map(
                        (pct) => ChoiceChip(
                          label: Text('${pct.toInt()}%'),
                          selected:
                              (double.tryParse(_discountInputController.text) ??
                                  -1) ==
                              pct,
                          onSelected: (selected) {
                            setState(
                              () => _discountInputController.text = pct
                                  .toInt()
                                  .toString(),
                            );
                          },
                        ),
                      )
                      .toList(),
                ),

              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    // 1. ACTUAL PRICE (STRIKE THROUGH)
                    _buildPriceRow(
                      "Gross Amount:",
                      "₹${(double.tryParse(_priceController.text) ?? 0).toStringAsFixed(2)}",
                      isBold: false,
                    ),
                    const SizedBox(height: 8),

                    // 2. DISCOUNT AMOUNT
                    _buildPriceRow(
                      "Discount (${_discountType == DiscountType.percentage ? '${_discountInputController.text}%' : 'Fixed'}):",
                      "- ₹${_discountValue.toStringAsFixed(2)}",
                      color: Colors.redAccent,
                      isBold: false,
                    ),

                    const Divider(height: 24),

                    // 3. FINAL NET PRICE
                    _buildPriceRow(
                      "Net Amount:",
                      "₹${_finalPrice.toStringAsFixed(2)}",
                      color: themeColor,
                      isBold: true,
                      fontSize: 22,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(60),
                  backgroundColor: themeColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: _isValid
                    ? () {
                        // ... addItem logic ...
                        // Note: final discount needs to be converted back to percentage if your model only stores %
                        double finalDiscountPercent =
                            _discountType == DiscountType.percentage
                            ? (double.tryParse(_discountInputController.text) ??
                                  0.0)
                            : ((double.tryParse(
                                        _discountInputController.text,
                                      ) ??
                                      0.0) /
                                  (double.tryParse(_priceController.text) ??
                                      1.0) *
                                  100);

                        final newItem = CartItem(
                          category: widget.category!,
                          mrp: double.tryParse(_priceController.text) ?? 0.0,
                          discountPercent: finalDiscountPercent,
                        );

                        if (widget.index != null) {
                          widget.provider.updateItem(newItem, widget.index!);
                        } else {
                          widget.provider.addItem(newItem);
                        }
                        Navigator.pop(context);
                      }
                    : null,
                child: Text(
                  widget.existingItem != null ? 'UPDATE ITEM' : 'ADD TO BILL',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    String value, {
    Color? color,
    bool isBold = false,
    double fontSize = 14,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.blueGrey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  bool get _isValid {
    final double sticker = double.tryParse(_priceController.text) ?? 0.0;
    final double discountVal =
        double.tryParse(_discountInputController.text) ?? 0.0;

    // 1. Price must be greater than 0
    if (sticker <= 0) return false;

    // 2. Category must not be null
    if (widget.category == null && widget.existingItem == null) return false;

    // 3. Discount logic
    if (_discountType == DiscountType.percentage) {
      // Percentage shouldn't exceed 100% (unless your business logic allows it)
      if (discountVal < 0 || discountVal > 100) return false;
    } else {
      // Amount discount shouldn't exceed the sticker price
      if (discountVal < 0 || discountVal > sticker) return false;
    }

    return true;
  }
}
