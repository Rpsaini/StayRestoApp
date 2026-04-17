import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../domain/usecases/search_hotels_usecase.dart';
import '../bloc/hotel_search_bloc.dart';
import '../bloc/hotel_search_event.dart';
import 'guest_rooms_sheet.dart';

/// Full booking-style form after results (destination, dates, guests, rooms, Search) — like StayResto web.
void showModifyBookingSearchSheet(
  BuildContext context,
  SearchParams params,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _ModifyBookingSearchBody(initial: params),
    ),
  );
}

class _ModifyBookingSearchBody extends StatefulWidget {
  final SearchParams initial;

  const _ModifyBookingSearchBody({required this.initial});

  @override
  State<_ModifyBookingSearchBody> createState() =>
      _ModifyBookingSearchBodyState();
}

class _ModifyBookingSearchBodyState extends State<_ModifyBookingSearchBody> {
  late final TextEditingController _destCtrl;
  late DateTime _checkIn;
  late DateTime _checkOut;
  late int _adults;
  late int _children;
  late List<int> _childrenAges;
  late int _rooms;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _destCtrl = TextEditingController(text: p.location);
    _checkIn = DateTime.tryParse(p.checkIn) ??
        DateTime.now().add(const Duration(days: 1));
    _checkOut = DateTime.tryParse(p.checkOut) ??
        _checkIn.add(const Duration(days: 2));
    if (!_checkOut.isAfter(_checkIn)) {
      _checkOut = _checkIn.add(const Duration(days: 1));
    }
    _adults = p.adults.clamp(1, 8);
    _children = p.children.clamp(0, 6);
    _childrenAges = List<int>.from(p.childAges ?? []);
    while (_childrenAges.length < _children) {
      _childrenAges.add(5);
    }
    _rooms = p.rooms.clamp(1, 8);
  }

  @override
  void dispose() {
    _destCtrl.dispose();
    super.dispose();
  }

  String get _fmtIn => DateFormat('dd MMM').format(_checkIn);
  String get _fmtOut => DateFormat('dd MMM').format(_checkOut);
  String get _dayIn => DateFormat('EEE').format(_checkIn);
  String get _dayOut => DateFormat('EEE').format(_checkOut);
  int get _nights => _checkOut.difference(_checkIn).inDays;

  String get _guestLine {
    final bits = <String>[
      '$_adults adult${_adults > 1 ? 's' : ''}',
      if (_children > 0) '$_children child${_children > 1 ? 'ren' : ''}',
      '$_rooms room${_rooms > 1 ? 's' : ''}',
    ];
    return bits.join(' · ');
  }

  Future<void> _pickDate({required bool isIn}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isIn ? _checkIn : _checkOut,
      firstDate: isIn ? DateTime.now() : _checkIn.add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1A4B8E),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isIn) {
        _checkIn = picked;
        if (_checkOut.isBefore(_checkIn.add(const Duration(days: 1)))) {
          _checkOut = _checkIn.add(const Duration(days: 1));
        }
      } else {
        _checkOut = picked;
      }
    });
  }

  void _guestSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => GuestRoomsSheet(
        adults: _adults,
        children: _children,
        childrenAges: List.from(_childrenAges),
        rooms: _rooms,
        onDone: (a, c, ages, r) => setState(() {
          _adults = a;
          _children = c;
          _childrenAges = ages;
          _rooms = r;
        }),
      ),
    );
  }

  void _submit() {
    final city = _destCtrl.text.trim();
    if (city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a destination'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      );
      return;
    }
    final params = SearchParams(
      location: city,
      checkIn: DateFormat('yyyy-MM-dd').format(_checkIn),
      checkOut: DateFormat('yyyy-MM-dd').format(_checkOut),
      adults: _adults,
      children: _children,
      rooms: _rooms,
      childAges: _children > 0 ? List<int>.from(_childrenAges) : null,
    );
    context.read<HotelSearchBloc>().add(SearchHotelsEvent(params));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 28.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Modify search',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1D2E),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Same options as on stayresto.com/booking',
              style: TextStyle(
                fontSize: 12.sp,
                color: const Color(0xFF94A3B8),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Destination',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
              ),
            ),
            SizedBox(height: 6.h),
            Container(
              height: 48.h,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  SizedBox(width: 12.w),
                  Icon(
                    Icons.location_on_rounded,
                    size: 18.sp,
                    color: const Color(0xFF1A4B8E),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: TextField(
                      controller: _destCtrl,
                      textCapitalization: TextCapitalization.words,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1A1D2E),
                      ),
                      decoration: InputDecoration(
                        hintText: 'City, hotel or area',
                        hintStyle: TextStyle(
                          fontSize: 13.sp,
                          color: const Color(0xFF94A3B8),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Check-in',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      _dateChip(
                        _fmtIn,
                        _dayIn,
                        Icons.event_rounded,
                        () => _pickDate(isIn: true),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Check-out',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      _dateChip(
                        _fmtOut,
                        _dayOut,
                        Icons.event_available_rounded,
                        () => _pickDate(isIn: false),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              '$_nights night${_nights == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A4B8E),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Guests & rooms',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
              ),
            ),
            SizedBox(height: 6.h),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _guestSheet,
                borderRadius: BorderRadius.circular(12.r),
                child: Ink(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 14.h,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.people_alt_rounded,
                          size: 18.sp,
                          color: const Color(0xFF1A4B8E),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            _guestLine,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A1D2E),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: const Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 24.h),
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
                onPressed: _submit,
                child: Text(
                  'Search',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateChip(
    String date,
    String day,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
            child: Row(
              children: [
                Icon(icon, size: 16.sp, color: const Color(0xFF1A4B8E)),
                SizedBox(width: 8.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1D2E),
                      ),
                    ),
                    Text(
                      day,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
