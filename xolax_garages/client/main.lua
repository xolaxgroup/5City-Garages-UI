local GUI                     = {}
local HasAlreadyEnteredMarker = false
local LastZone                = nil
local CurrentGarage           = nil
local PlayerData              = {}
local CurrentAction           = nil
local IsInShopMenu            = false
local pCoords 				  = nil
local hex = nil
VehTable = {}
ESX                           = nil
GUI.Time                      = 0

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end
	PlayerData = ESX.GetPlayerData()
end)

RegisterNetEvent('esx:setJob2')
AddEventHandler('esx:setJob2', function(job2)
	PlayerData.job2 = job2
end)

RegisterCommand("vehprops", function()
	local playerPed = PlayerPedId()
	local vehicle = GetVehiclePedIsIn(playerPed, false)
	local vehicleProps = ESX.Game.GetVehicleProperties(vehicle)
	print(json.encode(vehicleProps))
	DisplayRadar(false)
end)

Citizen.CreateThread(function()
	AddTextEntry('WT_BUTTERFLYFADE', 'Batterfly Fade')
end)

RegisterNetEvent('xolax:dvveh')
AddEventHandler('xolax:dvveh', function()
	local playerPed = PlayerPedId()
	local vehicle   = ESX.Game.GetVehicleInDirection()

	if IsPedInAnyVehicle(playerPed, true) then
		vehicle = GetVehiclePedIsIn(playerPed, false)
	end

	if DoesEntityExist(vehicle) then
		DeleteVehicle(vehicle)
	end
end)

-- Create Blips
Citizen.CreateThread(function()
	for i=1, #Config.Garages do
		if Config.Garages[i].Blip == true then
			local blip = AddBlipForCoord(Config.Garages[i].Marker)
			SetBlipSprite (blip, 50)
			SetBlipDisplay(blip, 4)
			SetBlipScale  (blip, 0.5)
			SetBlipColour (blip, 38)
			SetBlipAsShortRange(blip, true)		
			BeginTextCommandSetBlipName("STRING")
			AddTextComponentString(_U('garage_blip'))
			EndTextCommandSetBlipName(blip)
		end
	end
	for i=1, #Config.Impound, 1 do
		local blip2 = AddBlipForCoord(Config.Impound[i])
		SetBlipSprite (blip2, 67)
		SetBlipDisplay(blip2, 4)
		SetBlipScale  (blip2, 0.6)
		SetBlipColour (blip2, 61)
		SetBlipAsShortRange(blip2, true)		
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString(_U('impound_blip'))
		EndTextCommandSetBlipName(blip2)
	end

	for i=1, #Config.CarScrap, 1 do
		local blip3 = AddBlipForCoord(Config.CarScrap[i])
		SetBlipSprite (blip3, 463)
		SetBlipDisplay(blip3, 4)
		SetBlipScale  (blip3, 1.2)
		SetBlipColour (blip3, 31)
		SetBlipAsShortRange(blip3, true)		
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString(_U('scrap_blip'))
		EndTextCommandSetBlipName(blip3)
	end
end)

Citizen.CreateThread(function()
	while true do
		local playerPed = PlayerPedId()
		pCoords = GetEntityCoords(playerPed)
		Citizen.Wait(800)
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(1)
		if hex == nil then
			ESX.TriggerServerCallback('xolax_garages:getPlayerHex', function(h)
				hex = h
            end)
            ESX.TriggerServerCallback('xolax_garages:getVehiclesNames', function(vt)
                VehTable = vt
            end)
		end
	end
end)

function GetVehicleNameModel(car)
        for i=1, #VehTable, 1 do
            if car == GetHashKey(VehTable[i].model) then
                return VehTable[i].name
            end
		end
        return GetDisplayNameFromVehicleModel(car)
end

function round(n)
    if not n then return 0; end
    return n % 1 >= 0.5 and math.ceil(n) or math.floor(n)
end

local cache = {}
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(5)
		for _, data in ipairs(cache) do
			if(GetDistanceBetweenCoords(pCoords, data.coords.x, data.coords.y, data.coords.z, true) < Config.DrawDistance) then
				DrawMarker(data.marker, data.coords.x, data.coords.y, data.coords.z, 0.0, 0.0, 0.0, data.offset.x, data.offset.y, data.offset.z, data.size.x, data.size.y, data.size.z, data.color.r, data.color.g, data.color.b, 100, false, true, 2, false, false, false, false)
			end
		end
	end
end)

