/// Factory de client CoAP.
///
/// Le package `coap` nécessite un [CoapClient] par paire (IP, port).
/// Cette fonction factorise la création pour éviter la duplication
/// dans [CoapRepository].

import 'package:coap/coap.dart';

/// Construit un [CoapClient] pointant vers l'IP et le port donnés.
///
/// [CoapConfigDefault] utilise les paramètres par défaut du protocole CoAP :
///   - ACK_TIMEOUT = 2s, MAX_RETRANSMIT = 4, etc.
/// Aucun fichier YAML de configuration n'est nécessaire.
///
/// Toujours appeler [CoapClient.close()] après usage pour libérer le socket UDP.
CoapClient buildCoapClient(String ip, {int port = 5683}) {
  return CoapClient(
    Uri(scheme: 'coap', host: ip, port: port),
    config: CoapConfigDefault(),
  );
}
