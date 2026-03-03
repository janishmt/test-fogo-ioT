/// Modèle immuable représentant une lecture de température reçue d'un appareil.
///
/// Correspond directement au JSON retourné par GET /temperature :
///   { "value": 20.0, "unit": "C", "ts": 1712345678 }

import 'package:equatable/equatable.dart';

class TemperatureReading extends Equatable {
  const TemperatureReading({
    required this.value,
    required this.unit,
    required this.timestamp,
  });

  /// Valeur numérique de la température.
  final double value;

  /// Unité de mesure (toujours "C" pour Celsius dans ce projet).
  final String unit;

  /// Horodatage de la mesure, converti depuis le timestamp Unix du JSON.
  final DateTime timestamp;

  /// Désérialise une [TemperatureReading] depuis le JSON de l'appareil.
  ///
  /// Le champ "ts" est un timestamp Unix en secondes → multiplié par 1000
  /// pour obtenir des millisecondes (format attendu par [DateTime]).
  factory TemperatureReading.fromJson(Map<String, dynamic> json) {
    return TemperatureReading(
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (json['ts'] as int) * 1000,
      ),
    );
  }

  @override
  List<Object> get props => [value, unit, timestamp];
}
