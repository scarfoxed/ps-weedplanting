QBCore = exports['qb-core']:GetCoreObject()
PlayerJob = QBCore.Functions.GetPlayerData().job
local seedUsed = false

--- Functions

local RotationToDirection = function(rot)
    local rotZ = math.rad(rot.z)
    local rotX = math.rad(rot.x)
    local cosOfRotX = math.abs(math.cos(rotX))
    return vector3(-math.sin(rotZ) * cosOfRotX, math.cos(rotZ) * cosOfRotX, math.sin(rotX))
end
  
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
    if resource ~= GetCurrentResourceName() then return end
    clearWeedRun()
end)

-- Functions for menus

local function ClearPlant(entity)
    local netId = NetworkGetNetworkIdFromEntity(entity)
    TaskTurnPedToFaceEntity(cache.ped, entity, 1.0)
    Wait(1500)

    lib.requestAnimDict('amb@medic@standing@kneel@base')
    lib.requestAnimDict('anim@gangops@facility@servers@bodysearch@')

    TaskPlayAnim(cache.ped, 'amb@medic@standing@kneel@base', 'base', 8.0, 8.0, -1, 1, 0, false, false, false)
    TaskPlayAnim(cache.ped, 'anim@gangops@facility@servers@bodysearch@', 'player_search', 8.0, 8.0, -1, 48, 0, false,
        false, false)
    if lib.progressCircle({
        duration = 8500,
        position = 'bottom',
        label = 'Clearing Plant',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true,
            mouse = false,
            },
        })
    then
        TriggerServerEvent('ps-weedplanting:server:ClearPlant', netId)
        ClearPedTasks(cache.ped)
        RemoveAnimDict('amb@medic@standing@kneel@base')
        RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
    else
        lib.notify({ description = 'Canceled', type = 'error'})
        ClearPedTasks(cache.ped)
        RemoveAnimDict('amb@medic@standing@kneel@base')
        RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
    end
end

local function HarvestPlant(entity)
    local netId = NetworkGetNetworkIdFromEntity(entity)
    TaskTurnPedToFaceEntity(cache.ped, entity, 1.0)
    Wait(1500)

    lib.requestAnimDict('amb@medic@standing@kneel@base')
    lib.requestAnimDict('anim@gangops@facility@servers@bodysearch@')

    TaskPlayAnim(cache.ped, 'amb@medic@standing@kneel@base', 'base', 8.0, 8.0, -1, 1, 0, false, false, false)
    TaskPlayAnim(cache.ped, 'anim@gangops@facility@servers@bodysearch@', 'player_search', 8.0, 8.0, -1, 48, 0, false,
        false, false)

    if lib.progressCircle({
        duration = 8500,
        position = 'bottom',
        label = 'Harvesting Plant',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true,
            mouse = false,
            },
        })
    then
        TriggerServerEvent('ps-weedplanting:server:HarvestPlant', netId)
        ClearPedTasks(cache.ped)
        RemoveAnimDict('amb@medic@standing@kneel@base')
        RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
    else
        lib.notify({ description = 'Canceled', type = 'error'})
        ClearPedTasks(cache.ped)
        RemoveAnimDict('amb@medic@standing@kneel@base')
        RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
    end
end

local function PoliceDestroy(entity)
    local netId = NetworkGetNetworkIdFromEntity(entity)
    TaskTurnPedToFaceEntity(cache.ped, entity, 1.0)
    Wait(500)
    ClearPedTasks(cache.ped)
    TriggerServerEvent('ps-weedplanting:server:PoliceDestroy', netId)
end

local function GiveWater(entity)
    local hasitem = exports.ox_inventory:Search('count', Shared.FullCanItem)
    if hasitem > 0 then
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
        if lib.progressCircle({
            duration = 6000,
            position = 'bottom',
            label = 'Watering Plant',
            useWhileDead = false,
            canCancel = true,
            disable = {
                car = true,
                move = true,
                combat = true,
                mouse = false,
            },
            anim = {
                dict = 'weapon@w_sp_jerrycan',
                clip = 'fire',
                flag = 1
            },
            })
        then
            TriggerServerEvent('ps-weedplanting:server:GiveWater', netId)
            ClearPedTasks(cache.ped)
            DeleteEntity(created_object)
            StopParticleFxLooped(effect, 0)
        else
            ClearPedTasks(cache.ped)
            DeleteEntity(created_object)
            StopParticleFxLooped(effect, 0)
            lib.notify({ description = 'Canceled', type = 'error'})
        end
    else
        lib.notify({ description = 'You dont have a watering can', type = 'error'})
    end