-- Enter / Exit marker events
Citizen.CreateThread(function ()
  while PlayerData.job == nil do
	Citizen.Wait(500)
  end
  while true do
	Wait(600)
	cache = {}
    local isInMarker  = false
    local currentZone = nil
	local playerPed = GetPlayerPed(-1)
    for i=1, #Config.Garages, 1 do
		if(GetDistanceBetweenCoords(pCoords, Config.Garages[i].Marker, true) < Config.DrawDistance) then
			if Config.Garages[i].Visible[1] == nil then
				if Config.Garages[i].Hex == true then
					for j=1, #Config.Garages[i].Hexs, 1 do
						if hex == Config.Garages[i].Hexs[j] then
							table.insert(cache, {
								marker = Config.MarkerType,
								coords  = Config.Garages[i].Marker,
								offset = {x = 0.0, y = 0.0, z = 0.0},
								size = {x = 5.0, y = 5.0, z = 0.5},
								color = {r = 17, g = 255, b = 0}
							})
							if(GetDistanceBetweenCoords(pCoords, Config.Garages[i].Marker, true) < Config.MarkerSize.x) then
								if IsPedInAnyVehicle(playerPed) then
									isInMarker  = true
									currentZone = 'park_car'
									CurrentGarage = Config.Garages[i].Marker
								elseif not IsPedInAnyVehicle(playerPed) then
									isInMarker = true
									currentZone = 'pullout_car'
									CurrentGarage = Config.Garages[i].Marker
								end
							end
						end
					end
				else
					if Config.Garages[i].Properties then
						for j=1, #Config.Garages[i].Properties, 1 do
							if exports['esx_property']:PropertyIsOwned({name = Config.Garages[i].Properties[j]}) == true then
								for j=1, #Config.Garages[i].Properties, 1 do
									table.insert(cache, {
										marker = Config.MarkerType,
										coords  = Config.Garages[i].Marker,
										offset = {x = 0.0, y = 0.0, z = 0.0},
										size = {x = 5.0, y = 5.0, z = 0.5},
										color = {r = 17, g = 255, b = 0}
									})
									if(GetDistanceBetweenCoords(pCoords, Config.Garages[i].Marker, true) < Config.MarkerSize.x) then
										if IsPedInAnyVehicle(playerPed) then
											isInMarker  = true
											currentZone = 'park_car'
											CurrentGarage = Config.Garages[i].Marker
										elseif not IsPedInAnyVehicle(playerPed) then
											isInMarker = true
											currentZone = 'pullout_car'
											CurrentGarage = Config.Garages[i].Marker
										end
									end
								end
							end
						end
					else
						table.insert(cache, {
							marker = Config.MarkerType,
							coords  = Config.Garages[i].Marker,
							offset = {x = 0.0, y = 0.0, z = 0.0},
							size = {x = 5.0, y = 5.0, z = 0.5},
							color = {r = 17, g = 255, b = 0}
						})
						if(GetDistanceBetweenCoords(pCoords, Config.Garages[i].Marker, true) < Config.MarkerSize.x) then
							if IsPedInAnyVehicle(playerPed) then
								isInMarker  = true
								currentZone = 'park_car'
								CurrentGarage = Config.Garages[i].Marker
							elseif not IsPedInAnyVehicle(playerPed) then
								isInMarker = true
								currentZone = 'pullout_car'
								CurrentGarage = Config.Garages[i].Marker
							end
						end
					end
				end
			else
				for j=1, #Config.Garages[i].Visible, 1 do
					if PlayerData.job.name == Config.Garages[i].Visible[j] then
						table.insert(cache, {
							marker = Config.MarkerType,
							coords  = Config.Garages[i].Marker,
							offset = {x = 0.0, y = 0.0, z = 0.0},
							size = {x = 5.0, y = 5.0, z = 0.5},
							color = {r = 17, g = 255, b = 0}
						})
						if(GetDistanceBetweenCoords(pCoords, Config.Garages[i].Marker, true) < Config.MarkerSize.x) then
							if IsPedInAnyVehicle(playerPed) then
								isInMarker  = true
								currentZone = 'park_car'
								CurrentGarage = Config.Garages[i].Marker
							elseif not IsPedInAnyVehicle(playerPed) then
								isInMarker = true
								currentZone = 'pullout_car'
								CurrentGarage = Config.Garages[i].Marker
							end
						end
					end
				end
			end
		end
    end
	for i=1, #Config.Impound, 1 do
		table.insert(cache, {
			marker = Config.MarkerType,
			coords  = Config.Impound[i],
			offset = {x = 0.0, y = 0.0, z = 0.0},
			size = {x = 5.0, y = 5.0, z = 0.5},
			color = {r = 17, g = 255, b = 0}
		})
		if(GetDistanceBetweenCoords(pCoords, Config.Impound[i], true) < Config.MarkerSize.x) then
			isInMarker  = true
			currentZone = 'impound_veh'
			CurrentGarage = Config.Impound[i]
		end
    end
	for i=1, #Config.PoliceImpound, 1 do
		table.insert(cache, {
			marker = Config.MarkerType,
			coords  = Config.PoliceImpound[i],
			offset = {x = 0.0, y = 0.0, z = 0.0},
			size = {x = 5.0, y = 5.0, z = 0.5},
			color = {r = 17, g = 255, b = 0}
		})
		if(GetDistanceBetweenCoords(pCoords, Config.PoliceImpound[i], true) < Config.MarkerSize.x) then
			if PlayerData.job.name == 'police' then
				isInMarker  = true
				currentZone = 'police_impound_veh'
				CurrentGarage = Config.PoliceImpound[i]
			end
		end
    end
	for i=1, #Config.SetSubowner, 1 do
		table.insert(cache, {
			marker = Config.MarkerType,
			coords  = Config.SetSubowner[i],
			offset = {x = 0.0, y = 0.0, z = 0.0},
			size = {x = 2.0, y = 2.0, z = 0.5},
			color = {r = 17, g = 255, b = 0}
		})
		if(GetDistanceBetweenCoords(pCoords, Config.SetSubowner[i], true) < 2.0) then
			isInMarker  = true
			currentZone = 'subowner_veh'
			CurrentGarage = Config.SetSubowner[i]
		end
	end

	for i=1, #Config.CarScrap, 1 do
		table.insert(cache, {
			marker = Config.MarkerType,
			coords  = Config.CarScrap[i],
			offset = {x = 0.0, y = 0.0, z = 0.0},
			size = {x = 5.0, y = 5.0, z = 0.5},
			color = {r = 17, g = 255, b = 0}
		})
		if(GetDistanceBetweenCoords(pCoords, Config.CarScrap[i], true) < Config.MarkerSize.x) then
			isInMarker  = true
			currentZone = 'scrap_veh'
			CurrentGarage = Config.CarScrap[i]
		end
    end

    if (isInMarker and not HasAlreadyEnteredMarker) or (isInMarker and LastZone ~= currentZone) then
		HasAlreadyEnteredMarker = true
		LastZone = currentZone
		TriggerEvent('xolax_garages:hasEnteredMarker', currentZone)
    end
    if not isInMarker and HasAlreadyEnteredMarker then
		HasAlreadyEnteredMarker = false
		TriggerEvent('xolax_garages:hasExitedMarker', LastZone)
    end
  end
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	PlayerData.job = job
end)

