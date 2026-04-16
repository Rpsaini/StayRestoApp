import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../hotel_search/domain/entities/hotel_entity.dart';
import '../../../hotel_search/domain/entities/room_entity.dart';
import '../bloc/Booking bloc.dart';
import 'BookingSuccessPage.dart';

class PaymentPage extends StatefulWidget {
  final HotelEntity hotel;
  final RoomEntity room;
  final String checkIn;
  final String checkOut;
  final int guests;

  const PaymentPage({
    super.key,
    required this.hotel,
    required this.room,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();

    context.read<BookingBloc>().add(
      SelectRoom(room: widget.room, hotel: widget.hotel),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  int get _nights {
    try {
      final parts1 = widget.checkIn.split('-');
      final parts2 = widget.checkOut.split('-');
      final d1 = DateTime(
        int.parse(parts1[0]),
        int.parse(parts1[1]),
        int.parse(parts1[2]),
      );
      final d2 = DateTime(
        int.parse(parts2[0]),
        int.parse(parts2[1]),
        int.parse(parts2[2]),
      );
      return d2.difference(d1).inDays.clamp(1, 365);
    } catch (_) {
      return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BookingBloc, BookingState>(
      listener: (context, state) {
        if (state is BookingSuccess) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<BookingBloc>(),
                child: BookingSuccessPage(
                  bookingId: state.bookingId,
                  hotelName: state.hotel.name,
                  roomTypeName: state.room.roomTypeName,
                  checkIn: state.checkIn,
                  checkOut: state.checkOut,
                  guests: state.guests,
                  totalPaid: state.totalPaid,
                ),
              ),
            ),
          );
        }
        if (state is BookingFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FB),
        body: BlocBuilder<BookingBloc, BookingState>(
          builder: (ctx, state) {
            final roomPrice = widget.room.pricePerNight * _nights;
            final taxes = roomPrice * 0.18;
            final total = roomPrice + taxes;

            return CustomScrollView(
              slivers: [
                _buildAppBar(context),
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 120.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSummaryCard(),
                            SizedBox(height: 16.h),
                            _buildPriceCard(roomPrice, taxes, total),
                            SizedBox(height: 16.h),
                            _buildPayOnHotelCard(),
                            SizedBox(height: 16.h),
                            _buildSecurityNote(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: BlocBuilder<BookingBloc, BookingState>(
          builder: (ctx, state) {
            final processing = state is BookingProcessing;
            final roomPrice = widget.room.pricePerNight * _nights;
            final taxes = roomPrice * 0.18;
            final total = roomPrice + taxes;

            return Container(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 28.h),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    margin: EdgeInsets.only(bottom: 10.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: const Color(0xFFFED7AA)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.hotel_rounded,
                          size: 14.sp,
                          color: const Color(0xFFEA580C),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'Pay On Hotel — Payment will be collected at the hotel during check-in.',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: const Color(0xFFB45309),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Amount',
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
                                '₹${total.toInt()}',
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
                                  'at hotel',
                                  style: TextStyle(
                                    fontSize: 10.sp,
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
                          height: 50.h,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: processing
                                  ? const Color(0xFF1A4B8E).withOpacity(0.7)
                                  : const Color(0xFF1A4B8E),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                            ),
                            onPressed: processing
                                ? null
                                : () {
                                    HapticFeedback.lightImpact();
                                    ctx.read<BookingBloc>().add(
                                      ConfirmBooking(
                                        checkIn: widget.checkIn,
                                        checkOut: widget.checkOut,
                                        guests: widget.guests,
                                      ),
                                    );
                                  },
                            child: processing
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 18.w,
                                        height: 18.h,
                                        child: const CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      SizedBox(width: 10.w),
                                      Text(
                                        'Confirming...',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_circle_rounded,
                                        size: 16.sp,
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        'Confirm Booking',
                                        style: TextStyle(
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
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
        'Checkout',
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(36.h),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            children: [
              _step(1, 'Room', true, true),
              _stepLine(true),
              _step(2, 'Review', true, false),
              _stepLine(false),
              _step(3, 'Confirm', false, false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _step(int n, String label, bool active, bool done) {
    return Row(
      children: [
        Container(
          width: 20.w,
          height: 20.h,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: done
                ? Icon(
                    Icons.check_rounded,
                    size: 11.sp,
                    color: const Color(0xFF1A4B8E),
                  )
                : Text(
                    '$n',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: active ? const Color(0xFF1A4B8E) : Colors.white,
                    ),
                  ),
          ),
        ),
        SizedBox(width: 4.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : Colors.white.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _stepLine(bool active) => Expanded(
    child: Container(
      height: 1.5,
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      color: active
          ? Colors.white.withOpacity(0.6)
          : Colors.white.withOpacity(0.2),
    ),
  );

  Widget _buildSummaryCard() {
    final hasImg =
        widget.hotel.frontImageUrl.isNotEmpty &&
        widget.hotel.frontImageUrl.startsWith('http');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A4B8E).withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
            child: SizedBox(
              height: 110.h,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  hasImg
                      ? Image.network(
                          widget.hotel.frontImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imgPh(),
                        )
                      : _imgPh(),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                        stops: const [0.3, 1.0],
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
                          widget.hotel.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 10.sp,
                              color: Colors.white70,
                            ),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: Text(
                                widget.hotel.city,
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: Colors.white70,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    size: 9.sp,
                                    color: const Color(0xFFFBBF24),
                                  ),
                                  SizedBox(width: 2.w),
                                  Text(
                                    widget.hotel.rating.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 9.sp,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
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
          Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(7.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F7FF),
                        borderRadius: BorderRadius.circular(9.r),
                      ),
                      child: Icon(
                        Icons.bed_rounded,
                        size: 16.sp,
                        color: const Color(0xFF1A4B8E),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.room.roomTypeName,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1D2E),
                            ),
                          ),
                          Text(
                            '${widget.guests} guest${widget.guests > 1 ? 's' : ''}  ·  $_nights night${_nights > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Container(height: 1, color: const Color(0xFFF0F4F8)),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: _dateChip(
                        'Check-in',
                        widget.checkIn,
                        Icons.login_rounded,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        '$_nights N',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A4B8E),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: _dateChip(
                        'Check-out',
                        widget.checkOut,
                        Icons.logout_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateChip(String label, String date, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 11.sp, color: const Color(0xFF1A4B8E)),
          SizedBox(width: 5.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9.sp,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
              Text(
                date,
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

  Widget _buildPriceCard(double roomPrice, double taxes, double total) {
    return Container(
      padding: EdgeInsets.all(16.w),
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
          Text(
            'Price Breakdown',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1D2E),
            ),
          ),
          SizedBox(height: 12.h),
          _priceRow(
            '₹${widget.room.pricePerNight.toInt()} × $_nights night${_nights > 1 ? 's' : ''}',
            '₹${roomPrice.toInt()}',
            false,
          ),
          SizedBox(height: 8.h),
          _priceRow('GST (18%)', '₹${taxes.toInt()}', false),
          SizedBox(height: 10.h),
          Container(height: 1, color: const Color(0xFFF0F4F8)),
          SizedBox(height: 10.h),
          _priceRow('Total (Pay at Hotel)', '₹${total.toInt()}', true),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, bool isTotal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 13.sp : 12.sp,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            color: isTotal ? const Color(0xFF1A1D2E) : const Color(0xFF6B7280),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 15.sp : 12.sp,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
            color: isTotal ? const Color(0xFF1A4B8E) : const Color(0xFF374151),
          ),
        ),
      ],
    );
  }

  Widget _buildPayOnHotelCard() {
    return Container(
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
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 12.h),
            child: Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1D2E),
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.fromLTRB(12.w, 0, 12.w, 14.h),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1A4B8E).withOpacity(0.06),
                  const Color(0xFF2563EB).withOpacity(0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: const Color(0xFF1A4B8E).withOpacity(0.18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48.w,
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A4B8E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Icon(
                    Icons.hotel_rounded,
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
                        'Pay On Hotel',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1D2E),
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        'Pay at the hotel during check-in. No online payment required.',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: const Color(0xFF6B7280),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10.w),
                Container(
                  width: 22.w,
                  height: 22.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF1A4B8E),
                      width: 6,
                    ),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Benefits
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 14.h),
            child: Row(
              children: [
                _benefitChip(Icons.no_encryption_rounded, 'No Advance'),
                SizedBox(width: 8.w),
                _benefitChip(Icons.cancel_outlined, 'Free Cancel'),
                SizedBox(width: 8.w),
                _benefitChip(Icons.verified_rounded, 'Instant Confirm'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _benefitChip(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F7FF),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16.sp, color: const Color(0xFF1A4B8E)),
            SizedBox(height: 4.h),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A4B8E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityNote() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.verified_user_rounded,
            size: 16.sp,
            color: const Color(0xFF16A34A),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'Your booking is secured · No payment required right now',
              style: TextStyle(
                fontSize: 11.sp,
                color: const Color(0xFF15803D),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imgPh() => Container(
    color: const Color(0xFFE2E8F0),
    child: Center(
      child: Icon(
        Icons.hotel_rounded,
        size: 40,
        color: const Color(0xFFCBD5E1),
      ),
    ),
  );
}
