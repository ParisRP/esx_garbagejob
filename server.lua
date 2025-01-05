ESX = nil

-- Récupération de l'ESX framework
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

-- Variables pour suivre le travail des joueurs
local jobInProgress = {}

-- Début du travail de collecte des déchets
RegisterServerEvent('garbagejob:startJob')
AddEventHandler('garbagejob:startJob', function()
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    -- Vérifier si le joueur a déjà un travail en cours
    if jobInProgress[_source] then
        TriggerClientEvent('esx:showNotification', _source, 'Vous avez déjà un travail de collecte en cours.')
        return
    end

    -- Marquer le travail comme étant en cours
    jobInProgress[_source] = true
    TriggerClientEvent('esx:showNotification', _source, 'Le travail de collecte des déchets a commencé.')
end)

-- Collecte d'un sac de poubelle (récompense)
RegisterServerEvent('garbagejob:collectBag')
AddEventHandler('garbagejob:collectBag', function()
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    -- Ajouter un sac de poubelle à l'inventaire du joueur (ou ajuster à votre système d'inventaire)
    xPlayer.addInventoryItem('garbage_bag', 1) -- Exemple avec un item appelé "garbage_bag"

    -- Notifier le joueur
    TriggerClientEvent('esx:showNotification', _source, 'Vous avez collecté un sac de poubelle.')
end)

-- Déposer les sacs de poubelle au centre de recyclage
RegisterServerEvent('garbagejob:depositBags')
AddEventHandler('garbagejob:depositBags', function()
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    -- Vérifier si le joueur a des sacs de poubelle
    local garbageBagCount = xPlayer.getInventoryItem('garbage_bag').count
    if garbageBagCount > 0 then
        -- Enlever un sac de poubelle de l'inventaire
        xPlayer.removeInventoryItem('garbage_bag', 1)

        -- Ajouter de l'argent ou des points de travail pour la récompense
        local reward = 50 -- Exemple de récompense en argent
        xPlayer.addMoney(reward)

        -- Notifier le joueur
        TriggerClientEvent('esx:showNotification', _source, 'Vous avez déposé un sac de poubelle. Vous avez gagné ' .. reward .. '$.')

        -- Si le joueur n'a plus de sacs à déposer, terminer le travail
        local newGarbageBagCount = xPlayer.getInventoryItem('garbage_bag').count
        if newGarbageBagCount == 0 then
            jobInProgress[_source] = nil
            TriggerClientEvent('esx:showNotification', _source, 'Vous avez terminé votre travail de collecte.')
        end
    else
        TriggerClientEvent('esx:showNotification', _source, 'Vous n\'avez pas de sacs de poubelle à déposer.')
    end
end)

-- Quand le joueur quitte le serveur, annuler son travail en cours
AddEventHandler('playerDropped', function()
    local _source = source

    -- Annuler le travail du joueur s'il est en cours
    if jobInProgress[_source] then
        jobInProgress[_source] = nil
    end
end)