function SubownerVehicle()
	ESX.UI.Menu.Open(
		'dialog', GetCurrentResourceName(), 'subowner_player',
		{
			title = "Tablica rejestracyjna",
			align = 'center'
		},
		function(data, menu)
			local plate = string.upper(tostring(data.value))
			ESX.TriggerServerCallback('xolax_garages:checkIfPlayerIsOwner', function(isOwner)
				if isOwner then
					menu.close()
					ESX.UI.Menu.Open(
						'default', GetCurrentResourceName(), 'subowner_menu',
						{
							title = "Zarządzanie pojazdem " .. plate,
							align = 'center',
							elements	= {
								{label = "Nadaj współwłaściciela", value = 'give_sub'},
								{label = "Usuwanie współwłaścicieli", value = 'manage_sub'},
								{label = "Przepisywanie pojazdu", value = 'sell_vehicle'},
							}
						},
						function(data2, menu2)
							local playerPed = PlayerPedId()
							if data2.current.value == 'give_sub' then
								local players      = ESX.Game.GetPlayersInArea(GetEntityCoords(playerPed), 3.0)
								local foundPlayers = false
								local elements     = {}
				
								for i=1, #players, 1 do
									if players[i] ~= PlayerId() then
										foundPlayers = true
				
										table.insert(elements, {
											label = GetPlayerName(players[i]),
											player = players[i]
										})
									end
								end
				
								if not foundPlayers then
									ESX.ShowNotification('Brak osób w pobliżu!')
									return
								end
				
								foundPlayers = false
				
								ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'give_item_to',
								{
									title    = 'Nadawanie kluczy',
									align    = 'bottom-right',
									elements = elements
								}, function(data2, menu2)
									local players, nearbyPlayer = ESX.Game.GetPlayersInArea(GetEntityCoords(playerPed), 3.0)

									for i=1, #players, 1 do
										if players[i] ~= PlayerId() then
				
											if players[i] == data2.current.player then
												foundPlayers = true
												nearbyPlayer = players[i]
												break
											end
										end
									end
				
									if not foundPlayers then
										ESX.ShowNotification('Brak osób w pobliżu!')
										menu2.close()
										return
									end

									TriggerServerEvent('xolax_garages:setSubowner', plate, GetPlayerServerId(nearbyPlayer))
								end, function(data2, menu2)
									menu2.close()
								end) 							
							elseif data2.current.value == 'manage_sub' then
								ESX.TriggerServerCallback('xolax_garages:getSubowners', function(subowners)
									if #subowners > 0 then
										ESX.UI.Menu.Open(
											'default', GetCurrentResourceName(), 'subowners',
											{
												title = _U('deleting_sub', plate),
												align = 'center',
												elements = subowners
											},
											function(data3, menu3)
												local subowner = data3.current.value
												ESX.UI.Menu.Open(
													'default', GetCurrentResourceName(), 'yesorno',
													{
														title = _U('sure_delete'),
														align = 'center',
														elements = {
															{label = _U('no'), value = 'no'},
															{label = _U('yes'), value = 'yes'}
														}
													},
													function(data4, menu4)
														if data4.current.value == 'yes' then
															TriggerServerEvent('xolax_garages:deleteSubowner', plate, subowner)
															menu4.close()
															menu3.close()
															menu2.close()
														elseif data4.current.value == 'no' then
															menu4.close()
														end
													end,
													function(data4, menu4)
														menu4.close()
													end
												)													
											end,
											function(data3, menu3)
												menu3.close()
											end
										)
									else
										ESX.ShowNotification(_U('no_subs'))
									end
								end, plate)
							elseif data2.current.value == 'sell_vehicle' then
								local players      = ESX.Game.GetPlayersInArea(GetEntityCoords(playerPed), 3.0)
								local foundPlayers = false
								local elements     = {}
				
								for i=1, #players, 1 do
									if players[i] ~= PlayerId() then
										foundPlayers = true
				
										table.insert(elements, {
											label = GetPlayerName(players[i]),
											player = players[i]
										})
									end
								end
				
								if not foundPlayers then
									ESX.ShowNotification('Brak osób w pobliżu!')
									return
								end
				
								foundPlayers = false
				
								ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'sell_vehicle',
								{
									title    = 'Przepisywanie pojazdu',
									align    = 'bottom-right',
									elements = elements
								}, function(data2, menu2)
									local players, nearbyPlayer = ESX.Game.GetPlayersInArea(GetEntityCoords(playerPed), 3.0)

									for i=1, #players, 1 do
										if players[i] ~= PlayerId() then
				
											if players[i] == data2.current.player then
												foundPlayers = true
												nearbyPlayer = players[i]
												break
											end
										end
									end
				
									if not foundPlayers then
										ESX.ShowNotification('Brak osób w pobliżu!')
										menu2.close()
										return
									end

									TriggerServerEvent('xolax_garages:setOwner', plate, GetPlayerServerId(nearbyPlayer))
								end, function(data2, menu2)
									menu2.close()
								end) 	
							end
						end,
						function(data2,menu2)
							menu2.close()
						end
					)
				else
					ESX.ShowNotification("~r~Nie jesteś właścicielem tego pojazdu!")
				end
			end, plate)
		end,
		function(data,menu)
			menu.close()
		end
	)
