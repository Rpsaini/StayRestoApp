import 'package:flutter/material.dart';

import '../../domain/entities/hotel_entity.dart';
import '../../domain/entities/room_entity.dart';
import 'full_screen_image_gallery.dart';

/// Opens full-screen gallery for all hotel images (same everywhere in the app).
void openHotelImagePreview(BuildContext context, HotelEntity hotel) {
  FullScreenImageGallery.show(
    context,
    urls: List<String>.from(hotel.resolvedHotelGalleryUrls),
    title: hotel.name,
  );
}

/// Opens full-screen gallery for all room images; falls back to hotel hero if needed.
void openRoomImagePreview(
  BuildContext context,
  RoomEntity room, {
  HotelEntity? hotel,
}) {
  final urls = List<String>.from(room.galleryImageUrls);
  if (urls.isEmpty && room.primaryImageUrl.trim().isNotEmpty) {
    urls.add(room.primaryImageUrl.trim());
  }
  if (urls.isEmpty && hotel != null) {
    final fallback = hotel.resolvedHotelGalleryUrls;
    if (fallback.isNotEmpty) {
      urls.addAll(fallback);
    } else {
      final h = hotel.frontImageUrl.trim();
      if (h.isNotEmpty) urls.add(h);
    }
  }
  final title = hotel != null
      ? '${room.roomTypeName} · ${hotel.name}'
      : room.roomTypeName;
  FullScreenImageGallery.show(context, urls: urls, title: title);
}
