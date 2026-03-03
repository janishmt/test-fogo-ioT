/// Constantes globales de l'application Fogo.
///
/// Centralise tous les paramètres de configuration réseau et temporels
/// pour faciliter les ajustements sans chasser les valeurs dans tout le code.
class AppConstants {
  /// Port standard CoAP (UDP). Défini par la RFC 7252.
  static const int coapPort = 5683;

  /// Timeout pour la phase de découverte initiale d'un appareil.
  /// Si l'appareil ne répond pas en 3s lors du scan, il est ignoré.
  static const Duration discoveryTimeout = Duration(seconds: 3);

  /// Intervalle entre deux pings de santé (GET /health) sur un appareil déjà connu.
  static const Duration healthPingInterval = Duration(seconds: 10);

  /// Timeout pour chaque ping de santé individuel.
  /// Plus court que l'intervalle pour éviter les pings qui se chevauchent.
  static const Duration healthPingTimeout = Duration(seconds: 4);

  /// Intervalle du rafraîchissement automatique de la température.
  static const Duration temperatureRefreshInterval = Duration(seconds: 5);

  /// Nombre maximum de sondes réseau lancées en parallèle lors du scan.
  /// Évite de saturer le réseau ou le système avec trop de sockets simultanés.
  static const int maxConcurrentProbes = 20;

  /// Nombre d'échecs consécutifs à partir duquel un appareil passe en Offline.
  static const int offlineThreshold = 3;

  /// Adresses loopback toujours incluses dans le scan.
  /// Permet de tester en local avec plusieurs instances du simulateur
  /// sur 127.0.0.1, 127.0.0.2, etc. (aliases loopback Windows/Linux).
  static const List<String> alwaysScanHosts = [
    '127.0.0.1',
    '127.0.0.2',
    '127.0.0.3',
    '127.0.0.4',
    '127.0.0.5',
  ];
}
