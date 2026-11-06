import 'package:cabina/common/errors/exceptions.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App key/value storage. Callers see only strings and [StorageException],
/// never the backend.
class LocalStorage {
  LocalStorage({required SharedPreferences prefs}) : _prefs = prefs;

  final SharedPreferences _prefs;

  static const _readError = 'Could not load your saved data';
  static const _writeError = 'Could not save your changes';

  /// The value stored under [key], or `null` when there is none.
  Future<String?> read(String key) =>
      _guard(_readError, () async => _prefs.getString(key));

  Future<void> write(String key, String value) =>
      _guardWrite(() => _prefs.setString(key, value));

  Future<void> delete(String key) => _guardWrite(() => _prefs.remove(key));

  /// Runs [operation] and turns any failure into a [StorageException] with
  /// the original as `cause`.
  Future<T> _guard<T>(String message, Future<T> Function() operation) async {
    try {
      return await operation();
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(
        StorageException(message, cause: error),
        stackTrace,
      );
    }
  }

  /// Like [_guard], and a backend that reports `false` also throws.
  Future<void> _guardWrite(Future<bool> Function() operation) async {
    final saved = await _guard(_writeError, operation);
    if (!saved) throw const StorageException(_writeError);
  }
}
