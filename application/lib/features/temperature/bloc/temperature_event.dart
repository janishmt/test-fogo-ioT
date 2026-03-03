part of 'temperature_bloc.dart';

/// Classe de base pour tous les événements du [TemperatureBloc].
abstract class TemperatureEvent extends Equatable {
  const TemperatureEvent();

  @override
  List<Object> get props => [];
}

/// Demande le chargement initial de la température d'un appareil.
///
/// Envoyé automatiquement à la création du BLoC dans [DeviceDetailScreen].
class TemperatureLoadRequested extends TemperatureEvent {
  const TemperatureLoadRequested(this.deviceIp);
  final String deviceIp;

  @override
  List<Object> get props => [deviceIp];
}

/// Demande la modification de la température via PUT /temperature.
///
/// Envoyé lorsque l'utilisateur soumet le formulaire dans [TemperatureWidget].
class TemperatureSetRequested extends TemperatureEvent {
  const TemperatureSetRequested({required this.deviceIp, required this.value});
  final String deviceIp;
  final double value; // nouvelle valeur en degrés Celsius

  @override
  List<Object> get props => [deviceIp, value];
}

/// Événement interne déclenché par le timer de rafraîchissement automatique.
///
/// Préfixé par _ car il n'est jamais envoyé depuis l'extérieur du BLoC.
class _TemperatureRefreshTick extends TemperatureEvent {
  const _TemperatureRefreshTick(this.deviceIp);
  final String deviceIp;

  @override
  List<Object> get props => [deviceIp];
}
