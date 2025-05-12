import 'package:get_storage/get_storage.dart';

/// A singleton utility for secure, persistent key-value storage.
///
/// Provides a simplified API for reading, writing, and deleting values
/// without exposing the underlying storage implementation.
class FinnUtilStorage {
  static final FinnUtilStorage _instance = FinnUtilStorage._internal();

  final GetStorage _box;

  /// Private named constructor for singleton pattern.
  FinnUtilStorage._internal() : _box = GetStorage();

  /// Returns the singleton instance of [FinnUtilStorage].
  factory FinnUtilStorage() => _instance;

  /// Initializes the storage engine.
  ///
  /// Must be called once before any read/write operations.
  static Future<void> init() async {
    await GetStorage.init();
  }

  /// Writes a [value] associated with the given [key].
  ///
  /// If [value] is null, the stored entry will be set to null.
  Future<void> write({required String key, required String? value}) async {
    await _instance._box.write(key, value);
  }

  /// Reads the value associated with the given [key].
  ///
  /// Returns the stored `String` value, or `null` if the key does not exist.
  Future<String?> read({required String key}) async {
    return _instance._box.read<String>(key);
  }

  /// Deletes the entry for the given [key].
  Future<void> delete({required String key}) async {
    await _instance._box.remove(key);
  }

  /// Clears all stored entries.
  ///
  /// Use with caution: this will remove every key-value pair.
  Future<void> deleteAll() async {
    await _instance._box.erase();
  }

  /// Checks whether the given [key] exists in storage.
  ///
  /// Returns `true` if the key is present, `false` otherwise.
  Future<bool> containsKey({required String key}) async {
    return _instance._box.hasData(key);
  }
}
