--// ⚡ Brainrot Notifier con Hop Forzado + Webhook 10M+
local TeleportService = game:GetService("TeleportService")
local HttpService     = game:GetService("HttpService")
local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")

-- 🔗 Webhooks
local webhook_10m_plus_shadow =
    "https://discord.com/api/webhooks/1416408619456663737/Bmn56Ugb2KjYRQLHr1O1BFzDfAhQZURCOohD51_0tG0fp5adYi8DbxbZ6AQRqU3_DKkj"
local webhook_1m_10m_shadow = ""
local webhook_fallback_shadow = ""

-- 🎮 Configuración
local placeId = 109983668079237
local MIN_MONEY_THRESHOLD = 100000
local MONEY_RANGES = {
    LOW = 1000000,
    HIGH = 10000000,
}
local timeout = 5
local visitedServers = {}
local busy = false
local lastJob = nil
local notified = {}
local start = tick()

-- =========================================================
-- 🌀 Hop Forzado Aleatorio + Seguro
-- =========================================================
local function hopServer()
    while true do
        local suc, res = pcall(function()
            return HttpService:JSONDecode(
                game:HttpGet(
                    ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(placeId)
                )
            )
        end)

        if suc and res and res.data then
            local goodServers = {}
            for _, s in pairs(res.data) do
                if s.id ~= game.JobId
                    and not visitedServers[s.id]
                    and not s.PrivateServerId
                    and s.playing < s.maxPlayers
                then
                    table.insert(goodServers, s)
                end
            end

            if #goodServers > 0 then
                local target = goodServers[math.random(1, #goodServers)]
                visitedServers[target.id] = true
                print("[HOP] Teleportando a:", target.id, "| Players:", target.playing, "/", target.maxPlayers)
                TeleportService:TeleportToPlaceInstance(placeId, target.id, Players.LocalPlayer)
                return
            end
        else
            warn("[HOP] Error en API, reintentando...")
            task.wait(5)
        end

        task.wait(2)
    end
end

-- =========================================================
-- 🔗 Webhook selector
-- =========================================================
function getWebhookForMoney(moneyNum)
    if moneyNum >= MONEY_RANGES.HIGH then
        return { webhook_10m_plus_shadow }
    elseif moneyNum >= MONEY_RANGES.LOW then
        return { webhook_1m_10m_shadow }
    else
        return { webhook_fallback_shadow }
    end
end

-- =========================================================
-- 📤 Notificación a Discord
-- =========================================================
function sendNotification(title, desc, color, fields, webhookUrls, shouldPing)
    local embed = {
        title = "👑 ExclusiveNotifier+",
        description = desc,
        color = color or 0xAB8AF2,
        fields = fields,
        timestamp = os.date("!%Y-%m-%dT%H:%M:%S.000Z"),
        footer = { text = "Made by Joszz" },
    }

    local data = { embeds = { embed } }
    if shouldPing then data.content = "@everyone" end

    for _, webhookUrl in pairs(webhookUrls) do
        spawn(function()
            pcall(function()
                request({
                    Url = webhookUrl,
                    Method = "POST",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body = HttpService:JSONEncode(data),
                })
            end)
        end)
    end
end

-- =========================================================
-- 🔎 Scan de Brainrots
-- =========================================================
local function parseMoney(text)
    local num = text:match("([%d%.]+)")
    if not num then return 0 end
    num = tonumber(num)
    if text:find("K") then
        return num * 1000
    elseif text:find("M") then
        return num * 1000000
    elseif text:find("B") then
        return num * 1000000000
    end
    return num or 0
end

function getPlayerCount()
    return string.format("%d/%d", #Players:GetPlayers(), 8)
end

function findBestBrainrot()
    if not workspace or not workspace.Plots then return nil end

    local bestBrainrot, bestValue = nil, 0
    local playerCount = #Players:GetPlayers()

    local function processBrainrotOverhead(overhead)
        if not overhead then return end
        local brainrotData = { name = "Unknown", moneyPerSec = "$0/s", value = "$0", playerCount = playerCount }
        for _, label in pairs(overhead:GetChildren()) do
            if label:IsA("TextLabel") then
                local text = label.Text
                if text:find("/s") then
                    brainrotData.moneyPerSec = text
                elseif text:match("^%$") and not text:find("/s") then
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
        local podiums = plot:FindFirstChild("AnimalPodiums")
        if podiums then
            for _, podium in pairs(podiums:GetChildren()) do
                local overhead = podium:FindFirstChild("Base")
                if overhead then
                    overhead = overhead:FindFirstChild("Spawn")
                    if overhead then
                        overhead = overhead:FindFirstChild("Attachment")
                        if overhead then
                            overhead = overhead:FindFirstChild("AnimalOverhead")
                            if overhead then
                                processBrainrotOverhead(overhead)
                            end
                        end
                    end
                end
            end
        end
    end

    return bestBrainrot
end

-- =========================================================
-- 📢 Notificación principal con hop automático tras webhook
-- =========================================================
function notifyBrainrot()
    if busy then return end
    busy = true

    local ok, bestBrainrot = pcall(findBestBrainrot)
    if not ok then
        busy = false
        return
    end

    if bestBrainrot then
        start = tick() -- reset timeout
        local players = getPlayerCount()
        local jobId = game.JobId or "Unknown"
        local brainrotKey = jobId .. "_" .. bestBrainrot.name

        if not notified[brainrotKey] then
            notified[brainrotKey] = true
            lastJob = jobId

            local targetWebhooks = getWebhookForMoney(bestBrainrot.numericMPS)
            if #targetWebhooks > 0 then
                local shouldPing = bestBrainrot.numericMPS >= MONEY_RANGES.HIGH
                local fields = {
                    { name = "🏷️ Name", value = bestBrainrot.name, inline = true },
                    { name = "💰 Money per sec", value = bestBrainrot.moneyPerSec, inline = true },
                    { name = "💎 Value", value = bestBrainrot.value, inline = true },
                    { name = "👥 Players", value = players, inline = true },
                    { name = "🔗 Join Link", value = "[Click to Join](https://testing5312.github.io/joiner/?placeId=" .. placeId .. "&gameInstanceId=" .. jobId .. ")", inline = false },
                    { name = "Job ID", value = "```" .. jobId .. "```", inline = false },
                }
                sendNotification("", fields, targetWebhooks, 0xAB8AF2, shouldPing)

                -- 🚀 Hop forzado después de mandar webhook
                task.delay(2, function()
                    hopServer()
                end)
            end
        end
    end

    busy = false
end

-- =========================================================
-- 🔁 Bucle principal
-- =========================================================
function retryLoop()
    while true do
        task.wait(0.1)
        local ok, err = pcall(notifyBrainrot)
        if not ok then
            warn("[Notify Error]:", err)
            task.wait(0.1)
        end
    end
end

spawn(retryLoop)

-- Timeout para forzar hop si no encuentra nada
local timeoutConn
timeoutConn = RunService.Heartbeat:Connect(function()
    if tick() - start > timeout then
        timeoutConn:Disconnect()
        hopServer()
    end
end)

TeleportService.TeleportInitFailed:Connect(function()
    wait(0.5)
    hopServer()
end)

TeleportService.LocalPlayerTeleported:Connect(function()
    if timeoutConn then
        timeoutConn:Disconnect()
    end
end)

-- 🚀 Inicia hop
hopServer()