end

RegisterNetEvent('garaz')
AddEventHandler('garaz', function()
	local playerPed = GetPlayerPed(-1)
	local vehicle = GetVehiclePedIsIn(playerPed)
	if vehicle ~= 0 then
		local vehicleProps  = ESX.Game.GetVehicleProperties(vehicle)
		local name          = GetDisplayNameFromVehicleModel(vehicleProps.model)
		local plate         = vehicleProps.plate
		local health		= GetVehicleEngineHealth(vehicle)
		if canParkVehicle(playerPed, vehicle) then
			if health > Config.MinimumHealth then
				ESX.TriggerServerCallback('xolax_garages:checkIfVehicleIsOwned', function (owned)
					if owned ~= nil then      
						Citizen.Wait(200)              
						TriggerServerEvent("xolax_garages:updateOwnedVehicle", vehicleProps)
						TaskLeaveVehicle(playerPed, vehicle, 16)
						ESX.Game.DeleteVehicle(vehicle)
					else
						ESX.ShowNotification(_U('not_owner'))
					end
				end, vehicleProps.plate)
			else
				ESX.ShowNotification(_U('repair'))
			end
		else
			ESX.ShowNotification("~r~Pasażerowie muszą opuścić pojazd, bądź musisz siedzieć na miejscu kierowcy.")
		end
	else
		SendNUIMessage({
			clearme = true
		})
		ESX.TriggerServerCallback('xolax_garages:getVehiclesInGarage', function(vehicles)
			ESX.TriggerServerCallback('xolax_garages:getVehiclesInScrap', function(vehicless)
				for i=1, #vehicles, 1 do
					local nazwa
					local nazwa2
					local nazwa3
					if nazwa == nil then
						nazwa = 'white'
						if round(vehicles[i].engineHealth)/10 < 30.99 then
							nazwa = 'red'
						elseif round(vehicles[i].engineHealth)/10 > 31 and round(vehicles[i].engineHealth)/10 < 75.99 then
							nazwa = 'yellow'
						elseif round(vehicles[i].engineHealth)/10 > 76 then
							nazwa = 'green'
						end
					end

					if nazwa2 == nil then
						nazwa2 = 'white'
						if round(vehicles[i].bodyHealth)/10 < 30.99 then
							nazwa2 = 'red'
						elseif round(vehicles[i].bodyHealth)/10 > 31 and round(vehicles[i].bodyHealth)/10 < 75.99 then
							nazwa2 = 'yellow'
						elseif round(vehicles[i].bodyHealth)/10 > 76 then
							nazwa2 = 'green'
						end
					end

					local carname = GetVehicleNameModel(vehicles[i].model)
					SendNUIMessage({
						addcar = true,
						canImpound = true,
						number = i,
						model = vehicles[i].plate,
						name = "<span> Silnik: <font color='..nazwa..'>" .. vehicles[i].engineHealth / 10 .. "%</font> | Karoseria:  <font color='..nazwa2..'>" .. vehicles[i].bodyHealth / 10 .. "%</font> |  Rejestracja:  " .. vehicles[i].plate ..  " ] </span> <font color=#0a0808> Model Pojazdu: </font> " .. carname,
						engine = vehicles[i].engineHealth and math.floor((vehicles[i].engineHealth - 500) / 5) or '??',
						body = vehicles[i].bodyHealth and math.floor(vehicles[i].bodyHealth / 10) or '??'
					})
				end
			end)
		end)
		openGui()
	end
end)

