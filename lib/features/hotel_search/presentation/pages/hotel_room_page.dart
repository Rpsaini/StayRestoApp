import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain/entities/hotel_entity.dart';
import '../../domain/entities/room_entity.dart';
// import '../../../features/hotel_search/presentation/bloc/Booking_bloc.dart';
import '../bloc/Booking bloc.dart';
import 'PaymentPage.dart';
import 'Wishlist_bloc.dart';

class HotelRoomPage extends StatefulWidget {
  final HotelEntity hotel;
  final String checkIn;
  final String checkOut;
  final int guests;

  const HotelRoomPage({
    super.key,
    required this.hotel,
    this.checkIn = '',
    this.checkOut = '',
    this.guests = 2,
  });

  @override
  State<HotelRoomPage> createState() => _HotelRoomPageState();
}

class _HotelRoomPageState extends State<HotelRoomPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _amenities = [
    {'icon': Icons.wifi_rounded, 'title': 'Free WiFi', 'available': true},
    {'icon': Icons.pool_rounded, 'title': 'Pool', 'available': true},
    {
      'icon': Icons.local_parking_rounded,
      'title': 'Parking',
      'available': true,
    },
    {
      'icon': Icons.restaurant_rounded,
      'title': 'Restaurant',
      'available': true,
    },
    {'icon': Icons.spa_rounded, 'title': 'Spa', 'available': true},
    {'icon': Icons.fitness_center_rounded, 'title': 'Gym', 'available': true},
    {'icon': Icons.ac_unit_rounded, 'title': 'AC', 'available': true},
    {'icon': Icons.local_bar_rounded, 'title': 'Bar', 'available': false},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  HotelEntity get hotel => widget.hotel;

  // ✅ FIX 1: Agar checkIn/checkOut empty ho toh fallback dates generate karo
  String get _effectiveCheckIn {
    if (widget.checkIn.isNotEmpty) return widget.checkIn;
    final d = DateTime.now().add(const Duration(days: 1));
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String get _effectiveCheckOut {
    if (widget.checkOut.isNotEmpty) return widget.checkOut;
    final d = DateTime.now().add(const Duration(days: 2));
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildSliverAppBar(context),
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hotel.name,
                                  style: TextStyle(
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1A1D2E),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                SizedBox(height: 5.h),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_rounded,
                                      size: 14.sp,
                                      color: const Color(0xFF1A4B8E),
                                    ),
                                    SizedBox(width: 3.w),
                                    Expanded(
                                      child: Text(
                                        hotel.address.isNotEmpty
                                            ? hotel.address
                                            : hotel.city,
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: const Color(0xFF6B7280),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 10.h,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1A4B8E), Color(0xFF2563EB)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14.r),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF1A4B8E,
                                  ).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star_rounded,
                                      size: 14.sp,
                                      color: const Color(0xFFFBBF24),
                                    ),
                                    SizedBox(width: 3.w),
                                    Text(
                                      hotel.rating.toStringAsFixed(1),
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  'Rating',
                                  style: TextStyle(
                                    fontSize: 9.sp,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14.h),
                      Row(
                        children: [
                          _statBadge(
                            icon: Icons.bed_rounded,
                            label: '${hotel.availableRoomsCount} Rooms',
                            color: const Color(0xFF16A34A),
                          ),
                          SizedBox(width: 8.w),
                          _statBadge(
                            icon: Icons.currency_rupee_rounded,
                            label: 'From ₹${hotel.bestPricePerNight.toInt()}',
                            color: const Color(0xFF1A4B8E),
                          ),
                          if (hotel.city.isNotEmpty) ...[
                            SizedBox(width: 8.w),
                            _statBadge(
                              icon: Icons.location_city_rounded,
                              label: hotel.city,
                              color: const Color(0xFF7C3AED),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 16.h),
                      TabBar(
                        controller: _tabController,
                        labelColor: const Color(0xFF1A4B8E),
                        unselectedLabelColor: const Color(0xFF9CA3AF),
                        indicatorColor: const Color(0xFF1A4B8E),
                        indicatorWeight: 2.5,
                        labelStyle: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                        ),
                        unselectedLabelStyle: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        tabs: const [
                          Tab(text: 'Overview'),
                          Tab(text: 'Rooms'),
                          Tab(text: 'Amenities'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 520.h,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildRoomsTab(),
                      _buildAmenitiesTab(),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 100.h)),
            ],
          ),
          Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomCTA()),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    final imageUrl = hotel.frontImageUrl.trim();
    final hasNetwork =
        imageUrl.isNotEmpty &&
        (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'));

    return SliverAppBar(
      expandedHeight: 260.h,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF1A4B8E),
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(
            Icons.arrow_back_ios_rounded,
            size: 16.sp,
            color: Colors.white,
          ),
        ),
      ),
      actions: [
        BlocBuilder<WishlistBloc, WishlistState>(
          builder: (ctx, wishState) {
            final isSaved = wishState.contains(hotel.id);
            return GestureDetector(
              onTap: () {
                ctx.read<WishlistBloc>().add(ToggleWishlist(hotel));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          isSaved
                              ? Icons.favorite_border_rounded
                              : Icons.favorite_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isSaved
                              ? 'Removed from wishlist'
                              : 'Added to wishlist!',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    backgroundColor: isSaved
                        ? const Color(0xFF6B7280)
                        : const Color(0xFFEF4444),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                margin: EdgeInsets.symmetric(vertical: 8.h),
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: isSaved
                      ? const Color(0xFFEF4444).withOpacity(0.9)
                      : Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: isSaved
                      ? [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withOpacity(0.4),
                            blurRadius: 8,
                          ),
                        ]
                      : [],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    isSaved
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    key: ValueKey(isSaved),
                    size: 18.sp,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          },
        ),
        SizedBox(width: 6.w),
        Container(
          margin: EdgeInsets.symmetric(vertical: 8.h),
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(Icons.share_rounded, size: 18.sp, color: Colors.white),
        ),
        SizedBox(width: 12.w),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            hasNetwork
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _heroPh(),
                    loadingBuilder: (_, child, prog) =>
                        prog == null ? child : _heroShimmer(),
                  )
                : imageUrl.isNotEmpty
                ? Image.asset(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _heroPh(),
                  )
                : _heroPh(),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.25),
                    Colors.transparent,
                    Colors.black.withOpacity(0.4),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(18.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About This Hotel',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1D2E),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '${hotel.name} is a premium property located in ${hotel.city}. Enjoy world-class amenities, stunning views, and exceptional service. Whether you\'re here for business or leisure, we have everything to make your stay unforgettable.',
            style: TextStyle(
              fontSize: 13.sp,
              color: const Color(0xFF6B7280),
              height: 1.6,
            ),
          ),
          SizedBox(height: 18.h),
          Text(
            'Hotel Highlights',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1D2E),
            ),
          ),
          SizedBox(height: 10.h),
          _highlightRow(
            Icons.verified_rounded,
            'Verified Property',
            'Certified & quality assured',
          ),
          SizedBox(height: 8.h),
          _highlightRow(
            Icons.support_agent_rounded,
            '24/7 Support',
            'Round the clock assistance',
          ),
          SizedBox(height: 8.h),
          _highlightRow(
            Icons.free_breakfast_rounded,
            'Complimentary Breakfast',
            'Free breakfast for all guests',
          ),
          SizedBox(height: 8.h),
          _highlightRow(
            Icons.cancel_rounded,
            'Free Cancellation',
            'Cancel up to 24hrs before check-in',
          ),
          SizedBox(height: 18.h),
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42.w,
                  height: 42.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A4B8E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.map_rounded,
                    size: 20.sp,
                    color: const Color(0xFF1A4B8E),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Address',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: const Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        hotel.address.isNotEmpty ? hotel.address : hotel.city,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1D2E),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18.sp,
                  color: const Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _highlightRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 38.w,
          height: 38.h,
          decoration: BoxDecoration(
            color: const Color(0xFF1A4B8E).withOpacity(0.08),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, size: 18.sp, color: const Color(0xFF1A4B8E)),
        ),
        SizedBox(width: 12.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1D2E),
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11.sp, color: const Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ],
    );
  }

  // ✅ FIX 2: _effectiveCheckIn/_effectiveCheckOut/_guests use karo
  Widget _buildRoomsTab() {
    if (hotel.availableRooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bed_rounded,
              size: 48.sp,
              color: const Color(0xFFCBD5E1),
            ),
            SizedBox(height: 12.h),
            Text(
              'No rooms available',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Check back later for availability',
              style: TextStyle(fontSize: 12.sp, color: const Color(0xFF9CA3AF)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: hotel.availableRooms.length,
      itemBuilder: (context, index) {
        final room = hotel.availableRooms[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 14.h),
          child: _RoomCard(
            room: room,
            hotel: widget.hotel,
            checkIn: _effectiveCheckIn, // ✅ actual / fallback date
            checkOut: _effectiveCheckOut, // ✅ actual / fallback date
            guests: widget.guests, // ✅ actual guests
          ),
        );
      },
    );
  }

  Widget _buildAmenitiesTab() {
    return Padding(
      padding: EdgeInsets.all(18.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All Amenities',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1D2E),
            ),
          ),
          SizedBox(height: 14.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _amenities.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10.w,
              mainAxisSpacing: 10.h,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, index) {
              final item = _amenities[index];
              final available = item['available'] as bool;
              return Container(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                decoration: BoxDecoration(
                  color: available
                      ? const Color(0xFFF0F7FF)
                      : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: available
                        ? const Color(0xFF1A4B8E).withOpacity(0.15)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      size: 22.sp,
                      color: available
                          ? const Color(0xFF1A4B8E)
                          : const Color(0xFFCBD5E1),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      item['title'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: available
                            ? const Color(0xFF374151)
                            : const Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ✅ FIX 3: "Book Now" → "View Rooms" — Rooms tab pe le jaao
  Widget _buildBottomCTA() {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Best Price',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: const Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${hotel.bestPricePerNight.toInt()}',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A4B8E),
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
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: SizedBox(
              height: 48.h,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A4B8E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                onPressed: () => _tabController.animateTo(1), // ✅ Rooms tab
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'View Rooms',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(Icons.bed_rounded, size: 18.sp),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroPh() => Container(
    color: const Color(0xFFE2E8F0),
    child: Center(
      child: Icon(
        Icons.hotel_rounded,
        size: 60,
        color: const Color(0xFFCBD5E1),
      ),
    ),
  );
  Widget _heroShimmer() => Container(color: const Color(0xFFE2E8F0));
}

// ─────────────────────────────────────────────────────────────────────────────
// Room Card — navigates to PaymentPage
// ─────────────────────────────────────────────────────────────────────────────
class _RoomCard extends StatelessWidget {
  final RoomEntity room;
  final HotelEntity hotel;
  final String checkIn;
  final String checkOut;
  final int guests;

  const _RoomCard({
    required this.room,
    required this.hotel,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = room.primaryImageUrl.trim();
    final hasNetwork =
        imageUrl.isNotEmpty &&
        (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A4B8E).withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110.w,
              height: 120.h,
              child: hasNetwork
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                      loadingBuilder: (_, child, prog) =>
                          prog == null ? child : _placeholder(),
                    )
                  : imageUrl.isNotEmpty
                  ? Image.asset(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      room.roomTypeName,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1D2E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Wrap(
                      spacing: 5.w,
                      runSpacing: 4.h,
                      children: [
                        _pill(Icons.wifi_rounded, 'WiFi'),
                        _pill(Icons.ac_unit_rounded, 'AC'),
                        _pill(Icons.local_parking_rounded, 'Parking'),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Per night',
                              style: TextStyle(
                                fontSize: 9.sp,
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                            Text(
                              '₹${room.pricePerNight.toInt()}',
                              style: TextStyle(
                                fontSize: 17.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1A4B8E),
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        SizedBox(
                          height: 32.h,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A4B8E),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(horizontal: 14.w),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                            ),
                            // ✅ MAIN FIX — sahi data ke saath PaymentPage navigate karo
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BlocProvider(
                                  create: (_) => BookingBloc(),
                                  child: PaymentPage(
                                    hotel: hotel,
                                    room: room,
                                    checkIn: checkIn,
                                    checkOut: checkOut,
                                    guests: guests,
                                  ),
                                ),
                              ),
                            ),
                            child: Text(
                              'Select',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _pill(IconData icon, String label) => Container(
    padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
    decoration: BoxDecoration(
      color: const Color(0xFFF0F7FF),
      borderRadius: BorderRadius.circular(20.r),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 9.sp, color: const Color(0xFF1A4B8E)),
        SizedBox(width: 3.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 9.sp,
            color: const Color(0xFF1A4B8E),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _placeholder() => Container(
    color: const Color(0xFFF1F5F9),
    child: Center(
      child: Icon(Icons.bed_rounded, size: 32, color: const Color(0xFFCBD5E1)),
    ),
  );
}
