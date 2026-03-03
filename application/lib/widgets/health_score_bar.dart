/// Widget affichant le score de santé d'un appareil (0–100).
///
/// Composé de deux éléments superposés :
///   1. Le score numérique en gras
///   2. Une barre de progression linéaire proportionnelle au score
///
/// La couleur varie selon le seuil :
///   ≥ 70 → vert   (appareil en bonne santé)
///   ≥ 40 → orange (dégradé)
///   <  40 → rouge  (critique ou hors ligne)
///
/// Utilisé dans [DeviceListTile] (colonne gauche) et [DeviceDetailScreen] (en-tête).

import 'package:flutter/material.dart';

class HealthScoreBar extends StatelessWidget {
  const HealthScoreBar({super.key, required this.score});

  /// Score entre 0 et 100 calculé par [StatusRules.computeScore].
  final int score;

  @override
  Widget build(BuildContext context) {
    // Sélection de la couleur selon les seuils de santé
    final color = score >= 70
        ? Colors.green.shade600
        : score >= 40
            ? Colors.orange.shade700
            : Colors.red.shade600;

    return SizedBox(
      width: 44, // largeur fixe pour un alignement cohérent dans les listes
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$score',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: score / 100, // 0.0 à 1.0
              minHeight: 4,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
