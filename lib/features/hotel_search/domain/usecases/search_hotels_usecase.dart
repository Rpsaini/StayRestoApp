import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../entities/hotel_entity.dart';
import '../repositories/hotel_repository.dart';

class SearchHotelsUseCase {
  final HotelRepository repository;
  const SearchHotelsUseCase(this.repository);

  Future<Either<Failure, List<HotelEntity>>> call(SearchParams params) {
    return repository.searchHotels(
      location: params.location,
      checkIn: params.checkIn,
      checkOut: params.checkOut,
      adults: params.adults,
      children: params.children,
      rooms: params.rooms,
      childAges: params.childAges,
    );
  }
}

class SearchParams extends Equatable {
  final String location;
  final String checkIn;
  final String checkOut;
  final int adults;
  final int children;
  final int rooms;
  final List<int>? childAges;

  const SearchParams({
    required this.location,
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    this.children = 0,
    this.rooms = 1,
    this.childAges,
  });

  @override
  List<Object?> get props => [
    location,
    checkIn,
    checkOut,
    adults,
    children,
    rooms,
    childAges,
  ];
}
