import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/entities/hotel_entity.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EVENTS
// ─────────────────────────────────────────────────────────────────────────────
abstract class HotelListingEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchHotels extends HotelListingEvent {
  final String cityName;
  final HotelListingFilters filters;
  FetchHotels({this.cityName = '', this.filters = const HotelListingFilters()});
  @override
  List<Object?> get props => [cityName, filters];
}

class LoadMoreHotels extends HotelListingEvent {}

class ApplyFilters extends HotelListingEvent {
  final HotelListingFilters filters;
  ApplyFilters(this.filters);
  @override
  List<Object?> get props => [filters];
}

// ✅ FIX: const constructor — no positional param issue
class ApplySorting extends HotelListingEvent {
  final SortOption sort;
  ApplySorting(this.sort);
  @override
  List<Object?> get props => [sort];
}

// ─────────────────────────────────────────────────────────────────────────────
// STATES
// ─────────────────────────────────────────────────────────────────────────────
abstract class HotelListingState extends Equatable {
  @override
  List<Object?> get props => [];
}

class HotelListingInitial extends HotelListingState {}

class HotelListingLoading extends HotelListingState {}

class HotelListingError extends HotelListingState {
  final String message;
  HotelListingError(this.message);
  @override
  List<Object?> get props => [message];
}

class HotelListingLoaded extends HotelListingState {
  final List<HotelEntity> hotels;
  final bool isLoadingMore;
  final bool hasMore;
  final HotelListingFilters filters;
  final SortOption sort;

  HotelListingLoaded({
    required this.hotels,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.filters = const HotelListingFilters(),
    this.sort = SortOption.recommended,
  });

  HotelListingLoaded copyWith({
    List<HotelEntity>? hotels,
    bool? isLoadingMore,
    bool? hasMore,
    HotelListingFilters? filters,
    SortOption? sort,
  }) {
    return HotelListingLoaded(
      hotels: hotels ?? this.hotels,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      filters: filters ?? this.filters,
      sort: sort ?? this.sort,
    );
  }

  @override
  List<Object?> get props => [hotels, isLoadingMore, hasMore, filters, sort];
}

enum SortOption { recommended, priceLowHigh, priceHighLow, ratingHighLow }

class HotelListingFilters extends Equatable {
  final double? minPrice;
  final double? maxPrice;
  final int? minRating;
  final String? propertyType;

  const HotelListingFilters({
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.propertyType,
  });

  bool get hasActiveFilters =>
      minPrice != null ||
      maxPrice != null ||
      minRating != null ||
      propertyType != null;

  HotelListingFilters copyWith({
    double? minPrice,
    double? maxPrice,
    int? minRating,
    String? propertyType,
    bool clearAll = false,
  }) {
    if (clearAll) return const HotelListingFilters();
    return HotelListingFilters(
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minRating: minRating ?? this.minRating,
      propertyType: propertyType ?? this.propertyType,
    );
  }

  @override
  List<Object?> get props => [minPrice, maxPrice, minRating, propertyType];
}

class HotelListingBloc extends Bloc<HotelListingEvent, HotelListingState> {
  HotelListingBloc() : super(HotelListingInitial()) {
    on<FetchHotels>(_onFetch);
    on<LoadMoreHotels>(_onLoadMore);
    on<ApplyFilters>(_onFilter);
    on<ApplySorting>(_onSort);
  }

  static const _cities = [
    'Mumbai',
    'Delhi',
    'Goa',
    'Jaipur',
    'Bangalore',
    'Shimla',
    'Kerala',
    'Manali',
    'Agra',
    'Hyderabad',
    'Pune',
    'Kolkata',
    'Chennai',
    'Udaipur',
    'Rishikesh',
  ];

  int _currentPage = 0;
  String _cityName = '';
  final List<HotelEntity> _allHotels = [];
  final Set<int> _seenIds = {};

  Future<void> _onFetch(
    FetchHotels event,
    Emitter<HotelListingState> emit,
  ) async {
    emit(HotelListingLoading());
    _currentPage = 0;
    _cityName = event.cityName;
    _allHotels.clear();
    _seenIds.clear();

    final hotels = await _fetchPage(0, event.cityName);
    final sorted = _applyFiltersAndSort(
      hotels,
      event.filters,
      SortOption.recommended,
    );

    emit(
      HotelListingLoaded(
        hotels: sorted,
        hasMore: hotels.length >= 4,
        filters: event.filters,
        sort: SortOption.recommended,
      ),
    );
  }

  Future<void> _onLoadMore(
    LoadMoreHotels event,
    Emitter<HotelListingState> emit,
  ) async {
    if (state is! HotelListingLoaded) return;
    final current = state as HotelListingLoaded;
    if (!current.hasMore || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));
    _currentPage++;

