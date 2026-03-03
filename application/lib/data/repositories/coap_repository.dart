/// Repository CoAP — couche d'accès réseau bas niveau.
///
/// Encapsule tous les appels réseau CoAP (GET /health, GET/PUT /temperature).
/// Les BLoCs ne connaissent pas le protocole CoAP : ils passent par ce repository.
///
/// Chaque méthode crée un [CoapClient] dédié et le ferme dans le bloc finally
/// pour libérer le socket UDP immédiatement après usage.

import 'dart:async';
import 'dart:convert';

import 'package:coap/coap.dart';
import 'package:logging/logging.dart';

import '../../core/coap_config.dart';
import '../../core/constants.dart';
import '../models/connection_status.dart';
import '../models/device.dart';
import '../models/temperature_reading.dart';

class CoapRepository {
  final _log = Logger('CoapRepository');

  /// Sonde un appareil via GET /health et retourne un [Device] si valide.
  ///
  /// Utilisée à deux moments :
  ///   1. Durant le scan de découverte (timeout court = [discoveryTimeout])
  ///   2. Durant le monitoring périodique (via [DeviceMonitorBloc])
  ///
  /// Retourne [null] si l'appareil est injoignable, timeout, ou renvoie une erreur.
  Future<Device?> probeHealth(String ip) async {
    final client = buildCoapClient(ip);
    final stopwatch = Stopwatch()..start(); // mesure la latence aller-retour
    try {
      final uri = Uri(scheme: 'coap', host: ip, port: AppConstants.coapPort, path: 'health');
      final response = await client
          .get(uri)
          .timeout(AppConstants.discoveryTimeout);
      stopwatch.stop();

      if (!response.isSuccess) {
        _log.fine('Probe non-success: $ip → ${response.code}');
        return null;
      }

      final json = jsonDecode(response.payloadString) as Map<String, dynamic>;
      // Construit un Device "Online" avec un health score calculé depuis la latence mesurée
      return Device(
        ip: ip,
        port: AppConstants.coapPort,
        deviceId: json['device_id'] as String,
        name: json['name'] as String,
        status: ConnectionStatus.online,
        healthScore: StatusRules.computeScore(
          successiveFailures: 0,
          lastResponseMs: stopwatch.elapsedMilliseconds,
        ),
        lastSeen: DateTime.now(),
        uptimeSeconds: json['uptime_s'] as int,
        successiveFailures: 0,
        lastResponseMs: stopwatch.elapsedMilliseconds,
      );
    } on TimeoutException {
      _log.fine('Probe timeout: $ip');
      return null;
    } catch (e) {
      _log.finer('Probe failed: $ip — $e');
      return null;
    } finally {
      client.close(); // libère le socket UDP dans tous les cas
    }
  }

  /// Lit la température courante d'un appareil via GET /temperature.
  ///
  /// Lance une exception si la réponse n'est pas un succès CoAP,
  /// ce qui permet au [TemperatureBloc] de gérer l'erreur proprement.
  Future<TemperatureReading> getTemperature(String ip) async {
    final client = buildCoapClient(ip);
    try {
      final uri = Uri(
        scheme: 'coap',
        host: ip,
        port: AppConstants.coapPort,
        path: 'temperature',
      );
      final response = await client
          .get(uri)
          .timeout(AppConstants.healthPingTimeout);
      if (!response.isSuccess) {
        throw Exception('GET /temperature failed: ${response.code}');
      }
      final json = jsonDecode(response.payloadString) as Map<String, dynamic>;
      return TemperatureReading.fromJson(json);
    } finally {
      client.close();
    }
  }

  /// Modifie la température d'un appareil via PUT /temperature.
  ///
  /// Envoie { "value": [value] } et retourne la valeur confirmée par l'appareil.
  /// Lance une exception si l'appareil répond avec un code d'erreur CoAP.
  Future<TemperatureReading> setTemperature(String ip, double value) async {
    final client = buildCoapClient(ip);
    try {
      final uri = Uri(
        scheme: 'coap',
        host: ip,
        port: AppConstants.coapPort,
        path: 'temperature',
      );
      final response = await client
          .put(
            uri,
            payload: jsonEncode({'value': value}),
            format: CoapMediaType.applicationJson,
          )
          .timeout(AppConstants.healthPingTimeout);
      if (!response.isSuccess) {
        throw Exception('PUT /temperature failed: ${response.code}');
      }
      final json = jsonDecode(response.payloadString) as Map<String, dynamic>;
      return TemperatureReading.fromJson(json);
    } finally {
      client.close();
    }
  }
}
