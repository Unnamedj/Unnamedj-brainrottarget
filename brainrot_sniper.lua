local TeleportService = game:GetService('TeleportService')
local HttpService = game:GetService('HttpService')
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')

local webhook_50m_plus_shadow = "https://discord.com/api/webhooks/1414033069773553675/THLoMraxSLBskloDJ22gFFihlgBLgg6bQy6HYrR0m4HgY_Zx5DR-HQJrKKHcFwmFrm-M"

local webhook_10m_plus_shadow =
    'https://discord.com/api/webhooks/1411766758431522877/E1kZgZnLxOOQ8lNRzZgDTheeuXbwZaPvWhjiypxozxtpFv6tK4JOOmarG3SqKQkfQvIF'

local webhook_1m_10m_shadow =
    ''

local webhook_fallback_shadow =
    ''

local placeId = 109983668079237
local MIN_MONEY_THRESHOLD = 100000
local MONEY_RANGES = {
    LOW = 1000000,
    MID = 10000000,
    HIGH = 50000000,
}

local timeout = 5
local seenServers = {}
local visitedServers = {}
local busy = false
local lastJob = nil
local notified = {}

local SPECIAL_PETS = {
    "Nuclearo Dinossauro",
    "Strawberry Elephant",
    "Dragon Cannelloni"
}

function checkSpecialPets()
    if not workspace or not workspace.Plots then
        return nil
    end

    for _, plot in pairs(workspace.Plots:GetChildren()) do
        for _, specialName in pairs(SPECIAL_PETS) do
            local petModel = plot:FindFirstChild(specialName)
            if petModel then
                return {
                    name = specialName,
                    playerCount = getPlayerCount(),
                    jobId = game.JobId or "Unknown",
                }
            end
        end
    end

    return nil
end

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
        
        return { webhook_50m_plus_shadow }
    elseif moneyNum >= MONEY_RANGES.MID then
        
        return { webhook_10m_plus_shadow }
    else
        
        return { webhook_fallback_shadow }
    end
end

function sendMessage(msg, webhookUrl)
    local http = game:GetService('HttpService')
    local payload = http:JSONEncode({ content = msg })

    local targetWebhook = webhookUrl or webhook_fallback_shadow

    request({
        Url = targetWebhook,
        Method = 'POST',
        Headers = { ['Content-Type'] = 'application/json' },
        Body = payload,
    })
end

function sendDiscordEmbed(title, desc, color, fields, webhookUrl, shouldPing)
    local http = game:GetService('HttpService')

    local embed = {
        title = title,
        description = desc,
        color = color or 0xAB8AF2,
        fields = fields,
        timestamp = os.date('!%Y-%m-%dT%H:%M:%S.000Z'),
        footer = {
            text = 'Made by da huzz (jk by @kinicki and modified by T) :)',
        },
    }

    local data = {
        embeds = { embed },
    }

    if shouldPing then
        data.content = '@everyone'
    end

    local targetWebhook = webhookUrl or webhook_fallback_shadow

    spawn(function()
        pcall(function()
            request({
                Url = targetWebhook,
                Method = 'POST',
                Headers = { ['Content-Type'] = 'application/json' },
                Body = http:JSONEncode(data),
            })
        end)
    end)
end

function sendNotification(
    title,
    desc,
    color,
    fields,
    webhookUrls,
    shouldPing
)
    local http = game:GetService('HttpService')

    local embed = {
        title = title,
        description = desc,
        color = color or 0xAB8AF2,
        fields = fields,
        timestamp = os.date('!%Y-%m-%dT%H:%M:%S.000Z'),
        footer = {
            text = 'Made by da huzz (jk by @kinicki and modified by T) :)',
        },
    }

    local data = {
        embeds = { embed },
    }

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

function sendEmbeds(embeds, webhookUrl)
    local http = game:GetService('HttpService')

    local data = {
        embeds = embeds,
    }

    local targetWebhook = webhookUrl or webhook_fallback_shadow

    request({
        Url = targetWebhook,
        Method = 'POST',
        Headers = { ['Content-Type'] = 'application/json' },
        Body = http:JSONEncode(data),
    })
end

local function parseMoney(text)
    local num = text:match('([%d%.]+)')
    if not num then
        return 0
    end
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

function formatMoneyDisplay(moneyNum)
    if moneyNum >= 1000000000 then
        local result = '$'
            .. string.format('%.1f', moneyNum / 1000000000)
            .. 'b/s'
        return result
    elseif moneyNum >= 1000000 then
        local result = '$' .. string.format('%.1f', moneyNum / 1000000) .. 'm/s'
        return result
    elseif moneyNum >= 1000 then
        local result = '$' .. string.format('%.1f', moneyNum / 1000) .. 'k/s'
        return result
    else
        local result = '$' .. tostring(moneyNum) .. '/s'
        return result
    end
end

