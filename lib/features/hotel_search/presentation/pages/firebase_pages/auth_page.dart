import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'firebase_auth_services.dart';

// import 'firebase_auth_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with TickerProviderStateMixin {
  bool _isLogin = true;
  bool _loading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  String? _errorMsg;
  bool _showResend = false;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);

    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _fadeCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isLogin = !_isLogin;
      _errorMsg = null;
      _showResend = false;
    });
    _slideCtrl.forward(from: 0);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMsg = null;
      _showResend = false;
    });

    AuthResult result;
    if (_isLogin) {
      result = await AuthService.signIn(
        email: _emailCtrl.text,
        password: _passCtrl.text,
      );
    } else {
      result = await AuthService.signUp(
        email: _emailCtrl.text,
        password: _passCtrl.text,
      );
    }

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      if (!_isLogin) {
        _showSnack(result.message, isSuccess: true);
        Future.delayed(const Duration(seconds: 2), _toggle);
      }
    } else {
      setState(() {
        _errorMsg = result.message;
        _showResend = result.needsVerification;
      });
    }
  }

  Future<void> _resendVerification() async {
    setState(() => _loading = true);
    final result = await AuthService.resendVerificationEmail(
      email: _emailCtrl.text,
      password: _passCtrl.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    _showSnack(result.message, isSuccess: result.success);
  }

  Future<void> _forgotPassword() async {
    if (_emailCtrl.text.isEmpty) {
      setState(() => _errorMsg = 'Enter your email first.');
      return;
    }
    setState(() => _loading = true);
    final result = await AuthService.resetPassword(_emailCtrl.text);
    if (!mounted) return;
    setState(() => _loading = false);
    _showSnack(result.message, isSuccess: result.success);
  }

  void _showSnack(String msg, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isSuccess
            ? const Color(0xFF10B981)
            : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: EdgeInsets.all(16.w),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: Stack(
        children: [
          Positioned(
            top: -80.h,
            left: -60.w,
            child: _blob(220.w, const Color(0xFF1A4B8E), 0.12),
          ),
          Positioned(
            top: 80.h,
            right: -40.w,
            child: _blob(160.w, const Color(0xFF0C2461), 0.08),
          ),
          Positioned(
            bottom: -60.h,
            right: -40.w,
            child: _blob(200.w, const Color(0xFF1A4B8E), 0.1),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 48.h),

                    Center(
                      child: Container(
                        width: 64.w,
                        height: 64.w,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0C2461), Color(0xFF1A4B8E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18.r),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1A4B8E).withOpacity(0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'SR',
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 28.h),

                    SlideTransition(
                      position: _slideAnim,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isLogin ? 'Welcome\nBack 👋' : 'Create\nAccount ✨',
                            style: TextStyle(
                              fontSize: 28.sp,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0C2461),
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            _isLogin
                                ? 'Sign in to continue to StayResto'
                                : 'Join StayResto today — it\'s free',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 32.h),

                    SlideTransition(
                      position: _slideAnim,
                      child: Container(
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24.r),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1A4B8E).withOpacity(0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _inputField(
                                controller: _emailCtrl,
                                label: 'Email Address',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return 'Email is required';
                                  if (!RegExp(
                                    r'^[\w-.]+@[\w-]+\.[a-z]{2,}$',
                                  ).hasMatch(v)) {
                                    return 'Enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 14.h),

                              _inputField(
                                controller: _passCtrl,
                                label: 'Password',
                                icon: Icons.lock_outline_rounded,
                                obscure: _obscurePass,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscurePass
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: const Color(0xFF94A3B8),
                                    size: 18.sp,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePass = !_obscurePass,
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return 'Password is required';
                                  if (v.length < 6)
                                    return 'Minimum 6 characters';
                                  return null;
                                },
                              ),

                              if (!_isLogin) ...[
                                SizedBox(height: 14.h),
                                _inputField(
                                  controller: _confirmCtrl,
                                  label: 'Confirm Password',
                                  icon: Icons.lock_outline_rounded,
                                  obscure: _obscureConfirm,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscureConfirm
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: const Color(0xFF94A3B8),
                                      size: 18.sp,
                                    ),
                                    onPressed: () => setState(
                                      () => _obscureConfirm = !_obscureConfirm,
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return 'Please confirm password';
                                    if (v != _passCtrl.text)
                                      return 'Passwords do not match';
                                    return null;
                                  },
                                ),
                              ],

                              if (_isLogin) ...[
                                SizedBox(height: 8.h),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _forgotPassword,
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: const Color(0xFF1A4B8E),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],

                              if (_errorMsg != null) ...[
                                SizedBox(height: 12.h),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 10.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(10.r),
                                    border: Border.all(
                                      color: const Color(0xFFFECACA),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline_rounded,
                                        color: Color(0xFFEF4444),
                                        size: 16,
                                      ),
                                      SizedBox(width: 8.w),
                                      Expanded(
                                        child: Text(
                                          _errorMsg!,
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: const Color(0xFFDC2626),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_showResend) ...[
                                  SizedBox(height: 8.h),
                                  TextButton(
                                    onPressed: _resendVerification,
                                    child: Text(
                                      'Resend verification email',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: const Color(0xFF1A4B8E),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],

                              SizedBox(height: 20.h),

                              SizedBox(
                                width: double.infinity,
                                height: 50.h,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0C2461),
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: const Color(
                                      0xFF0C2461,
                                    ).withOpacity(0.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14.r),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _loading
                                      ? SizedBox(
                                          width: 20.w,
                                          height: 20.w,
                                          child:
                                              const CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.5,
                                              ),
                                        )
                                      : Text(
                                          _isLogin
                                              ? 'Sign In'
                                              : 'Create Account',
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 24.h),

                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isLogin
                                ? "Don't have an account? "
                                : 'Already have an account? ',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          GestureDetector(
                            onTap: _toggle,
                            child: Text(
                              _isLogin ? 'Sign Up' : 'Sign In',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0C2461),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        fontSize: 13.sp,
        color: const Color(0xFF1A1D2E),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 12.sp, color: const Color(0xFF94A3B8)),
        prefixIcon: Icon(icon, size: 18.sp, color: const Color(0xFF94A3B8)),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF8FAFF),
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFF1A4B8E), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        errorStyle: TextStyle(fontSize: 11.sp),
      ),
    );
  }

  Widget _blob(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}
