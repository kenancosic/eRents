import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

final log = Logger('ERentsApp');

void setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((rec) {
    debugPrint('${rec.level.name}: ${rec.time}: ${rec.message}');
    if (rec.error != null) {
      debugPrint('ERROR: ${rec.error}');
    }
    if (rec.stackTrace != null) {
      debugPrint(rec.stackTrace.toString());
    }
  });
}
