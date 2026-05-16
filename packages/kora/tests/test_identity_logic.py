import os
import json
from kora.core.identity import detect_runtime_identity, resolve_identity, get_identity_response

def test_identity(user_env):
    os.environ["USER"] = user_env
    runtime = detect_runtime_identity()
    profile = resolve_identity(runtime)
    response = get_identity_response(profile)
    
    print(f"--- TEST: {user_env} ---")
    print(f"ID: {profile.get('id')}")
    print(f"Level: {profile.get('permission_level')}")
    print(f"Response: {response}\n")

if __name__ == "__main__":
    # Ensure UserRegistry uses /tmp for test
    os.environ["KORA_USER_STORAGE"] = "/tmp/kora/users"
    
    # Create test registry if needed
    from kora.core.users import UserRegistry, KoraUser
    reg = UserRegistry("/tmp/kora/users")
    
    # Re-init for this process
    ragton = KoraUser(id="ragton", display_name="Ragton", full_name="Gabriel Aguiar Rocha", linux_user="rocha", role="owner", permission_level="admin_owner")
    nicoly = KoraUser(id="nicoly", display_name="Nicoly", linux_user="nina", role="trusted_partner", permission_level="trusted_user")
    reg.save_user(ragton)
    reg.save_user(nicoly)

    test_identity("rocha")
    test_identity("nina")
    test_identity("visitor")
