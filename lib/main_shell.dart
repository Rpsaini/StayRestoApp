import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stayresto/pages/bookings_page.dart';
import 'package:stayresto/pages/profile_page.dart';
import 'package:stayresto/pages/wishlist_page.dart';

import '../features/hotel_search/presentation/pages/home_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  Key _bookingsKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomePage(),
          const WishlistPage(),
          BookingsPage(key: _bookingsKey),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: _BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            if (index == 2) {
              _bookingsKey = UniqueKey();
            }
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNavBar({required this.currentIndex, required this.onTap});

  static const _items = [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _NavItem(
      icon: Icons.favorite_outline,
      activeIcon: Icons.favorite_rounded,
      label: 'Wishlist',
    ),
    _NavItem(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
      label: 'Bookings',
    ),
    _NavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60.h,
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final active = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 3.h,
                          width: active ? 20.w : 0,
                          margin: EdgeInsets.only(bottom: 4.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A4B8E),
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        ),
                        Icon(
                          active ? item.activeIcon : item.icon,
                          size: 22.sp,
                          color: active
                              ? const Color(0xFF1A4B8E)
                              : const Color(0xFF94A3B8),
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: active
                                ? const Color(0xFF1A4B8E)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
