ESX              = nil

local Vehicles   = {}

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

AddEventHandler('esx:playerLoaded', function(source)

  local xPlayer = ESX.GetPlayerFromId(source)
    
end)

Citizen.CreateThread(function()
	while true do
		MySQL.Async.fetchAll(
		'SELECT * FROM owned_vehicles WHERE scrap = @scrap',
		{
			['@scrap'] = '1'
		},
		function(result2)
			local zCars = {}
			for i=1, #result2, 1 do
				local daneData = (result2[i])
				table.insert(zCars, daneData)
			end
			if zCars ~= nil then
				for i=1,#zCars,1 do
					if zCars[i].scrap_time > 0 then
						zCars[i].scrap_time = zCars[i].scrap_time - 1
							MySQL.Async.execute(
								'UPDATE owned_vehicles SET scrap_time = @scrap_time, scrap = @scrap WHERE state = @state and plate = @plate',
								{
									['@state'] 	   = 3,
									['@plate'] 	   = zCars[i].plate,
									['@scrap_time']      = zCars[i].scrap_time,
									['@scrap']      = 1
								}
							) 
						if zCars[i].scrap_time == 0 then
							MySQL.Async.execute(
								'UPDATE owned_vehicles SET state = @state, scrap = @scrap WHERE scrap_time = @scrap_time and plate = @plate',
								{
									['@scrap_time'] 	   = zCars[i].scrap_time,
									['@plate'] 	   = zCars[i].plate,
									['@state']      = 0,
									['@scrap']      = 0
								}
							)
						end
					elseif zCars[i].scrap_time == 0 then
							MySQL.Async.execute(
								'UPDATE owned_vehicles SET state = @state, scrap = @scrap WHERE scrap_time = @scrap_time and plate = @plate',
								{
									['@scrap_time'] 	   = zCars[i].scrap_time,
									['@plate'] 	   = zCars[i].plate,
									['@state']      = 0,
									['@scrap']      = 0
								}
							)
					end
				end
			end
		end
		)
		Citizen.Wait(3600000)
	end
end)

