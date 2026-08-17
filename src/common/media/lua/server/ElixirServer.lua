require "ElixirConsumption"

local MODULE = "ElixirCraftB42"
local recentRequests = {}
local REQUEST_WINDOW_MS = 750
local REQUEST_RETENTION_MS = 60000

local function setting(name, fallback)
    local options = SandboxVars and SandboxVars.ElixirCraftB42
    if options and options[name] ~= nil then return options[name] end
    return fallback
end

local function debugLog(message)
    if setting("EnableDebugLogging", false) then
        print("[ElixirCraftB42] DEBUG " .. tostring(message))
    end
end

local function playerKey(player)
    return tostring(player:getOnlineID()) .. ":" .. tostring(player:getUsername() or "unknown")
end

local function pruneRecentRequests(now)
    if now <= 0 then return end
    for key, requestedAt in pairs(recentRequests) do
        if now - requestedAt > REQUEST_RETENTION_MS then
            recentRequests[key] = nil
        end
    end
end

local function reject(player, args, reason, remaining)
    -- Never mint inventory from client-provided counts. A modified client could
    -- otherwise request rejected treatments repeatedly to duplicate items.
    debugLog(string.format("reject treatment=%s reason=%s itemKept=%s",
        tostring(args.treatment), tostring(reason), tostring(args.itemKept == true)))
    sendServerCommand(player, MODULE, "TreatmentRejected", {
        treatment = args.treatment,
        reason = reason,
        remaining = remaining,
        itemKept = args.itemKept == true,
    })
end

local function findItem(container, itemId, expectedType)
    if not container or not container.getItems then return nil, nil end
    local items = container:getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if tostring(item:getID()) == itemId and item:getFullType() == expectedType then
            return container, item
        end
        if item.getInventory then
            local nestedContainer, nestedItem = findItem(item:getInventory(), itemId, expectedType)
            if nestedItem then return nestedContainer, nestedItem end
        end
    end
    return nil, nil
end

local function shouldReturnRejected(treatment)
    if treatment == "KnoxCure" then
        return not setting("ConsumeCureOnFailedUse", false)
    end
    return setting("ReturnRejectedStimulant", true)
end

local function restoreItem(container, item)
    if not container or not item then return false end
    local restored = pcall(function() container:AddItem(item) end)
    return restored
end

local function onClientCommand(module, command, player, args)
    if module ~= MODULE or command ~= "UseTreatment" or not player then return end
    args = args or {}
    local treatment = tostring(args.treatment or "")
    local expectedType = treatment == "KnoxCure" and "ElixirCraft.KnoxCure"
        or treatment == "AdrenalineStimulant" and "ElixirCraft.StaminaElixir"
        or nil
    if not expectedType or tostring(args.itemType or "") ~= expectedType then
        reject(player, args, "invalid-request")
        return
    end

    local itemId = tostring(args.itemId or "")
    if itemId == "" then
        reject(player, args, "missing-item-id")
        return
    end

    local key = playerKey(player)
    local now = getTimestampMs and getTimestampMs() or 0
    pruneRecentRequests(now)
    if recentRequests[key] and now > 0 and now - recentRequests[key] < REQUEST_WINDOW_MS then
        args.itemKept = true
        reject(player, args, "rate-limited")
        return
    end
    recentRequests[key] = now
    debugLog(string.format("request treatment=%s player=%s",
        treatment, playerKey(player)))

    local ok, reason, detail = ElixirConsumption.ValidateTreatment(player, treatment)
    if not ok then
        args.itemKept = true
        reject(player, args, reason, detail)
        return
    end


    local container, item = findItem(player:getInventory(), itemId, expectedType)
    if not item then
        reject(player, args, "item-not-found")
        return
    end

    container:Remove(item)
    local applied, applyOk, applyReason, applyDetail = pcall(
        ElixirConsumption.ApplyTreatment, player, treatment)
    if applied then
        ok, reason, detail = applyOk, applyReason, applyDetail
    else
        ok, reason, detail = false, "treatment-error", nil
        print("[ElixirCraftB42] ERROR treatment transaction failed: " .. tostring(applyOk))
    end
    if not ok then
        local returned = shouldReturnRejected(treatment) and restoreItem(container, item)
        args.itemKept = returned
        reject(player, args, reason, detail)
        return
    end

    sendServerCommand(player, MODULE, "TreatmentApplied", {
        treatment = treatment,
        provider = detail,
    })

    local announcement = tonumber(setting("UsageAnnouncement", 2)) or 2
    if announcement == 4 then
        sendServerCommand(MODULE, "UsageAnnouncement", {
            username = player:getUsername() or "unknown",
            treatment = treatment,
        })
    elseif announcement == 3 then
        sendServerCommand(player, MODULE, "UsageAnnouncement", {
            username = player:getUsername() or "unknown",
            treatment = treatment,
        })
    end
end

Events.OnClientCommand.Add(onClientCommand)

local function onPlayerUpdate(player)
    if ElixirConsumption.ProcessPostCrash(player) then
        sendServerCommand(player, MODULE, "StimulantCrash", {})
    end
end

Events.OnPlayerUpdate.Add(onPlayerUpdate)
