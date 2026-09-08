import 'package:flutter_test/flutter_test.dart';
import 'package:send_to_linkwarden/model/user_instance.dart';

void main() {
  test('serialization round trip', () {
    final instance = UserInstance(
      user: 'u',
      server: 'http://example.com',
      apiToken: 'tok',
    );
    final json = instance.toJson();
    final loaded = UserInstance.fromJson(json);
    expect(loaded.user, 'u');
    expect(loaded.server, 'http://example.com');
    expect(loaded.apiToken, 'tok');
    expect(loaded.valid, isTrue);
  });

  test('invalid when missing fields', () {
    final instance = UserInstance();
    expect(instance.valid, isFalse);
  });

  test(
    'handles legacy instances with password by keeping it, but new save drops it',
    () {
      // This tests the data model handles legacy payloads
      final legacyJson = {
        'id': '123',
        'user': 'test',
        'server': 'https://example.com',
        'password': 'old_password',
        'apiToken': 'valid_token',
      };
      final loaded = UserInstance.fromJson(legacyJson);
      expect(loaded.password, 'old_password');
      expect(loaded.apiToken, 'valid_token');

      // Simulate what happens in AddEditUserInstanceView when saving username/password
      // the password field is explicitly cleared out in our new view logic, but the model
      // accepts it being null and serializes without issues.
      loaded.password = null;
      final reserialized = loaded.toJson();
      expect(reserialized['password'], isNull);
    },
  );
}
