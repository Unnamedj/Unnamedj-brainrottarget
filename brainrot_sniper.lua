local TeleportService = game:GetService('TeleportService')
local HttpService = game:GetService('HttpService')
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')

-- 🔄 Webhooks actualizadas
local webhook_10m_plus_shadow =
    'https://discord.com/api/webhooks/1411766758431522877/E1kZgZnLxOOQ8lNRzZgDTheeuXbwZaPvWhjiypxozxtpFv6tK4JOOmarG3SqKQkfQvIF'

local webhook_1m_10m_shadow =
    'https://discord.com/api/webhooks/1413284755172102204/pKNnhCRC7XEKc5FM4ROZGLss8c9xgrow1itREK-rfwEUkpL5T4CjEWizulbdUpXVbmiG'

local webhook_fallback_shadow =
    ''

local placeId = 109983668079237
local MIN_MONEY_THRESHOLD = 100000
local MONEY_RANGES = {
    LOW = 1000000,
    HIGH = 10000000,
}

local timeout = 5
local seenServers = {}
local visitedServers = {}
local busy = false
local lastJob = nil
local notified = {}

function hopServer()
    local teleport = game:GetService('TeleportService')
    local players = game:GetService('Players')
    local http = game:GetService('HttpService')

    local currentJob = game.JobId
    local placeId = game.PlaceId

    local maxTries = 2
    local tries = 0

    while tries < maxTries do
        tries = tries + 1

        local success, serverInfo = pcall(function()
            return http:JSONDecode(
                game:HttpGet(
                    'https://games.roblox.com/v1/games/'
                        .. placeId
                        .. '/servers/Public?sortOrder=Asc&limit=100'
                )
            )
        end)

        if success and serverInfo and serverInfo.data then
            local goodServers = {}
            for _, server in pairs(serverInfo.data) do
                if
                    server.id
                    and server.playing
                    and server.playing < server.maxPlayers
                    and server.playing >= 1
                    and not visitedServers[server.id]
                then
                    table.insert(goodServers, server)
                end
            end

            if #goodServers > 0 then
                local randomServer = goodServers[math.random(1, #goodServers)]

                visitedServers[randomServer.id] = true
                local visitedCount = 0
                for _ in pairs(visitedServers) do
                    visitedCount = visitedCount + 1
                end

                if visitedCount > 5 then
                    local oldestServer = nil
                    for serverId in pairs(visitedServers) do
                        if not oldestServer then
                            oldestServer = serverId
                        end
                    end
                    if oldestServer then
                        visitedServers[oldestServer] = nil
                    end
                end

                pcall(function()
                    teleport:TeleportToPlaceInstance(
                        placeId,
                        randomServer.id,
                        players.LocalPlayer
                    )
                end)
                return
            end
        end
        wait(0)
    end

    pcall(function()
        teleport:TeleportToPlaceInstance(placeId, 'random', players.LocalPlayer)
    end)
end

function getWebhookForMoney(moneyNum)
    if moneyNum >= MONEY_RANGES.HIGH then
        return { webhook_10m_plus_shadow }
    elseif moneyNum >= MONEY_RANGES.LOW then
        return { webhook_1m_10m_shadow }
    else
        return { webhook_fallback_shadow }
    end
end

function sendNotification(title, desc, color, fields, webhookUrls, shouldPing)
    local http = game:GetService('HttpService')

    local embed = {
        title = title,
        description = desc,
        color = color or 0xAB8AF2,
        fields = fields,
        timestamp = os.date('!%Y-%m-%dT%H:%M:%S.000Z'),
        footer = {
            text = 'Made by @kinicki and @joszz :)',
        },
    }

    local data = { embeds = { embed } }
    if shouldPing then
        data.content = '@everyone'
    end

    for _, webhookUrl in pairs(webhookUrls) do
        spawn(function()
            pcall(function()
                request({
                    Url = webhookUrl,
                    Method = 'POST',
                    Headers = { ['Content-Type'] = 'application/json' },
                    Body = http:JSONEncode(data),
                })
            end)
        end)
    end
end

local function parseMoney(text)
    local num = text:match('([%d%.]+)')
    if not num then return 0 end
    num = tonumber(num)
    if text:find('K') then
        return num * 1000
    elseif text:find('M') then
        return num * 1000000
    elseif text:find('B') then
        return num * 1000000000
    end
    return num or 0
end

function getPlayerCount()
    local players = game:GetService('Players')
    local count = #players:GetPlayers()
    local max = game.PlaceId and 8 or 8
    return string.format('%d/%d', count, max)
end

-- 🔥 Siempre hace hop
function notifyBrainrot()
    if busy then return end
    busy = true

    local success, bestBrainrot = pcall(function()
        return findBestBrainrot()
    end)

    if not success then
        busy = false
        hopServer()
        return
    end

    if bestBrainrot then
        local players = getPlayerCount()
        local jobId = game.JobId or 'Unknown'
        local brainrotKey = jobId .. '_' .. bestBrainrot.name .. '_' .. bestBrainrot.moneyPerSec

        if not notified[brainrotKey] then
            notified[brainrotKey] = true
            lastJob = jobId

            local targetWebhooks = getWebhookForMoney(bestBrainrot.numericMPS)
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

            sendNotification('Private Notifier', '', 0xAB8AF2, fields, targetWebhooks, shouldPing)
            wait(1)
            hopServer()
        else
            hopServer()
        end
    else
        hopServer()
    end

    busy = false
end

function retryLoop()
    while true do
        wait(0.1)
        pcall(notifyBrainrot)
    end
end

spawn(retryLoop)