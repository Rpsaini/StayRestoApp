import 'package:stayresto/core/constants/api_constants.dart';

import '../../domain/entities/hotel_entity.dart';
import 'room_model.dart';

class HotelModel extends HotelEntity {
  const HotelModel({
    required super.id,
    required super.name,
    required super.rating,
    required super.city,
    required super.address,
    required super.bestPricePerNight,
    required super.frontImageUrl,
    required super.availableRoomsCount,
    required super.availableRooms,
  });

  factory HotelModel.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as Map<String, dynamic>?;
    final frontImagePath = images?['front'] as String?;

    final roomsList =
        (json['available_rooms'] as List<dynamic>?)
            ?.map((r) => RoomModel.fromJson(r as Map<String, dynamic>))
            .toList() ??
        [];

    return HotelModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Unknown Hotel',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      city: json['city'] as String? ?? '',
      address: json['address'] as String? ?? '',
      bestPricePerNight:
          (json['best_price_per_night'] as num?)?.toDouble() ?? 0.0,
      frontImageUrl: _resolveImageUrl(frontImagePath),
      availableRoomsCount: json['available_rooms_count'] as int? ?? 0,
      availableRooms: roomsList,
    );
  }

  static String _resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${ApiConstants.imageBaseUrl}$path';
  }
}
