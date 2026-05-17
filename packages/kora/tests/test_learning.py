import os
import shutil
import pytest
from pathlib import Path
from kora.core.learning import LearningEngine

@pytest.fixture
def temp_learning_dir(tmp_path):
    d = tmp_path / "kora" / "learning"
    d.mkdir(parents=True, exist_ok=True)
    return d

def test_get_profile(temp_learning_dir):
    engine = LearningEngine(learning_dir=str(temp_learning_dir))
    profile = engine.get_profile("test_user")
    
    assert "spelling_mappings" in profile
    assert "technical_vocabulary" in profile
    assert "active_projects" in profile
    assert "user_preferences" in profile
    assert "conversational_style" in profile
    
    assert profile["spelling_mappings"]["niques"] == "NixOS"

def test_correct_transcription(temp_learning_dir):
    engine = LearningEngine(learning_dir=str(temp_learning_dir))
    
    # Text with spelling mistakes
    text = "eu quero compilar no hyperland e testar no glacie"
    corrected = engine.correct_transcription(text, "test_user")
    
    assert "Hyprland" in corrected
    assert "Glacier" in corrected
    assert "hyperland" not in corrected
    assert "glacie" not in corrected

def test_should_trigger_learning(temp_learning_dir):
    engine = LearningEngine(learning_dir=str(temp_learning_dir))
    
    assert engine._should_trigger_learning("você transcreveu errado, eu quis dizer NixOS") == True
    assert engine._should_trigger_learning("eu prefiro a voz mais doce") == True
    assert engine._should_trigger_learning("estou trabalhando no Caelestia shell") == True
    assert engine._should_trigger_learning("como está o tempo hoje?") == False

class MockOllamaAdapter:
    async def generate(self, prompt, system_prompt):
        return """
        {
          "spelling_mappings": {"proxmoxe": "Proxmox"},
          "new_vocabulary": ["LXD", "ZFS"],
          "active_projects": ["Proxmox Migration"],
          "preferences": ["Prefere comandos de terminal diretos"]
        }
        """

@pytest.mark.anyio
async def test_learn_from_turn(temp_learning_dir, monkeypatch):
    engine = LearningEngine(learning_dir=str(temp_learning_dir))
    engine.llm = MockOllamaAdapter()
    
    user_msg = "Você transcreveu proxmoxe errado, o correto é Proxmox. Estou trabalhando no projeto Proxmox Migration e prefiro comandos diretos."
    assistant_resp = "Entendido, farei a correção."
    
    # First turn
    await engine.learn_from_turn(user_msg, assistant_resp, "test_user")
    
    profile = engine.get_profile("test_user")
    assert profile["spelling_mappings"]["proxmoxe"] == "Proxmox"
    assert "LXD" in profile["technical_vocabulary"]
    assert "ZFS" in profile["technical_vocabulary"]
    assert "Proxmox Migration" in profile["active_projects"]
    assert "Prefere comandos de terminal diretos" in profile["user_preferences"]
