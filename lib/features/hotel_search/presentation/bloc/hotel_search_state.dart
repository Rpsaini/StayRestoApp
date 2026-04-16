import 'package:equatable/equatable.dart';

import '../../domain/entities/hotel_entity.dart';
import '../../domain/usecases/search_hotels_usecase.dart';

abstract class HotelSearchState extends Equatable {
  const HotelSearchState();

  @override
  List<Object?> get props => [];
}

class HotelSearchInitial extends HotelSearchState {
  const HotelSearchInitial();
}

class HotelSearchLoading extends HotelSearchState {
  const HotelSearchLoading();
}

class HotelSearchLoaded extends HotelSearchState {
  final List<HotelEntity> hotels;
  final int totalCount;
  final SearchParams? searchParams;

  const HotelSearchLoaded({
    required this.hotels,
    required this.totalCount,
    this.searchParams,
  });

  @override
  List<Object?> get props => [hotels, totalCount, searchParams];
}

class HotelSearchError extends HotelSearchState {
  final String message;
  final bool isNetworkError;

  const HotelSearchError({required this.message, this.isNetworkError = false});

  @override
  List<Object?> get props => [message, isNetworkError];
}

class HotelSearchEmpty extends HotelSearchState {
  const HotelSearchEmpty();
}
