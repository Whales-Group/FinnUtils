import 'dart:convert';
import 'dart:io';

import 'package:finn_utils/utils/exceptions/finn_utils_client_exceptions.dart';
import 'package:http/http.dart' as http;

/// Callback for handling successful HTTP responses.
typedef OnSuccess = void Function(String response);

/// Callback for handling HTTP errors.
typedef OnError = void Function(FinnUtilsClientException error);

/// Intercepts an HTTP request before it's sent.
///
/// Allows modification of method, URI, headers, or body.
typedef Interceptor =
    Future<void> Function({
      required String method,
      required Uri uri,
      required Map<String, String> headers,
      dynamic body,
    });

/// Executes after an HTTP response is received.
///
/// Allows inspection or side-effects based on the response.
typedef AfterEffect =
    Future<void> Function({
      required String method,
      required Uri uri,
      required Map<String, String> headers,
      dynamic body,
      required http.Response response,
    });

/// A stateless HTTP client with configurable global settings.
///
/// Supports GET, POST, PUT, PATCH, DELETE, file upload/download,
/// request interceptors, and post-response hooks.
abstract class Client {
  /// Base URL for all requests.
  static String baseUrl = '';

  /// Default headers applied to every request.
  static Map<String, String> defaultHeaders = {};

  /// Optional global request interceptor.
  static Interceptor? globalInterceptor;

  /// Optional global after-response effect.
  static AfterEffect? globalAfterEffect;

  /// Whether to automatically invoke [globalInterceptor] before each request.
  static bool useGlobalInterceptor = true;

  /// Whether to automatically invoke [globalAfterEffect] after each response.
  static bool useGlobalAfterEffect = true;

  /// Configures the HTTP client globally.
  ///
  /// - [base]: sets the base URL.
  /// - [headers]: sets default headers.
  /// - [interceptor]: sets a global request interceptor.
  /// - [afterEffect]: sets a global after-response hook.
  /// - [applyGlobalInterceptor]: whether to run global interceptor by default.
  /// - [applyGlobalAfterEffect]: whether to run global afterEffect by default.
  static void configure({
    String? base,
    Map<String, String>? headers,
    Interceptor? interceptor,
    AfterEffect? afterEffect,
    bool? applyGlobalInterceptor,
    bool? applyGlobalAfterEffect,
  }) {
    if (base != null) baseUrl = base;
    if (headers != null) defaultHeaders = headers;
    if (interceptor != null) globalInterceptor = interceptor;
    if (afterEffect != null) globalAfterEffect = afterEffect;
    if (applyGlobalInterceptor != null)
      useGlobalInterceptor = applyGlobalInterceptor;
    if (applyGlobalAfterEffect != null)
      useGlobalAfterEffect = applyGlobalAfterEffect;
  }

  /// Sends an HTTP GET request to [path].
  ///
  /// Returns the response body as a [String].
  static Future<String> get(
    String path, {
    Map<String, String>? headers,
    OnSuccess? onSuccess,
    OnError? onError,
    Interceptor? interceptor,
    AfterEffect? afterEffect,
  }) async => _request(
    'GET',
    path,
    headers: headers,
    onSuccess: onSuccess,
    onError: onError,
    interceptor: interceptor,
    afterEffect: afterEffect,
  );

  /// Sends an HTTP POST request to [path] with optional [body].
  ///
  /// Returns the response body as a [String].
  static Future<String> post(
    String path, {
    Map<String, String>? headers,
    dynamic body,
    OnSuccess? onSuccess,
    OnError? onError,
    Interceptor? interceptor,
    AfterEffect? afterEffect,
  }) async => _request(
    'POST',
    path,
    headers: headers,
    body: body,
    onSuccess: onSuccess,
    onError: onError,
    interceptor: interceptor,
    afterEffect: afterEffect,
  );

  /// Sends an HTTP PUT request to [path] with optional [body].
  ///
  /// Returns the response body as a [String].
  static Future<String> put(
    String path, {
    Map<String, String>? headers,
    dynamic body,
    OnSuccess? onSuccess,
    OnError? onError,
    Interceptor? interceptor,
    AfterEffect? afterEffect,
  }) async => _request(
    'PUT',
    path,
    headers: headers,
    body: body,
    onSuccess: onSuccess,
    onError: onError,
    interceptor: interceptor,
    afterEffect: afterEffect,
  );

