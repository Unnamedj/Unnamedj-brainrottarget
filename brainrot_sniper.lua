-- Full Pet Sniper Ultra Rápido + ESP + Webhooks + Turbo Server Hop Prioridad 3-5

--🎯 Objetivos
getgenv().WebhookATargets = {
    "Chicleteira Bicicleteira", "Dragon Cannelloni", "La Grande Combinasion",
    "Garama and Madundung", "Nuclearo Dinossauro"
}
getgenv().WebhookBTargets = {
    "Ballerino Lololo", "Los Crocodillitos", "Piccione Macchina", "Trenostruzzo Turbo 3000",
    "Trigoligre Frutonni", "Orcalero Orcala", "Coco Elefanto", "Girafa Celestre",
    "Gattianino Nyanino", "Matteo", "Tralalero Tralala", "Espresso Signora",
    "Odin Din Din Dun", "Statutino Libertino", "Trippi Troppi Troppa Trippa"
}
getgenv().WebhookCTargets = {
    "Las Vaquitas Saturnitas", "Pot Hotspot", "Tortuginni Dragonfruitini",
    "Graipuss Medussi", "Las Tralaleritas", "Los tralaleritos",
    "Chimpanzini Spiderini", "La Vacca Saturno Saturnita"
}

--🌐 Webhooks
local webhookA = "https://discord.com/api/webhooks/1398949589792587897/..."
local webhookB = "https://discord.com/api/webhooks/1399229152649019452/..."
local webhookC = "https://discord.com/api/webhooks/1402409276856860672/..."

--🔧 Servicios
local Players, HttpService, TeleportService = game:GetService("Players"), game:GetService("HttpService"), game:GetService("TeleportService")
local LocalPlayer, visited = Players.LocalPlayer, {[game.JobId] = true}
local sent, JobId, stopHop = false, game.JobId, false

--👁️ ESP
local function addESP(model)
    if model:FindFirstChild("PetESP") then return end
    local gui = Instance.new("BillboardGui", model)
    gui.Name = "PetESP"; gui.Adornee = model; gui.Size = UDim2.new(0, 100, 0, 30); gui.AlwaysOnTop = true
    gui.StudsOffset = Vector3.new(0, 3, 0)

    local text = Instance.new("TextLabel", gui)
    text.Size = UDim2.new(1, 0, 1, 0); text.BackgroundTransparency = 1; text.Text = "🎯 Target Pet"
    text.TextColor3 = Color3.fromRGB(255, 0, 0); text.TextStrokeTransparency = 0.5
    text.Font = Enum.Font.SourceSansBold; text.TextScaled = true
end

--📩 Webhook
local function sendWebhook(pets, jobId, url)
    if sent then return end
    sent = true

    local counts, formatted = {}, {}
    for _, p in ipairs(pets) do counts[p] = (counts[p] or 0) + 1 end
    for pet, c in pairs(counts) do table.insert(formatted, c > 1 and pet .. " x" .. c or pet) end

    local joinUrl = "https://testing5312.github.io/joiner/?placeId=" .. game.PlaceId .. "&gameInstanceId=" .. jobId
    local data = HttpService:JSONEncode({
        content = url == webhookA and "@everyone" or "",
        embeds = {{
            title = "⭐️ Shadow Notifier",
            description = "Sniped Brainrot in server",
            fields = {
                {name = "User", value = LocalPlayer.Name},
                {name = "Found Pet(s)", value = table.concat(formatted, "\n")},
                {name = "Server JobId", value = "`" .. jobId .. "`"},
                {name = "Teleport Script", value = "game:GetService('TeleportService'):TeleportToPlaceInstance("..game.PlaceId..", '"..jobId.."')"},
                {name = "🌐 Join Server", value = "[Click here](" .. joinUrl .. ")"},
                {name = "Time", value = os.date("%Y-%m-%d %H:%M:%S")}
            },
            color = 0x800080
        }}
    })

    local req = http_request or request or (syn and syn.request)
    if req then pcall(function()
        req({Url = url, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = data})
    end) end
end

--🔍 Detección rápida
local function detect(model)
    if not model:IsA("Model") or model:FindFirstChild("PetESP") then return end
    local n = string.lower(model.Name)

    for hook, targets in pairs({[webhookA] = getgenv().WebhookATargets, [webhookB] = getgenv().WebhookBTargets, [webhookC] = getgenv().WebhookCTargets}) do
        for _, target in ipairs(targets) do
            if string.find(n, string.lower(target)) then
                addESP(model)
                sendWebhook({model.Name}, JobId, hook)
                stopHop = true
                task.delay(8, function()
                    TeleportService:Teleport(game.PlaceId)
                end)
                return
            end
        end
    end
end

--🌍 Server Hop con prioridad 3 → 5 → cualquiera
local function hopServer()
    local tries, cursor = 0, nil

    while not stopHop and tries < 8 do
        local url = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
        if cursor then url = url .. "&cursor=" .. cursor end

        local success, result = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(url))
        end)

        if success and result and result.data then
            local servers3, servers5, serversAny = {}, {}, {}

            for _, s in ipairs(result.data) do
                if not visited[s.id] and s.id ~= JobId then
                    if s.playing <= 3 then
                        table.insert(servers3, s.id)
                    elseif s.playing <= 5 then
                        table.insert(servers5, s.id)
                    elseif s.playing < s.maxPlayers then
                        table.insert(serversAny, s.id)
                    end
                end
            end

            local function teleportTo(choices)
                if #choices > 0 then
                    local picked = choices[math.random(1, #choices)]
                    visited[picked] = true
                    local succ, err = pcall(function()
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, picked)
                    end)
                    if not succ then tries += 1 end
                    return true
                end
                return false
            end

            if teleportTo(servers3) or teleportTo(servers5) or teleportTo(serversAny) then
                return
            end

            cursor = result.nextPageCursor
        else
            tries += 1
        end
        task.wait(0)
    end

    TeleportService:Teleport(game.PlaceId)
end

--⏱️ Escaneo instantáneo
workspace.DescendantAdded:Connect(function(obj)
    task.spawn(function()
        detect(obj)
    end)
end)

--🚀 Auto Hop cada 0.2s si no encuentra target
task.delay(1, function()
    while not stopHop do
        hopServer()
        task.wait(0.2)
    end
end)