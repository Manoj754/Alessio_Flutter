import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutterapp/core/network/api_client.dart';
import 'package:flutterapp/core/network/api_exception.dart';
import 'package:flutterapp/core/storage/token_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// In-memory stand-in for the secure store (no platform channel in tests).
class _FakeTokens implements TokenStorage {
  String? access = 'old-access';
  String? refresh = 'old-refresh';

  @override
  Future<String?> readAccessToken() async => access;

  @override
  Future<String?> readRefreshToken() async => refresh;

  @override
  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {
    access = accessToken;
    refresh = refreshToken;
  }

  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
  }
}

http.Response _json(Object body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  late _FakeTokens tokens;
  late int refreshCalls;
  late int expiredEvents;

  /// A client whose `/products` accepts only `new-access`, and whose
  /// `/auth/refresh` answers with [onRefresh].
  ApiClient clientWith(Future<http.Response> Function() onRefresh) {
    final mock = MockClient((req) async {
      if (req.url.path == '/auth/refresh') {
        refreshCalls++;
        return onRefresh();
      }
      final ok = req.headers['Authorization'] == 'Bearer new-access';
      return ok
          ? _json({'products': []}, 200)
          : _json({'message': 'Token Expired!'}, 401);
    });
    final client = ApiClient(mock, tokens);
    client.sessionExpired.listen((_) => expiredEvents++);
    return client;
  }

  setUp(() {
    tokens = _FakeTokens();
    refreshCalls = 0;
    expiredEvents = 0;
  });

  test('a successful refresh retries the request transparently', () async {
    final client = clientWith(
      () async => _json({
        'accessToken': 'new-access',
        'refreshToken': 'new-refresh',
      }, 200),
    );
    final res = await client.get('/products');
    expect(res, {'products': []});
    expect(tokens.access, 'new-access');
    expect(tokens.refresh, 'new-refresh');
    expect(expiredEvents, 0);
  });

  test('a rejected refresh clears tokens and ends the session', () async {
    final client = clientWith(
      () async => _json({'message': 'Invalid refresh token'}, 401),
    );
    await expectLater(
      client.get('/products'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.type,
          'type',
          ApiErrorType.unauthorized,
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(tokens.access, isNull);
    expect(expiredEvents, 1);
  });

  test(
    'offline during refresh keeps the session and reports offline',
    () async {
      final client = clientWith(() async => throw http.ClientException('down'));
      await expectLater(
        client.get('/products'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.type,
            'type',
            ApiErrorType.network,
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(tokens.access, 'old-access');
      expect(tokens.refresh, 'old-refresh');
      expect(expiredEvents, 0);
    },
  );

  test('a server error during refresh keeps the session', () async {
    final client = clientWith(() async => _json({'message': 'oops'}, 503));
    await expectLater(
      client.get('/products'),
      throwsA(
        isA<ApiException>().having((e) => e.type, 'type', ApiErrorType.server),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(tokens.refresh, 'old-refresh');
    expect(expiredEvents, 0);
  });

  test('simultaneous 401s share a single refresh call', () async {
    final client = clientWith(
      () async => _json({
        'accessToken': 'new-access',
        'refreshToken': 'new-refresh',
      }, 200),
    );
    await Future.wait([
      client.get('/products'),
      client.get('/products'),
      client.get('/products'),
    ]);
    expect(refreshCalls, 1);
  });
}
