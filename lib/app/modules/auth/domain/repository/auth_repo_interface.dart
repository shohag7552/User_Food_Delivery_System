abstract class AuthRepoInterface {
  // Future<bool> auth(String email, String password);
  // Future<bool> logout();
  Future<bool> isLoggedIn();
  Future<bool> loginAdmin(String email, String password);
}
