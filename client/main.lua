local QBCore = nil
local ESX = nil

if GetResourceState('qb-core') == 'started' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif GetResourceState('es_extended') == 'started' then
    ESX = exports['es_extended']:getSharedObject()
end

local L = Config.Locales[Config.Locale] or Config.Locales.en
local editing = false
local originalCoords = nil
local originalHeading = nil
local capturedEmote = nil
local originalAlpha = 255
local lastSync = 0
local lastSentX, lastSentY, lastSentZ, lastSentH
local sweepHandle = nil
local sweepFromX, sweepFromY, sweepFromZ = nil, nil, nil
local sweepNextAt = 0
local blockNx, blockNy, blockNz = nil, nil, nil
local blockUntil = 0
local remoteEdits = {}

local controls = {
    w = 32,
    s = 33,
    a = 34,
    d = 35,
    q = 44,
    e = 38,
    pageUp = 10,
    pageDown = 11,
    enter = 191,
    backspace = 194,
    escape = 200,
    shift = 21,
    ctrl = 36,
}

local disabledControls = {
    10, 11, 21, 22, 24, 25, 30, 31, 32, 33, 34, 35, 36, 38, 44, 45, 68, 69, 70, 92, 140, 141, 142, 191, 194, 200, 257, 263, 264,
}

local function notify(message, notifyType)
    if Config.UseNovaUI and GetResourceState('nova-ui') == 'started' then
        exports['nova-ui']:Notify(message, notifyType)
        return
    end
    if Config.Notify == 'ox' and GetResourceState('ox_lib') == 'started' then
        exports.ox_lib:notify({ description = message, type = notifyType })
        return
    end
    
    if QBCore then
        TriggerEvent('QBCore:Notify', message, notifyType or 'primary')
    elseif ESX then
        ESX.ShowNotification(message, notifyType or 'info')
    else
        SetNotificationTextEntry("STRING")
        AddTextComponentString(message)
        DrawNotification(false, false)
    end
end

-- nova-ui varsa TextUI ile yardim metni (ZERO overhead). Yoksa eski 2D draw fallback.
local function useNovaUI()
    return GetResourceState('nova-ui') == 'started'
end
local function showHelpUI()
    if not Config.DrawHelp then return end
    if useNovaUI() then
        exports['nova-ui']:ShowTextUI({ text = L.help, position = 'top-center' })
    end
end
local function hideHelpUI()
    if useNovaUI() then
        pcall(function() exports['nova-ui']:HideTextUI() end)
    end
end
local function drawHelpText()
    -- nova-ui varsa burada hicbir sey cizme (TextUI zaten gosteriyor)
    if useNovaUI() or not Config.DrawHelp then return end
    SetTextFont(4)
    SetTextScale(0.0, 0.36)
    SetTextColour(255, 255, 255, 230)
    SetTextOutline()
    SetTextCentre(false)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(L.help)
    EndTextCommandDisplayText(Config.HelpPosition.x, Config.HelpPosition.y)
end

-- 60 fps keeps today's step size. A hitch cannot take a step larger than 50 ms.
local function frameScale()
    local frame = GetFrameTime()
    if type(frame) ~= 'number' or frame ~= frame or frame <= 0.0 then return 1.0 end
    if frame > 0.05 then frame = 0.05 end
    return frame * 60.0
end

local function getStep(scale)
    local step = Config.MoveStep

    if IsDisabledControlPressed(0, controls.shift) then
        step = step * Config.FastMultiplier
    elseif IsDisabledControlPressed(0, controls.ctrl) then
        step = step * Config.SlowMultiplier
    end

    return step * scale
end

local function withinLimit(origin, dest)
    if not Config.LimitMovement or not origin then return true end
    local dx = dest.x - origin.x
    local dy = dest.y - origin.y
    if math.sqrt(dx * dx + dy * dy) > (Config.MaxDistance or 5.0) then return false end
    if math.abs(dest.z - origin.z) > (Config.MaxHeight or 3.5) then return false end
    return true
end

