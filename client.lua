-- Déclaration des coordonnées des points de collecte de déchets
local garbagePoints = {
    {x = 200.1, y = -1503.6, z = 29.14},
    {x = 300.5, y = -1405.7, z = 29.37},
    {x = 245.6, y = -1345.9, z = 29.54},
    {x = 180.8, y = -1324.5, z = 29.31}
}

local recyclingLocation = {x = -552.6, y = -1690.4, z = 19.18}, {x = -552.6, y = -1690.4, z = 19.18} -- Centre de recyclage
local vehicleSpawnLocation = {x = 1849.6, y = 2587.1, z = 45.6} -- Lieu de spawn du camion près de la prison

-- Lieu de départ du job
local jobStartLocation = {x = 200.1, y = -1503.6, z = 29.14} -- Départ du travail

-- Créer un blip pour le point de départ du job
Citizen.CreateThread(function()
    local blip = AddBlipForCoord(jobStartLocation.x, jobStartLocation.y, jobStartLocation.z)
    SetBlipSprite(blip, 365) -- Icône de la poubelle
    SetBlipColour(blip, 5) -- Couleur du blip (Vert pour la poubelle)
    SetBlipRoute(blip, true) -- Tracer la route vers le point de départ
end)

-- Fonction pour afficher du texte en 3D
function DrawText3D(x, y, z, text)
    SetDrawOrigin(x, y, z, 0)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

-- Commande pour démarrer le travail de collecte des déchets
RegisterCommand('startgarbagejob', function()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    -- Vérifier si le joueur est à proximité du point de départ
    if #(playerCoords - vector3(jobStartLocation.x, jobStartLocation.y, jobStartLocation.z)) < 3.0 then
        TriggerServerEvent('garbagejob:startJob') -- Demander au serveur de commencer le job
        TriggerEvent('esx:showNotification', 'Le travail de collecte des déchets commence !')
    else
        TriggerEvent('esx:showNotification', 'Vous devez être près du point de départ pour commencer.')
    end
end, false)

-- Fonction pour commencer à collecter les déchets
RegisterNetEvent('garbagejob:startJob')
AddEventHandler('garbagejob:startJob', function()
    local currentPointIndex = 1
    local playerPed = PlayerPedId()
    
    -- Créer un blip pour le premier point de collecte
    local blip = AddBlipForCoord(garbagePoints[currentPointIndex].x, garbagePoints[currentPointIndex].y, garbagePoints[currentPointIndex].z)
    SetBlipSprite(blip, 365)
    SetBlipColour(blip, 5)
    SetBlipRoute(blip, true)
    
    -- Lancer une boucle pour gérer le travail
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
            
            local playerCoords = GetEntityCoords(playerPed)
            local distance = #(playerCoords - vector3(garbagePoints[currentPointIndex].x, garbagePoints[currentPointIndex].y, garbagePoints[currentPointIndex].z))
            
            -- Vérifier si le joueur est proche du point de collecte
            if distance < 3.0 then
                DrawText3D(garbagePoints[currentPointIndex].x, garbagePoints[currentPointIndex].y, garbagePoints[currentPointIndex].z + 1.0, '[E] Collecter un sac de poubelle')
                
                if IsControlJustReleased(0, 38) then -- La touche 'E' pour collecter
                    -- Animer le joueur pour collecter un sac
                    TaskStartScenarioInPlace(playerPed, 'PROP_HUMAN_BUM_BIN', 0, true)
                    Citizen.Wait(5000) -- Attente de 5 secondes pour l'animation
                    ClearPedTasksImmediately(playerPed)
                    
                    -- Notifier le joueur
                    TriggerServerEvent('garbagejob:collectBag')
                    TriggerEvent('esx:showNotification', 'Vous avez collecté un sac de poubelle.')
                    
                    -- Passer au point suivant
                    currentPointIndex = currentPointIndex + 1
                    if garbagePoints[currentPointIndex] then
                        -- Mettre à jour le blip pour le prochain point
                        SetBlipCoords(blip, garbagePoints[currentPointIndex].x, garbagePoints[currentPointIndex].y, garbagePoints[currentPointIndex].z)
                    else
                        -- Si tous les sacs sont collectés, diriger le joueur vers le centre de recyclage
                        RemoveBlip(blip)
                        blip = AddBlipForCoord(recyclingLocation.x, recyclingLocation.y, recyclingLocation.z)
                        SetBlipSprite(blip, 478) -- Icône de recyclage
                        SetBlipColour(blip, 2) -- Couleur du blip (Bleu pour le recyclage)
                        SetBlipRoute(blip, true)
                        TriggerEvent('esx:showNotification', 'Vous avez collecté tous les sacs. Dirigez-vous vers le centre de recyclage.')
                        break
                    end
                end
            end
        end
    end)
end)

-- Commande pour demander un camion de poubelle
RegisterCommand('getgarbagetruck', function()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    -- Créer le véhicule à proximité de la prison ou d'un autre point
    local vehicleModel = GetHashKey('trash') -- Le modèle du camion
    RequestModel(vehicleModel)
    while not HasModelLoaded(vehicleModel) do
        Citizen.Wait(100)
    end

    -- Créer le véhicule
    local vehicle = CreateVehicle(vehicleModel, vehicleSpawnLocation.x, vehicleSpawnLocation.y, vehicleSpawnLocation.z, 0.0, true, false)
    SetVehicleNumberPlateText(vehicle, "WORK" .. math.random(100, 999)) -- Ajouter un numéro de plaque aléatoire
    TaskWarpPedIntoVehicle(playerPed, vehicle, -1) -- Mettre le joueur dans le camion

    -- Notification à l'utilisateur
    TriggerEvent('esx:showNotification', 'Votre camion de poubelle a été livré près de la prison.')
end, false)

-- Gérer le dépôt des sacs au centre de recyclage
RegisterNetEvent('garbagejob:depositBags')
AddEventHandler('garbagejob:depositBags', function()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local distance = #(playerCoords - vector3(recyclingLocation.x, recyclingLocation.y, recyclingLocation.z))

    -- Vérifier si le joueur est proche du centre de recyclage
    if distance < 3.0 then
        TriggerServerEvent('garbagejob:depositBags') -- Appeler l'événement serveur pour le dépôt des sacs
        TriggerEvent('esx:showNotification', 'Vous avez déposé vos sacs de poubelle au centre de recyclage.')
    else
        TriggerEvent('esx:showNotification', 'Vous devez être près du centre de recyclage pour déposer vos sacs.')
    end
end)
