# Fogo — Mini-écosystème IoT CoAP

Fogo est composé de deux parties : un simulateur d'appareil IoT en Python (CoAP/UDP) et une application Flutter pour surveiller les appareils, lire et modifier leur température.

```
fogo-projet/
├── device_sim/          # Simulateur Python
│   ├── src/
│   │   └── main.py      # Point d'entrée
│   ├── tests/           # 28 tests unitaires
│   ├── requirements.txt
│   └── pytest.ini
└── application/         # Application Flutter
    └── lib/
        ├── core/        # Constantes, logger, config CoAP
        ├── data/        # Modèles + repositories
        ├── features/    # Blocs et écrans (discovery, monitor, temperature)
        └── widgets/     # Composants réutilisables
```

---

## Lancer le simulateur

```bash
cd device_sim
python -m venv venv

# Windows
venv\Scripts\activate
# macOS / Linux
source venv/bin/activate

pip install -r requirements.txt
python src/main.py
```

Le simulateur tourne sur `coap://127.0.0.1:5683`.

Options disponibles :

```bash
python src/main.py --latence 500        # ajoute 500 ms de latence
python src/main.py --perte 0.3          # 30 % de perte de paquets
python src/main.py --hors_ligne         # aucune réponse
python src/main.py --latence 1500 --perte 0.1

# Plusieurs devices sur la même machine (dans des terminaux séparés)
python src/main.py --host 127.0.0.1
python src/main.py --host 127.0.0.2
python src/main.py --host 127.0.0.3
```

Le **multi-device simultané est testé et fonctionnel** : chaque instance obtient un `device_id` unique et écoute sur une adresse loopback distincte. L'application Flutter les découvre tous lors du scan et les surveille en parallèle, chacun avec son propre timer de ping, son statut et son health score indépendants.

Exemple concret avec trois devices — un stable, un lent, un hors-ligne :

```bash
# Terminal 1 — device stable
python src/main.py --host 127.0.0.1

# Terminal 2 — device avec latence élevée (bascule en Degraded)
python src/main.py --host 127.0.0.2 --latence 2500

# Terminal 3 — device hors-ligne (bascule en Offline après 3 pings manqués)
python src/main.py --host 127.0.0.3 --hors_ligne
```

---

## Lancer l'application Flutter

Flutter 3.10+ et Dart 3.0+ requis.

```bash
cd application
flutter pub get
flutter run -d windows   # Windows
flutter run -d macos     # macOS
flutter run -d linux     # Linux
flutter run -d android   # Android
flutter run -d ios       # iOS
```

**Sur smartphone**, le téléphone et l'ordinateur qui fait tourner le simulateur doivent être sur le **même réseau Wi-Fi**. L'app scanne automatiquement le sous-réseau et trouve le simulateur.

Sur Android, l'app demandera la permission de localisation au premier lancement — c'est nécessaire pour que le système autorise l'accès aux infos réseau Wi-Fi.

---

## Endpoints CoAP

**GET /health**
```json
{
  "device_id": "device-4827",
  "name": "DeviceSim",
  "uptime_s": 142,
  "ts": 1700000000
}
```

**GET /temperature**
```json
{ "value": 20.0, "unit": "C", "ts": 1700000000 }
```

**PUT /temperature**
```json
// Payload
{ "value": 21.5 }

// Réponse
{ "value": 21.5, "unit": "C", "ts": 1700000000 }
```

---

## Simuler de l'instabilité

- `--latence <ms>` : délai artificiel avant la réponse
- `--perte <0-1>` : probabilité d'ignorer une requête
- `--hors_ligne` : le simulateur ne répond plus du tout

```bash
python src/main.py --latence 2500 --perte 0.5
```

Avec ces paramètres, l'app bascule les devices en `Degraded` ou `Offline` selon les seuils définis.

---

## Architecture Flutter

On utilise le pattern BLoC pour séparer données, logique et UI.

- **DiscoveryBloc** : scan du réseau local, détecte les appareils qui répondent sur `/health`
- **DeviceMonitorBloc** : ping périodique (toutes les 10 s) de chaque device, met à jour le statut
- **TemperatureBloc** : lecture/écriture de la température, refresh automatique toutes les 5 s

Les timers sont créés et annulés dans les blocs (`close()`). Le `DiscoveryBloc` passe les devices trouvés au `DeviceMonitorBloc` via un `BlocListener` — pas de couplage direct entre les deux.

---

## Découverte des appareils

On utilise un **scan réseau actif** : l'application sonde chaque IP du sous-réseau sur le port 5683 avec une requête `GET /health`.

- `127.0.0.1` est toujours inclus
- L'IP Wi-Fi est récupérée via `network_info_plus`, avec un fallback sur `NetworkInterface.list()` pour Ethernet
- Les probes partent par batch de 20 en parallèle
- Les devices sont ajoutés à la liste dès qu'ils répondent, sans attendre la fin du scan

On a préféré cette approche au multicast CoAP parce qu'elle fonctionne même si le simulateur n'implémente pas d'annonce, et qu'elle est plus simple à déboguer.

---

## Statuts de connexion

| Statut | Condition |
|--------|-----------|
| `Unknown` | jamais pingé |
| `Online` | réponse reçue, latence < 2000 ms, 0 échec consécutif |
| `Degraded` | 1–2 échecs consécutifs, ou latence ≥ 2000 ms |
| `Offline` | ≥ 3 échecs consécutifs |

**Health score (0–100) :**
```
score = clamp(100 − (failures × 30) − latencyPenalty, 0, 100)
latencyPenalty = clamp((lastResponseMs − 500) / 50, 0, 40)
```

---

## Tests

```bash
# Simulateur
cd device_sim
python -m pytest tests/ -v

# Flutter
cd application
flutter test test/status_rules_test.dart
```

---

## Bonus implémentés

| Bonus | Détail |
|-------|--------|
| **Multi-device simultané** | Plusieurs instances du simulateur sur des IPs loopback distinctes, surveillées en parallèle par l'app |
| **Health score numérique (0–100)** | Affiché avec barre de progression colorée pour chaque device (vert ≥ 70, orange ≥ 40, rouge < 40) |
| **Logs structurés** | Package `logging` avec horodatage, niveau et nom du composant source (`DiscoveryBloc`, `CoapRepository`, etc.) |
| **UI soignée** | Material 3, badges de statut colorés, barre de santé, rafraîchissement temps réel |
| **Tests unitaires** | 28 tests pytest (simulateur) + 23 tests Flutter (logique de statut et health score) |

---

## Compatibilité

Windows, macOS, Linux — simulateur et application Flutter testés sur les trois plateformes.
