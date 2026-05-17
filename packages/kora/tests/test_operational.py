import os
from kora.core.operational import get_cpu_load, get_ram_usage, get_disk_usage, get_git_status, get_operational_context, format_operational_prompt

def test_get_cpu_load():
    load = get_cpu_load()
    assert isinstance(load, str)
    assert len(load) > 0

def test_get_ram_usage():
    ram = get_ram_usage()
    assert isinstance(ram, str)
    assert len(ram) > 0

def test_get_disk_usage():
    disk = get_disk_usage()
    assert isinstance(disk, str)
    assert len(disk) > 0

def test_get_git_status():
    git_ctx = get_git_status("/tmp/nonexistent_directory_for_kora_test")
    assert git_ctx["branch"] == "desconhecido"
    assert git_ctx["commit"] == "desconhecido"
    assert git_ctx["status"] == "CLEAN"

def test_get_operational_context():
    ctx = get_operational_context()
    assert "timestamp" in ctx
    assert "hostname" in ctx
    assert "cpu_load" in ctx
    assert "ram_usage" in ctx
    assert "disk_usage" in ctx
    assert "git_branch" in ctx
    assert "git_commit" in ctx
    assert "git_status" in ctx
    assert "glacier_online" in ctx

def test_format_operational_prompt():
    ctx = get_operational_context()
    prompt = format_operational_prompt(ctx)
    assert "Consciência Operacional" in prompt
    assert ctx["hostname"] in prompt
    assert ctx["git_branch"] in prompt
