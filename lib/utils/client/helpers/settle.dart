/// A utility class for handling and settling HTTP responses in a standardized way.
///
/// The [Settle] class provides static methods to parse, validate, and extract
/// information from HTTP responses, including error handling and optional
/// authentication expiration triggers. It is designed to be configured globally
/// and used throughout your application to ensure consistent response handling.
///
/// Example usage:
/// ```dart
/// Settle.configure(
///   onForceOut: () {
///     // Handle forced logout or session expiration
///   },
///   errorMessageExtractor: (response) {
///     // Custom error message extraction logic
///     return "Custom error: $response";
///   },
/// );
///
/// final result = Settle.settleResponse<MyModel>(
///   responseString,
///   fromJsonT: (json) => MyModel.fromJson(json),
///   wrapper: (json) => MyModel.fromJson(json),
/// );
/// ```
///
/// Typedefs:
/// - [FromJson] is a function that converts a JSON object to a Dart object.
/// - [OnForceOutCallback] is a callback triggered when authentication expires.
/// - [ErrorMessageExtractor] extracts an error message from a response string.
/// - [ResponseWrapper] wraps the parsed JSON into the desired response type.
///
/// Methods:
/// - [configure] sets up global callbacks and error extractors.
/// - [settleResponse] parses and validates the response, returning the wrapped result or throwing a [FinnUtilsSettlerException] on error.
/// - [_triggerForceOutIfNeeded] checks for authentication expiration and triggers the callback if needed.
/// - [_defaultErrorMessageExtractor] provides a default way to extract error messages from responses.
/// - [_safeJsonDecode] safely decodes a JSON string into a map.
///
/// Throws:
/// - [FinnUtilsSettlerException] if the response is invalid, contains an error, or if session expiration is detected.
///
/// See also:
/// - [FinnUtilsSettlerException] for custom exception handling.
library;
import 'dart:convert';

import 'package:finn_utils/utils/exceptions/finn_utils_settler_exception.dart';

typedef FromJson<T> = T Function(dynamic json);
typedef OnForceOutCallback = void Function();
typedef ErrorMessageExtractor = String Function(String? responseString);
typedef ResponseWrapper<T> = T Function(Map<String, dynamic> json);

class Settle {
  static OnForceOutCallback? _onForceOutCallback;
  static ErrorMessageExtractor _defaultExtractor =
      _defaultErrorMessageExtractor;

  /// Configure global response-handling callbacks.
  ///
  /// - [onForceOut]: Called once when a response indicates session expiration.
  /// - [errorMessageExtractor]: Custom logic to extract an error message from
  ///   a raw response string.
  static void configure({
    OnForceOutCallback? onForceOut,
    ErrorMessageExtractor? errorMessageExtractor,
  }) {
    _onForceOutCallback = onForceOut;
    if (errorMessageExtractor != null) {
      _defaultExtractor = errorMessageExtractor;
    }
  }

  /// Parses and validates [responseString], then wraps it with [wrapper].
  ///
  /// - [fromJsonT]: Converts the raw JSON map into an intermediate Dart object.
  /// - [wrapper]: Produces the final return type from the JSON map.
  ///
  /// Returns the wrapped result on success.
  /// Throws [FinnUtilsSettlerException] on invalid JSON, non-2xx status, or
  /// if [_triggerForceOutIfNeeded] detects session expiration.
  static T settleResponse<T>(
    String responseString, {
    required FromJson<T> fromJsonT,
    required ResponseWrapper<T> wrapper,
  }) {
    try {
      final Map<String, dynamic>? response = _safeJsonDecode(responseString);

      _triggerForceOutIfNeeded(responseString);

      if (response == null) {
        throw FinnUtilsSettlerException("Invalid or empty JSON response.");
      }

      final int? statusCode = response["status"];
      if (statusCode == null || statusCode < 200 || statusCode >= 300) {
        throw FinnUtilsSettlerException(_defaultExtractor(responseString));
      }

      return wrapper(response);
    } catch (e) {
      throw FinnUtilsSettlerException(e.toString());
    }
  }

  /// Checks [responseBody] for authentication expiration markers.
  ///
  /// If detected and an [onForceOut] callback has been configured, triggers
  /// that callback and throws [FinnUtilsSettlerException] to halt processing.
  static void _triggerForceOutIfNeeded(String responseBody) {
    if (responseBody.contains("Unauthenticated.") &&
        _onForceOutCallback != null) {
      _onForceOutCallback!();
      throw FinnUtilsSettlerException("Session Expired");
    }
  }

  /// Default error message extraction from a raw JSON or plain string.
  ///
  /// Looks for top-level `message` or `error` fields in the JSON. Falls back
  /// to returning the raw string or a generic message.
  static String _defaultErrorMessageExtractor(String? responseString) {
    try {
      if (responseString == null || responseString.isEmpty) {
        return "Invalid or empty response received.";
      }

      if (!responseString.trim().startsWith('{')) {
        return responseString.trim();
      }

      final Map<String, dynamic>? response = _safeJsonDecode(responseString);
      if (response == null) return "Invalid JSON structure.";

      String? message = response["message"]?.toString();
      String? error = response["error"]?.toString();

      if (message != null && message.isNotEmpty) return message;
      if (error != null && error.isNotEmpty) return error;

      return "An unexpected error occurred.";
    } catch (_) {
      return "An error occurred while extracting the message.";
    }
  }

  /// Safely decodes a JSON [jsonString] into a `Map<String, dynamic>`.
  ///
  /// Returns `null` if decoding fails.
  static Map<String, dynamic>? _safeJsonDecode(String jsonString) {
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }
}
