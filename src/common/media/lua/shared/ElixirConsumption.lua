ElixirConsumption = ElixirConsumption or {}

local MOD_DATA_KEY = "ElixirCraftB42"
local MODULE = "ElixirCraftB42"

local function setting(name, fallback)
    local options = SandboxVars and SandboxVars.ElixirCraftB42
    if options and options[name] ~= nil then return options[name] end
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

local function validPlayer(player)
    return player and instanceof(player, "IsoPlayer") and not player:isDead()
end

local function remainingCooldown(player, field, cooldown)
    if cooldown <= 0 then return 0 end
    local usedAt = tonumber(stateFor(player)[field]) or -1000000
    return math.max(0, cooldown - (worldHours() - usedAt))
end

local function notify(player, text)
    if not player then return end
    if HaloTextHelper and HaloTextHelper.addGoodText then
        HaloTextHelper.addGoodText(player, text)
    elseif player.Say then
        player:Say(text)
    end
end

local function medicalLevel(recipeData)
    local player = recipeData and (recipeData.character or recipeData.player)
    if not player and getPlayer then player = getPlayer() end
    if not player or not player.getPerkLevel or not Perks or not Perks.Doctor then return 0 end
    return tonumber(player:getPerkLevel(Perks.Doctor)) or 0
end

local function canUseAdminCrafting(player)
    if not setting("AdminOnlyCrafting", false) then return true end
    if not player or not player.getAccessLevel then return false end
    local level = tostring(player:getAccessLevel() or "")
    return level == "admin" or level == "moderator" or level == "overseer"
end

local function recipePlayer(recipeData)
    local player = recipeData and (recipeData.character or recipeData.player)
    if not player and getPlayer then player = getPlayer() end
    return player
end

local function rollPercent(chance)
    chance = math.max(0, math.min(100, tonumber(chance) or 0))
    if chance >= 100 then return true end
    if ZombRandFloat then return ZombRandFloat(0.0, 100.0) < chance end
    return false
end

local function cureKnoxInfection(player)
    if setting("EnableAntibodiesIntegration", true) then
        local loaded, medicalFileModule = pcall(require, "antibodies_medical_file")
        if loaded and medicalFileModule and medicalFileModule.of then
            local medicalFile = medicalFileModule.of(player, false)
            if medicalFile and medicalFile.cureKnoxVirus then
                medicalFile:cureKnoxVirus(player)
                medicalFile.knoxInfectionLevel = 0
                medicalFile.knoxInfectionDelta = 0
                medicalFile.knoxAntibodiesLevel = 0
                if medicalFile.updateKnoxInfection then medicalFile:updateKnoxInfection(player) end
                return "Antibodies"
            end
        end
    end

    local damage = player:getBodyDamage()
    local parts = damage:getBodyParts()
    for i = 0, parts:size() - 1 do parts:get(i):SetInfected(false) end
    damage:setInfected(false)
    damage:setInfectionTime(-1.0)
    damage:setInfectionMortalityDuration(-1.0)
    return "Vanilla"
end

local function clearBitesAndWounds(damage, scope)
    if scope < 2 then return end
    local parts = damage:getBodyParts()
    for i = 0, parts:size() - 1 do
        local part = parts:get(i)
        part:SetBitten(false)
        if scope >= 3 then
            part:setBleeding(false)
            part:setDeepWounded(false)
            part:setHaveGlass(false)
            part:setScratched(false, true)
            part:setCut(false)
            part:setBurnTime(0)
            part:setFractureTime(0)
        end
    end
end

local function applyPostCrash(player)
    local state = stateFor(player)
    local due = tonumber(state.adrenalineCrashAt)
    if not due or worldHours() < due then return end
    state.adrenalineCrashAt = nil
    if not setting("EnableStimulantPostCrash", true) then return end
    local stats = player:getStats()
    if not stats then return end
    local fatigue = math.max(0, math.min(1,
        tonumber(setting("StimulantCrashFatigue", 0.35)) or 0.35))
    stats:setFatigue(math.max(stats:getFatigue(), fatigue))
    notify(player, getText("IGUI_ElixirCraft_AdrenalineCrash"))
