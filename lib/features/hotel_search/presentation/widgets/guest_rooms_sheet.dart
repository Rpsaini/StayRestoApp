import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Guests, children (with ages), and rooms — same controls as the StayResto web booking form.
class GuestRoomsSheet extends StatefulWidget {
  final int adults;
  final int children;
  final List<int> childrenAges;
  final int rooms;
  final void Function(int adults, int children, List<int> ages, int rooms) onDone;

  const GuestRoomsSheet({
    super.key,
    required this.adults,
    required this.children,
    required this.childrenAges,
    required this.rooms,
    required this.onDone,
  });

  @override
  State<GuestRoomsSheet> createState() => _GuestRoomsSheetState();
}

class _GuestRoomsSheetState extends State<GuestRoomsSheet> {
  late int _a, _c, _r;
  late List<int> _ages;

  @override
  void initState() {
    super.initState();
    _a = widget.adults;
    _c = widget.children;
    _r = widget.rooms.clamp(1, 8);
    _ages = List.from(widget.childrenAges);
    while (_ages.length < _c) {
      _ages.add(5);
    }
  }

  Future<void> _showAgePicker(int idx) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ChildAgeDialog(
        childNumber: idx + 1,
        initialAge: idx < _ages.length ? _ages[idx] : 5,
        onConfirm: (age) => setState(() {
          if (idx < _ages.length) {
            _ages[idx] = age;
          } else {
            _ages.add(age);
          }
        }),
      ),
    );
  }

  Future<void> _incChildren() async {
    setState(() {
      _c++;
      _ages.add(5);
    });
    await _showAgePicker(_c - 1);
  }

  void _decChildren() {
    if (_c > 0) {
      setState(() {
        _c--;
        if (_ages.length > _c) _ages.removeAt(_c);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.fromLTRB(22.w, 12.h, 22.w, 36.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 18.h),
          Text(
            'Guests & rooms',
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1D2E),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Adults, children, ages, and number of rooms',
            style: TextStyle(fontSize: 12.sp, color: const Color(0xFF94A3B8)),
          ),
          SizedBox(height: 24.h),
          _row(
            Icons.person_rounded,
            const Color(0xFFEFF6FF),
            const Color(0xFF1A4B8E),
            'Adults',
            'Age 13+',
            _a,
            _a > 1 ? () => setState(() => _a--) : null,
            _a < 8 ? () => setState(() => _a++) : null,
          ),
          Container(
            height: 1,
            color: const Color(0xFFF0F4F8),
            margin: EdgeInsets.symmetric(vertical: 16.h),
          ),
          _row(
            Icons.child_care_rounded,
            const Color(0xFFFFF7ED),
            const Color(0xFFF59E0B),
            'Children',
            'Ages 2–12',
            _c,
            _c > 0 ? _decChildren : null,
            _c < 6 ? _incChildren : null,
          ),
          if (_c > 0) ...[
            SizedBox(height: 14.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.child_friendly_rounded,
                        size: 14.sp,
                        color: const Color(0xFFF59E0B),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'Children ages',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFB45309),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Tap to edit',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 6.h,
                    children: List.generate(_c, (i) {
                      final age = i < _ages.length ? _ages[i] : 5;
                      return GestureDetector(
                        onTap: () => _showAgePicker(i),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(color: const Color(0xFFF59E0B)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Child ${i + 1}',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                '·',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                '$age yrs',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFB45309),
                                ),
                              ),
                              SizedBox(width: 4.w),
                              Icon(
                                Icons.edit_rounded,
                                size: 10.sp,
                                color: const Color(0xFFF59E0B),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
          Container(
            height: 1,
            color: const Color(0xFFF0F4F8),
            margin: EdgeInsets.symmetric(vertical: 16.h),
          ),
          _row(
            Icons.meeting_room_rounded,
            const Color(0xFFF0FDF4),
            const Color(0xFF15803D),
            'Rooms',
            'Number of rooms',
            _r,
            _r > 1 ? () => setState(() => _r--) : null,
            _r < 8 ? () => setState(() => _r++) : null,
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
              onPressed: () {
                widget.onDone(_a, _c, List.from(_ages.take(_c)), _r);
                Navigator.pop(context);
              },
              child: Text(
                'Done · $_r room${_r > 1 ? 's' : ''} · $_a adult${_a > 1 ? 's' : ''}'
                '${_c > 0 ? ', $_c child${_c > 1 ? 'ren' : ''}' : ''}',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(
    IconData icon,
    Color bg,
    Color ic,
    String title,
    String sub,
    int count,
    VoidCallback? dec,
    VoidCallback? inc,
  ) {
    return Row(
      children: [
        Container(
          width: 46.w,
          height: 46.h,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(13.r),
          ),
          child: Icon(icon, size: 22.sp, color: ic),
        ),
        SizedBox(width: 14.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1D2E),
              ),
            ),
            Text(
              sub,
              style: TextStyle(fontSize: 11.sp, color: const Color(0xFF94A3B8)),
            ),
          ],
        ),
        const Spacer(),
        _btn(Icons.remove_rounded, dec),
        SizedBox(width: 16.w),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 19.sp,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1A1D2E),
          ),
        ),
        SizedBox(width: 16.w),
        _btn(Icons.add_rounded, inc),
      ],
    );
  }

  Widget _btn(IconData icon, VoidCallback? fn) => GestureDetector(
    onTap: fn,
    child: Container(
      width: 36.w,
      height: 36.h,
      decoration: BoxDecoration(
        color: fn != null ? const Color(0xFF1A4B8E) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Icon(
        icon,
        size: 16.sp,
        color: fn != null ? Colors.white : const Color(0xFFCBD5E1),
      ),
    ),
  );
}

class _ChildAgeDialog extends StatefulWidget {
  final int childNumber;
  final int initialAge;
  final void Function(int) onConfirm;

  const _ChildAgeDialog({
    required this.childNumber,
    required this.initialAge,
    required this.onConfirm,
  });

  @override
  State<_ChildAgeDialog> createState() => _ChildAgeDialogState();
}

class _ChildAgeDialogState extends State<_ChildAgeDialog> {
  late int _age;

  @override
  void initState() {
    super.initState();
    _age = widget.initialAge;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 28.w),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56.w,
              height: 56.h,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(
                Icons.child_care_rounded,
                size: 28.sp,
                color: const Color(0xFFF59E0B),
              ),
            ),
            SizedBox(height: 14.h),
            Text(
              'Child ${widget.childNumber} age',
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1D2E),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'How old is this child?',
              style: TextStyle(fontSize: 12.sp, color: const Color(0xFF94A3B8)),
            ),
            SizedBox(height: 20.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Column(
                children: [
                  Text(
                    '$_age',
                    style: TextStyle(
                      fontSize: 42.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFF59E0B),
                      height: 1,
                    ),
                  ),
                  Text(
                    'years old',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              height: 44.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 13,
                separatorBuilder: (_, __) => SizedBox(width: 8.w),
                itemBuilder: (_, age) {
                  final sel = age == _age;
                  return GestureDetector(
                    onTap: () => setState(() => _age = age),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 40.w,
                      height: 40.h,
                      decoration: BoxDecoration(
                        color: sel
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: sel
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: sel
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFF59E0B).withOpacity(0.3),
                                  blurRadius: 8,
                                ),
                              ]
                            : [],
                      ),
                      child: Center(
                        child: Text(
                          '$age',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: sel ? Colors.white : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
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
                onPressed: () {
                  widget.onConfirm(_age);
                  Navigator.pop(context);
                },
                child: Text(
                  'Confirm age $_age',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
