--// ⚡ Brainrot Notifier con Hop Forzado + Webhooks (10M–29M y 30M+)
local TeleportService = game:GetService("TeleportService")
local HttpService     = game:GetService("HttpService")
local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")

-- 🔗 Webhooks
local webhook_30m_plus_shadow =
    "https://discord.com/api/webhooks/1415127793947115670/4BECWBUu9c6hvlbDyDrl9LmJYMAfT5ZcNTZRVGl9y-Eu3xv_NSObCRMnhdrGkpuKOlrL"
local webhook_10m_30m_shadow =
    "https://discord.com/api/webhooks/1415127656923664435/1pciNJ3WMUSzcMP_CjccwhfvfV8Y5ZEhT_ISvrlxSrgZRKKRsuWUHtwWuW69CrTsPUVG"

-- 🎮 Configuración
local placeId = 109983668079237
local MIN_MONEY_THRESHOLD = 10000000 -- 10M es el mínimo que nos importa
local timeout = 5
local visitedServers = {}
local busy = false
local lastJob = nil
local notified = {}

-- =========================================================
-- 🌀 Hop Forzado
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
            table.sort(res.data, function(a, b)
                return a.playing < b.playing
            end)

            for _, s in pairs(res.data) do
                if s.id ~= game.JobId
                    and not visitedServers[s.id]
                    and not s.PrivateServerId
                    and s.playing < s.maxPlayers
                then
                    visitedServers[s.id] = true
                    print("[HOP] Teleportando a server:", s.id, "| Players:", s.playing, "/", s.maxPlayers)
                    TeleportService:TeleportToPlaceInstance(placeId, s.id, Players.LocalPlayer)
                    return
                end
            end
        else
            warn("[HOP] Error en API, reintentando...")
        end

        task.wait(2) -- espera antes de volver a intentar
    end
end

-- =========================================================
-- 🔗 Webhooks según dinero
-- =========================================================
function getWebhookForMoney(moneyNum)
    if moneyNum >= 30000000 then
        print("[SCAN] Detectado Brainrot de " .. moneyNum .. " → Enviado a Webhook 30M+")
        return { webhook_30m_plus_shadow }
    elseif moneyNum >= 10000000 then
        print("[SCAN] Detectado Brainrot de " .. moneyNum .. " → Enviado a Webhook 10M–29M")
        return { webhook_10m_30m_shadow }
    else
        print("[SCAN] Detectado Brainrot de " .. moneyNum .. " → NO se envía (menor a 10M)")
        return {}
    end
end

-- =========================================================
-- 📤 Enviar notificación a Discord
-- =========================================================
function sendNotification(title, desc, color, fields, webhookUrls, shouldPing)
    local embed = {
        title = "ExclusiveNotifier+", -- 🔹 Cambio aquí
        description = desc,
        color = color or 0xAB8AF2,
        fields = fields,
        timestamp = os.date("!%Y-%m-%dT%H:%M:%S.000Z"),
        footer = { text = "Made by Joszz" }, -- 🔹 Cambio aquí
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
    local count = #Players:GetPlayers()
    local max = game.PlaceId and 8 or 8
    return string.format("%d/%d", count, max)
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
-- 📢 Notificación principal
-- =========================================================
function notifyBrainrot()
    if busy then return end
    busy = true

    local success, bestBrainrot = pcall(findBestBrainrot)

    if not success then
        busy = false
        return
    end

    if bestBrainrot then
        local players = getPlayerCount()
        local jobId = game.JobId or "Unknown"
        local brainrotKey = jobId .. "_" .. bestBrainrot.name .. "_" .. bestBrainrot.moneyPerSec

        if not notified[brainrotKey] then
            notified[brainrotKey] = true
            lastJob = jobId

            local targetWebhooks = getWebhookForMoney(bestBrainrot.numericMPS)
            if #targetWebhooks > 0 then
                local shouldPing = bestBrainrot.numericMPS >= 30000000
                local fields = {
                    { name = "🏷️ Name", value = bestBrainrot.name, inline = true },
                    { name = "💰 Money per sec", value = bestBrainrot.moneyPerSec, inline = true },
                    { name = "👥 Players", value = players, inline = true },
                    { name = "🔗 Join Link", value = "[Click to Join](https://testing5312.github.io/joiner/?placeId=" .. placeId .. "&gameInstanceId=" .. jobId .. ")", inline = false },
                    { name = "Job ID", value = "```" .. jobId .. "```", inline = false },
                }

                sendNotification("ExclusiveNotifier+", "", 0xAB8AF2, fields, targetWebhooks, shouldPing)
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
        local ok = pcall(notifyBrainrot)
        if not ok then task.wait(0.1) end
    end
end

spawn(retryLoop)

-- Timeout para forzar hop si no hay resultados
local start = tick()
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
