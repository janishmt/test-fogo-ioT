part of 'device_monitor_bloc.dart';

/// État du [DeviceMonitorBloc] : snapshot de tous les appareils surveillés.
class DeviceMonitorState extends Equatable {
  const DeviceMonitorState({this.devices = const {}});

  /// Map deviceId → Device pour des lookups en O(1).
  ///
  /// Utiliser une Map plutôt qu'une List permet de mettre à jour
  /// un seul appareil sans reconstruire toute la liste.
  final Map<String, Device> devices;

  /// Liste triée alphabétiquement par nom, utilisée par l'UI pour l'affichage.
  ///
  /// Calculé à la demande (getter) plutôt que stocké, pour éviter la duplication.
  List<Device> get deviceList {
    final list = devices.values.toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  DeviceMonitorState copyWith({Map<String, Device>? devices}) {
    return DeviceMonitorState(devices: devices ?? this.devices);
  }

  @override
  List<Object> get props => [devices];
}
