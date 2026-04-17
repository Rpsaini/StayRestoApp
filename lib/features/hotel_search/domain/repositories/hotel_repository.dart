import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/hotel_entity.dart';

abstract class HotelRepository {
  /// Search uses the same JSON body as BookingEngine → `SEARCH_API_URL` (POST).
  Future<Either<Failure, List<HotelEntity>>> searchHotels({
    required String location,
    required String checkIn,
    required String checkOut,
    required int adults,
    int children = 0,
    int rooms = 1,
    List<int>? childAges,
  });
}
