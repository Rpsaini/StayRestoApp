import 'package:dio/dio.dart';

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
      final response = await dio.post(
        'https://portal.stayresto.com/api/search/',
        data: requestBody,
        options: Options(
          followRedirects: true,
          maxRedirects: 5,
          validateStatus: (status) => status != null && status < 400,
        ),
      );

      if (response.data == null || response.data is! Map<String, dynamic>) {
        throw const ParseFailure('Invalid response format from server.');
      }

      final searchResponse = SearchResponseModel.fromJson(
        response.data as Map<String, dynamic>,
      );

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