end

local function GiveFertilizer(entity)
    local hasitem = exports.ox_inventory:Search('count', Shared.FertilizerItem)
    if hasitem > 0 then
        local netId = NetworkGetNetworkIdFromEntity(entity)
        local coords = GetEntityCoords(cache.ped)
        local model = joaat('w_am_jerrycan_sf')
        TaskTurnPedToFaceEntity(cache.ped, entity, 1.0)
        Wait(1500)

        lib.requestModel(model)

        local created_object = CreateObject(model, coords.x, coords.y, coords.z, true, true, true)
        AttachEntityToEntity(created_object, cache.ped, GetPedBoneIndex(cache.ped, 28422), 0.3, 0.1, 0.0, 90.0, 180.0,
            0.0, true, true, false, true, 1, true)
        if lib.progressCircle({
            duration = 6000,
            position = 'bottom',
            label = 'Adding Fertilizer',
            useWhileDead = false,
            canCancel = true,
            disable = {
                car = true,
                move = true,
                combat = true,
                mouse = false,
            },
            anim = {
                dict = 'weapon@w_sp_jerrycan',
                clip = 'fire',
                flag = 1
            },
            })
        then
            TriggerServerEvent('ps-weedplanting:server:GiveFertilizer', netId)
            ClearPedTasks(cache.ped)
            DeleteEntity(created_object)
        else
            ClearPedTasks(cache.ped)
            DeleteEntity(created_object)
            lib.notify({ description = 'Canceled', type = 'error'})
        end
    else
        lib.notify({ description = 'You dont have any fertilizer', type = 'error'})
    end
end

