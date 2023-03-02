local package
local hasPackage = false

local waitingForPackage = false
local packageZone

local delivering = false
local dropOffBlip
local hasDropOff = false
local dropOffArea
local deliveryPed
local madeDeal = false

--- Functions

--- Checks if a player has a suspicious package on him or her
--- @return nil
local checkPackage = function()
    Wait(250) -- May have to increase this to 500 or 1000 so the core/invent can catch up
    if QBCore.Functions.HasItem(Shared.SusPackageItem, 1) then
        if not hasPackage then
            -- Animation
            lib.requestAnimDict('anim@heists@box_carry@')
            TaskPlayAnim(cache.ped, 'anim@heists@box_carry@', 'idle', 5.0, -1, -1, 50, 0, false, false, false)

            -- Package
            local pos = GetEntityCoords(cache.ped, true)

            lib.requestModel(Shared.PackageProp)
            local object = CreateObject(Shared.PackageProp, pos.x, pos.y, pos.z, true, true, true)
            AttachEntityToEntity(object, cache.ped, GetPedBoneIndex(cache.ped, 57005), 0.1, 0.1, -0.25, 300.0, 250.0,
                15.0, true, true, false, true, 1, true)
            package = object
            hasPackage = true

            -- Walk
            CreateThread(function()
                while hasPackage do
                    Wait(0)
                    SetPlayerSprint(cache.playerId, false)
                    DisableControlAction(0, 21, true)
                    DisableControlAction(0, 22, true)
                    if not IsEntityPlayingAnim(cache.ped, 'anim@heists@box_carry@', 'idle', 3) then
                        TaskPlayAnim(cache.ped, 'anim@heists@box_carry@', 'idle', 8.0, 8.0, -1, 50, 0, false, false,
                            false)
                    end
                end
            end)
        end
    else
        DetachEntity(package, true, true)
        DeleteObject(package)
        StopAnimTask(cache.ped, 'anim@heists@box_carry@', 'idle', 1.0)
        package = nil
        hasPackage = false
    end
end

