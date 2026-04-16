import 'hotel_model.dart';

class SearchResponseModel {
  final bool success;
  final int count;
  final List<HotelModel> results;

  const SearchResponseModel({
    required this.success,
    required this.count,
    required this.results,
  });

  factory SearchResponseModel.fromJson(Map<String, dynamic> json) {
    final resultsList =
        (json['results'] as List<dynamic>?)
            ?.map((h) => HotelModel.fromJson(h as Map<String, dynamic>))
            .toList() ??
        [];

    return SearchResponseModel(
      success: json['success'] as bool? ?? false,
      count: json['count'] as int? ?? 0,
      results: resultsList,
    );
  }
}
