/// BLoC de surveillance continue des appareils IoT.
///
/// Maintient un Timer par appareil surveillé qui déclenche un ping (GET /health)
/// toutes les [AppConstants.healthPingInterval] secondes.
///
/// Gestion des états par appareil :
///   - Ping réussi  → reset successiveFailures, mise à jour latence/uptime/statut
///   - Ping échoué  → incrémente successiveFailures → recalcule statut et score
///
/// Protection contre les pings simultanés : un drapeau [_pinging] par appareil
/// empêche de lancer un nouveau ping si le précédent est encore en cours.
///
/// Cycle de vie des ressources :
///   - Timer créé dans [_onDeviceAdded], annulé dans [_onDeviceRemoved] ou [close]
///   - [close] override garantit l'annulation de tous les timers quand le BLoC est détruit

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

import '../../../core/constants.dart';
import '../../../data/models/connection_status.dart';
import '../../../data/models/device.dart';
import '../../../data/repositories/coap_repository.dart';

part 'device_monitor_event.dart';
part 'device_monitor_state.dart';

class DeviceMonitorBloc
    extends Bloc<DeviceMonitorEvent, DeviceMonitorState> {
  DeviceMonitorBloc({required this.coapRepository})
      : super(const DeviceMonitorState()) {
    on<DeviceMonitorDeviceAdded>(_onDeviceAdded);
    on<DeviceMonitorDeviceRemoved>(_onDeviceRemoved);
    on<_DeviceMonitorTickFired>(_onTickFired); // événement interne (privé)
  }

  final CoapRepository coapRepository;
  final _log = Logger('DeviceMonitorBloc');

  /// Map deviceId → Timer périodique de ping.
  final Map<String, Timer> _timers = {};

  /// Map deviceId → booléen "un ping est en cours".
  /// Évite les pings qui se chevauchent si la réponse est plus longue que l'intervalle.
  final Map<String, bool> _pinging = {};

  /// Ajoute un appareil à la surveillance et démarre son timer de ping.
  ///
  /// Si l'appareil existe déjà (re-scan), son timer est réinitialisé.
  Future<void> _onDeviceAdded(
    DeviceMonitorDeviceAdded event,
    Emitter<DeviceMonitorState> emit,
  ) async {
    final device = event.device;
    final updated = Map<String, Device>.from(state.devices)
      ..[device.deviceId] = device;
    emit(state.copyWith(devices: updated));

    // Annule l'éventuel timer existant avant d'en créer un nouveau
    _timers[device.deviceId]?.cancel();
    _timers[device.deviceId] = Timer.periodic(
      AppConstants.healthPingInterval,
      (_) => add(_DeviceMonitorTickFired(device.deviceId)), // envoie un event interne à chaque tick
    );
    _pinging[device.deviceId] = false;
    _log.info('Surveillance démarrée : ${device.name} @ ${device.ip}');
  }

  /// Arrête la surveillance d'un appareil et supprime son timer.
  Future<void> _onDeviceRemoved(
    DeviceMonitorDeviceRemoved event,
    Emitter<DeviceMonitorState> emit,
  ) async {
    _timers[event.deviceId]?.cancel();
    _timers.remove(event.deviceId);
    _pinging.remove(event.deviceId);
    final updated = Map<String, Device>.from(state.devices)
      ..remove(event.deviceId);
    emit(state.copyWith(devices: updated));
    _log.info('Surveillance arrêtée : ${event.deviceId}');
  }

  /// Exécute un ping pour l'appareil identifié par [event.deviceId].
  ///
  /// Ignoré si un ping est déjà en cours pour cet appareil (protection contre
  /// les chevauchements quand l'appareil répond plus lentement que l'intervalle).
  Future<void> _onTickFired(
    _DeviceMonitorTickFired event,
    Emitter<DeviceMonitorState> emit,
  ) async {
    final current = state.devices[event.deviceId];
    if (current == null) return; // appareil retiré entre-temps

    // Évite les pings simultanés pour le même device
    if (_pinging[event.deviceId] == true) return;
    _pinging[event.deviceId] = true;

    final stopwatch = Stopwatch()..start();
    try {
      final probed = await coapRepository
          .probeHealth(current.ip)
          .timeout(AppConstants.healthPingTimeout);
      stopwatch.stop();

      final Device updated;
      if (probed != null) {
        // Ping réussi : remet les échecs à 0 et met à jour latence/uptime/statut
        final ms = stopwatch.elapsedMilliseconds;
        updated = current.copyWith(
          successiveFailures: 0,
          lastSeen: DateTime.now(),
          lastResponseMs: ms,
          uptimeSeconds: probed.uptimeSeconds,
          status: StatusRules.compute(
            successiveFailures: 0,
            lastResponseMs: ms,
            hasEverResponded: true,
          ),
          healthScore: StatusRules.computeScore(
            successiveFailures: 0,
            lastResponseMs: ms,
          ),
        );
      } else {
        // Ping échoué : incrémente le compteur d'échecs
        updated = _buildFailure(current);
      }

      _emitUpdate(emit, updated);
    } catch (_) {
      // Timeout ou exception réseau inattendue → traité comme un échec
      _emitUpdate(emit, _buildFailure(current));
    } finally {
      _pinging[event.deviceId] = false; // libère le verrou dans tous les cas
    }
  }

  /// Construit une version "échec" d'un appareil (failures + 1, statut/score recalculés).
  Device _buildFailure(Device current) {
    final failures = current.successiveFailures + 1;
    _log.warning(
      'Ping échoué pour ${current.name} — '
      '$failures échec(s) consécutif(s)',
    );
    return current.copyWith(
      successiveFailures: failures,
      status: StatusRules.compute(
        successiveFailures: failures,
        lastResponseMs: current.lastResponseMs,
        hasEverResponded: current.lastSeen != null,
      ),
      healthScore: StatusRules.computeScore(
        successiveFailures: failures,
        lastResponseMs: current.lastResponseMs,
      ),
    );
  }

  /// Émet un nouvel état avec l'appareil mis à jour dans la map.
  void _emitUpdate(Emitter<DeviceMonitorState> emit, Device updated) {
    final devices = Map<String, Device>.from(state.devices)
      ..[updated.deviceId] = updated;
    emit(state.copyWith(devices: devices));
  }

  /// Annule tous les timers actifs quand le BLoC est fermé (navigation, dispose).
  @override
  Future<void> close() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _pinging.clear();
    return super.close();
  }
}