end

local function logUse(player, treatment, provider)
    if not setting("EnableUsageLogging", true) then return end
    local username = player:getUsername() or "unknown"
    print(string.format(
        "[ElixirCraftB42] USE treatment=%s provider=%s username=%s character=%s x=%d y=%d z=%d",
        treatment, provider or "native", username, player:getDisplayName() or username,
        math.floor(player:getX()), math.floor(player:getY()), math.floor(player:getZ())
    ))
end

function ElixirConsumption.GetRemainingCooldown(player, treatment)
    if not validPlayer(player) then return 0 end
    if treatment == "KnoxCure" then
        return remainingCooldown(player, "lastKnoxCureUse",
            tonumber(setting("KnoxCureCooldownHours", 24.0)) or 24.0)
    end
    return remainingCooldown(player, "lastAdrenalineUse",
        tonumber(setting("AdrenalineCooldownHours", 6.0)) or 6.0)
end

function ElixirConsumption.CanCraftKnoxCure(recipeData)
    local player = recipePlayer(recipeData)
    return setting("EnableKnoxCure", true)
        and setting("EnableKnoxCureCrafting", true)
        and canUseAdminCrafting(player)
        and medicalLevel(recipeData) >= (tonumber(setting("KnoxCureMedicalLevel", 0)) or 0)
end

function ElixirConsumption.CanCraftAdrenalineStimulant(recipeData)
    local player = recipePlayer(recipeData)
    return setting("EnableAdrenalineStimulant", true)
        and setting("EnableAdrenalineCrafting", true)
        and canUseAdminCrafting(player)
        and medicalLevel(recipeData) >= (tonumber(setting("AdrenalineMedicalLevel", 0)) or 0)
end

function ElixirConsumption.ApplyTreatment(player, treatment)
    if not validPlayer(player) then return false, "invalid-player" end

    local remaining = ElixirConsumption.GetRemainingCooldown(player, treatment)
    if remaining > 0 then return false, "cooldown", math.ceil(remaining) end

    if treatment == "KnoxCure" then
        if not setting("EnableKnoxCure", true) then return false, "disabled" end
        local state = stateFor(player)
        if setting("OneCurePerCharacter", false) and state.usedKnoxCure then
            return false, "one-cure-limit"
        end
        if not rollPercent(setting("CureEffectiveness", 100.0)) then
            return false, "ineffective"
        end
        local damage = player:getBodyDamage()
        if not damage then return false, "no-body-damage" end
        local provider = cureKnoxInfection(player)
        local scope = math.max(1, math.min(4,
            tonumber(setting("CureTreatmentScope", 2)) or 2))
        clearBitesAndWounds(damage, scope)
        if scope >= 4 then
            damage:RestoreToFullHealth()
            damage:setOverallBodyHealth(100.0)
        end
        state.lastKnoxCureUse = worldHours()
        state.usedKnoxCure = true
        logUse(player, treatment, provider)
        return true, provider
    end

    if treatment == "AdrenalineStimulant" then
        if not setting("EnableAdrenalineStimulant", true) then return false, "disabled" end
        local state = stateFor(player)
        local previousUse = tonumber(state.lastAdrenalineUse) or -1000000
        local overdoseWindow = math.max(0,
            tonumber(setting("StimulantOverdoseWindowHours", 6.0)) or 6.0)
        local overdosed = overdoseWindow > 0 and worldHours() - previousUse < overdoseWindow
        local stats = player:getStats()
        if not stats then return false, "no-stats" end
        local restore = math.max(1, math.min(100,
            tonumber(setting("AdrenalineRestorePercent", 100.0)) or 100.0)) / 100
        stats:setEndurance(math.min(1.0, stats:getEndurance() + restore))
        if setting("ClearFatigue", true) then stats:setFatigue(0) end
        stats:setEnduranceRecharging(false)
        stats:setPanic(math.min(100, stats:getPanic()
            + (tonumber(setting("AdrenalinePanic", 0)) or 0)))
        stats:setStress(math.min(1.0, stats:getStress()
            + (tonumber(setting("AdrenalineStress", 0.0)) or 0.0)))
        stats:setThirst(math.min(1.0, stats:getThirst()
            + (tonumber(setting("AdrenalineThirst", 0.0)) or 0.0)))
        if overdosed then
            local damage = player:getBodyDamage()
            local healthLoss = math.max(0, math.min(100,
                tonumber(setting("StimulantOverdoseHealthLoss", 10.0)) or 10.0))
            if damage and healthLoss > 0 then
                damage:setOverallBodyHealth(math.max(1,
                    damage:getOverallBodyHealth() - healthLoss))
            end
            stats:setPanic(math.min(100, stats:getPanic() + 35))
            stats:setStress(math.min(1.0, stats:getStress() + 0.35))
        end
        state.lastAdrenalineUse = worldHours()
        state.adrenalineCrashAt = worldHours() + math.max(0,
            tonumber(setting("StimulantEffectDurationHours", 1.0)) or 1.0)
        logUse(player, treatment, "native")
        return true, "native"
    end

    return false, "unknown-treatment"
