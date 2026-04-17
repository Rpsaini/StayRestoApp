import 'package:dio/dio.dart';

import '../../../../core/auth/portal_session.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/failures.dart';
import '../models/hotel_model.dart';
import '../models/search_response_model.dart';

abstract class HotelRemoteDataSource {
  Future<List<HotelModel>> searchHotels(Map<String, dynamic> requestBody);
}

class HotelRemoteDataSourceImpl implements HotelRemoteDataSource {
  final Dio dio;
  const HotelRemoteDataSourceImpl(this.dio);

  @override
  Future<List<HotelModel>> searchHotels(
    Map<String, dynamic> requestBody,
  ) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        ApiConstants.searchEndpoint,
        data: requestBody,
        options: Options(
          followRedirects: true,
          maxRedirects: 5,
          validateStatus: (status) =>
              status != null && (status < 400 || status == 429),
        ),
      );

      final code = response.statusCode;
      final data = response.data;

      if (code == 429 && data is Map<String, dynamic>) {
        final retry = data['retry_after'];
        throw ServerFailure(
          'Too many searches. Try again in ${retry ?? 'a few'} seconds.',
        );
      }

      if (code != 200 || data == null) {
        throw ServerFailure(
          'Search failed${code != null ? ' ($code)' : ''}.',
        );
      }

      await PortalSession.ingestFromApiJson(data);

      final searchResponse = SearchResponseModel.fromJson(data);

      if (!searchResponse.success) {
        throw const ServerFailure('Search request was not successful.');
      }

      return searchResponse.results;
    } on DioException catch (e) {
      throw _mapDioError(e);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ParseFailure('Unexpected error: $e');
    }
  }

  Failure _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkFailure(
          'Connection timed out. Please check your internet.',
        );
      case DioExceptionType.connectionError:
        return const NetworkFailure(
          'No internet connection. Please try again.',
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 429) {
          return const ServerFailure(
            'Too many searches. Please wait and try again.',
          );
        }
        if (statusCode == 422 || statusCode == 400) {
          return const ServerFailure('Invalid search parameters.');
        }
        return ServerFailure(
          'Server error ($statusCode). Please try again later.',
        );
      default:
        return ServerFailure('Network error: ${e.message}');
    }
  }
}
