import asyncio
import time
import pytest
import main


# ==============================
# Tests simulation d'instabilité
# ==============================
class TestChaos:

    async def test_sans_chaos_resout_rapidement(self):
        """Sans paramètre, la coroutine doit se terminer en < 100ms."""
        t = time.time()
        await main.peut_etre_chaos()
        elapsed_ms = (time.time() - t) * 1000
        assert elapsed_ms < 100

    async def test_latence_appliquee(self):
        """Avec LATENCE_MS=300, la réponse doit prendre >= 300ms."""
        main.LATENCE_MS = 300
        t = time.time()
        await main.peut_etre_chaos()
        elapsed_ms = (time.time() - t) * 1000
        assert elapsed_ms >= 280  # marge de 20ms pour les imprécisions

    async def test_latence_proportionnelle(self):
        """Une latence de 500ms doit être plus longue qu'une de 100ms."""
        main.LATENCE_MS = 100
        t = time.time()
        await main.peut_etre_chaos()
        elapsed_100 = (time.time() - t) * 1000

        main.LATENCE_MS = 500
        t = time.time()
        await main.peut_etre_chaos()
        elapsed_500 = (time.time() - t) * 1000

        assert elapsed_500 > elapsed_100

    async def test_hors_ligne_ne_resout_jamais(self):
        """Mode hors_ligne : la coroutine ne doit jamais se terminer."""
        main.HORS_LIGNE = True
        with pytest.raises(asyncio.TimeoutError):
            await asyncio.wait_for(main.peut_etre_chaos(), timeout=0.5)

    async def test_perte_totale_ne_resout_jamais(self):
        """Avec TAUX_PERTE=1.0, chaque appel est toujours bloqué."""
        main.TAUX_PERTE = 1.0
        with pytest.raises(asyncio.TimeoutError):
            await asyncio.wait_for(main.peut_etre_chaos(), timeout=0.2)

    async def test_perte_nulle_resout_toujours(self):
        """Avec TAUX_PERTE=0.0, aucun appel ne doit être perdu."""
        main.TAUX_PERTE = 0.0
        for _ in range(5):
            # Ne doit pas lever TimeoutError
            await asyncio.wait_for(main.peut_etre_chaos(), timeout=1.0)

    async def test_hors_ligne_prioritaire_sur_latence(self):
        """Hors_ligne bloque même si LATENCE_MS est à 0."""
        main.HORS_LIGNE = True
        main.LATENCE_MS = 0
        with pytest.raises(asyncio.TimeoutError):
            await asyncio.wait_for(main.peut_etre_chaos(), timeout=0.5)
