import 'package:flutterapp/core/localization/app_strings.dart';

/// What kind of failure an API call hit — lets views pick the right icon/copy
/// (offline vs. server problem) without parsing messages.
enum ApiErrorType { network, timeout, unauthorized, notFound, server, unknown }

/// A user-safe API error. [message] is always fit to show on screen; the raw
/// backend body never reaches the UI.
class ApiException implements Exception {
  final ApiErrorType type;
  final String message;
  final int? statusCode;

  const ApiException(this.type, this.message, {this.statusCode});

  const ApiException.network()
    : this(ApiErrorType.network, AppStrings.errorNetwork);

  const ApiException.timeout()
    : this(ApiErrorType.timeout, AppStrings.errorTimeout);

  /// Map an HTTP status to a calm, user-facing error. [serverMessage] is the
  /// backend's own `message` field — only used where it's known to be safe
  /// (DummyJSON's 400 on login is "Invalid credentials").
  factory ApiException.fromStatus(int status, {String? serverMessage}) {
    if (status == 401 || status == 403) {
      return ApiException(
        ApiErrorType.unauthorized,
        AppStrings.errorSessionExpired,
        statusCode: status,
      );
    }
    if (status == 404) {
      return ApiException(
        ApiErrorType.notFound,
        AppStrings.errorNotFound,
        statusCode: status,
      );
    }
    if (status >= 500) {
      return ApiException(
        ApiErrorType.server,
        AppStrings.errorServer,
        statusCode: status,
      );
    }
    return ApiException(
      ApiErrorType.unknown,
      serverMessage ?? AppStrings.errorGeneric,
      statusCode: status,
    );
  }

  @override
  String toString() => message;
}
