part of 'discovery_bloc.dart';

/// Classe de base pour tous les événements de [DiscoveryBloc].
///
/// Dans le pattern BLoC, les Events sont les "intentions" envoyées par l'UI
/// ou d'autres parties de l'app vers le BLoC. Le BLoC les traite et émet
/// un nouvel état en réponse.
abstract class DiscoveryEvent extends Equatable {
  const DiscoveryEvent();

  @override
  List<Object> get props => [];
}

/// Déclenche un scan réseau complet.
///
/// Envoyé lorsque l'utilisateur appuie sur le bouton "Scanner"
/// ou l'icône loupe dans la AppBar.
class DiscoveryScanRequested extends DiscoveryEvent {
  const DiscoveryScanRequested();
}
