/// Statuts de connexion possibles pour un appareil IoT surveillé.
///
/// La progression typique est :
///   unknown → online → degraded → offline
/// mais un appareil peut passer directement de online à offline (3 échecs d'affilée).

enum ConnectionStatus { unknown, online, degraded, offline }

/// Contient la logique de calcul du statut et du score de santé.
///
/// Ces règles sont séparées dans une classe statique pour pouvoir être
/// testées indépendamment de l'UI et du BLoC (voir status_rules_test.dart).
class StatusRules {
  /// Calcule le statut de connexion selon les résultats de ping récents.
  ///
  /// Règles (appliquées dans cet ordre) :
  /// - [unknown]  : jamais eu de réponse
  /// - [offline]  : ≥ 3 échecs consécutifs
  /// - [degraded] : 1 ou 2 échecs consécutifs
  /// - [degraded] : 0 échec mais latence ≥ 2000 ms (réseau lent)
  /// - [online]   : 0 échec et latence < 2000 ms
  static ConnectionStatus compute({
    required int successiveFailures,
    required int? lastResponseMs,
    required bool hasEverResponded,
  }) {
    if (!hasEverResponded) return ConnectionStatus.unknown;
    if (successiveFailures >= 3) return ConnectionStatus.offline;
    if (successiveFailures >= 1) return ConnectionStatus.degraded;
    // successiveFailures == 0 : dernière tentative réussie
    if (lastResponseMs != null && lastResponseMs >= 2000) {
      return ConnectionStatus.degraded; // trop lent même sans échec
    }
    return ConnectionStatus.online;
  }

  /// Calcule un score de santé de 0 à 100.
  ///
  /// Formule : 100 − (failures × 30) − latencyPenalty, borné à [0, 100]
  ///
  /// La pénalité de latence commence à 500ms et augmente de 1 point par 50ms
  /// supplémentaires, jusqu'à un maximum de 40 points :
  ///   latencyPenalty = clamp((lastMs − 500) / 50, 0, 40)
  ///
  /// Exemples :
  ///   0 échec, 200ms  → score = 100
  ///   0 échec, 1000ms → score = 90  (pénalité = 10)
  ///   1 échec, 200ms  → score = 70  (pénalité failure = 30)
  ///   2 échecs        → score = 40
  ///   3 échecs        → score = 0
  static int computeScore({
    required int successiveFailures,
    required int? lastResponseMs,
  }) {
    if (successiveFailures >= 3) return 0; // offline = score nul
    final failurePenalty = successiveFailures * 30;
    final latencyPenalty = lastResponseMs == null
        ? 0
        : ((lastResponseMs - 500) / 50).clamp(0.0, 40.0).toInt();
    return (100 - failurePenalty - latencyPenalty).clamp(0, 100);
  }
}
