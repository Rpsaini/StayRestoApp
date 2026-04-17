import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../features/hotel_search/domain/entities/hotel_entity.dart';
import '../features/hotel_search/presentation/pages/Wishlist_bloc.dart';
import '../features/hotel_search/presentation/pages/hotel_room_page.dart';
import '../features/hotel_search/presentation/widgets/image_preview_actions.dart';

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: BlocBuilder<WishlistBloc, WishlistState>(
        builder: (ctx, state) {
          final items = state.hotels;
          return CustomScrollView(
            slivers: [
              _buildAppBar(ctx, items.length),
              items.isEmpty
                  ? SliverFillRemaining(child: _buildEmpty())
                  : SliverPadding(
                      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 24.h),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => Padding(
                            padding: EdgeInsets.only(bottom: 14.h),
                            child: _WishlistCard(
                              hotel: items[i],
                              onRemove: () => ctx.read<WishlistBloc>().add(
                                ToggleWishlist(items[i]),
                              ),
                              onTap: () => Navigator.push(
                                ctx,
                                MaterialPageRoute(
                                  builder: (_) => BlocProvider.value(
                                    value: ctx.read<WishlistBloc>(),
                                    child: HotelRoomPage(hotel: items[i]),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          childCount: items.length,
                        ),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }

  // ── Compact AppBar
  Widget _buildAppBar(BuildContext context, int count) {
    return SliverAppBar(
      expandedHeight: 88.h,
      floating: false,
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
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.zero,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A3A6E), Color(0xFF1A4B8E), Color(0xFF2563EB)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(56.w, 0, 16.w, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 32.w,
                    height: 32.h,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(9.r),
                    ),
                    child: Icon(
                      Icons.favorite_rounded,
                      size: 15.sp,
                      color: const Color(0xFFFCA5A5),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'My Wishlist',
                        style: TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        count == 0
                            ? 'No saved hotels'
                            : '$count hotel${count == 1 ? '' : 's'} saved',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.white.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (count > 0)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 5.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.hotel_rounded,
                            size: 11.sp,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '$count',
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90.w,
              height: 90.h,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withOpacity(0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                Icons.favorite_outline_rounded,
                size: 42.sp,
                color: const Color(0xFFEF4444),
              ),
            ),
            SizedBox(height: 18.h),
            Text(
              'No saved hotels yet',
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1D2E),
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Tap the ♥ on any hotel card\nto save your favorites here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: const Color(0xFF9CA3AF),
                height: 1.5,
              ),
            ),
            SizedBox(height: 24.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: const Color(0xFF1A4B8E).withOpacity(0.06),
                borderRadius: BorderRadius.circular(30.r),
                border: Border.all(
                  color: const Color(0xFF1A4B8E).withOpacity(0.15),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 15.sp,
                    color: const Color(0xFF1A4B8E),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    'Browse Hotels',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A4B8E),
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
}

class _WishlistCard extends StatelessWidget {
  final HotelEntity hotel;
  final VoidCallback onRemove;
  final VoidCallback onTap;
  const _WishlistCard({
    required this.hotel,
    required this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = hotel.resolvedHotelGalleryUrls.isNotEmpty
        ? hotel.resolvedHotelGalleryUrls.first.trim()
        : hotel.frontImageUrl.trim();
    final hasImg =
        imageUrl.isNotEmpty &&
        (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A4B8E).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                GestureDetector(
                  onTap: () => openHotelImagePreview(context, hotel),
                  child: AspectRatio(
                    aspectRatio: 16 / 8,
                    child: hasImg
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _ph(),
                            loadingBuilder: (_, child, prog) =>
                                prog == null ? child : _shimmer(),
                          )
                        : (imageUrl.isNotEmpty
                            ? Image.asset(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _ph(),
                              )
                            : _ph()),
                  ),
                ),
                Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.55),
                          ],
                          stops: const [0.4, 1.0],
                        ),
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
                          '₹${hotel.bestPricePerNight.toInt()}',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Padding(
                          padding: EdgeInsets.only(bottom: 2.h),
                          child: Text(
                            '/night',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Positioned(
                    bottom: 10.h,
                    right: 52.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 11.sp,
                            color: const Color(0xFFFBBF24),
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            hotel.rating.toStringAsFixed(1),
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
                    top: 10.h,
                    right: 10.w,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        width: 36.w,
                        height: 36.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEF4444).withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.favorite_rounded,
                          size: 16.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onTap,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 14.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hotel.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1D2E),
                          letterSpacing: -0.3,
                        ),
                      ),
                    SizedBox(height: 5.h),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 12.sp,
                          color: const Color(0xFF1A4B8E),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Text(
                            hotel.address.isNotEmpty
                                ? hotel.address
                                : hotel.city,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Container(height: 1, color: const Color(0xFFF0F4F8)),
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
                        onPressed: onTap,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'View Hotel',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
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
        size: 40,
        color: const Color(0xFFCBD5E1),
      ),
    ),
  );
  Widget _shimmer() => Container(color: const Color(0xFFE2E8F0));
}
