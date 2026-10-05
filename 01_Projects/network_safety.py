"""Network destination checks shared by local-service clients."""

from __future__ import annotations

import ipaddress
from urllib.parse import urlsplit


def is_loopback_http_url(url: str) -> bool:
    """Accept only HTTP(S) URLs whose host is localhost or a loopback IP."""
    if not isinstance(url, str) or not url.strip():
        return False
    try:
        parsed = urlsplit(url.strip())
        hostname = parsed.hostname
        parsed.port  # Validate a supplied port instead of deferring to the HTTP client.
    except ValueError:
        return False
    if (
        parsed.scheme.lower() not in {"http", "https"}
        or not hostname
        or parsed.username is not None
        or parsed.password is not None
        or parsed.query
        or parsed.fragment
    ):
        return False
    normalized_host = hostname.lower()
    if normalized_host.endswith("."):
        normalized_host = normalized_host[:-1]
    if normalized_host == "localhost":
        return True
    try:
        address = ipaddress.ip_address(normalized_host)
    except ValueError:
        return False
    if isinstance(address, ipaddress.IPv6Address) and address.ipv4_mapped:
        return address.ipv4_mapped.is_loopback
    return address.is_loopback
