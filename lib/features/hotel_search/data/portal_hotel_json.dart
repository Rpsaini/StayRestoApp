import '../../../core/constants/api_constants.dart';
import '../domain/entities/hotel_entity.dart';

/// Normalizes portal search / top-hotels JSON into [HotelEntity] (same fields as BookingEngine consumes).
class PortalHotelJson {
  PortalHotelJson._();

  static String resolveImageUrl(dynamic v) {
    if (v == null || v.toString().trim().isEmpty) return '';
    final s = v.toString().trim();
    if (s.startsWith('http://') || s.startsWith('https://')) return s;
    final base = ApiConstants.imageBaseUrl;
    return s.startsWith('/') ? '$base$s' : '$base/$s';
  }

  static List<String> _collectGalleryFromMap(Map<String, dynamic> m) {
    final seen = <String>{};
    final out = <String>[];

    void add(dynamic v) {
      if (v == null) return;
      if (v is String) {
        final u = resolveImageUrl(v);
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

    add(m['front_image']?.toString());
    add(m['primary_image']?.toString());

    final images = m['images'];
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

  static String _paymentTypeFromMap(Map<String, dynamic> m) {
    final raw = (m['payment_type'] ?? m['paymentType'] ?? 'pay_at_hotel')
        .toString()
        .toLowerCase()
        .trim();
    if (raw == 'full_payment' || raw == 'full') return 'full_payment';
    return 'pay_at_hotel';
  }

  static HotelEntity toHotelEntity(
    Map<String, dynamic> m, {
    String fallbackLocation = '',
  }) {
    final id = int.tryParse(m['id']?.toString() ?? '0') ?? 0;
    final gallery = _collectGalleryFromMap(m);
    final hotelImg = gallery.isNotEmpty ? gallery.first : '';
    final policies = m['hotel_policies'];
    final hp = policies is Map ? Map<String, dynamic>.from(policies as Map) : null;
    final bestNight = double.tryParse(
          m['best_price_per_night']?.toString() ??
              m['best_price']?.toString() ??
              m['price_per_night']?.toString() ??
              '0',
        ) ??
        0.0;
    return HotelEntity(
      id: id,
      name: (m['name'] ?? 'Hotel').toString(),
      rating: double.tryParse(m['rating']?.toString() ?? '0') ?? 0.0,
      city: (m['city'] ?? fallbackLocation).toString(),
      address: (m['address'] ?? m['city'] ?? fallbackLocation).toString(),
      bestPricePerNight: bestNight,
      frontImageUrl: hotelImg,
      galleryImageUrls: gallery,
      paymentType: _paymentTypeFromMap(m),
      availableRoomsCount:
          int.tryParse(m['available_rooms_count']?.toString() ?? '0') ?? 0,
      availableRooms: const [],
      aboutHotel: (m['about_hotel'] as String?)?.trim() ?? '',
      starRating: int.tryParse(m['star_rating']?.toString() ?? '') ?? 0,
      state: (m['state'] ?? '').toString(),
      country: (m['country'] ?? '').toString(),
      zipCode: (m['zip_code'] ?? '').toString(),
      fullAddress: (m['full_address'] ?? '').toString(),
      phone: (m['phone'] ?? '').toString().trim(),
      email: (m['email'] ?? '').toString(),
      checkInTime:
          (m['check_in_time'] ?? hp?['check_in_time'] ?? '').toString(),
      checkOutTime:
          (m['check_out_time'] ?? hp?['check_out_time'] ?? '').toString(),
      latitude: double.tryParse(m['latitude']?.toString() ?? ''),
      longitude: double.tryParse(m['longitude']?.toString() ?? ''),
      gstPercentage: double.tryParse(m['gst_percentage']?.toString() ?? ''),
    );
  }
}
