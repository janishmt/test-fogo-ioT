/// Widget de contrôle de la température d'un appareil.
///
/// Utilise [BlocConsumer] qui combine BlocBuilder (rebuild UI) et BlocListener
/// (effets de bord comme afficher un SnackBar) en un seul widget.
///
/// Structure :
///   - Section "Température actuelle" : affiche la valeur avec timestamp
///   - Section "Modifier la température" : formulaire de saisie + bouton envoi
///
/// Comportements clés :
///   - Lors d'un chargement initial ou en cours → spinner
///   - Lors d'une mise à jour (PUT) → spinner dans le bouton + formulaire désactivé
///   - Erreur (chargement ou mise à jour) → SnackBar rouge (via listener)
///   - Le rafraîchissement automatique (toutes les 5s) met à jour silencieusement
///     la valeur sans afficher de spinner

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/temperature_bloc.dart';

class TemperatureWidget extends StatefulWidget {
  const TemperatureWidget({super.key, required this.deviceIp});

  final String deviceIp;

  @override
  State<TemperatureWidget> createState() => _TemperatureWidgetState();
}

class _TemperatureWidgetState extends State<TemperatureWidget> {
  final _controller = TextEditingController(); // contrôleur du champ texte

  @override
  void dispose() {
    _controller.dispose(); // libère le contrôleur quand le widget est détruit
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TemperatureBloc, TemperatureState>(
      // listener : réagit aux changements d'état sans rebuild (effets de bord)
      listener: (context, state) {
        if (state.status == TemperatureStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Erreur inconnue'),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      // builder : reconstruit l'UI à chaque nouvel état
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCurrentTemperature(context, state), // carte de la valeur actuelle
              const SizedBox(height: 32),
              _buildSetTemperatureForm(context, state), // formulaire de modification
            ],
          ),
        );
      },
    );
  }

  /// Carte affichant la température actuelle.
  ///
  /// Affiche un spinner si la donnée n'est pas encore chargée,
  /// sinon la valeur en grand format avec le timestamp de la mesure.
  Widget _buildCurrentTemperature(
    BuildContext context,
    TemperatureState state,
  ) {
    final isLoading = state.status == TemperatureStatus.initial ||
        state.status == TemperatureStatus.loading;

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        child: Column(
          children: [
            Text(
              'Température actuelle',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 12),
            isLoading
                ? const CircularProgressIndicator()
                : Text(
                    state.reading != null
                        ? '${state.reading!.value.toStringAsFixed(1)} °${state.reading!.unit}'
                        : '--', // aucune donnée disponible
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
            // Timestamp de la mesure, affiché uniquement si la donnée est disponible
            if (state.reading != null) ...[
              const SizedBox(height: 8),
              Text(
                'Mis à jour : ${_formatTimestamp(state.reading!.timestamp)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Formulaire de modification de la température.
  ///
  /// Le champ texte et le bouton sont désactivés pendant un PUT en cours.
  /// Le bouton affiche un spinner pendant la mise à jour.
  Widget _buildSetTemperatureForm(
    BuildContext context,
    TemperatureState state,
  ) {
    final isUpdating = state.status == TemperatureStatus.updating;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Modifier la température',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Nouvelle valeur (°C)',
            border: const OutlineInputBorder(),
            suffixText: '°C',
            enabled: !isUpdating, // désactivé pendant le PUT
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: isUpdating ? null : () => _submit(context), // null = bouton grisé
          icon: isUpdating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          label: Text(isUpdating ? 'Envoi...' : 'Mettre à jour'),
        ),
      ],
    );
  }

  /// Valide la saisie et envoie l'événement [TemperatureSetRequested].
  ///
  /// Accepte aussi bien le point que la virgule comme séparateur décimal.
  /// Affiche un SnackBar si la valeur n'est pas un nombre valide.
  void _submit(BuildContext context) {
    final value = double.tryParse(_controller.text.replaceAll(',', '.'));
    if (value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Valeur invalide — entrez un nombre'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    context.read<TemperatureBloc>().add(
          TemperatureSetRequested(deviceIp: widget.deviceIp, value: value),
        );
    _controller.clear();
  }

  /// Formate un timestamp en durée relative courte.
  String _formatTimestamp(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 5) return "à l'instant";
    if (diff.inSeconds < 60) return 'il y a ${diff.inSeconds}s';
    return 'il y a ${diff.inMinutes}min';
  }
}
