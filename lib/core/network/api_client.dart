import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterapp/core/config/api_config.dart';
import 'package:flutterapp/core/network/api_exception.dart';
import 'package:flutterapp/core/storage/token_storage.dart';
import 'package:http/http.dart' as http;

/// The one HTTP entry point for every repository.
///
/// Owns the things no repository should repeat: base URL, JSON encoding,
/// timeouts, attaching the bearer token, and turning transport/HTTP failures
/// into a user-safe [ApiException]. An authorized call that comes back 401 is
/// retried once after a token refresh; if the server rejects the refresh too,
/// the session is cleared and [sessionExpired] fires so the auth layer can
/// sign out. A refresh that merely can't reach the server signs no one out.
class ApiClient {
  final http.Client _http;
  final TokenStorage _tokens;

  ApiClient(this._http, this._tokens);

  final _sessionExpired = StreamController<void>.broadcast();

  /// Emits when the server stops accepting the stored session.
  Stream<void> get sessionExpired => _sessionExpired.stream;

  /// Shared in-flight refresh, so a burst of 401s triggers one refresh call.
  Future<bool>? _refreshing;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
    bool authorized = true,
  }) {
    return _send(
      () async =>
          _http.get(_uri(path, query), headers: await _headers(authorized)),
      authorized: authorized,
    );
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool authorized = true,
  }) {
    return _send(
      () async => _http.post(
        _uri(path, null),
        headers: await _headers(authorized),
        body: jsonEncode(body ?? const {}),
      ),
      authorized: authorized,
    );
  }

  Uri _uri(String path, Map<String, dynamic>? query) {
    return Uri.parse(
      '${ApiConfig.baseUrl}$path',
    ).replace(queryParameters: query?.map((k, v) => MapEntry(k, v.toString())));
  }

  Future<Map<String, String>> _headers(bool authorized) async {
    final token = authorized ? await _tokens.readAccessToken() : null;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() request, {
    required bool authorized,
  }) async {
    var res = await _guard(request);
    if (res.statusCode == 401 && authorized) {
      // Throws (offline / server down) without signing the user out — only
      // a refresh the server actually rejects ends the session.
      if (await _refreshSession()) {
        res = await _guard(request);
      } else {
        _sessionExpired.add(null);
      }
    }
    return _decode(res);
  }

  /// Run [request] with a timeout, mapping transport failures to
  /// [ApiException] so callers only ever deal with one error type.
  Future<http.Response> _guard(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(ApiConfig.requestTimeout);
    } on TimeoutException {
      throw const ApiException.timeout();
    } on SocketException {
      throw const ApiException.network();
    } on http.ClientException {
      throw const ApiException.network();
    }
  }

  Map<String, dynamic> _decode(http.Response res) {
    Map<String, dynamic>? json;
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) json = decoded;
    } catch (_) {
      // Non-JSON body (HTML error page, empty) — handled by status below.
    }
    if (res.statusCode >= 200 && res.statusCode < 300 && json != null) {
      return json;
    }
    if (kDebugMode) {
      debugPrint('[api] ${res.request?.url} → ${res.statusCode}: ${res.body}');
    }
    throw ApiException.fromStatus(
      res.statusCode,
      serverMessage: json?['message'] as String?,
    );
  }

  Future<bool> _refreshSession() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  /// True when the session was renewed; false when the server rejected the
  /// refresh token, which means the session is really over.
  ///
  /// Throws [ApiException] when the refresh couldn't be completed — offline,
  /// timeout, server error. The tokens are kept, and the caller sees that
  /// failure (e.g. "You're offline") instead of being signed out over a
  /// network blip; the next request simply tries again.
  Future<bool> _doRefresh() async {
    final refreshToken = await _tokens.readRefreshToken();
    if (refreshToken == null) return false;
    final res = await _guard(
      () => _http.post(
        _uri(ApiConfig.refresh, null),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'refreshToken': refreshToken,
          'expiresInMins': ApiConfig.tokenExpiresInMins,
        }),
      ),
    );
    if (res.statusCode >= 500) throw ApiException.fromStatus(res.statusCode);
    if (res.statusCode != 200) {
      await _tokens.clear();
      return false;
    }
    final String accessToken;
    final String newRefreshToken;
    try {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      accessToken = json['accessToken'] as String;
      newRefreshToken = json['refreshToken'] as String;
    } catch (_) {
      // A 200 we can't read is the server's fault, not the session's.
      throw ApiException.fromStatus(500);
    }
    await _tokens.save(accessToken: accessToken, refreshToken: newRefreshToken);
    return true;
  }

  void dispose() {
    _sessionExpired.close();
    _http.close();
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(http.Client(), ref.watch(tokenStorageProvider));
  ref.onDispose(client.dispose);
  return client;
});
