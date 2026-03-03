part of 'temperature_bloc.dart';

/// Phases du cycle de vie de la donnée température.
enum TemperatureStatus {
  initial,  // état de départ, avant tout chargement
  loading,  // premier chargement en cours (affiche un spinner)
  loaded,   // donnée disponible (chargement initial ou rafraîchissement réussi)
  updating, // PUT en cours (désactive le formulaire)
  error,    // erreur réseau (affiche un SnackBar)
}

/// État du [TemperatureBloc] pour un appareil donné.
class TemperatureState extends Equatable {
  const TemperatureState({
    this.status = TemperatureStatus.initial,
    this.reading,
    this.errorMessage,
  });

  /// Phase actuelle.
  final TemperatureStatus status;

  /// Dernière lecture de température disponible.
  /// Conservée même en cas d'erreur de rafraîchissement (dernière valeur connue).
  final TemperatureReading? reading;

  /// Message d'erreur, non-null uniquement si [status] == [TemperatureStatus.error].
  final String? errorMessage;

  TemperatureState copyWith({
    TemperatureStatus? status,
    TemperatureReading? reading,
    String? errorMessage,
  }) {
    return TemperatureState(
      status: status ?? this.status,
      reading: reading ?? this.reading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, reading, errorMessage];
}
