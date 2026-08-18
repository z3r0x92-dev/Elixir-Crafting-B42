local function setting(name, fallback)
    local options = SandboxVars and SandboxVars.ElixirCraftB42
    if options and options[name] ~= nil then return options[name] end
    return fallback
end

local function isMedicalContainer(roomType, containerType)
    local room = string.lower(tostring(roomType or ""))
    local container = string.lower(tostring(containerType or ""))
    local function contains(value, fragment)
        return string.find(value, fragment, 1, true) ~= nil
    end
    if setting("LootPharmacies", true)
        and (contains(room, "pharmacy") or contains(room, "drugstore")) then return true end
    if setting("LootHospitals", true)
        and (contains(room, "hospital") or contains(room, "medical")
            or container == "medicine" or container == "firstaid") then return true end
    if setting("LootAmbulances", true)
        and (contains(room, "ambulance") or contains(container, "ambulance")) then return true end
    if setting("LootMilitaryMedical", false)
        and contains(room, "military") and contains(container, "medical") then return true end
    if setting("LootLaboratories", false)
        and (contains(room, "laboratory") or contains(room, "lab")) then return true end
    if setting("LootSurvivorCaches", false)
        and (contains(room, "survivor") or contains(container, "survivor")) then return true end
    return false
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
