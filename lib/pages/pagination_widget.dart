import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PaginationWidget extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  const PaginationWidget({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    final pages = _visiblePages();

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),

      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ← Prev
            _NavBtn(
              icon: Icons.chevron_left_rounded,
              enabled: currentPage > 1,
              onTap: () => onPageChanged(currentPage - 1),
            ),
            SizedBox(width: 4.w),

            // First page if not in visible range
            if (pages.first > 1) ...[
              _PageBtn(page: 1, current: currentPage, onTap: onPageChanged),
              SizedBox(width: 4.w),
              if (pages.first > 2) ...[_Ellipsis(), SizedBox(width: 4.w)],
            ],

            // Visible page numbers
            for (final p in pages) ...[
              _PageBtn(page: p, current: currentPage, onTap: onPageChanged),
              SizedBox(width: 4.w),
            ],

            // Last page if not in visible range
            if (pages.last < totalPages) ...[
              if (pages.last < totalPages - 1) ...[
                _Ellipsis(),
                SizedBox(width: 4.w),
              ],
              _PageBtn(
                page: totalPages,
                current: currentPage,
                onTap: onPageChanged,
              ),
              SizedBox(width: 4.w),
            ],

            // → Next
            _NavBtn(
              icon: Icons.chevron_right_rounded,
              enabled: currentPage < totalPages,
              onTap: () => onPageChanged(currentPage + 1),
            ),
          ],
        ),
      ),
    );
  }

  List<int> _visiblePages() {
    const max = 5;
    if (totalPages <= max) return List.generate(totalPages, (i) => i + 1);
    final start = (currentPage - 2).clamp(1, totalPages - max + 1);
    final end = (start + max - 1).clamp(1, totalPages);
    return List.generate(end - start + 1, (i) => start + i);
  }
}

class _PageBtn extends StatelessWidget {
  final int page, current;
  final ValueChanged<int> onTap;
  const _PageBtn({
    required this.page,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = page == current;
    return GestureDetector(
      onTap: active ? null : () => onTap(page),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 36.w,
        height: 36.h,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF1A4B8E) : Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: active ? const Color(0xFF1A4B8E) : const Color(0xFFE2E8F0),
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: const Color(0xFF1A4B8E).withOpacity(0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Center(
          child: Text(
            '$page',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              color: active ? Colors.white : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _NavBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 36.w,
        height: 36.h,
        decoration: BoxDecoration(
          color: enabled ? Colors.white : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: enabled ? const Color(0xFFE2E8F0) : const Color(0xFFF0F4F8),
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Icon(
            icon,
            size: 20.sp,
            color: enabled ? const Color(0xFF1A4B8E) : const Color(0xFFCBD5E1),
          ),
        ),
      ),
    );
  }
}

class _Ellipsis extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 20.w,
    child: Center(
      child: Text(
        '…',
        style: TextStyle(
          fontSize: 14.sp,
          color: const Color(0xFF94A3B8),
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
