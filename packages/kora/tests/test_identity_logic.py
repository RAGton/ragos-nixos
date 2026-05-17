import os
import pytest
from kora.core.identity import detect_runtime_identity, resolve_identity, get_identity_response
from kora.core.users import UserRegistry, KoraUser

@pytest.fixture(autouse=True)
def setup_users(tmp_path):
    storage_path = tmp_path / "users"
    os.environ["KORA_USER_STORAGE"] = str(storage_path)

    reg = UserRegistry(str(storage_path))
    ragton = KoraUser(id="ragton", display_name="Ragton", full_name="Gabriel Aguiar Rocha", linux_user="rocha", role="owner", permission_level="admin_owner")
    nicoly = KoraUser(id="nicoly", display_name="Nicoly", linux_user="nina", role="trusted_partner", permission_level="trusted_user")
    reg.save_user(ragton)
    reg.save_user(nicoly)

    yield

    if "KORA_USER_STORAGE" in os.environ:
        del os.environ["KORA_USER_STORAGE"]

@pytest.mark.parametrize("user_env,expected_name", [
    ("rocha", "Gabriel Aguiar Rocha"),
    ("nina", "Nicoly"),
    ("unknown_user", "Visitante Desconhecido"),
])
def test_identity_detection(user_env, expected_name, monkeypatch):
    monkeypatch.setenv("USER", user_env)
    runtime = detect_runtime_identity()
    identity_ctx = resolve_identity(runtime)
    profile = identity_ctx["resolved_identity"]

    assert profile is not None
    assert profile.get("full_name") == expected_name or profile.get("display_name") == expected_name
