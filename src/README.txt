ELIXIR CRAFTING B42 v1.2.0
========================================

MOD ID
ElixirCraftB42

ITEM IDS
ElixirCraft.KnoxCure
ElixirCraft.StaminaElixir

INSTALLATION
Copy ElixirCraftB42 into C:\Users\<you>\Zomboid\mods\ and enable it.
For multiplayer, install the same version on the server and every client.
Append ElixirCraftB42 to the server Mods= line. After Workshop publication,
append its Workshop ID to WorkshopItems= as well.

DEFAULT BALANCE
- Experimental Knox Cure: guaranteed infection cure and full physical recovery.
- Cure crafting: enabled; admins can disable it for reward/event-only use.
- Cure cooldown: 24 in-game hours.
- Adrenaline Stimulant: full endurance/fatigue recovery, 6-hour cooldown.
- Usage logging: enabled.

ANTIBODIES COMPATIBILITY
- Compatible with Antibodies v1.97 (Workshop ID 2392676812).
- Antibodies continues to provide condition-based, chance-driven recovery.
- The Experimental Knox Cure is the separate guaranteed recovery path.
- Cure use invokes Antibodies' own cure method and resets its cached levels.
- Antibodies is supported but not required; this add-on remains standalone.

ADMIN COMMANDS
additem "Username" "ElixirCraft.KnoxCure" 1
additem "Username" "ElixirCraft.StaminaElixir" 1

NOTES
- Water is consumed from the selected bottle or mug; the container is retained.
- Sandbox changes should be made while the server is stopped, then restarted.
- Test on a staging save before enabling infection curing on a public server.
