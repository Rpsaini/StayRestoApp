import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import 'core/network/dio_client.dart';
import 'features/hotel_search/data/datasources/hotel_remote_datasource.dart';
import 'features/hotel_search/domain/repositories/hotel_repository.dart';
import 'features/hotel_search/domain/repositories/hotel_repository_impl.dart';
import 'features/hotel_search/domain/usecases/search_hotels_usecase.dart';
import 'features/hotel_search/presentation/bloc/hotel_search_bloc.dart';

final sl = GetIt.instance; // Service Locator

Future<void> init() async {
  // ─── BLoC
  sl.registerFactory(() => HotelSearchBloc(searchHotelsUseCase: sl()));

  // ─── Use Cases
  sl.registerLazySingleton(() => SearchHotelsUseCase(sl()));

  // ─── Repository
  sl.registerLazySingleton<HotelRepository>(() => HotelRepositoryImpl(sl()));

  // ─── Data Sources
  sl.registerLazySingleton<HotelRemoteDataSource>(
    () => HotelRemoteDataSourceImpl(sl()),
  );

  // ─── External
  sl.registerLazySingleton<Dio>(() => DioClient.instance.dio);
}
