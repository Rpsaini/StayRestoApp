import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stayresto/injection_container.dart' as di;

import '../../domain/entities/hotel_entity.dart';
import '../../domain/entities/room_entity.dart';
import '../bloc/Booking bloc.dart';
import '../widgets/image_preview_actions.dart';
import 'PaymentPage.dart';
import 'Wishlist_bloc.dart';

class HotelRoomPage extends StatefulWidget {
  final HotelEntity hotel;
  final String checkIn;
  final String checkOut;
  /// Total guests (adults + children) — used when [adults]/[children] are not set separately.
  final int guests;
  final int adults;
  final int children;
  final int rooms;
  final List<int>? childAges;

  const HotelRoomPage({
    super.key,
    required this.hotel,
    this.checkIn = '',
    this.checkOut = '',
    this.guests = 2,
    this.adults = 0,
    this.children = 0,
    this.rooms = 1,
    this.childAges,
  });

  int get effectiveAdults => adults > 0 ? adults : (guests >= 1 ? guests : 2);

  int get effectiveChildren => children;

  int get effectiveRooms => rooms >= 1 ? rooms : 1;

  @override
  State<HotelRoomPage> createState() => _HotelRoomPageState();
}

class _HotelRoomPageState extends State<HotelRoomPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _roomsSectionKey = GlobalKey();
  bool _elevateAppBar = false;

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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToRooms() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _roomsSectionKey.currentContext;
      if (ctx != null && mounted) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          alignment: 0.08,
        );
      }
    });
  }

  HotelEntity get hotel => widget.hotel;

  int get _nightsStay {
    try {
      final a = DateTime.parse(_effectiveCheckIn);
      final b = DateTime.parse(_effectiveCheckOut);
      final n = b.difference(a).inDays;
      return n < 1 ? 1 : n;
    } catch (_) {
      return 1;
    }
  }

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
          NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.axis == Axis.vertical) {
                final under = n.metrics.pixels > 56;
                if (under != _elevateAppBar) {
                  setState(() => _elevateAppBar = under);
                }
              }
              return false;
            },
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                _buildSliverAppBar(context, _elevateAppBar),
                SliverToBoxAdapter(child: _buildHotelDetailHeader()),
                SliverToBoxAdapter(child: _buildStaySummaryStrip()),
                ..._buildAboutSliver(),
                ..._buildRoomsSlivers(),
                SliverToBoxAdapter(child: _buildAmenitiesSection()),
                SliverToBoxAdapter(child: SizedBox(height: 140.h)),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(top: false, child: _buildBottomCTA()),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeading(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF94A3B8),
            letterSpacing: 0.6,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1A1D2E),
            height: 1.2,
          ),
        ),
      ],
    );
  }

  String _displayYmd(String ymd) {
    final p = ymd.split('-');
    if (p.length == 3) {
      return '${p[2]}/${p[1]}/${p[0]}';
    }
    return ymd;
  }

  Widget _buildStaySummaryStrip() {
    final g = widget.effectiveAdults + widget.effectiveChildren;
    final r = widget.effectiveRooms;
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(18.w, 0, 18.w, 16.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: const Color(0xFFE8ECF2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _miniDateCol(
                    'Check-in',
                    _displayYmd(_effectiveCheckIn),
                    Icons.login_rounded,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    '$_nightsStay N',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A4B8E),
                    ),
                  ),
                ),
                Expanded(
                  child: _miniDateCol(
                    'Check-out',
                    _displayYmd(_effectiveCheckOut),
                    Icons.logout_rounded,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Container(height: 1, color: const Color(0xFFE8ECF2)),
            SizedBox(height: 10.h),
            Row(
              children: [
                Icon(
                  Icons.people_outline_rounded,
                  size: 16.sp,
                  color: const Color(0xFF64748B),
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    '$g guest${g == 1 ? '' : 's'} · $r room${r == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniDateCol(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12.sp, color: const Color(0xFF94A3B8)),
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1A1D2E),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildAboutSliver() {
    return [
      SliverToBoxAdapter(
        child: Container(
          width: double.infinity,
          color: const Color(0xFFF4F6FB),
          padding: EdgeInsets.fromLTRB(18.w, 20.h, 18.w, 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeading('About', 'This property'),
              SizedBox(height: 12.h),
              Text(
                hotel.aboutHotel.trim().isNotEmpty
                    ? hotel.aboutHotel.trim()
                    : '${hotel.name} is in ${hotel.city}. Comfortable rooms, '
                        'thoughtful service, and amenities suited to short breaks or longer stays.',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF475569),
                  height: 1.55,
                ),
              ),
              SizedBox(height: 20.h),
              _sectionHeading('Highlights', 'Why guests choose us'),
              SizedBox(height: 12.h),
              _highlightRow(
                Icons.verified_rounded,
                'Verified property',
                'Quality-assured listing',
              ),
              SizedBox(height: 10.h),
              _highlightRow(
                Icons.support_agent_rounded,
                'Guest support',
                'Help when you need it',
              ),
              SizedBox(height: 10.h),
              _highlightRow(
                Icons.free_breakfast_rounded,
                'Dining',
                'Breakfast options may apply',
              ),
              SizedBox(height: 10.h),
              _highlightRow(
                Icons.event_available_rounded,
                'Flexible plans',
                'Check policy before you book',
              ),
              SizedBox(height: 20.h),
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: const Color(0xFFE8ECF2)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44.w,
                      height: 44.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A4B8E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.map_rounded,
                        size: 22.sp,
                        color: const Color(0xFF1A4B8E),
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Location',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            hotel.address.isNotEmpty
                                ? hotel.address
                                : hotel.city,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A1D2E),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildRoomsSlivers() {
    final g = widget.effectiveAdults + widget.effectiveChildren;
    final r = widget.effectiveRooms;
    final guestLine =
        '$g guest${g == 1 ? '' : 's'} · $r room${r == 1 ? '' : 's'} · '
        '${_displayYmd(_effectiveCheckIn)} – ${_displayYmd(_effectiveCheckOut)}';

    return [
      SliverToBoxAdapter(
        key: _roomsSectionKey,
        child: Container(
          width: double.infinity,
          color: const Color(0xFFF4F6FB),
          padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeading('Rooms', 'Choose your stay'),
              SizedBox(height: 6.h),
              Text(
                guestLine,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFF64748B),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
      if (hotel.availableRooms.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(18.w, 0, 18.w, 24.h),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 36.h, horizontal: 20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: const Color(0xFFE8ECF2)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.bed_rounded,
                    size: 44.sp,
                    color: const Color(0xFFCBD5E1),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'No rooms for these dates',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Try different dates or run a new search.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
      else
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final room = hotel.availableRooms[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: 14.h),
                  child: _RoomCard(
                    room: room,
                    hotel: widget.hotel,
                    checkIn: _effectiveCheckIn,
                    checkOut: _effectiveCheckOut,
                    adults: widget.effectiveAdults,
                    children: widget.effectiveChildren,
                    rooms: widget.effectiveRooms,
                    childAges: widget.childAges,
                  ),
                );
              },
              childCount: hotel.availableRooms.length,
            ),
          ),
        ),
    ];
  }

  Widget _buildAmenitiesSection() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF4F6FB),
      padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading('Amenities', 'Hotel facilities'),
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
                        color: available ? const Color(0xFF374151)
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

  Widget _buildHotelDetailHeader() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 8.h),
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
                        fontSize: 21.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1D2E),
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 2.h),
                          child: Icon(
                            Icons.location_on_rounded,
                            size: 15.sp,
                            color: const Color(0xFF1A4B8E),
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            hotel.address.isNotEmpty
                                ? hotel.address
                                : hotel.city,
                            style: TextStyle(
                              fontSize: 13.sp,
                              height: 1.35,
                              color: const Color(0xFF64748B),
                            ),
                            maxLines: 3,
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
                      color: const Color(0xFF1A4B8E).withOpacity(0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 15.sp,
                          color: const Color(0xFFFBBF24),
                        ),
                        SizedBox(width: 3.w),
                        Text(
                          hotel.rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Guest rating',
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: Colors.white.withOpacity(0.88),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _statBadge(
                  icon: Icons.bed_rounded,
                  label: '${hotel.availableRoomsCount} rooms',
                  color: const Color(0xFF16A34A),
                ),
                SizedBox(width: 8.w),
                _statBadge(
                  icon: Icons.currency_rupee_rounded,
                  label: 'From ₹${hotel.bestPricePerNight.toInt()}/night',
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
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, bool innerBoxIsScrolled) {
    final imageUrl = hotel.resolvedHotelGalleryUrls.isNotEmpty
        ? hotel.resolvedHotelGalleryUrls.first.trim()
        : hotel.frontImageUrl.trim();
    final galleryCount = hotel.resolvedHotelGalleryUrls.length;
    final hasNetwork =
        imageUrl.isNotEmpty &&
        (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'));

    return SliverAppBar(
      expandedHeight: 260.h,
      pinned: true,
      stretch: true,
      forceElevated: innerBoxIsScrolled,
      elevation: innerBoxIsScrolled ? 0.5 : 0,
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
        background: GestureDetector(
          onTap: () => openHotelImagePreview(context, hotel),
          child: Stack(
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
              if (galleryCount > 0)
                Positioned(
                  right: 12.w,
                  bottom: 20.h,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 16.sp,
                          color: Colors.white,
                        ),
                        if (galleryCount > 1) ...[
                          SizedBox(width: 6.w),
                          Text(
                            '$galleryCount photos · tap to view',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ] else
                          Text(
                            'Tap to view',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
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

  RoomEntity? get _leadRoom {
    final rooms = hotel.availableRooms;
    if (rooms.isEmpty) return null;
    // Avoid List.reduce: runtime list is often List<RoomModel> while the field
    // type is List<RoomEntity>, and reified reduce then rejects the callback.
    RoomEntity lead = rooms.first;
    for (var i = 1; i < rooms.length; i++) {
      final r = rooms[i];
      if (r.pricePerNight < lead.pricePerNight) lead = r;
    }
    return lead;
  }

  Widget _buildBottomCTA() {
    final lead = _leadRoom;
    final perNight = lead?.pricePerNight ?? hotel.bestPricePerNight;
    final listed = lead?.listedPricePerNight;
    final hasDisc = lead?.hasListedDiscount ?? false;
    final pct = lead?.discountPercent ?? 0;
    final stayTotal = perNight * _nightsStay;

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
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasDisc && listed != null) ...[
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 3.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      '$pct% OFF',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF166534),
                      ),
                    ),
                  ),
                  SizedBox(height: 6.h),
                ],
                Text(
                  'From',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (hasDisc && listed != null) ...[
                      Text(
                        '\u20B9${listed.toInt()}',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFDC2626),
                          decoration: TextDecoration.lineThrough,
                          decorationColor: const Color(0xFFDC2626),
                          decorationThickness: 2,
                          height: 1,
                        ),
                      ),
                      SizedBox(width: 8.w),
                    ],
                    Text(
                      '\u20B9${perNight.toInt()}',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A4B8E),
                        height: 1,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Padding(
                      padding: EdgeInsets.only(bottom: 2.h),
                      child: Text(
                        '/ night',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  '$_nightsStay night${_nightsStay == 1 ? '' : 's'} from \u20B9${stayTotal.toInt()} (excl. taxes)',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          SizedBox(
            height: 48.h,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A4B8E),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 18.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              onPressed: _scrollToRooms,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View rooms',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Icon(Icons.arrow_forward_rounded, size: 18.sp),
                ],
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
// Room Card — StayResto-style pricing + checkout
// ─────────────────────────────────────────────────────────────────────────────
class _RoomCard extends StatelessWidget {
  final RoomEntity room;
  final HotelEntity hotel;
  final String checkIn;
  final String checkOut;
  final int adults;
  final int children;
  final int rooms;
  final List<int>? childAges;

  const _RoomCard({
    required this.room,
    required this.hotel,
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    required this.children,
    required this.rooms,
    this.childAges,
  });

  int get _nights {
    try {
      final a = DateTime.parse(checkIn);
      final b = DateTime.parse(checkOut);
      final n = b.difference(a).inDays;
      return n < 1 ? 1 : n;
    } catch (_) {
      return 1;
    }
  }

  int get _guestTotal => adults + children;

  @override
  Widget build(BuildContext context) {
    final imageUrl = room.resolvedGalleryUrls.isNotEmpty
        ? room.resolvedGalleryUrls.first.trim()
        : room.primaryImageUrl.trim();
    final hasNetwork = imageUrl.isNotEmpty &&
        (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'));
    final listed = room.listedPricePerNight;
    final hasDisc = room.hasListedDiscount;
    final pct = room.discountPercent;
    final staySubtotal = room.pricePerNight * _nights;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: const Color(0xFFE8ECF2)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: () =>
                            openRoomImagePreview(context, room, hotel: hotel),
                        child: SizedBox(
                          width: 118.w,
                          height: 132.h,
                          child: hasNetwork
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _placeholder(),
                                  loadingBuilder: (_, child, prog) =>
                                      prog == null ? child : _placeholder(),
                                )
                              : imageUrl.isNotEmpty ? Image.asset(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _placeholder(),
                                    )
                                  : _placeholder(),
                        ),
                      ),
                      if (hasDisc)
                        Positioned(
                          top: 8.h,
                          left: 8.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              '$pct% OFF',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 10.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            room.roomTypeName,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            '$_nights night${_nights == 1 ? '' : 's'} · '
                            '$_guestTotal guest${_guestTotal == 1 ? '' : 's'} · '
                            '$rooms room${rooms == 1 ? '' : 's'}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          SizedBox(height: 10.h),
                          Wrap(
                            spacing: 6.w,
                            runSpacing: 4.h,
                            children: [
                              _pill(Icons.wifi_rounded, 'WiFi'),
                              _pill(Icons.ac_unit_rounded, 'AC'),
                              _pill(Icons.free_breakfast_rounded, 'Breakfast'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 1, color: const Color(0xFFF1F5F9)),
                    SizedBox(height: 12.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Per night',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (hasDisc && listed != null) ...[
                                    Text(
                                      '₹${listed.toInt()}',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFFDC2626),
                                        decoration: TextDecoration.lineThrough,
                                        decorationColor: const Color(0xFFDC2626),
                                        decorationThickness: 2,
                                        height: 1,
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                  ],
                                  Text(
                                    '₹${room.pricePerNight.toInt()}',
                                    style: TextStyle(
                                      fontSize: 24.sp,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF1A4B8E),
                                      height: 1,
                                    ),
                                  ),
                                  SizedBox(width: 4.w),
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 3.h),
                                    child: Text(
                                      '/ night',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                'Stay subtotal · ₹${staySubtotal.toInt()} for '
                                '$_nights night${_nights == 1 ? '' : 's'} (excl. taxes)',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 10.w),
                        SizedBox(
                          height: 44.h,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A4B8E),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BlocProvider(
                                  create: (_) => di.sl<BookingBloc>(),
                                  child: PaymentPage(
                                    hotel: hotel,
                                    room: room,
                                    checkIn: checkIn,
                                    checkOut: checkOut,
                                    guests: adults + children,
                                    adults: adults,
                                    children: children,
                                    rooms: rooms,
                                    childAges: childAges,
                                  ),
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Book',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Icon(Icons.arrow_forward_rounded, size: 16.sp),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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

