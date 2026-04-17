import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain/entities/hotel_entity.dart';
import '../widgets/image_preview_actions.dart';
import 'hotel_room_page.dart';
// import '../../features/hotel_search/domain/entities/hotel_entity.dart';
// import '../../Screen/home_search_screen/sub_pages/hotel_room_page.dart';

class HotelListingPage extends StatelessWidget {
  final String title;

  final List<HotelEntity> hotels;

  const HotelListingPage({
    super.key,
    required this.title,
    required this.hotels,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF1A4B8E),
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.arrow_back_ios_rounded,
                  size: 16.sp,
                  color: Colors.white,
                ),
              ),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            actions: [
              Container(
                margin: EdgeInsets.only(right: 14.w, top: 8.h, bottom: 8.h),
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.hotel_rounded, size: 11.sp, color: Colors.white),
                    SizedBox(width: 4.w),
                    Text(
                      '${hotels.length}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 24.h),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 12.h,
                mainAxisExtent: 230.h, // same card height as homepage
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => _HotelCard(
                  hotel: hotels[i],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HotelRoomPage(hotel: hotels[i]),
                    ),
                  ),
                ),
                childCount: hotels.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HotelCard extends StatelessWidget {
  final HotelEntity hotel;
  final VoidCallback onTap;
  const _HotelCard({required this.hotel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final heroUrl = hotel.resolvedHotelGalleryUrls.isNotEmpty
        ? hotel.resolvedHotelGalleryUrls.first
        : hotel.frontImageUrl;
    final hasImg = heroUrl.isNotEmpty &&
        (heroUrl.startsWith('http://') || heroUrl.startsWith('https://'));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A4B8E).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => openHotelImagePreview(context, hotel),
              child: SizedBox(
                height: 140.h,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    hasImg
                        ? Image.network(
                            heroUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _ph(),
                            loadingBuilder: (_, child, prog) =>
                                prog == null ? child : _ph(),
                          )
                        : (heroUrl.isNotEmpty
                            ? Image.asset(
                                heroUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _ph(),
                              )
                            : _ph()),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.45),
                            ],
                            stops: const [0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 7.h,
                      right: 7.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 9.sp,
                              color: const Color(0xFFFBBF24),
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              hotel.rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A1D2E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 7.h,
                      left: 8.w,
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '₹${hotel.bestPricePerNight.toInt()}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1,
                              ),
                            ),
                            TextSpan(
                              text: '/nt',
                              style: TextStyle(
                                fontSize: 9.sp,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.fromLTRB(9.w, 7.h, 9.w, 8.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hotel.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1D2E),
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 9.sp,
                          color: const Color(0xFF1A4B8E),
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Text(
                            hotel.city.isNotEmpty ? hotel.city : hotel.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9.sp,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 7.h),
                    SizedBox(
                      width: double.infinity,
                      height: 26.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A4B8E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        onPressed: onTap,
                        child: Text(
                          'Book Now',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ph() => Container(
    color: const Color(0xFFF1F5F9),
    child: Center(
      child: Icon(
        Icons.hotel_rounded,
        size: 26,
        color: const Color(0xFFCBD5E1),
      ),
    ),
  );
}
