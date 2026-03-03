/// BLoC de découverte réseau.
///
/// Gère le cycle de vie d'un scan réseau :
///   idle → scanning (appareils ajoutés un par un) → complete | error
///
/// Architecture BLoC :
///   Event  : [DiscoveryScanRequested] (déclenché par l'utilisateur)
///   State  : [DiscoveryState] (statut du scan + liste des appareils trouvés)
///   Sortie : quand le scan est complet, [DiscoveryScreen] transfère chaque
///            appareil au [DeviceMonitorBloc] via un BlocListener.

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

import '../../../data/models/device.dart';
import '../../../data/repositories/discovery_repository.dart';

part 'discovery_event.dart';
part 'discovery_state.dart';

class DiscoveryBloc extends Bloc<DiscoveryEvent, DiscoveryState> {
  DiscoveryBloc({required this.discoveryRepository})
      : super(const DiscoveryState()) {
    on<DiscoveryScanRequested>(_onScanRequested);
  }

  final DiscoveryRepository discoveryRepository;
  final _log = Logger('DiscoveryBloc');

  /// Gère l'événement [DiscoveryScanRequested].
  ///
  /// Utilise [emit.forEach] pour consommer le Stream de découverte :
  ///   - Chaque appareil trouvé → l'ajoute à [discoveredDevices] et émet un nouvel état
  ///   - Erreur dans le Stream → passe en statut [error]
  ///   - Stream terminé → passe en statut [complete]
  Future<void> _onScanRequested(
    DiscoveryScanRequested event,
    Emitter<DiscoveryState> emit,
  ) async {
    // Réinitialise la liste avant chaque nouveau scan
    emit(state.copyWith(
      status: DiscoveryStatus.scanning,
      discoveredDevices: [],
    ));

    try {
      // emit.forEach est la méthode BLoC pour consommer un Stream de manière sûre.
      // Elle gère automatiquement l'annulation si le BLoC est fermé en cours de scan.
      await emit.forEach<Device>(
        discoveryRepository.scanNetwork(),
        onData: (device) => state.copyWith(
          discoveredDevices: [...state.discoveredDevices, device], // accumulation immutable
        ),
        onError: (error, stack) {
          _log.severe('Erreur stream discovery', error, stack);
          return state.copyWith(
            status: DiscoveryStatus.error,
            errorMessage: error.toString(),
          );
        },
      );
      // Le Stream s'est terminé normalement
      emit(state.copyWith(status: DiscoveryStatus.complete));
      _log.info(
        'Scan terminé : ${state.discoveredDevices.length} device(s) trouvé(s)',
      );
    } catch (e, st) {
      _log.severe('Scan échoué', e, st);
      emit(state.copyWith(
        status: DiscoveryStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
