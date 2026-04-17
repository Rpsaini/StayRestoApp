import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../hotel_search/domain/entities/hotel_entity.dart';
import '../../../hotel_search/domain/entities/room_entity.dart';
import '../bloc/Booking bloc.dart';
import '../widgets/image_preview_actions.dart';
import 'BookingSuccessPage.dart';

/// Default food packages (same rates as StayResto web fallback when API list is absent).
class _FoodPackageOption {
  final String id;
  final String title;
  final String description;
  final double adultPerNight;
  final double childPerNight;

  const _FoodPackageOption({
    required this.id,
    required this.title,
    required this.description,
    required this.adultPerNight,
    required this.childPerNight,
  });
}

const _kFoodPackages = <_FoodPackageOption>[
  _FoodPackageOption(
    id: 'none',
    title: 'No Food Package',
    description: '',
    adultPerNight: 0,
    childPerNight: 0,
  ),
  _FoodPackageOption(
    id: 'breakfast',
    title: 'Breakfast Only',
    description: 'Continental breakfast included',
    adultPerNight: 500,
    childPerNight: 250,
  ),
  _FoodPackageOption(
    id: 'breakfast_lunch',
    title: 'Breakfast + Lunch',
    description: 'Continental breakfast and lunch included',
    adultPerNight: 1200,
    childPerNight: 600,
  ),
  _FoodPackageOption(
    id: 'breakfast_dinner',
    title: 'Breakfast + Dinner',
    description: 'Continental breakfast and dinner included',
    adultPerNight: 1500,
    childPerNight: 750,
  ),
  _FoodPackageOption(
    id: 'full_board',
    title: 'Full Board (All Meals)',
    description: 'Breakfast, lunch, and dinner included',
    adultPerNight: 2500,
    childPerNight: 1250,
  ),
];

const _kExtraBedAdultDefault = 1000.0;
const _kExtraBedChildDefault = 500.0;
const _kGstRate = 0.18;

/// Values sent as `payment_type` when confirming (API / StayResto-style).
const _kPaymentPayAtHotel = 'pay_on_hotel';
const _kPaymentAdvance = 'advance_payment';
/// Property requires prepay only (`hotel.paymentType == full_payment`).
const _kPaymentFullPayment = 'full_payment';

const _kArrivalTimes = <String>[
  '',
  '12:00 PM',
  '1:00 PM',
  '2:00 PM',
  '3:00 PM',
  '4:00 PM',
  '5:00 PM',
  '6:00 PM',
  '7:00 PM',
  '8:00 PM',
  '9:00 PM',
  '10:00 PM',
  '11:00 PM',
];

class PaymentPage extends StatefulWidget {
  final HotelEntity hotel;
  final RoomEntity room;
  final String checkIn;
  final String checkOut;
  final int guests;
  final int adults;
  final int children;
  final int rooms;
  final List<int>? childAges;

  /// When set with [foodChildAgeMax], child food/extra-bed-kid charges use only
  /// children in this age range (matches web `age_definition`).
  final int? foodChildAgeMin;
  final int? foodChildAgeMax;

