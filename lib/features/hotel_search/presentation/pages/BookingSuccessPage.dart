import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../pages/bookings_page.dart';
import '../bloc/Booking bloc.dart';

class BookingSuccessPage extends StatefulWidget {
  final String bookingId;
  final String hotelName;
  final String roomTypeName;
  final String checkIn;
  final String checkOut;
  final int guests;
  final double totalPaid;

  const BookingSuccessPage({
    super.key,
    required this.bookingId,
    required this.hotelName,
    required this.roomTypeName,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    required this.totalPaid,
  });

  @override
  State<BookingSuccessPage> createState() => _BookingSuccessPageState();
}

class _BookingSuccessPageState extends State<BookingSuccessPage>
    with TickerProviderStateMixin {
  late AnimationController _checkCtrl;
  late AnimationController _contentCtrl;
  late AnimationController _pulseCtrl;

  late Animation<double> _checkScale;
  late Animation<double> _checkOpacity;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();

    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _checkScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut));
    _checkOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkCtrl, curve: const Interval(0.0, 0.4)),
    );
    _contentFade = CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut);
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut));
    _pulseAnim = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _checkCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _contentCtrl.forward();
    });
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    _contentCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _goHome() {
    context.read<BookingBloc>().add(ResetBooking());
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _goToBookings() {
    context.read<BookingBloc>().add(ResetBooking());
    Navigator.of(context).popUntil((route) => route.isFirst);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const BookingsPage()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
          child: Column(
            children: [
              SizedBox(height: 36.h),

              AnimatedBuilder(
                animation: Listenable.merge([_checkCtrl, _pulseCtrl]),
                builder: (_, __) => ScaleTransition(
                  scale: _checkScale,
                  child: FadeTransition(
                    opacity: _checkOpacity,
                    child: ScaleTransition(
                      scale: _pulseAnim,
                      child: Container(
                        width: 96.w,
                        height: 96.h,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF16A34A).withOpacity(0.35),
                              blurRadius: 28,
                              spreadRadius: 4,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: 48.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20.h),

              FadeTransition(
                opacity: _contentFade,
                child: SlideTransition(
                  position: _contentSlide,
                  child: Column(
                    children: [
                      Text(
                        'Booking Confirmed! 🎉',
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1A1D2E),
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'Your stay has been successfully booked',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24.h),

              FadeTransition(
                opacity: _contentFade,
                child: SlideTransition(
                  position: _contentSlide,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      vertical: 12.h,
                      horizontal: 16.w,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF1A3A6E),
                          Color(0xFF1A4B8E),
                          Color(0xFF2563EB),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1A4B8E).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Icon(
                            Icons.confirmation_number_rounded,
                            size: 20.sp,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Booking ID',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: Colors.white60,
                              ),
                            ),
                            Text(
                              widget.bookingId,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(
                              ClipboardData(text: widget.bookingId),
                            );
                            HapticFeedback.lightImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Booking ID copied!'),
                                backgroundColor: const Color(0xFF16A34A),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.all(7.w),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              Icons.copy_rounded,
                              size: 14.sp,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 14.h),

              FadeTransition(
                opacity: _contentFade,
                child: SlideTransition(
                  position: _contentSlide,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1A4B8E).withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 10.h),
                          child: Text(
                            'Booking Details',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1D2E),
                            ),
                          ),
                        ),
                        _detailRow(
                          Icons.hotel_rounded,
                          'Hotel',
                          widget.hotelName,
                          const Color(0xFF1A4B8E),
                        ),
                        _divider(),
                        _detailRow(
                          Icons.bed_rounded,
                          'Room',
                          widget.roomTypeName,
                          const Color(0xFF7C3AED),
                        ),
                        _divider(),
                        _detailRow(
                          Icons.login_rounded,
                          'Check-in',
                          widget.checkIn,
                          const Color(0xFF16A34A),
                        ),
                        _divider(),
                        _detailRow(
                          Icons.logout_rounded,
                          'Check-out',
                          widget.checkOut,
                          const Color(0xFFEA580C),
                        ),
                        _divider(),
                        _detailRow(
                          Icons.people_rounded,
                          'Guests',
                          '${widget.guests} guest${widget.guests > 1 ? 's' : ''}',
                          const Color(0xFF0369A1),
                        ),
                        _divider(),
                        _detailRow(
                          Icons.hotel_rounded,
                          'Payment',
                          'Pay On Hotel',
                          const Color(0xFF7C3AED),
                        ),
                        _divider(),
                        Padding(
                          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 14.h),
                          child: Row(
                            children: [
                              Container(
                                width: 34.w,
                                height: 34.h,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF16A34A,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Icon(
                                  Icons.currency_rupee_rounded,
                                  size: 15.sp,
                                  color: const Color(0xFF16A34A),
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Amount Due',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                  Text(
                                    '₹${widget.totalPaid.toInt()}',
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF16A34A),
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 5.h,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF7ED),
                                  borderRadius: BorderRadius.circular(20.r),
                                  border: Border.all(
                                    color: const Color(0xFFFED7AA),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.hotel_rounded,
                                      size: 12.sp,
                                      color: const Color(0xFFEA580C),
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      'Pay at Hotel',
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
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              FadeTransition(
                opacity: _contentFade,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 15.sp,
                        color: const Color(0xFFEA580C),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Please carry a valid ID proof at the time of check-in. Payment will be collected at the hotel.',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: const Color(0xFFB45309),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 28.h),

              FadeTransition(
                opacity: _contentFade,
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A4B8E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        onPressed: _goHome,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.home_rounded, size: 18.sp),
                            SizedBox(width: 8.w),
                            Text(
                              'Back to Home',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    SizedBox(
                      width: double.infinity,
                      height: 46.h,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: const Color(0xFF1A4B8E).withOpacity(0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        onPressed: _goToBookings,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.book_online_rounded,
                              size: 16.sp,
                              color: const Color(0xFF1A4B8E),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'View My Bookings',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A4B8E),
                              ),
                            ),
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
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 9.h),
      child: Row(
        children: [
          Container(
            width: 34.w,
            height: 34.h,
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, size: 15.sp, color: color),
          ),
          SizedBox(width: 10.w),
          Text(
            label,
            style: TextStyle(fontSize: 12.sp, color: const Color(0xFF6B7280)),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1D2E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(
    height: 1,
    color: const Color(0xFFF0F4F8),
    indent: 16.w,
    endIndent: 16.w,
  );
}
