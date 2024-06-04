ESX                = nil
local InService    = {}
local MaxInService = {}

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

function GetInServiceCount(name)
	local count = 0

	for k,v in pairs(InService[name]) do
		if v == true then
			count = count + 1
		end
	end

	return count
end

AddEventHandler('esx_service:activateService', function(name, max)
	InService[name]    = {}
	MaxInService[name] = max
end)


local collectedDates = {}

function getPlayersInJob(jobID)
	local onDuty = 0
	local offDuty = 0
	for _, playerId in ipairs(GetPlayers()) do
		local xPlayer = ESX.GetPlayerFromId(playerId)
		local job = xPlayer.getJob()
		local jobName = job.name
		if (jobName == jobID) then
			if (InService[jobID]) then 
				if (InService[jobID][tonumber(playerId)]) then 
					onDuty = onDuty + 1;
				else 
					offDuty = offDuty + 1;
				end 
			end 
		end 
	end 
	return onDuty, offDuty
end 


Citizen.CreateThread(function()
	while true do
		Citizen.Wait(Config.UpdateInterval * 1000) 

		collectedDates = {}

		for _,v in ipairs(Config.Jobs) do 
			onDuty,offDuty = getPlayersInJob(v[1])
			table.insert(collectedDates,{
				inline = true,
				name = "** [".. onDuty+offDuty .."] " .. v[2] .. "**",
				value = [[
					في الخدمة :]] .. onDuty .. [[ 
					خارج الخدمة :]] .. offDuty .. [[
				]]
			})
		end 

		local embed = {
			{
				["color"] = Config.EmbedColor,
				["title"] = Config.title,
				["footer"] = {
					["text"] = os.date("%H:%M  %Y-%m-%d  مركز التوظيف "),
					["icon_url"] = Config.avatarUrl
				},
				["fields"] = collectedDates
			}
		}
		PerformHttpRequest(Config.WebhookUrl.."/messages/"..Config.messageID, function(err, text, headers) end, 'PATCH', json.encode({ avatar_url = Config.avatarUrl, embeds = embed }), { ['Content-Type'] = 'application/json' })
	end
end)

AddEventHandler('onResourceStop', function(resourceName)
	if (GetCurrentResourceName() ~= resourceName) then
	  return
	end
	
	local embed = {
		{
			["color"] = Config.EmbedColor,
			["title"] = Config.title,
			["description"] = "السيرفر أوفلاين 🔴",
		}
	}
	PerformHttpRequest(Config.WebhookUrl.."/messages/"..Config.messageID, function(err, text, headers) end, 'PATCH', json.encode({ avatar_url = Config.avatarUrl, embeds = embed }), { ['Content-Type'] = 'application/json' })


end)


RegisterServerEvent('esx_service:disableService')
AddEventHandler('esx_service:disableService', function(name)
	if (not InService[name]) then 
		InService[name] = {}
	end 
	InService[name][source] = nil
	TriggerEvent('rcore_infinity_activity:disabledService', source, name)

	
end)

RegisterServerEvent('esx_service:notifyAllInService')
AddEventHandler('esx_service:notifyAllInService', function(notification, name)
	for k,v in pairs(InService[name]) do
		if v == true then
			TriggerClientEvent('esx_service:notifyAllInService', k, notification, source)
		end
	end
end)

ESX.RegisterServerCallback('esx_service:enableService', function(source, cb, name)
	if (not InService[name]) then 
		InService[name] = {}
	end 
	
	local inServiceCount = GetInServiceCount(name)

	print(name, "Logged in job..!")
	
	if inServiceCount >= MaxInService[name] then
		cb(false, MaxInService[name], inServiceCount)
	else
		InService[name][source] = true
		TriggerEvent('rcore_infinity_activity:enableService', source, name)
		cb(true, MaxInService[name], inServiceCount)
	end
end)



ESX.RegisterServerCallback('esx_service:isInService', function(source, cb, name)
	local isInService = false

	if InService[name][source] then
		isInService = true
	end

	cb(isInService)
end)

ESX.RegisterServerCallback('esx_service:getInServiceList', function(source, cb, name)
	cb(InService[name])
end)

AddEventHandler('playerDropped', function()
	local _source = source
		
	for k,v in pairs(InService) do
		if v[_source] == true then
			v[_source] = nil
		end
	end
end)