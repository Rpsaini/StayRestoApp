import 'package:stayresto/core/constants/api_constants.dart';

import '../../domain/entities/room_entity.dart';

class RoomModel extends RoomEntity {
  const RoomModel({
    required super.id,
    required super.roomTypeName,
    required super.pricePerNight,
    required super.primaryImageUrl,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] as int,
      roomTypeName: json['room_type_name'] as String? ?? 'Standard Room',
      pricePerNight: (json['price_per_night'] as num?)?.toDouble() ?? 0.0,
      primaryImageUrl: _resolveImageUrl(json['primary_image'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'room_type_name': roomTypeName,
    'price_per_night': pricePerNight,
    'primary_image': primaryImageUrl,
  };

  static String _resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${ApiConstants.imageBaseUrl}$path';
  }
}
