-- 💀 Brainrot Pro Sniper by JOSZMSR (modificado por ChatGPT)
-- Mejorado: sigue haciendo hop

--==🎯 Pets Objetivo==--
getgenv().WebhookATargets = {
    "Chicleteira Bicicleteira",
    "Dragon Cannelloni",
    "La Grande Combinasion",
    "Garama and Madundung",
    "Nuclearo Dinossauro",
    "Los Combinasionas"
}

getgenv().WebhookBTargets = {
    "Los Tralaleritos",
    "Graipuss Medussi",
    "Sammyni Spyderini",
    "Torrtuginni Dragonfrutini",
    "Pot Hotspot",
    "Las Tralaleritas"
}

--==📊 Brainrot exacto por Pet==--
local petBrainrot = {
    ["Chicleteira Bicicleteira"] = "3,500,000",
    ["Dragon Cannelloni"] = "15,400,000",
    ["La Grande Combinasion"] = "10,000,000",
    ["Garama and Madundung"] = "50,000,000",
    ["Nuclearo Dinossauro"] = "15,000,000",
    ["Los Tralaleritos"] = "500,000",
    ["Graipuss Medussi"] = "1,000,000",
    ["Sammyni Spyderini"] = "350,000",
    ["Torrtuginni Dragonfrutini"] = "400,000",
    ["Pot Hotspot"] = "2,500,000",
    ["Las Tralaleritas"] = "650,000",
    ["Los Combinasionas"] = "15,000,000"
}

--==🌐 Webhooks==--
local webhookA = "https://discord.com/api/webhooks/1398949589792587897/bjhmpxp-gy5zzi_S5gxaJTT4pT0RRlSF3jdI4CuhvoP8y-efC5SoIKRiopMVpDdKZL2X"
local webhookB = "https://discord.com/api/webhooks/1399229152649019452/DMtjxmpnDT0LG0NFxhPNil0NdgAEtpco_DBbKkLd2FOx7_z2CnANyooo-pV3kJEUKBnH"

--==📦 Servicios==--
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local hops, webhookSent = 0, false
local visited = {[game.JobId] = true}
local failedServers = {}
local detectedPets = {}

--==📊 UI Contador de Hops==--
local ui = Instance.new("ScreenGui", game.CoreGui)
local label = Instance.new("TextLabel", ui)
label.Size = UDim2.new(0, 200, 0, 30)
label.Position = UDim2.new(0.8, 0, 0, 20)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.new(1, 1, 1)
label.Font = Enum.Font.GothamBold
label.TextScaled = true
label.Text = "Server Hops: 0"

--==🧲 ESP==--
local function addESP(target)
    if target:FindFirstChild("PetESP") then return end
    local esp = Instance.new("BillboardGui", target)
    esp.Name = "PetESP"
    esp.Size = UDim2.new(0, 100, 0, 25)
    esp.AlwaysOnTop = true
    esp.Adornee = target
    esp.StudsOffset = Vector3.new(0, 2, 0)

    local text = Instance.new("TextLabel", esp)
    text.Size = UDim2.new(1, 0, 1, 0)
    text.Text = "🎯 TARGET"
    text.BackgroundTransparency = 1
    text.TextColor3 = Color3.fromRGB(255, 80, 80)
    text.TextStrokeTransparency = 0.3
    text.Font = Enum.Font.GothamBold
    text.TextScaled = true
end

