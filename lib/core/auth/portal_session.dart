import 'package:shared_preferences/shared_preferences.dart';

/// Persists StayResto portal credentials from [ApiConstants.customerLoginBookingsEndpoint] (token and/or Set-Cookie).
class PortalSession {
  PortalSession._();

  static const tokenKey = 'stayresto_portal_session_token';
  static const cookieKey = 'stayresto_portal_cookie_header';

  static Future<String?> readToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(tokenKey);
  }

  static Future<void> writeToken(String? value) async {
    final p = await SharedPreferences.getInstance();
    if (value == null || value.isEmpty) {
      await p.remove(tokenKey);
    } else {
      await p.setString(tokenKey, value);
    }
  }

  static Future<void> writeCookie(String? value) async {
    final p = await SharedPreferences.getInstance();
    if (value == null || value.isEmpty) {
      await p.remove(cookieKey);
    } else {
      await p.setString(cookieKey, value);
    }
  }

  static Future<({String? token, String? cookie})> readAuthHeaders() async {
    final p = await SharedPreferences.getInstance();
    return (
      token: p.getString(tokenKey),
      cookie: p.getString(cookieKey),
    );
  }

  static Future<void> clearAll() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(tokenKey);
    await p.remove(cookieKey);
  }

  /// Reads `session_token` (and similar) from search/login JSON and stores it.
  static Future<void> ingestFromApiJson(Map<String, dynamic> data) async {
    final s = extractSessionStringFromJson(data);
    if (s != null && s.isNotEmpty) {
      await writeToken(s);
    }
  }

  static String? extractSessionStringFromJson(Map<String, dynamic> data) {
    const topKeys = <String>[
      'session_token',
      'sessionToken',
      'guest_session',
      'booking_session',
      'booking_session_token',
      'search_session',
      'token',
      'access',
      'access_token',
      'session_key',
      'auth_token',
    ];
    for (final k in topKeys) {
      final s = _asSessionString(data[k]);
      if (s != null) return s;
    }

    final sessionObj = data['session'];
    if (sessionObj is Map<String, dynamic>) {
      for (final k in topKeys) {
        final s = _asSessionString(sessionObj[k]);
        if (s != null) return s;
      }
    }

    for (final nest in <String>['data', 'result', 'payload', 'meta']) {
      final v = data[nest];
      if (v is Map<String, dynamic>) {
        final inner = extractSessionStringFromJson(v);
        if (inner != null) return inner;
      }
    }
    return null;
  }

  static String? _asSessionString(dynamic v) {
    if (v is String && v.isNotEmpty) return v;
    if (v is num) return v.toString();
    return null;
  }
}
