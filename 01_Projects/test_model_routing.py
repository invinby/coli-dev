from __future__ import annotations

import asyncio
import json
from unittest.mock import AsyncMock

import pytest
from fastapi import HTTPException
from starlette.requests import Request

import orchestrator


@pytest.fixture
def route_store(tmp_path, monkeypatch):
    store = orchestrator.SubjectModelRouteStore(tmp_path / "subject-model-routing.json")
    monkeypatch.setattr(orchestrator, "subject_model_routes", store)
    return store


def _request(client_host: str, origin: str | None = None) -> Request:
    headers = [(b"origin", origin.encode("ascii"))] if origin else []
    return Request({
        "type": "http",
        "method": "GET",
        "path": "/settings/model-routing",
        "headers": headers,
        "client": (client_host, 50000),
    })


def test_route_store_returns_auto_for_every_supported_subject(route_store):
    snapshot = route_store.snapshot()

    assert set(snapshot) == set(orchestrator.SUBJECT_MODEL_ROUTE_SUBJECTS)
    assert all(route == {"provider": "auto", "model": None} for route in snapshot.values())


def test_route_store_persists_provider_model_without_storing_secrets(route_store, tmp_path):
    expected = {"provider": "openrouter", "model": "meta-llama/llama-3.3-70b-instruct:free"}
    assert route_store.set("biology", expected["provider"], expected["model"]) == expected

    reloaded = orchestrator.SubjectModelRouteStore(tmp_path / "subject-model-routing.json")
    assert reloaded.get("biology") == expected
    assert "API_KEY" not in reloaded.path.read_text(encoding="utf-8")


def test_route_store_validates_model_ids_by_provider(route_store):
    assert route_store.set("zoology", "ollama", "qwen3:8b") == {
        "provider": "ollama", "model": "qwen3:8b",
    }
    with pytest.raises(ValueError, match="Invalid model identifier"):
        route_store.set("physics", "gemini", "models/gemini-pro")
    with pytest.raises(ValueError, match="Automatic routing"):
        route_store.set("english", "auto", "gemini-2.5-flash")


def test_corrupt_route_entries_fall_back_to_safe_defaults(route_store):
    route_store.path.parent.mkdir(parents=True, exist_ok=True)
    route_store.path.write_text(json.dumps({
        "subjects": {
            "physics": {"provider": ["not", "hashable"], "model": "gemini-pro"},
            "biology": {"provider": "gemini", "model": "../unexpected-path"},
        },
    }), encoding="utf-8")

    snapshot = route_store.snapshot()

    assert snapshot["physics"] == {"provider": "auto", "model": None}
    assert snapshot["biology"] == {"provider": "gemini", "model": None}


def test_configured_specialist_receives_the_subject_model(route_store, monkeypatch):
    model_id = "meta-llama/llama-3.3-70b-instruct:free"
    route_store.set("biology", "openrouter", model_id)
    monkeypatch.setattr(orchestrator, "OPENROUTER_KEY", "test-openrouter-key")
    engine = orchestrator.ConsiliumEngine(http_client=AsyncMock())
    ask_openrouter = AsyncMock(return_value="Biology specialist answer")
    engine._ask_openrouter = ask_openrouter

    response, provider = asyncio.run(engine._ask_cloud_specialist(
        "Explain cell division", "System prompt", "cloud-specialist", subject="biology",
    ))

    assert response == "Biology specialist answer"
    assert provider == "openrouter"
    assert ask_openrouter.await_args.kwargs["model"] == model_id
    assert engine.specialist_model_label == f"OpenRouter: {model_id}"


def test_failed_subject_model_is_not_reported_as_a_used_model(route_store, monkeypatch):
    route_store.set("physics", "gemini", "gemini-invalid-model")
    monkeypatch.setattr(orchestrator, "GEMINI_KEY", "test-gemini-key")
    monkeypatch.setattr(orchestrator, "KIMI_KEY", "")
    monkeypatch.setattr(orchestrator, "OPENROUTER_KEY", "")
    engine = orchestrator.ConsiliumEngine(http_client=AsyncMock())
    ask_gemini = AsyncMock(return_value="[Ошибка HTTP 404: Gemini]")
    fallback = AsyncMock(return_value=("[KIMI_API_KEY not set or the configured Kimi route failed]", "kimi"))
    engine._ask_gemini = ask_gemini
    engine._ask_default_cloud_specialist = fallback

    asyncio.run(engine._ask_cloud_specialist(
        "Explain a force", "System prompt", "cloud-specialist", subject="physics",
    ))

    assert "/gemini-invalid-model:generateContent" in ask_gemini.await_args.args[2]
    assert fallback.await_args.kwargs["excluded_provider"] == "gemini"
    assert engine.specialist_model_label is None


def test_model_routing_settings_are_loopback_only(route_store):
    with pytest.raises(HTTPException) as error:
        asyncio.run(orchestrator.get_subject_model_routes(_request("203.0.113.20")))

    assert error.value.status_code == 403

    routes = asyncio.run(orchestrator.get_subject_model_routes(_request("127.0.0.1")))
    assert set(item["subject"] for item in routes["subjects"]) == set(
        orchestrator.SUBJECT_MODEL_ROUTE_SUBJECTS
    )


def test_model_routing_settings_reject_untrusted_origins(route_store):
    with pytest.raises(HTTPException) as error:
        asyncio.run(orchestrator.get_subject_model_routes(
            _request("127.0.0.1", "https://attacker.example"),
        ))

    assert error.value.status_code == 403
