part of 'device_monitor_bloc.dart';

/// Classe de base pour tous les événements du [DeviceMonitorBloc].
abstract class DeviceMonitorEvent extends Equatable {
  const DeviceMonitorEvent();

  @override
  List<Object> get props => [];
}

/// Démarre la surveillance d'un appareil nouvellement découvert.
///
/// Envoyé par [DiscoveryScreen] via un BlocListener quand le scan est terminé.
class DeviceMonitorDeviceAdded extends DeviceMonitorEvent {
  const DeviceMonitorDeviceAdded(this.device);
  final Device device;

  @override
  List<Object> get props => [device];
}

/// Arrête la surveillance d'un appareil (non utilisé dans l'UI actuelle,
/// mais prévu pour une future fonctionnalité de suppression manuelle).
class DeviceMonitorDeviceRemoved extends DeviceMonitorEvent {
  const DeviceMonitorDeviceRemoved(this.deviceId);
  final String deviceId;

  @override
  List<Object> get props => [deviceId];
}

/// Événement interne déclenché par le Timer périodique pour lancer un ping.
///
/// Préfixé par _ car il n'est jamais envoyé depuis l'extérieur du BLoC.
/// Utiliser un Event (plutôt qu'un appel direct) garantit que le traitement
/// passe par la file d'événements BLoC et ne cause pas de race conditions.
class _DeviceMonitorTickFired extends DeviceMonitorEvent {
  const _DeviceMonitorTickFired(this.deviceId);
  final String deviceId;

  @override
  List<Object> get props => [deviceId];
}
