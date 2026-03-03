Projet- Simulateur de device ioT

Un simulateur d’appareil IoT communiquant en CoAP over UDP

Une application Flutter permettant :

-la découverte dynamique des appareils

-l’affichage de leur état réseau

-la lecture et modification de la température

-Le projet met l’accent sur :

-compréhension réseau (UDP, timeouts, instabilité)

-architecture logicielle propre

-gestion de systèmes instables

-robustesse et qualité du code

🏗 Architecture Globale
Flutter App  <--CoAP/UDP-->  Device Simulator(s)

Chaque device :

écoute sur UDP port 5683

expose des ressources CoAP REST

peut simuler instabilité réseau

L’application Flutter :

découvre dynamiquement les devices

maintient leur statut réseau

interagit via GET / PUT

Partie 1 — Device Simulator (Python + CoAP)
🔧 Technologies

Python 3.10+

Bibliothèque aiocoap

Protocole CoAP (RFC 7252)

UDP port 5683

▶️ Lancement
Installation
python -m venv venv
venv\Scripts\activate
pip install aiocoap
Démarrage simple
python src/main.py
Avec instabilité réseau
python src/main.py --latence 200 --perte 0.2
Mode hors-ligne
python src/main.py --hors_ligne
📡 Ressources CoAP
1️⃣ Health

GET

coap://<ip>:5683/health

Réponse :

{
  "device_id": "device-1234",
  "name": "DeviceSim",
  "uptime_s": 42,
  "ts": 1700000000
}
Logique

device_id généré dynamiquement à chaque démarrage

uptime_s calculé dynamiquement

ts = timestamp Unix

2️⃣ Temperature
GET /temperature
{
  "value": 20.0,
  "unit": "C",
  "ts": 1700000000
}
PUT /temperature

Payload :

{
  "value": 21.0
}

Réponse : état mis à jour avec nouveau timestamp.

🌪 Simulation d’Instabilité

Implémentée via arguments CLI :

--latence:	Ajoute un délai artificiel en millisecondes
--perte:	Probabilité de perte de paquet (0–1)
--hors_ligne:	Simule un device totalement non-réactif

Avant chaque réponse :

Application éventuelle d’un délai (asyncio.sleep)

Simulation de perte via probabilité aléatoire

Mode offline = aucune réponse (timeout côté client)

Cela permet de tester :

gestion des timeouts

dégradation réseau

robustesse applicative