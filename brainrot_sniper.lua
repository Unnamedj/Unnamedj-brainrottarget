

    
        
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
