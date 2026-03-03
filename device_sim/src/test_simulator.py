import asyncio
import json
import time
import sys
from aiocoap import Context, Message, GET, PUT

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")

URI_APPAREIL = "coap://127.0.0.1:5683"

# -----------------------------
# Test /sante GET
# -----------------------------
async def tester_sante(protocole):
    print("=== Test /sante GET ===")
    try:
        requete = Message(code=GET, uri=f"{URI_APPAREIL}/health")
        reponse = await asyncio.wait_for(protocole.request(requete).response, timeout=5)
        donnees = json.loads(reponse.payload.decode())
        print(f"Réponse: {donnees}")
        assert "device_id" in donnees and "name" in donnees and "uptime_s" in donnees and "ts" in donnees
        print("✅ /sante OK\n")
    except Exception as e:
        print(f"❌ /sante échoué: {e}\n")

# -----------------------------
# Test /temperature GET/PUT
# -----------------------------
async def tester_temperature(protocole):
    print("=== Test /temperature GET/PUT ===")
    try:
        # GET initial
        requete_get = Message(code=GET, uri=f"{URI_APPAREIL}/temperature")
        reponse_get = await asyncio.wait_for(protocole.request(requete_get).response, timeout=5)
        donnees = json.loads(reponse_get.payload.decode())
        valeur_originale = donnees.get("value", 0)
        print(f"Réponse GET: {donnees}")

        # PUT pour modifier
        nouvelle_valeur = valeur_originale + 1
        requete_put = Message(
            code=PUT,
            uri=f"{URI_APPAREIL}/temperature",
            payload=json.dumps({"value": nouvelle_valeur}).encode()
        )
        reponse_put = await asyncio.wait_for(protocole.request(requete_put).response, timeout=5)
        donnees_put = json.loads(reponse_put.payload.decode())
        print(f"Réponse PUT: {donnees_put}")

        assert donnees_put["value"] == nouvelle_valeur
        print("✅ /temperature GET/PUT OK\n")
    except Exception as e:
        print(f"❌ /temperature échouée: {e}\n")

# -----------------------------
# Test chaos / latence / perte / offline
# -----------------------------
async def tester_chaos(protocole, nb_requetes=20, delai_attente=5):
    print("=== Test chaos (latence/perte/offline) ===")
    recues = 0
    perdues = 0
    for i in range(nb_requetes):
        try:
            requete = Message(code=GET, uri=f"{URI_APPAREIL}/health")
            reponse = await asyncio.wait_for(protocole.request(requete).response, timeout=delai_attente)
            recues += 1
            print(f"[{i+1}/{nb_requetes}] Réponse reçue")
        except asyncio.TimeoutError:
            perdues += 1
            print(f"[{i+1}/{nb_requetes}] Requête expirée (perdue)")
        except Exception:
            perdues += 1
            print(f"[{i+1}/{nb_requetes}] Requête échouée (perdue)")

    print(f"\nTest chaos terminé : {recues} réponses reçues, {perdues} perdues\n")

# -----------------------------
# Programme principal
# -----------------------------
async def main():
    protocole = await Context.create_client_context()
    await asyncio.sleep(0.5)  # attendre que le serveur démarre
    await tester_sante(protocole)
    await tester_temperature(protocole)
    await tester_chaos(protocole)
    await asyncio.sleep(0.1)

if __name__ == "__main__":
    try:
        if sys.platform == "win32":
            asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
        asyncio.run(main())
    except KeyboardInterrupt:
        sys.exit(0)