--==🔍 Detección==--
local function detectPets()
    local foundA, foundB = {}, {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and not obj:FindFirstChild("PetESP") then
            local lowerName = obj.Name:lower()
            for _, pet in ipairs(getgenv().WebhookATargets) do
                if lowerName:find(pet:lower()) then
                    addESP(obj)
                    table.insert(foundA, obj.Name)
                end
            end
            for _, pet in ipairs(getgenv().WebhookBTargets) do
                if lowerName:find(pet:lower()) then
                    addESP(obj)
                    table.insert(foundB, obj.Name)
                end
            end
        end
    end
    return foundA, foundB
end

--==📤 Enviar Webhook==--
local function sendWebhook(pets, jobId, url)
    local fields = {}
    for _, petName in ipairs(pets) do
        local brainrot = petBrainrot[petName] or "Unknown"
        table.insert(fields, {
            name = "🎯 Pet: "..petName,
            value = "🧠 Brainrot: "..brainrot,
            inline = true
        })
    end

    table.insert(fields, {
        name = "📌 Job ID",
        value = "```lua\n"..jobId.."\n```",
        inline = false
    })

        table.insert(fields, {
        name = "🔗 Join Link",
        value = "https://testing5312.github.io/joiner/?placeId="..game.PlaceId.."&gameInstanceId="..jobId,
        inline = false
    })

    local contentMsg = (url == webhookA) and "@everyone" or ""

    local data = HttpService:JSONEncode({
        content = contentMsg,
        embeds = {{
            title = "Shadow Notifier",
            description = "Sniped Brainrots",
            color = 0x800080,
            fields = fields,
            footer = {text = os.date("%c")}
        }}
    })

    local req = http_request or request or (syn and syn.request)
    if req then
        pcall(function()
            req({
                Url = url,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = data
            })
        end)
    end
end

--==🚀 Server Hop PRO==--
local function hop()
    hops += 1
    label.Text = "Server Hops: " .. hops
    local PlaceId, cursor = game.PlaceId, nil

    for _ = 1, 5 do
        local url = "https://games.roblox.com/v1/games/"..PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
        if cursor then url = url .. "&cursor=" .. cursor end

        local ok, res = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(url))
        end)

        if ok and res and res.data then
            local candidates = {}
            for _, server in ipairs(res.data) do
                if server.playing < server.maxPlayers
                and not visited[server.id]
                and not failedServers[server.id] then
                    table.insert(candidates, server.id)
                end
            end

            if #candidates > 0 then
                local chosen = candidates[math.random(1, #candidates)]
                visited[chosen] = true
                local success, err = pcall(function()
                    TeleportService:TeleportToPlaceInstance(PlaceId, chosen)
                end)
                if not success then
                    warn("⚠️ Falló teleport: ", err)
                    failedServers[chosen] = true
                    task.wait(0.5)
                end
                return
            end

            cursor = res.nextPageCursor
            task.wait(0.1)
        else
            warn("❌ Falló obtener servidores")
            break
        end
    end

    warn("🔁 Reiniciando búsqueda...")
    visited = {[game.JobId] = true}
    failedServers = {}
    task.wait(1)
    hop()
end

--==🔁 Loop principal==--
local function startLoop()
    local a, b = detectPets()
    if #a > 0 and not webhookSent then
        webhookSent = true
        sendWebhook(a, game.JobId, webhookA)
        game.StarterGui:SetCore("SendNotification", {Title = "🎯 Found!", Text = a[1], Duration = 5})
        task.wait(5)
        hop()
    elseif #b > 0 and not webhookSent then
        webhookSent = true
        sendWebhook(b, game.JobId, webhookB)
        game.StarterGui:SetCore("SendNotification", {Title = "🎯 Found!", Text = b[1], Duration = 5})
        task.wait(5)
        hop()
    else
        task.delay(1, hop)
    end
    task.delay(3, startLoop)
end

startLoop()

--==📡 Detección en vivo==--
workspace.DescendantAdded:Connect(function(obj)
    task.wait(0.1)
    if obj:IsA("Model") and not obj:FindFirstChild("PetESP") then
        local name = obj.Name:lower()
        for _, pet in ipairs(getgenv().WebhookATargets) do
            if name:find(pet:lower()) and not detectedPets[obj.Name] then
                detectedPets[obj.Name] = true
                addESP(obj)
                sendWebhook({obj.Name}, game.JobId, webhookA)
                hop()
            end
        end
        for _, pet in ipairs(getgenv().WebhookBTargets) do
            if name:find(pet:lower()) and not detectedPets[obj.Name] then
                detectedPets[obj.Name] = true
                addESP(obj)
                sendWebhook({obj.Name}, game.JobId, webhookB)
                hop()
            end
        end
    end
end)

