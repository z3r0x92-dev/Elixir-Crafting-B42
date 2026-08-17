ELIXIR CRAFTING B42 v1.4.1
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
- Experimental Knox Cure: guaranteed infection cure; infection-and-bite scope by default.
- Cure crafting: enabled; admins can disable it for reward/event-only use.
- Cure cooldown: 24 in-game hours.
- Adrenaline Stimulant: 70% endurance recovery, fatigue preserved, 6-hour cooldown.
- Overdose window: 12 in-game hours, allowing a risky second dose after cooldown.
- Usage logging: enabled.
- Antibodies integration: enabled when the compatible module is detected.
- Rare medical-container loot: disabled by default.
- First Aid requirements: Cure 6, Adrenaline 3.
- Stimulant post-crash: enabled; overdose penalties are configurable.
- Rejected pre-validation requests leave the exact item untouched.
- Failed post-consumption treatments return the same item object when configured.

ANTIBODIES COMPATIBILITY
- Compatible with Antibodies v1.97 (Workshop ID 2392676812).
- Antibodies continues to provide condition-based, chance-driven recovery.
- The Experimental Knox Cure is the separate guaranteed recovery path.
- Cure use invokes Antibodies' own cure method and resets its cached levels.
- Antibodies is supported but not required; this add-on remains standalone.

MULTIPLAYER
- Right-click an elixir in inventory to use it.
- The server locates and removes the exact inventory item before applying treatment.
- Rejected requests cannot create replacement items.
- Dedicated-server logging records validated use.

ADMIN COMMANDS
additem "Username" "ElixirCraft.KnoxCure" 1
additem "Username" "ElixirCraft.StaminaElixir" 1

NOTES
- Water is consumed from the selected bottle or mug; the container is retained.
- Sandbox changes should be made while the server is stopped, then restarted.
- Test on a staging save before enabling infection curing on a public server.
