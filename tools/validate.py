#!/usr/bin/env python3
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
errors = []


def require(path: Path) -> str:
    if not path.is_file():
        errors.append(f"missing required file: {path.relative_to(ROOT)}")
        return ""
    return path.read_text(encoding="utf-8")


mod_info = require(SRC / "42" / "mod.info")
items = require(SRC / "common" / "media" / "scripts" / "elixirs_items.txt")
recipes = require(SRC / "common" / "media" / "scripts" / "elixirs_recipes.txt")
shared = require(SRC / "common" / "media" / "lua" / "shared" / "ElixirConsumption.lua")
server = require(SRC / "common" / "media" / "lua" / "server" / "ElixirServer.lua")
sandbox = require(SRC / "common" / "media" / "sandbox-options.txt")
sandbox_en = require(
    SRC / "common" / "media" / "lua" / "shared" / "Translate" / "EN" / "Sandbox_EN.txt"
)

for expected in (
    "id=ElixirCraftB42",
    "modversion=1.3.0",
    "poster=poster.png",
):
    if expected not in mod_info:
        errors.append(f"mod.info missing: {expected}")

for item_id, hook in (
    ("KnoxCure", "ElixirConsumption.OnEatKnoxCure"),
    ("StaminaElixir", "ElixirConsumption.OnEatAdrenalineStimulant"),
):
    if len(re.findall(rf"\bitem\s+{re.escape(item_id)}\b", items)) != 1:
        errors.append(f"expected exactly one item definition for {item_id}")
    if hook not in items:
        errors.append(f"missing item hook: {hook}")

for recipe_id in ("CraftKnoxCure", "CraftAdrenalineStimulant"):
    if f"craftRecipe {recipe_id}" not in recipes:
        errors.append(f"missing Build 42 recipe: {recipe_id}")

for marker in (
    'sendClientCommand(MODULE, "UseTreatment"',
    "function ElixirConsumption.ApplyTreatment",
):
    if marker not in shared:
        errors.append(f"shared treatment flow missing marker: {marker}")

for marker in (
    'command ~= "UseTreatment"',
    'sendServerCommand(player, MODULE, "TreatmentApplied"',
    "Events.OnClientCommand.Add(onClientCommand)",
):
    if marker not in server:
        errors.append(f"server authority flow missing marker: {marker}")

translations = set(re.findall(r"translation\s*=\s*([A-Za-z0-9_]+)", sandbox))
for key in sorted(translations):
    if f"Sandbox_ElixirCraftB42_{key}" not in sandbox_en:
        errors.append(f"missing Sandbox translation: {key}")

for icon in ("Item_PotionHealth.png", "Item_PotionStamina.png"):
    icon_path = SRC / "common" / "media" / "textures" / icon
    if not icon_path.is_file() or icon_path.stat().st_size == 0:
        errors.append(f"missing or empty texture: {icon_path.relative_to(ROOT)}")

if errors:
    print("VALIDATION FAILED")
    for error in errors:
        print(f"- {error}")
    sys.exit(1)

print("VALIDATION PASSED")
print("Build 42 structure, IDs, hooks, translations, and assets are present.")
