import 'package:apoorva_app/enum/discount_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:apoorva_app/model/cart/cart_item.dart';
import 'package:apoorva_app/model/category/category.dart';
import 'package:apoorva_app/screens/pos/pos_provider.dart';

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

  final Color primaryColor = const Color(0xFFFF5733);

  @override
  void initState() {
    super.initState();
    _discountType =
        widget.existingItem?.discountType ?? DiscountType.percentage;
    _priceController = TextEditingController(
      text: widget.existingItem?.mrp.toString() ?? '',
    );
    // _discountInputController = TextEditingController(
    //   text: (widget.existingItem?.discountPercent ?? 0.0).toString(),
    // );

    double initialValue = 0;
    if (widget.existingItem != null) {
      if (_discountType == DiscountType.percentage) {
        initialValue = widget.existingItem!.discountPercent;
      } else {
        // Convert stored percent back to currency: (percent / 100) * price
        initialValue =
            (widget.existingItem!.discountPercent / 100) *
            widget.existingItem!.mrp;
      }
    }

    _discountInputController = TextEditingController(
      text: initialValue > 0 ? initialValue.toStringAsFixed(2) : '0',
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    _discountInputController.dispose();
    super.dispose();
  }

  double get _stickerPrice => double.tryParse(_priceController.text) ?? 0.0;
  double get _discountInput =>
      double.tryParse(_discountInputController.text) ?? 0.0;

  double get _discountValue {
    if (_discountType == DiscountType.percentage) {
      return _stickerPrice * (_discountInput / 100);
    }
    return _discountInput.clamp(0, _stickerPrice);
  }

  double get _finalNetPrice =>
      (_stickerPrice - _discountValue).clamp(0, double.infinity);

  bool get _isEditing => widget.existingItem != null && widget.index != null;

  @override
  Widget build(BuildContext context) {
    // 🚀 Dynamic Labels based on Mode
    final String buttonText = _isEditing ? "UPDATE ITEM" : "ADD TO BILL";

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeaderIndicator(),

            _buildTitleRow(),

            // // 1. DYNAMIC TITLE
            // Text(
            //   titlePrefix,
            //   style: TextStyle(
            //     fontSize: 15,
            //     fontWeight: FontWeight.w700,
            //     color: Colors.grey.shade600,
            //     letterSpacing: 0.5,
            //   ),
            // ),
            const SizedBox(height: 24),
            _buildCompactHeroPrice(), // 🚀 Modern Underline Style

            const SizedBox(height: 24),
            _buildModernToggle(),

            const SizedBox(height: 20),
            _buildContextualDiscountSection(),

            const SizedBox(height: 24),
            _buildClassySummary(),

            const SizedBox(height: 24),

            // 2. DYNAMIC BUTTON
            _buildPrimaryButton(buttonText),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(String label) {
    bool isValid = _stickerPrice > 0;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      onPressed: isValid ? _handleSubmit : null,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildContextualDiscountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _discountType == DiscountType.percentage
              ? "SELECT PERCENTAGE"
              : "ENTER FIXED DISCOUNT",
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        if (_discountType == DiscountType.percentage)
          // 1. SHOW ONLY CHIPS IN PERCENTAGE MODE
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [0, 5, 10, 15, 20, 25, 30, 40, 50].map((pct) {
                bool isSelected =
                    (double.tryParse(_discountInputController.text) ?? -1) ==
                    pct.toDouble();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      "$pct%",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (val) {
                      HapticFeedback.selectionClick();
                      setState(
                        () => _discountInputController.text = pct.toString(),
                      );
                    },
                    selectedColor: primaryColor,
                    backgroundColor: Colors.grey.shade100,
                    side: BorderSide.none,
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                );
              }).toList(),
            ),
          )
        else
          // 2. SHOW ONLY INPUT IN AMOUNT MODE
          TextField(
            controller: _discountInputController,
            textAlign:
                TextAlign.center, // 🚀 Center it to match the Price field
            keyboardType: TextInputType.number,
            autofocus: true,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w300, // 🚀 Lighter weight = Modern feel
              color: Color(0xFF2D3436),
            ),
            decoration: InputDecoration(
              hintText: "0",
              // 🚀 Using prefixIcon instead of prefixText for better centering control
              prefixIcon: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  "₹",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),

              filled: false, // 🚀 Remove that heavy grey background
              isDense: true,

              // 🚀 Use ultra-light borders
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade100, width: 1),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: primaryColor.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (_) => setState(() {}),
          ),
      ],
    );
  }

  Widget _buildCompactHeroPrice() {
    return Column(
      children: [
        const Text(
          "ENTER STICKER PRICE",
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _priceController,
          autofocus: _discountType == DiscountType.percentage,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          style: const TextStyle(
            fontSize: 32, // 🚀 High impact typography
            fontWeight: FontWeight.w300,
            color: Color(0xFF2D3436),
            letterSpacing: -1,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: "0",
            prefixText: "₹ ",
            prefixStyle: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w300,
              color: Colors.grey.shade400,
            ),
            // 🚀 MODERN TEXTFIELD STYLE (Removing the box)
            filled: false,
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade100, width: 1),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: primaryColor.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildClassySummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          _buildSummaryRow("Subtotal", "₹${_stickerPrice.toInt()}"),
          const SizedBox(height: 8),
          _buildSummaryRow(
            "Discount Applied",
            "-₹${_discountValue.toInt()}",
            color: Colors.green.shade600,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 0.5),
          ),
          _buildSummaryRow(
            "NET TOTAL",
            "₹${_finalNetPrice.toInt()}",
            isBold: true,
            fontSize: 24,
            color: primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIndicator() => Container(
    width: 36,
    height: 4,
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(10),
    ),
  );

  Widget _buildTitleRow() => Text(
    _isEditing
        ? 'Edit ${widget.category?.name}'
        : 'Add ${widget.category?.name}',
    style: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: Colors.grey.shade600,
      letterSpacing: 0.5,
    ),
  );

  Widget _buildModernToggle() {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildToggleButton(DiscountType.percentage, "Percentage %"),
          _buildToggleButton(DiscountType.amount, "Fixed Amount ₹"),
        ],
      ),
    );
  }

  Widget _buildToggleButton(DiscountType type, String label) {
    bool isSelected = _discountType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          setState(() {
            _discountType = type;
            _discountInputController.clear();
            if (type == DiscountType.percentage)
              _discountInputController.text = "0";
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? primaryColor : Colors.grey.shade600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String val, {
    bool isBold = false,
    double fontSize = 13,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            color: Colors.blueGrey.shade700,
          ),
        ),
        Text(
          val,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            color: color ?? const Color(0xFF2D3436),
          ),
        ),
      ],
    );
  }

  void _handleSubmit() {
    final itemCategory = widget.category ?? widget.existingItem?.category;
    if (itemCategory == null) {
      debugPrint('Cannot submit: no category available');
      return;
    }

    final effectiveDiscountValue = _discountValue;
    final double finalDiscountPercent = _stickerPrice > 0
        ? (effectiveDiscountValue / _stickerPrice) * 100
        : 0.0;

    final newItem = CartItem(
      category: itemCategory,
      mrp: _stickerPrice,
      discountPercent: finalDiscountPercent,
      quantity: widget.existingItem?.quantity ?? 1,
      discountType: _discountType,
    );

    if (_isEditing) {
      widget.provider.updateItem(newItem, widget.index!);
    } else {
      widget.provider.addItem(newItem);
    }
    Navigator.pop(context);
  }
}
