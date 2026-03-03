// Point d'entrée de l'application Flutter Fogo.
//
// Responsabilités :
//   1. Initialiser le système de logs.
//   2. Instancier les repositories (couche d'accès aux données réseau).
//   3. Injecter ces dépendances dans l'arbre de widgets via les Providers BLoC.
//   4. Configurer le thème Material3 et démarrer sur DiscoveryScreen.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/logger.dart';
import 'data/repositories/coap_repository.dart';
import 'data/repositories/discovery_repository.dart';
import 'features/device_monitor/bloc/device_monitor_bloc.dart';
import 'features/discovery/bloc/discovery_bloc.dart';
import 'features/discovery/view/discovery_screen.dart';

void main() {
  setupLogging(); // Active les logs formatés dans la console
  runApp(const FogoApp());
}

class FogoApp extends StatelessWidget {
  const FogoApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Création des repositories (singleton pour toute la durée de vie de l'app)
    final coapRepo = CoapRepository();
    final discoveryRepo = DiscoveryRepository(coapRepository: coapRepo);

    return MultiRepositoryProvider(
      // MultiRepositoryProvider rend les repositories accessibles
      // à tous les descendants via context.read<XxxRepository>()
      providers: [
        RepositoryProvider<CoapRepository>.value(value: coapRepo),
        RepositoryProvider<DiscoveryRepository>.value(value: discoveryRepo),
      ],
      child: MultiBlocProvider(
        // MultiBlocProvider crée et injecte les BLoCs globaux.
        // Ces deux BLoCs vivent aussi longtemps que l'application :
        //   - DiscoveryBloc   : gère le scan réseau
        //   - DeviceMonitorBloc : gère la surveillance continue de chaque appareil
        providers: [
          BlocProvider(
            create: (_) => DiscoveryBloc(discoveryRepository: discoveryRepo),
          ),
          BlocProvider(
            create: (_) => DeviceMonitorBloc(coapRepository: coapRepo),
          ),
        ],
        child: MaterialApp(
          title: 'Fogo IoT Monitor',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepOrange, // couleur principale de l'app
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            cardTheme: const CardThemeData(
              surfaceTintColor: Colors.transparent, // évite la teinte Material3 sur les cartes
            ),
          ),
          home: const DiscoveryScreen(), // écran de démarrage
        ),
      ),
    );
  }
}
