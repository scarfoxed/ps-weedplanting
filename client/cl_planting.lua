QBCore = exports['qb-core']:GetCoreObject()
PlayerJob = QBCore.Functions.GetPlayerData().job
local seedUsed = false

--- Classes

---@class vector4
---@field x number The X coords
---@field y number The Y coords
---@field z number The Z height
---@field w number The heading

---@class vector3
---@field x number The X coords
---@field y number The Y coords
---@field z number The Z height

---@class vector2
---@field x number The X coords
---@field y number The Y coords

--- Turn rotation to direction
---@param rot number the rotation number
---@return vector3 the direction vector
local RotationToDirection = function(rot)
    local rotZ = math.rad(rot.z)
    local rotX = math.rad(rot.x)
    local cosOfRotX = math.abs(math.cos(rotX))
    return vector3(-math.sin(rotZ) * cosOfRotX, math.cos(rotZ) * cosOfRotX, math.sin(rotX))
end

-- Utils

--- Raycast the camera
---@param dist number Max distance for raycast
---@return number, vector3, number, string The hit result, the end position, the entity hit, the surface normal 
local RayCastCamera = function(dist)
    local camRot = GetGameplayCamRot()
    local camPos = GetGameplayCamCoord()
    local dir = RotationToDirection(camRot)
    local dest = camPos + (dir * dist)
    local ray = StartShapeTestRay(camPos, dest, 17, -1, 0)
    local _, hit, endPos, surfaceNormal, entityHit = GetShapeTestResult(ray)
    if hit == 0 then
        endPos = dest
    end
    return hit, endPos, entityHit, surfaceNormal
end

--- Notify the player
---@param text string The text to show
---@param type string The type of notification
function Notify(text, type)
    lib.notify({
        title = 'Weed planting',
        description = text,
        type = type
    })
end
--- Check if the player is a police officer
---@return boolean True if the player is a police officer
local function IsPolice()
    return PlayerJob.type == 'leo' and PlayerJob.onduty
end

--- Player load, unload and update handlers

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerJob = QBCore.Functions.GetPlayerData().job
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerJob = {}
    clearWeedRun()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then
        return
    end
    clearWeedRun()
end)

-- Functions for menus

--- Clear a plant
---@param entity number The entity to clear
local function ClearPlant(entity)
    local netId = NetworkGetNetworkIdFromEntity(entity)
    TaskTurnPedToFaceEntity(cache.ped, entity, 1.0)
    Wait(1500)

    lib.requestAnimDict('amb@medic@standing@kneel@base')
    lib.requestAnimDict('anim@gangops@facility@servers@bodysearch@')

    TaskPlayAnim(cache.ped, 'amb@medic@standing@kneel@base', 'base', 8.0, 8.0, -1, 1, 0, false, false, false)
    TaskPlayAnim(cache.ped, 'anim@gangops@facility@servers@bodysearch@', 'player_search', 8.0, 8.0, -1, 48, 0, false,
        false, false)

    QBCore.Functions.Progressbar('clear_plant', _U('clear_plant'), 8500, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true
    }, {}, {}, {}, function()
        TriggerServerEvent('ps-weedplanting:server:ClearPlant', netId)
        ClearPedTasks(cache.ped)
        RemoveAnimDict('amb@medic@standing@kneel@base')
        RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
    end, function()
        Notify(_U('canceled'), 'error')
        ClearPedTasks(cache.ped)
        RemoveAnimDict('amb@medic@standing@kneel@base')
        RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
    end)
end

--- Harvest a plant
---@param entity number The entity to plant
local function HarvestPlant(entity)
    local netId = NetworkGetNetworkIdFromEntity(entity)
    TaskTurnPedToFaceEntity(cache.ped, entity, 1.0)
    Wait(1500)

    lib.requestAnimDict('amb@medic@standing@kneel@base')
    lib.requestAnimDict('anim@gangops@facility@servers@bodysearch@')

    TaskPlayAnim(cache.ped, 'amb@medic@standing@kneel@base', 'base', 8.0, 8.0, -1, 1, 0, false, false, false)
    TaskPlayAnim(cache.ped, 'anim@gangops@facility@servers@bodysearch@', 'player_search', 8.0, 8.0, -1, 48, 0, false,
        false, false)

    QBCore.Functions.Progressbar('harvest_plant', _U('harvesting_plant'), 8500, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true
    }, {}, {}, {}, function()
        TriggerServerEvent('ps-weedplanting:server:HarvestPlant', netId)
        ClearPedTasks(cache.ped)
        RemoveAnimDict('amb@medic@standing@kneel@base')
        RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
    end, function()
        Notify(_U('canceled'), 'error')
        ClearPedTasks(cache.ped)
        RemoveAnimDict('amb@medic@standing@kneel@base')
        RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
    end)