local function hasMoved(x1, y1, z1, x2, y2, z2)
    local dx = x2 - x1
    local dy = y2 - y1
    local dz = z2 - z1
    return (dx * dx + dy * dy + dz * dz) > 1.0e-8
end

-- Keyboard diagonals on the digital keys drop an axis. The analog axes keep both.
local function stickAxis(value)
    if value > 0.4 then return 1.0 end
    if value < -0.4 then return -1.0 end
    if value > -0.12 and value < 0.12 then return 0.0 end
    return value
end

local function clearSweep()
    sweepHandle = nil
    sweepFromX, sweepFromY, sweepFromZ = nil, nil, nil
    blockNx, blockNy, blockNz = nil, nil, nil
end

local function deflect(x, y, z, fromX, fromY, fromZ)
    if not blockNx or GetGameTimer() > blockUntil then
        return x, y, z
    end
    local dx = x - fromX
    local dy = y - fromY
    local dz = z - fromZ
    local dot = dx * blockNx + dy * blockNy + dz * blockNz
    if dot < -0.0001 then
        return fromX + (dx - blockNx * dot), fromY + (dy - blockNy * dot), fromZ + (dz - blockNz * dot)
    end
    return x, y, z
end

-- One async probe in flight. A hit removes only the axis that entered the surface.
local function pollSweep(ped)
    if not sweepHandle then return end
    local status, hit, _, normal = GetShapeTestResult(sweepHandle)
    if status == 1 then return end
    local fromX, fromY, fromZ = sweepFromX, sweepFromY, sweepFromZ
    sweepHandle = nil
    sweepFromX, sweepFromY, sweepFromZ = nil, nil, nil
    if hit ~= 1 or not normal or not fromX then
        blockNx, blockNy, blockNz = nil, nil, nil
        return
    end

    local nx, ny, nz = normal.x + 0.0, normal.y + 0.0, normal.z + 0.0
    local nlen = nx * nx + ny * ny + nz * nz
    if nlen < 0.25 then
        SetEntityCoordsNoOffset(ped, fromX, fromY, fromZ, false, false, false)
        blockNx, blockNy, blockNz = nil, nil, nil
        return
    end

    blockNx, blockNy, blockNz = nx, ny, nz
    blockUntil = GetGameTimer() + 180
    local coords = GetEntityCoords(ped)
    local sx, sy, sz = deflect(coords.x, coords.y, coords.z, fromX, fromY, fromZ)
    if hasMoved(coords.x, coords.y, coords.z, sx, sy, sz) then
        if withinLimit(originalCoords, vector3(sx, sy, sz)) then
            SetEntityCoordsNoOffset(ped, sx, sy, sz, false, false, false)
        else
            SetEntityCoordsNoOffset(ped, fromX, fromY, fromZ, false, false, false)
        end
    end
end

local function queueSweep(ped, x1, y1, z1, x2, y2, z2)
    if not Config.CollisionCheck or sweepHandle then return end
    local now = GetGameTimer()
    if now < sweepNextAt then return end
    sweepFromX, sweepFromY, sweepFromZ = x1, y1, z1
    sweepHandle = StartShapeTestLosProbe(x1, y1, z1 + 0.4, x2, y2, z2 + 0.4, 17, ped, 7)
    sweepNextAt = now + 50
end

local function poseChanged(x, y, z, h)
    if lastSentX == nil then return true end
    if math.abs(x - lastSentX) > 0.0005 or math.abs(y - lastSentY) > 0.0005 or math.abs(z - lastSentZ) > 0.0005 then
        return true
    end
    local dh = math.abs(h - lastSentH) % 360.0
    if dh > 180.0 then dh = 360.0 - dh end
    return dh > 0.05
end

local function getForwardRight(heading)
    local radians = math.rad(heading)
    local forward = vector3(-math.sin(radians), math.cos(radians), 0.0)
    local right = vector3(math.cos(radians), math.sin(radians), 0.0)

    return forward, right
end

