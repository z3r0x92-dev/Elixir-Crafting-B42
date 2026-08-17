local MEDICAL_CONTAINERS = {
    medical = true,
    medicine = true,
    firstaid = true,
    counter = true,
}

local function setting(name, fallback)
    local options = SandboxVars and SandboxVars.ElixirCraftB42
    if options and options[name] ~= nil then return options[name] end
    return fallback
end

local function isMedicalContainer(roomType, containerType)
    local room = string.lower(tostring(roomType or ""))
    local container = string.lower(tostring(containerType or ""))
    if MEDICAL_CONTAINERS[container] then return true end
    return string.find(room, "medical", 1, true)
        or string.find(room, "hospital", 1, true)
        or string.find(room, "pharmacy", 1, true)
end

local function roll(chance)
    return (ZombRandFloat and ZombRandFloat(0.0, 100.0) or 100.0) < chance
end

local function onFillContainer(roomType, containerType, container)
    if not setting("EnableLootSpawns", false) or not container then return end
    if not isMedicalContainer(roomType, containerType) then return end

    local inventory = container
    if container.getItemContainer then
        inventory = container:getItemContainer() or container
    end
    if not inventory then return end
    if setting("EnableKnoxCure", true)
        and roll(tonumber(setting("KnoxCureLootChance", 0.05)) or 0.05) then
        inventory:AddItem("ElixirCraft.KnoxCure")
    end
    if setting("EnableAdrenalineStimulant", true)
        and roll(tonumber(setting("AdrenalineLootChance", 0.25)) or 0.25) then
        inventory:AddItem("ElixirCraft.StaminaElixir")
    end
end

Events.OnFillContainer.Add(onFillContainer)