end

---Destroy a seed
---@param entity number The entity to destroy
local function PoliceDestroy(entity)
    local netId = NetworkGetNetworkIdFromEntity(entity)
    TaskTurnPedToFaceEntity(cache.ped, entity, 1.0)
    Wait(500)
    ClearPedTasks(cache.ped)
    TriggerServerEvent('ps-weedplanting:server:PoliceDestroy', netId)
end

--- Give water to a plant
---@param entity number The entity to give water to
local function GiveWater(entity)
    if QBCore.Functions.HasItem(Shared.WaterItem, 1) then
        local netId = NetworkGetNetworkIdFromEntity(entity)
        local coords = GetEntityCoords(cache.ped)

        local model = joaat('prop_wateringcan')

        TaskTurnPedToFaceEntity(cache.ped, entity, 1.0)
        Wait(1500)

        lib.requestModel(model)
        lib.requestNamedPtfxAsset('core')

        SetPtfxAssetNextCall('core')
        local created_object = CreateObject(model, coords.x, coords.y, coords.z, true, true, true)
        AttachEntityToEntity(created_object, cache.ped, GetPedBoneIndex(cache.ped, 28422), 0.4, 0.1, 0.0, 90.0, 180.0,
            0.0, true, true, false, true, 1, true)
        local effect = StartParticleFxLoopedOnEntity('ent_sht_water', created_object, 0.35, 0.0, 0.25, 0.0, 0.0, 0.0,
            2.0, false, false, false)
        QBCore.Functions.Progressbar('weedplanting_water', _U('watering_plant'), 6000, false, false, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true
        }, {
            animDict = 'weapon@w_sp_jerrycan',
            anim = 'fire',
            flags = 1
        }, {}, {}, function()
            TriggerServerEvent('ps-weedplanting:server:GiveWater', netId)
            ClearPedTasks(cache.ped)
            DeleteEntity(created_object)
            StopParticleFxLooped(effect, 0)
        end, function()
            ClearPedTasks(cache.ped)
            DeleteEntity(created_object)
            StopParticleFxLooped(effect, 0)
            Notify(_U('canceled'), 'error')
        end)
    else
        Notify(_U('missing_water'), 'error')
    end
end

--- Give fertilizer to a plant
---@param entity number The entity to give fertilizer to
local function GiveFertilizer(entity)
    if QBCore.Functions.HasItem(Shared.FertilizerItem, 1) then
        local netId = NetworkGetNetworkIdFromEntity(entity)
        local coords = GetEntityCoords(cache.ped)
        local model = joaat('w_am_jerrycan_sf')
        TaskTurnPedToFaceEntity(cache.ped, entity, 1.0)
        Wait(1500)

        lib.requestModel(model)

        local created_object = CreateObject(model, coords.x, coords.y, coords.z, true, true, true)
        AttachEntityToEntity(created_object, cache.ped, GetPedBoneIndex(cache.ped, 28422), 0.3, 0.1, 0.0, 90.0, 180.0,
            0.0, true, true, false, true, 1, true)
        QBCore.Functions.Progressbar('weedplanting_fertilizer', _U('fertilizing_plant'), 6000, false, false, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true
        }, {
            animDict = 'weapon@w_sp_jerrycan',
            anim = 'fire',
            flags = 1
        }, {}, {}, function()
            TriggerServerEvent('ps-weedplanting:server:GiveFertilizer', netId)
            ClearPedTasks(cache.ped)
            DeleteEntity(created_object)
        end, function()
            ClearPedTasks(cache.ped)
            DeleteEntity(created_object)
            Notify(_U('canceled'), 'error')
        end)
    else
        Notify(_U('missing_fertilizer'), 'error')
    end
end

---Add male seed to a plant
---@param entity number The entity to add the seed to
local function AddMaleSeed(entity)
    if QBCore.Functions.HasItem(Shared.MaleSeed, 1) then
        local netId = NetworkGetNetworkIdFromEntity(entity)
        TaskTurnPedToFaceEntity(cache.ped, entity, 1.0)
        Wait(1500)

        lib.requestAnimDict('amb@medic@standing@kneel@base')
        lib.requestAnimDict('anim@gangops@facility@servers@bodysearch@')

        TaskPlayAnim(cache.ped, 'amb@medic@standing@kneel@base', 'base', 8.0, 8.0, -1, 1, 0, false, false, false)
        TaskPlayAnim(cache.ped, 'anim@gangops@facility@servers@bodysearch@', 'player_search', 8.0, 8.0, -1, 48, 0,
            false, false, false)

        QBCore.Functions.Progressbar('add_maleseed', _U('adding_male_seed'), 8500, false, true, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true
        }, {}, {}, {}, function()
            TriggerServerEvent('ps-weedplanting:server:AddMaleSeed', netId)
            ClearPedTasks(cache.ped)
            RemoveAnimDict('amb@medic@standing@kneel@base')
            RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
        end, function()
            Notify(_U('canceled'), 'error')
            ClearPedTasks(cache.ped)
            RemoveAnimDict('amb@medic@standing@kneel@base')
            RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
        end)
    else
        Notify(_U('missing_mseed'), 'error')
    end