local function getCurrentRpEmote()
    if not Config.ReplayRpEmote or GetResourceState('rpemotes') ~= 'started' then
        return nil
    end

    local ok, emoteName = pcall(function()
        return exports['rpemotes']:IsPlayerInAnim()
    end)

    if ok and emoteName then
        return emoteName
    end

    return nil
end

local function replayCapturedEmote()
    if not capturedEmote or GetResourceState('rpemotes') ~= 'started' then
        return
    end

    local emoteName = capturedEmote

    SetTimeout(100, function()
        exports['rpemotes']:EmoteCommandStart(emoteName)
    end)
end

local function restoreAlpha(ped)
    if originalAlpha and originalAlpha < 255 then
        SetEntityAlpha(ped, originalAlpha, false)
        return
    end

    ResetEntityAlpha(ped)
end

local function stopEditing(save)
    local ped = PlayerPedId()

    if not save and originalCoords and originalHeading then
        SetEntityCoordsNoOffset(ped, originalCoords.x, originalCoords.y, originalCoords.z, true, true, false)
        SetEntityHeading(ped, originalHeading)
    end

    if Config.FreezeWhileEditing then
        FreezeEntityPosition(ped, false)
    end

    restoreAlpha(ped)

    editing = false
    originalCoords = nil
    originalHeading = nil
    originalAlpha = nil
    lastSentX = nil
    clearSweep()

    replayCapturedEmote()
    capturedEmote = nil

    if Config.NetworkSync then
        TriggerServerEvent('nova-animpos:server:syncStop')
    end

    hideHelpUI()
    notify(save and L.saved or L.cancelled, save and 'success' or 'error')
end

local function startEditing()
    local ped = PlayerPedId()

    if IsPedInAnyVehicle(ped, false) then
        notify(L.vehicle, 'error')
        return
    end

    editing = true
    lastSentX = nil
    clearSweep()
    originalCoords = GetEntityCoords(ped)
    originalHeading = GetEntityHeading(ped)
    originalAlpha = GetEntityAlpha(ped)
    capturedEmote = getCurrentRpEmote()

    if Config.FreezeWhileEditing then
        FreezeEntityPosition(ped, true)
    end

    SetEntityAlpha(ped, Config.EditAlpha, false)

    showHelpUI()
    notify(L.started, 'primary')
    if Config.NetworkSync then
        TriggerServerEvent('nova-animpos:server:begin', originalCoords.x, originalCoords.y, originalCoords.z)
    end

    if not capturedEmote then
        notify(L.noAnim, 'primary')
    end
end

local function toggleEditing()
    if editing then
        stopEditing(true)
        return
    end

    startEditing()
end

RegisterCommand(Config.Command, toggleEditing, false)

CreateThread(function()
    TriggerEvent('chat:addSuggestion', '/' .. Config.Command, L.suggestion)
end)

