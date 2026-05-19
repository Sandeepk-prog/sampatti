import '../models/home_data.dart';

abstract class HomeRepository {
  Future<HomeData> getHomeData();
  Future<bool> checkDataExists();
  Future<void> initializeSampleData();
  Future<String?> getSavedNameFromPrefs();
}
