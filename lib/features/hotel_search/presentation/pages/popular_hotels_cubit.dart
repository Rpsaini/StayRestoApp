import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/entities/hotel_entity.dart';

abstract class PopularHotelsState {}

class PopularHotelsInitial extends PopularHotelsState {}

class PopularHotelsLoading extends PopularHotelsState {}

class PopularHotelsError extends PopularHotelsState {}

class PopularHotelsLoaded extends PopularHotelsState {
  final List<HotelEntity> hotels;
  PopularHotelsLoaded(this.hotels);
}

class PopularHotelsCubit extends Cubit<PopularHotelsState> {
  PopularHotelsCubit() : super(PopularHotelsInitial());

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
  ];

  static const int _maxTotal = 10000;

  Future<void> fetch() async {
    emit(PopularHotelsLoading());
    final allHotels = <HotelEntity>[];
    final seen = <int>{};

    for (final city in _cities) {
      try {
        final resp = await DioClient.instance.dio.post(
          '/search/',
          data: {
            'city_name': city,
            'check_in': _dt(DateTime.now().add(const Duration(days: 1))),
            'check_out': _dt(DateTime.now().add(const Duration(days: 2))),
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

        debugPrint('PopularHotels $city → ${raw.length} results');

        const base = 'https://portal.stayresto.com';
        String resolveImg(dynamic v) {
          if (v == null || v.toString().trim().isEmpty) return '';
          final s = v.toString().trim();
          return s.startsWith('http') ? s : '$base$s';
        }

        for (final e in raw) {
          final m = Map<String, dynamic>.from(e as Map);
          final id = int.tryParse(m['id']?.toString() ?? '0') ?? 0;

          if (seen.contains(id)) continue;
          seen.add(id);

          String hotelImg = '';
          final images = m['images'];
          if (images is Map) {
            hotelImg = resolveImg(images['front'] ?? images['primary'] ?? '');
          } else {
            hotelImg = resolveImg(m['front_image'] ?? m['primary_image'] ?? '');
          }

          allHotels.add(
            HotelEntity(
              id: id,
              name: (m['name'] ?? 'Hotel').toString(),
              rating: double.tryParse(m['rating']?.toString() ?? '0') ?? 0.0,
              city: (m['city'] ?? city).toString(),
              address: (m['address'] ?? m['city'] ?? city).toString(),
              bestPricePerNight:
                  double.tryParse(
                    m['best_price_per_night']?.toString() ??
                        m['price_per_night']?.toString() ??
                        '0',
                  ) ??
                  0.0,
              frontImageUrl: hotelImg,
              availableRoomsCount:
                  int.tryParse(m['available_rooms_count']?.toString() ?? '0') ??
                  0,
              availableRooms: const [],
            ),
          );
        }
      } catch (e) {
        debugPrint('PopularHotels $city error: $e');
        continue;
      }
    }

    debugPrint('PopularHotels TOTAL: ${allHotels.length}');
    if (allHotels.isEmpty) {
      emit(PopularHotelsError());
    } else {
      emit(PopularHotelsLoaded(allHotels));
    }
  }

  String _dt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
