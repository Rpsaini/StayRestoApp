import 'package:equatable/equatable.dart';

import 'room_entity.dart';

class HotelEntity extends Equatable {
  final int id;
  final String name;
  final double rating;
  final String city;
  final String address;
  final double bestPricePerNight;
  final String frontImageUrl;
  /// Hotel property photos (e.g. `images.front`, `images.pool`, … from API).
  final List<String> galleryImageUrls;
  /// API `payment_type`: `pay_at_hotel` (guest may pay at property or in advance);
  /// `full_payment` (online prepayment only — no pay-at-hotel choice).
  /// Prefer per-room [RoomEntity.paymentPlan] when present; this is a property default.
  final String paymentType;
  final int availableRoomsCount;
  final List<RoomEntity> availableRooms;

  /// Search / detail API: `about_hotel`, `star_rating`, address & contact extras.
  final String aboutHotel;
  final int starRating;
  final String state;
  final String country;
  final String zipCode;
  final String fullAddress;
  final String phone;
  final String email;
  final String checkInTime;
  final String checkOutTime;
  final double? latitude;
  final double? longitude;
  /// Property-level GST % (`gst_percentage`), when no room-specific rate applies.
  final double? gstPercentage;

  const HotelEntity({
    required this.id,
    required this.name,
    required this.rating,
    required this.city,
    required this.address,
    required this.bestPricePerNight,
    required this.frontImageUrl,
    this.galleryImageUrls = const [],
    this.paymentType = 'pay_at_hotel',
    required this.availableRoomsCount,
    required this.availableRooms,
    this.aboutHotel = '',
    this.starRating = 0,
    this.state = '',
    this.country = '',
    this.zipCode = '',
    this.fullAddress = '',
    this.phone = '',
    this.email = '',
    this.checkInTime = '',
    this.checkOutTime = '',
    this.latitude,
    this.longitude,
    this.gstPercentage,
  });

  /// All non-empty hotel image URLs for thumbnails and full-screen gallery.
  List<String> get resolvedHotelGalleryUrls {
    if (galleryImageUrls.isNotEmpty) return galleryImageUrls;
    final f = frontImageUrl.trim();
    if (f.isNotEmpty) return [f];
    return const [];
  }

  @override
  List<Object?> get props => [
    id,
    name,
    rating,
    city,
    address,
    bestPricePerNight,
    frontImageUrl,
    galleryImageUrls,
    paymentType,
    availableRoomsCount,
    availableRooms,
    aboutHotel,
    starRating,
    state,
    country,
    zipCode,
    fullAddress,
    phone,
    email,
    checkInTime,
    checkOutTime,
    latitude,
    longitude,
    gstPercentage,
  ];
  factory HotelEntity.fromJson(Map<String, dynamic> json) => HotelEntity(
    id: json['id'],
    name: json['name'],
    city: json['city'],
    address: json['address'],
    rating: (json['rating'] as num).toDouble(),
    bestPricePerNight: (json['bestPricePerNight'] as num).toDouble(),
    frontImageUrl: json['frontImageUrl'],
    galleryImageUrls: const [],
    paymentType: (json['paymentType'] ?? 'pay_at_hotel').toString(),
    availableRoomsCount: json['availableRoomsCount'],
    availableRooms: [],
    aboutHotel: (json['aboutHotel'] ?? '').toString(),
    starRating: (json['starRating'] as num?)?.toInt() ?? 0,
    state: (json['state'] ?? '').toString(),
    country: (json['country'] ?? '').toString(),
    zipCode: (json['zipCode'] ?? '').toString(),
    fullAddress: (json['fullAddress'] ?? '').toString(),
    phone: (json['phone'] ?? '').toString(),
    email: (json['email'] ?? '').toString(),
    checkInTime: (json['checkInTime'] ?? '').toString(),
    checkOutTime: (json['checkOutTime'] ?? '').toString(),
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    gstPercentage: (json['gstPercentage'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'city': city,
    'address': address,
    'rating': rating,
    'bestPricePerNight': bestPricePerNight,
    'frontImageUrl': frontImageUrl,
    if (galleryImageUrls.isNotEmpty) 'galleryImageUrls': galleryImageUrls,
    if (paymentType != 'pay_at_hotel') 'paymentType': paymentType,
    'availableRoomsCount': availableRoomsCount,
    if (aboutHotel.isNotEmpty) 'aboutHotel': aboutHotel,
    if (starRating > 0) 'starRating': starRating,
    if (gstPercentage != null) 'gstPercentage': gstPercentage,
  };
}
