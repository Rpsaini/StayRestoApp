import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/hotel_entity.dart';

// EVENTS

abstract class WishlistEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AddToWishlist extends WishlistEvent {
  final HotelEntity hotel;
  AddToWishlist(this.hotel);
  @override
  List<Object?> get props => [hotel.id];
}

class RemoveFromWishlist extends WishlistEvent {
  final int hotelId;
  RemoveFromWishlist(this.hotelId);
  @override
  List<Object?> get props => [hotelId];
}

class ToggleWishlist extends WishlistEvent {
  final HotelEntity hotel;
  ToggleWishlist(this.hotel);
  @override
  List<Object?> get props => [hotel.id];
}

class LoadWishlist extends WishlistEvent {}

class WishlistState extends Equatable {
  final List<HotelEntity> items;
  const WishlistState({this.items = const []});

  List<HotelEntity> get hotels => items;

  bool contains(int hotelId) => items.any((h) => h.id == hotelId);

  WishlistState copyWith({List<HotelEntity>? items}) =>
      WishlistState(items: items ?? this.items);

  @override
  List<Object?> get props => [items];
}

// BLOC — SharedPreferences persistence

class WishlistBloc extends Bloc<WishlistEvent, WishlistState> {
  static const String _kKey = 'wishlist_hotels';

  WishlistBloc() : super(const WishlistState()) {
    on<LoadWishlist>(_onLoad);
    on<AddToWishlist>(_onAdd);
    on<RemoveFromWishlist>(_onRemove);
    on<ToggleWishlist>(_onToggle);

    add(LoadWishlist());
  }

  // ── Load from SharedPreferences
  Future<void> _onLoad(LoadWishlist event, Emitter<WishlistState> emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_kKey);
      if (raw == null || raw.isEmpty) return;

      final List<dynamic> jsonList = jsonDecode(raw) as List<dynamic>;
      final List<HotelEntity> hotels = jsonList
          .map((e) => HotelEntity.fromJson(e as Map<String, dynamic>))
          .toList();

      emit(state.copyWith(items: hotels));
    } catch (_) {}
  }

  // ── Add
  Future<void> _onAdd(AddToWishlist event, Emitter<WishlistState> emit) async {
    if (state.contains(event.hotel.id)) return;
    final updated = [...state.items, event.hotel];
    emit(state.copyWith(items: updated));
    await _save(updated);
  }

  // ── Remove
  Future<void> _onRemove(
    RemoveFromWishlist event,
    Emitter<WishlistState> emit,
  ) async {
    final updated = state.items.where((h) => h.id != event.hotelId).toList();
    emit(state.copyWith(items: updated));
    await _save(updated);
  }

  // ── Toggle
  Future<void> _onToggle(
    ToggleWishlist event,
    Emitter<WishlistState> emit,
  ) async {
    final List<HotelEntity> updated = state.contains(event.hotel.id)
        ? state.items.where((h) => h.id != event.hotel.id).toList()
        : [...state.items, event.hotel];

    emit(state.copyWith(items: updated));
    await _save(updated);
  }

  // ── Save to SharedPreferences
  Future<void> _save(List<HotelEntity> hotels) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = hotels.map((h) => h.toJson()).toList();
      await prefs.setString(_kKey, jsonEncode(jsonList));
    } catch (_) {}
  }
}
