import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/auth/portal_session.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/portal_hotel_json.dart';
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

  /// Same as BookingEngine `_fetch_top_search_hotels` cap.
  static const int _maxHotels = 24;

  Future<void> fetch() async {
    emit(PopularHotelsLoading());
    try {
      final resp = await DioClient.instance.dio.post<Map<String, dynamic>>(
        ApiConstants.topSearchHotelsEndpoint,
        data: <String, dynamic>{},
      );

      final data = resp.data;
      if (data == null ||
          data['success'] != true ||
          data['locations'] is! List) {
        emit(PopularHotelsError());
        return;
      }

      await PortalSession.ingestFromApiJson(data);

      final locations = data['locations'] as List<dynamic>;
      final allHotels = <HotelEntity>[];
      final seen = <int>{};

      outer:
      for (final loc in locations) {
        if (loc is! Map) continue;
        final locMap = Map<String, dynamic>.from(loc);
        final fallback =
            (locMap['name'] ?? locMap['city'] ?? locMap['title'] ?? '')
                .toString();
        final hotelsRaw = locMap['hotels'] as List<dynamic>? ?? [];
        for (final h in hotelsRaw) {
          if (h is! Map) continue;
          final m = Map<String, dynamic>.from(h);
          final id = int.tryParse(m['id']?.toString() ?? '0') ?? 0;
          if (id == 0 || seen.contains(id)) continue;
          seen.add(id);
          allHotels.add(
            PortalHotelJson.toHotelEntity(m, fallbackLocation: fallback),
          );
          if (allHotels.length >= _maxHotels) break outer;
        }
      }

      debugPrint('PopularHotels (top-search) TOTAL: ${allHotels.length}');
      if (allHotels.isEmpty) {
        emit(PopularHotelsError());
      } else {
        emit(PopularHotelsLoaded(allHotels));
      }
    } catch (e, st) {
      debugPrint('PopularHotels error: $e $st');
      emit(PopularHotelsError());
    }
  }
}
