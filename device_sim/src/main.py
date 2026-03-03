"""
Simulateur de dispositif IoT — serveur CoAP (Constrained Application Protocol).

Ce script simule un appareil physique connecté au réseau local.
Il expose deux ressources accessibles via le protocole CoAP (UDP, port 5683) :

  - GET  /health      → informations statiques de l'appareil (ID, nom, uptime)
  - GET  /temperature → température actuelle simulée (modifiable)
  - PUT  /temperature → modifie la valeur de température stockée

Paramètres de ligne de commande (pour simuler des pannes réseau) :
  --latence     Délai artificiel en millisecondes avant chaque réponse
  --perte       Taux de perte de paquets, entre 0.0 (aucune) et 1.0 (totale)
  --hors_ligne  Si présent, l'appareil ne répond plus du tout (bloque indéfiniment)
  --host        Adresse IP sur laquelle écouter (défaut : 127.0.0.1)

Exemples d'utilisation :
  python main.py                              → appareil stable sur 127.0.0.1
  python main.py --host 127.0.0.2            → 2e appareil sur une autre IP loopback
  python main.py --latence 800 --perte 0.2   → réseau instable (800ms + 20% de perte)
  python main.py --hors_ligne                → appareil complètement inaccessible
"""

import asyncio
import sys
import random
import time
import json
import argparse
import socket
from aiocoap import resource, Context, Message, Code

# ==============================
# Configuration via ligne de commande
# ==============================
parser = argparse.ArgumentParser()
parser.add_argument("--latence", type=int, default=0, help="Latence en ms")
parser.add_argument("--perte", type=float, default=0.0, help="Taux de perte de paquets (0-1)")
parser.add_argument("--hors_ligne", action="store_true", help="Démarrer en mode hors-ligne")
parser.add_argument("--host", type=str, default="127.0.0.1", help="Adresse d'écoute (défaut: 127.0.0.1)")
args = parser.parse_args()

# Variables globales de configuration (modifiables par les tests via conftest.py)
LATENCE_MS = args.latence
TAUX_PERTE = args.perte
HORS_LIGNE = args.hors_ligne
HOST = args.host

# ==============================
# État du dispositif
# ==============================
def _get_local_ip():
    """Détecte l'IP locale de la machine pour l'afficher au démarrage.
    Ouvre un socket UDP factice vers 8.8.8.8 (pas de connexion réelle)
    afin que l'OS choisisse l'interface réseau sortante et révèle l'IP."""
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
            s.connect(("8.8.8.8", 80))
            return s.getsockname()[0]
    except Exception:
        return "127.0.0.1"

# Identifiant unique généré aléatoirement à chaque démarrage
ID_APPAREIL = f"device-{random.randint(1000,9999)}"
NOM_APPAREIL = "DeviceSim"

temperature = 20.0          # Valeur de température en degrés Celsius (partagée entre les ressources)
temps_debut = time.time()   # Timestamp du démarrage du serveur (pour calculer l'uptime)

# ==============================
# Simulation d'instabilité (chaos)
# ==============================
async def peut_etre_chaos():
    """Applique les effets de chaos configurés avant de traiter une requête.

    - Mode hors-ligne : attend 3600s (le client CoAP va timeout bien avant).
    - Perte de paquet : crée une Future qui ne se résout jamais → drop silencieux.
    - Latence         : attend N millisecondes avant de répondre.

    Cette fonction doit être appelée en tout premier dans chaque render_*.
    """
    if HORS_LIGNE:
        await asyncio.sleep(3600)  # simule l'absence de réponse

    if random.random() < TAUX_PERTE:
        await asyncio.get_running_loop().create_future()  # drop silencieux, jamais résolu

    if LATENCE_MS > 0:
        await asyncio.sleep(LATENCE_MS / 1000)  # simule la latence

# ==============================
# Ressources CoAP
# ==============================
class RessourceSante(resource.Resource):
    """Ressource CoAP exposée sur le chemin /health.

    Retourne les informations de base de l'appareil au format JSON :
      { "device_id": "device-XXXX", "name": "DeviceSim",
        "uptime_s": 42, "ts": 1712345678 }
    """

    async def render_get(self, requete):
        """Gère les requêtes GET /health."""
        await peut_etre_chaos()  # injecte latence / perte / hors-ligne avant de répondre

        temps_fonctionnement = int(time.time() - temps_debut)
        donnees = {
            "device_id": ID_APPAREIL,
            "name": NOM_APPAREIL,
            "uptime_s": temps_fonctionnement,
            "ts": int(time.time())
        }

        return Message(
            payload=json.dumps(donnees).encode(),
            content_format=50  # content-format 50 = application/json (standard CoAP)
        )


class RessourceTemperature(resource.Resource):
    """Ressource CoAP exposée sur le chemin /temperature.

    Supporte GET (lecture) et PUT (écriture) de la température simulée.
    La valeur est stockée dans la variable globale `temperature`.
    """

    async def render_get(self, requete):
        """Gère les requêtes GET /temperature.

        Retourne : { "value": 20.0, "unit": "C", "ts": 1712345678 }
        """
        await peut_etre_chaos()

        donnees = {
            "value": temperature,
            "unit": "C",
            "ts": int(time.time())
        }

        return Message(
            payload=json.dumps(donnees).encode(),
            content_format=50
        )

    async def render_put(self, requete):
        """Gère les requêtes PUT /temperature.

        Corps attendu : { "value": 25.5 }
        Retourne la nouvelle valeur confirmée avec le code CoAP 2.04 Changed.
        """
        global temperature
        await peut_etre_chaos()

        donnees_requete = json.loads(requete.payload.decode())
        temperature = float(donnees_requete["value"])  # mise à jour de la valeur globale

        donnees = {
            "value": temperature,
            "unit": "C",
            "ts": int(time.time())
        }

        return Message(
            code=Code.CHANGED,       # 2.04 Changed — équivalent HTTP 204 pour CoAP
            payload=json.dumps(donnees).encode(),
            content_format=50
        )

# ==============================
# Mise en place du serveur
# ==============================
async def principal():
    """Initialise le serveur CoAP, enregistre les ressources et démarre la boucle."""
    site = resource.Site()
    site.add_resource(['health'], RessourceSante())
    site.add_resource(['temperature'], RessourceTemperature())

    ip_locale = _get_local_ip()
    await Context.create_server_context(site, bind=(HOST, 5683))
    print(f"Appareil démarré : {ID_APPAREIL}")
    print(f"Accessible sur   : coap://{HOST}:5683 (LAN: {ip_locale})")
    await asyncio.get_running_loop().create_future()  # boucle infinie pour garder le serveur actif

if __name__ == "__main__":
    # Sur Windows, asyncio nécessite SelectorEventLoop pour les sockets UDP (aiocoap)
    if sys.platform == "win32":
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    asyncio.run(principal())
