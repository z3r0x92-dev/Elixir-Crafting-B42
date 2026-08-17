require "ElixirConsumption"

local MODULE = "ElixirCraftB42"

local treatments = {
    ["ElixirCraft.KnoxCure"] = "KnoxCure",
    ["ElixirCraft.StaminaElixir"] = "AdrenalineStimulant",
}

local function notify(player, text)
    if HaloTextHelper and HaloTextHelper.addGoodText then
        HaloTextHelper.addGoodText(player, text)
    elseif player and player.Say then
        player:Say(text)
    end
end

local function textOr(key, fallback, ...)
    local value = getText(key, ...)
    if not value or value == key then return fallback end
    return value
end

local function selectedItem(entry)
    if instanceof(entry, "InventoryItem") then return entry end
    if type(entry) == "table" and entry.items and entry.items[1] then
        return entry.items[1]
    end
    return nil
end

local function shouldReturn(treatment)
    if treatment == "KnoxCure" then
        return not ElixirConsumption.Setting("ConsumeCureOnFailedUse", false)
    end
    return ElixirConsumption.Setting("ReturnRejectedStimulant", true)
end

local function useSinglePlayer(player, item, treatment)
    local ok, reason, detail = ElixirConsumption.ValidateTreatment(player, treatment)
    if not ok then
        notify(player, reason == "cooldown"
            and textOr("IGUI_ElixirCraft_Cooldown",
                "Your body needs more time before another elixir.", detail or 1)
            or textOr("IGUI_ElixirCraft_TreatmentRejectedKept",
                "The treatment was rejected. The item remains in your inventory."))
        return
    end

    local container = item:getContainer()
    if not container then return end
    container:Remove(item)
    local applied, applyOk, applyReason, applyDetail = pcall(
        ElixirConsumption.ApplyTreatment, player, treatment)
    if applied then
        ok, reason, detail = applyOk, applyReason, applyDetail
    else
        ok, reason, detail = false, "treatment-error", nil
    end
    if not ok and shouldReturn(treatment) then container:AddItem(item) end
    notify(player, ok and getText(treatment == "KnoxCure"
        and "IGUI_ElixirCraft_KnoxCureUsed"
        or "IGUI_ElixirCraft_AdrenalineUsed")
        or getText("IGUI_ElixirCraft_TreatmentRejected"))
end

local function requestUse(player, item, treatment)
    if isClient and isClient() then
        sendClientCommand(MODULE, "UseTreatment", {
            treatment = treatment,
            itemType = item:getFullType(),
            itemId = tostring(item:getID()),
        })
        return
    end
    useSinglePlayer(player, item, treatment)
end

local function addContextOptions(playerIndex, context, items)
    local player = getSpecificPlayer(playerIndex)
    if not player then return end
    local added = {}
    for _, entry in ipairs(items) do
        local item = selectedItem(entry)
        local fullType = item and item:getFullType()
        local treatment = fullType and treatments[fullType]
        if treatment and not added[treatment] then
            local label = treatment == "KnoxCure"
                and textOr("ContextMenu_ElixirCraft_UseKnoxCure",
                    "Use Experimental Knox Cure")
                or textOr("ContextMenu_ElixirCraft_UseAdrenaline",
                    "Use Adrenaline Stimulant")
            context:addOption(label, player, requestUse, item, treatment)
            added[treatment] = true
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(addContextOptions)
