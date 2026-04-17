import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../data/datasources/booking_remote_datasource.dart';
import '../../domain/entities/hotel_entity.dart';
import '../../domain/entities/room_entity.dart';

class BookingRecord {
  final String bookingId;
  final HotelEntity hotel;
  final RoomEntity room;
  final String checkIn;
  final String checkOut;
  final double totalPaid;
  final String paymentMethod;
  final int guests;
  final DateTime bookedAt;

  BookingRecord({
    required this.bookingId,
    required this.hotel,
    required this.room,
    required this.checkIn,
    required this.checkOut,
    required this.totalPaid,
    required this.paymentMethod,
    required this.guests,
    required this.bookedAt,
  });
}

class BookingRepository {
  BookingRepository._internal();

  static final BookingRepository _instance = BookingRepository._internal();

  factory BookingRepository() => _instance;

  static BookingRepository get instance => _instance;

  final List<BookingRecord> _bookings = [];

  List<BookingRecord> get all => List.unmodifiable(_bookings);

  List<BookingRecord> get upcoming {
    final now = DateTime.now();
    return _bookings.where((b) {
        try {
          return _parseDate(b.checkOut).isAfter(now);
        } catch (_) {
          return false;
        }
      }).toList()
      ..sort((a, b) => _parseDate(a.checkIn).compareTo(_parseDate(b.checkIn)));
  }

  List<BookingRecord> get completed {
    final now = DateTime.now();
    return _bookings.where((b) {
      try {
        final co = _parseDate(b.checkOut);
        return co.isBefore(now) || co.isAtSameMomentAs(now);
      } catch (_) {
        return false;
      }
    }).toList()..sort(
      (a, b) => _parseDate(b.checkOut).compareTo(_parseDate(a.checkOut)),
    );
  }

  List<BookingRecord> get cancelled => [];

  void add(BookingRecord record) {
    _bookings.add(record);
  }

  DateTime _parseDate(String date) {
    final p = date.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }
}

abstract class BookingEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SelectRoom extends BookingEvent {
  final RoomEntity room;
  final HotelEntity hotel;
  SelectRoom({required this.room, required this.hotel});
  @override
  List<Object?> get props => [room.id, hotel.id];
}

class SelectPaymentMethod extends BookingEvent {
  final String method;
  SelectPaymentMethod(this.method);
  @override
  List<Object?> get props => [method];
}

class ConfirmBooking extends BookingEvent {
  final int hotelId;
  final int roomId;
  final String checkIn;
  final String checkOut;
  final int adults;
  final int children;
  final int rooms;
  final List<int>? childAges;
  /// Total payable (e.g. room × nights + taxes) — sent as `total_amount`.
  final double totalAmount;

  /// Aligns with StayResto web `bookingForm` fields where the API accepts them.
  final int selectedRoomIndex;
  final String foodPackage;
  final bool extraBedAdult;
  final bool extraBedKids;
  final bool carRentalInterest;
  final String specialRequests;
  final String arrivalTime;
  final String firstName;
  final String lastName;
  final String email;
  final String country;
  final String phoneCountryCode;
  final String phoneNumber;
  final bool paperlessConfirmation;
  final String affiliateCode;
  final bool bookingForSelf;
  final bool travelingForWork;

  ConfirmBooking({
    required this.hotelId,
    required this.roomId,
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    required this.children,
    required this.rooms,
    this.childAges,
    required this.totalAmount,
    this.selectedRoomIndex = 0,
    this.foodPackage = 'none',
    this.extraBedAdult = false,
    this.extraBedKids = false,
    this.carRentalInterest = false,
    this.specialRequests = '',
    this.arrivalTime = '',
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.country = 'India',
    this.phoneCountryCode = '+91',
    this.phoneNumber = '',
    this.paperlessConfirmation = true,
    this.affiliateCode = '',
    this.bookingForSelf = true,
    this.travelingForWork = false,
  });

  int get totalGuests => adults + children;

  @override
  List<Object?> get props => [
    hotelId,
    roomId,
    checkIn,
    checkOut,
    adults,
    children,
    rooms,
    childAges,
    totalAmount,
    selectedRoomIndex,
    foodPackage,
    extraBedAdult,
    extraBedKids,
    carRentalInterest,
    specialRequests,
    arrivalTime,
    firstName,
    lastName,
    email,
    country,
    phoneCountryCode,
    phoneNumber,
    paperlessConfirmation,
    affiliateCode,
    bookingForSelf,
    travelingForWork,
  ];
}

class ResetBooking extends BookingEvent {}

abstract class BookingState extends Equatable {
  @override
  List<Object?> get props => [];
}

class BookingInitial extends BookingState {}

class BookingRoomSelected extends BookingState {
  final RoomEntity room;
  final HotelEntity hotel;
  final String paymentMethod;

  BookingRoomSelected({
    required this.room,
    required this.hotel,
    this.paymentMethod = 'pay_on_hotel',
  });

  BookingRoomSelected copyWith({String? paymentMethod}) => BookingRoomSelected(
    room: room,
    hotel: hotel,
    paymentMethod: paymentMethod ?? this.paymentMethod,
  );

  double get roomPrice => room.pricePerNight;
  double get taxes => roomPrice * 0.18;
  double get total => roomPrice + taxes;

