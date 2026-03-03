/// Repository de découverte réseau.
///
/// Responsable de deux choses :
///   1. Calculer la liste des IPs à scanner ([computeScanTargets])
///   2. Scanner ces IPs en parallèle et émettre les appareils trouvés ([scanNetwork])
///
/// Stratégie de scan :
///   - Toujours scanner 127.0.0.1–127.0.0.5 (loopback pour tests locaux)
///   - Ajouter tout le subnet /24 de l'IP Wi-Fi (ex: 192.168.1.1–254)
///   - Si Wi-Fi indisponible, utiliser NetworkInterface.list() (couvre Ethernet Windows)
///
/// Le scan utilise des batches de [AppConstants.maxConcurrentProbes] sondes
/// simultanées pour ne pas saturer le réseau ni le système.

import 'dart:io';

import 'package:logging/logging.dart';
import 'package:network_info_plus/network_info_plus.dart';

import '../../core/constants.dart';
import '../models/device.dart';
import 'coap_repository.dart';

class DiscoveryRepository {
  DiscoveryRepository({required this.coapRepository});

  final CoapRepository coapRepository;
  final _log = Logger('DiscoveryRepository');
  final _networkInfo = NetworkInfo(); // plugin Flutter pour récupérer l'IP Wi-Fi

  /// Calcule la liste complète des IPs à sonder.
  ///
  /// Ordre de priorité :
  ///   1. [AppConstants.alwaysScanHosts] (loopback 127.0.0.1–5) — toujours inclus
  ///   2. Subnet Wi-Fi /24 via [NetworkInfo.getWifiIP()] — si disponible
  ///   3. Toutes les interfaces IPv4 via [NetworkInterface.list()] — fallback (Ethernet, VPN…)
  Future<List<String>> computeScanTargets() async {
    final targets = <String>{...AppConstants.alwaysScanHosts}; // Set pour éviter les doublons

    try {
      final wifiIp = await _networkInfo.getWifiIP();
      if (wifiIp != null && wifiIp.isNotEmpty) {
        _addSubnet(targets, wifiIp); // ajoute les 254 IPs du subnet Wi-Fi
      }
    } catch (_) {
      // Wi-Fi non disponible (mode avion, desktop sans Wi-Fi) → on passe au fallback
    }

    // Si on n'a trouvé que les loopbacks, on essaie les interfaces réseau directement
    if (targets.length <= AppConstants.alwaysScanHosts.length) {
      try {
        final interfaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4,
          includeLoopback: false, // loopback déjà ajouté manuellement
        );
        for (final iface in interfaces) {
          for (final addr in iface.addresses) {
            _addSubnet(targets, addr.address);
          }
        }
      } catch (e) {
        _log.warning('Impossible de lister les interfaces réseau: $e');
      }
    }

    _log.info('Scan de ${targets.length} hôtes (loopback + réseau local)');
    return targets.toList();
  }

  /// Ajoute les 254 IPs d'un subnet /24 dans [targets].
  ///
  /// Ex: pour localIp = "192.168.1.42", ajoute "192.168.1.1" à "192.168.1.254".
  void _addSubnet(Set<String> targets, String localIp) {
    final parts = localIp.split('.');
    if (parts.length == 4) {
      final subnet = '${parts[0]}.${parts[1]}.${parts[2]}';
      for (int i = 1; i <= 254; i++) {
        targets.add('$subnet.$i');
      }
      _log.info('Sous-réseau ajouté : $subnet.0/24');
    }
  }

  /// Scanne le réseau et émet chaque [Device] trouvé dès qu'il répond.
  ///
  /// Utilise un Stream pour que l'UI puisse afficher les appareils au fur et à mesure,
  /// sans attendre la fin du scan complet (qui peut prendre plusieurs secondes).
  ///
  /// Les sondes sont lancées par batches de [AppConstants.maxConcurrentProbes]
  /// puis attendues avec [Future.wait] avant de passer au batch suivant.
  Stream<Device> scanNetwork() async* {
    final targets = await computeScanTargets();
    _log.info('Démarrage du scan de ${targets.length} hôtes...');

    final batch = <Future<Device?>>[];

    for (final ip in targets) {
      batch.add(coapRepository.probeHealth(ip));

      // Quand le batch est plein, on attend toutes les sondes et on émet les résultats
      if (batch.length >= AppConstants.maxConcurrentProbes) {
        final results = await Future.wait(batch);
        for (final device in results.whereType<Device>()) { // filtre les null (IPs sans appareil)
          _log.info('Découvert : ${device.name} (${device.deviceId}) @ ${device.ip}');
          yield device; // émis immédiatement dans le Stream → l'UI s'actualise
        }
        batch.clear();
      }
    }

    // Traite le dernier batch (souvent incomplet)
    if (batch.isNotEmpty) {
      final results = await Future.wait(batch);
      for (final device in results.whereType<Device>()) {
        _log.info('Découvert : ${device.name} (${device.deviceId}) @ ${device.ip}');
        yield device;
      }
    }

    _log.info('Scan terminé.');
  }
}
