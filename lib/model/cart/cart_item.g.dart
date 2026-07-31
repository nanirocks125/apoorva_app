// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CartItem _$CartItemFromJson(Map<String, dynamic> json) => CartItem(
  category: Category.fromJson(json['category'] as Map<String, dynamic>),
  mrp: (json['mrp'] as num).toDouble(),
  discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0.0,
  quantity: (json['quantity'] as num).toInt(),
  discountType:
      $enumDecodeNullable(_$DiscountTypeEnumMap, json['discountType']) ??
      DiscountType.percentage,
);

Map<String, dynamic> _$CartItemToJson(CartItem instance) => <String, dynamic>{
  'category': instance.category.toJson(),
  'mrp': instance.mrp,
  'discountPercent': instance.discountPercent,
  'quantity': instance.quantity,
  'discountType': _$DiscountTypeEnumMap[instance.discountType]!,
};

const _$DiscountTypeEnumMap = {
  DiscountType.percentage: 'percentage',
  DiscountType.amount: 'amount',
  DiscountType.finalPrice: 'finalPrice',
};