  @override
  List<Object?> get props => [room.id, hotel.id, paymentMethod];
}

class BookingProcessing extends BookingState {
  final RoomEntity room;
  final HotelEntity hotel;
  final String paymentMethod;
  BookingProcessing({
    required this.room,
    required this.hotel,
    required this.paymentMethod,
  });
  @override
  List<Object?> get props => [room.id, hotel.id];
}

class BookingSuccess extends BookingState {
  final RoomEntity room;
  final HotelEntity hotel;
  final String bookingId;
  final String checkIn;
  final String checkOut;
  final double totalPaid;
  final String paymentMethod;
  final int guests;

  BookingSuccess({
    required this.room,
    required this.hotel,
    required this.bookingId,
    required this.checkIn,
    required this.checkOut,
    required this.totalPaid,
    required this.paymentMethod,
    required this.guests,
  });

  @override
  List<Object?> get props => [bookingId];
}

class BookingFailure extends BookingState {
  final String message;
  BookingFailure(this.message);
  @override
  List<Object?> get props => [message];
}

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final BookingRemoteDataSource _bookingRemote;

  BookingBloc(this._bookingRemote) : super(BookingInitial()) {
    on<SelectRoom>(_onSelectRoom);
    on<SelectPaymentMethod>(_onSelectPayment);
    on<ConfirmBooking>(_onConfirmBooking);
    on<ResetBooking>(_onReset);
  }

  void _onSelectRoom(SelectRoom event, Emitter<BookingState> emit) {
    final hotel = event.hotel;
    final room = event.room;
    final requiresFullOnline = room.requiresFullOnlinePayment ||
        hotel.paymentType == 'full_payment';
    final method =
        requiresFullOnline ? 'full_payment' : 'pay_on_hotel';
    emit(
      BookingRoomSelected(
        room: event.room,
        hotel: event.hotel,
        paymentMethod: method,
      ),
    );
  }

  void _onSelectPayment(SelectPaymentMethod event, Emitter<BookingState> emit) {
    if (state is! BookingRoomSelected) return;
    final s = state as BookingRoomSelected;
    if (s.room.requiresFullOnlinePayment || s.hotel.paymentType == 'full_payment') {
      return;
    }
    if (event.method != 'pay_on_hotel') return;
    emit(s.copyWith(paymentMethod: event.method));
  }

  Future<void> _onConfirmBooking(
    ConfirmBooking event,
    Emitter<BookingState> emit,
  ) async {
    if (state is! BookingRoomSelected) return;
    final s = state as BookingRoomSelected;

    emit(
      BookingProcessing(
        room: s.room,
        hotel: s.hotel,
        paymentMethod: s.paymentMethod,
      ),
    );

    final body = <String, dynamic>{
      'hotel_id': event.hotelId,
      'room_id': event.roomId,
      'check_in': event.checkIn,
      'check_out': event.checkOut,
      'adults': event.adults,
      'children': event.children,
      'rooms': event.rooms,
      'guests': event.totalGuests,
      'payment_type': s.paymentMethod,
      'total_amount': event.totalAmount,
      'currency': 'INR',
      'selected_room_index': event.selectedRoomIndex,
      'food_package': event.foodPackage,
      'extra_bed_adult': event.extraBedAdult,
      'extra_bed_kids': event.extraBedKids,
      'car_rental_interest': event.carRentalInterest,
      'special_requests': event.specialRequests,
      'arrival_time': event.arrivalTime,
      'first_name': event.firstName,
      'last_name': event.lastName,
      'email': event.email,
      'country': event.country,
      'phone_country_code': event.phoneCountryCode,
      'phone_number': event.phoneNumber,
      'paperless_confirmation': event.paperlessConfirmation,
      'affiliate_code': event.affiliateCode,
      'booking_for_self': event.bookingForSelf,
      'traveling_for_work': event.travelingForWork,
    };
    final ages = event.childAges;
    if (ages != null && ages.isNotEmpty) {
      body['child_ages'] = ages;
      body['child_age'] = ages.length == 1 ? ages.first : ages;
    }

    try {
      final result = await _bookingRemote.submitBooking(body);

      BookingRepository.instance.add(
        BookingRecord(
          bookingId: result.bookingId,
          hotel: s.hotel,
          room: s.room,
          checkIn: event.checkIn,
          checkOut: event.checkOut,
          totalPaid: event.totalAmount,
          paymentMethod: s.paymentMethod,
          guests: event.totalGuests,
          bookedAt: DateTime.now(),
        ),
      );

      emit(
        BookingSuccess(
          room: s.room,
          hotel: s.hotel,
          bookingId: result.bookingId,
          checkIn: event.checkIn,
          checkOut: event.checkOut,
          totalPaid: event.totalAmount,
          paymentMethod: s.paymentMethod,
          guests: event.totalGuests,
        ),
      );
    } on Failure catch (e) {
      emit(BookingFailure(e.message));
      emit(
        BookingRoomSelected(
          room: s.room,
          hotel: s.hotel,
          paymentMethod: s.paymentMethod,
        ),
      );
    }
  }

  void _onReset(ResetBooking event, Emitter<BookingState> emit) {
    emit(BookingInitial());
  }
}
