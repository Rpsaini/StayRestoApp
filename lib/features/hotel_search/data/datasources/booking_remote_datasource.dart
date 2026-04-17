import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/auth/portal_auth_sync.dart';
import '../../../../core/auth/portal_session.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/failures.dart';

/// Portal booking submit — body field names aligned with search API (`check_in`, `adults`, `child_ages`, etc.).
class BookingSubmitResult {
  final String bookingId;
  final Map<String, dynamic>? raw;

  const BookingSubmitResult({required this.bookingId, this.raw});
}

abstract class BookingRemoteDataSource {
  Future<BookingSubmitResult> submitBooking(Map<String, dynamic> body);
}

class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  final Dio dio;
  const BookingRemoteDataSourceImpl(this.dio);

  @override
  Future<BookingSubmitResult> submitBooking(Map<String, dynamic> body) async {
    try {
      await PortalAuthSync.syncFromFirebase(dio);

      final merged = Map<String, dynamic>.from(body);

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final idToken = await user.getIdToken(true);
        if (idToken != null && idToken.isNotEmpty) {
          merged['firebase_id_token'] = idToken;
          merged['id_token'] = idToken;
          merged['firebase_token'] = idToken;
        }
        if (user.email != null) {
          merged['email'] = user.email;
        }
        merged['uid'] = user.uid;
      }

      final session = await PortalSession.readToken();
      if (session != null && session.isNotEmpty) {
        merged['session_token'] = session;
        merged['session'] = session;
        merged['guest_session'] = session;
      }

      final response = await dio.post<Map<String, dynamic>>(
        ApiConstants.bookingSubmitEndpoint,
        data: merged,
        options: Options(
          followRedirects: true,
          maxRedirects: 5,
          validateStatus: (status) =>
              status != null && status < 500,
          headers: session != null && session.isNotEmpty
              ? <String, String>{
                  'X-Session-Token': session,
                  'X-Session': session,
                }
              : null,
        ),
      );

      final code = response.statusCode;
      final data = response.data;

      if (data == null) {
        throw ServerFailure(
          'Booking failed${code != null ? ' ($code)' : ''}.',
        );
      }

      if (code != null && code >= 400) {
        final msg = data['message']?.toString() ??
            data['error']?.toString() ??
            data['detail']?.toString() ??
            'Booking failed ($code).';
        throw ServerFailure(msg);
      }

      final success = data['success'];
      if (success == false) {
        final msg = data['message']?.toString() ??
            data['error']?.toString() ??
            'Booking was not accepted.';
        throw ServerFailure(msg);
      }

      final id = _extractBookingId(data);
      if (id == null || id.isEmpty) {
        throw const ParseFailure('Could not read booking reference from server.');
      }

      return BookingSubmitResult(bookingId: id, raw: data);
    } on DioException catch (e) {
      throw _mapDio(e);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ParseFailure('Booking error: $e');
    }
  }

  String? _extractBookingId(Map<String, dynamic> data) {
    final keys = [
      'booking_id',
      'booking_reference',
      'reference',
      'confirmation_code',
      'order_id',
      'id',
    ];
    for (final k in keys) {
      final v = data[k];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    }
    final nested = data['booking'];
    if (nested is Map<String, dynamic>) {
      return _extractBookingId(nested);
    }
    return null;
  }

  Failure _mapDio(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const NetworkFailure('Network error. Check your connection.');
    }
    final msg = e.response?.data is Map
        ? (e.response!.data as Map)['message']?.toString() ??
            (e.response!.data as Map)['error']?.toString()
        : null;
    return ServerFailure(
      msg ?? e.message ?? 'Booking request failed.',
    );
  }
}
