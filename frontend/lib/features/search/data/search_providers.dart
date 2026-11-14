import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/network/api_client_provider.dart';
import 'package:fluw/features/search/data/food_api.dart';
import 'package:fluw/features/search/data/recent_searches_storage.dart';

final foodApiProvider = Provider<FoodApi>((ref) => FoodApi(ref.watch(apiClientProvider)));

final recentSearchesStorageProvider = Provider<RecentSearchesStorage>(
  (ref) => throw UnimplementedError('recentSearchesStorageProvider phải được khởi tạo trong main()'),
);
