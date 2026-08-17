# Changelog

All notable changes to this project will be documented here.

## [Unreleased]

- In-game Build 42.20 multiplayer validation.
- Balance review for cure ingredients and cooldowns.

## [1.4.2] - 2026-08-17

- Explicitly synchronize successful server-side item removal to multiplayer clients.
- Synchronize exact-item restoration when a configured rejection returns an elixir.
- Remove consumed elixirs from the player's hands before deleting them.
- Add readable English fallbacks when custom context-menu or notification translations are unavailable.

## [1.4.1] - 2026-08-17

### Security

- Replaced client-trusted consumption with a server-owned inventory transaction.
- Treatment requests now include an item instance ID that the server must locate.
- The server removes the exact item before applying a treatment.
- Rejected pre-validation requests leave inventory untouched.
- Removed client-controlled inventory counts and replacement-item minting.
- Added request-cache expiry and protected treatment execution.

### Changed

- Elixirs are used from a right-click inventory action instead of food consumption.
- Post-stimulant crash effects now run on the server and notify the client.
- Default overdose window increased from 6 to 12 hours.
- Antibodies discovery is cached and integration failures include diagnostic detail.
- Antibodies public cure behavior is preferred over direct internal-field mutation.
- Workshop packaging defaults to public visibility.
- Updated item definitions to current Build 42 `ItemType` syntax.

## [1.4.0] - 2026-08-17

### Added

- Complete Sandbox schema for all previously implemented v1.3 controls.
- Separate Adrenaline crafting toggle.
- Configurable cure scope, effectiveness, failed-use consumption, and one-cure limit.
- Configurable stimulant duration, post-crash fatigue, overdose window, and health loss.
- Rejected-stimulant item-return control.
- Per-location loot toggles for pharmacies, hospitals, ambulances, military medical
  containers, laboratories, and survivor caches.
- Admin-only crafting, treatment announcement mode, and diagnostic logging settings.
- Validation checks for the v1.4 Sandbox and gameplay controls.

### Changed

- Meeks Protocol defaults now use First Aid 6 for the cure and First Aid 3 for
  Adrenaline crafting.
- Adrenaline restores 70% endurance and does not clear fatigue by default.
- Cure scope defaults to infection and bites instead of unconditional full healing.
- Metadata, documentation, and release packaging now target v1.4.0.

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
