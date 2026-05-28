# Referência: domains/security/SKILL.md — Seção A10 (SSRF)
# Quando usar: validação de URLs fornecidas pelo usuário antes de realizar fetch
# Nota: valida o IP após resolução DNS para prevenir DNS rebinding

import socket
import ipaddress
from urllib.parse import urlparse

PRIVATE_RANGES = [
    ipaddress.ip_network('10.0.0.0/8'),
    ipaddress.ip_network('172.16.0.0/12'),
    ipaddress.ip_network('192.168.0.0/16'),
    ipaddress.ip_network('127.0.0.0/8'),
    ipaddress.ip_network('169.254.0.0/16'),  # link-local / cloud metadata
    ipaddress.ip_network('::1/128'),
    ipaddress.ip_network('fc00::/7'),
]

ALLOWED_SCHEMES = {'https'}

def is_safe_url(url: str) -> bool:
    parsed = urlparse(url)
    if parsed.scheme not in ALLOWED_SCHEMES:
        return False

    hostname = parsed.hostname
    if not hostname:
        return False

    # Resolve DNS and validate the resulting IP — prevents DNS rebinding
    try:
        results = socket.getaddrinfo(hostname, None)
        for result in results:
            ip = ipaddress.ip_address(result[4][0])
            if any(ip in net for net in PRIVATE_RANGES):
                return False
    except socket.gaierror:
        return False

    return True