function getPlayerCount()
    local players = game:GetService('Players')
    local count = #players:GetPlayers()
    local max = game.PlaceId and 8 or 8
    return string.format('%d/%d', count, max)
end

function findBestBrainrot()
    if not workspace or not workspace.Plots then
        return nil
    end

    local bestBrainrot, bestValue = nil, 0
    local playerCount = #game:GetService('Players'):GetPlayers()

    local function processBrainrotOverhead(overhead)
        if not overhead then
            return
        end

        local brainrotData = {
            name = 'Unknown',
            moneyPerSec = '$0/s',
            value = '$0',
            playerCount = playerCount,
        }

        for _, label in pairs(overhead:GetChildren()) do
            if label:IsA('TextLabel') then
                local text = label.Text
                if text:find('/s') then
                    brainrotData.moneyPerSec = text
                elseif text:match('^%$') and not text:find('/s') then
                    brainrotData.value = text
                else
                    brainrotData.name = text
                end
            end
        end

        local numericValue = parseMoney(brainrotData.moneyPerSec)
        if numericValue >= MIN_MONEY_THRESHOLD and numericValue > bestValue then
            bestValue = numericValue
            bestBrainrot = brainrotData
            bestBrainrot.numericMPS = numericValue
        end
    end

    for _, plot in pairs(workspace.Plots:GetChildren()) do
        local podiums = plot:FindFirstChild('AnimalPodiums')
        if podiums then
            for _, podium in pairs(podiums:GetChildren()) do
                local overhead = podium:FindFirstChild('Base')
                if overhead then
                    overhead = overhead:FindFirstChild('Spawn')
                    if overhead then
                        overhead = overhead:FindFirstChild('Attachment')
                        if overhead then
                            overhead = overhead:FindFirstChild('AnimalOverhead')
                            if overhead then
                                processBrainrotOverhead(overhead)
                            end
                        end
                    end
                end
            end
        end
    end

    for _, child in pairs(workspace:GetChildren()) do
        if child:IsA('Model') and child.Name then
            local fakeRootPart = child:FindFirstChild('FakeRootPart')
            if fakeRootPart then
                local function searchBoneHierarchy(parent, depth)
                    depth = depth or 0
                    if depth > 10 then
                        return
                    end

                    for _, bone in pairs(parent:GetChildren()) do
                        if
                            bone.Name
                            and (
                                bone.Name:match('^Bone%.')
                                or bone.Name:find('Bone')
                            )
                        then
                            local hatAttachment =
                                bone:FindFirstChild('HatAttachment')
                            if hatAttachment then
                                local overheadAttachment =
                                    hatAttachment:FindFirstChild(
                                        'OVERHEAD_ATTACHMENT'
                                    )
                                if overheadAttachment then
                                    local animalOverhead =
                                        overheadAttachment:FindFirstChild(
                                            'AnimalOverhead'
                                        )
                                    if animalOverhead then
                                        processBrainrotOverhead(animalOverhead)
                                    end
                                end
                            end
                            searchBoneHierarchy(bone, depth + 1)
                        end
                    end
                end
                searchBoneHierarchy(fakeRootPart)
            end
        end
    end

    for _, plot in pairs(workspace.Plots:GetChildren()) do
        for _, child in pairs(plot:GetChildren()) do
            if child:IsA('Model') and child.Name then
                local fakeRootPart = child:FindFirstChild('FakeRootPart')
                if fakeRootPart then
                    local function searchBoneHierarchy(parent)
                        for _, bone in pairs(parent:GetChildren()) do
                            if bone.Name and bone.Name:match('^Bone%.') then
                                local hatAttachment =
                                    bone:FindFirstChild('HatAttachment')
                                if hatAttachment then
                                    local overheadAttachment =
                                        hatAttachment:FindFirstChild(
                                            'OVERHEAD_ATTACHMENT'
                                        )
                                    if overheadAttachment then
                                        local animalOverhead =
                                            overheadAttachment:FindFirstChild(
                                                'AnimalOverhead'
                                            )
                                        if animalOverhead then
                                            processBrainrotOverhead(
                                                animalOverhead
                                            )
                                        end
                                    end
                                end
                                searchBoneHierarchy(bone)
                            end
                        end
                    end
                    searchBoneHierarchy(fakeRootPart)
                end
            end
        end
    end

    local knownBrainrotNames = { 'Nuclearo Dinossauro', 'Dragon Cannelloni' }
    for _, brainrotName in pairs(knownBrainrotNames) do
        local brainrotModel = workspace:FindFirstChild(brainrotName)
        if brainrotModel then
            local fakeRootPart = brainrotModel:FindFirstChild('FakeRootPart')
            if fakeRootPart then
                local function searchAllBones(parent, path)
                    path = path or ''
                    for _, child in pairs(parent:GetChildren()) do
                        local currentPath = path .. '.' .. child.Name

                        if child.Name and child.Name:find('Bone') then
                            local hatAttachment =
                                child:FindFirstChild('HatAttachment')
                            if hatAttachment then
                                local overheadAttachment =
                                    hatAttachment:FindFirstChild(
                                        'OVERHEAD_ATTACHMENT'
                                    )
                                if overheadAttachment then
                                    local animalOverhead =
                                        overheadAttachment:FindFirstChild(
                                            'AnimalOverhead'
                                        )
                                    if animalOverhead then
                                        processBrainrotOverhead(animalOverhead)
                                    end
                                end
                            end
                        end
                        searchAllBones(child, currentPath)
                    end
                end
                searchAllBones(fakeRootPart)
            end
        end
    end

    return bestBrainrot
