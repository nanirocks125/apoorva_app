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
  DiscountType _discountType = DiscountType.finalPrice;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _quantity = widget.existingItem?.quantity ?? 1;
    _priceController = TextEditingController(
      text: widget.existingItem?.mrp.toStringAsFixed(0) ?? '',
    );
    _discountType =
        widget.existingItem?.discountType ?? DiscountType.finalPrice;

    String initialValue = '0';
    if (widget.existingItem != null) {
      if (_discountType == DiscountType.percentage) {
        initialValue = widget.existingItem!.discountPercent.toStringAsFixed(0);
      } else {
        final mrp = widget.existingItem!.mrp;
        final discountAmt = mrp * (widget.existingItem!.discountPercent / 100);
        initialValue = _discountType == DiscountType.amount
            ? discountAmt.toStringAsFixed(0)
            : (mrp - discountAmt).toStringAsFixed(0);
      }
    }
    _dynamicInputController = TextEditingController(text: initialValue);

    _priceController.text = '300';
    _dynamicInputController.text = '250';
    _quantity = 2;
  }

  double get _mrp {
    return (double.tryParse(_priceController.text) ?? 0.0);
  }

  double get _unitPriceDiscount => _mrp - _unitFinalPrice;

  double get _unitFinalPrice {
    final sticker = double.tryParse(_priceController.text) ?? 0.0;
    final val = double.tryParse(_dynamicInputController.text) ?? 0.0;
    if (_discountType == DiscountType.percentage) {
      return sticker * (1 - (val / 100));
    }
    if (_discountType == DiscountType.amount) {
      return (sticker - val).clamp(0, sticker);
    }
    return val.clamp(0, sticker);
  }

  double get _unitDiscountPercentage {
    return (_unitPriceDiscount * 100 / _mrp);
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFFFF5733);
    final softBg = themeColor.withOpacity(0.05);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Minimal Handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              widget.existingItem != null
                  ? 'Edit ${widget.category?.name}'
                  : 'Add ${widget.category?.name}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 24),

            // PRICE & QTY ROW
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildInputField(
                    controller: _priceController,
                    label: "Unit Price",
                    prefix: "₹",
                    isBig: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "  Quantity",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 4,
                        ),
                        decoration: BoxDecoration(
                          color: softBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _qtyBtn(
                              Icons.remove,
                              () => setState(
                                () => _quantity = (_quantity > 1)
                                    ? _quantity - 1
                                    : 1,
                              ),
                            ),
                            Text(
                              "$_quantity",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            _qtyBtn(
                              Icons.add,
                              () => setState(() => _quantity++),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // DISCOUNTS SEGMENT (Fixed Clipping with shorter labels)
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<DiscountType>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: DiscountType.finalPrice,
                    label: Text('Final ₹'),
                  ),
                  ButtonSegment(
                    value: DiscountType.percentage,
                    label: Text('% Off'),
                  ),
                  ButtonSegment(
                    value: DiscountType.amount,
                    label: Text('₹ Discount'),
                  ),
                ],
                selected: {_discountType},
                onSelectionChanged: (set) => setState(() {
                  _discountType = set.first;
                  _dynamicInputController.clear();
                }),
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  selectedBackgroundColor: themeColor,
                  selectedForegroundColor: Colors.white,
                  side: BorderSide(color: Colors.grey.shade200),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_discountType != DiscountType.percentage)
              _buildInputField(
                controller: _dynamicInputController,
                label: _discountType == DiscountType.percentage
                    ? "Discount Percentage"
                    : "Enter Amount",
                prefix: _discountType == DiscountType.percentage ? "" : "₹",
              ),

            // 4. QUICK PERCENT CHIPS (Only for percentage mode)
            if (_discountType == DiscountType.percentage)
              Wrap(
                spacing: 8,
                children: [0.0, 5.0, 10.0, 15.0, 20.0]
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

            // SUMMARY CARD (Modern lightweight look)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: softBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: themeColor.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  _summaryRow(
                    "Gross Total",
                    "₹${(_mrp * _quantity).toStringAsFixed(2)}",
                  ),
                  const SizedBox(height: 10),
                  _summaryRow(
                    "Discount (${_unitDiscountPercentage.toStringAsFixed(0)}%)",
                    "- ₹${(_unitPriceDiscount * _quantity).toStringAsFixed(2)}",
                    isTotal: false,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 10),
                  _summaryRow(
                    "Net Payable",
                    "₹${(_unitFinalPrice * _quantity).toStringAsFixed(2)}",
                    isTotal: true,
                    color: themeColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ACTION BUTTON
            ElevatedButton(
              onPressed: _isValid() ? _saveItem : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(64),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
              ),
              child: Text(
                widget.existingItem != null ? "UPDATE ITEM" : "ADD TO BILL",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    String? prefix,
    bool isBig = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      onChanged: (_) => setState(() {}),
      style: TextStyle(fontSize: isBig ? 22 : 16, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefix != null ? "$prefix " : null,
        filled: true,
        fillColor: Colors.grey.shade50,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.blueGrey,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: Colors.black87),
        ),
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String val, {
    bool isTotal = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? Colors.black87 : Colors.blueGrey,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          val,
          style: TextStyle(
            fontSize: isTotal ? 22 : 16,
            fontWeight: FontWeight.w900,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  bool _isValid() {
    return _mrp > 0 && (widget.category != null || widget.existingItem != null);
  }

  void _saveItem() {
    final item = CartItem(
      category: widget.existingItem?.category ?? widget.category!,
      mrp: _mrp,
      quantity: _quantity,
      discountPercent: _unitDiscountPercentage,
      discountType: _discountType,
    );

    try {
      // 2. IMPORTANT: Use context.read instead of widget.provider
      // This ensures we get the currently active instance of the provider
      final posProvider = widget.provider;

      // Safety check: only call if not disposed
      if (widget.index != null) {
        posProvider.updateItem(item, widget.index!);
      } else {
        posProvider.addItem(item);
      }

      Navigator.pop(context);
    } catch (e) {
      debugPrint("Provider error: $e");
      // If it still fails, the provider was truly killed.
      // Usually popping the navigator is the only safe move here.
      Navigator.pop(context);
    }
  }
}
