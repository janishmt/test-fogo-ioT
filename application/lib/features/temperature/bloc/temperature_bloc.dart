/// BLoC de gestion de la température d'un appareil.
///
/// Créé à chaque ouverture de [DeviceDetailScreen] (scoped BLoC)
/// et détruit à la fermeture de l'écran.
///
/// Comportement :
///   - Charge la température initiale au démarrage (TemperatureLoadRequested)
///   - Lance un timer de rafraîchissement automatique toutes les 5 secondes
///   - Permet à l'utilisateur de modifier la température (TemperatureSetRequested)
///   - Les rafraîchissements automatiques sont "silencieux" : pas de loader affiché
///   - Les erreurs de rafraîchissement automatique sont ignorées (ne montrent pas d'erreur)

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

import '../../../core/constants.dart';
import '../../../data/models/temperature_reading.dart';
import '../../../data/repositories/coap_repository.dart';

part 'temperature_event.dart';
part 'temperature_state.dart';

class TemperatureBloc extends Bloc<TemperatureEvent, TemperatureState> {
  TemperatureBloc({required this.coapRepository})
      : super(const TemperatureState()) {
    on<TemperatureLoadRequested>(_onLoadRequested);
    on<TemperatureSetRequested>(_onSetRequested);
    on<_TemperatureRefreshTick>(_onRefreshTick); // événement interne du timer
  }

  final CoapRepository coapRepository;
  final _log = Logger('TemperatureBloc');
  Timer? _refreshTimer; // timer de rafraîchissement automatique (un seul à la fois)

  /// Charge la température initiale et démarre le timer de rafraîchissement.
  ///
  /// Passe par l'état "loading" pour afficher un indicateur dans l'UI.
  Future<void> _onLoadRequested(
    TemperatureLoadRequested event,
    Emitter<TemperatureState> emit,
  ) async {
    emit(state.copyWith(status: TemperatureStatus.loading));
    try {
      final reading = await coapRepository.getTemperature(event.deviceIp);
      emit(state.copyWith(status: TemperatureStatus.loaded, reading: reading));
      _startRefreshTimer(event.deviceIp); // démarre le refresh automatique
    } catch (e, st) {
      _log.warning('Lecture température échouée pour ${event.deviceIp}', e, st);
      emit(state.copyWith(
        status: TemperatureStatus.error,
        errorMessage: 'Impossible de lire la température : appareil injoignable',
      ));
    }
  }

  /// Met à jour la température via PUT /temperature.
  ///
  /// Passe par l'état "updating" pour désactiver le formulaire pendant l'envoi.
  /// En cas d'erreur, un SnackBar est affiché (géré dans [TemperatureWidget]).
  Future<void> _onSetRequested(
    TemperatureSetRequested event,
    Emitter<TemperatureState> emit,
  ) async {
    emit(state.copyWith(status: TemperatureStatus.updating));
    try {
      final reading = await coapRepository
          .setTemperature(event.deviceIp, event.value)
          .timeout(AppConstants.healthPingTimeout);
      emit(state.copyWith(status: TemperatureStatus.loaded, reading: reading));
      _log.info('Température mise à jour : ${event.value}°C');
    } catch (e, st) {
      _log.warning('PUT température échoué', e, st);
      emit(state.copyWith(
        status: TemperatureStatus.error,
        errorMessage: 'Mise à jour échouée : appareil injoignable',
      ));
    }
  }

  /// Rafraîchissement silencieux déclenché par le timer.
  ///
  /// Ne passe PAS par l'état "loading" pour éviter le clignotement de l'UI.
  /// Les erreurs sont ignorées : si l'appareil ne répond pas, la dernière
  /// valeur connue reste affichée jusqu'au prochain rafraîchissement réussi.
  Future<void> _onRefreshTick(
    _TemperatureRefreshTick event,
    Emitter<TemperatureState> emit,
  ) async {
    // Rafraîchissement silencieux : on ne passe pas en loading
    try {
      final reading = await coapRepository.getTemperature(event.deviceIp);
      emit(state.copyWith(status: TemperatureStatus.loaded, reading: reading));
    } catch (_) {
      // Échec silencieux sur refresh automatique
    }
  }

  /// Démarre (ou redémarre) le timer de rafraîchissement.
  ///
  /// Annule le timer précédent avant d'en créer un nouveau pour éviter
  /// les timers fantômes en cas d'appel multiple.
  void _startRefreshTimer(String deviceIp) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      AppConstants.temperatureRefreshInterval,
      (_) => add(_TemperatureRefreshTick(deviceIp)),
    );
  }

  /// Annule le timer quand l'écran est fermé (BLoC détruit).
  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    return super.close();
  }
}