end

--- Events
RegisterNetEvent('ps-weedplanting:client:UseWeedSeed', function()
    if cache.vehicle then
        return
    end
    if seedUsed then
        return
    end
    seedUsed = true
    local ModelHash = Shared.WeedProps[1]

    lib.requestModel(ModelHash)

    lib.showTextUI(_U('place_or_cancel'))

    local hit, dest, _, _ = RayCastCamera(Shared.rayCastingDistance)
    local plant = CreateObject(ModelHash, dest.x, dest.y, dest.z + Shared.ObjectZOffset, false, false, false)
    SetEntityCollision(plant, false, false)
    SetEntityAlpha(plant, 150, true)

    local planted = false
    while not planted do
        Wait(0)
        hit, dest, _, _ = RayCastCamera(Shared.rayCastingDistance)
        if hit == 1 then
            SetEntityCoords(plant, dest.x, dest.y, dest.z + Shared.ObjectZOffset)

            -- [E] To spawn plant
            if IsControlJustPressed(0, 38) then
                planted = true
                lib.hideTextUI()
                DeleteObject(plant)

                lib.requestAnimDict('amb@medic@standing@kneel@base')
                lib.requestAnimDict('anim@gangops@facility@servers@bodysearch@')

                TaskPlayAnim(cache.ped, 'amb@medic@standing@kneel@base', 'base', 8.0, 8.0, -1, 1, 0, false, false, false)
                TaskPlayAnim(cache.ped, 'anim@gangops@facility@servers@bodysearch@', 'player_search', 8.0, 8.0, -1, 48,
                    0, false, false, false)
                QBCore.Functions.Progressbar('spawn_plant', _U('place_sapling'), 2000, false, true, {
                    disableMovement = true,
                    disableCarMovement = false,
                    disableMouse = false,
                    disableCombat = true
                }, {}, {}, {}, function()
                    TriggerServerEvent('ps-weedplanting:server:CreateNewPlant', dest)
                    planted = false
                    seedUsed = false
                    ClearPedTasks(cache.ped)
                    RemoveAnimDict('amb@medic@standing@kneel@base')
                    RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
                end, function()
                    Notify(_U('canceled'), 'error')
                    planted = false
                    seedUsed = false
                    ClearPedTasks(cache.ped)
                    RemoveAnimDict('amb@medic@standing@kneel@base')
                    RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
                end)
            end

            -- [G] to cancel
            if IsControlJustPressed(0, 47) then
                lib.hideTextUI()
                planted = false
                seedUsed = false
                DeleteObject(plant)
                return
            end
        end
    end
end)

