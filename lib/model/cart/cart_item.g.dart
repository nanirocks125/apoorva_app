// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CartItem _$CartItemFromJson(Map<String, dynamic> json) => CartItem(
  category: Category.fromJson(json['category'] as Map<String, dynamic>),
  stickerPrice: (json['stickerPrice'] as num).toDouble(),
  discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0.0,
  quantity: (json['quantity'] as num?)?.toInt() ?? 1,
);

Map<String, dynamic> _$CartItemToJson(CartItem instance) => <String, dynamic>{
  'category': instance.category.toJson(),
  'stickerPrice': instance.stickerPrice,
  'discountPercent': instance.discountPercent,
  'quantity': instance.quantity,
};
