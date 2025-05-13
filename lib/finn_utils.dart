import 'package:finn_utils/utils/finn_util_storage/finn_util_storage.dart';

export 'utils/client/client.dart';
export 'utils/client/helpers/settle.dart';
export 'utils/exceptions/finn_utils_client_exceptions.dart';
export 'utils/exceptions/finn_utils_settler_exception.dart';
export 'utils/finn_util_storage/finn_util_storage.dart';

abstract class FinnUtils {
  static FinnUtilStorage get storage => FinnUtilStorage.instance;

  static Future<void> get initStorage => FinnUtilStorage.initialize();
}
