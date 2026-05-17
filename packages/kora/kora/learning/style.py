from __future__ import annotations


def build_style_context(profile: dict) -> str:
    prefs = profile.get("user_preferences", [])
    style = profile.get("conversational_style", "tecnico, calmo, direto")
    return (
        f"Estilo conversacional: {style}.\n"
        f"Preferencias: {', '.join(prefs) if prefs else 'sem preferencias dinamicas'}."
    )
