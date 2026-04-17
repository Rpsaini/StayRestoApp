import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../features/hotel_search/presentation/bloc/Booking bloc.dart';
import '../features/hotel_search/presentation/widgets/image_preview_actions.dart';

class BookingsPage extends StatelessWidget {
  const BookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _BookingsBody();
  }
}

class _BookingsBody extends StatefulWidget {
  const _BookingsBody();

  @override
  State<_BookingsBody> createState() => _BookingsBodyState();
}

class _BookingsBodyState extends State<_BookingsBody>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = BookingRepository();
    final upcoming = repo.upcoming;
    final completed = repo.completed;
    final cancelled = repo.cancelled;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
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
              'My Bookings',
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            bottom: TabBar(
              controller: _tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.55),
              indicatorColor: Colors.white,
              indicatorWeight: 2.5,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                Tab(
                  child: _TabLabel(
                    label: 'Upcoming',
                    count: upcoming.length,
                    activeColor: const Color(0xFF22C55E),
                  ),
                ),
                Tab(
                  child: _TabLabel(
                    label: 'Completed',
                    count: completed.length,
                    activeColor: const Color(0xFF60A5FA),
                  ),
                ),
                Tab(
                  child: _TabLabel(
                    label: 'Cancelled',
                    count: cancelled.length,
                    activeColor: const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tab,
          children: [
            _BookingsList(bookings: upcoming, status: 'upcoming'),
            _BookingsList(bookings: completed, status: 'completed'),
            _BookingsList(bookings: cancelled, status: 'cancelled'),
          ],
        ),
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  final String label;
  final int count;
  final Color activeColor;

  const _TabLabel({
    required this.label,
    required this.count,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        if (count > 0) ...[
          SizedBox(width: 5.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: activeColor,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 9.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _BookingsList extends StatelessWidget {
  final List<BookingRecord> bookings;
  final String status;

  const _BookingsList({required this.bookings, required this.status});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) return _EmptyState(status: status);

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
      itemCount: bookings.length,
      itemBuilder: (ctx, i) => Padding(
        padding: EdgeInsets.only(bottom: 14.h),
        child: _BookingCard(record: bookings[i], status: status),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingRecord record;
  final String status;

  const _BookingCard({required this.record, required this.status});

  Color get _statusColor {
    switch (status) {
      case 'upcoming':
        return const Color(0xFF16A34A);
      case 'completed':
        return const Color(0xFF1A4B8E);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String get _statusLabel {
    switch (status) {
      case 'upcoming':
        return 'Upcoming';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  IconData get _statusIcon {
    switch (status) {
      case 'upcoming':
        return Icons.upcoming_rounded;
      case 'completed':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  int get _nights {
    try {
      final p1 = record.checkIn.split('-');
      final p2 = record.checkOut.split('-');
      final d1 = DateTime(int.parse(p1[0]), int.parse(p1[1]), int.parse(p1[2]));
      final d2 = DateTime(int.parse(p2[0]), int.parse(p2[1]), int.parse(p2[2]));
      return d2.difference(d1).inDays.clamp(1, 365);
    } catch (_) {
      return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = record.hotel.resolvedHotelGalleryUrls.isNotEmpty
        ? record.hotel.resolvedHotelGalleryUrls.first.trim()
        : record.hotel.frontImageUrl.trim();
    final hasImg = imageUrl.isNotEmpty &&
        (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A4B8E).withOpacity(0.07),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
            child: SizedBox(
              height: 120.h,
              width: double.infinity,
              child: GestureDetector(
                onTap: () => openHotelImagePreview(context, record.hotel),
                behavior: HitTestBehavior.opaque,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    hasImg
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _ph(),
                          )
                        : (imageUrl.isNotEmpty
                            ? Image.asset(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _ph(),
                              )
                            : _ph()),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.65),
                          ],
                          stops: const [0.3, 1.0],
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
                        color: _statusColor,
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: _statusColor.withOpacity(0.35),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_statusIcon, size: 10.sp, color: Colors.white),
                          SizedBox(width: 4.w),
                          Text(
                            _statusLabel,
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ),
                    Positioned(
                      bottom: 10.h,
                      left: 12.w,
                      right: 12.w,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.hotel.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 10.sp,
                                color: Colors.white70,
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                record.hotel.city,
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: Colors.white70,
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
          ),

          Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.confirmation_number_rounded,
                      size: 12.sp,
                      color: const Color(0xFF9CA3AF),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      record.bookingId,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: const Color(0xFF9CA3AF),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatBookedAt(record.bookedAt),
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),

                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.bed_rounded,
                        size: 16.sp,
                        color: const Color(0xFF1A4B8E),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          record.room.roomTypeName,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1D2E),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.people_rounded,
                        size: 12.sp,
                        color: const Color(0xFF9CA3AF),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '${record.guests} guest${record.guests > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10.h),

                Row(
                  children: [
                    Expanded(
                      child: _infoBox(
                        icon: Icons.login_rounded,
                        label: 'Check-in',
                        value: record.checkIn,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        '$_nights\nNight${_nights > 1 ? 's' : ''}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1A4B8E),
                          height: 1.3,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: _infoBox(
                        icon: Icons.logout_rounded,
                        label: 'Check-out',
                        value: record.checkOut,
                        color: const Color(0xFFEA580C),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),

                Container(height: 1, color: const Color(0xFFF0F4F8)),
                SizedBox(height: 12.h),

                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Amount',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                        Text(
                          '₹${record.totalPaid.toInt()}',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1A4B8E),
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: const Color(0xFFFED7AA)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.hotel_rounded,
                            size: 12.sp,
                            color: const Color(0xFFEA580C),
                          ),
                          SizedBox(width: 5.w),
                          Text(
                            'Pay On Hotel',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFEA580C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (status == 'upcoming') ...[
                  SizedBox(height: 10.h),
                  _CountdownChip(checkIn: record.checkIn),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatBookedAt(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  Widget _infoBox({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 11.sp, color: color),
          SizedBox(width: 5.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 9.sp, color: color.withOpacity(0.7)),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1D2E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ph() => Container(
    color: const Color(0xFFE2E8F0),
    child: Center(
      child: Icon(
        Icons.hotel_rounded,
        size: 36,
        color: const Color(0xFFCBD5E1),
      ),
    ),
  );
}

class _CountdownChip extends StatelessWidget {
  final String checkIn;
  const _CountdownChip({required this.checkIn});

  int get _daysLeft {
    try {
      final p = checkIn.split('-');
      final d = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
      return d.difference(DateTime.now()).inDays;
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = _daysLeft;
    final String label;
    final Color color;

    if (days == 0) {
      label = 'Check-in Today!';
      color = const Color(0xFF16A34A);
    } else if (days == 1) {
      label = 'Check-in Tomorrow';
      color = const Color(0xFFEA580C);
    } else if (days <= 7) {
      label = '$days days to go';
      color = const Color(0xFF7C3AED);
    } else {
      label = '$days days to go';
      color = const Color(0xFF1A4B8E);
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String status;
  const _EmptyState({required this.status});

  String get _emoji {
    switch (status) {
      case 'upcoming':
        return '';
      case 'completed':
        return '';
      case 'cancelled':
        return '❌';
      default:
        return '';
    }
  }

  String get _title {
    switch (status) {
      case 'upcoming':
        return 'No Upcoming Trips';
      case 'completed':
        return 'No Completed Stays';
      case 'cancelled':
        return 'No Cancelled Bookings';
      default:
        return 'No Bookings';
    }
  }

  String get _subtitle {
    switch (status) {
      case 'upcoming':
        return 'Your confirmed bookings will appear here';
      case 'completed':
        return 'Your past stays will be shown here';
      case 'cancelled':
        return 'Any cancelled bookings will appear here';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90.w,
              height: 90.h,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Center(
                child: Text(_emoji, style: TextStyle(fontSize: 36.sp)),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              _title,
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1D2E),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: const Color(0xFF94A3B8),
                height: 1.5,
              ),
            ),
            SizedBox(height: 28.h),
            SizedBox(
              height: 46.h,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A4B8E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 28.w),
                ),
                onPressed: () => Navigator.pop(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_rounded, size: 16.sp),
                    SizedBox(width: 8.w),
                    Text(
                      'Explore Hotels',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
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
}
