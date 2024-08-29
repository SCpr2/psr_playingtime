local string_format = string.format
local ESX = exports['es_extended']:getSharedObject()
local playerIdServer = {}
local WebhookChannel = "https://discord.com/api/webhooks/" --ISI WEBHOOK DISINI

local function SecondsToClock(seconds)
    if seconds ~= nil then
        local seconds = tonumber(seconds)

        if seconds <= 0 then
            return "00:00:00";
        else
            hours = string_format("%02.f", math.floor(seconds/3600));
            mins = string_format("%02.f", math.floor(seconds/60 - (hours*60)));
            secs = string_format("%02.f", math.floor(seconds - hours*3600 - mins *60));
            return 'Hours:' ..hours.." Mins:"..mins.." Secs:"..secs
        end
    end
end

local function SendToWebhook(tittle, desc)
	local embedsHook = {
		{
			title = tittle,
			description = desc,
			fields = {
				{name = "**STATUS EVENT**", value = 'SEDANG BERLANGSUNG', inline = true},
                {name = "**THANKS TO**", value = 'TEAM', inline = true}
			},
			color = 65280
		}
	}

    PerformHttpRequest(WebhookChannel, function(err, text, headers) end, 'POST', json.encode({username = '(PLAYING TIME)', embeds = embedsHook, avatar_url = ''}), { ['Content-Type'] = 'application/json' })
end

MySQL.ready(function()
    MySQL.query('SELECT `identifier`, `time`, `name` FROM `playtime` ORDER BY `time` DESC LIMIT 10', {}, function(response)
        if response then
            local sendTittleToWebhook = ''
            for i = 1, #response do
                local row = response[i]
                sendTittleToWebhook = sendTittleToWebhook.. '```' ..i.. '.'..row.identifier.. '\n Nama IC: ' ..row.name.. ' \n'..SecondsToClock(row.time).. '```\n'
            end
            SendToWebhook('TOP PLAYING TIME', sendTittleToWebhook)
        end
    end)
end)

local function InitTimes(_source)
    local identifier = GetPlayerIdentifiers(_source)[1]
    local Players = ESX.GetPlayerFromId(_source)
    local row = MySQL.single.await('SELECT `time` FROM `playtime` WHERE `identifier` = ? LIMIT 1', {
        identifier
    })

    if row then
        playerIdServer[_source] = {
            time = row.time
        }
    else
        playerIdServer[_source] = {
            time = 0
        }
        MySQL.insert('INSERT INTO `playtime` (identifier, time, name) VALUES (?, ?, ?)', {
            identifier, 0, Players.getName()
        }, function(id)
            -- print(id)
        end)
    end
end

local function UpdatePlayTime(_source)
    if playerIdServer[_source] then
        local Players = ESX.GetPlayerFromId(_source)
        local identifier = GetPlayerIdentifiers(_source)[1]
        local timeSet = playerIdServer[_source].time
        MySQL.update('UPDATE playtime SET time = ?, name = ? WHERE identifier = ?', {
            timeSet, Players.getName(), identifier
        }, function(affectedRows)
            -- print('Update Time Playing : ', affectedRows)
        end)
    end
end

--################################################--
-------------------START DEBUG----------------------
--################################################--
--RegisterCommand('timeset', function(source)
--    InitTimes(source)
--end, false)

--RegisterCommand('timeupdate', function(source)
--	UpdatePlayTime(source)
--end, false)
--################################################--
-------------------END DEBUG----------------------
--################################################--

lib.addCommand('sendplayingtime', {
    help = "Update Webhook PlayTime",
    params = nil,
    restricted = 'group.admin'
}, function(source, args, raw)
    MySQL.query('SELECT `identifier`, `time`, `name` FROM `playtime` ORDER BY `time` DESC LIMIT 10', {}, function(response)
        if response then
            local sendTittleToWebhook = ''
            for i = 1, #response do
                local row = response[i]
                sendTittleToWebhook = sendTittleToWebhook.. '```' ..i.. '.'..row.identifier.. '\n Nama IC: ' ..row.name.. ' \n'..SecondsToClock(row.time).. '```\n'
            end
            SendToWebhook('TOP PLAYING TIME', sendTittleToWebhook)
        end
    end)
end)


RegisterNetEvent('esx:playerLoaded', function(playerId)
    -- print(playerId, 'set time loaded')
    InitTimes(playerId)
end)

AddEventHandler('esx:playerDropped', function(playerid)
    -- print('update player time dropped:  ', playerid)
	UpdatePlayTime(playerid)
    playerIdServer[playerid] = nil
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == cache.resource then
        for source in pairs(playerIdServer) do
            UpdatePlayTime(source)
        end
    end
end)

--untuk pause time jika player tersebut dalam zona AFK/Posisi AFK
--isi code disini
local function PlayerNotInAFK(src)
    -- local notAFK = Player(src).state.notInAFK
    -- if notAFK then
    --     return true
    -- end
    -- return false
    return true
end

local function PlayTimesPlus()
    for source in pairs(playerIdServer) do
        if playerIdServer[source] and PlayerNotInAFK(source) then
            playerIdServer[source].time = playerIdServer[source].time + 60
        end
    end
    SetTimeout(60000, PlayTimesPlus)
end

CreateThread(function()
    PlayTimesPlus()
end)
