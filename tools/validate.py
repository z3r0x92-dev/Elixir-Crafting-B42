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
client = require(SRC / "common" / "media" / "lua" / "client" / "ElixirClient.lua")
sandbox = require(SRC / "common" / "media" / "sandbox-options.txt")
sandbox_en = require(
    SRC / "common" / "media" / "lua" / "shared" / "Translate" / "EN" / "Sandbox_EN.txt"
)

for expected in (
    "id=ElixirCraftB42",
    "modversion=1.4.2",
    "poster=poster.png",
):
    if expected not in mod_info:
        errors.append(f"mod.info missing: {expected}")

for item_id in ("KnoxCure", "StaminaElixir"):
    if len(re.findall(rf"\bitem\s+{re.escape(item_id)}\b", items)) != 1:
        errors.append(f"expected exactly one item definition for {item_id}")

if items.count("ItemType = base:normal,") != 2:
    errors.append("both elixirs must use the Build 42 ItemType = base:normal syntax")
if "OnEat" in items or re.search(r"\bType\s*=\s*Food\b", items):
    errors.append("elixirs must not use the legacy client-consumed food path")

for recipe_id in ("CraftKnoxCure", "CraftAdrenalineStimulant"):
    if f"craftRecipe {recipe_id}" not in recipes:
        errors.append(f"missing Build 42 recipe: {recipe_id}")

for marker in (
    "function ElixirConsumption.ApplyTreatment",
    "function ElixirConsumption.ValidateTreatment",
    "function ElixirConsumption.ProcessPostCrash",
    'setting("EnableAdrenalineCrafting", true)',
    'setting("CureTreatmentScope", 2)',
    'setting("StimulantOverdoseWindowHours", 12.0)',
):
    if marker not in shared:
        errors.append(f"shared treatment flow missing marker: {marker}")

for marker in (
    'sendClientCommand(MODULE, "UseTreatment"',
    "itemId = tostring(item:getID())",
    "Events.OnFillInventoryObjectContextMenu.Add(addContextOptions)",
):
    if marker not in client:
        errors.append(f"client treatment flow missing marker: {marker}")

for marker in (
    'command ~= "UseTreatment"',
    'sendServerCommand(player, MODULE, "TreatmentApplied"',
    "pruneRecentRequests(now)",
    "Never mint inventory from client-provided counts",
    "findItem(player:getInventory(), itemId, expectedType)",
    "container:Remove(item)",
    "sendRemoveItemFromContainer(container, item)",
    "sendAddItemToContainer(container, item)",
    "pcall(\n        ElixirConsumption.ApplyTreatment",
    "Events.OnPlayerUpdate.Add(onPlayerUpdate)",
    "Events.OnClientCommand.Add(onClientCommand)",
    "elseif announcement == 3 then",
):
    if marker not in server:
        errors.append(f"server authority flow missing marker: {marker}")

for insecure_marker in ("countAfter", "refundIfMissing", "OnEatKnoxCure", "OnEatAdrenalineStimulant"):
    if insecure_marker in server or insecure_marker in shared or insecure_marker in client:
        errors.append(f"client-trusted inventory marker must not be present: {insecure_marker}")

for marker in (
    "local integrationOk, provider = pcall(function()",
    "Antibodies integration failed; using vanilla cure fallback",
    "local function resolveAntibodies()",
):
    if marker not in shared:
        errors.append(f"Antibodies fallback missing marker: {marker}")

if "default = 12.0," not in sandbox:
    errors.append("the overdose window must default to 12 in-game hours")

translations = set(re.findall(r"translation\s*=\s*([A-Za-z0-9_]+)", sandbox))
for key in sorted(translations):
    if f"Sandbox_ElixirCraftB42_{key}" not in sandbox_en:
        errors.append(f"missing Sandbox translation: {key}")

for required_option in (
    "KnoxCureMedicalLevel",
    "EnableAdrenalineCrafting",
    "CureTreatmentScope",
    "CureEffectiveness",
    "OneCurePerCharacter",
    "EnableStimulantPostCrash",
    "StimulantOverdoseWindowHours",
    "AdminOnlyCrafting",
    "UsageAnnouncement",
    "EnableDebugLogging",
):
    if f"option ElixirCraftB42.{required_option}" not in sandbox:
        errors.append(f"missing v1.4 Sandbox option: {required_option}")

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
