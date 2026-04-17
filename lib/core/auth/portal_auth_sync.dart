import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../constants/api_constants.dart';
import 'portal_session.dart';

/// Exchanges a Firebase ID token for a portal session (token / cookies) so
/// protected routes like [ApiConstants.bookingSubmitEndpoint] accept the request.
class PortalAuthSync {
  PortalAuthSync._();

  static Future<void> syncFromFirebase(Dio dio) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      await PortalSession.clearAll();
      return;
    }

    final idToken = await user.getIdToken(true);
    if (idToken == null || idToken.isEmpty) return;

    try {
      final resp = await dio.post<Map<String, dynamic>>(
        ApiConstants.customerLoginBookingsEndpoint,
        data: <String, dynamic>{
          'firebase_id_token': idToken,
          'id_token': idToken,
          'firebase_token': idToken,
          if (user.email != null) 'email': user.email,
          'uid': user.uid,
        },
        options: Options(
          validateStatus: (code) => code != null && code < 500,
          followRedirects: true,
          maxRedirects: 5,
        ),
      );

      final data = resp.data;
      if (data is Map<String, dynamic>) {
        await PortalSession.ingestFromApiJson(data);
      }

      final rawCookies = resp.headers.map['set-cookie'];
      if (rawCookies != null && rawCookies.isNotEmpty) {
        final merged = rawCookies
            .map((e) => e.split(';').first.trim())
            .where((e) => e.isNotEmpty)
            .join('; ');
        if (merged.isNotEmpty) {
          await PortalSession.writeCookie(merged);
        }
      }
    } catch (_) {
      // Non-fatal: search still works; booking will surface an error if needed.
    }
  }
}
