require "ElixirConsumption"

local MODULE = "ElixirCraftB42"
local recentRequests = {}

local function playerKey(player)
    return tostring(player:getOnlineID()) .. ":" .. tostring(player:getUsername() or "unknown")
end

local function refundIfMissing(player, itemType, expectedCount)
    local inventory = player and player:getInventory()
    if not inventory or not itemType then return end
    local actual = inventory.getItemCountRecurse and inventory:getItemCountRecurse(itemType) or 0
    local expected = math.max(0, tonumber(expectedCount) or 0)
    if actual <= expected then inventory:AddItem(itemType) end
end

local function reject(player, args, reason, remaining)
    refundIfMissing(player, args.itemType, args.countAfter)
    sendServerCommand(player, MODULE, "TreatmentRejected", {
        treatment = args.treatment,
        reason = reason,
        remaining = remaining,
    })
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

    local key = playerKey(player)
    local now = getTimestampMs and getTimestampMs() or 0
    if recentRequests[key] and now > 0 and now - recentRequests[key] < 750 then
        reject(player, args, "rate-limited")
        return
    end
    recentRequests[key] = now

    local ok, reason, detail = ElixirConsumption.ApplyTreatment(player, treatment)
    if not ok then
        reject(player, args, reason, detail)
        return
    end

    sendServerCommand(player, MODULE, "TreatmentApplied", {
        treatment = treatment,
        provider = detail,
    })
end

Events.OnClientCommand.Add(onClientCommand)
