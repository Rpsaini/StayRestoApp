import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/hotel_entity.dart';

abstract class HotelRepository {
  Future<Either<Failure, List<HotelEntity>>> searchHotels({
    required String cityName,
    String? hotelName,
    String? address,
    String? locationName,
    required String checkIn,
    required String checkOut,
    required int adults,
    int children = 0,
    int rooms = 1,
    String propertyType = 'hotel',
    int? starRating,
    double? minPrice,
    double? maxPrice,
  });
}
