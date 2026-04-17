import 'package:equatable/equatable.dart';

class RoomEntity extends Equatable {
  final int id;
  final String roomTypeName;
  final double pricePerNight;
  /// Listed / rack rate before discount (when API sends it — same idea as StayResto web strikethrough).
  final double? listedPricePerNight;
  final String primaryImageUrl;
  /// All room photos (primary first), parsed from API `images` / `primary_image`.
  final List<String> galleryImageUrls;
  /// From API `booking_payment_info.payment_plan` (`pay_at_hotel` | `full_payment`).
  final String paymentPlan;
  /// Room-level GST % when API sends `gst_percentage` (e.g. 12.0, 15.0).
  final double? gstPercentage;

  const RoomEntity({
    required this.id,
    required this.roomTypeName,
    required this.pricePerNight,
    this.listedPricePerNight,
    required this.primaryImageUrl,
    this.galleryImageUrls = const [],
    this.paymentPlan = 'pay_at_hotel',
    this.gstPercentage,
  });

  /// Online prepayment required for this room (Search API payment plan).
  bool get requiresFullOnlinePayment =>
      paymentPlan == 'full_payment' || paymentPlan == 'full';

  /// Non-empty gallery, or `[primaryImageUrl]` when set, for UI and previews.
  List<String> get resolvedGalleryUrls {
    if (galleryImageUrls.isNotEmpty) return galleryImageUrls;
    final p = primaryImageUrl.trim();
    if (p.isNotEmpty) return [p];
    return const [];
  }

  bool get hasListedDiscount =>
      listedPricePerNight != null &&
      listedPricePerNight! > pricePerNight + 0.009;

  int get discountPercent {
    if (!hasListedDiscount) return 0;
    final l = listedPricePerNight!;
    return (((l - pricePerNight) / l) * 100).round().clamp(1, 99);
  }

  @override
  List<Object?> get props => [
    id,
    roomTypeName,
    pricePerNight,
    listedPricePerNight,
    primaryImageUrl,
    galleryImageUrls,
    paymentPlan,
    gstPercentage,
  ];
}