local function AddMaleSeed(entity)
    local hasitem = exports.ox_inventory:Search('count', Shared.MaleSeed)
    if hasitem > 0 then
        local netId = NetworkGetNetworkIdFromEntity(entity)
        TaskTurnPedToFaceEntity(cache.ped, entity, 1.0)
        Wait(1500)

        lib.requestAnimDict('amb@medic@standing@kneel@base')
        lib.requestAnimDict('anim@gangops@facility@servers@bodysearch@')

        TaskPlayAnim(cache.ped, 'amb@medic@standing@kneel@base', 'base', 8.0, 8.0, -1, 1, 0, false, false, false)
        TaskPlayAnim(cache.ped, 'anim@gangops@facility@servers@bodysearch@', 'player_search', 8.0, 8.0, -1, 48, 0,
            false, false, false)
        if lib.progressCircle({
            duration = 8500,
            position = 'bottom',
            label = 'Adding Male Seed',
            useWhileDead = false,
            canCancel = true,
            disable = {
                car = true,
                move = true,
                combat = true,
                mouse = false,
                },
            })
        then
            TriggerServerEvent('ps-weedplanting:server:AddMaleSeed', netId)
            ClearPedTasks(cache.ped)
            RemoveAnimDict('amb@medic@standing@kneel@base')
            RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
        else
            lib.notify({ description = 'Canceled', type = 'error'})
            ClearPedTasks(cache.ped)
            RemoveAnimDict('amb@medic@standing@kneel@base')
            RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
        end
    else
        lib.notify({ description = 'You have no male seeds to add', type = 'error'})
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

    lib.showTextUI('[E] - Plant [G] - Cancel', {
        position = "left-center",
        icon = 'cannabis',
    })
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
                if lib.progressCircle({
                    duration = 2000,
                    position = 'bottom',
                    label = 'Planting Sapling',
                    useWhileDead = false,
                    canCancel = true,
                    disable = {
                        car = true,
                        move = true,
                        combat = true,
                        mouse = false,
                        },
                    })
                then
                    TriggerServerEvent('ps-weedplanting:server:CreateNewPlant', dest)
                    planted = false
                    seedUsed = false
                    ClearPedTasks(cache.ped)
                    RemoveAnimDict('amb@medic@standing@kneel@base')
                    RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
                else
                    lib.notify({ description = 'Canceled', type = 'error'})
                    planted = false
                    seedUsed = false
                    ClearPedTasks(cache.ped)
                    RemoveAnimDict('amb@medic@standing@kneel@base')
                    RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
                end
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
    QBCore.Functions.TriggerCallback('ps-weedplanting:server:GetPlantData', function(result)
        if not result then
            return
        end
        local options = {}
        if result.health == 0 then -- Destroy plant
            options[#options+1] = {
                title = 'Clear Plant',
                icon = 'fas fa-skull-crossbones',
                onSelect = function()
                    ClearPlant(data.entity)
                end
            }
            options[#options+1] = {
                title = 'Close Menu',
                icon = 'fas fa-xmark',
                onSelect = function()
                    lib.hideContext('clearplants')
                end
            }
            lib.registerContext({
                id = 'clearplants',
                title = 'Cannabis Plant',
                canClose = true,
                options = options
            })
            lib.showContext('clearplants')
        elseif result.growth == 100 then -- Harvest
            local options = {}
            if IsPolice() then
                options[#options+1] = {
                    title = 'Stage: ' .. result.stage .. ' - Health: ' .. result.health,
                    description = 'This plant is ready for harvest!',
                    icon = 'fas fa-scissors',
                    onSelect = function()
                        HarvestPlant(data.entity)
                    end
                }
                options[#options+1] = {
                    title = 'Destroy Plant',
                    icon = 'fas fa-fire',
                    onSelect = function()
                        PoliceDestroy(data.entity)
                    end
                }
                options[#options+1] = {
                    title = 'Close Menu',
                    icon = 'fas fa-xmark',
                    onSelect = function()
                        lib.hideContext('destroyplants')
                    end
                }
            else
                options[#options+1] = {
                    title = 'Stage: ' .. result.stage .. ' - Health: ' .. result.health,
                    description = 'This plant is ready for harvest!',
                    icon = 'fas fa-scissors',
                    onSelect = function()
                        HarvestPlant(data.entity)
                    end
                }
                options[#options+1] = {
                    title = 'Close Menu',
                    icon = 'fas fa-xmark',
                    onSelect = function()
                        lib.hideContext('destroyplants')
                    end
                }
            end
            lib.registerContext({
                id = 'destroyplants',
                title = 'Cannabis Plant',
                canClose = true,
                options = options
            })
            lib.showContext('destroyplants')
        elseif result.gender == 'female' then -- Option to add male seed
            local options = {}
           if IsPolice() then
                options[#options+1] = {
                    title = 'Growth: ' .. result.growth .. '%' .. ' - Stage: ' .. result.stage,
                    description = 'Health: ' .. result.health,
                    icon = 'fas fa-chart-simple',
                }
                options[#options+1] = {
                    title = 'Close Menu',
                    icon = 'fas fa-xmark',
                    onSelect = function()
                        lib.hideContext('healthmenu')
                    end
                }
                options[#options+1] = {
                    title = 'Destroy Plant',
                    icon = 'fas fa-fire',
                    onSelect = function()
                        PoliceDestroy(data.entity)
                    end
                }
            else
                options[#options+1] = {
                    title = 'Growth: ' .. result.growth .. '%' .. ' - Stage: ' .. result.stage,
                    description = 'Health: ' .. result.health,
                    icon = 'fas fa-chart-simple',
                }
                options[#options+1] = {
                    title = 'Water: ' .. result.water .. '%',
                    description = 'Add Water',
                    icon = 'fas fa-shower',
                    onSelect = function()
                        GiveWater(data.entity)
                    end
                }
                options[#options+1] = {
                    title = 'Fertilizer: ' .. result.fertilizer .. '%',
                    description = 'Add Fertilizer',
                    icon = 'fab fa-nutritionix',
                    onSelect = function()
                        GiveFertilizer(data.entity)
                    end
                }
                options[#options+1] = {
                    title = 'Gender: ' .. result.gender,
                    description = 'Add Male Seed',
                    icon = 'fas fa-venus',
                    onSelect = function()
                        AddMaleSeed(data.entity)
                    end
                }
                options[#options+1] = {
                    title = 'Close Menu',
                    icon = 'fas fa-xmark',
                    onSelect = function()
                        lib.hideContext('healthmenu')
                    end
                }
            end
            lib.registerContext({
                id = 'healthmenu',
                title = 'Cannabis Plant',
                canClose = true,
                options = options
            })
            lib.showContext('healthmenu')
        else -- No option to add male seed
            local options = {}
           if IsPolice() then
                options[#options+1] = {
                    title = 'Growth: ' .. result.growth .. '%' .. ' - Stage: ' .. result.stage,
                    description = 'Health: ' .. result.health,
                    icon = 'fas fa-chart-simple',
                }
                options[#options+1] = {
                    title = 'Close Menu',
                    icon = 'fas fa-xmark',
                    onSelect = function()
                        lib.hideContext('nomaleseed')
                    end
                }
                options[#options+1] = {
                    title = 'Destroy Plant',
                    icon = 'fas fa-fire',
                    onSelect = function()
                        PoliceDestroy(data.entity)
                    end
                }
            else
                options[#options+1] = {
                    title = 'Growth: ' .. result.growth .. '%' .. ' - Stage: ' .. result.stage,
                    description = 'Health: ' .. result.health,
                    icon = 'fas fa-chart-simple',
                }
                options[#options+1] = {
                    title = 'Water: ' .. result.water .. '%',
                    description ='Add Water',
                    icon = 'fas fa-shower',
                    onSelect = function()
                        GiveWater(data.entity)
                    end
                }
                options[#options+1] = {
                    title = 'Fertilizer: ' .. result.fertilizer .. '%',
                    description = 'Add Fertilizer',
                    icon = 'fab fa-nutritionix',
                    onSelect = function()
                        GiveFertilizer(data.entity)
                    end
                }
                options[#options+1] = {
                    title = 'Gender: ' .. result.gender,
                    icon = 'fas fa-mars',
                }
                options[#options+1] = {
                    title = 'Close Menu',
                    icon = 'fas fa-xmark',
                    onSelect = function()
                        lib.hideContext('nomaleseed')
                    end
                }
                lib.registerContext({
                    id = 'nomaleseed',
                    title = 'Cannabis Plant',
                    canClose = true,
                    options = options
                })
                lib.showContext('nomaleseed')
            end
        end
    end, netId)