  const PaymentPage({
    super.key,
    required this.hotel,
    required this.room,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    this.adults = 0,
    this.children = 0,
    this.rooms = 1,
    this.childAges,
    this.foodChildAgeMin,
    this.foodChildAgeMax,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _guestDetailsKey = GlobalKey();
  final _scrollController = ScrollController();
  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  late int _selectedRoomIndex;
  late RoomEntity _selectedRoom;

  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _specialCtrl;
  late final TextEditingController _affiliateCtrl;

  String _foodPackageId = 'none';
  bool _extraBedAdult = false;
  bool _extraBedKids = false;
  bool _carRental = false;
  bool _paperless = true;
  bool _bookingForSelf = true;
  bool _travelingForWork = false;
  String _arrivalTime = '';
  String _country = 'India';
  String _phoneCode = '+91';

  double _extraBedAdultRate = _kExtraBedAdultDefault;
  double _extraBedChildRate = _kExtraBedChildDefault;

  List<RoomEntity> get _roomsList {
    final list = widget.hotel.availableRooms;
    if (list.isNotEmpty) return list;
    return [widget.room];
  }

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController();
    _lastNameCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _specialCtrl = TextEditingController();
    _affiliateCtrl = TextEditingController();

    final rooms = _roomsList;
    _selectedRoomIndex = rooms.indexWhere((r) => r.id == widget.room.id);
    if (_selectedRoomIndex < 0) _selectedRoomIndex = 0;
    _selectedRoom = rooms[_selectedRoomIndex];

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BookingBloc>().add(
            SelectRoom(room: _selectedRoom, hotel: widget.hotel),
          );
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _scrollController.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _phoneFocus.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _specialCtrl.dispose();
    _affiliateCtrl.dispose();
    super.dispose();
  }

  int get _adultsEffective =>
      widget.adults > 0
          ? widget.adults
          : (widget.guests >= 1 ? widget.guests : 2);

  int get _childrenEffective => widget.children;

  int get _roomsEffective => widget.rooms >= 1 ? widget.rooms : 1;

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

  int _chargeableChildrenForFood() {
    if (_childrenEffective <= 0) return 0;
    final minA = widget.foodChildAgeMin;
    final maxA = widget.foodChildAgeMax;
    if (minA == null || maxA == null) return _childrenEffective;
    final ages = widget.childAges;
    if (ages == null || ages.isEmpty) return 0;
    return ages.where((a) => a >= minA && a <= maxA).length;
  }

  int _chargeableChildrenForExtraBed() => _chargeableChildrenForFood();

  _FoodPackageOption? _selectedFoodDef() {
    for (final p in _kFoodPackages) {
      if (p.id == _foodPackageId) return p;
    }
    return _kFoodPackages.first;
  }

  /// Room tariff before tax (all rooms × nights).
  double _roomSubtotal(RoomEntity r) =>
      r.pricePerNight * _nights * _roomsEffective;

  double _foodAdultTotal(_FoodPackageOption pkg) {
    if (pkg.id == 'none') return 0;
    return pkg.adultPerNight *
        _adultsEffective *
        _nights *
        _roomsEffective;
  }

  double _foodChildTotal(_FoodPackageOption pkg) {
    if (pkg.id == 'none') return 0;
    final c = _chargeableChildrenForFood();
    return pkg.childPerNight * c * _nights * _roomsEffective;
  }

  double _extraBedAdultTotal() {
    if (!_extraBedAdult) return 0;
    return _extraBedAdultRate * _nights * _roomsEffective;
  }

  double _extraBedKidsTotal() {
    if (!_extraBedKids) return 0;
    final c = _chargeableChildrenForExtraBed();
    return _extraBedChildRate * c * _nights * _roomsEffective;
  }

  String _effectivePaymentMethod(BookingState state) {
    if (state is BookingRoomSelected) return state.paymentMethod;
    if (state is BookingProcessing) return state.paymentMethod;
    return _kPaymentPayAtHotel;
  }

  /// Search API: `booking_payment_info.payment_plan` per room, or hotel `payment_type`.
  bool _requiresFullOnlinePayment() =>
      _selectedRoom.requiresFullOnlinePayment ||
      widget.hotel.paymentType == _kPaymentFullPayment;

  bool _isPayOnlineMethod(String method) =>
      method == _kPaymentAdvance || method == _kPaymentFullPayment;

  /// Uses room `gst_percentage`, then hotel `gst_percentage`, else 18% default.
  double get _effectiveGstRate {
    final pct = _selectedRoom.gstPercentage ?? widget.hotel.gstPercentage;
    if (pct != null && pct > 0) return (pct / 100.0).clamp(0.0, 0.5);
    return _kGstRate;
  }

  ({double subtotal, double gst, double total}) _totals() {
    final pkg = _selectedFoodDef()!;
    final room = _roomSubtotal(_selectedRoom);
    final foodA = _foodAdultTotal(pkg);
    final foodC = _foodChildTotal(pkg);
    final exA = _extraBedAdultTotal();
    final exC = _extraBedKidsTotal();
    final sub = room + foodA + foodC + exA + exC;
    final gstRate = _effectiveGstRate;
    final gst = sub * gstRate;
    return (subtotal: sub, gst: gst, total: sub + gst);
  }

  Future<void> _openDirections() async {
    final parts = <String>[
      widget.hotel.address,
      widget.hotel.city,
    ].where((s) => s.trim().isNotEmpty).join(', ');
    if (parts.isEmpty) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(parts)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _selectRoom(int index) {
    if (index < 0 || index >= _roomsList.length) return;
    setState(() {
      _selectedRoomIndex = index;
      _selectedRoom = _roomsList[index];
    });
    context.read<BookingBloc>().add(
          SelectRoom(room: _selectedRoom, hotel: widget.hotel),
        );
  }

  void _scrollGuestDetailsIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _guestDetailsKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          alignment: 0.12,
        );
      }
    });
  }

  void _attemptCompleteBooking() {
    final fn = _firstNameCtrl.text.trim();
    final ln = _lastNameCtrl.text.trim();
    final ph = _phoneCtrl.text.trim();

    if (fn.isEmpty || ln.isEmpty || ph.isEmpty) {
      _formKey.currentState?.validate();
      _scrollGuestDetailsIntoView();
      if (fn.isEmpty) {
        _firstNameFocus.requestFocus();
      } else if (ln.isEmpty) {
        _lastNameFocus.requestFocus();
      } else {
        _phoneFocus.requestFocus();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please fill first name, last name, and mobile number in Your details.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFEA580C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      _scrollGuestDetailsIntoView();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fix the highlighted fields in Your details.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFEA580C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      );
      return;
    }

    _showBookingConfirmationDialog();
  }

  Future<void> _showBookingConfirmationDialog() async {
    final bill = _totals();
    final blocState = context.read<BookingBloc>().state;
    final payMethod = _effectivePaymentMethod(blocState);
    final paymentLabel = payMethod == _kPaymentFullPayment
        ? 'Full payment online'
        : (payMethod == _kPaymentAdvance
            ? 'Advance payment'
            : 'Pay at hotel');
    final email = _emailCtrl.text.trim();
    final guestSummary =
        '$_adultsEffective adult${_adultsEffective == 1 ? '' : 's'}'
        '${_childrenEffective > 0 ? ', $_childrenEffective child${_childrenEffective == 1 ? '' : 'ren'}' : ''}'
        ' · $_roomsEffective room${_roomsEffective == 1 ? '' : 's'}';

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            'Confirm booking',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1D2E),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _confirmDialogRow('Hotel', widget.hotel.name),
                _confirmDialogRow('Room', _selectedRoom.roomTypeName),
                _confirmDialogRow('Check-in', widget.checkIn),
                _confirmDialogRow('Check-out', widget.checkOut),
                _confirmDialogRow('Guests', guestSummary),
                _confirmDialogRow('Guest', '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}'),
                _confirmDialogRow('Mobile', '$_phoneCode ${_phoneCtrl.text.trim()}'),
                if (email.isNotEmpty) _confirmDialogRow('Email', email),
                _confirmDialogRow('Total (incl. GST)', _rupee(bill.total)),
                _confirmDialogRow('Payment', paymentLabel),
                SizedBox(height: 14.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Text(
                    'Booking details will be sent to your email'
                    '${email.isNotEmpty ? ' ($email)' : ''} with your login '
                    'username and password.',
                    style: TextStyle(
                      fontSize: 12.sp,
                      height: 1.45,
                      color: const Color(0xFF1E40AF),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: Text(
                'Back',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1A4B8E),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: Text(
                'Confirm',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      if (!(_formKey.currentState?.validate() ?? false)) {
        _scrollGuestDetailsIntoView();
        return;
      }
      _submitBooking();
    }
  }

  Widget _confirmDialogRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1D2E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitBooking() {
    final t = _totals();
    final pkg = _selectedFoodDef()!;
    context.read<BookingBloc>().add(
          ConfirmBooking(
            hotelId: widget.hotel.id,
            roomId: _selectedRoom.id,
            checkIn: widget.checkIn,
            checkOut: widget.checkOut,
            adults: _adultsEffective,
            children: _childrenEffective,
            rooms: _roomsEffective,
            childAges: widget.childAges,
            totalAmount: t.total,
            selectedRoomIndex: _selectedRoomIndex,
            foodPackage: pkg.id,
            extraBedAdult: _extraBedAdult,
            extraBedKids: _extraBedKids,
            carRentalInterest: _carRental,
            specialRequests: _specialCtrl.text.trim(),
            arrivalTime: _arrivalTime,
            firstName: _firstNameCtrl.text.trim(),
            lastName: _lastNameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            country: _country,
            phoneCountryCode: _phoneCode,
            phoneNumber: _phoneCtrl.text.trim(),
            paperlessConfirmation: _paperless,
            affiliateCode: _affiliateCtrl.text.trim(),
            bookingForSelf: _bookingForSelf,
            travelingForWork: _travelingForWork,
          ),
        );
  }

  String _rupee(num n) => '₹${n.round()}';

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
            final bill = _totals();
            final paymentMethod = _effectivePaymentMethod(state);
            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                _buildAppBar(context),
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 120.h),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTopHeroAndStayDatesCard(),
                              SizedBox(height: 14.h),
                              _buildHotelHeader(),
                              SizedBox(height: 14.h),
                              if (_roomsList.length > 1) ...[
                                _sectionTitle('Choose your room'),
                                SizedBox(height: 8.h),
                                _buildRoomSelector(),
                                SizedBox(height: 16.h),
                              ],
                              _buildSummaryCard(),
                              SizedBox(height: 16.h),
                              _buildRoomDetailsPanel(),
                              SizedBox(height: 16.h),
                              _buildFoodSection(),
                              SizedBox(height: 16.h),
                              _buildExtraBedSection(),
                              SizedBox(height: 16.h),
                              _buildAddOnsSection(),
                              SizedBox(height: 16.h),
                              _buildGuestDetailsSection(),
                              SizedBox(height: 16.h),
                              _buildOptionalQuestionsSection(),
                              SizedBox(height: 16.h),
                              _buildPriceCard(bill, paymentMethod),
                              SizedBox(height: 16.h),
                              _buildPaymentMethodCard(paymentMethod),
                              SizedBox(height: 16.h),
                              _buildSecurityNote(paymentMethod),
                              SizedBox(height: 16.h),
                              _buildCollapsibleInfo(),
                            ],
                          ),
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
            final bill = _totals();
            final payMethod = _effectivePaymentMethod(state);
            final advance = _isPayOnlineMethod(payMethod);
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
                      color: advance
                          ? const Color(0xFFEFF6FF)
                          : const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: advance
                            ? const Color(0xFFBFDBFE)
                            : const Color(0xFFFED7AA),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          advance
                              ? Icons.payments_rounded
                              : Icons.hotel_rounded,
                          size: 14.sp,
                          color: advance
                              ? const Color(0xFF1D4ED8)
                              : const Color(0xFFEA580C),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            advance
                                ? (payMethod == _kPaymentFullPayment
                                    ? 'Full payment required — pay ${_rupee(bill.total)} online to confirm.'
                                    : 'Advance payment — pay ${_rupee(bill.total)} online to confirm this booking.')
                                : 'Pay at hotel — no online payment required now.',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: advance
                                  ? const Color(0xFF1E40AF)
                                  : const Color(0xFFB45309),
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
                            'Total',
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
                                _rupee(bill.total),
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
                                  'incl. GST',
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
                                    _attemptCompleteBooking();
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
                                        'Submitting...',
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
                                        advance
                                            ? (payMethod == _kPaymentFullPayment
                                                ? 'Pay now & confirm'
                                                : 'Pay & complete booking')
                                            : 'Complete booking',
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
                  SizedBox(height: 6.h),
                  Text(
                    'By booking, you agree to the property terms and privacy policy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: const Color(0xFF94A3B8),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(
        t,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1A1D2E),
        ),
      );

  Widget _sectionNote(String t) => Padding(
        padding: EdgeInsets.only(bottom: 8.h),
        child: Text(
          t,
          style: TextStyle(
            fontSize: 11.sp,
            color: const Color(0xFF64748B),
            height: 1.4,
          ),
        ),
      );

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
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
        child: child,
      );

  Widget _buildHotelHeader() {
    final r = _selectedRoom;
    final perNight = r.pricePerNight;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.hotel.name,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 4.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  [
                    widget.hotel.address,
                    widget.hotel.city,
                  ].where((s) => s.trim().isNotEmpty).join(', '),
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: const Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _openDirections,
                icon: Icon(Icons.map_rounded, size: 16.sp),
                label: Text('Directions', style: TextStyle(fontSize: 11.sp)),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Text(
                '${_rupee(perNight)} / night',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF059669),
                ),
              ),
              SizedBox(width: 12.w),
              if (widget.hotel.availableRoomsCount > 0)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    '${widget.hotel.availableRoomsCount} rooms available',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1D4ED8),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoomSelector() {
    return SizedBox(
      height: 132.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _roomsList.length,
        separatorBuilder: (_, __) => SizedBox(width: 10.w),
        itemBuilder: (context, i) {
          final r = _roomsList[i];
          final sel = i == _selectedRoomIndex;
          final photoCount = r.resolvedGalleryUrls.length;
          final showRoomAlbum = photoCount > 0 ||
              widget.hotel.resolvedHotelGalleryUrls.isNotEmpty ||
              widget.hotel.frontImageUrl.trim().isNotEmpty;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 148.w,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: sel
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFE2E8F0),
                width: sel ? 2 : 1,
              ),
              boxShadow: [
                if (sel)
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(12.r)),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _selectRoom(i),
                            child: _roomTileImage(_roomThumbUrl(r)),
                          ),
                        ),
                        if (showRoomAlbum)
                          Positioned(
                            top: 6.h,
                            right: 6.w,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _openRoomGallery(r),
                                borderRadius: BorderRadius.circular(8.r),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                    vertical: 3.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.55),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.photo_library_outlined,
                                        size: 12.sp,
                                        color: Colors.white,
                                      ),
                                      if (photoCount > 0) ...[
                                        SizedBox(width: 3.w),
                                        Text(
                                          '$photoCount',
                                          style: TextStyle(
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _selectRoom(i),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(12.r),
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(8.w, 6.h, 8.w, 8.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.roomTypeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            '${_rupee(r.pricePerNight)}/night',
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                          Text(
                            'Tap image to select · album for photos',
                            style: TextStyle(
                              fontSize: 8.sp,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// First room image, or hotel hero image if the room has no URLs.
  String _roomThumbUrl(RoomEntity r) {
    final urls = r.resolvedGalleryUrls;
    if (urls.isNotEmpty) return urls.first;
    return widget.hotel.frontImageUrl.trim();
  }

  Widget _roomTileImage(String url) {
    final t = url.trim();
    if (t.isEmpty) return _imgPh();
    final net =
        t.startsWith('http://') || t.startsWith('https://');
    if (net) {
      return Image.network(
        t,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _imgPh(),
        loadingBuilder: (_, child, prog) =>
            prog == null ? child : _imgPh(),
      );
    }
    return Image.asset(
      t,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => _imgPh(),
    );
  }

  void _openRoomGallery(RoomEntity room) =>
      openRoomImagePreview(context, room, hotel: widget.hotel);

  void _openHotelGallery() => openHotelImagePreview(context, widget.hotel);

  Widget _buildRoomDetailsPanel() {
    final r = _selectedRoom;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Room details'),
          if (_roomsEffective > 1)
            _sectionNote(
              "You're booking $_roomsEffective rooms of this type; room "
              'subtotal includes all rooms.',
            ),
          Text(
            r.roomTypeName,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1D2E),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Guests: $_adultsEffective adult${_adultsEffective == 1 ? '' : 's'}'
            '${_childrenEffective > 0 ? ', $_childrenEffective child${_childrenEffective == 1 ? '' : 'ren'}' : ''}'
            '${widget.childAges != null && widget.childAges!.isNotEmpty ? ' (${widget.childAges!.join(', ')} yr)' : ''}',
            style: TextStyle(
              fontSize: 11.sp,
              color: const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodSection() {
    final pkg = _selectedFoodDef()!;
    final chargeable = _chargeableChildrenForFood();
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Food packages'),
          _sectionNote(
            'Select one package. Formula: (adult rate × adults + child rate × '
            'chargeable children) × nights × rooms.',
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(10.w),
            margin: EdgeInsets.only(bottom: 10.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(10.r),
              border: const Border(
                left: BorderSide(color: Color(0xFF2563EB), width: 3),
              ),
            ),
            child: Text(
              'Guests: $_adultsEffective adults · $_childrenEffective children'
              '${widget.foodChildAgeMin != null && widget.foodChildAgeMax != null ? ' (food rate for ages ${widget.foodChildAgeMin}–${widget.foodChildAgeMax}: $chargeable)' : ''}'
              ' · $_nights night${_nights == 1 ? '' : 's'} · $_roomsEffective room${_roomsEffective == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
                height: 1.35,
              ),
            ),
          ),
          ..._kFoodPackages.where((p) => p.id != 'none').map((p) {
            final sel = _foodPackageId == p.id;
            final total = _foodAdultTotal(p) + _foodChildTotal(p);
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: InkWell(
                onTap: () => setState(() => _foodPackageId = p.id),
                borderRadius: BorderRadius.circular(12.r),
                child: Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: sel
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFE2E8F0),
                      width: sel ? 2 : 1,
                    ),
                    color: sel
                        ? const Color(0xFFEFF6FF)
                        : Colors.white,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        sel
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        size: 22.sp,
                        color: sel
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF94A3B8),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.title,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            if (p.description.isNotEmpty)
                              Text(
                                p.description,
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            Text(
                              'Adults ${_rupee(p.adultPerNight)}/night · '
                              'Children ${_rupee(p.childPerNight)}/night',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _rupee(total),
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          InkWell(
            onTap: () => setState(() => _foodPackageId = 'none'),
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: _foodPackageId == 'none'
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFE2E8F0),
                  width: _foodPackageId == 'none' ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _foodPackageId == 'none'
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    size: 22.sp,
                    color: _foodPackageId == 'none'
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF94A3B8),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'No food package',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(_rupee(0), style: TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          if (pkg.id != 'none') SizedBox(height: 8.h),
        ],
      ),
    );
  }

  Widget _buildExtraBedSection() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Extra bed'),
          _sectionNote(
            'Per bed per night. Child extra bed uses chargeable children '
            '${widget.foodChildAgeMin != null && widget.foodChildAgeMax != null ? '(ages ${widget.foodChildAgeMin}–${widget.foodChildAgeMax})' : '(all children)'} — '
            'same rule as web.',
          ),
          CheckboxListTile(
            value: _extraBedAdult,
            onChanged: (v) =>
                setState(() => _extraBedAdult = v ?? false),
            title: Text(
              'Extra bed for adult · ${_rupee(_extraBedAdultRate)}/bed/night',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          CheckboxListTile(
            value: _extraBedKids,
            onChanged: (v) => setState(() => _extraBedKids = v ?? false),
            title: Text(
              'Extra bed for kids · ${_rupee(_extraBedChildRate)}/bed/night',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildAddOnsSection() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Add to your stay'),
          CheckboxListTile(
            value: _carRental,
            onChanged: (v) => setState(() => _carRental = v ?? false),
            title: Text(
              "I'm interested in renting a car",
              style: TextStyle(fontSize: 12.sp),
            ),
            subtitle: Text(
              'Rental options may appear in your confirmation.',
              style: TextStyle(fontSize: 10.sp, color: const Color(0xFF94A3B8)),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          SizedBox(height: 8.h),
          _sectionTitle('Special requests'),
          _sectionNote('Optional — property will try its best.'),
          TextFormField(
            controller: _specialCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter requests (English or Hindi)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              contentPadding: EdgeInsets.all(12.w),
            ),
          ),
          SizedBox(height: 12.h),
          _sectionTitle('Estimated arrival'),
          _sectionNote('Optional — 24h front desk.'),
          DropdownButtonFormField<String>(
            value: _arrivalTime.isEmpty ? null : _arrivalTime,
            hint: const Text('Please select'),
            items: _kArrivalTimes
                .where((t) => t.isNotEmpty)
                .map(
                  (t) => DropdownMenuItem(value: t, child: Text(t)),
                )
                .toList(),
            onChanged: (v) => setState(() => _arrivalTime = v ?? ''),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestDetailsSection() {
    return KeyedSubtree(
      key: _guestDetailsKey,
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: const Color(0xFF3B82F6), width: 2),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Your details'),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _firstNameCtrl,
                  focusNode: _firstNameFocus,
                  decoration: _fieldDeco('First name *'),
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _lastNameFocus.requestFocus(),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: TextFormField(
                  controller: _lastNameCtrl,
                  focusNode: _lastNameFocus,
                  decoration: _fieldDeco('Last name *'),
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          TextFormField(
            controller: _emailCtrl,
            decoration: _fieldDeco('Email *'),
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              if (!v.contains('@')) return 'Invalid email';
              return null;
            },
          ),
          SizedBox(height: 10.h),
          DropdownButtonFormField<String>(
            value: _country,
            decoration: _fieldDeco('Country *'),
            items: const [
              DropdownMenuItem(value: 'India', child: Text('India')),
              DropdownMenuItem(value: 'United States', child: Text('United States')),
              DropdownMenuItem(value: 'United Kingdom', child: Text('United Kingdom')),
              DropdownMenuItem(value: 'Canada', child: Text('Canada')),
              DropdownMenuItem(value: 'Australia', child: Text('Australia')),
            ],
            onChanged: (v) => setState(() => _country = v ?? 'India'),
          ),
          SizedBox(height: 10.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 118.w,
                child: DropdownButtonFormField<String>(
                  value: _phoneCode,
                  decoration: _fieldDeco('Code'),
                  items: const [
                    DropdownMenuItem(value: '+91', child: Text('IN +91')),
                    DropdownMenuItem(value: '+1', child: Text('US +1')),
                    DropdownMenuItem(value: '+44', child: Text('UK +44')),
                    DropdownMenuItem(value: '+61', child: Text('AU +61')),
                  ],
                  onChanged: (v) => setState(() => _phoneCode = v ?? '+91'),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: TextFormField(
                  controller: _phoneCtrl,
                  focusNode: _phoneFocus,
                  decoration: _fieldDeco('Phone *'),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  validator: (v) =>
                      (v == null || v.trim().length < 6) ? 'Required' : null,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            'Used to verify your booking and for the hotel to reach you.',
            style: TextStyle(fontSize: 10.sp, color: const Color(0xFF94A3B8)),
          ),
          CheckboxListTile(
            value: _paperless,
            onChanged: (v) => setState(() => _paperless = v ?? true),
            title: Text(
              'Paperless confirmation (recommended)',
              style: TextStyle(fontSize: 11.sp),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          TextFormField(
            controller: _affiliateCtrl,
            decoration: _fieldDeco('Affiliate code (optional)'),
          ),
        ],
      ),
      ),
    );
  }

  InputDecoration _fieldDeco(String label) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      );

  Widget _buildOptionalQuestionsSection() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Who are you booking for? (optional)'),
          RadioListTile<bool>(
            title: const Text("I'm the main guest"),
            value: true,
            groupValue: _bookingForSelf,
            onChanged: (v) => setState(() => _bookingForSelf = v ?? true),
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<bool>(
            title: const Text("I'm booking for someone else"),
            value: false,
            groupValue: _bookingForSelf,
            onChanged: (v) => setState(() => _bookingForSelf = v ?? false),
            contentPadding: EdgeInsets.zero,
          ),
          SizedBox(height: 8.h),
          _sectionTitle('Traveling for work? (optional)'),
          RadioListTile<bool>(
            title: const Text('Yes'),
            value: true,
            groupValue: _travelingForWork,
            onChanged: (v) => setState(() => _travelingForWork = v ?? false),
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<bool>(
            title: const Text('No'),
            value: false,
            groupValue: _travelingForWork,
            onChanged: (v) => setState(() => _travelingForWork = v ?? false),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(
    ({double subtotal, double gst, double total}) bill,
    String paymentMethod,
  ) {
    final r = _selectedRoom;
    final totalLabel = _isPayOnlineMethod(paymentMethod)
        ? 'Total (pay online now)'
        : 'Total (pay at hotel)';
    final listed = r.listedPricePerNight;
    final hasDisc = r.hasListedDiscount && listed != null;
    final roomBase = _roomSubtotal(r);
    final listedTotal =
        hasDisc ? (listed! * _nights * _roomsEffective) : 0.0;
    final saveRoom =
        hasDisc ? (listed! - r.pricePerNight) * _nights * _roomsEffective : 0.0;
    final pkg = _selectedFoodDef()!;
    final fA = _foodAdultTotal(pkg);
    final fC = _foodChildTotal(pkg);
    final eA = _extraBedAdultTotal();
    final eC = _extraBedKidsTotal();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price summary',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1D2E),
            ),
          ),
          SizedBox(height: 10.h),
          _priceRow('Per night (this room)', _rupee(r.pricePerNight), false),
          if (_roomsEffective > 1)
            _priceRow('Rooms', '$_roomsEffective', false),
          _priceRow('Check-in', widget.checkIn, false),
          _priceRow('Check-out', widget.checkOut, false),
          _priceRow(
            'Length of stay',
            '$_nights night${_nights == 1 ? '' : 's'}',
            false,
          ),
          Container(height: 1, color: const Color(0xFFF0F4F8)),
          SizedBox(height: 10.h),
          if (hasDisc) ...[
            Container(
              padding: EdgeInsets.all(10.w),
              margin: EdgeInsets.only(bottom: 10.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Text(
                '${r.discountPercent}% off · Save ${_rupee(saveRoom)} on room tariff',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF166534),
                ),
              ),
            ),
            _priceRow(
              'Listed total',
              _rupee(listedTotal),
              false,
              strike: true,
            ),
            SizedBox(height: 6.h),
          ],
          _priceRow(
            'Room subtotal',
            _rupee(roomBase),
            false,
          ),
          if (fA > 0) _priceRow('Food (adults)', _rupee(fA), false),
          if (fC > 0) _priceRow('Food (children)', _rupee(fC), false),
          if (eA > 0) _priceRow('Extra bed (adults)', _rupee(eA), false),
          if (eC > 0) _priceRow('Extra bed (children)', _rupee(eC), false),
          SizedBox(height: 8.h),
          _priceRow(
            'GST (${(_effectiveGstRate * 100).round()}%)',
            _rupee(bill.gst),
            false,
          ),
          SizedBox(height: 8.h),
          Container(height: 1, color: const Color(0xFFF0F4F8)),
          SizedBox(height: 8.h),
          _priceRow(totalLabel, _rupee(bill.total), true),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, bool isTotal, {bool strike = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 13.sp : 11.sp,
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
                color: isTotal
                    ? const Color(0xFF1A1D2E)
                    : const Color(0xFF6B7280),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 15.sp : 11.sp,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
              color: strike
                  ? const Color(0xFFDC2626)
                  : (isTotal
                      ? const Color(0xFF1A4B8E)
                      : const Color(0xFF374151)),
              decoration: strike ? TextDecoration.lineThrough : null,
              decorationColor: strike ? const Color(0xFFDC2626) : null,
              decorationThickness: strike ? 2 : null,
            ),
          ),
        ],
      ),
    );
  }

  /// Hotel photo + name overlay, then check-in / check-out row at the top of the form.
  Widget _buildTopHeroAndStayDatesCard() {
    final heroUrl = widget.hotel.resolvedHotelGalleryUrls.isNotEmpty
        ? widget.hotel.resolvedHotelGalleryUrls.first
        : widget.hotel.frontImageUrl.trim();
    final hotelPhotoCount = widget.hotel.resolvedHotelGalleryUrls.length;

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
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _openHotelGallery,
                      child: heroUrl.isNotEmpty
                          ? _roomTileImage(heroUrl)
                          : _imgPh(),
                    ),
                  ),
                  IgnorePointer(
                    child: DecoratedBox(
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
                  ),
                  Positioned(
                    top: 8.h,
                    right: 8.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.photo_library_outlined,
                            size: 14.sp,
                            color: Colors.white,
                          ),
                          if (hotelPhotoCount > 1) ...[
                            SizedBox(width: 4.w),
                            Text(
                              '$hotelPhotoCount',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10.h,
                    left: 12.w,
                    right: 12.w,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _openHotelGallery,
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
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(14.w),
            child: Row(
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
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final r = _selectedRoom;

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
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Row(
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
                    r.roomTypeName,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1D2E),
                    ),
                  ),
                  Text(
                    '$_adultsEffective adult${_adultsEffective > 1 ? 's' : ''}'
                    '${_childrenEffective > 0 ? ', $_childrenEffective child${_childrenEffective > 1 ? 'ren' : ''}' : ''}'
                    ' · $_roomsEffective room${_roomsEffective > 1 ? 's' : ''}'
                    ' · $_nights night${_nights > 1 ? 's' : ''}',
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

  Widget _buildPaymentMethodCard(String selectedMethod) {
    final lockedFull = _requiresFullOnlinePayment();

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
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 8.h),
            child: Text(
              'Payment method',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1D2E),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 10.h),
            child: lockedFull
                ? Column(
                    children: [
                      _paymentMethodOptionTile(
                        selected: true,
                        enabled: false,
                        icon: Icons.payments_rounded,
                        title: 'Advance payment',
                        subtitle:
                            'This property requires full payment online. You cannot pay only at the hotel.',
                        onTap: () {},
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _paymentMethodOptionTile(
                        selected: true,
                        enabled: false,
                        icon: Icons.hotel_rounded,
                        title: 'Pay at hotel',
                        subtitle:
                            'Settle the bill at check-in. No card needed in the app.',
                        onTap: () {},
                      ),
                    ],
                  ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 14.h),
            child: Row(
              children: _isPayOnlineMethod(selectedMethod)
                  ? [
                      _benefitChip(Icons.lock_rounded, 'Secure checkout'),
                      SizedBox(width: 8.w),
                      _benefitChip(Icons.bolt_rounded, 'Instant confirm'),
                    ]
                  : [
                      _benefitChip(Icons.savings_outlined, 'No advance'),
                      SizedBox(width: 8.w),
                      _benefitChip(Icons.verified_rounded, 'Flexible'),
                    ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentMethodOptionTile({
    required bool selected,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    final borderColor = selected
        ? const Color(0xFF2563EB)
        : const Color(0xFFE2E8F0);
    final tile = Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        gradient: selected
            ? LinearGradient(
                colors: [
                  const Color(0xFF1A4B8E).withOpacity(0.08),
                  const Color(0xFF2563EB).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: selected ? null : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: borderColor, width: selected ? 2 : 1),
      ),
      child: Row(
        children: [
          Container(
            width: 46.w,
            height: 46.h,
            decoration: BoxDecoration(
              color: const Color(0xFF1A4B8E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              icon,
              size: 22.sp,
              color: const Color(0xFF1A4B8E),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
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
                SizedBox(height: 3.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: const Color(0xFF6B7280),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Container(
            width: 22.w,
            height: 22.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFCBD5E1),
                width: 2,
              ),
              color: Colors.white,
            ),
            child: selected
                ? Center(
                    child: Container(
                      width: 12.w,
                      height: 12.h,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
    if (!enabled) return tile;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: tile,
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

  Widget _buildSecurityNote(String paymentMethod) {
    final advance = _isPayOnlineMethod(paymentMethod);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: advance
            ? const Color(0xFFEFF6FF)
            : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: advance
              ? const Color(0xFFBFDBFE)
              : const Color(0xFFBBF7D0),
        ),
      ),
      child: Row(
        children: [
          Icon(
            advance ? Icons.shield_rounded : Icons.verified_user_rounded,
            size: 16.sp,
            color: advance
                ? const Color(0xFF2563EB)
                : const Color(0xFF16A34A),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              advance
                  ? 'Your card or UPI is processed securely. The amount matches your stay total below.'
                  : 'No payment needed now — you pay when you stay.',
              style: TextStyle(
                fontSize: 11.sp,
                color: advance
                    ? const Color(0xFF1E40AF)
                    : const Color(0xFF15803D),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleInfo() {
    return Column(
      children: [
        ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 12.w),
          collapsedBackgroundColor: Colors.white,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.r),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.r),
          ),
          title: Text(
            'Hotel details',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1D2E),
            ),
          ),
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailLine('Name', widget.hotel.name),
                  if (widget.hotel.address.isNotEmpty)
                    _detailLine('Address', widget.hotel.address),
                  _detailLine('City', widget.hotel.city),
                  _detailLine('Rating', widget.hotel.rating.toStringAsFixed(1)),
                  TextButton.icon(
                    onPressed: _openDirections,
                    icon: Icon(Icons.map_rounded, size: 18.sp),
                    label: const Text('Open in Google Maps'),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 12.w),
          collapsedBackgroundColor: Colors.white,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.r),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.r),
          ),
          title: Text(
            'Cancellation & policies',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1D2E),
            ),
          ),
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
              child: Text(
                'Detailed cancellation and no-show rules appear on your '
                'confirmation when the property provides them (same as web search results).',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: const Color(0xFF64748B),
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _detailLine(String k, String v) => Padding(
        padding: EdgeInsets.only(bottom: 8.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 88.w,
              child: Text(
                k,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475569),
                ),
              ),
            ),
            Expanded(
              child: Text(
                v,
                style: TextStyle(fontSize: 11.sp, color: const Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
      );

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
        'Complete booking',
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
              _step(2, 'Details', true, false),
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