end

function notifyBrainrot()
    if busy then
        return
    end

    busy = true

    local success, bestBrainrot = pcall(function()
        return findBestBrainrot()
    end)

    if not success then
        spawn(function()
            wait(0.01)
            busy = false
        end)
        return
    end

    local specialPet = checkSpecialPets()
    if specialPet then
        local jobId = specialPet.jobId
        local brainrotKey = jobId .. "_" .. specialPet.name .. "_SPECIAL"

        if not notified[brainrotKey] then
            notified[brainrotKey] = true
            lastJob = jobId

            local fields = {
                {
                    name = "🏷️ Special Pet Found",
                    value = specialPet.name,
                    inline = true,
                },
                {
                    name = "👥 Players",
                    value = specialPet.playerCount,
                    inline = true,
                },
                {
                    name = "🔗 Join Link",
                    value = "[Click to Join](https://testing5312.github.io/joiner/?placeId=109983668079237&gameInstanceId=" .. jobId .. ")",
                    inline = false,
                },
                {
                    name = "Job ID (Mobile)",
                    value = "`" .. jobId .. "`",
                    inline = false,
                },
                {
                    name = "Job ID (PC)",
                    value = "```" .. jobId .. "```",
                    inline = false,
                },
                {
                    name = "Join Script (PC)",
                    value = "```game:GetService(\"TeleportService\"):TeleportToPlaceInstance(109983668079237,\""
                        .. jobId .. "\",game.Players.LocalPlayer)```",
                    inline = false,
                },
            }

            sendNotification(
                "Private Notifier - Special Pet",
                "",
                0xAB8AF2,
                fields,
                { webhook_10m_plus_shadow },
                true
            )
        end
    end

    if bestBrainrot then
        local players = getPlayerCount()
        local jobId = game.JobId or 'Unknown'
        local brainrotKey = jobId
            .. '_'
            .. bestBrainrot.name
            .. '_'
            .. bestBrainrot.moneyPerSec

        if not notified[brainrotKey] then
            notified[brainrotKey] = true
            lastJob = jobId

            local targetWebhooks = getWebhookForMoney(bestBrainrot.numericMPS)
            local shouldPing = bestBrainrot.numericMPS >= MONEY_RANGES.MID

            local fields = {
                {
                    name = '🏷️ Name',
                    value = bestBrainrot.name,
                    inline = true,
                },
                {
                    name = '💰 Money per sec',
                    value = bestBrainrot.moneyPerSec,
                    inline = true,
                },
                {
                    name = '👥 Players',
                    value = players,
                    inline = true,
                },
                {
                    name = '🔗 Join Link',
                    value = '[Click to Join](https://testing5312.github.io/joiner/?placeId=109983668079237&gameInstanceId='
                        .. jobId
                        .. ')',
                    inline = false,
                },
                {
                    name = 'Job ID (Mobile)',
                    value = '`' .. jobId .. '`',
                    inline = false,
                },
                {
                    name = 'Job ID (PC)',
                    value = '```' .. jobId .. '```',
                    inline = false,
                },
                {
                    name = 'Join Script (PC)',
                    value = '```game:GetService("TeleportService"):TeleportToPlaceInstance(109983668079237,"'
                        .. jobId
                        .. '",game.Players.LocalPlayer)```',
                    inline = false,
                },
            }

            sendNotification(
                'Private Notifier',
                '',
                0xAB8AF2,
                fields,
                targetWebhooks,
                shouldPing
            )
        end
    end

    spawn(function()
        wait(0.01)
        busy = false
    end)
end

function retryLoop()
    while true do
        wait(0.01)
        local success, error = pcall(function()
            notifyBrainrot()
        end)

        if not success then
            wait(0.01)
        end
    end
end

spawn(retryLoop)

pcall(function()
    notifyBrainrot()
end)

local start = tick()
local timeoutConn

timeoutConn = RunService.Heartbeat:Connect(function()
    if tick() - start > timeout then
        timeoutConn:Disconnect()
        hopServer()
    end
end)

TeleportService.TeleportInitFailed:Connect(function(player, result, error)
    wait(0.1)
    hopServer()
end)

TeleportService.LocalPlayerTeleported:Connect(function()
    if timeoutConn then
        timeoutConn:Disconnect()
    end
end)

hopServer()