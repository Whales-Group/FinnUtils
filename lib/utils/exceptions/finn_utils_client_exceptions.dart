class FinnUtilsClientException implements Exception {
  final String message;
  FinnUtilsClientException(this.message);

  @override
  String toString() => 'FinnUtilsClientException: $message';
}