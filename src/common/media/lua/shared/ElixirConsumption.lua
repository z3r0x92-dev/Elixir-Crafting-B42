ElixirConsumption = ElixirConsumption or {}

local MOD_DATA_KEY = "ElixirCraftB42"

local function setting(name, fallback)
    local options = SandboxVars and SandboxVars.ElixirCraftB42
    if options and options[name] ~= nil then
        return options[name]
    end
    return fallback
end

local function worldHours()
    local gameTime = getGameTime()
    return gameTime and gameTime:getWorldAgeHours() or 0
end

local function stateFor(player)
    local modData = player:getModData()
    modData[MOD_DATA_KEY] = modData[MOD_DATA_KEY] or {}
    return modData[MOD_DATA_KEY]
end

local function remainingCooldown(player, field, cooldown)
    if cooldown <= 0 then return 0 end
    local usedAt = tonumber(stateFor(player)[field]) or -1000000
    return math.max(0, cooldown - (worldHours() - usedAt))
end

local function notify(player, text)
    if HaloTextHelper and HaloTextHelper.addGoodText then
        HaloTextHelper.addGoodText(player, text)
    elseif player.Say then
        player:Say(text)
    end
end

local function logUse(player, potion)
    if not setting("EnableUsageLogging", true) then return end
    local username = player:getUsername() or "unknown"
    print(string.format(
        "[ElixirCraftB42] USE potion=%s username=%s character=%s x=%d y=%d z=%d",
        potion, username, player:getDisplayName() or username,
        math.floor(player:getX()), math.floor(player:getY()), math.floor(player:getZ())
    ))
end

local function validPlayer(player)
    return player and instanceof(player, "IsoPlayer") and not player:isDead()
end

local function cureKnoxInfection(player)
    -- Antibodies v1.97 keeps its own persistent medical record. Use its
    -- public module method when present so its cached infection state remains
    -- consistent with the native BodyDamage state.
    local loaded, medicalFileModule = pcall(require, "antibodies_medical_file")
    if loaded and medicalFileModule and medicalFileModule.of then
        local medicalFile = medicalFileModule.of(player, false)
        if medicalFile and medicalFile.cureKnoxVirus then
            medicalFile:cureKnoxVirus(player)
            medicalFile.knoxInfectionLevel = 0
            medicalFile.knoxInfectionDelta = 0
            medicalFile.knoxAntibodiesLevel = 0
            if medicalFile.updateKnoxInfection then
                medicalFile:updateKnoxInfection(player)
            end
            return "Antibodies"
        end
    end

    -- Standalone fallback matching the native cure state used by Antibodies.
    local damage = player:getBodyDamage()
    local parts = damage:getBodyParts()
    for i = 0, parts:size() - 1 do
        parts:get(i):SetInfected(false)
    end
    damage:setInfected(false)
    damage:setInfectionTime(-1.0)
    damage:setInfectionMortalityDuration(-1.0)
    return "Vanilla"
end

function ElixirConsumption.CanCraftKnoxCure(recipeData)
    return setting("EnableKnoxCure", true)
        and setting("EnableKnoxCureCrafting", true)
end

function ElixirConsumption.CanCraftAdrenalineStimulant(recipeData)
    return setting("EnableAdrenalineStimulant", true)
end

function ElixirConsumption.OnEatKnoxCure(item, player, amount)
    if not validPlayer(player) or not setting("EnableKnoxCure", true) then return end
    if amount and amount < 0.99 then return end

    local cooldown = tonumber(setting("KnoxCureCooldownHours", 24.0)) or 24.0
    local remaining = remainingCooldown(player, "lastKnoxCureUse", cooldown)
    if remaining > 0 then
        notify(player, getText("IGUI_ElixirCraft_Cooldown", math.ceil(remaining)))
        return
    end

    local damage = player:getBodyDamage()
    if not damage then return end
    -- Clear Antibodies and native Knox state first, then perform the full
    -- physical reset. This order prevents stale infection timers or cached
    -- Antibodies data from surviving the cure.
    local provider = cureKnoxInfection(player)
    damage:RestoreToFullHealth()
    damage:setOverallBodyHealth(100.0)

    stateFor(player).lastKnoxCureUse = worldHours()
    notify(player, getText("IGUI_ElixirCraft_KnoxCureUsed"))
    print("[ElixirCraftB42] Knox cure provider=" .. provider)
    logUse(player, "KnoxCure")
end

function ElixirConsumption.OnEatAdrenalineStimulant(item, player, amount)
    if not validPlayer(player) or not setting("EnableAdrenalineStimulant", true) then return end
    if amount and amount < 0.99 then return end

    local cooldown = tonumber(setting("AdrenalineCooldownHours", 6.0)) or 6.0
    local remaining = remainingCooldown(player, "lastAdrenalineUse", cooldown)
    if remaining > 0 then
        notify(player, getText("IGUI_ElixirCraft_Cooldown", math.ceil(remaining)))
        return
    end

    local stats = player:getStats()
    if not stats then return end
    local restore = math.max(1, math.min(100,
        tonumber(setting("AdrenalineRestorePercent", 100.0)) or 100.0)) / 100
    stats:setEndurance(math.min(1.0, stats:getEndurance() + restore))
    if setting("ClearFatigue", true) then stats:setFatigue(0) end
    stats:setEnduranceRecharging(false)

    stateFor(player).lastAdrenalineUse = worldHours()
    notify(player, getText("IGUI_ElixirCraft_AdrenalineUsed"))
    logUse(player, "AdrenalineStimulant")
end