end

local function countAfterUse(player, fullType)
    local inventory = player and player:getInventory()
    if not inventory or not inventory.getItemCountRecurse then return 0 end
    return inventory:getItemCountRecurse(fullType)
end

local function returnRejectedItem(player, treatment, fullType)
    local shouldReturn = treatment == "KnoxCure"
        and not setting("ConsumeCureOnFailedUse", false)
        or treatment == "AdrenalineStimulant"
        and setting("ReturnRejectedStimulant", true)
    local inventory = player and player:getInventory()
    if shouldReturn and inventory then inventory:AddItem(fullType) end
end

local function requestTreatment(player, treatment, fullType)
    if not validPlayer(player) then return end
    if isClient and isClient() then
        sendClientCommand(MODULE, "UseTreatment", {
            treatment = treatment,
            itemType = fullType,
            countAfter = countAfterUse(player, fullType),
        })
        return
    end

    local ok, reason, detail = ElixirConsumption.ApplyTreatment(player, treatment)
    if ok then
        notify(player, getText(treatment == "KnoxCure"
            and "IGUI_ElixirCraft_KnoxCureUsed"
            or "IGUI_ElixirCraft_AdrenalineUsed"))
    elseif reason == "cooldown" then
        returnRejectedItem(player, treatment, fullType)
        notify(player, getText("IGUI_ElixirCraft_Cooldown", detail))
    else
        returnRejectedItem(player, treatment, fullType)
        notify(player, getText("IGUI_ElixirCraft_TreatmentRejected"))
    end
end

function ElixirConsumption.OnEatKnoxCure(item, player, amount)
    if amount and amount < 0.99 then return end
    requestTreatment(player, "KnoxCure", "ElixirCraft.KnoxCure")
end

function ElixirConsumption.OnEatAdrenalineStimulant(item, player, amount)
    if amount and amount < 0.99 then return end
    requestTreatment(player, "AdrenalineStimulant", "ElixirCraft.StaminaElixir")
end

local function onServerCommand(module, command, args)
    if module ~= MODULE or not getPlayer then return end
    local player = getPlayer()
    if not player then return end
    if command == "TreatmentApplied" then
        notify(player, getText(args.treatment == "KnoxCure"
            and "IGUI_ElixirCraft_KnoxCureUsed"
            or "IGUI_ElixirCraft_AdrenalineUsed"))
    elseif command == "TreatmentRejected" then
        if args.reason == "cooldown" then
            notify(player, getText("IGUI_ElixirCraft_Cooldown", args.remaining or 1))
        else
            notify(player, getText("IGUI_ElixirCraft_TreatmentRejected"))
        end
    elseif command == "UsageAnnouncement" then
        notify(player, getText("IGUI_ElixirCraft_GlobalUse",
            args.username or "unknown", args.treatment or "treatment"))
    end
end

if Events and Events.OnServerCommand and isClient and isClient() then
    Events.OnServerCommand.Add(onServerCommand)
end

if Events and Events.OnPlayerUpdate then
    Events.OnPlayerUpdate.Add(applyPostCrash)
end
