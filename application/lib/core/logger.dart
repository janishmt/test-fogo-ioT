/// Configuration du système de logs pour toute l'application.
///
/// Utilise le package `logging` (Dart standard) plutôt que de simples `print`.
/// Chaque classe crée son propre Logger nommé (ex: Logger('CoapRepository'))
/// ce qui permet de filtrer les logs par source.

import 'package:logging/logging.dart';

/// Initialise le logger racine avec un format lisible.
///
/// À appeler une seule fois dans [main], avant [runApp].
///
/// Format de sortie :
///   [INFO   ] 14:32:01.123 CoapRepository: Probe timeout: 192.168.1.42
///   [WARNING] 14:32:05.456 DeviceMonitorBloc: Ping échoué — 2 échec(s)
void setupLogging() {
  hierarchicalLoggingEnabled = true; // permet de configurer des niveaux par logger
  Logger.root.level = Level.ALL;     // capture tous les niveaux (FINE, INFO, WARNING, SEVERE…)
  Logger.root.onRecord.listen((record) {
    // Extrait hh:mm:ss.mmm depuis le timestamp ISO 8601
    final time = record.time.toIso8601String().substring(11, 23);
    final level = record.level.name.padRight(7); // aligne sur 7 caractères pour la lisibilité
    // ignore: avoid_print
    print('[$level] $time ${record.loggerName}: ${record.message}');
    if (record.error != null) {
      // ignore: avoid_print
      print('  ERROR: ${record.error}');
    }
    if (record.stackTrace != null) {
      // ignore: avoid_print
      print('  STACK: ${record.stackTrace}');
    }
  });
}
