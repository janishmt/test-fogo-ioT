/// Écran principal de l'application — liste des appareils découverts.
///
/// Structure de l'écran :
///   AppBar  : titre + bouton scan (loupe ou spinner selon l'état)
///   Body    : bandeau de statut ([_ScanStatusBanner]) + liste ([_DeviceListView])
///   FAB     : bouton "Scanner" (caché pendant le scan)
///
/// Interactions entre BLoCs :
///   - [DiscoveryBloc]     : pilote le scan réseau, fourni l'état de scan
///   - [DeviceMonitorBloc] : reçoit les appareils trouvés pour les surveiller
///
/// Le [BlocListener] transfère chaque appareil découvert vers le [DeviceMonitorBloc]
/// dès que le scan est terminé (statut "complete"). C'est ce qui démarre la
/// surveillance périodique de chaque appareil.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../device_monitor/bloc/device_monitor_bloc.dart';
import '../../device_monitor/view/device_detail_screen.dart';
import '../bloc/discovery_bloc.dart';
import '../../../widgets/device_list_tile.dart';

class DiscoveryScreen extends StatelessWidget {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<DiscoveryBloc, DiscoveryState>(
      // Réagit uniquement quand le scan passe à "complete"
      listenWhen: (prev, curr) => curr.status == DiscoveryStatus.complete,
      listener: (context, state) {
        // Enregistre chaque appareil trouvé dans le monitor pour démarrer le ping périodique
        for (final device in state.discoveredDevices) {
          context
              .read<DeviceMonitorBloc>()
              .add(DeviceMonitorDeviceAdded(device));
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text(
            'Fogo — IoT Monitor',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            // Affiche un spinner pendant le scan, la loupe sinon
            BlocBuilder<DiscoveryBloc, DiscoveryState>(
              builder: (context, state) {
                if (state.status == DiscoveryStatus.scanning) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                return IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: 'Scanner le réseau',
                  onPressed: () => context
                      .read<DiscoveryBloc>()
                      .add(const DiscoveryScanRequested()),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            _ScanStatusBanner(), // bandeau coloré indiquant l'état du scan
            Expanded(child: _DeviceListView()), // liste des appareils (depuis DeviceMonitorBloc)
          ],
        ),
        // FAB visible uniquement quand aucun scan n'est en cours
        floatingActionButton: BlocBuilder<DiscoveryBloc, DiscoveryState>(
          builder: (context, state) {
            if (state.status == DiscoveryStatus.scanning) {
              return const SizedBox.shrink(); // invisible pendant le scan
            }
            return FloatingActionButton.extended(
              onPressed: () => context
                  .read<DiscoveryBloc>()
                  .add(const DiscoveryScanRequested()),
              icon: const Icon(Icons.radar),
              label: const Text('Scanner'),
            );
          },
        ),
      ),
    );
  }
}

/// Bandeau coloré en haut de l'écran indiquant l'état du scan.
///
/// - Bleu   : scan en cours (avec compteur d'appareils trouvés)
/// - Vert   : scan terminé (nombre total d'appareils)
/// - Rouge  : erreur (message d'erreur)
/// - Vide   : état idle (aucun bandeau)
class _ScanStatusBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiscoveryBloc, DiscoveryState>(
      builder: (context, state) {
        if (state.status == DiscoveryStatus.scanning) {
          return Container(
            width: double.infinity,
            color: Colors.blue.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text(
                  'Scan en cours — ${state.discoveredDevices.length} appareil(s) trouvé(s)…',
                  style: TextStyle(fontSize: 13, color: Colors.blue.shade700),
                ),
              ],
            ),
          );
        }
        if (state.status == DiscoveryStatus.error) {
          return Container(
            width: double.infinity,
            color: Colors.red.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              'Erreur scan : ${state.errorMessage}',
              style: TextStyle(fontSize: 13, color: Colors.red.shade700),
            ),
          );
        }
        if (state.status == DiscoveryStatus.complete) {
          return Container(
            width: double.infinity,
            color: Colors.green.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '${state.discoveredDevices.length} appareil(s) trouvé(s)',
              style: TextStyle(fontSize: 13, color: Colors.green.shade700),
            ),
          );
        }
        return const SizedBox.shrink(); // idle : rien à afficher
      },
    );
  }
}

/// Liste des appareils sous surveillance, triés alphabétiquement.
///
/// Écoute [DeviceMonitorBloc] (pas DiscoveryBloc) pour afficher
/// les données en temps réel (statut et score mis à jour par le monitor).
///
/// Affiche un état vide illustré si aucun appareil n'a encore été découvert.
class _DeviceListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeviceMonitorBloc, DeviceMonitorState>(
      builder: (context, state) {
        if (state.devices.isEmpty) {
          // État vide : invitation à scanner
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.device_unknown, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'Aucun appareil détecté',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Appuyez sur Scanner pour détecter les appareils CoAP',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Liste triée par nom (deviceList est un getter trié dans DeviceMonitorState)
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80), // espace pour le FAB
          itemCount: state.deviceList.length,
          itemBuilder: (context, index) {
            final device = state.deviceList[index];
            return DeviceListTile(
              device: device,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DeviceDetailScreen(device: device),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
