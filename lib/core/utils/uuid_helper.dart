import 'package:uuid/uuid.dart';

class UuidHelper {
  static const _uuid = Uuid();

  static String generate() {
    return _uuid.v4();
  }

  /// Generate a unique ID with a prefix
  static String generateWithPrefix(String prefix) {
    return '${prefix}_${_uuid.v4()}';
  }
}
