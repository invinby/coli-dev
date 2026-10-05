#!/usr/bin/env python3
"""
Диагностика соединения с Obsidian Local REST API.

Запуск:
    .venv/bin/python 01_Projects/test_obsidian_connect.py
"""

import asyncio
import os
import traceback
from pathlib import Path

from dotenv import load_dotenv

_env_path = Path(__file__).resolve().parent.parent / ".env"
load_dotenv(_env_path)

OBSIDIAN_API_KEY = os.getenv("OBSIDIAN_API_KEY", "")
OPENROUTER_KEY = os.getenv("OPENROUTER_API_KEY", "")

URLS = [
    "https://127.0.0.1:27124",
    "https://127.0.0.1:27123",
    "http://127.0.0.1:27124",
    "http://127.0.0.1:27123",
]


async def check_url(url: str, api_key: str) -> None:
    """Проверить конкретный URL."""
    import httpx

    print(f"\n  → {url}/vault/")
    try:
        async with httpx.AsyncClient(verify=False, timeout=5) as client:
            resp = await client.get(
                f"{url}/vault/",
                headers={"Authorization": f"Bearer {api_key}"},
            )
            print(f"    Status: {resp.status_code}")
            if resp.status_code == 200:
                data = resp.json()
                print(f"    OK! Files: {len(data) if isinstance(data, list) else '?'}")
            else:
                print(f"    Body: {resp.text[:200]}")
    except httpx.ConnectError:
        print("    ❌ Connection refused")
    except httpx.TimeoutException:
        print("    ❌ Timeout (5s)")
    except Exception:
        print("    ❌ Error:")
        traceback.print_exc()


async def main() -> None:
    print("=" * 60)
    print("  DIAGNOSTIC: Obsidian Local REST API")
    print("=" * 60)

    # 1. Check .env
    print("\n📋 .env check:")
    print(f"  OBSIDIAN_API_KEY = {'[SET]' if OBSIDIAN_API_KEY else '[EMPTY]'}")
    print(f"  OPENROUTER_API_KEY = {'[SET]' if OPENROUTER_KEY else '[EMPTY]'}")

    if not OBSIDIAN_API_KEY:
        print("\n  ❌ OBSIDIAN_API_KEY is not set!")
        print("  → Edit .env and add: OBSIDIAN_API_KEY=\"your_key_from_obsidian\"")
        print("  → Get key: Obsidian → Settings → Local REST API → copy key")

    # 2. Test URLs
    print(f"\n📋 Testing {len(URLS)} candidate URLs:")
    for url in URLS:
        await check_url(url, OBSIDIAN_API_KEY)

    print("\n" + "=" * 60)
    print("  TROUBLESHOOTING")
    print("=" * 60)
    print("""
  1. Open Obsidian → Settings → Community plugins → make sure plugins are ON
  2. Install/enable 'Local REST API' plugin
  3. Settings → Local REST API → verify:
     - Status: green (enabled)
     - Port: 27123 (HTTP) or 27124 (HTTPS)
     - Protocol: Copy the URL format from the plugin
  4. Copy the API key from the plugin settings
  5. Add to .env: OBSIDIAN_API_KEY=\"paste_key_here\"
  
  If still failing:
  - Restart Obsidian entirely
  - Check if macOS Firewall is blocking: System Settings → Network → Firewall
""")


if __name__ == "__main__":
    asyncio.run(main())