CreateThread(function()
    while true do
        if not editing then
            Wait(500)
        else
            Wait(0)

            local ped = PlayerPedId()

            for _, control in ipairs(disabledControls) do
                DisableControlAction(0, control, true)
            end

            if Config.CollisionCheck then
                pollSweep(ped)
            end

            local coords = GetEntityCoords(ped)
            local fromX, fromY, fromZ = coords.x, coords.y, coords.z
            local heading = GetEntityHeading(ped)
            local scale = frameScale()
            local step = getStep(scale)
            local heightStep = Config.HeightStep * scale
            local rotateStep = Config.RotateStep * scale
            local forward, right = getForwardRight(heading)
            local rightAmount = stickAxis(GetDisabledControlNormal(0, 30))
            local forwardAmount = stickAxis(-GetDisabledControlNormal(0, 31))
            if forwardAmount == 0.0 and rightAmount == 0.0 then
                if IsDisabledControlPressed(0, controls.w) then forwardAmount = 1.0 end
                if IsDisabledControlPressed(0, controls.s) then forwardAmount = forwardAmount - 1.0 end
                if IsDisabledControlPressed(0, controls.d) then rightAmount = 1.0 end
                if IsDisabledControlPressed(0, controls.a) then rightAmount = rightAmount - 1.0 end
            end
            local upAmount = 0.0
            if IsDisabledControlPressed(0, controls.pageUp) then upAmount = 1.0 end
            if IsDisabledControlPressed(0, controls.pageDown) then upAmount = upAmount - 1.0 end
            local headingMoved = false

            if IsDisabledControlPressed(0, controls.q) then
                heading = heading + rotateStep
                headingMoved = true
            end

            if IsDisabledControlPressed(0, controls.e) then
                heading = heading - rotateStep
                headingMoved = true
            end

            local targetX, targetY, targetZ = fromX, fromY, fromZ
            if forwardAmount ~= 0.0 or rightAmount ~= 0.0 then
                local hx = fromX + forward.x * step * forwardAmount + right.x * step * rightAmount
                local hy = fromY + forward.y * step * forwardAmount + right.y * step * rightAmount
                if withinLimit(originalCoords, vector3(hx, hy, fromZ)) then
                    targetX, targetY = hx, hy
                end
            end
            if upAmount ~= 0.0 then
                local hz = targetZ + heightStep * upAmount
                if withinLimit(originalCoords, vector3(targetX, targetY, hz)) then
                    targetZ = hz
                end
            end
            if Config.CollisionCheck then
                targetX, targetY, targetZ = deflect(targetX, targetY, targetZ, fromX, fromY, fromZ)
                if not withinLimit(originalCoords, vector3(targetX, targetY, targetZ)) then
                    targetX, targetY, targetZ = fromX, fromY, fromZ
                end
            end

            local positionChanged = hasMoved(fromX, fromY, fromZ, targetX, targetY, targetZ)
            if positionChanged then
                SetEntityCoordsNoOffset(ped, targetX, targetY, targetZ, false, false, false)
                queueSweep(ped, fromX, fromY, fromZ, targetX, targetY, targetZ)
                coords = vector3(targetX, targetY, targetZ)
            end
            if headingMoved then
                SetEntityHeading(ped, heading % 360.0)
            end

            if positionChanged or headingMoved then
                local sentHeading = heading % 360.0
                if Config.NetworkSync and poseChanged(coords.x, coords.y, coords.z, sentHeading) and (GetGameTimer() - lastSync) >= Config.SyncInterval then
                    lastSync = GetGameTimer()
                    lastSentX, lastSentY, lastSentZ, lastSentH = coords.x, coords.y, coords.z, sentHeading
                    TriggerServerEvent('nova-animpos:server:sync', coords.x, coords.y, coords.z, sentHeading)
                end
            end

            if IsDisabledControlJustPressed(0, controls.enter) then
                stopEditing(true)
            elseif IsDisabledControlJustPressed(0, controls.backspace) or IsDisabledControlJustPressed(0, controls.escape) then
                stopEditing(false)
            end

            drawHelpText()
        end
    end
end)

-- Practice other players' edit move live (overcomes anchor issue)
RegisterNetEvent('nova-animpos:client:remoteUpdate', function(serverId, x, y, z, h)
    if serverId == GetPlayerServerId(PlayerId()) then return end
    remoteEdits[serverId] = { x = x, y = y, z = z, h = h, expires = GetGameTimer() + 1000 }
end)

RegisterNetEvent('nova-animpos:client:remoteStop', function(serverId)
    remoteEdits[serverId] = nil
end)

CreateThread(function()
    while true do
        local active = false

        for serverId, t in pairs(remoteEdits) do
            if GetGameTimer() > t.expires then
                remoteEdits[serverId] = nil
            else
                active = true
                local pid = GetPlayerFromServerId(serverId)
                if pid ~= -1 then
                    local ped = GetPlayerPed(pid)
                    if ped and ped ~= 0 and DoesEntityExist(ped) then
                        SetEntityCoordsNoOffset(ped, t.x, t.y, t.z, false, false, false)
                        SetEntityHeading(ped, t.h)
                    end
                end
            end
        end

        Wait(active and 0 or 500)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() or not editing then return end

    local ped = PlayerPedId()
    if Config.FreezeWhileEditing then
        FreezeEntityPosition(ped, false)
    end

    restoreAlpha(ped)
end)
