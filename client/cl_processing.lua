local DisableMovement = {
    disableMovement = true,
    disableCarMovement = true,
    disableMouse = false,
    disableCombat = true,
}

--- Events
RegisterNetEvent('ps-weedplanting:client:UseBranch', function()
    QBCore.Functions.Progressbar('weedbranch', _U('processing_branch'), 5000, false, true, DisableMovement, {}, {}, {}, function() -- Done
        TriggerServerEvent('ps-weedplanting:server:ProcessBranch')
    end, function() -- Cancel
        Notify(_U('canceled'), 'error')
    end)
end)

RegisterNetEvent('ps-weedplanting:client:UseDryWeed', function()
    QBCore.Functions.Progressbar('dryweed', _U('packaging_weed'), 5000, false, true, DisableMovement, {}, {}, {}, function() -- Done
        TriggerServerEvent('ps-weedplanting:server:PackageWeed')
    end, function() -- Cancel
        Notify(_U('canceled'), 'error')
    end)
end)
