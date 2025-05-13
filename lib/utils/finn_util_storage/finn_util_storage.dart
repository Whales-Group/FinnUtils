import 'package:get_storage/get_storage.dart';

/// A generic singleton utility for persistent key-value storage using GetStorage.
///
/// Supports any JSON-serializable type (String, int, double, bool, List, Map).
class FinnUtilStorage {
  static FinnUtilStorage? _instance;

  final GetStorage _box;

  /// Private constructor
  FinnUtilStorage._() : _box = GetStorage();

  /// Initializes the singleton instance and GetStorage
  static Future<void> initialize() async {
    await GetStorage.init();
    _instance ??= FinnUtilStorage._();
  }

  /// Returns the singleton instance. Make sure `initialize()` is called before accessing.
  static FinnUtilStorage get instance {
    if (_instance == null) {
      throw Exception(
          'FinnUtilStorage not initialized. Call FinnUtilStorage.initialize() first.');
    }
    return _instance!;
  }

  /// Writes a [value] of any type [T] with the given [key].
  ///
  /// Must be JSON-serializable.
  Future<void> write<T>({required String key, required T? value}) async {
    await _box.write(key, value);
  }

  /// Reads a value of type [T] for the given [key].
  ///
  /// Returns `null` if the key doesn't exist.
  T? read<T>({required String key}) {
    return _box.read<T>(key);
  }

  /// Deletes the entry with the given [key].
  Future<void> delete({required String key}) async {
    await _box.remove(key);
  }

  /// Clears all stored key-value pairs.
  Future<void> deleteAll() async {
    await _box.erase();
  }

  /// Returns `true` if the given [key] exists.
  bool containsKey({required String key}) {
    return _box.hasData(key);
  }
}
