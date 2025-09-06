local TeleportService = game:GetService('TeleportService')
local HttpService = game:GetService('HttpService')
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')

-- 🔄 ÚNICO Webhook (10m+)
local webhook_10m_plus_shadow =
    'https://discord.com/api/webhooks/1411766758431522877/E1kZgZnLxOOQ8lNRzZgDTheeuXbwZaPvWhjiypxozxtpFv6tK4JOOmarG3SqKQkfQvIF'

local placeId = 109983668079237
local MONEY_RANGES = { HIGH = 10000000 }

local visitedServers = {}
local busy = false
local notified = {}

function hopServer()
    local currentJob = game.JobId
    local maxTries = 2
    local tries = 0

    while tries < maxTries do
        tries += 1
        local success, serverInfo = pcall(function()
            return HttpService:JSONDecode(
                game:HttpGet('https://games.roblox.com/v1/games/'.. placeId .. '/servers/Public?sortOrder=Asc&limit=100')
            )
        end)

        if success and serverInfo and serverInfo.data then
            local goodServers = {}
            for _, server in pairs(serverInfo.data) do
                if server.id and server.playing and server.playing < server.maxPlayers and server.playing >= 1 and not visitedServers[server.id] then
                    table.insert(goodServers, server)
                end
            end

            if #goodServers > 0 then
                local randomServer = goodServers[math.random(1, #goodServers)]
                visitedServers[randomServer.id] = true
                if table.getn(visitedServers) > 5 then
                    for id in pairs(visitedServers) do
                        visitedServers[id] = nil
                        break
                    end
                end
                pcall(function()
                    TeleportService:TeleportToPlaceInstance(placeId, randomServer.id, Players.LocalPlayer)
                end)
                return
            end
        end
        task.wait()
    end

    pcall(function()
        TeleportService:TeleportToPlaceInstance(placeId, 'random', Players.LocalPlayer)
    end)
end

function sendNotification(title, desc, color, fields, shouldPing)
    local embed = {
        title = title,
        description = desc,
        color = color or 0xAB8AF2,
        fields = fields,
        timestamp = os.date('!%Y-%m-%dT%H:%M:%S.000Z'),
        footer = { text = 'Made by @kinicki and @joszz :)' },
    }

    local data = HttpService:JSONEncode({ embeds = { embed }, content = shouldPing and '@everyone' or nil })

    spawn(function()
        pcall(function()
            HttpService:PostAsync(
                webhook_10m_plus_shadow,
                data,
                Enum.HttpContentType.ApplicationJson
            )
        end)
    end)
end

function getPlayerCount()
    return string.format('%d/%d', #Players:GetPlayers(), 8)
end

-- 🔥 Siempre hace hop
function notifyBrainrot()
    if busy then return end
    busy = true

    local success, bestBrainrot = pcall(function()
        return findBestBrainrot()
    end)

    if not success or not bestBrainrot then
        busy = false
        hopServer()
        return
    end

    local players = getPlayerCount()
    local jobId = game.JobId or 'Unknown'
    local brainrotKey = jobId .. '_' .. bestBrainrot.name .. '_' .. bestBrainrot.moneyPerSec

    if not notified[brainrotKey] then
        notified[brainrotKey] = true

        local shouldPing = bestBrainrot.numericMPS >= MONEY_RANGES.HIGH
        local fields = {
            { name = '🏷️ Name', value = bestBrainrot.name, inline = true },
            { name = '💰 Money per sec', value = bestBrainrot.moneyPerSec, inline = true },
            { name = '👥 Players', value = players, inline = true },
            { name = '🔗 Join Link', value = '[Click to Join](https://testing5312.github.io/joiner/?placeId=109983668079237&gameInstanceId=' .. jobId .. ')', inline = false },
            { name = 'Job ID (Mobile)', value = '`' .. jobId .. '`', inline = false },
            { name = 'Job ID (PC)', value = '```' .. jobId .. '```', inline = false },
            { name = 'Join Script (PC)', value = '```game:GetService("TeleportService"):TeleportToPlaceInstance(109983668079237,"' .. jobId .. '",game.Players.LocalPlayer)```', inline = false },
        }

        sendNotification('Private Notifier', '', 0xAB8AF2, fields, shouldPing)
        task.wait(1)
        hopServer()
    else
        hopServer()
    end

    busy = false
end

function retryLoop()
    while true do
        task.wait(0.1)
        pcall(notifyBrainrot)
    end
end

spawn(retryLoop)