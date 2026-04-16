import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stayresto/widgets/app_text.dart';

class GuestSelectorField extends StatelessWidget {
  const GuestSelectorField({
    super.key,
    required this.adults,
    required this.children,
    required this.onChanged,
    this.maxAdults = 10,
    this.maxChildren = 10,
  });

  final int adults;
  final int children;
  final void Function(int adults, int children) onChanged;
  final int maxAdults;
  final int maxChildren;

  String get _label {
    final a = '$adults ${adults == 1 ? 'Adult' : 'Adults'}';
    final c = '$children ${children == 1 ? 'Child' : 'Children'}';
    return '$a, $c';
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GuestBottomSheet(
        adults: adults,
        children: children,
        maxAdults: maxAdults,
        maxChildren: maxChildren,
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openSheet(context),
      child: Container(
        height: 46.h,
        decoration: BoxDecoration(
          color: Color(0xFFF2F4F7),
          borderRadius: BorderRadius.circular(14),
          // border: Border.all(color: const Color(0xFFE4E6EF), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Container(
              width: 30.w,
              height: 30.h,
              decoration: BoxDecoration(
                // color: const Color(0xFFEEF1FF),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                Icons.people_alt_rounded,
                size: 18.sp,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                _label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1A1D2E),
                  letterSpacing: 0.1,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }
}

class _GuestBottomSheet extends StatefulWidget {
  const _GuestBottomSheet({
    required this.adults,
    required this.children,
    required this.maxAdults,
    required this.maxChildren,
    required this.onChanged,
  });

  final int adults;
  final int children;
  final int maxAdults;
  final int maxChildren;
  final void Function(int adults, int children) onChanged;

  @override
  State<_GuestBottomSheet> createState() => _GuestBottomSheetState();
}

class _GuestBottomSheetState extends State<_GuestBottomSheet>
    with SingleTickerProviderStateMixin {
  late int _adults;
  late int _children;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _adults = widget.adults;
    _children = widget.children;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _apply() {
    widget.onChanged(_adults, _children);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      alignment: Alignment.bottomCenter,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10.h),
            Container(
              width: 38.w,
              height: 3.h,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E2EE),
                borderRadius: BorderRadius.circular(3.r),
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Container(
                  width: 38.w,
                  height: 38.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF1FF),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.people_alt_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 18.sp,
                  ),
                ),
                SizedBox(width: 10.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.heading(context, "Select Guests"),
                    AppText.small(context, "Choose number of travellers"),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20.h),

            _GuestCounterRow(
              icon: Icons.person_rounded,
              iconColor: Theme.of(context).colorScheme.primary,
              iconBg: const Color(0xFFEEF1FF),
              title: 'Adults',
              subtitle: 'Age 13 or above',
              count: _adults,
              min: 1,
              max: widget.maxAdults,
              onDecrement: () => setState(() => _adults--),
              onIncrement: () => setState(() => _adults++),
            ),

            Padding(
              padding: EdgeInsets.symmetric(vertical: 11.h),
              child: Divider(color: Color(0xFFF0F1F7), thickness: 1.5),
            ),

            _GuestCounterRow(
              icon: Icons.child_care_rounded,
              iconColor: const Color(0xFFFF7043),
              iconBg: const Color(0xFFFFF0EC),
              title: 'Children',
              subtitle: 'Age 2 – 12',
              count: _children,
              min: 0,
              max: widget.maxChildren,
              onDecrement: () => setState(() => _children--),
              onIncrement: () => setState(() => _children++),
            ),

            SizedBox(height: 25.h),

            SizedBox(
              width: double.infinity,
              height: 42.h,
              child: ElevatedButton(
                onPressed: _apply,
                style: ElevatedButton.styleFrom(
                  // backgroundColor: Theme.of(context).colorScheme.primary,
                  // foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Apply  •  $_adults ${_adults == 1 ? 'Adult' : 'Adults'}, '
                  '$_children ${_children == 1 ? 'Child' : 'Children'}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
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

class _GuestCounterRow extends StatelessWidget {
  const _GuestCounterRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.min,
    required this.max,
    required this.onDecrement,
    required this.onIncrement,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final int count;
  final int min;
  final int max;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38.w,
          height: 38.h,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(icon, color: iconColor, size: 22.sp),
        ),
        SizedBox(width: 12.w),

        // Labels
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1D2E),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12.sp, color: Color(0xFF9EA3B8)),
              ),
            ],
          ),
        ),

        Row(
          children: [
            _CounterButton(
              icon: Icons.remove,
              enabled: count > min,
              onTap: () {
                HapticFeedback.lightImpact();
                onDecrement();
              },
            ),
            SizedBox(
              width: 36.w,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Text(
                  '$count',
                  key: ValueKey(count),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1D2E),
                  ),
                ),
              ),
            ),
            _CounterButton(
              icon: Icons.add,
              enabled: count < max,
              onTap: () {
                HapticFeedback.lightImpact();
                onIncrement();
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _CounterButton extends StatelessWidget {
  const _CounterButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 30.w,
        height: 30.h,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFEEF1FF) : const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled ? const Color(0xFFCDD3FC) : const Color(0xFFE8E9EF),
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? const Color(0xFF4F6EF7) : const Color(0xFFCCCED9),
        ),
      ),
    );
  }
}
