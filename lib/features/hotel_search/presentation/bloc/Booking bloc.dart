import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../hotel_search/domain/entities/hotel_entity.dart';
import '../../../hotel_search/domain/entities/room_entity.dart';

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
  final String checkIn;
  final String checkOut;
  final int guests;
  ConfirmBooking({
    required this.checkIn,
    required this.checkOut,
    required this.guests,
  });
  @override
  List<Object?> get props => [checkIn, checkOut, guests];
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
  BookingBloc() : super(BookingInitial()) {
    on<SelectRoom>(_onSelectRoom);
    on<SelectPaymentMethod>(_onSelectPayment);
    on<ConfirmBooking>(_onConfirmBooking);
    on<ResetBooking>(_onReset);
  }

  void _onSelectRoom(SelectRoom event, Emitter<BookingState> emit) {
    emit(BookingRoomSelected(room: event.room, hotel: event.hotel));
  }

  void _onSelectPayment(SelectPaymentMethod event, Emitter<BookingState> emit) {
    if (state is BookingRoomSelected) {
      emit(
        (state as BookingRoomSelected).copyWith(paymentMethod: event.method),
      );
    }
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

    await Future.delayed(const Duration(seconds: 2));

    final bookingId =
        'SR${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}${Random().nextInt(999)}';

    BookingRepository.instance.add(
      BookingRecord(
        bookingId: bookingId,
        hotel: s.hotel,
        room: s.room,
        checkIn: event.checkIn,
        checkOut: event.checkOut,
        totalPaid: s.total,
        paymentMethod: s.paymentMethod,
        guests: event.guests,
        bookedAt: DateTime.now(),
      ),
    );

    emit(
      BookingSuccess(
        room: s.room,
        hotel: s.hotel,
        bookingId: bookingId,
        checkIn: event.checkIn,
        checkOut: event.checkOut,
        totalPaid: s.total,
        paymentMethod: s.paymentMethod,
        guests: event.guests,
      ),
    );
  }

  void _onReset(ResetBooking event, Emitter<BookingState> emit) {
    emit(BookingInitial());
  }
}
