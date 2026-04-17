import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:stayresto/injection_container.dart' as di;

import '../../domain/entities/hotel_entity.dart';
import '../../domain/usecases/search_hotels_usecase.dart';
import '../bloc/hotel_search_bloc.dart';
import '../bloc/hotel_search_event.dart';
import '../bloc/hotel_search_state.dart';
import 'Wishlist_bloc.dart';
import 'hotel_listing_page.dart';
import 'hotel_room_page.dart';
import 'hotel_search_result_page.dart' show HotelSearchResultsSliverGroup;
import 'popular_hotels_cubit.dart';
import '../widgets/guest_rooms_sheet.dart';
import '../widgets/image_preview_actions.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final TextEditingController _destCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final GlobalKey _searchResultsKey = GlobalKey();

  DateTime _checkIn = DateTime.now().add(const Duration(days: 1));
  DateTime _checkOut = DateTime.now().add(const Duration(days: 3));
  int _adults = 2;
  int _children = 0;
  int _rooms = 1;
  List<int> _childrenAges = [];
  bool _isScrolled = false;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late AnimationController _shimmerCtrl;

  final _destinations = const [
    {'name': 'Goa', 'emoji': '🏖️', 'tag': 'Beach'},
    {'name': 'Shimla', 'emoji': '🏔️', 'tag': 'Hills'},
    {'name': 'Jaipur', 'emoji': '🏰', 'tag': 'Heritage'},
    {'name': 'Mumbai', 'emoji': '🏙️', 'tag': 'City'},
    {'name': 'Kerala', 'emoji': '🌿', 'tag': 'Nature'},
    {'name': 'Agra', 'emoji': '🕌', 'tag': 'Iconic'},
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _scrollCtrl.addListener(() {
      final s = _scrollCtrl.offset > 10;
      if (s != _isScrolled) setState(() => _isScrolled = s);
    });
  }

  @override
  void dispose() {
    _destCtrl.dispose();
    _scrollCtrl.dispose();
    _fadeCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  String get _greetingLine {
    final h = DateTime.now().hour;
    final part = h < 12
        ? 'Good morning'
        : h < 17
        ? 'Good afternoon'
        : 'Good evening';
    final user = FirebaseAuth.instance.currentUser;
    String? first;
    final dn = user?.displayName?.trim();
    if (dn != null && dn.isNotEmpty) {
      first = dn.split(RegExp(r'\s+')).first;
    } else {
      final em = user?.email;
      if (em != null && em.contains('@')) {
        first = em.split('@').first;
        if (first.isEmpty) first = null;
      }
    }
    if (first != null) return '$part, $first';
    return '$part — where to next?';
  }

  String get _fmtIn => DateFormat('dd MMM').format(_checkIn);
  String get _fmtOut => DateFormat('dd MMM').format(_checkOut);
  String get _dayIn => DateFormat('EEE').format(_checkIn);
  String get _dayOut => DateFormat('EEE').format(_checkOut);
  int get _nights => _checkOut.difference(_checkIn).inDays;
  String get _guestLabel =>
      '$_adults adult${_adults > 1 ? 's' : ''}'
      '${_children > 0 ? ', $_children child${_children > 1 ? 'ren' : ''}' : ''}'
      ' · $_rooms room${_rooms > 1 ? 's' : ''}';

  void _search(BuildContext ctx, HotelSearchBloc bloc) {
    FocusManager.instance.primaryFocus?.unfocus();
    final city = _destCtrl.text.trim();
    if (city.isEmpty) {
      _snack(ctx, 'Please enter a destination 📍');
      return;
    }
    HapticFeedback.lightImpact();
    _go(ctx, bloc, city);
  }

  void _go(BuildContext ctx, HotelSearchBloc bloc, String city) {
    FocusManager.instance.primaryFocus?.unfocus();
    bloc.add(
      SearchHotelsEvent(
        SearchParams(
          location: city,
          checkIn: DateFormat('yyyy-MM-dd').format(_checkIn),
          checkOut: DateFormat('yyyy-MM-dd').format(_checkOut),
          adults: _adults,
          children: _children,
          rooms: _rooms,
          childAges: _children > 0 ? List<int>.from(_childrenAges) : null,
        ),
      ),
    );
  }

  void _scrollToSearchResults() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final anchor = _searchResultsKey.currentContext;
      if (anchor != null) {
        Scrollable.ensureVisible(
          anchor,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          alignment: 0.02,
        );
      }
    });
  }

  void _snack(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: EdgeInsets.all(16.w),
        duration: const Duration(seconds: 2),
      ),
    );
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
        if (_checkOut.isBefore(_checkIn.add(const Duration(days: 1))))
          _checkOut = _checkIn.add(const Duration(days: 1));
      } else {
        _checkOut = picked;
      }
    });
  }

  void _guestSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
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

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<HotelSearchBloc>()),
        BlocProvider(create: (_) => PopularHotelsCubit()..fetch()),
      ],
      child: Builder(
        builder: (ctx) {
          final bloc = ctx.read<HotelSearchBloc>();
          return Scaffold(
            backgroundColor: const Color(0xFFF4F6FB),
            extendBodyBehindAppBar: true,
            appBar: _appBar(ctx),
            body: FadeTransition(
              opacity: _fadeAnim,
              child: BlocListener<HotelSearchBloc, HotelSearchState>(
                listenWhen: (prev, curr) =>
                    curr is HotelSearchLoading ||
                    curr is HotelSearchLoaded ||
                    curr is HotelSearchEmpty ||
                    curr is HotelSearchError,
                listener: (context, state) {
                  _scrollToSearchResults();
                  if (state is HotelSearchLoaded &&
                      state.searchParams != null) {
                    final p = state.searchParams!;
                    setState(() {
                      _destCtrl.text = p.location;
                      final inD = DateTime.tryParse(p.checkIn);
                      final outD = DateTime.tryParse(p.checkOut);
                      if (inD != null) {
                        _checkIn = inD;
                      }
                      if (outD != null) {
                        _checkOut = outD;
                      }
                      _adults = p.adults;
                      _children = p.children;
                      _rooms = p.rooms;
                      _childrenAges = List<int>.from(p.childAges ?? []);
                      while (_childrenAges.length < _children) {
                        _childrenAges.add(5);
                      }
                    });
                  }
                },
                child: RefreshIndicator(
                  color: const Color(0xFF1A4B8E),
                  displacement: 48,
                  onRefresh: () async {
                    HapticFeedback.lightImpact();
                    await ctx.read<PopularHotelsCubit>().fetch();
                  },
                  child: CustomScrollView(
                    controller: _scrollCtrl,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                    SliverToBoxAdapter(child: _hero(ctx, bloc)),
                    SliverToBoxAdapter(child: _promo(ctx)),
                    HotelSearchResultsSliverGroup(anchorKey: _searchResultsKey),
                    SliverToBoxAdapter(child: _destinationsSection(ctx, bloc)),
                    SliverToBoxAdapter(child: _popularSection(ctx)),
                    SliverToBoxAdapter(child: _offers(ctx)),
                    SliverToBoxAdapter(child: SizedBox(height: 40.h)),
                  ],
                ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _appBar(BuildContext ctx) => AppBar(
    backgroundColor: _isScrolled
        ? Colors.white.withOpacity(0.97)
        : Colors.transparent,
    elevation: _isScrolled ? 0.5 : 0,
    surfaceTintColor: Colors.transparent,
    systemOverlayStyle: _isScrolled
        ? SystemUiOverlayStyle.dark
        : SystemUiOverlayStyle.light,
    leading: Padding(
      padding: EdgeInsets.only(left: 16.w, top: 5.h, bottom: 5.h),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: _isScrolled
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        padding: EdgeInsets.all(4.w),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7.r),
          child: Image.asset(
            'assets/images/stayresto_logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.hotel_rounded,
              color: const Color(0xFF1A4B8E),
              size: 18.sp,
            ),
          ),
        ),
      ),
    ),
    leadingWidth: 58.w,
    title: Text(
      'StayResto',
      style: TextStyle(
        fontSize: 17.sp,
        fontWeight: FontWeight.w800,
        color: _isScrolled ? const Color(0xFF1A1D2E) : Colors.white,
        letterSpacing: -0.5,
      ),
    ),
    actions: [
      Padding(
        padding: EdgeInsets.only(right: 8.w),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: const Text(
                    'You are all caught up — no new alerts.',
                  ),
                  backgroundColor: const Color(0xFF1A1D2E),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  margin: EdgeInsets.all(16.w),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            borderRadius: BorderRadius.circular(11.r),
            child: Container(
              width: 36.w,
              height: 36.h,
              margin: EdgeInsets.only(right: 6.w, top: 6.h, bottom: 6.h),
              decoration: BoxDecoration(
                color: _isScrolled
                    ? const Color(0xFFF1F5F9)
                    : Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(11.r),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.notifications_outlined,
                      color: _isScrolled
                          ? const Color(0xFF1A1D2E)
                          : Colors.white,
                      size: 18.sp,
                    ),
                  ),
                  Positioned(
                    top: 7.h,
                    right: 7.w,
                    child: Container(
                      width: 7.w,
                      height: 7.h,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _hero(BuildContext ctx, HotelSearchBloc bloc) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0C2461), Color(0xFF1A4B8E), Color(0xFF1E63C3)],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -40,
            child: Container(
              width: 200.w,
              height: 200.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 50,
            child: Container(
              width: 70.w,
              height: 70.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 28.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _heroHeadline(),
                  SizedBox(height: 20.h),
                  _searchCard(ctx, bloc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroHeadline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _greetingLine,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.88),
            letterSpacing: 0.2,
          ),
        ),
        SizedBox(height: 12.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _heroPill(
                '✨',
                'Best Prices Guaranteed',
                const Color(0xFFF59E0B),
                const Color(0xFFFDE68A),
              ),
              SizedBox(width: 8.w),
              _heroPill(
                '',
                '50K+ Hotels',
                const Color(0xFF10B981),
                const Color(0xFF6EE7B7),
                dot: true,
              ),
              SizedBox(width: 8.w),
              _heroPill(
                '🏨',
                '500+ Cities',
                const Color(0xFF60A5FA),
                const Color(0xFFBAE6FD),
              ),
              SizedBox(width: 8.w),
              _heroPill(
                '⭐',
                '4.8 Rating',
                const Color(0xFFF59E0B),
                const Color(0xFFFDE68A),
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Discover Your ',
                  style: TextStyle(
                    fontSize: 33.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.15,
                    letterSpacing: -1.0,
                  ),
                ),
                TextSpan(
                  text: 'Perfect',
                  style: TextStyle(
                    fontSize: 33.sp,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    letterSpacing: -1.0,
                    foreground: Paint()
                      ..shader = const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFFDE68A)],
                      ).createShader(Rect.fromLTWH(0, 0, 600, 50)),
                  ),
                ),
                TextSpan(
                  text: ' Stay',
                  style: TextStyle(
                    fontSize: 33.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.15,
                    letterSpacing: -1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          'Hotels · Resorts · Boutiques · Villas',
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.white.withOpacity(0.5),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _heroPill(
    String emoji,
    String label,
    Color border,
    Color text, {
    bool dot = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: border.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: border.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot)
            Container(
              width: 6.w,
              height: 6.h,
              decoration: BoxDecoration(color: border, shape: BoxShape.circle),
            )
          else if (emoji.isNotEmpty)
            Text(emoji, style: TextStyle(fontSize: 11.sp)),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchCard(BuildContext ctx, HotelSearchBloc bloc) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 36,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _lbl('Where to?'),
          SizedBox(height: 6.h),
          Container(
            height: 46.h,
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
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.search,
                    textCapitalization: TextCapitalization.words,
                    onSubmitted: (_) => _search(ctx, bloc),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1A1D2E),
                    ),
                    decoration: InputDecoration(
                      hintText: 'City, hotel or destination...',
                      hintStyle: TextStyle(
                        fontSize: 13.sp,
                        color: const Color(0xFF94A3B8),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  ),
                ),
                if (_destCtrl.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _destCtrl.clear();
                      setState(() {});
                    },
                    child: Padding(
                      padding: EdgeInsets.all(10.w),
                      child: Icon(
                        Icons.cancel_rounded,
                        size: 16.sp,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  )
                else
                  SizedBox(width: 12.w),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _lbl('Check-in'),
                    SizedBox(height: 6.h),
                    _dateTile(
                      date: _fmtIn,
                      day: _dayIn,
                      icon: Icons.event_rounded,
                      onTap: () => _pickDate(isIn: true),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _lbl('Check-out'),
                    SizedBox(height: 6.h),
                    _dateTile(
                      date: _fmtOut,
                      day: _dayOut,
                      icon: Icons.event_available_rounded,
                      onTap: () => _pickDate(isIn: false),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Text(
              '$_nights ${_nights == 1 ? 'night' : 'nights'}',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A4B8E),
              ),
            ),
          ),
          SizedBox(height: 14.h),
          _lbl('Guests'),
          SizedBox(height: 6.h),
          GestureDetector(
            onTap: () => _guestSheet(ctx),
            child: Container(
              height: 46.h,
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFE2E8F0)),
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
                      _guestLabel,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1D2E),
                      ),
                    ),
                  ),
                  if (_childrenAges.isNotEmpty)
                    Text(
                      'Ages: ${_childrenAges.join(', ')}',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  SizedBox(width: 6.w),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18.sp,
                    color: const Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),
          BlocBuilder<HotelSearchBloc, HotelSearchState>(
            builder: (_, state) {
              final loading = state is HotelSearchLoading;
              return SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A4B8E),
                    foregroundColor: Colors.white,
                    elevation: loading ? 0 : 3,
                    shadowColor: const Color(0xFF1A4B8E).withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  onPressed: loading ? null : () => _search(ctx, bloc),
                  child: loading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Text(
                              'Searching...',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_rounded, size: 20.sp),
                            SizedBox(width: 8.w),
                            Text(
                              'Search Hotels',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _lbl(String t) => Text(
    t,
    style: TextStyle(
      fontSize: 11.sp,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF94A3B8),
      letterSpacing: 0.2,
    ),
  );

  Widget _dateTile({
    required String date,
    required String day,
    required IconData icon,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 46.h,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14.sp, color: const Color(0xFF1A4B8E)),
          SizedBox(width: 6.w),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
  );

  Widget _promo(BuildContext ctx) => Container(
    margin: EdgeInsets.fromLTRB(18.w, 20.h, 18.w, 0),
    height: 78.h,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
      ),
      borderRadius: BorderRadius.circular(18.r),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF0F766E).withOpacity(0.3),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Row(
      children: [
        SizedBox(width: 18.w),
        Text('🎉', style: TextStyle(fontSize: 28.sp)),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Get 20% OFF your first booking!',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'Use code: STAY20 · Valid till 31 Mar',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.white.withOpacity(0.75),
                ),
              ),
            ],
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              await Clipboard.setData(const ClipboardData(text: 'STAY20'));
              HapticFeedback.mediumImpact();
              if (!ctx.mounted) return;
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: const Text('Code STAY20 copied to clipboard'),
                  backgroundColor: const Color(0xFF0F766E),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  margin: EdgeInsets.all(16.w),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20.r),
            child: Container(
              margin: EdgeInsets.only(right: 14.w),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                'Copy',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F766E),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _destinationsSection(BuildContext ctx, HotelSearchBloc bloc) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18.w, 26.h, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(right: 18.w),
            child: _secHeader('Popular Destinations'),
          ),
          SizedBox(height: 14.h),
          SizedBox(
            height: 96.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _destinations.length,
              separatorBuilder: (_, __) => SizedBox(width: 12.w),
              itemBuilder: (_, i) {
                final d = _destinations[i];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _destCtrl.text = d['name']!;
                      setState(() {});
                      HapticFeedback.lightImpact();
                      _go(ctx, bloc, d['name']!);
                    },
                    borderRadius: BorderRadius.circular(18.r),
                    child: Ink(
                      width: 78.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18.r),
                        border: Border.all(
                          color: const Color(0xFF1A4B8E).withOpacity(0.06),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1A4B8E).withOpacity(0.07),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(d['emoji']!, style: TextStyle(fontSize: 26.sp)),
                          SizedBox(height: 5.h),
                          Text(
                            d['name']!,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1D2E),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            d['tag']!,
                            style: TextStyle(
                              fontSize: 9.sp,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _popularSection(BuildContext ctx) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18.w, 20.h, 18.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BlocBuilder<PopularHotelsCubit, PopularHotelsState>(
            builder: (ctx2, state) {
              return _secHeader(
                'Popular Hotels',

                onSeeAll: state is PopularHotelsLoaded
                    ? () => Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) => HotelListingPage(
                            title: 'Popular Hotels',
                            hotels: state.hotels,
                          ),
                        ),
                      )
                    : null,
              );
            },
          ),

          SizedBox(height: 14.h),
          BlocBuilder<PopularHotelsCubit, PopularHotelsState>(
            builder: (_, state) {
              if (state is PopularHotelsLoading) return _shimmer();
              if (state is PopularHotelsError) return _popularErr(ctx);
              if (state is PopularHotelsLoaded) {
                if (state.hotels.isEmpty) return _popularEmpty();

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: state.hotels.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12.w,
                    mainAxisSpacing: 12.h,
                    mainAxisExtent: 230.h,
                  ),
                  itemBuilder: (_, i) => _PopularCard(
                    hotel: state.hotels[i],
                    onTap: () => Navigator.push(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: ctx.read<WishlistBloc>(),
                          child: HotelRoomPage(hotel: state.hotels[i]),
                        ),
                      ),
                    ),
                  ),
                );
              }
              return _shimmer();
            },
          ),
        ],
      ),
    );
  }

  Widget _shimmer() => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: 6,
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 12.w,
      mainAxisSpacing: 12.h,
      mainAxisExtent: 230.h,
    ),
    itemBuilder: (_, __) => AnimatedBuilder(
      animation: _shimmerCtrl,
      builder: (_, __) {
        final t = _shimmerCtrl.value;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + t * 2, 0),
              end: Alignment(0.2 + t * 2, 0.3),
              colors: const [
                Color(0xFFE2E8F0),
                Color(0xFFF1F5F9),
                Color(0xFFE2E8F0),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    ),
  );

  Widget _popularErr(BuildContext ctx) => Container(
    padding: EdgeInsets.all(18.w),
    decoration: BoxDecoration(
      color: const Color(0xFFFEF2F2),
      borderRadius: BorderRadius.circular(16.r),
    ),
    child: Row(
      children: [
        Icon(
          Icons.wifi_off_rounded,
          color: const Color(0xFFEF4444),
          size: 22.sp,
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Could not load popular hotels',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1D2E),
                ),
              ),
              Text(
                'Check internet connection',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () => ctx.read<PopularHotelsCubit>().fetch(),
          child: Text(
            'Retry',
            style: TextStyle(
              color: const Color(0xFF1A4B8E),
              fontWeight: FontWeight.w700,
              fontSize: 13.sp,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _popularEmpty() => Container(
    padding: EdgeInsets.all(24.w),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(16.r),
    ),
    child: Center(
      child: Text(
        'No popular hotels right now',
        style: TextStyle(fontSize: 13.sp, color: const Color(0xFF9CA3AF)),
      ),
    ),
  );

  Widget _offers(BuildContext ctx) {
    final list = [
      {
        'icon': '🏷️',
        'title': 'Early Bird',
        'sub': 'Book 30 days early,\nsave 25%',
        'color': const Color(0xFF7C3AED),
        'hint':
            'Early-bird rates apply at checkout when you book 30+ days ahead.',
      },
      {
        'icon': '💳',
        'title': 'Pay Later',
        'sub': 'Reserve now,\npay at hotel',
        'color': const Color(0xFF0369A1),
        'hint':
            'Pay-at-property options depend on the hotel — available on select stays.',
      },
      {
        'icon': '🌟',
        'title': 'Earn Points',
        'sub': 'Loyalty rewards\non every stay',
        'color': const Color(0xFFB45309),
        'hint': 'Rewards program coming soon — stay tuned!',
      },
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(18.w, 28.h, 18.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _secHeader('Exclusive Offers'),
          SizedBox(height: 14.h),
          Row(
            children: List.generate(list.length, (i) {
              final o = list[i];
              final c = o['color'] as Color;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: i < list.length - 1 ? 10.w : 0,
                  ),
                  child: Material(
                    color: c.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(16.r),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text(o['hint'] as String),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            margin: EdgeInsets.all(16.w),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16.r),
                      child: Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: c.withOpacity(0.18)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              o['icon'] as String,
                              style: TextStyle(fontSize: 22.sp),
                            ),
                            SizedBox(height: 7.h),
                            Text(
                              o['title'] as String,
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                                color: c,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              o['sub'] as String,
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: const Color(0xFF94A3B8),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _secHeader(String title, {VoidCallback? onSeeAll}) => Row(
    children: [
      Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF1A1D2E),
          letterSpacing: -0.3,
        ),
      ),
      const Spacer(),
      if (onSeeAll != null)
        GestureDetector(
          onTap: onSeeAll,
          child: Text(
            'See all',
            style: TextStyle(
              fontSize: 12.sp,
              color: const Color(0xFF1A4B8E),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
    ],
  );
}

class _PopularCard extends StatelessWidget {
  final HotelEntity hotel;
  final VoidCallback onTap;
  const _PopularCard({required this.hotel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final heroUrl = hotel.resolvedHotelGalleryUrls.isNotEmpty
        ? hotel.resolvedHotelGalleryUrls.first
        : hotel.frontImageUrl;
    final hasImg = heroUrl.isNotEmpty &&
        (heroUrl.startsWith('http://') || heroUrl.startsWith('https://'));
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A4B8E).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => openHotelImagePreview(context, hotel),
              child: SizedBox(
                height: 140.h,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    hasImg
                        ? Image.network(
                            heroUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _ph(),
                            loadingBuilder: (_, child, prog) =>
                                prog == null ? child : _ph(),
                          )
                        : (heroUrl.isNotEmpty
                            ? Image.asset(
                                heroUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _ph(),
                              )
                            : _ph()),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.45),
                            ],
                            stops: const [0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Rating badge
                    Positioned(
                      top: 7.h,
                      right: 7.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 9.sp,
                              color: const Color(0xFFFBBF24),
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              hotel.rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A1D2E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Price
                    Positioned(
                      bottom: 7.h,
                      left: 8.w,
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '₹${hotel.bestPricePerNight.toInt()}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1,
                              ),
                            ),
                            TextSpan(
                              text: '/nt',
                              style: TextStyle(
                                fontSize: 9.sp,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.fromLTRB(9.w, 7.h, 9.w, 8.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hotel.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1D2E),
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 9.sp,
                          color: const Color(0xFF1A4B8E),
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Text(
                            hotel.city.isNotEmpty ? hotel.city : hotel.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9.sp,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 7.h),
                    SizedBox(
                      width: double.infinity,
                      height: 26.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A4B8E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        onPressed: onTap,
                        child: Text(
                          'Book Now',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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

  Widget _ph() => Container(
    color: const Color(0xFFF1F5F9),
    child: Center(
      child: Icon(
        Icons.hotel_rounded,
        size: 26,
        color: const Color(0xFFCBD5E1),
      ),
    ),
  );
}