  /// Sends an HTTP PATCH request to [path] with optional [body].
  ///
  /// Returns the response body as a [String].
  static Future<String> patch(
    String path, {
    Map<String, String>? headers,
    dynamic body,
    OnSuccess? onSuccess,
    OnError? onError,
    Interceptor? interceptor,
    AfterEffect? afterEffect,
  }) async => _request(
    'PATCH',
    path,
    headers: headers,
    body: body,
    onSuccess: onSuccess,
    onError: onError,
    interceptor: interceptor,
    afterEffect: afterEffect,
  );

  /// Sends an HTTP DELETE request to [path] with optional [body].
  ///
  /// Returns the response body as a [String].
  static Future<String> delete(
    String path, {
    Map<String, String>? headers,
    dynamic body,
    OnSuccess? onSuccess,
    OnError? onError,
    Interceptor? interceptor,
    AfterEffect? afterEffect,
  }) async => _request(
    'DELETE',
    path,
    headers: headers,
    body: body,
    onSuccess: onSuccess,
    onError: onError,
    interceptor: interceptor,
    afterEffect: afterEffect,
  );

  /// Uploads a [file] via multipart POST to [path].
  ///
  /// [fieldName] defaults to 'file'. Returns the response body.
  static Future<String> uploadFile(
    String path,
    File file, {
    Map<String, String>? headers,
    String fieldName = 'file',
    OnSuccess? onSuccess,
    OnError? onError,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'));
      request.headers.addAll({...defaultHeaders, ...?headers});
      request.files.add(
        await http.MultipartFile.fromPath(fieldName, file.path),
      );

      final streamed = await request.send();
      final resString = await streamed.stream.bytesToString();

      if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
        onSuccess?.call(resString);
        return resString;
      } else {
        throw FinnUtilsClientException('Upload failed: $resString');
      }
    } catch (e) {
      onError?.call(FinnUtilsClientException(e.toString()));
      rethrow;
    }
  }

  /// Downloads content from [path] and saves it to [saveToPath].
  ///
  /// Returns a success message or throws on error.
  static Future<String> downloadFile(
    String path,
    String saveToPath, {
    Map<String, String>? headers,
    OnSuccess? onSuccess,
    OnError? onError,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$path'),
        headers: {...defaultHeaders, ...?headers},
      );

      if (response.statusCode == 200) {
        final file = File(saveToPath);
        await file.writeAsBytes(response.bodyBytes);
        final message = 'File saved to $saveToPath';
        onSuccess?.call(message);
        return message;
      } else {
        throw FinnUtilsClientException('Download failed: ${response.body}');
      }
    } catch (e) {
      onError?.call(FinnUtilsClientException(e.toString()));
      rethrow;
    }
  }

  /// Core request handler used by all HTTP methods.
  static Future<String> _request(
    String method,
    String path, {
    Map<String, String>? headers,
    dynamic body,
    OnSuccess? onSuccess,
    OnError? onError,
    Interceptor? interceptor,
    AfterEffect? afterEffect,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final requestHeaders = {...defaultHeaders, ...?headers};
      final encodedBody = body != null ? jsonEncode(body) : null;

      // Apply global interceptor if enabled
      if (useGlobalInterceptor && globalInterceptor != null) {
        await globalInterceptor!(
          method: method,
          uri: uri,
          headers: requestHeaders,
          body: body,
        );
      }

      // Apply method-level interceptor
      if (interceptor != null) {
        await interceptor(
          method: method,
          uri: uri,
          headers: requestHeaders,
          body: body,
        );
      }

      // Execute HTTP request
      late final http.Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: requestHeaders);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: requestHeaders,
            body: encodedBody,
          );
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: requestHeaders,
            body: encodedBody,
          );
          break;
        case 'PATCH':
          response = await http.patch(
            uri,
            headers: requestHeaders,
            body: encodedBody,
          );
          break;
        case 'DELETE':
          response = await http.delete(
            uri,
            headers: requestHeaders,
            body: encodedBody,
          );
          break;
        default:
          throw FinnUtilsClientException('Unsupported HTTP method: $method');
      }

      // Apply global afterEffect if enabled
      if (useGlobalAfterEffect && globalAfterEffect != null) {
        await globalAfterEffect!(
          method: method,
          uri: uri,
          headers: requestHeaders,
          body: body,
          response: response,
        );
      }

      // Apply method-level afterEffect
      if (afterEffect != null) {
        await afterEffect(
          method: method,
          uri: uri,
          headers: requestHeaders,
          body: body,
          response: response,
        );
      }

      // Success or error handling
      if (response.statusCode >= 200 && response.statusCode < 300) {
        onSuccess?.call(response.body);
        return response.body;
      } else {
        throw FinnUtilsClientException(response.body);
      }
    } catch (e) {
      onError?.call(FinnUtilsClientException(e.toString()));
      rethrow;
    }
  }
}