end)

RegisterNetEvent('ps-weedplanting:client:OpenFillWaterMenu', function()
    lib.registerContext({
        id = 'fillwater',
        title = 'Cannabis Plant',
        canClose = true,
        options = {
            {
                title = 'Fill Watering Can',
                icon = 'fa-solid fa-oil-can',
                onSelect = function()
                    TriggerEvent('ps-weedplanting:client:FillWater')
                end
            },
            {
                title = 'Close Menu',
                icon = 'fas fa-xmark',
                onSelect = function()
                    lib.hideContext('fillwater')
                end
            }
        }
    })
    lib.showContext('fillwater')
end)

RegisterNetEvent('ps-weedplanting:client:FillWater', function()

    local hasItem = exports.ox_inventory:Search('slots', Shared.WaterItem)
    if not hasItem then
        lib.notify({description = 'You need a water bottle', type = 'error'})
        return
    end

    if lib.progressCircle({
        duration = 2000,
        position = 'bottom',
        label = 'Filling Watering Can',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true,
            mouse = false,
            },
        })
    then
        TriggerServerEvent('ps-weedplanting:server:GetFullWateringCan')
    else
        lib.notify({description = 'Canceled', type = 'error'})
    end
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
    local options = {
        {
            icon = 'fas fa-cannabis',
            label = 'Check Plant',
            event = 'ps-weedplanting:client:CheckPlant',
            distance = 2.5,
        }
    }
    exports.ox_target:addModel(Shared.WeedProps, options)
end)
