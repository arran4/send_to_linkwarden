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
}
