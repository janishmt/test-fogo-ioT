/// Modèle immuable représentant un appareil IoT découvert sur le réseau.
///
/// Utilise [Equatable] pour que deux instances avec les mêmes valeurs
/// soient considérées égales (important pour BLoC : évite les rebuilds inutiles).
///
/// Toute mise à jour passe par [copyWith] qui retourne une nouvelle instance
/// (immutabilité fonctionnelle).

import 'package:equatable/equatable.dart';
import 'connection_status.dart';

class Device extends Equatable {
  const Device({
    required this.ip,
    required this.port,
    required this.deviceId,
    required this.name,
    required this.status,
    required this.healthScore,
    required this.lastSeen,
    required this.uptimeSeconds,
    required this.successiveFailures,
    required this.lastResponseMs,
  });

  /// Adresse IP de l'appareil sur le réseau local.
  final String ip;

  /// Port CoAP (toujours 5683 dans cette app).
  final int port;

  /// Identifiant unique généré par le simulateur au démarrage (ex: "device-4271").
  final String deviceId;

  /// Nom lisible de l'appareil (ex: "DeviceSim").
  final String name;

  /// Statut de connexion calculé par [StatusRules.compute].
  final ConnectionStatus status;

  /// Score de santé de 0 à 100 calculé par [StatusRules.computeScore].
  final int healthScore;

  /// Horodatage de la dernière réponse reçue. Null si l'appareil n'a jamais répondu.
  final DateTime? lastSeen;

  /// Durée de fonctionnement de l'appareil en secondes (fournie par /health).
  final int uptimeSeconds;

  /// Nombre d'échecs de ping consécutifs depuis la dernière réponse réussie.
  /// Remis à 0 à chaque succès.
  final int successiveFailures;

  /// Latence du dernier ping réussi en millisecondes. Null si aucun succès.
  final int? lastResponseMs;

  /// Retourne une copie de cet appareil avec les champs spécifiés modifiés.
  /// Les champs non fournis conservent leur valeur actuelle.
  /// Note : [ip], [port], [deviceId] et [name] ne changent jamais après la découverte.
  Device copyWith({
    ConnectionStatus? status,
    int? healthScore,
    DateTime? lastSeen,
    int? uptimeSeconds,
    int? successiveFailures,
    int? lastResponseMs,
  }) {
    return Device(
      ip: ip,
      port: port,
      deviceId: deviceId,
      name: name,
      status: status ?? this.status,
      healthScore: healthScore ?? this.healthScore,
      lastSeen: lastSeen ?? this.lastSeen,
      uptimeSeconds: uptimeSeconds ?? this.uptimeSeconds,
      successiveFailures: successiveFailures ?? this.successiveFailures,
      lastResponseMs: lastResponseMs ?? this.lastResponseMs,
    );
  }

  /// Champs utilisés par Equatable pour comparer deux Device.
  /// Deux Device sont égaux si et seulement si tous ces champs sont identiques.
  @override
  List<Object?> get props => [
        ip,
        port,
        deviceId,
        name,
        status,
        healthScore,
        lastSeen,
        uptimeSeconds,
        successiveFailures,
        lastResponseMs,
      ];
}
