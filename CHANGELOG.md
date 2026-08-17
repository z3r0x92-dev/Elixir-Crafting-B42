# Changelog

All notable changes to this project will be documented here.

## [Unreleased]

- In-game Build 42.20 multiplayer validation.
- Balance review for cure ingredients and cooldowns.

## [1.3.0] - 2026-08-17

### Added

- Server-authoritative multiplayer treatment application.
- Server-side cooldown validation and treatment-use logging.
- Cooldown rejection item return.
- Per-player request rate limiting.
- Optional Antibodies integration toggle.
- Configurable First Aid requirements for both recipes.
- Optional rare medical-container loot with separate item chances.
- Optional stimulant panic, stress, and thirst costs.
- Automated repository validation and Lua compile checks.

### Changed

- Updated package and documentation version to 1.3.0.
- Expanded multiplayer test requirements.

## [1.2.0] - 2026-08-17

### Added

- Experimental Knox Cure.
- Adrenaline Stimulant.
- Optional Antibodies v1.97 medical-file integration.
- Native Sandbox settings.
- Persistent per-character cooldowns.
- Configurable endurance restoration and fatigue removal.
- Treatment-use logging with username, character, and coordinates.
- English item, recipe, interface, and Sandbox translations.
- Custom poster and inventory icons.
- Build and Workshop packaging scripts.

### Changed

- Redesigned the original Instant Health Potion as a guaranteed Knox cure.
- Increased the cure recipe cost to include Plantain, Ginseng, and Antibiotics.
- Separated guaranteed cure behavior from Antibodies' condition-based recovery.

## [1.1.0] - 2026-08-17

- Initial configurable health and stamina prototype.
