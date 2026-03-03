/// Badge coloré indiquant le statut de connexion d'un appareil.
///
/// Mapping statut → couleur :
///   Online   → vert   (appareil joignable et réactif)
///   Degraded → orange (lent ou 1-2 échecs consécutifs)
///   Offline  → rouge  (≥3 échecs consécutifs)
///   Unknown  → gris   (jamais répondu)

import 'package:flutter/material.dart';
import '../data/models/connection_status.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final ConnectionStatus status;

  @override
  Widget build(BuildContext context) {
    // Déstructuration via pattern matching Dart 3 — extrait label et couleur en une ligne
    final (label, color) = switch (status) {
      ConnectionStatus.online => ('Online', Colors.green.shade600),
      ConnectionStatus.degraded => ('Degraded', Colors.orange.shade700),
      ConnectionStatus.offline => ('Offline', Colors.red.shade600),
      ConnectionStatus.unknown => ('Unknown', Colors.grey.shade500),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12), // pill shape
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
