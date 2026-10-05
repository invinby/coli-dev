from pathlib import Path

from app_paths import app_data_dir, app_log_dir, session_file_path
from knowledge_index import default_database_path


def test_app_data_paths_follow_platform_conventions(tmp_path: Path) -> None:
    assert app_data_dir(platform="darwin", environ={}, home=tmp_path) == (
        tmp_path / "Library" / "Application Support" / "coli-dev"
    )
    assert app_data_dir(
        platform="win32",
        environ={"LOCALAPPDATA": str(tmp_path / "AppData" / "Local")},
        home=tmp_path,
    ) == tmp_path / "AppData" / "Local" / "ColiDev"
    assert app_data_dir(
        platform="linux",
        environ={"XDG_DATA_HOME": str(tmp_path / "xdg-data")},
        home=tmp_path,
    ) == tmp_path / "xdg-data" / "coli-dev"


def test_data_and_log_overrides_are_honored(tmp_path: Path) -> None:
    data = tmp_path / "private-data"
    logs = tmp_path / "private-logs"

    assert app_data_dir(platform="win32", environ={"COLIDEV_DATA_DIR": str(data)}) == data
    assert app_log_dir(platform="darwin", environ={"COLIDEV_LOG_DIR": str(logs)}) == logs


def test_knowledge_index_uses_the_shared_data_override(monkeypatch, tmp_path: Path) -> None:
    data = tmp_path / "private-data"
    monkeypatch.setenv("COLIDEV_DATA_DIR", str(data))

    assert default_database_path() == data / "knowledge.sqlite3"


def test_log_paths_follow_platform_conventions(tmp_path: Path) -> None:
    assert app_log_dir(platform="darwin", environ={}, home=tmp_path) == (
        tmp_path / "Library" / "Logs" / "coli-dev"
    )
    assert app_log_dir(
        platform="win32",
        environ={"LOCALAPPDATA": str(tmp_path / "AppData" / "Local")},
        home=tmp_path,
    ) == tmp_path / "AppData" / "Local" / "ColiDev" / "Logs"
    assert app_log_dir(
        platform="linux",
        environ={"XDG_STATE_HOME": str(tmp_path / "xdg-state")},
        home=tmp_path,
    ) == tmp_path / "xdg-state" / "coli-dev" / "logs"


def test_session_file_keeps_legacy_data_until_an_override_is_set(tmp_path: Path) -> None:
    old_file = tmp_path / "Library" / "Application Support" / "coli-dev" / "sessions.json"
    old_file.parent.mkdir(parents=True)
    old_file.write_text('{"sessions": [], "mode": "online"}', encoding="utf-8")

    assert session_file_path(platform="win32", environ={}, home=tmp_path) == old_file
    assert session_file_path(
        platform="win32",
        environ={"COLIDEV_DATA_DIR": str(tmp_path / "new-data")},
        home=tmp_path,
    ) == tmp_path / "new-data" / "sessions.json"