-- Key controls
Citizen.CreateThread(function ()
	while true do
		Citizen.Wait(1)
		if CurrentAction ~= nil then
			if CurrentAction == 'park_car' then
				DisplayHelpText(_U('store_veh'))
			elseif CurrentAction == 'pullout_car' then
				DisplayHelpText(_U('release_veh'))
			elseif CurrentAction == 'tow_menu' then
				DisplayHelpText(_U('tow_veh'))
			elseif CurrentAction == 'police_impound_menu' then
				DisplayHelpText(_U('p_impound_veh'))
			elseif CurrentAction == 'subowner_veh' then
				DisplayHelpText(_U('subowner_veh'))
			elseif CurrentAction == 'scrap_veh' then
				DisplayHelpText('Nacisnij ~INPUT_CONTEXT~, aby zezłomować samochód')
			end

            if IsControlPressed(0, 38) and (GetGameTimer() - GUI.Time) > 300 then
				if CurrentAction == 'park_car' then
					local playerPed = GetPlayerPed(-1)
					local vehicle       = GetVehiclePedIsIn(playerPed)
					local vehicleProps  = ESX.Game.GetVehicleProperties(vehicle)
					local name          = GetDisplayNameFromVehicleModel(vehicleProps.model)
					local plate         = vehicleProps.plate
					local health		= GetVehicleEngineHealth(vehicle)
					if canParkVehicle(playerPed, vehicle) then
						if health > Config.MinimumHealth then
							ESX.TriggerServerCallback('xolax_garages:checkIfVehicleIsOwned', function (owned)
								if owned ~= nil then      
									Citizen.Wait(200)              
									TriggerServerEvent("xolax_garages:updateOwnedVehicle", vehicleProps)
									TaskLeaveVehicle(playerPed, vehicle, 16)
									ESX.Game.DeleteVehicle(vehicle)
								else
									ESX.ShowNotification(_U('not_owner'))
								end
							end, vehicleProps.plate)
						else
							ESX.ShowNotification(_U('repair'))
						end
					else
						ESX.ShowNotification("~r~Pasażerowie muszą opuścić pojazd, bądź musisz siedzieć na miejscu kierowcy.")
					end
				elseif CurrentAction == 'pullout_car' then
					SendNUIMessage({
						clearme = true
					})
                    ESX.TriggerServerCallback('xolax_garages:getVehiclesInGarage', function(vehicles)
						ESX.TriggerServerCallback('xolax_garages:getVehiclesInScrap', function(vehicless)
							for i=1, #vehicles, 1 do
								local nazwa
								local nazwa2
								local nazwa3
								if nazwa == nil then
									nazwa = 'white'
									if round(vehicles[i].engineHealth)/10 < 30.99 then
										nazwa = 'red'
									elseif round(vehicles[i].engineHealth)/10 > 31 and round(vehicles[i].engineHealth)/10 < 75.99 then
										nazwa = 'yellow'
									elseif round(vehicles[i].engineHealth)/10 > 76 then
										nazwa = 'green'
									end
								end
		
								if nazwa2 == nil then
									nazwa2 = 'white'
									if round(vehicles[i].bodyHealth)/10 < 30.99 then
										nazwa2 = 'red'
									elseif round(vehicles[i].bodyHealth)/10 > 31 and round(vehicles[i].bodyHealth)/10 < 75.99 then
										nazwa2 = 'yellow'
									elseif round(vehicles[i].bodyHealth)/10 > 76 then
										nazwa2 = 'green'
									end
								end

								local carname = GetVehicleNameModel(vehicles[i].model)
								SendNUIMessage({
									addcar = true,
									canImpound = true,
									number = i,
									model = vehicles[i].plate,
									name = "<span> Silnik: <font color='..nazwa..'>" .. vehicles[i].engineHealth / 10 .. "%</font> | Karoseria:  <font color='..nazwa2..'>" .. vehicles[i].bodyHealth / 10 .. "%</font> |  Rejestracja:  " .. vehicles[i].plate ..  " ] </span> <font color=#0a0808> Model Pojazdu: </font> " .. carname,
									engine = vehicles[i].engineHealth and math.floor((vehicles[i].engineHealth - 500) / 5) or '??',
									body = vehicles[i].bodyHealth and math.floor(vehicles[i].bodyHealth / 10) or '??'
								})
							end
						end)
					end)
					openGui()
				elseif CurrentAction == 'tow_menu' then
					SendNUIMessage({
						clearimp = true
					})
					ESX.TriggerServerCallback('xolax_garages:getVehiclesToTow', function(vehicles)
						ESX.TriggerServerCallback('xolax_garages:getVehiclesInScrap', function(vehicless)
							local numbers = 0
							for i=1, #vehicles, 1 do
								local carname = GetVehicleNameModel(vehicles[i].model)
								SendNUIMessage({
									impcar = true,
									canImpound = true,
									number = i,
									model = vehicles[i].plate,
									name = "<span> [ Cena Odcholowania: $1000 |  Rejestracja:  " .. vehicles[i].plate ..  " ] </span> <font color=#767676> Model Pojazdu: </font> " ..  carname,
									engine = vehicles[i].engineHealth and math.floor((vehicles[i].engineHealth - 500) / 5) or '??',
									body = vehicles[i].bodyHealth and math.floor(vehicles[i].bodyHealth / 10) or '??'
								})
								numbers = i
							end
							for i=1, #vehicless, 1 do
								local carname = GetVehicleNameModel(vehicless[i].data.model)
								SendNUIMessage({
									impcar = true,
									canImpound = false,
									number = numbers + i,
									model = vehicless[i].data.plate,
									name = "<span> [ Czas do odholowania: "..vehicless[i].scrap_time .."h |  Rejestracja:  " .. vehicless[i].data.plate ..  " ] </span> <font color=#767676> Model Pojazdu: </font> " ..  carname,
								})
							end
						end)
					end)
					openGui()
				elseif CurrentAction == 'police_impound_menu' then
					SendNUIMessage({
						clearpolice = true
					})
					ESX.TriggerServerCallback('xolax_garages:getTakedVehicles', function(vehicles)
						for i=1, #vehicles, 1 do
							local carname = GetVehicleNameModel(vehicles[i].model)
							SendNUIMessage({
								policecar = true,
								number = i,
								model = vehicles[i].plate,
								name = "<span> [ Silnik:  " .. vehicles[i].engineHealth / 10 .. "% Karoseria:  " ..  vehicles[i].bodyHealth / 10 .. "%  Rejestracja:  " .. vehicles[i].plate ..  " ] </span> <font color=#767676> Model Pojazdu: </font> " .. carname,
								engine = vehicles[i].engineHealth and math.floor((vehicles[i].engineHealth - 500) / 5) or '??',
								body = vehicles[i].bodyHealth and math.floor(vehicles[i].bodyHealth / 10) or '??'
							})
						end
					end)
					openGui()
				elseif CurrentAction == 'subowner_veh' then
					if not IsPedInAnyVehicle(GetPlayerPed(-1)) then
						SubownerVehicle()
					end
				elseif CurrentAction == 'scrap_veh' then
					if IsControlPressed(0, 38) and (GetGameTimer() - GUI.Time) > 1000 then
						local playerPed = GetPlayerPed(-1)
						local vehicle       = GetVehiclePedIsIn(playerPed)
						local vehicleProps  = ESX.Game.GetVehicleProperties(vehicle)
						local modelcar = GetDisplayNameFromVehicleModel(vehicleProps.model)
						local plate         = vehicleProps.plate
						local model	= GetEntityModel(vehicle)
						if (GetPedInVehicleSeat(vehicle, -1) == GetPlayerPed(-1)) or IsVehicleSeatFree(vehicle, -1) then
							TriggerServerEvent("xolax_garages:checkScrap", vehicleProps, modelcar, model)
						else
							ScrapCarsMenu()
						end
						CurrentAction = 'scrap_veh'
						GUI.Time      = GetGameTimer()
					end
				end
				CurrentAction = nil
				GUI.Time      = GetGameTimer()
			end
		end
	end
end)

