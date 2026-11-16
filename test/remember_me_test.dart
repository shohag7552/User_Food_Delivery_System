import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikomart_user_app/app/appwrite/appwrite_service.dart';
import 'package:kikomart_user_app/app/modules/auth/domain/repository/auth_repository.dart';
import 'package:kikomart_user_app/app/resources/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(AuthRepository, SharedPreferences)> repo(
    Map<String, Object> prefs, {
    Map<String, String> secure = const {},
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    FlutterSecureStorage.setMockInitialValues(Map.of(secure));
    final p = await SharedPreferences.getInstance();
    return (AuthRepository(sharedPreferences: p, appwriteService: _NoAppwrite()), p);
  }

  test('the password goes to secure storage, never to SharedPreferences', () async {
    final (r, prefs) = await repo({});
    await r.saveRememberedCredentials(email: 'a@b.com', password: 's3cret');

    expect(prefs.getKeys().map(prefs.get), isNot(contains('s3cret')));
    expect(await const FlutterSecureStorage().read(key: Constants.rememberedPassword), 's3cret');
    expect(await r.getRememberedCredentials(), (email: 'a@b.com', password: 's3cret'));
    expect(r.getRememberedEmail(), 'a@b.com');
  });

  test('unticking remember me forgets both', () async {
    final (r, prefs) = await repo({});
    await r.saveRememberedCredentials(email: 'a@b.com', password: 's3cret');
    await r.clearRememberedCredentials();

    expect(await r.getRememberedCredentials(), isNull);
    expect(r.getRememberedEmail(), isNull);
    expect(await const FlutterSecureStorage().read(key: Constants.rememberedPassword), isNull);
    expect(prefs.getKeys(), isEmpty);
  });

  test('a plain-text password from an older build is moved and deleted', () async {
    final (r, prefs) = await repo({
      Constants.rememberMe: true,
      Constants.rememberedEmail: 'a@b.com',
      Constants.legacyRememberedPassword: 'old-plain',
    });

    expect(await r.getRememberedCredentials(), (email: 'a@b.com', password: 'old-plain'));
    expect(prefs.containsKey(Constants.legacyRememberedPassword), isFalse);
    expect(await const FlutterSecureStorage().read(key: Constants.rememberedPassword), 'old-plain');
  });
}

/// These tests never reach Appwrite; the real client needs platform plugins.
class _NoAppwrite implements AppwriteService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
