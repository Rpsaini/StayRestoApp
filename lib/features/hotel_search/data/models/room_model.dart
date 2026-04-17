import 'package:stayresto/core/constants/api_constants.dart';

import '../../domain/entities/room_entity.dart';

class RoomModel extends RoomEntity {
  const RoomModel({
    required super.id,
    required super.roomTypeName,
    required super.pricePerNight,
    super.listedPricePerNight,
    required super.primaryImageUrl,
    super.galleryImageUrls = const [],
    super.paymentPlan = 'pay_at_hotel',
    super.gstPercentage,
  });

  static double? _parseListed(Map<String, dynamic> json) {
    final keys = [
      'listed_price_per_night',
      'strike_price_per_night',
      'original_price_per_night',
      'rack_price_per_night',
      'mrp_per_night',
      'before_discount_per_night',
    ];
    for (final k in keys) {
      final v = json[k];
      if (v is num) return v.toDouble();
      if (v != null) {
        final d = double.tryParse(v.toString());
        if (d != null) return d;
      }
    }
    return null;
  }

  static String _parsePaymentPlan(Map<String, dynamic> json) {
    final info = json['booking_payment_info'];
    if (info is Map) {
      final plan =
          (info['payment_plan'] ?? info['paymentPlan'] ?? '').toString();
      final p = plan.toLowerCase().trim();
      if (p == 'full_payment' || p == 'full' || p == 'prepay') {
        return 'full_payment';
      }
    }
    return 'pay_at_hotel';
  }

  static double? _parseGst(Map<String, dynamic> json) {
    final v = json['gst_percentage'] ?? json['gstPercentage'];
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '');
  }

  /// Listed nightly rate from stay totals when API sends `original_total_for_stay`.
  static double? _listedFromStayTotals(Map<String, dynamic> json, double price) {
    final orig = json['original_total_for_stay'];
    final nights = (json['nights'] as num?)?.toDouble() ?? 0;
    final roomsReq = (json['rooms_requested'] as num?)?.toDouble() ??
        (json['rooms'] as num?)?.toDouble() ??
        1;
    if (orig is! num || nights <= 0 || roomsReq <= 0) return null;
    final perNight = orig.toDouble() / nights / roomsReq;
    if (perNight <= price + 0.009) return null;
    return perNight;
  }

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    final price = (json['price_per_night'] as num?)?.toDouble() ?? 0.0;
    var listed = _parseListed(json) ?? _listedFromStayTotals(json, price);
    if (listed != null && listed <= price) {
      listed = null;
    }
    final gallery = _collectGalleryUrls(json);
    final idRaw = json['id'];
    final id = idRaw is int
        ? idRaw
        : int.tryParse(idRaw?.toString() ?? '') ?? 0;
    return RoomModel(
      id: id,
      roomTypeName: json['room_type_name'] as String? ?? 'Standard Room',
      pricePerNight: price,
      listedPricePerNight: listed,
      primaryImageUrl: gallery.isNotEmpty ? gallery.first : '',
      galleryImageUrls: gallery,
      paymentPlan: _parsePaymentPlan(json),
      gstPercentage: _parseGst(json),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'room_type_name': roomTypeName,
    'price_per_night': pricePerNight,
    if (listedPricePerNight != null)
      'listed_price_per_night': listedPricePerNight,
    'primary_image': primaryImageUrl,
    if (galleryImageUrls.isNotEmpty) 'gallery_image_urls': galleryImageUrls,
  };

  static String _resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    final t = path.trim();
    if (t.startsWith('http://') || t.startsWith('https://')) return t;
    if (t.startsWith('/')) return '${ApiConstants.imageBaseUrl}$t';
    return '${ApiConstants.imageBaseUrl}/$t';
  }

  /// Collects URLs from flat fields and nested `images` (StayResto web shape).
  static List<String> _collectGalleryUrls(Map<String, dynamic> json) {
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

    add(json['primary_image']);
    add(json['primaryImage']);
    add(json['image']);
    add(json['thumbnail']);
    add(json['photo']);

    final images = json['images'];
    if (images is Map) {
      const orderedKeys = [
        'primary',
        'bathroom',
        'view_balcony',
        'floor_plan',
        'view',
        'thumbnail',
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
