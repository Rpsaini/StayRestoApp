import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../data/datasources/hotel_remote_datasource.dart';
import '../../domain/entities/hotel_entity.dart';
import '../../domain/repositories/hotel_repository.dart';

class HotelRepositoryImpl implements HotelRepository {
  final HotelRemoteDataSource remoteDataSource;
  const HotelRepositoryImpl(this.remoteDataSource);

  @override
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
  }) async {
    try {
      final body = <String, dynamic>{
        'city_name': cityName,
        'check_in': checkIn,
        'check_out': checkOut,
        'adults': adults,
        'children': children,
        'rooms': rooms,
        'property_type': propertyType,
        if (hotelName != null && hotelName.isNotEmpty) 'hotel_name': hotelName,
        if (address != null && address.isNotEmpty) 'address': address,
        if (locationName != null && locationName.isNotEmpty)
          'location_name': locationName,
        if (starRating != null) 'star_rating': starRating,
        if (minPrice != null) 'min_price': minPrice,
        if (maxPrice != null) 'max_price': maxPrice,
      };

      final hotels = await remoteDataSource.searchHotels(body);

      if (hotels.isEmpty) {
        return const Left(
          EmptyResultsFailure('No hotels found for your search.'),
        );
      }

      return Right(hotels);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ParseFailure('Unexpected error: $e'));
    }
  }
}
