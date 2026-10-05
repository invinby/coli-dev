"""Per-user storage paths for ColiDev's local backend."""

from __future__ import annotations

import os
import sys
from collections.abc import Mapping
from pathlib import Path


def _environment(environ: Mapping[str, str] | None) -> Mapping[str, str]:
    return os.environ if environ is None else environ


def _home(home: Path | None) -> Path:
    return Path.home() if home is None else Path(home)


def _absolute_environment_path(value: str | None, fallback: Path) -> Path:
    if not value or not value.strip():
        return fallback
    candidate = Path(value).expanduser()
    return candidate if candidate.is_absolute() else fallback


def app_data_dir(
    *,
    platform: str | None = None,
    environ: Mapping[str, str] | None = None,
    home: Path | None = None,
) -> Path:
    """Return ColiDev's per-user data directory, honoring its explicit override."""
    current_platform = sys.platform if platform is None else platform
    env = _environment(environ)
    home_dir = _home(home)
    configured = env.get("COLIDEV_DATA_DIR", "").strip()
    if configured:
        return Path(configured).expanduser()

    if current_platform == "darwin":
        return home_dir / "Library" / "Application Support" / "coli-dev"
    if current_platform == "win32":
        fallback = home_dir / "AppData" / "Local"
        return _absolute_environment_path(env.get("LOCALAPPDATA"), fallback) / "ColiDev"

    fallback = home_dir / ".local" / "share"
    return _absolute_environment_path(env.get("XDG_DATA_HOME"), fallback) / "coli-dev"


def app_log_dir(
    *,
    platform: str | None = None,
    environ: Mapping[str, str] | None = None,
    home: Path | None = None,
) -> Path:
    """Return ColiDev's per-user log directory, with an optional explicit override."""
    current_platform = sys.platform if platform is None else platform
    env = _environment(environ)
    home_dir = _home(home)
    configured = env.get("COLIDEV_LOG_DIR", "").strip()
    if configured:
        return Path(configured).expanduser()

    if current_platform == "darwin":
        return home_dir / "Library" / "Logs" / "coli-dev"
    if current_platform == "win32":
        fallback = home_dir / "AppData" / "Local"
        return _absolute_environment_path(env.get("LOCALAPPDATA"), fallback) / "ColiDev" / "Logs"

    fallback = home_dir / ".local" / "state"
    return _absolute_environment_path(env.get("XDG_STATE_HOME"), fallback) / "coli-dev" / "logs"


def session_file_path(
    *,
    platform: str | None = None,
    environ: Mapping[str, str] | None = None,
    home: Path | None = None,
) -> Path:
    """Return the session file path and preserve the old file if it already exists."""
    env = _environment(environ)
    home_dir = _home(home)
    current_platform = sys.platform if platform is None else platform
    target = app_data_dir(platform=current_platform, environ=env, home=home_dir) / "sessions.json"
    if env.get("COLIDEV_DATA_DIR", "").strip():
        return target

    legacy = home_dir / "Library" / "Application Support" / "coli-dev" / "sessions.json"
    if legacy != target and legacy.is_file() and not target.exists():
        return legacy
    return target
