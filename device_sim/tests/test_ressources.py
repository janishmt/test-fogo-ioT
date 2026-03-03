import json
import time
import pytest
from aiocoap import Code
import main


class FakeRequete:
    """Fausse requête CoAP pour les tests unitaires."""
    def __init__(self, payload=b""):
        self.payload = payload


# ==============================
# Tests GET /health
# ==============================
class TestRessourceSante:

    async def test_champs_requis(self):
        ressource = main.RessourceSante()
        reponse = await ressource.render_get(FakeRequete())
        donnees = json.loads(reponse.payload.decode())
        assert "device_id" in donnees
        assert "name" in donnees
        assert "uptime_s" in donnees
        assert "ts" in donnees

    async def test_device_id_format(self):
        ressource = main.RessourceSante()
        reponse = await ressource.render_get(FakeRequete())
        donnees = json.loads(reponse.payload.decode())
        assert donnees["device_id"].startswith("device-")
        assert len(donnees["device_id"]) > len("device-")

    async def test_uptime_positif(self):
        ressource = main.RessourceSante()
        reponse = await ressource.render_get(FakeRequete())
        donnees = json.loads(reponse.payload.decode())
        assert donnees["uptime_s"] >= 0

    async def test_ts_recent(self):
        ressource = main.RessourceSante()
        reponse = await ressource.render_get(FakeRequete())
        donnees = json.loads(reponse.payload.decode())
        assert abs(donnees["ts"] - int(time.time())) <= 2

    async def test_nom_correct(self):
        ressource = main.RessourceSante()
        reponse = await ressource.render_get(FakeRequete())
        donnees = json.loads(reponse.payload.decode())
        assert donnees["name"] == "DeviceSim"

    async def test_content_format_json(self):
        ressource = main.RessourceSante()
        reponse = await ressource.render_get(FakeRequete())
        assert reponse.opt.content_format == 50  # application/json

    async def test_payload_json_valide(self):
        ressource = main.RessourceSante()
        reponse = await ressource.render_get(FakeRequete())
        # Ne doit pas lever d'exception
        donnees = json.loads(reponse.payload.decode())
        assert isinstance(donnees, dict)


# ==============================
# Tests GET + PUT /temperature
# ==============================
class TestRessourceTemperature:

    async def test_get_champs_requis(self):
        ressource = main.RessourceTemperature()
        reponse = await ressource.render_get(FakeRequete())
        donnees = json.loads(reponse.payload.decode())
        assert "value" in donnees
        assert "unit" in donnees
        assert "ts" in donnees

    async def test_get_unite_celsius(self):
        ressource = main.RessourceTemperature()
        reponse = await ressource.render_get(FakeRequete())
        donnees = json.loads(reponse.payload.decode())
        assert donnees["unit"] == "C"

    async def test_get_valeur_initiale(self):
        main.temperature = 20.0
        ressource = main.RessourceTemperature()
        reponse = await ressource.render_get(FakeRequete())
        donnees = json.loads(reponse.payload.decode())
        assert donnees["value"] == 20.0

    async def test_get_ts_recent(self):
        ressource = main.RessourceTemperature()
        reponse = await ressource.render_get(FakeRequete())
        donnees = json.loads(reponse.payload.decode())
        assert abs(donnees["ts"] - int(time.time())) <= 2

    async def test_put_met_a_jour_globale(self):
        ressource = main.RessourceTemperature()
        payload = json.dumps({"value": 35.5}).encode()
        await ressource.render_put(FakeRequete(payload))
        assert main.temperature == 35.5

    async def test_put_retourne_nouvelle_valeur(self):
        ressource = main.RessourceTemperature()
        payload = json.dumps({"value": 42.0}).encode()
        reponse = await ressource.render_put(FakeRequete(payload))
        donnees = json.loads(reponse.payload.decode())
        assert donnees["value"] == 42.0

    async def test_put_code_changed(self):
        ressource = main.RessourceTemperature()
        payload = json.dumps({"value": 25.0}).encode()
        reponse = await ressource.render_put(FakeRequete(payload))
        assert reponse.code == Code.CHANGED

    async def test_put_valeur_negative(self):
        ressource = main.RessourceTemperature()
        payload = json.dumps({"value": -10.0}).encode()
        reponse = await ressource.render_put(FakeRequete(payload))
        donnees = json.loads(reponse.payload.decode())
        assert donnees["value"] == -10.0

    async def test_get_apres_put_retourne_nouvelle_valeur(self):
        ressource = main.RessourceTemperature()
        payload = json.dumps({"value": 99.9}).encode()
        await ressource.render_put(FakeRequete(payload))
        reponse = await ressource.render_get(FakeRequete())
        donnees = json.loads(reponse.payload.decode())
        assert donnees["value"] == 99.9

    async def test_put_ts_mis_a_jour(self):
        ressource = main.RessourceTemperature()
        payload = json.dumps({"value": 50.0}).encode()
        reponse = await ressource.render_put(FakeRequete(payload))
        donnees = json.loads(reponse.payload.decode())
        assert abs(donnees["ts"] - int(time.time())) <= 2