Citizen.CreateThread(function()
	SetNuiFocus(false, false)
end)

-- Open Gui and Focus NUI
function openGui()
	SetNuiFocus(true, true)
	SendNUIMessage({openGarage = true})
end

-- Close Gui and disable NUI
function closeGui()
	SetNuiFocus(false)
	SendNUIMessage({openGarage = false})
end

-- NUI Callback Methods
RegisterNUICallback('close', function(data, cb)
	closeGui()
	cb('ok')
end)

-- NUI Callback Methods
RegisterNUICallback('pullCar', function(data, cb)
	local playerPed  = GetPlayerPed(-1)
	ESX.TriggerServerCallback('xolax_garages:checkIfVehicleIsOwned', function (owned)
		ESX.TriggerServerCallback('xolax_garages:checkIfVehicleIsNotPulled', function (pulled)
			if pulled == '1' then
				ESX.ShowNotification('Nie możesz wyciągnąć tego pojazdu!')
			else 
				local spawnCoords  = {
					x = CurrentGarage.x,
					y = CurrentGarage.y,
					z = CurrentGarage.z,
				}
				ESX.Game.SpawnVehicle(owned.model, spawnCoords, GetEntityHeading(playerPed), function(vehicle)
					TaskWarpPedIntoVehicle(playerPed,  vehicle,  -1)
					ESX.Game.SetVehicleProperties(vehicle, owned)
					SetVehicleEngineHealth(vehicle, owned.engineHealth)
					local localVehPlate = string.lower(GetVehicleNumberPlateText(vehicle))
					local localVehLockStatus = GetVehicleDoorLockStatus(vehicle)
					TriggerEvent("ls:getOwnedVehicle", vehicle, localVehPlate, localVehLockStatus)
					local networkid = NetworkGetNetworkIdFromEntity(vehicle)
					TriggerServerEvent("xolax_garages:removeCarFromParking", owned.plate, networkid)

					ESX.TriggerServerCallback('xolax_garages:getVehiclesNames', function(VehTable)
						for j=1, #VehTable, 1 do
							local VehModel = GetDisplayNameFromVehicleModel(owned.model)
							if VehModel == GetDisplayNameFromVehicleModel(VehTable[j].model) then
								TriggerServerEvent('xolax_logi:wypierdolenieZgarazu', VehModel)
							end
						end
					end)
				end)
			end
		end, data.model)
	end, data.model)
	closeGui()
	cb('ok')
end)

