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
    required String location,
    required String checkIn,
    required String checkOut,
    required int adults,
    int children = 0,
    int rooms = 1,
    List<int>? childAges,
  }) async {
    try {
      final body = <String, dynamic>{
        'location': location,
        'check_in': checkIn,
        'check_out': checkOut,
        'adults': adults,
        'children': children,
        'rooms': rooms,
      };
      if (childAges != null && childAges.isNotEmpty) {
        body['child_ages'] = childAges;
        body['child_age'] = childAges.length == 1 ? childAges.first : childAges;
      }

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
