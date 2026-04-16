import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../features/hotel_search/presentation/pages/firebase_pages/firebase_auth_services.dart';

// import 'firebase_auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? get _user => AuthService.currentUser;

  String get _initials {
    final email = _user?.email ?? '';
    if (email.isEmpty) return 'SR';
    final parts = email.split('@')[0];
    if (parts.length >= 2) {
      return parts.substring(0, 2).toUpperCase();
    }
    return parts.toUpperCase();
  }

  String get _displayName => _user?.displayName ?? 'StayResto User';
  String get _email => _user?.email ?? 'user@stayresto.com';
  bool get _isVerified => _user?.emailVerified ?? false;

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          'Log Out',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0C2461),
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(fontSize: 13.sp, color: const Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 13.sp,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Log Out',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AuthService.signOut();
    }
  }

  Future<void> _resendVerification() async {
    try {
      await _user?.sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Verification email sent!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          margin: EdgeInsets.all(16.w),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not send email. Try again later.'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          margin: EdgeInsets.all(16.w),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _ProfileHeader(
              initials: _initials,
              displayName: _displayName,
              email: _email,
              isVerified: _isVerified,
              onResendVerification: _resendVerification,
            ),
          ),
          SliverToBoxAdapter(child: _MenuSection(onLogout: _signOut)),
          SliverToBoxAdapter(child: SizedBox(height: 40.h)),
        ],
      ),
    );
  }
}

// Profile Header

class _ProfileHeader extends StatelessWidget {
  final String initials;
  final String displayName;
  final String email;
  final bool isVerified;
  final VoidCallback onResendVerification;

  const _ProfileHeader({
    required this.initials,
    required this.displayName,
    required this.email,
    required this.isVerified,
    required this.onResendVerification,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0C2461), Color(0xFF1A4B8E)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 28.h),
          child: Column(
            children: [
              Container(
                width: 72.w,
                height: 72.h,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),

              Text(
                displayName,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4.h),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: isVerified
                          ? const Color(0xFF10B981).withOpacity(0.25)
                          : const Color(0xFFF59E0B).withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isVerified
                              ? Icons.verified_rounded
                              : Icons.warning_amber_rounded,
                          size: 10.sp,
                          color: isVerified
                              ? const Color(0xFF34D399)
                              : const Color(0xFFFBBF24),
                        ),
                        SizedBox(width: 3.w),
                        Text(
                          isVerified ? 'Verified' : 'Unverified',
                          style: TextStyle(
                            fontSize: 9.sp,
                            color: isVerified
                                ? const Color(0xFF34D399)
                                : const Color(0xFFFBBF24),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (!isVerified) ...[
                SizedBox(height: 8.h),
                GestureDetector(
                  onTap: onResendVerification,
                  child: Text(
                    'Tap to resend verification email',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: const Color(0xFFFBBF24),
                      decoration: TextDecoration.underline,
                      decorationColor: const Color(0xFFFBBF24),
                    ),
                  ),
                ),
              ],

              SizedBox(height: 16.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _stat('0', 'Bookings'),
                  _divider(),
                  _stat('0', 'Wishlist'),
                  _divider(),
                  _stat('0', 'Reviews'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String value, String label) => Column(
    children: [
      Text(
        value,
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
      Text(
        label,
        style: TextStyle(fontSize: 11.sp, color: Colors.white.withOpacity(0.7)),
      ),
    ],
  );

  Widget _divider() =>
      Container(width: 1, height: 30.h, color: Colors.white.withOpacity(0.2));
}

class _MenuSection extends StatelessWidget {
  final VoidCallback onLogout;

  const _MenuSection({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Account'),
          SizedBox(height: 8.h),
          _menuCard([
            _MenuItem(
              Icons.person_outline_rounded,
              'Edit Profile',
              () => _comingSoon(context),
            ),
            _MenuItem(
              Icons.lock_outline_rounded,
              'Change Password',
              () => _changePassword(context),
            ),
            _MenuItem(
              Icons.notifications_outlined,
              'Notifications',
              () => _comingSoon(context),
            ),
          ]),
          SizedBox(height: 16.h),
          _sectionLabel('Support'),
          SizedBox(height: 8.h),
          _menuCard([
            _MenuItem(
              Icons.help_outline_rounded,
              'Help & Support',
              () => _comingSoon(context),
            ),
            _MenuItem(
              Icons.privacy_tip_outlined,
              'Privacy Policy',
              () => _comingSoon(context),
            ),
            _MenuItem(
              Icons.info_outline_rounded,
              'About StayResto',
              () => _showAbout(context),
            ),
          ]),
          SizedBox(height: 24.h),

          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFEF4444)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              onPressed: onLogout,
              icon: Icon(
                Icons.logout_rounded,
                color: const Color(0xFFEF4444),
                size: 18.sp,
              ),
              label: Text(
                'Log Out',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Coming soon! 🚀'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1A4B8E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: EdgeInsets.all(16.w),
      ),
    );
  }

  void _changePassword(BuildContext context) {
    final user = AuthService.currentUser;
    if (user == null) return;
    AuthService.resetPassword(user.email!).then((_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password reset email sent!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF10B981),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          margin: EdgeInsets.all(16.w),
        ),
      );
    });
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          'About StayResto',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0C2461),
          ),
        ),
        content: Text(
          'StayResto v1.0.0\n\nYour all-in-one booking experience for stays and restaurants.',
          style: TextStyle(fontSize: 13.sp, color: const Color(0xFF64748B)),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0C2461),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 12.sp,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF94A3B8),
      letterSpacing: 0.5,
    ),
  );

  Widget _menuCard(List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A4B8E).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isLast = i == items.length - 1;
          return Column(
            children: [
              ListTile(
                leading: Container(
                  width: 36.w,
                  height: 36.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    item.icon,
                    size: 18.sp,
                    color: const Color(0xFF1A4B8E),
                  ),
                ),
                title: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1D2E),
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14.sp,
                  color: const Color(0xFF94A3B8),
                ),
                onTap: item.onTap,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14.w,
                  vertical: 4.h,
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 62.w,
                  color: const Color(0xFFF0F4F8),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuItem(this.icon, this.label, this.onTap);
}
