import 'package:equatable/equatable.dart';

import 'room_entity.dart';

class HotelEntity extends Equatable {
  final int id;
  final String name;
  final double rating;
  final String city;
  final String address;
  final double bestPricePerNight;
  final String frontImageUrl;
  final int availableRoomsCount;
  final List<RoomEntity> availableRooms;

  const HotelEntity({
    required this.id,
    required this.name,
    required this.rating,
    required this.city,
    required this.address,
    required this.bestPricePerNight,
    required this.frontImageUrl,
    required this.availableRoomsCount,
    required this.availableRooms,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    rating,
    city,
    address,
    bestPricePerNight,
    frontImageUrl,
    availableRoomsCount,
    availableRooms,
  ];
  factory HotelEntity.fromJson(Map<String, dynamic> json) => HotelEntity(
    id: json['id'],
    name: json['name'],
    city: json['city'],
    address: json['address'],
    rating: (json['rating'] as num).toDouble(),
    bestPricePerNight: (json['bestPricePerNight'] as num).toDouble(),
    frontImageUrl: json['frontImageUrl'],
    availableRoomsCount: json['availableRoomsCount'],
    availableRooms: [],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'city': city,
    'address': address,
    'rating': rating,
    'bestPricePerNight': bestPricePerNight,
    'frontImageUrl': frontImageUrl,
    'availableRoomsCount': availableRoomsCount,
  };
}
