# Contributing

Bug reports, balance feedback, translations, and compatibility improvements are welcome.

## Reporting a bug

Include:

- Project Zomboid build number
- Single-player, hosted multiplayer, or dedicated server
- Elixir Crafting version
- Antibodies version, if installed
- Exact reproduction steps
- Relevant `console.txt` errors
- Whether the issue reproduces without unrelated mods

Do not upload an entire server configuration containing passwords or other secrets.

## Development guidelines

- Keep the `ElixirCraft` script module and `ElixirConsumption` Lua namespace isolated.
- Do not overwrite vanilla or Antibodies files.
- Preserve standalone behavior when optional integrations are unavailable.
- Use Build 42 `craftRecipe` input/output syntax.
- Put user-facing text in translation files.
- Make server-affecting behavior configurable through native Sandbox settings.
- Test changes with a remote multiplayer client before marking them stable.

## Pull requests

Explain the problem, the proposed behavior, and how the change was tested. Keep unrelated formatting or refactoring out of focused fixes.

