-- Relays one player's edit to nearby players. No session means no broadcast.

local sessions = {}
local lastSyncAt = {}
local lastStopAt = {}

local function finite(n)
    return type(n) == 'number' and n == n and n > -math.huge and n < math.huge
end

-- Drops broken coordinates. This is not the gameplay distance limit.
local function inWorld(x, y, z)
    return math.abs(x) <= 100000.0 and math.abs(y) <= 100000.0 and z >= -5000.0 and z <= 20000.0
end

local function tooFar(origin, x, y, z)
    if not Config.LimitMovement then return false end
    local dx = x - origin.x
    local dy = y - origin.y
    local slack = 0.05
    if math.sqrt(dx * dx + dy * dy) > (Config.MaxDistance or 5.0) + slack then return true end
    if math.abs(z - origin.z) > (Config.MaxHeight or 3.5) + slack then return true end
    return false
end

local function syncGap()
    local interval = tonumber(Config.SyncInterval) or 90
    if interval < 1 then interval = 90 end
    local gap = interval - 25
    if gap < 45 then gap = 45 end
    return gap
end

local function broadcast(src, x, y, z, h)
    local bucket = GetPlayerRoutingBucket(src)
    local reach = 600.0 * 600.0
    for _, id in ipairs(GetPlayers()) do
        local target = tonumber(id)
        if target and target ~= src and GetPlayerRoutingBucket(target) == bucket then
            local ped = GetPlayerPed(target)
            if ped and ped ~= 0 then
                local coords = GetEntityCoords(ped)
                local dx = coords.x - x
                local dy = coords.y - y
                local dz = coords.z - z
                if (dx * dx + dy * dy + dz * dz) <= reach then
                    TriggerClientEvent('nova-animpos:client:remoteUpdate', target, src, x, y, z, h)
                end
            end
        end
    end
end

RegisterNetEvent('nova-animpos:server:begin', function(x, y, z)
    local src = source
    if sessions[src] then return end

    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end
    if GetVehiclePedIsIn(ped, false) ~= 0 then return end

    local pedCoords = GetEntityCoords(ped)
    if not finite(pedCoords.x) or not finite(pedCoords.y) or not finite(pedCoords.z) then return end

    local originX, originY, originZ = pedCoords.x, pedCoords.y, pedCoords.z
    if finite(x) and finite(y) and finite(z) and inWorld(x, y, z) then
        local dx = x - pedCoords.x
        local dy = y - pedCoords.y
        local dz = z - pedCoords.z
        -- A matching client start covers replication delay. A far start is ignored.
        if (dx * dx + dy * dy + dz * dz) <= (2.0 * 2.0) then
            originX, originY, originZ = x, y, z
        end
    end

    sessions[src] = { x = originX, y = originY, z = originZ }
end)

RegisterNetEvent('nova-animpos:server:sync', function(x, y, z, h)
    local src = source
    local origin = sessions[src]
    if not origin then return end
    if not finite(x) or not finite(y) or not finite(z) or not inWorld(x, y, z) then return end

    h = tonumber(h)
    if not finite(h) or math.abs(h) > 360000.0 then return end

    local now = GetGameTimer()
    local previous = lastSyncAt[src]
    if previous and (now - previous) < syncGap() then return end
    if tooFar(origin, x, y, z) then return end

    lastSyncAt[src] = now
    h = h % 360.0
    if h < 0.0 then h = h + 360.0 end
    broadcast(src, x + 0.0, y + 0.0, z + 0.0, h + 0.0)
end)

RegisterNetEvent('nova-animpos:server:syncStop', function()
    local src = source
    if not sessions[src] then return end
    sessions[src] = nil
    lastSyncAt[src] = nil

    local now = GetGameTimer()
    if lastStopAt[src] and (now - lastStopAt[src]) < 200 then return end
    lastStopAt[src] = now
    TriggerClientEvent('nova-animpos:client:remoteStop', -1, src)
end)

AddEventHandler('playerDropped', function()
    local src = source
    sessions[src] = nil
    lastSyncAt[src] = nil
    lastStopAt[src] = nil
end)

local githubRepo = 'msaber07/nova-animpos'

CreateThread(function()
    local localFile = LoadResourceFile(GetCurrentResourceName(), 'version.json')
    if not localFile then return end

    local localData = json.decode(localFile)
    if not localData or not localData.version then return end
    local currentVersion = localData.version

    PerformHttpRequest('https://raw.githubusercontent.com/' .. githubRepo .. '/main/version.json', function(statusCode, responseText)
        if statusCode == 200 and responseText then
            local data = json.decode(responseText)
            if data and data.version and data.version ~= currentVersion then
                print(('^3An update is available for %s (current version: %s)^7'):format(GetCurrentResourceName(), currentVersion))
                print(('^5https://github.com/%s/releases/tag/v%s^7'):format(githubRepo, data.version))
            end
        end
    end, 'GET', '', '')
end)
