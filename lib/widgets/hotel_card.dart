import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HotelCard extends StatelessWidget {
  const HotelCard({
    super.key,
    required this.imagePath,
    required this.hotelName,
    required this.location,
    required this.rating,
    required this.reviewCount,
    required this.pricePerNight,
    this.onBookNow,
    this.isNetworkImage = false,
  });

  final String imagePath;
  final String hotelName;
  final String location;
  final double rating;
  final int reviewCount;
  final int pricePerNight;
  final VoidCallback? onBookNow;
  final bool isNetworkImage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A4B8E).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 180.h,
                  child: isNetworkImage && imagePath.isNotEmpty
                      ? Image.network(
                          imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                          loadingBuilder: (_, child, progress) =>
                              progress == null ? child : _shimmer(),
                        )
                      : (imagePath.isNotEmpty
                            ? Image.asset(imagePath, fit: BoxFit.cover)
                            : _placeholder()),
                ),

                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.52),
                        ],
                        stops: const [0.45, 1.0],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 10.h,
                  right: 10.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 5.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.10),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 13.sp,
                          color: const Color(0xFFFBBF24),
                        ),
                        SizedBox(width: 3.w),
                        Text(
                          rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1D2E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Positioned(
                  bottom: 10.h,
                  left: 12.w,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹$pricePerNight',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Padding(
                        padding: EdgeInsets.only(bottom: 2.h),
                        child: Text(
                          '/night',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 14.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hotelName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1D2E),
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(height: 5.h),

                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 13.sp,
                        color: const Color(0xFF1A4B8E),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          '$reviewCount reviews',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: const Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  Divider(
                    color: const Color(0xFFF3F4F6),
                    thickness: 1,
                    height: 1,
                  ),
                  SizedBox(height: 12.h),

                  SizedBox(
                    width: double.infinity,
                    height: 42.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A4B8E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      onPressed: onBookNow ?? () {},
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Book Now',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Icon(Icons.arrow_forward_rounded, size: 15.sp),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: const Color(0xFFF1F5F9),
    child: Center(
      child: Icon(
        Icons.hotel_rounded,
        size: 48,
        color: const Color(0xFFCBD5E1),
      ),
    ),
  );

  Widget _shimmer() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFFE2E8F0), Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
      ),
    ),
  );
}