    final newHotels = await _fetchPage(_currentPage, _cityName);
    final combined = [...current.hotels, ...newHotels];
    final sorted = _applyFiltersAndSort(
      combined,
      current.filters,
      current.sort,
    );

    emit(
      current.copyWith(
        hotels: sorted,
        isLoadingMore: false,
        hasMore: newHotels.length >= 4,
      ),
    );
  }

  Future<void> _onFilter(
    ApplyFilters event,
    Emitter<HotelListingState> emit,
  ) async {
    if (state is! HotelListingLoaded) return;
    final current = state as HotelListingLoaded;
    final filtered = _applyFiltersAndSort(
      _allHotels,
      event.filters,
      current.sort,
    );
    emit(current.copyWith(hotels: filtered, filters: event.filters));
  }

  Future<void> _onSort(
    ApplySorting event,
    Emitter<HotelListingState> emit,
  ) async {
    if (state is! HotelListingLoaded) return;
    final current = state as HotelListingLoaded;
    final sorted = _applyFiltersAndSort(
      current.hotels,
      current.filters,
      event.sort,
    );
    emit(current.copyWith(hotels: sorted, sort: event.sort));
  }

  Future<List<HotelEntity>> _fetchPage(int page, String cityName) async {
    final List<HotelEntity> result = [];

    final citiesToTry = cityName.isNotEmpty
        ? [cityName]
        : _cities.skip(page * 3).take(3).toList();

    for (final city in citiesToTry) {
      try {
        final resp = await DioClient.instance.dio.post(
          '/search/',
          data: {
            'city_name': city,
            'check_in': _dateStr(DateTime.now().add(const Duration(days: 1))),
            'check_out': _dateStr(DateTime.now().add(const Duration(days: 2))),
            'adults': 2,
            'children': 0,
          },
        );

        final data = resp.data;
        List<dynamic> raw = [];
        if (data is Map<String, dynamic>) {
          raw = (data['results'] ?? []) as List<dynamic>;
        } else if (data is List) {
          raw = data;
        }

        const base = 'https://portal.stayresto.com';
        String resolveImg(dynamic v) {
          if (v == null || v.toString().trim().isEmpty) return '';
          final s = v.toString().trim();
          return s.startsWith('http') ? s : '$base$s';
        }

        for (final e in raw) {
          final m = Map<String, dynamic>.from(e as Map);
          final id = int.tryParse(m['id']?.toString() ?? '0') ?? 0;
          if (_seenIds.contains(id)) continue;
          _seenIds.add(id);

          String img = '';
          final images = m['images'];
          if (images is Map) {
            img = resolveImg(images['front'] ?? images['primary'] ?? '');
          } else {
            img = resolveImg(m['front_image'] ?? m['primary_image'] ?? '');
          }

          final hotel = HotelEntity(
            id: id,
            name: (m['name'] ?? 'Hotel').toString(),
            rating: double.tryParse(m['rating']?.toString() ?? '0') ?? 0.0,
            city: (m['city'] ?? city).toString(),
            address: (m['address'] ?? m['city'] ?? city).toString(),
            bestPricePerNight:
                double.tryParse(m['best_price_per_night']?.toString() ?? '0') ??
                0.0,
            frontImageUrl: img,
            availableRoomsCount:
                int.tryParse(m['available_rooms_count']?.toString() ?? '0') ??
                0,
            availableRooms: const [],
          );
          result.add(hotel);
          _allHotels.add(hotel);
        }
      } catch (e) {
        debugPrint('HotelListingBloc $city error: $e');
      }
    }
    return result;
  }

  List<HotelEntity> _applyFiltersAndSort(
    List<HotelEntity> hotels,
    HotelListingFilters filters,
    SortOption sort,
  ) {
    var list = hotels.where((h) {
      if (filters.minPrice != null && h.bestPricePerNight < filters.minPrice!)
        return false;
      if (filters.maxPrice != null && h.bestPricePerNight > filters.maxPrice!)
        return false;
      if (filters.minRating != null && h.rating < filters.minRating!)
        return false;
      return true;
    }).toList();

    switch (sort) {
      case SortOption.priceLowHigh:
        list.sort((a, b) => a.bestPricePerNight.compareTo(b.bestPricePerNight));
        break;
      case SortOption.priceHighLow:
        list.sort((a, b) => b.bestPricePerNight.compareTo(a.bestPricePerNight));
        break;
      case SortOption.ratingHighLow:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case SortOption.recommended:
        break;
    }
    return list;
  }

  String _dateStr(DateTime d) =>
      '${d.year}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
