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
    super.galleryImageUrls = const [],
    super.paymentType = 'pay_at_hotel',
    required super.availableRoomsCount,
    required super.availableRooms,
    super.aboutHotel = '',
    super.starRating = 0,
    super.state = '',
    super.country = '',
    super.zipCode = '',
    super.fullAddress = '',
    super.phone = '',
    super.email = '',
    super.checkInTime = '',
    super.checkOutTime = '',
    super.latitude,
    super.longitude,
    super.gstPercentage,
  });

  static String _parsePaymentType(Map<String, dynamic> json) {
    final raw = (json['payment_type'] ?? json['paymentType'] ?? 'pay_at_hotel')
        .toString()
        .toLowerCase()
        .trim();
    if (raw == 'full_payment' || raw == 'full') return 'full_payment';
    return 'pay_at_hotel';
  }

  static int? _parseInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '');
  }

  static double? _parseDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '');
  }

  factory HotelModel.fromJson(Map<String, dynamic> json) {
    final gallery = _collectHotelGalleryUrls(json);
    final policies = json['hotel_policies'];
    final hp = policies is Map ? Map<String, dynamic>.from(policies as Map) : null;

    final roomsList =
        (json['available_rooms'] as List<dynamic>?)
            ?.map((r) => RoomModel.fromJson(r as Map<String, dynamic>))
            .toList() ??
        [];

    final idRaw = json['id'];
    final id = idRaw is int
        ? idRaw
        : int.tryParse(idRaw?.toString() ?? '') ?? 0;

    final roomsCountRaw = json['available_rooms_count'];
    final roomsCount = roomsCountRaw is int
        ? roomsCountRaw
        : int.tryParse(roomsCountRaw?.toString() ?? '0') ?? 0;

    final bestNight = _parseDouble(json['best_price_per_night']) ??
        _parseDouble(json['best_price']) ??
        0.0;

    return HotelModel(
      id: id,
      name: json['name'] as String? ?? 'Unknown Hotel',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      city: json['city'] as String? ?? '',
      address: json['address'] as String? ?? '',
      bestPricePerNight: bestNight,
      frontImageUrl: gallery.isNotEmpty ? gallery.first : '',
      galleryImageUrls: gallery,
      paymentType: _parsePaymentType(json),
      availableRoomsCount: roomsCount,
      availableRooms: roomsList,
      aboutHotel: (json['about_hotel'] as String?)?.trim() ?? '',
      starRating: _parseInt(json['star_rating']) ?? 0,
      state: json['state'] as String? ?? '',
      country: json['country'] as String? ?? '',
      zipCode: json['zip_code'] as String? ?? '',
      fullAddress: json['full_address'] as String? ?? '',
      phone: (json['phone'] ?? '').toString().trim(),
      email: (json['email'] ?? '').toString(),
      checkInTime:
          (json['check_in_time'] ?? hp?['check_in_time'] ?? '').toString(),
      checkOutTime:
          (json['check_out_time'] ?? hp?['check_out_time'] ?? '').toString(),
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      gstPercentage: _parseDouble(json['gst_percentage']),
    );
  }

  static String _resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    final t = path.trim();
    if (t.startsWith('http://') || t.startsWith('https://')) return t;
    if (t.startsWith('/')) return '${ApiConstants.imageBaseUrl}$t';
    return '${ApiConstants.imageBaseUrl}/$t';
  }

  /// StayResto web order: front, restaurant, pool, gym, spa, viewpoint, skytop, …
  static List<String> _collectHotelGalleryUrls(Map<String, dynamic> json) {
    final seen = <String>{};
    final out = <String>[];

    void add(dynamic v) {
      if (v == null) return;
      if (v is String) {
        final u = _resolveImageUrl(v);
        if (u.isNotEmpty && !seen.contains(u)) {
          seen.add(u);
          out.add(u);
        }
        return;
      }
      if (v is Map) {
        final url = v['url'] ?? v['src'] ?? v['image'];
        if (url != null) add(url.toString());
      }
    }

    add(json['front_image']);
    add(json['primary_image']);
    add(json['image']);

    final images = json['images'];
    if (images is Map) {
      const orderedKeys = [
        'front',
        'restaurant',
        'pool',
        'gym',
        'spa',
        'viewpoint',
        'skytop',
        'primary',
      ];
      for (final k in orderedKeys) {
        add(images[k]);
      }
      final galleryList = images['gallery'];
      if (galleryList is List) {
        for (final item in galleryList) {
          add(item);
        }
      }
      for (final e in images.entries) {
        add(e.value);
      }
    }

    return out;
  }
}
