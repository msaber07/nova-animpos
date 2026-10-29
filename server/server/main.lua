-- Relays location to other players during editing (live sync).
-- It only broadcasts the coordinates from the client; The owner ignores his own package.

local editOrigin = {}

local function tooFar(origin, x, y, z)
    if not Config.LimitMovement or not origin then return false end
    local dx = x - origin.x
    local dy = y - origin.y
    if math.sqrt(dx * dx + dy * dy) > (Config.MaxDistance or 5.0) then return true end
    if math.abs(z - origin.z) > (Config.MaxHeight or 3.5) then return true end
    return false
end

RegisterNetEvent('nova-animpos:server:begin', function(x, y, z)
    local src = source
    if type(x) ~= 'number' or type(y) ~= 'number' or type(z) ~= 'number' then return end
    editOrigin[src] = { x = x, y = y, z = z }
end)

RegisterNetEvent('nova-animpos:server:sync', function(x, y, z, h)
    local src = source
    if type(x) ~= 'number' or type(y) ~= 'number' or type(z) ~= 'number' then return end
    if tooFar(editOrigin[src], x, y, z) then return end
    TriggerClientEvent('nova-animpos:client:remoteUpdate', -1, src, x + 0.0, y + 0.0, z + 0.0, (tonumber(h) or 0.0) + 0.0)
end)

RegisterNetEvent('nova-animpos:server:syncStop', function()
    local src = source
    editOrigin[src] = nil
    TriggerClientEvent('nova-animpos:client:remoteStop', -1, src)
end)

AddEventHandler('playerDropped', function()
    editOrigin[source] = nil
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
