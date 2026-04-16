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
      cityName: params.cityName,
      hotelName: params.hotelName,
      checkIn: params.checkIn,
      checkOut: params.checkOut,
      adults: params.adults,
      children: params.children,
      rooms: params.rooms,
      starRating: params.starRating,
      minPrice: params.minPrice,
      maxPrice: params.maxPrice,
    );
  }
}

class SearchParams extends Equatable {
  final String cityName;
  final String? hotelName;
  final String checkIn;
  final String checkOut;
  final int adults;
  final int children;
  final int rooms;
  final int? starRating;
  final double? minPrice;
  final double? maxPrice;

  const SearchParams({
    required this.cityName,
    this.hotelName,
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    this.children = 0,
    this.rooms = 1,
    this.starRating,
    this.minPrice,
    this.maxPrice,
  });

  @override
  List<Object?> get props => [
    cityName,
    hotelName,
    checkIn,
    checkOut,
    adults,
    children,
    rooms,
    starRating,
    minPrice,
    maxPrice,
  ];
}
