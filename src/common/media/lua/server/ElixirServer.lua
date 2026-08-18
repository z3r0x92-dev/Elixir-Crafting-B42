require "ElixirConsumption"

local MODULE = "ElixirCraftB42"
local PROTOCOL_VERSION = 3
local recentRequests = {}
local compatibleClients = {}
local lastAnnouncements = {}
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

local function handleHello(player, args)
    local key = playerKey(player)
    local compatible = tonumber(args and args.protocol) == PROTOCOL_VERSION
    compatibleClients[key] = compatible
    sendServerCommand(player, MODULE,
        compatible and "VersionAccepted" or "VersionMismatch",
        { protocol = PROTOCOL_VERSION })
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
    local added = pcall(function() container:AddItem(item) end)
    if not added then return false end
    local _, restored = findItem(container, tostring(item:getID()), item:getFullType())
    return restored ~= nil
        and (not item.getContainer or item:getContainer() == container)
end

local function onClientCommand(module, command, player, args)
    if module ~= MODULE or not player then return end
    args = args or {}
    if command == "Hello" then
        handleHello(player, args)
        return
    end
    if command ~= "UseTreatment" then return end

    if compatibleClients[playerKey(player)] ~= true
        or tonumber(args.protocol) ~= PROTOCOL_VERSION then
        args.itemKept = true
        reject(player, args, "protocol-mismatch")
        sendServerCommand(player, MODULE, "VersionMismatch", { protocol = PROTOCOL_VERSION })
        return
    end
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
        if shouldReturnRejected(treatment) and not returned then
            print(string.format(
                "[ElixirCraftB42] ERROR failed to restore rejected item id=%s type=%s player=%s",
                itemId, expectedType, playerKey(player)))
        end
        args.itemKept = returned
        reject(player, args, reason, detail)
        return
    end

    sendServerCommand(player, MODULE, "TreatmentApplied", {
        treatment = treatment,
        provider = reason,
        overdose = type(detail) == "table" and detail.overdose == true,
        overdoseHealthLoss = type(detail) == "table" and detail.overdoseHealthLoss or 0,
        healthAfter = type(detail) == "table" and detail.healthAfter or nil,
        scope = type(detail) == "table" and detail.scope or nil,
        enduranceAfter = type(detail) == "table" and detail.enduranceAfter or nil,
        fatigueAfter = type(detail) == "table" and detail.fatigueAfter or nil,
        panicAfter = type(detail) == "table" and detail.panicAfter or nil,
        stressAfter = type(detail) == "table" and detail.stressAfter or nil,
        thirstAfter = type(detail) == "table" and detail.thirstAfter or nil,
    })

    local announcement = tonumber(setting("UsageAnnouncement", 2)) or 2
    local announcementNow = getTimestampMs and getTimestampMs() or 0
    local announcementCooldown = math.max(0,
        tonumber(setting("UsageAnnouncementCooldownSeconds", 5.0)) or 5.0) * 1000
    local announcementKey = playerKey(player)
    local canAnnounce = announcementNow <= 0 or not lastAnnouncements[announcementKey]
        or announcementNow - lastAnnouncements[announcementKey] >= announcementCooldown
    if canAnnounce and announcement == 4 then
        sendServerCommand(MODULE, "UsageAnnouncement", {
            username = player:getUsername() or "unknown",
            treatment = treatment,
        })
        lastAnnouncements[announcementKey] = announcementNow
    elseif canAnnounce and announcement == 3 then
        sendServerCommand(player, MODULE, "UsageAnnouncement", {
            username = player:getUsername() or "unknown",
            treatment = treatment,
        })
        lastAnnouncements[announcementKey] = announcementNow
    end
end

Events.OnClientCommand.Add(onClientCommand)

local function onPlayerUpdate(player)
    if not ElixirConsumption.ProcessPostCrash then return end
    local crashed, fatigue = ElixirConsumption.ProcessPostCrash(player)
    if crashed then
        sendServerCommand(player, MODULE, "StimulantCrash", { fatigue = fatigue })
    end
end

Events.OnPlayerUpdate.Add(onPlayerUpdate)