RegisterNUICallback('towCar', function(data, cb)
	closeGui()
	cb('ok')
	if data.can_impound == 'true' then
		ESX.TriggerServerCallback('xolax_garages:towVehicle', function(id)
			if id ~= nil then
				local entity = NetworkGetEntityFromNetworkId(tonumber(id))
				ESX.ShowNotification(_U('checking_veh'))
				Citizen.Wait(math.random(500, 4000))
				if entity == 0 then
					ESX.TriggerServerCallback('xolax_garages:checkMoney', function(hasMoney)
						if hasMoney then
							ESX.ShowNotification(_U('checking_veh'))
							Citizen.Wait(math.random(500, 4000))
							TriggerServerEvent('xolax_garages:pay')
							ESX.ShowNotification(_U('veh_impounded', data.model))
							TriggerServerEvent("xolax_garages:updateState", data.model)
						else
							ESX.ShowNotification(_U('no_money'))
						end
					end)
				elseif entity ~= 0 and (GetVehicleNumberOfPassengers(entity) > 0 or not IsVehicleSeatFree(entity, -1)) then
					ESX.ShowNotification(_U('cant_impound'))
				else
					ESX.TriggerServerCallback('xolax_garages:checkMoney', function(hasMoney)
						if hasMoney then
							TriggerServerEvent('xolax_garages:pay')
							if entity ~= 0 then
								ESX.Game.DeleteVehicle(entity)
							end
							ESX.ShowNotification(_U('veh_impounded', data.model))
							TriggerServerEvent("xolax_garages:updateState", data.model)
						else
							ESX.ShowNotification(_U('no_money'))
						end
					end)
				end
			else
				ESX.TriggerServerCallback('xolax_garages:checkMoney', function(hasMoney)
					if hasMoney then
						ESX.ShowNotification(_U('checking_veh'))
						Citizen.Wait(math.random(500, 4000))
						TriggerServerEvent('xolax_garages:pay')
						ESX.ShowNotification(_U('veh_impounded', data.model))
						TriggerServerEvent("xolax_garages:updateState", data.model)
					else
						ESX.ShowNotification(_U('no_money'))
					end
				end)
			end
		end, data.model)
	else
		ESX.ShowNotification('Nie możesz odholować zezłomowanego pojazdu!')
	end
end)

