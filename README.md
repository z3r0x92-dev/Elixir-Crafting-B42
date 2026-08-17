# Elixir Crafting — Knox Cure & Adrenaline (Build 42)

A lightweight Project Zomboid Build 42 mod that adds two configurable emergency treatments for single-player and multiplayer. Multiplayer treatment effects, cooldowns, and logs are validated by the server.

- **Experimental Knox Cure** — guarantees removal of the Knox infection and restores the character to full physical health.
- **Adrenaline Stimulant** — restores endurance and optionally clears fatigue.

The cure integrates with **Antibodies v1.97** when it is installed. Antibodies remains the condition-based recovery path, while the Experimental Knox Cure provides a rare guaranteed alternative.

> Status: pre-release. The script and archive structure have been validated, but the mod must complete in-game Build 42.20 multiplayer testing before a stable release is published.

## Features

- Native Build 42 `craftRecipe` formatting
- Build 42 versioned mod structure
- Optional Antibodies v1.97 integration
- Configurable crafting availability
- Persistent per-character cooldowns
- Server-authoritative multiplayer treatment application
- Cooldown-safe rejection with item return
- Configurable stamina restoration
- Optional fatigue removal
- Optional stimulant panic, stress, and thirst costs
- Configurable First Aid crafting requirements
- Optional rare medical-container loot
- Server-console usage logging
- English localization
- Custom inventory icons and Workshop artwork
- No overrides of vanilla or Antibodies files

## Compatibility

| Component | Status |
|---|---|
| Project Zomboid Build 42.20 | Target version |
| Single-player | Supported by design; testing required |
| Multiplayer | Supported by design; dedicated-server testing required |
| Antibodies v1.97 | Optional integration |
| Survivor League / Meeks Protocol | Separate namespace; no file overrides |

Antibodies is available at [Steam Workshop item 2392676812](https://steamcommunity.com/sharedfiles/filedetails/?id=2392676812).

The add-on calls Antibodies' own cure routine when its module is available and integration is enabled. If Antibodies is absent or integration is disabled, it uses the native Project Zomboid infection fields.

## Item IDs

```text
ElixirCraft.KnoxCure
ElixirCraft.StaminaElixir
```

Admin examples:

```text
additem "Username" "ElixirCraft.KnoxCure" 1
additem "Username" "ElixirCraft.StaminaElixir" 1
```

## Recipes

### Experimental Knox Cure

- 0.5 L water in a water bottle or white mug
- 5 Plantain
- 5 Ginseng
- 1 Antibiotics

### Adrenaline Stimulant

- 0.5 L water in a water bottle or white mug
- 5 Ginseng

The water is consumed while the container is retained.

## Sandbox settings

- Enable Experimental Knox Cure
- Allow players to craft the Knox Cure
- Knox Cure cooldown in in-game hours
- Knox Cure minimum First Aid level
- Enable Adrenaline Stimulant
- Adrenaline minimum First Aid level
- Adrenaline endurance restoration percentage
- Remove fatigue after stimulant use
- Panic, stress, and thirst added by the stimulant
- Adrenaline cooldown in in-game hours
- Enable or disable Antibodies integration
- Enable rare medical-container loot
- Separate Cure and Adrenaline loot chances
- Log treatment usage

Disable cure crafting to reserve it for administrators, Survivor League rewards, events, or server vendors.

## Local installation

Copy `src` as an `ElixirCraftB42` directory under the local mods directory:

```text
%USERPROFILE%\Zomboid\mods\ElixirCraftB42\42\mod.info
%USERPROFILE%\Zomboid\mods\ElixirCraftB42\common\media\...
```

Alternatively, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\build-release.ps1
```

Then extract `dist\ElixirCraftB42-v1.3.0.zip` into `%USERPROFILE%\Zomboid\mods`.

## Steam Workshop package

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\build-workshop.ps1
```

This creates:

```text
dist\ElixirCraftB42-Workshop\
├── workshop.txt
├── preview.png
└── Contents\mods\ElixirCraftB42\
```

Copy `ElixirCraftB42-Workshop` into `%USERPROFILE%\Zomboid\Workshop`, launch Project Zomboid, and open **Workshop → Create and update items**. Keep the first upload unlisted until it passes multiplayer testing.

After Steam assigns an ID, preserve the generated `id=` value in your private upload workspace. Do not commit a personal Workshop ID to a community fork unless that fork owns the corresponding Workshop item.

## Dedicated server

After publication, configure the server with both Workshop IDs and Mod IDs:

```ini
WorkshopItems=2392676812;ELIXIR_WORKSHOP_ID
Mods=lgd_antibodies;ElixirCraftB42
```

Antibodies is optional at the code level. Remove its Workshop and Mod IDs if the server does not use it.

## Repository structure

```text
src/                 Editable Project Zomboid mod
tools/               PowerShell release builders
workshop/            Workshop metadata template and preview
CHANGELOG.md          Version history
CONTRIBUTING.md       Contribution and testing guidance
LICENSE               MIT License
```

## Testing

Before publishing a stable release, verify:

1. Both items load without World Dictionary errors.
2. Both recipes appear and consume the correct ingredients.
3. The cure removes infection and restores all body parts.
4. Antibodies no longer reports an active infection after the cure.
5. Cooldowns survive relogging and reconnecting.
6. Sandbox settings appear in hosted and dedicated-server configuration.
7. A remote multiplayer client receives the same results as the host.
8. `console.txt` contains no Lua exceptions or repeated warnings.
9. A cooldown rejection returns the consumed item without duplicating it.
10. Disabled loot spawning adds no items to newly generated containers.

## Automated validation

Run the repository validator before packaging:

```text
python tools/validate.py
```

GitHub Actions also checks the Build 42 structure, IDs, script hooks, translations,
textures, and Lua syntax on pushes and pull requests.

Please attach relevant `console.txt` excerpts and reproduction steps to bug reports.

## Credits

- Developed for the Meeks Protocol Project Zomboid server.
- Antibodies compatibility targets the open-source work by lonegamedev.
- Project Zomboid is developed by The Indie Stone.

This project does not redistribute Antibodies or Project Zomboid assets.

## License

Released under the [MIT License](LICENSE).
