class FinnUtilsSettlerException implements Exception {
  final String message;
  FinnUtilsSettlerException(this.message);

  @override
  String toString() => 'FinnUtilsSettlerException: $message';
}