RegisterNUICallback('impoundCar', function(data, cb)
	closeGui()
	cb('ok')
	local playerPed  = GetPlayerPed(-1)
	ESX.TriggerServerCallback('xolax_garages:checkVehProps', function(veh)
		ESX.ShowNotification(_U('checking_veh'))
		Citizen.Wait(math.random(500, 4000))
		local spawnCoords  = {
			x = CurrentGarage.x,
			y = CurrentGarage.y,
			z = CurrentGarage.z,
		}
		ESX.Game.SpawnVehicle(veh.model, spawnCoords, GetEntityHeading(playerPed), function(vehicle)
			TaskWarpPedIntoVehicle(playerPed,  vehicle,  -1)
			ESX.Game.SetVehicleProperties(vehicle, veh)
			local networkid = NetworkGetNetworkIdFromEntity(vehicle)
			TriggerServerEvent("xolax_garages:removeCarFromPoliceParking", data.model, networkid)
		end)
	end, data.model)
	
end)


function DisplayHelpText(str)
	BeginTextCommandDisplayHelp("STRING")
	AddTextComponentScaleform(str)
	EndTextCommandDisplayHelp(0, 0, 1, -1)
end

AddEventHandler('xolax_garages:hasEnteredMarker', function (zone)
	if zone == 'pullout_car' then
		CurrentAction = 'pullout_car'
	elseif zone == 'park_car' then
		CurrentAction = 'park_car'
	elseif zone == 'impound_veh' then
		CurrentAction = 'tow_menu'
	elseif zone == 'police_impound_veh' then
		CurrentAction = 'police_impound_menu'
	elseif zone == 'subowner_veh' then
		CurrentAction = 'subowner_veh'
	elseif zone == 'scrap_veh' then
		CurrentAction = 'scrap_veh'
	end
end)

AddEventHandler('xolax_garages:hasExitedMarker', function (zone)
  if IsInShopMenu then
    IsInShopMenu = false
    CurrentGarage = nil
  end
  if not IsInShopMenu then
	ESX.UI.Menu.CloseAll()
  end
  CurrentAction = nil
end)

function canParkVehicle(ped, vehicle)
	if GetPedInVehicleSeat(vehicle, -1) ~= ped then
		return false
	end

	local count = 0
	for i = 0, GetVehicleMaxNumberOfPassengers(vehicle), 1 do
		if not IsVehicleSeatFree(vehicle, i) then
			count = count + 1
		end
	end

	return count == 1
end

RegisterNetEvent('xolax_garages:sendScrap')
AddEventHandler('xolax_garages:sendScrap', function()
	local playerPed = GetPlayerPed(-1)
	local vehicle       = GetVehiclePedIsIn(playerPed)
	Citizen.Wait(100)
	TaskLeaveVehicle(playerPed, vehicle, 0)
	Citizen.Wait(2000)
	ESX.Game.DeleteVehicle(vehicle)
end)