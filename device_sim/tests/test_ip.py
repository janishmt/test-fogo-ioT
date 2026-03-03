import socket
import pytest
import main


# ==============================
# Tests _get_local_ip
# ==============================
class TestGetLocalIp:

    def test_retourne_une_chaine(self):
        ip = main._get_local_ip()
        assert isinstance(ip, str)

    def test_format_ipv4_valide(self):
        ip = main._get_local_ip()
        parts = ip.split(".")
        assert len(parts) == 4
        assert all(p.isdigit() and 0 <= int(p) <= 255 for p in parts)

    def test_ip_non_vide(self):
        ip = main._get_local_ip()
        assert len(ip) > 0

    def test_fallback_sur_erreur_reseau(self, monkeypatch):
        """Si le réseau est indisponible, doit retourner 127.0.0.1."""
        def faux_connect(self, *args):
            raise OSError("Réseau simulé indisponible")
        monkeypatch.setattr(socket.socket, "connect", faux_connect)
        ip = main._get_local_ip()
        assert ip == "127.0.0.1"
