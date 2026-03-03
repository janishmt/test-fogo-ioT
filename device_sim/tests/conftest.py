"""
Configuration partagée pour pytest.

Ce fichier est chargé automatiquement par pytest avant l'exécution des tests.
Il sert à deux choses :
  1. Neutraliser argparse de main.py avant son import (sinon pytest crashe
     car il transmet ses propres arguments à argparse).
  2. Fournir une fixture autouse qui remet les variables globales de main.py
     dans leur état initial entre chaque test, pour garantir l'isolation.
"""

import sys
import os

# Neutralise argparse AVANT tout import de main.py.
# Sans ça, argparse lirait les arguments de pytest (ex: --tb=short) et planterait.
sys.argv = ["main"]

# Ajoute le dossier src/ au chemin Python pour pouvoir faire `import main`
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))

import pytest
import main as m


@pytest.fixture(autouse=True)
def reset_etat():
    """Fixture d'isolation : remet les variables globales dans leur état initial.

    Exécutée automatiquement avant ET après chaque test (grace à yield).
    Cela garantit qu'un test qui modifie la température ou active le mode chaos
    ne pollue pas les tests suivants.
    """
    # État initial avant le test
    m.temperature = 20.0
    m.LATENCE_MS = 0
    m.TAUX_PERTE = 0.0
    m.HORS_LIGNE = False

    yield  # le test s'exécute ici

    # Nettoyage après le test (au cas où le test aurait modifié l'état)
    m.temperature = 20.0
    m.LATENCE_MS = 0
    m.TAUX_PERTE = 0.0
    m.HORS_LIGNE = False
