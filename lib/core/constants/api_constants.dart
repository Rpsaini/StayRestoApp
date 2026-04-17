/// StayResto portal URLs — aligned with [BookingEngine/BookingEngine/settings.py].
class ApiConstants {
  ApiConstants._();

  /// `API_BASE_URL` default in BookingEngine
  static const String portalBaseUrl = 'https://portal.stayresto.com';

  /// Dio [BaseOptions.baseUrl] — paths are under `/api/` (see `SEARCH_API_URL`).
  static const String baseUrl = '$portalBaseUrl/api';

  static const String searchEndpoint = '/search/';

  /// `TOP_SEARCH_HOTELS_API_URL` path segment after `/api/`
  static const String topSearchHotelsEndpoint = '/top-search-hotels/';

  /// `BEST_LOCATIONS_API_URL`
  static const String bestLocationsEndpoint = '/best-locations/';

  /// `BOOKING_SUBMIT_API_URL`
  static const String bookingSubmitEndpoint = '/booking/submit/';

  /// `BOOKING_UPDATE_PAYMENT_API_URL`
  static const String bookingUpdatePaymentEndpoint = '/booking/update-payment/';

  /// `CUSTOMER_LOGIN_BOOKINGS_API_URL`
  static const String customerLoginBookingsEndpoint = '/customer/login-bookings/';

  /// `CUSTOMER_CANCEL_BOOKING_API_URL`
  static const String customerCancelBookingEndpoint = '/customer/cancel-booking/';

  /// `REVIEW_RATINGS_API_URL` (path under `/api/`)
  static const String reviewRatingsEndpoint = '/review/ratings/';

  /// `REVIEW_SUBMIT_API_URL`
  static const String reviewSubmitEndpoint = '/review/submit/';

  /// `IMAGES_BASE_URL` — prefix for relative image paths from the API
  static const String imageBaseUrl = portalBaseUrl;
}