RegisterNetEvent('ps-weedplanting:client:CheckPlant', function(data)
    local netId = NetworkGetNetworkIdFromEntity(data.entity)
    lib.callback('ps-weedplanting:server:GetPlantData', false, function(result)
        if not result then
            return
        end
        if result.health == 0 then -- Destroy plant
            lib.registerContext({
                id = 'destroy_plant_menu',
                title = _U('destroy_plant'),
                options = {{
                    title = _U('clear_plant_header'),
                    description = _U('clear_plant_text'),
                    icon = 'skull-crossbones',
                    onSelect = function()
                        ClearPlant(data.entity)
                    end
                }}
            })
            lib.showContext('destroy_plant_menu')
        elseif result.growth == 100 then -- Harvest
            if IsPolice() then
                lib.registerContext({
                    id = 'police_plant',
                    title = _U('plant_header'),
                    options = {{
                        title = 'Stage: ' .. result.stage .. ' - Health: ' .. result.health,
                        description = _U('ready_for_harvest'),
                        icon = 'scissors',
                        onSelect = function()
                            HarvestPlant(data.entity)
                        end
                    }, {
                        title = _U('destroy_plant'),
                        description = _U('ready_for_harvest'),
                        icon = 'fire',
                        onSelect = function()
                            PoliceDestroy(data.entity)
                        end
                    }}
                })
                lib.showContext('police_plant')
            else
                lib.registerContext({
                    id = 'player_plant',
                    title = _U('plant_header'),
                    options = {{
                        title = 'Stage: ' .. result.stage .. ' - Health: ' .. result.health,
                        description = _U('ready_for_harvest'),
                        icon = 'scissors',
                        onSelect = function()
                            HarvestPlant(data.entity)
                        end
                    }}
                })
                lib.showContext('player_plant')
            end
        elseif result.gender == 'female' then -- Option to add male seed
            if IsPolice() then
                lib.registerContext({
                    id = 'police_plant',
                    title = _U('plant_header'),
                    options = {{
                        title = 'Growth: ' .. result.growth .. '%' .. ' - Stage: ' .. result.stage,
                        description = 'Health: ' .. result.health,
                        icon = 'chart-simple'
                    }, {
                        title = _U('destroy_plant'),
                        description = _U('ready_for_harvest'),
                        icon = 'fire',
                        onSelect = function()
                            PoliceDestroy(data.entity)
                        end
                    }}
                })
                lib.showContext('police_plant')
            else
                lib.registerContext({
                    id = 'player_plant',
                    title = _U('plant_header'),
                    options = {{
                        title = 'Growth: ' .. result.growth .. '%' .. ' - Stage: ' .. result.stage,
                        description = 'Health: ' .. result.health,
                        icon = 'chart-simple'
                    }, {
                        title = 'Water: ' .. result.water .. '%',
                        description = _U('add_water'),
                        icon = 'shower',
                        onSelect = function()
                            GiveWater(data.entity)
                        end
                    }, {
                        title = 'Fertilizer: ' .. result.fertilizer .. '%',
                        description = _U('add_fertilizer'),
                        icon = 'seedling',
                        onSelect = function()
                            GiveFertilizer(data.entity)
                        end
                    }, {
                        title = 'Gender: ' .. result.gender,
                        description = _U('add_mseed'),
                        icon = 'venus',
                        onSelect = function()
                            AddMaleSeed(data.entity)
                        end
                    }}
                })
                lib.showContext('player_plant')
            end
        else -- No option to add male seed
            if IsPolice() then
                lib.registerContext({
                    id = 'police_plant',
                    title = _U('plant_header'),
                    options = {{
                        title = 'Growth: ' .. result.growth .. '%' .. ' - Stage: ' .. result.stage,
                        description = 'Health: ' .. result.health,
                        icon = 'chart-simple'
                    }, {
                        title = _U('destroy_plant'),
                        description = _U('ready_for_harvest'),
                        icon = 'fire',
                        onSelect = function()
                            PoliceDestroy(data.entity)
                        end
                    }}
                })
                lib.showContext('police_plant')
            else
                lib.registerContext({
                    id = 'player_plant',
                    title = _U('plant_header'),
                    options = {{
                        title = 'Growth: ' .. result.growth .. '%' .. ' - Stage: ' .. result.stage,
                        description = 'Health: ' .. result.health,
                        icon = 'chart-simple'
                    }, {
                        title = 'Water: ' .. result.water .. '%',
                        description = _U('add_water'),
                        icon = 'shower',
                        onSelect = function()
                            GiveWater(data.entity)
                        end
                    }, {
                        title = 'Fertilizer: ' .. result.fertilizer .. '%',
                        description = _U('add_fertilizer'),
                        icon = 'seedling',
                        onSelect = function()
                            GiveFertilizer(data.entity)
                        end
                    }, {
                        title = 'Gender: ' .. result.gender,
                        description = _U('add_mseed'),
                        icon = 'mars'
                    }}
                })
                lib.showContext('player_plant')
            end
        end
    end, netId)
end)

RegisterNetEvent('ps-weedplanting:client:FireGoBrrrrrrr', function(coords)
    local pedCoords = GetEntityCoords(cache.ped)
    if #(pedCoords - vector3(coords.x, coords.y, coords.z)) > 300 then
        return
    end

    lib.requestNamedPtfxAsset('core')

    SetPtfxAssetNextCall('core')
    local effect = StartParticleFxLoopedAtCoord('ent_ray_paleto_gas_flames', coords.x, coords.y, coords.z + 0.5, 0.0,
        0.0, 0.0, 0.6, false, false, false, false)
    Wait(Shared.FireTime)
    StopParticleFxLooped(effect, 0)
end)

--- Threads

CreateThread(function()
    exports['qb-target']:AddTargetModel(Shared.WeedProps, {
        options = {{
            type = 'client',
            event = 'ps-weedplanting:client:CheckPlant',
            icon = 'fas fa-cannabis',
            label = _U('check_plant')
        }},
        distance = 1.5
    })
end)