--- Creates a drop off blip at a given coordinate
--- @param coords vector4 - Coordinates of a location
local createDropOffBlip = function(coords)
    dropOffBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(dropOffBlip, 140)
    SetBlipColour(dropOffBlip, 25)
    SetBlipAsShortRange(dropOffBlip, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(_U('weedrun_delivery_blip'))
    EndTextCommandSetBlipName(dropOffBlip)
end

--- Creates a drop off ped at a given coordinate
--- @param coords vector4 - Coordinates of a location
--- @return nil
local createDropOffPed = function(coords)
    if deliveryPed then
        return
    end
    local model = Shared.DropOffPeds[math.random(#Shared.DropOffPeds)]
    local hash = joaat(model)


    lib.requestModel(hash)

    deliveryPed = CreatePed(5, hash, coords.x, coords.y, coords.z - 1.0, coords.w, true, true)
    while not DoesEntityExist(deliveryPed) do
        Wait(0)
    end
    ClearPedTasks(deliveryPed)
    ClearPedSecondaryTask(deliveryPed)
    TaskSetBlockingOfNonTemporaryEvents(deliveryPed, true)
    SetPedFleeAttributes(deliveryPed, 0, 0)
    SetPedCombatAttributes(deliveryPed, 17, 1)
    SetPedSeeingRange(deliveryPed, 0.0)
    SetPedHearingRange(deliveryPed, 0.0)
    SetPedAlertness(deliveryPed, 0)
    SetPedKeepTask(deliveryPed, true)
    FreezeEntityPosition(deliveryPed, true)
    exports['qb-target']:AddTargetEntity(deliveryPed, {
        options = {{
            type = 'client',
            event = 'ps-weedplanting:client:DeliverWeed',
            icon = 'fas fa-cannabis',
            label = _U('deliver_package')
        }},
        distance = 2.0
    })
end

--- Method to create a drop-off location for delivering the weedrun packages
--- @return nil
local createNewDropOff = function()
    if hasDropOff then
        return
    end
    hasDropOff = true
    TriggerEvent('qb-phone:client:CustomNotification', _U('weedrun_delivery_title'), _U('weedrun_delivery_godropoff'),
        'fas fa-cannabis', '#00FF00', 8000)
    local randomLoc = Shared.DropOffLocations[math.random(#Shared.DropOffLocations)]
    createDropOffBlip(randomLoc)
    dropOffArea = CircleZone:Create(randomLoc.xyz, 85.0, {
        name = 'dropOffArea',
        debugPoly = false
    })

    dropOffArea:onPlayerInOut(function(isPointInside, point)
        if isPointInside then
            if not deliveryPed then
                TriggerEvent('qb-phone:client:CustomNotification', _U('weedrun_delivery_title'),
                    _U('weedrun_delivery_makedropoff'), 'fas fa-cannabis', '#00FF00', 8000)
                createDropOffPed(randomLoc)
            end
        end
    end)
end

--- Method to clear current weed run
--- @return nil
clearWeedRun = function()
    -- Deliveries
    delivering = false
    hasDropOff = false
    RemoveBlip(dropOffBlip)
    if dropOffArea then
        dropOffArea:destroy()
        DeletePed(deliveryPed)
        deliveryPed = nil
    end

    -- Package
    if package then
        DetachEntity(package, true, true)
        DeleteObject(package)
        StopAnimTask(cache.ped, 'anim@heists@box_carry@', 'idle', 1.0)
        package = nil
        hasPackage = false
    end
end

--- Events

RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    checkPackage()
end)

RegisterNetEvent('ps-weedplanting:client:StartPackage', function(data)
    if waitingForPackage then
        return
    end
    local hasItem = QBCore.Functions.HasItem(Shared.PackedWeedItem, 1)
    if not hasItem then
        Notify(_U('dont_have_anything'), 'error')
        return
    end

    FreezeEntityPosition(cache.ped, true)
    TaskTurnPedToFaceEntity(cache.ped, data.entity, 1.0)
    Wait(1500)
    PlayAmbientSpeech1(cache.ped, 'Generic_Hi', 'Speech_Params_Force')
    Wait(1000)

    lib.requestAnimDict('mp_safehouselost@')

    TaskPlayAnim(cache.ped, 'mp_safehouselost@', 'package_dropoff', 8.0, 1.0, -1, 16, 0, 0, 0, 0)
    QBCore.Functions.Progressbar('weedrun_pack', _U('handing_over_weed'), 4000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true
    }, {}, {}, {}, function()
        FreezeEntityPosition(cache.ped, false)
        QBCore.Functions.TriggerCallback('ps-weedplanting:server:PackageGoods', function(result)
            if not result then
                return
            end
            waitingForPackage = true
            Notify(_U('wait_closeby'), 'primary')

            packageZone = CircleZone:Create(Shared.WeedRunStart.xyz, 10.0, {
                name = 'weedrunning_start',
                debugPoly = false
            })

            packageZone:onPlayerInOut(function(isPointInside, point)
                if not isPointInside then
                    packageZone:destroy()
                    if waitingForPackage then
                        TriggerServerEvent('ps-weedplanting:server:DestroyWaitForPackage')
                        waitingForPackage = false
                    end
                end
            end)
        end)
    end, function()
        Notify(_U('canceled'), 'error')
        FreezeEntityPosition(cache.ped, false)
    end)
end)

RegisterNetEvent('ps-weedplanting:client:PackageGoodsReceived', function()
    if waitingForPackage then
        packageZone:destroy()
        waitingForPackage = false
    end
end)

RegisterNetEvent('ps-weedplanting:client:ClockIn', function()
    if delivering then
        return
    end
    delivering = true
    TriggerEvent('qb-phone:client:CustomNotification', _U('weedrun_delivery_title'), _U('weedrun_delivery_waitfornew'),
        'fas fa-cannabis', '#00FF00', 8000)
    Wait(math.random(Shared.DeliveryWaitTime[1], Shared.DeliveryWaitTime[2]))
    createNewDropOff()
end)

RegisterNetEvent('ps-weedplanting:client:ClockOut', function()
    if not delivering then
        return
    end
    delivering = false
    hasDropOff = false
    RemoveBlip(dropOffBlip)
    if dropOffArea then
        dropOffArea:destroy()
        DeletePed(deliveryPed)
        deliveryPed = nil
    end
    Notify(_U('weedrun_clockout'), 'primary')
end)

RegisterNetEvent('ps-weedplanting:client:DeliverWeed', function()
    if madeDeal then
        return
    end

    if not hasPackage then
        Notify(_U('weedrun_hasnopackage'), 'error')
        return
    end

    if not IsPedOnFoot(cache.ped) then
        return
    end
    if #(GetEntityCoords(cache.ped) - GetEntityCoords(deliveryPed)) < 5.0 then
        madeDeal = true
        exports['qb-target']:RemoveTargetEntity(deliveryPed)

        -- Alert Cops
        if math.random(100) <= Shared.CallCopsChance then
            if GetResourceState('ps-dispatch') == 'started' then
                exports['ps-dispatch']:DrugSale() -- Project-SLoth ps-dispatch
            end
        end

        -- Face each other
        FreezeEntityPosition(cache.ped, true)
        TaskTurnPedToFaceEntity(deliveryPed, cache.ped, 1.0)
        TaskTurnPedToFaceEntity(cache.ped, deliveryPed, 1.0)
        PlayAmbientSpeech1(cache.ped, 'Generic_Hi', 'Speech_Params_Force')
        Wait(1500)
        PlayAmbientSpeech1(deliveryPed, 'Generic_Hi', 'Speech_Params_Force')
        Wait(1000)
        TriggerServerEvent('ps-weedplanting:server:WeedrunDelivery')

        -- deliveryPed animation
        PlayAmbientSpeech1(deliveryPed, 'Chat_State', 'Speech_Params_Force')
        Wait(500)
        RequestAnimDict('mp_safehouselost@')
        while not HasAnimDictLoaded('mp_safehouselost@') do
            Wait(0)
        end
        TaskPlayAnim(deliveryPed, 'mp_safehouselost@', 'package_dropoff', 8.0, 1.0, -1, 16, 0, 0, 0, 0)
        Wait(3000)

        -- Finishing up
        FreezeEntityPosition(cache.ped, false)
        RemoveBlip(dropOffBlip)
        dropOffBlip = nil
        dropOffArea:destroy()
        Wait(2000)
        TriggerEvent('qb-phone:client:CustomNotification', _U('weedrun_delivery_title'), _U('weedrun_delivery_success'),
            'fas fa-cannabis', '#00FF00', 20000)
        ClearPedTasks(cache.ped)

        -- Delete Delivery Ped
        FreezeEntityPosition(deliveryPed, false)
        SetPedKeepTask(deliveryPed, false)
        TaskSetBlockingOfNonTemporaryEvents(deliveryPed, false)
        ClearPedTasks(deliveryPed)
        TaskWanderStandard(deliveryPed, 10.0, 10)
        SetPedAsNoLongerNeeded(deliveryPed)
        Wait(20000)
        DeletePed(deliveryPed)
        deliveryPed = nil
        hasDropOff = false
        madeDeal = false

        Wait(math.random(Shared.DeliveryWaitTime[1], Shared.DeliveryWaitTime[2]))
        createNewDropOff()
    end
end)

--- Threads

CreateThread(function()
    exports['qb-target']:SpawnPed({
        model = Shared.PedModel,
        coords = Shared.WeedRunStart,
        minusOne = true,
        freeze = true,
        invincible = true,
        blockevents = true,
        animDict = 'anim@mp_celebration@idles@female',
        anim = 'celebration_idle_f_a',
        flag = 0,
        target = {
            options = {{ -- Create Package
                type = 'client',
                event = 'ps-weedplanting:client:StartPackage',
                icon = 'fas fa-circle-chevron-right',
                label = _U('package_goods'),
                canInteract = function()
                    return not waitingForPackage
                end
            }, { -- Receive Package
                type = 'server',
                event = 'ps-weedplanting:server:CollectPackageGoods',
                icon = 'fas fa-circle-chevron-right',
                label = _U('grab_packaged_goods'),
                canInteract = function()
                    return waitingForPackage
                end
            }, { -- Clock In for deliveries
                type = 'client',
                event = 'ps-weedplanting:client:ClockIn',
                icon = 'fas fa-stopwatch',
                label = _U('start_delivering'),
                canInteract = function()
                    return not delivering
                end
            }, { -- Clock out for deliveries
                type = 'client',
                event = 'ps-weedplanting:client:ClockOut',
                icon = 'fas fa-stopwatch',
                label = _U('stop_delivering'),
                canInteract = function()
                    return delivering
                end
            }},
            distance = 1.5
        }
    })
end)
