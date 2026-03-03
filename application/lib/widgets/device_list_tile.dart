/// Item de liste représentant un appareil IoT dans [DiscoveryScreen].
///
/// Disposition :
///   Gauche   : [HealthScoreBar] (score numérique + barre de progression colorée)
///   Centre   : nom de l'appareil + IP + ID
///   Droite   : [StatusBadge] (Online/Degraded/Offline/Unknown) + "il y a Xs"
///
/// Appuyer sur la tile navigue vers [DeviceDetailScreen].

import 'package:flutter/material.dart';
import '../data/models/device.dart';
import 'health_score_bar.dart';
import 'status_badge.dart';

class DeviceListTile extends StatelessWidget {
  const DeviceListTile({
    super.key,
    required this.device,
    required this.onTap,
  });

  final Device device;
  final VoidCallback onTap; // callback de navigation fourni par [_DeviceListView]

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: HealthScoreBar(score: device.healthScore), // score à gauche
        title: Text(
          device.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              device.ip,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            Text(
              'ID: ${device.deviceId}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            StatusBadge(status: device.status), // badge coloré Online/Degraded/…
            const SizedBox(height: 4),
            Text(
              _formatLastSeen(device.lastSeen),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  /// Formate la date de dernière réponse en texte relatif.
  /// Retourne "Jamais vu" si l'appareil n'a jamais répondu.
  String _formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'Jamais vu';
    final diff = DateTime.now().difference(lastSeen);
    if (diff.inSeconds < 60) return 'il y a ${diff.inSeconds}s';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes}min';
    return 'il y a ${diff.inHours}h';
  }
}
