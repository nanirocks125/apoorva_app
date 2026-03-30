// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaleItem _$SaleItemFromJson(Map<String, dynamic> json) => SaleItem(
  categoryId: json['cat_id'] as String,
  qty: (json['qty'] as num).toInt(),
  stickerPrice: (json['sticker_price'] as num).toDouble(),
  finalPrice: (json['final_price'] as num).toDouble(),
);

Map<String, dynamic> _$SaleItemToJson(SaleItem instance) => <String, dynamic>{
  'cat_id': instance.categoryId,
  'qty': instance.qty,
  'sticker_price': instance.stickerPrice,
  'final_price': instance.finalPrice,
};
