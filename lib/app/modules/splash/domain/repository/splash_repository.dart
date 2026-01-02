
import 'package:appwrite_user_app/app/modules/splash/domain/repository/splash_repo_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashRepository implements SplashRepoInterface {
  // final ApiService apiService;
  final SharedPreferences sharedPreferences;
  SplashRepository({required this.sharedPreferences});

  // @override
  // Future<ConfigModel?> getConfigData() async {
  //   Response response = await apiService.getData(AppUrls.configUri);
  //   if (response.statusCode == 200) {
  //     return ConfigModel.fromJson(response.body);
  //   } else {
  //     ApiChecker.checkApi(response);
  //     return null;
  //   }
  // }

  @override
  Future<bool> saveIntroSeen(bool seen) async {
    return true; // await sharedPreferences.setBool(AppUrls.seenIntro, seen);
  }

  @override
  bool isIntroSeen() {
    return true;
    // return sharedPreferences.getBool(AppUrls.seenIntro)??false;
  }
}