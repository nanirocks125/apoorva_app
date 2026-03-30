// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaleItem _$SaleItemFromJson(Map<String, dynamic> json) => SaleItem(
  categoryId: json['cat_id'] as String,
  qty: (json['qty'] as num?)?.toInt() ?? 0,
  stickerPrice: (json['stickerPrice'] as num?)?.toDouble() ?? 0,
  finalPrice: (json['finalPrice'] as num?)?.toDouble() ?? 0,
  categoryName: json['categoryName'] as String? ?? '',
);

Map<String, dynamic> _$SaleItemToJson(SaleItem instance) => <String, dynamic>{
  'cat_id': instance.categoryId,
  'categoryName': instance.categoryName,
  'qty': instance.qty,
  'stickerPrice': instance.stickerPrice,
  'finalPrice': instance.finalPrice,
};
