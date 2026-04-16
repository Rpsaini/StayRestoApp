import 'package:equatable/equatable.dart';

import '../../domain/usecases/search_hotels_usecase.dart';

abstract class HotelSearchEvent extends Equatable {
  const HotelSearchEvent();

  @override
  List<Object?> get props => [];
}

class SearchHotelsEvent extends HotelSearchEvent {
  final SearchParams params;
  const SearchHotelsEvent(this.params);

  @override
  List<Object?> get props => [params];
}

class ResetSearchEvent extends HotelSearchEvent {
  const ResetSearchEvent();
}
