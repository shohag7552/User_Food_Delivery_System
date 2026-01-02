

abstract class SplashRepoInterface {
  Future<bool> saveIntroSeen(bool seen);
  bool isIntroSeen();
  // Future<ConfigModel?> getConfigData();
}