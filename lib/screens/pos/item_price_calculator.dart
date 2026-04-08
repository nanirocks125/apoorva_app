// 🚀 REFACTORED CALCULATOR COMPONENT
import 'package:apoorva_app/enum/discount_type.dart' show DiscountType;
import 'package:apoorva_app/model/cart/cart_item.dart';
import 'package:apoorva_app/model/category/category.dart';
import 'package:apoorva_app/screens/pos/pos_provider.dart';
import 'package:flutter/material.dart';

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
  late TextEditingController _dynamicInputController;
  DiscountType _discountType = DiscountType.percentage;

  // Calculate the Discount Amount in ₹
  double get _discountValue {
    final double sticker = double.tryParse(_priceController.text) ?? 0.0;
    final double inputVal =
        double.tryParse(_dynamicInputController.text) ?? 0.0;

    switch (_discountType) {
      case DiscountType.percentage:
        return sticker * (inputVal / 100);
      case DiscountType.amount:
        return inputVal;
      case DiscountType.finalPrice:
        return (sticker - inputVal).clamp(
          0,
          sticker,
        ); // Reverse calculate discount
    }
  }

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: widget.existingItem?.mrp.toStringAsFixed(0) ?? '',
    );

    // If there's an existing item, determine the initial type and value
    _discountType =
        widget.existingItem?.discountType ?? DiscountType.percentage;

    String initialValue = '0';
    if (widget.existingItem != null) {
      if (_discountType == DiscountType.percentage) {
        initialValue = widget.existingItem!.discountPercent.toStringAsFixed(0);
      } else {
        // Calculate the raw discount amount or final price based on saved percentage
        final mrp = widget.existingItem!.mrp;
        final discountAmt = mrp * (widget.existingItem!.discountPercent / 100);
        if (_discountType == DiscountType.amount) {
          initialValue = discountAmt.toStringAsFixed(0);
        } else if (_discountType == DiscountType.finalPrice) {
          initialValue = (mrp - discountAmt).toStringAsFixed(0);
        }
      }
    }

    _dynamicInputController = TextEditingController(text: initialValue);
  }

  // Calculate the Final Net Price in ₹
  double get _finalPrice {
    final double sticker = double.tryParse(_priceController.text) ?? 0.0;
    final double inputVal =
        double.tryParse(_dynamicInputController.text) ?? 0.0;

    switch (_discountType) {
      case DiscountType.percentage:
        return sticker * (1 - (inputVal / 100));
      case DiscountType.amount:
        return (sticker - inputVal).clamp(0, sticker);
      case DiscountType.finalPrice:
        return inputVal.clamp(0, sticker); // Input IS the final price
    }
  }

  // Validation Logic
  bool get _isValid {
    final double sticker = double.tryParse(_priceController.text) ?? 0.0;
    final double inputVal =
        double.tryParse(_dynamicInputController.text) ?? 0.0;

    if (sticker <= 0) return false;
    if (widget.category == null && widget.existingItem == null) return false;

    switch (_discountType) {
      case DiscountType.percentage:
        if (inputVal < 0 || inputVal > 100) return false;
        break;
      case DiscountType.amount:
      case DiscountType.finalPrice:
        if (inputVal < 0 || inputVal > sticker)
          return false; // Cannot exceed sticker price
        break;
    }
    return true;
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

              // 2. DISCOUNT TYPE SEGMENTED BUTTON
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<DiscountType>(
                  segments: const [
                    ButtonSegment(
                      value: DiscountType.percentage,
                      label: Text('Percent (%)'),
                      icon: Icon(Icons.percent),
                    ),
                    ButtonSegment(
                      value: DiscountType.amount,
                      label: Text('Discount (₹)'),
                      icon: Icon(Icons.currency_rupee),
                    ),
                    ButtonSegment(
                      value: DiscountType.finalPrice,
                      label: Text('Final (₹)'),
                      icon: Icon(Icons.check_circle_outline),
                    ),
                  ],
                  selected: {_discountType},
                  onSelectionChanged: (Set<DiscountType> newSelection) {
                    setState(() {
                      _discountType = newSelection.first;
                      _dynamicInputController.clear();
                    });
                  },
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: themeColor.withOpacity(0.1),
                    selectedForegroundColor: themeColor,
                    side: BorderSide(color: themeColor.withOpacity(0.5)),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 3. DYNAMIC INPUT FIELD
              TextField(
                controller: _dynamicInputController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                style: const TextStyle(fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: _discountType == DiscountType.percentage
                      ? 'Discount Percentage (%)'
                      : _discountType == DiscountType.amount
                      ? 'Discount Amount (₹)'
                      : 'Final Net Price (₹)',
                  prefixText: _discountType == DiscountType.percentage
                      ? ''
                      : '₹ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => FocusScope.of(context).unfocus(),
              ),

              const SizedBox(height: 10),

              // 4. QUICK PERCENT CHIPS (Only for percentage mode)
              if (_discountType == DiscountType.percentage)
                Wrap(
                  spacing: 8,
                  children: [0.0, 5.0, 10.0, 20.0]
                      .map(
                        (pct) => ChoiceChip(
                          label: Text('${pct.toInt()}%'),
                          selected:
                              (double.tryParse(_dynamicInputController.text) ??
                                  -1) ==
                              pct,
                          onSelected: (selected) {
                            setState(
                              () => _dynamicInputController.text = pct
                                  .toInt()
                                  .toString(),
                            );
                          },
                        ),
                      )
                      .toList(),
                ),

              const SizedBox(height: 10),

              // 5. SUMMARY BOX
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildPriceRow(
                      "Gross Amount:",
                      "₹${(double.tryParse(_priceController.text) ?? 0).toStringAsFixed(2)}",
                      isBold: false,
                    ),
                    const SizedBox(height: 8),

                    _buildPriceRow(
                      "Discount (${_discountType == DiscountType.percentage ? '${_dynamicInputController.text.isEmpty ? '0' : _dynamicInputController.text}%' : 'Derived'}):",
                      "- ₹${_discountValue.toStringAsFixed(2)}",
                      color: Colors.redAccent,
                      isBold: false,
                    ),

                    const Divider(height: 24),

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

              // 6. SAVE BUTTON
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
                        final double sticker =
                            double.tryParse(_priceController.text) ?? 1.0;
                        final double safeSticker = sticker == 0 ? 1.0 : sticker;

                        // Calculate final percentage regardless of which mode was used
                        // (So your backend/cart can universally store the correct %)
                        double finalDiscountPercent;
                        if (_discountType == DiscountType.percentage) {
                          finalDiscountPercent =
                              double.tryParse(_dynamicInputController.text) ??
                              0.0;
                        } else {
                          finalDiscountPercent =
                              (_discountValue / safeSticker) * 100;
                        }

                        final category =
                            widget.existingItem?.category ?? widget.category;
                        if (category == null) return;

                        final newItem = CartItem(
                          category: category,
                          mrp: double.tryParse(_priceController.text) ?? 0.0,
                          discountPercent: finalDiscountPercent,
                          discountType: _discountType,
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
}
