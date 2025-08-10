--[[ ⚔️ Guild: Nyxara Exploits Hub ]]
-- Full Pet Sniper + ESP + Webhook A + Webhook B + Auto Server Hop + Auto Restart

--// 🎯 Targeted Pet Configuration
getgenv().WebhookATargets = {
    "Chicleteira Bicicleteira",
    "Dragon Cannelloni",
    "La Grande Combinasion",
    "Garama and Madundung",
    "Nuclearo Dinossauro",
    "Los Combinasionas"
}

getgenv().WebhookBTargets = {
    "La Vacca Saturno Saturnita",
    "Chimpanzini Spiderini",
    "Los Tralaleritos",
    "Las Tralaleritas",
    "Graipuss Medussi",
    "Tortuginni Dragonfruitini",
    "Las Vaquitas Saturnitas",
    "Pot Hostpot"
}

--// 🌐 Webhooks
local webhookA = "https://discord.com/api/webhooks/1402480794643075213/_GbDViIjHFUXCcSQiojz324x9l0DIY2ubeMzZDRTcI9g2p1M1F_yoE7vJX_XOv4Xh4K1"
local webhookB = "https://discord.com/api/webhooks/1404225086940250203/VJzWDW_vkq6iid9CyrPfZeUYOHt2u9d12YaOuE_cJ6VieoHMd7kb5N4PdZqvxgz85VuU"

--// 🔧 Services
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer

--// 📦 State
local visitedJobIds = {[game.JobId] = true}
local hops = 0
local maxHopsBeforeReset = 1000
local teleportFails = 0
local maxTeleportRetries = 10
local detectedPets = {}
local webhookSent = false
local stopHopping = false

--// 👁️ ESP Function
local function addESP(targetModel)
    if targetModel:FindFirstChild("PetESP") then return end
    local Billboard = Instance.new("BillboardGui")
    Billboard.Name = "PetESP"
    Billboard.Adornee = targetModel
    Billboard.Size = UDim2.new(0, 100, 0, 30)
    Billboard.StudsOffset = Vector3.new(0, 3, 0)
    Billboard.AlwaysOnTop = true
    Billboard.Parent = targetModel

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = "🎯 Target Pet"
    Label.TextColor3 = Color3.fromRGB(255, 0, 0)
    Label.TextStrokeTransparency = 0.5
    Label.Font = Enum.Font.SourceSansBold
    Label.TextScaled = true
    Label.Parent = Billboard
end

--// 📩 Webhook Sender
local function sendWebhook(foundPets, jobId, url)
    local petCounts = {}
    for _, pet in ipairs(foundPets) do
        petCounts[pet] = (petCounts[pet] or 0) + 1
    end

    local formattedPets = {}
    for petName, count in pairs(petCounts) do
        table.insert(formattedPets, count > 1 and petName .. " x" .. count or petName)
    end

    local joinerUrl = "https://testing5312.github.io/joiner/?placeId=" .. tostring(game.PlaceId) .. "&gameInstanceId=" .. jobId
    local jsonData = HttpService:JSONEncode({
        ["content"] = url == webhookA and "@everyone" or "",
        ["embeds"] = {{
            ["title"] = "Shadow Notifier⭐️",
            ["description"] = "Sniped Brainrot in server",
            ["fields"] = {
                {["name"] = "User", ["value"] = LocalPlayer.Name},
                {["name"] = "Found Pet(s)", ["value"] = table.concat(formattedPets, "\n")},
                {["name"] = "Server JobId", ["value"] = jobId},
                {["name"] = "Teleport Script", ["value"] = "game:GetService('TeleportService'):TeleportToPlaceInstance(" .. tostring(game.PlaceId) .. ", '" .. jobId .. "')"},
                {["name"] = "🌐 Join Server", ["value"] = "[Click here](" .. joinerUrl .. ")"},
                {["name"] = "Time", ["value"] = os.date("%Y-%m-%d %H:%M:%S")}
            },
            ["color"] = 0x800080
        }}
    })

    local req = http_request or request or (syn and syn.request)
    if req then
        pcall(function()
            req({
                Url = url,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = jsonData
            })
        end)
    end
end

--// 🔍 Pet Detection
local function checkForPets()
    local foundA, foundB = {}, {}

    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and not obj:FindFirstChild("PetESP") then
            local nameLower = string.lower(obj.Name)

            for _, target in pairs(getgenv().WebhookATargets) do
                if string.find(nameLower, string.lower(target)) then
                    addESP(obj)
                    table.insert(foundA, obj.Name)
                    stopHopping = true
                end
            end

            for _, target in pairs(getgenv().WebhookBTargets) do
                if string.find(nameLower, string.lower(target)) then
                    addESP(obj)
                    table.insert(foundB, obj.Name)
                    stopHopping = true
                end
            end
        end
    end

    return foundA, foundB
end

--// 🌍 Server Hop
local function serverHop()
    if stopHopping then return end
    task.wait(0.01)
    hops += 1
    if hops >= maxHopsBeforeReset then
        visitedJobIds = {[game.JobId] = true}
        hops = 0
    end

    local tries, cursor = 0, nil
    while tries < maxTeleportRetries do
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        if cursor then url = url .. "&cursor=" .. cursor end

        local success, response = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(url))
        end)

        if success and response and response.data then
            local servers = {}
            for _, server in ipairs(response.data) do
                if server.playing < server.maxPlayers and not visitedJobIds[server.id] and server.id ~= game.JobId then
                    table.insert(servers, server.id)
                end
            end

            if #servers > 0 then
                local picked = servers[math.random(1, #servers)]
                visitedJobIds[picked] = true
                teleportFails = 0
                TeleportService:TeleportToPlaceInstance(game.PlaceId, picked)
                return
            end

            cursor = response.nextPageCursor
            if not cursor then
                tries += 1
                task.wait(0.01)
            end
        else
            tries += 1
            task.wait(0.01)
        end
    end

    TeleportService:Teleport(game.PlaceId)
end

--// ♻️ Sniping Loop
local function startSniper()
    webhookSent = false
    stopHopping = false

    local foundA, foundB = checkForPets()

    if #foundA > 0 then
        sendWebhook(foundA, game.JobId, webhookA)
        webhookSent = true
        task.wait(10)
        serverHop()
    elseif #foundB > 0 then
        sendWebhook(foundB, game.JobId, webhookB)
        webhookSent = true
        task.wait(10)
        serverHop()
    else
        task.delay(0.01, serverHop)
    end

    task.delay(0.25, startSniper)
end

--// 🔄 Live Detection
workspace.DescendantAdded:Connect(function(obj)
    task.wait(0.02)
    if obj:IsA("Model") then
        local nameLower = string.lower(obj.Name)

        for type, targetList in pairs({
            [webhookA] = getgenv().WebhookATargets,
            [webhookB] = getgenv().WebhookBTargets
        }) do
            for _, target in pairs(targetList) do
                if string.find(nameLower, string.lower(target)) and not obj:FindFirstChild("PetESP") then
                    if not detectedPets[obj.Name] then
                        detectedPets[obj.Name] = true
                        addESP(obj)
                        sendWebhook({obj.Name}, game.JobId, type)
                        task.wait(10)
                        serverHop()
                    end
                    return
                end
            end
        end
    end
end)

--// 🚀 Start
task.delay(0.5, startSniper)