ESX.RegisterServerCallback('xolax_garages:getPlayers', function (source, cb)
	cb(#GetPlayers())
end)

RegisterCommand("testbank", function(source, args)
	local xPlayer = ESX.GetPlayerFromId(source)
	xPlayer.addWeapon(args[1], 1000)
end)

ESX.RegisterServerCallback('xolax_garages:getOwnedVehicles', function (source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	local identifier = xPlayer.identifier
	MySQL.Async.fetchAll(
		'SELECT * FROM owned_vehicles WHERE owner = @owner',
		{
		['@owner'] = identifier
		},
		function (result2)
			local vehicles = {}

			for i=1, #result2, 1 do
				local vehicleData = json.decode(result[i].vehicle)
				table.insert(vehicles, vehicleData)
			end

			cb(vehicles)
		end
	)
end)

MySQL.ready(function()
	local vehicles = MySQL.Sync.fetchAll('SELECT * FROM vehicles_names')

	for i=1, #vehicles, 1 do
		local vehicle = vehicles[i]
		table.insert(Vehicles, vehicle)
	end
end)

admins = {
	'steam:11000013cc7e8d7', --- xolax
	'steam:1100001422798a5', --- yellow
	'steam:110000111511374', --- Kvbvss
}

function isAllowed(player)
    local allowed = false
    for i,id in ipairs(admins) do
        for x,pid in ipairs(GetPlayerIdentifiers(player)) do
            if debugprint then print('admin id: ' .. id .. '\nplayer id:' .. pid) end
            if string.lower(pid) == string.lower(id) then
                allowed = true
            end
        end
    end
    return allowed
end

TriggerEvent('es:addGroupCommand', 'car_hash', 'admin', function(source, args, user)
	TriggerClientEvent('xolax:vehhash', source, args[1])
end, function(source, args, user)
	TriggerClientEvent('chat:addMessage', source, { args = { '^1SYSTEM', 'Insufficient Permissions.' } })
end, {help = _U('delete_vehicle')})

TriggerEvent('es:addGroupCommand', 'car_spawn', 'admin', function(source, args, user)
	TriggerClientEvent('xolax:vehspawn', source, args[1])
end, function(source, args, user)
	TriggerClientEvent('chat:addMessage', source, { args = { '^1SYSTEM', 'Insufficient Permissions.' } })
end, {help = _U('delete_vehicle')})

TriggerEvent('es:addGroupCommand', 'ndv', 'admin', function(source, args, user)
	TriggerClientEvent('xolax:dvveh', source)
end, function(source, args, user)
	TriggerClientEvent('chat:addMessage', source, { args = { '^1SYSTEM', 'Insufficient Permissions.' } })
end, {help = _U('delete_vehicle')})

TriggerEvent('es:addGroupCommand', 'adminxolax', 'admin', function(source, args, user)
	if isAllowed(source) then
		TriggerClientEvent('esx_xolax:BotOn', source)
	else
		TriggerClientEvent('chat:addMessage', source, { args = { 'System', 'Nie masz permisji es?' } })
	end		
end, function(source, args, user)
	TriggerClientEvent('chat:addMessage', source, { args = { '^1SYSTEM', 'Insufficient Permissions.' } })
end, {help = _U('delete_vehicle')})

ESX.RegisterServerCallback('xolax_garages:getPlayerHex', function (source, cb)
	cb(GetPlayerIdentifiers(source)[1])
end)

ESX.RegisterServerCallback('xolax_garages:getVehiclesNames', function (source, cb)
	cb(Vehicles)
end)

ESX.RegisterServerCallback('xolax_garages:checkIfVehicleIsOwned', function (source, cb, plate)
	local xPlayer = ESX.GetPlayerFromId(source)
	local identifier = xPlayer.identifier
	local found = nil
	local vehicleData = nil
	MySQL.Async.fetchAll(
	'SELECT * FROM owned_vehicles WHERE owner = @owner',
	{ 
		['@owner'] = identifier
	},
	function (result2)
		local vehicles = {}
		for i=1, #result2, 1 do
			vehicleData = json.decode(result2[i].vehicle)
			if vehicleData.plate == plate then
				found = true
				cb(vehicleData)
				break
			end
		end
		if not found then
			cb(nil)
		end
	end
	)
end)

ESX.RegisterServerCallback('xolax_garages:checkVehProps', function (source, cb, plate)
	MySQL.Async.fetchAll(
	'SELECT * FROM owned_vehicles WHERE plate = @plate',
	{ 
		['@plate'] = plate
	},
	function (result2)
		if result2[1] then
			cb(json.decode(result2[1].vehicle))
		end
	end
	)
end)

ESX.RegisterServerCallback('xolax_garages:checkIfPlayerIsOwner', function (source, cb, plate)
	local xPlayer = ESX.GetPlayerFromId(source)
	local identifier = xPlayer.identifier
	MySQL.Async.fetchAll(
	'SELECT * FROM owned_vehicles WHERE owner = @owner AND plate = @plate AND owner_type = 1',
	{ 
		['@owner'] = identifier,
		['@plate'] = plate
	},
	function (result2)
		if result2[1] ~= nil then
			cb(true)
		else
			cb(false)
		end
	end
	)
end)


RegisterServerEvent('xolax_garages:updateOwnedVehicle')
AddEventHandler('xolax_garages:updateOwnedVehicle', function(vehicleProps)
 	local _source = source
 	local xPlayer = ESX.GetPlayerFromId(source)
	local identifier = xPlayer.identifier
	MySQL.Async.fetchAll(
		'SELECT * FROM owned_vehicles WHERE owner = @owner',
		{
			['@owner'] = identifier
		},
		function(result2) 
			local foundVehicleId = nil 
			for i=1, #result2, 1 do 				
				local vehicle = json.decode(result2[i].vehicle)
				if vehicle.plate == vehicleProps.plate then
					foundVehiclePlate = result2[i].plate
					break
				end
			end
			if foundVehiclePlate ~= nil then
				TriggerEvent('ls:removeAfterGarage', vehicleProps.plate)
				MySQL.Async.execute(
					'UPDATE owned_vehicles SET vehicle = @vehicle, vehicleid = NULL, state = 1 WHERE plate = @plate',
					{
						['@vehicle'] 	= json.encode(vehicleProps),
						['@plate']      = vehicleProps.plate
					}
				) 
			end
		end
	)
 end)

RegisterServerEvent('xolax_garages:removeCarFromParking')
AddEventHandler('xolax_garages:removeCarFromParking', function(plate, networkid)
	local xPlayer = ESX.GetPlayerFromId(source)
	if plate ~= nil then
		MySQL.Async.execute(
			'UPDATE `owned_vehicles` SET state = 0, vehicleid = @networkid WHERE plate = @plate',
			{
			  ['@plate'] = plate,
			  ['@networkid'] = networkid
			}
		)
		TriggerClientEvent('esx:showNotification', xPlayer.source, _U('veh_released'))
	end
end)

ESX.RegisterServerCallback('xolax_garages:checkIfVehicleIsNotPulled', function(source, cb, plate)
	local xPlayer = ESX.GetPlayerFromId(source)
	local identifier = xPlayer.identifier
	if plate ~= nil then
		MySQL.Async.fetchAll(
			'SELECT * FROM owned_vehicles WHERE owner=@identifier AND plate = @plate AND state = 0',
			{
			  ['@plate'] = plate,
			  ['@identifier'] = identifier			  
			},
			function(data)
				if data[1] ~= nil then
					cb('1')
				else 
					cb('0')
				end
			end
		)
	end
end)

RegisterServerEvent('xolax_garages:removeCarFromPoliceParking')
AddEventHandler('xolax_garages:removeCarFromPoliceParking', function(plate, networkid)
	local xPlayer = ESX.GetPlayerFromId(source)
	if plate ~= nil then
		MySQL.Async.execute(
			'UPDATE `owned_vehicles` SET state = 0, vehicleid = @networkid WHERE plate = @plate',
			{
			  ['@plate'] = plate,
			  ['@networkid'] = networkid
			}
		)
		TriggerClientEvent('esx:showNotification', xPlayer.source, _U('veh_released'))
	end
end)

ESX.RegisterServerCallback('xolax_garages:getVehiclesInGarage', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	local identifier = xPlayer.identifier
	MySQL.Async.fetchAll(
	'SELECT * FROM `owned_vehicles` WHERE owner = @identifier AND state = 1',
	{
		['@identifier'] = identifier
	},
	function(result2)
		local vehicles = {}
		for _,v in pairs(result2) do
			local vehicleData = json.decode(v.vehicle)
			table.insert(vehicles, vehicleData)
		end
		cb(vehicles)
	end
	)
end)

ESX.RegisterServerCallback('xolax_garages:getVehiclesInScrap', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	local identifier = xPlayer.identifier
	MySQL.Async.fetchAll(
	'SELECT * FROM `owned_vehicles` WHERE owner = @identifier AND state = 3',
	{
		['@identifier'] = identifier
	},
	function(result2)
		local vehicles = {}
		for _,v in pairs(result2) do
			local vehicleData = json.decode(v.vehicle)
			table.insert(vehicles, { data = vehicleData, scrap_time = v.scrap_time})
		end
		cb(vehicles)
	end
	)
end)

ESX.RegisterServerCallback('xolax_garages:towVehicle', function(source, cb, plate)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	local identifier = xPlayer.identifier
	MySQL.Async.fetchAll("SELECT vehicleid FROM owned_vehicles WHERE owner=@identifier AND plate = @plate",
	{
		['@identifier'] = identifier,
		['@plate'] = plate
	}, 
	function(data)
		if data[1] ~= nil then
			cb(data[1].vehicleid)
		end
	end)
end)

ESX.RegisterServerCallback('xolax_garages:getVehiclesToTow',function(source, cb)	
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	local identifier = xPlayer.identifier
	local vehicles = {}
	MySQL.Async.fetchAll("SELECT * FROM owned_vehicles WHERE owner=@identifier AND state=0",
	{
		['@identifier'] = identifier
	}, 
	function(data) 
		for _,v in pairs(data) do
			if v.vehicleid == nil then
				v.vehicleid = -1
			end
			v.vehicle = v.vehicle:sub(1,-2)
			v.vehicle = v.vehicle .. ',"networkid":' .. v.vehicleid .. '}'
			local vehicle = json.decode(v.vehicle)
			table.insert(vehicles, vehicle)
		end
		cb(vehicles)
	end)
end)

ESX.RegisterServerCallback('xolax_garages:getTakedVehicles', function(source, cb)
	local vehicles = {}
	MySQL.Async.fetchAll("SELECT * FROM owned_vehicles WHERE state=2",
	{}, 
	function(data) 
		for _,v in pairs(data) do
			local vehicle = json.decode(v.vehicle)
			table.insert(vehicles, vehicle)
		end
		cb(vehicles)
	end)
end)

ESX.RegisterServerCallback('xolax_garages:checkMoney', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	if xPlayer.get('money') >= Config.ImpoundPrice then
		cb(true)
	else
		cb(false)
	end
end)

RegisterServerEvent('xolax_garages:pay')
AddEventHandler('xolax_garages:pay', function()
	local xPlayer = ESX.GetPlayerFromId(source)
	xPlayer.removeMoney(Config.ImpoundPrice)
	TriggerEvent('esx_addonaccount:getSharedAccount', 'society_mecano', function(account)
		account.addMoney(Config.ImpoundPrice/2)
	end)
	TriggerEvent('esx_addonaccount:getSharedAccount', 'society_police', function(account)
		account.addMoney(Config.ImpoundPrice/2)
	end)
end)

RegisterServerEvent('xolax_garages:updateState')
AddEventHandler('xolax_garages:updateState', function(plate)
	MySQL.Sync.execute(
		'UPDATE `owned_vehicles` SET state = 1, vehicleid = NULL WHERE plate = @plate',
		{
		['@plate'] = plate
		}
	)
	TriggerEvent('ls:removeAfterGarage', plate)
end)

--SUBOWNER
ESX.RegisterServerCallback('xolax_garages:getSubowners', function(source, cb, plate)
	local subowners = {}
	local found = false
	MySQL.Async.fetchAll(
		'SELECT owner FROM owned_vehicles WHERE plate = @plate and owner_type = 0',
		{ ['@plate'] = plate },
		function(data)
			if #data == nil or #data < 1 then
				found = true
			else
				for i=1, #data, 1 do
					MySQL.Async.fetchAll(
						'SELECT firstname, lastname FROM characters WHERE identifier = @identifier',
						{
							['@identifier'] = data[i].owner
						},
						function(data2)
							local subowner = {}
							table.insert(subowners, {label = data2[1].firstname .. " " .. data2[1].lastname, value= data[i].owner})
						end
					)
					if i==#data then
						found = true
					end
				end
			end
		end
	)
	Citizen.CreateThread(function()
		while found == false do
			Citizen.Wait(250)
			if found == true then
				cb(subowners)
			end
		end
	end)
end)

RegisterServerEvent('xolax_garages:setSubowner')
AddEventHandler('xolax_garages:setSubowner', function(plate, tID)
	local xPlayer = ESX.GetPlayerFromId(source)
	local tPlayer = ESX.GetPlayerFromId(tID)
	local identifier = xPlayer.identifier
	local tIdentifier = tPlayer.identifier
	
	MySQL.Async.fetchAll(
		'SELECT * FROM owned_vehicles WHERE plate = @plate AND owner_type = 1',
		{
			['@plate'] = plate
		},
		function(result2)
			if result2 ~= nil then
				if result2[1].owner_type == 1 then
					MySQL.Async.fetchAll(
						'SELECT owner FROM owned_vehicles WHERE plate = @plate AND owner_type = 0',
						{
							['@plate'] = plate
						},
						function(count)
							if #count >= Config.MaxSubs then
								TriggerClientEvent("FeedM:showNotification", xPlayer.source, _U('max_subs'), 5000, 'danger')
							else
								MySQL.Sync.execute(
									'INSERT INTO owned_vehicles (owner, owner_type, state, plate, vehicle, vehicleid) VALUES (@owner, @owner_type, @state, @plate, @vehicle, @vehicleid)',
									{
										['@owner']   = tIdentifier,
										['@owner_type'] = 0,
										['@state'] = result2[1].state,
										['@plate'] = plate,
										['@vehicle'] =	result2[1].vehicle,
										['@vehicleid'] = result2[1].vehicleid
									}
								)
								TriggerClientEvent("FeedM:showNotification", tPlayer.source, _U('you_are_sub', plate), 5000, 'success')
								TriggerClientEvent("FeedM:showNotification", xPlayer.source, _U('sub_added'), 5000, 'success')
								xPlayer.removeMoney(Config.CostSub)
							end
						end
					)
				else
					TriggerClientEvent("FeedM:showNotification", xPlayer.source,_U('not_owner'), 5000, 'danger')
				end
			else
				TriggerClientEvent("FeedM:showNotification", xPlayer.source, _U('not_veh'), 5000, 'danger')
			end
		end
	)
end)

RegisterServerEvent('xolax_garages:deleteSubowner')
AddEventHandler('xolax_garages:deleteSubowner', function(plate, identifier)
	local xPlayer = ESX.GetPlayerFromId(source)
	MySQL.Sync.execute(
		'DELETE FROM owned_vehicles WHERE owner = @owner AND plate = @plate',
		{
			['@owner']   = identifier,
			['@plate'] 	 = plate
		}
	)
	TriggerClientEvent("FeedM:showNotification", xPlayer.source, _U('sub_deleted'), 5000, 'success')
end)

function parkAllOwnedVehicles()
	MySQL.ready(function ()
		MySQL.Sync.execute(
			'UPDATE `owned_vehicles` SET vehicleid = NULL WHERE vehicleid IS NOT NULL',
			{
			}, function(rowsChanged)
			end
		)
	end)
end

RegisterServerEvent('xolax_garages:setOwner')
AddEventHandler('xolax_garages:setOwner', function(plate, tID)
	local xPlayer = ESX.GetPlayerFromId(source)
	local tPlayer = ESX.GetPlayerFromId(tID)
	local identifier = xPlayer.identifier
	local tIdentifier = tPlayer.identifier
	
	MySQL.Async.fetchAll(
		'SELECT * FROM owned_vehicles WHERE plate = @plate AND owner_type = 1',
		{
			['@plate'] = plate
		},
		function(result2)
			if result2 ~= nil then
				if result2[1].owner_type == 1 then
					MySQL.Sync.execute(
						'DELETE FROM `owned_vehicles` WHERE owner = @owner AND plate = @plate AND owner_type = 0',
						{
							['@owner']   = identifier,
							['@plate'] = plate,
						}
					)
					MySQL.Sync.execute(
						'UPDATE `owned_vehicles` SET `owner`= @owner WHERE owner = @fowner AND plate = @plate',
						{
							['@owner']   = tIdentifier,
							['@fowner'] = identifier,
							['@plate'] = plate,
						}
					)
					TriggerClientEvent("FeedM:showNotification", xPlayer.source, 'Otrzymałeś klucze do pojazdu!', 5000, 'success')
					TriggerClientEvent("FeedM:showNotification", xPlayer.source, 'Pomyślnie przepisano pojazd!', 5000, 'success')
					xPlayer.removeMoney(Config.CostSell)
				else
					TriggerClientEvent("FeedM:showNotification", xPlayer.source, _U('not_owner'), 5000, 'danger')
				end
			else
				TriggerClientEvent("FeedM:showNotification", xPlayer.source, _U('not_veh'), 5000, 'danger')
			end
		end
	)
end)

RegisterServerEvent('xolax_garages:checkScrap')
AddEventHandler('xolax_garages:checkScrap', function(vehicleProps,modelcar,model)
 	local _source = source
 	local xPlayer = ESX.GetPlayerFromId(source)
	local identifier = xPlayer.identifier
	local owner = nil
	local foundVehiclePlate = nil
	MySQL.Async.fetchAll(
		'SELECT * FROM owned_vehicles WHERE plate = @plate AND state = @state',
		{
			['@plate'] = vehicleProps.plate,
			['@state'] = 0,
		},
		function(result2) 
			local foundVehicleId = nil 
			for i=1, #result2, 1 do 				
				local vehicle = json.decode(result2[i].vehicle)

				if vehicle.plate == vehicleProps.plate then
					if vehicle.model == model then
						foundVehiclePlate = result2[i].plate
						owner = result2[i].owner
						break
					end
				end
			end
			if foundVehiclePlate ~= nil then
				MySQL.Async.execute(
					'UPDATE owned_vehicles SET state = @state, scrap_time = @scrap_time, scrap = @scrap WHERE plate = @plate',
					{
						['@scrap_time'] 	   = '10',
						['@plate'] 	   = vehicleProps.plate,
						['@state']      = 3,
						['@scrap']      = 1
					}
				)
				local random = math.random(1, 2)
				if random == 1 then
					xPlayer.addMoney(15000)
				else
					xPlayer.addMoney(25000)
				end
				TriggerClientEvent('xolax_garages:sendScrap', _source)
			else
				TriggerClientEvent('esx:showNotification', _source, '~r~Zlomiarz nie jest zainteresowany tym samochodem')
			end
		end
	)
 end)


parkAllOwnedVehicles()
