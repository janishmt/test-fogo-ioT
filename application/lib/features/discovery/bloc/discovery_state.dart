part of 'discovery_bloc.dart';

/// Phases du cycle de vie d'un scan réseau.
enum DiscoveryStatus {
  idle,     // aucun scan en cours (état initial)
  scanning, // scan actif — appareils ajoutés progressivement
  complete, // scan terminé avec succès
  error,    // scan interrompu par une erreur
}

/// État courant du [DiscoveryBloc].
///
/// Immuable — toute modification passe par [copyWith].
class DiscoveryState extends Equatable {
  const DiscoveryState({
    this.status = DiscoveryStatus.idle,
    this.discoveredDevices = const [],
    this.errorMessage,
  });

  /// Phase actuelle du scan.
  final DiscoveryStatus status;

  /// Appareils découverts jusqu'ici (croît au fur et à mesure du scan).
  final List<Device> discoveredDevices;

  /// Message d'erreur, non-null uniquement si [status] == [DiscoveryStatus.error].
  final String? errorMessage;

  DiscoveryState copyWith({
    DiscoveryStatus? status,
    List<Device>? discoveredDevices,
    String? errorMessage,
  }) {
    return DiscoveryState(
      status: status ?? this.status,
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, discoveredDevices, errorMessage];
}
