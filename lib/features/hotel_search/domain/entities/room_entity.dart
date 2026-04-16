import 'package:equatable/equatable.dart';

class RoomEntity extends Equatable {
  final int id;
  final String roomTypeName;
  final double pricePerNight;
  final String primaryImageUrl;

  const RoomEntity({
    required this.id,
    required this.roomTypeName,
    required this.pricePerNight,
    required this.primaryImageUrl,
  });

  @override
  List<Object?> get props => [id, roomTypeName, pricePerNight, primaryImageUrl];
}
