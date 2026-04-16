import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/usecases/search_hotels_usecase.dart';
import 'hotel_search_event.dart';
import 'hotel_search_state.dart';

class HotelSearchBloc extends Bloc<HotelSearchEvent, HotelSearchState> {
  final SearchHotelsUseCase searchHotelsUseCase;

  HotelSearchBloc({required this.searchHotelsUseCase})
    : super(const HotelSearchInitial()) {
    on<SearchHotelsEvent>(_onSearchHotels);
    on<ResetSearchEvent>(_onResetSearch);
  }

  Future<void> _onSearchHotels(
    SearchHotelsEvent event,
    Emitter<HotelSearchState> emit,
  ) async {
    emit(const HotelSearchLoading());

    final result = await searchHotelsUseCase(event.params);

    result.fold(
      (failure) {
        if (failure is EmptyResultsFailure) {
          emit(const HotelSearchEmpty());
        } else {
          emit(
            HotelSearchError(
              message: failure.message,
              isNetworkError: failure is NetworkFailure,
            ),
          );
        }
      },
      (hotels) {
        emit(
          HotelSearchLoaded(
            hotels: hotels,
            totalCount: hotels.length,
            searchParams: event.params,
          ),
        );
      },
    );
  }

  void _onResetSearch(ResetSearchEvent event, Emitter<HotelSearchState> emit) {
    emit(const HotelSearchInitial());
  }
}
