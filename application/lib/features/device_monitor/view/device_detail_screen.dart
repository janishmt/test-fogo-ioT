/// Écran de détail d'un appareil IoT.
///
/// Affiche deux sections :
///   1. [_DeviceInfoCard] : informations statiques et métriques de connexion
///      (IP, port, uptime, latence, statut, health score, dernière réponse)
///   2. [TemperatureWidget] : lecture et modification de la température en temps réel
///
/// Important : [TemperatureBloc] est créé ici (BlocProvider scoped) et non dans main.dart,
/// car il est propre à cet écran et doit être détruit quand l'utilisateur revient en arrière.
/// Le BLoC démarre immédiatement le chargement via `..add(TemperatureLoadRequested(...))`.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/device.dart';
import '../../../data/repositories/coap_repository.dart';
import '../../temperature/bloc/temperature_bloc.dart';
import '../../temperature/view/temperature_widget.dart';
import '../../../widgets/status_badge.dart';
import '../../../widgets/health_score_bar.dart';

class DeviceDetailScreen extends StatelessWidget {
  const DeviceDetailScreen({super.key, required this.device});

  /// Snapshot de l'appareil au moment de l'ouverture de l'écran.
  /// Note : cet écran ne se met PAS à jour si le DeviceMonitorBloc modifie l'appareil
  /// (les données affichées dans _DeviceInfoCard sont figées à l'ouverture).
  final Device device;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Crée un TemperatureBloc local à cet écran et charge la température immédiatement
      create: (_) => TemperatureBloc(
        coapRepository: context.read<CoapRepository>(),
      )..add(TemperatureLoadRequested(device.ip)),
      child: Scaffold(
        appBar: AppBar(
          title: Text(device.name),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DeviceInfoCard(device: device), // métriques de connexion
              const Divider(height: 1),
              TemperatureWidget(deviceIp: device.ip), // contrôle température
            ],
          ),
        ),
      ),
    );
  }
}

/// Carte d'informations de connexion d'un appareil.
///
/// Affiche en haut : health score (barre), nom, ID, badge de statut.
/// Puis une liste de métriques : IP, port, uptime, dernière réponse, latence, échecs.
class _DeviceInfoCard extends StatelessWidget {
  const _DeviceInfoCard({required this.device});

  final Device device;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête : score + nom/ID + badge de statut
            Row(
              children: [
                HealthScoreBar(score: device.healthScore),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        device.deviceId,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: device.status),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            // Métriques de connexion en ligne label/valeur
            _InfoRow(label: 'Adresse IP', value: device.ip),
            _InfoRow(label: 'Port', value: '${device.port}'),
            _InfoRow(
              label: 'Uptime',
              value: _formatUptime(device.uptimeSeconds),
            ),
            _InfoRow(
              label: 'Dernière réponse',
              value: device.lastSeen != null
                  ? _formatLastSeen(device.lastSeen!)
                  : 'Jamais',
            ),
            if (device.lastResponseMs != null)
              _InfoRow(
                label: 'Latence',
                value: '${device.lastResponseMs} ms',
              ),
            _InfoRow(
              label: 'Échecs consécutifs',
              value: '${device.successiveFailures}',
            ),
          ],
        ),
      ),
    );
  }

  /// Formate une durée en secondes en texte lisible (42s / 5min 3s / 1h 30min).
  String _formatUptime(int seconds) {
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${seconds ~/ 60}min ${seconds % 60}s';
    return '${seconds ~/ 3600}h ${(seconds % 3600) ~/ 60}min';
  }

  /// Formate un DateTime en durée relative (il y a 5s / il y a 3min / il y a 2h).
  String _formatLastSeen(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'il y a ${diff.inSeconds}s';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes}min';
    return 'il y a ${diff.inHours}h';
  }
}

/// Ligne d'information : [label] à gauche, [value] à droite.
/// Utilisée pour afficher les métriques de connexion de façon homogène.
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
