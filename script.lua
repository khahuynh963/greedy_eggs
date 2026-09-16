--[[
    ===================================================================
    🥚 GREEDY EGGS - ULTIMATE AUTO HUB V2.0 (PRO REWRITE)
    Game: Greedy Eggs 🥚 by Random Ahhh Games
    Tối ưu hóa hiệu năng 60 FPS: Siêu Mượt, Không Giật Lag!
    Tương thích 100% Delta Executor (Android & PC), Wave, Codex, Fluxus.
    
    TÍNH NĂNG CHÍNH ĐÃ VIẾT LẠI & TỐI ƯU TOÀN DIỆN:
      1. 🛒 AUTO MUA TRỨNG TRÊN SÔNG (RIVER AUTO BUY):
         - Quét toàn bộ trứng trôi trên sông (bãi đá sông) theo thời gian thực.
         - Hỗ trợ Mua Tất Cả (Buy All) hoặc Lọc Mua theo Độ Hiếm (Common -> Supreme).
         - Tính năng River Proximity Assist: Lướt nhẹ nhặt trứng sông chuẩn 100%.
      2. 🥚 AUTO TRỒNG & THU HOẠCH (AUTO PLANT & HARVEST):
         - Tự động lấy trứng từ túi đồ (Common, Advanced, Legendary...) gieo vào bệ đất.
         - Tự động bơm đồ ăn may mắn (Basic -> Magic +250% Luck).
         - Theo dõi thời gian lớn tối đa của trứng và tự động thu hoạch.
      3. 🛡️ KHIÊN CHỐNG SÉT 24/7 & NÉ SÉT SIÊU TỐC:
         - Tự động phát hiện đám mây sét / tia sét sà xuống bệ trứng.
         - Thu hoạch né sét vào túi đồ an toàn (0ms - 2.5s) trước khi sét đánh vỡ trứng!
      4. 💰 KINH TẾ & TIỆN ÍCH:
         - Tự nhặt Cash/s, tự trộm trứng cuối map, tự bán, 3D ESP & Sky Beacon.
    ===================================================================
--]]

local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer

-- ── Safe GUI Container Helper ──
local function getGuiContainer()
    local container = nil
    pcall(function()
        if gethui then
            container = gethui()
        elseif syn and syn.protect_gui then
            local f = Instance.new("Folder")
            syn.protect_gui(f)
            f.Parent = game:GetService("CoreGui")
            container = f
        elseif game:GetService("CoreGui") then
            container = game:GetService("CoreGui")
        end
    end)
    if not container then
        pcall(function()
            container = LocalPlayer:WaitForChild("PlayerGui")
        end)
    end
    return container
end

-- Clear old GUI instances
pcall(function()
    local c = getGuiContainer()
    if c and c:FindFirstChild("GreedyEggsGui") then
        c.GreedyEggsGui:Destroy()
    end
    if game:GetService("CoreGui"):FindFirstChild("GreedyEggsGui") then
        game:GetService("CoreGui").GreedyEggsGui:Destroy()
    end
    if LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("GreedyEggsGui") then
        LocalPlayer.PlayerGui.GreedyEggsGui:Destroy()
    end
end)

-- ── State Variables ──
local State = {
    -- 1. River Auto Buy
    AutoBuy = true, -- Mặc định bật để tự động gom trứng
    AutoBuyAll = true, -- Mua tất cả trứng trôi qua
    BuyDelayIndex = 2,
    BuyDelay = 0.15,
    RiverProximityAssist = true, -- Đảm bảo nhặt trúng 100%

    -- 2. Farming & Planting
    AutoPlant = false,
    LightningShield247 = true, -- Khiên chống sét độc lập 24/7
    AutoDodgeLightning = true,
    DodgeLeadTimeIndex = 6, -- 2.0s
    GrowthWaitIndex = 4, -- 15s

    -- 3. Food & Luck
    AutoFood = true,
    SelectedFoodIndex = 1, -- Basic (+37% Free)

    -- 4. Stealing Eggs & Economy
    AutoStealEndMap = false,
    AutoCollectCash = true,
    AutoSell = false,
    AutoTrash = false,

    -- 5. Visuals & ESP
    EggESP = true,
    SkyBeacons = true,
    FPSBoost = false,

    -- 6. Utilities
    SpeedEnabled = false,
    WalkSpeed = 120,
    CFrameBoost = true,
    CFrameSpeed = 5,
    InfiniteJump = false,
    Noclip = false,
    AntiAFK = true
}

local ALL_BUY_DELAYS = {0.05, 0.15, 0.3, 0.5, 1.0}
local ALL_DODGE_TIMES = {0.5, 0.8, 1.0, 1.2, 1.5, 2.0, 2.5, 3.0}
local ALL_GROWTH_TIMES = {5, 8, 10, 12, 15, 20, 25, 30}

local ALL_FOOD_TYPES = {"Basic", "None", "Better", "Premium", "Super", "Magic"}
local ALL_FOOD_DISPLAYS = {
    "Basic (+37% Luck Free)",
    "None (Free)",
    "Better (+73% Luck $)",
    "Premium (+115% Luck $)",
    "Super (+168% Luck $)",
    "Magic (+250% Luck $)"
}

local ALL_RARITIES = {
    "Common", "Rare", "Epic", "Legendary", "Mythical", 
    "Godly", "Secret", "Divine", "OG", "Celestial", 
    "Eternal", "Forbidden", "Unknown", "Supreme"
}

local SelectedRarities = {
    ["Common"]    = true,
    ["Rare"]      = true,
    ["Epic"]      = true,
    ["Legendary"] = true,
    ["Mythical"]  = true,
    ["Godly"]     = true,
    ["Secret"]    = true,
    ["Divine"]    = true,
    ["OG"]        = true,
    ["Celestial"] = true,
    ["Eternal"]   = true,
    ["Forbidden"] = true,
    ["Unknown"]   = true,
    ["Supreme"]   = true
}

local ESPHighlights = {}
local ESPBillboards = {}
local ESPBeacons = {}

-- ── Helpers: Character & Roots ──
local function getCharacter()
    return LocalPlayer.Character
end

local function getRootPart()
    local char = getCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

-- ── Plot Detection Engine (Plot_<UserId>) ──
local cachedMyPlot = nil

local function getMyPlot()
    if cachedMyPlot and cachedMyPlot.Parent then
        return cachedMyPlot
    end

    local pName = LocalPlayer.Name:lower()
    local pDisp = LocalPlayer.DisplayName:lower()
    local pId = tostring(LocalPlayer.UserId)
    local targetPlotName = "Plot_" .. pId

    pcall(function()
        -- 1. Search inside Workspace.Plots
        local plotsFolder = Workspace:FindFirstChild("Plots") or Workspace:FindFirstChild("Bases") or Workspace:FindFirstChild("Islands") or Workspace:FindFirstChild("Farms")
        if plotsFolder then
            local tycoons = plotsFolder:FindFirstChild("Tycoons") or plotsFolder:FindFirstChild("PlotSlots") or plotsFolder:FindFirstChild("Plots")
            if tycoons then
                local direct = tycoons:FindFirstChild(targetPlotName)
                if direct then cachedMyPlot = direct return end
                for _, child in ipairs(tycoons:GetChildren()) do
                    if child.Name == targetPlotName or child.Name:find(pId) or child.Name:lower():find(pName) then
                        cachedMyPlot = child return
                    end
                end
            end

            local directPlots = plotsFolder:FindFirstChild(targetPlotName)
            if directPlots then cachedMyPlot = directPlots return end

            for _, child in ipairs(plotsFolder:GetChildren()) do
                local cName = child.Name:lower()
                if cName == targetPlotName:lower() or cName:find(pId) or cName:find(pName) or cName:find(pDisp) then
                    cachedMyPlot = child return
                end
                for _, attr in ipairs({"Owner", "Player", "UserId", "Username"}) do
                    local v = child:GetAttribute(attr)
                    if v and (tostring(v):lower() == pName or tostring(v) == pId) then
                        cachedMyPlot = child return
                    end
                end
                local ownerVal = child:FindFirstChild("Owner") or child:FindFirstChild("Player")
                if ownerVal and (ownerVal.Value == LocalPlayer or tostring(ownerVal.Value):lower() == pName) then
                    cachedMyPlot = child return
                end
            end
        end

        -- 2. Direct search in Workspace
        local directWs = Workspace:FindFirstChild(targetPlotName)
        if directWs then cachedMyPlot = directWs return end

        for _, obj in ipairs(Workspace:GetChildren()) do
            local oName = obj.Name:lower()
            if (oName:find("plot") or oName:find("base") or oName:find("farm")) and (oName:find(pName) or oName:find(pId) or oName:find(pDisp)) then
                cachedMyPlot = obj return
            end
        end

        -- 3. Deep search for Plot_<UserId>
        for _, desc in ipairs(Workspace:GetDescendants()) do
            if (desc:IsA("Model") or desc:IsA("Folder")) and desc.Name == targetPlotName then
                cachedMyPlot = desc return
            end
        end
    end)

    return cachedMyPlot
end

local function isOtherPlayerPlot(container)
    if not container or container == Workspace then return false end
    local myPlot = getMyPlot()
    if myPlot and (container == myPlot or container:IsDescendantOf(myPlot)) then
        return false
    end

    local myId = tostring(LocalPlayer.UserId)
    local curr = container
    while curr and curr ~= Workspace do
        local cName = curr.Name:lower()
        if cName:find("plot") or cName:find("base") or cName:find("pen") or cName:find("farm") or cName:find("tycoon") then
            local plotUserId = cName:match("plot_(%d+)")
            if plotUserId and plotUserId ~= myId then return true end
            for _, attr in ipairs({"Owner", "Player", "UserId", "Username"}) do
                local val = curr:GetAttribute(attr)
                if val and tostring(val) ~= myId and tostring(val):lower() ~= LocalPlayer.Name:lower() then
                    return true
                end
            end
            local ownerVal = curr:FindFirstChild("Owner") or curr:FindFirstChild("Player")
            if ownerVal and ownerVal.Value ~= LocalPlayer then
                return true
            end
        end
        curr = curr.Parent
    end

    return false
end

-- ── Rarity Detection with Word Boundaries ──
local function detectEggRarity(item)
    if not item then return "Common" end

    local function matchStrict(str)
        if not str or str == "" then return nil end
        local s = tostring(str):lower()
        if s:find("%f[%a]uncommon%f[%A]") then return "Common" end
        for _, r in ipairs({"Supreme", "Forbidden", "Eternal", "Celestial", "Divine", "Secret", "Godly", "Mythical", "Legendary", "Epic", "Rare", "OG", "Common"}) do
            if s:find("%f[%a]" .. r:lower() .. "%f[%A]") then
                return r
            end
        end
        return nil
    end

    local found = matchStrict(item.Name)
    if found then return found end

    pcall(function()
        for _, attr in ipairs({"Rarity", "Tier", "Type", "ItemRarity"}) do
            local v = item:GetAttribute(attr)
            if v then
                local res = matchStrict(v)
                if res then found = res break end
            end
        end
        if not found then
            for _, desc in ipairs(item:GetDescendants()) do
                if desc:IsA("StringValue") and (desc.Name:lower() == "rarity" or desc.Name:lower() == "tier") then
                    local res = matchStrict(desc.Value)
                    if res then found = res break end
                elseif desc:IsA("TextLabel") and desc.Visible then
                    local res = matchStrict(desc.Text)
                    if res then found = res break end
                end
            end
        end
    end)

    return found or "Common"
end

-- ── Safe & Instant Trigger Prompt ──
local function triggerPrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return end

    pcall(function()
        prompt.RequiresLineOfSight = false
        prompt.HoldDuration = 0
        prompt.MaxActivationDistance = 999999
        prompt.Enabled = true

        if fireproximityprompt then
            fireproximityprompt(prompt, 0)
            fireproximityprompt(prompt, 100)
            fireproximityprompt(prompt)
        end

        prompt:InputHoldBegin()
        task.wait(0.02)
        prompt:InputHoldEnd()
    end)
end

-- ── 🛒 1. RIVER EGG PROMPTS DETECTOR (SÔNG MUA TRỨNG) ──
local function getRiverPrompts()
    local riverPrompts = {}
    local myPlot = getMyPlot()

    pcall(function()
        for _, prompt in ipairs(Workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                local parent = prompt.Parent
                if parent and not isOtherPlayerPlot(parent) then
                    -- Không phải nằm trong plot của chính mình
                    if not (myPlot and (parent == myPlot or parent:IsDescendantOf(myPlot))) then
                        local act = (prompt.ActionText or ""):lower()
                        local obj = (prompt.ObjectText or ""):lower()
                        local pName = parent.Name:lower()

                        -- Kiểm tra từ khóa mua hoặc trứng trôi sông
                        local isRiverBuy = act:find("buy") or act:find("purchase") or act:find("mua")
                                        or act:find("take") or act:find("claim") or act:find("grab") or act:find("pick")
                                        or obj:find("buy") or obj:find("egg") or obj:find("trứng")
                                        or pName:find("egg") or pName:find("conveyor") or pName:find("river")
                                        or pName:find("belt") or pName:find("stream")

                        -- Kiểm tra model cha
                        if not isRiverBuy then
                            local m = parent
                            while m and not m:IsA("Model") and m ~= Workspace do
                                m = m.Parent
                            end
                            if m and (m.Name:lower():find("egg") or m.Name:lower():find("conveyor") or m.Name:lower():find("river")) then
                                isRiverBuy = true
                            end
                        end

                        if isRiverBuy then
                            table.insert(riverPrompts, prompt)
                        end
                    end
                end
            end
        end
    end)

    return riverPrompts
end

-- ── 🥚 2. EGG PAD PROMPTS DETECTOR (BỆ ĐẤT GIEO & THU HOẠCH) ──
local function getEggPadPrompts(plot)
    if not plot then
        plot = getMyPlot()
    end
    local plantPrompt, harvestPrompt, padPart = nil, nil, nil

    local excludeKeywords = {
        "trash", "bin", "dump", "sell", "buy", "purchase", "mua", 
        "money", "cash", "coin", "collect money", "collect cash", "gom",
        "store", "shop", "vendor", "like", "reward", "group", "gift", "daily", "spin", "chest"
    }

    local candidatePrompts = {}

    -- Quét trong myPlot
    if plot then
        pcall(function()
            for _, desc in ipairs(plot:GetDescendants()) do
                if desc:IsA("ProximityPrompt") then
                    table.insert(candidatePrompts, desc)
                end
            end
        end)
    end

    -- Quét quanh 25 studs của nhân vật (bệ đất nơi đang đứng)
    pcall(function()
        local hrp = getRootPart()
        if hrp then
            for _, prompt in ipairs(Workspace:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") and not isOtherPlayerPlot(prompt.Parent) then
                    local pPart = prompt.Parent
                    local pos = pPart and (pPart:IsA("BasePart") and pPart.Position or (pPart:IsA("Model") and pPart.PrimaryPart and pPart.PrimaryPart.Position))
                    if pos and (pos - hrp.Position).Magnitude <= 25 then
                        local already = false
                        for _, cp in ipairs(candidatePrompts) do
                            if cp == prompt then already = true break end
                        end
                        if not already then
                            table.insert(candidatePrompts, prompt)
                        end
                    end
                end
            end
        end
    end)

    for _, desc in ipairs(candidatePrompts) do
        local act = (desc.ActionText or ""):lower()
        local obj = (desc.ObjectText or ""):lower()
        local pName = desc.Parent and desc.Parent.Name:lower() or ""

        local isExcluded = false
        for _, kw in ipairs(excludeKeywords) do
            if act:find(kw) or obj:find(kw) or pName:find(kw) then
                isExcluded = true break
            end
        end

        if not isExcluded then
            -- 1. Nút Thu Hoạch (Harvest)
            local isHarvest = act:find("harvest") or act:find("take") or act:find("pick") 
                           or act:find("claim") or act:find("hatch") or act:find("collect") 
                           or act:find("grab") or act:find("thu") or act:find("ấp") 
                           or act:find("lấy") or act:find("gặt") or act:find("nhặt")

            -- 2. Nút Gieo Trứng (Plant)
            local isPlant = not isHarvest and (act:find("plant") or act:find("place") or act:find("deposit") 
                                            or act:find("put") or act:find("sow") or act:find("gieo") 
                                            or act:find("đặt") or act:find("trồng") 
                                            or (obj:find("pad") and act == "") or (obj:find("plot") and act == ""))

            if isHarvest then
                if not harvestPrompt then
                    harvestPrompt = desc
                    padPart = desc.Parent
                end
            elseif isPlant then
                if not plantPrompt then
                    plantPrompt = desc
                    padPart = desc.Parent
                end
            end
        end
    end

    if not padPart and plot then
        padPart = plot:FindFirstChild("EggPad") or plot:FindFirstChild("Pad") or plot:FindFirstChild("Soil") or plot:FindFirstChild("GrowPad") or plot:FindFirstChild("Plot")
    end

    return plantPrompt, harvestPrompt, padPart
end

-- ── ⚡ 3. LIGHTNING THREAT DETECTOR (PHÁT HIỆN SÉT ĐÁNH) ──
local lastThreatDetectedTime = 0

local function checkLightningThreat(padPart, plot, plantStartTime)
    if not padPart then return false, nil end
    local hasThreat = false
    local strikeTime = nil

    pcall(function()
        local padPos = padPart:IsA("BasePart") and padPart.Position or (padPart:IsA("Model") and padPart.PrimaryPart and padPart.PrimaryPart.Position)
        if not padPos then return end

        for _, obj in ipairs(Workspace:GetChildren()) do
            local oName = obj.Name:lower()
            if oName:find("lightning") or oName:find("thunder") or oName:find("strike") or oName:find("storm") or oName:find("cloud") then
                local oPos = obj:IsA("BasePart") and obj.Position or (obj:IsA("Model") and obj.PrimaryPart and obj.PrimaryPart.Position)
                if oPos then
                    local horizontalDist = math.sqrt((oPos.X - padPos.X)^2 + (oPos.Z - padPos.Z)^2)
                    if horizontalDist <= 30 then
                        hasThreat = true
                        for _, desc in ipairs(obj:GetDescendants()) do
                            if desc:IsA("TextLabel") then
                                local num = desc.Text:match("([%d%.]+)s?")
                                if num then strikeTime = tonumber(num) end
                            end
                        end
                    end
                end
            end
        end

        if plot then
            for _, desc in ipairs(plot:GetDescendants()) do
                local dName = desc.Name:lower()
                if dName:find("lightning") or dName:find("cloud") or dName:find("target") then
                    hasThreat = true
                end
            end
        end
    end)

    return hasThreat, strikeTime
end

-- ── Movement & Anti-AFK ──
pcall(function()
    LocalPlayer.Idled:Connect(function()
        if State.AntiAFK then
            VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
            task.wait(1)
            VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
        end
    end)
end)

RunService.Stepped:Connect(function()
    if State.Noclip then
        local char = getCharacter()
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end
end)

RunService.RenderStepped:Connect(function(dt)
    if State.SpeedEnabled and State.CFrameBoost then
        local hrp = getRootPart()
        local hum = getHumanoid()
        if hrp and hum and hum.MoveDirection.Magnitude > 0 then
            hrp.CFrame = hrp.CFrame + (hum.MoveDirection * (State.CFrameSpeed * 10 * dt))
        end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if State.InfiniteJump then
        local hum = getHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ═══════════════════════════════════════════════════════════
-- 🎨 MODERN V28 OBSIDIAN GUI
-- ═══════════════════════════════════════════════════════════

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GreedyEggsGui"
ScreenGui.ResetOnSpawn = false
pcall(function() ScreenGui.Parent = getGuiContainer() end)

local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragInput, dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Floating Icon Button
local ToggleIcon = Instance.new("TextButton")
ToggleIcon.Name = "ToggleIcon"
ToggleIcon.Size = UDim2.new(0, 52, 0, 52)
ToggleIcon.Position = UDim2.new(0, 15, 0.25, 0)
ToggleIcon.BackgroundColor3 = Color3.fromRGB(14, 17, 24)
ToggleIcon.Text = "🥚"
ToggleIcon.TextSize = 26
ToggleIcon.Active = true
ToggleIcon.Parent = ScreenGui

local IconCorner = Instance.new("UICorner")
IconCorner.CornerRadius = UDim.new(1, 0)
IconCorner.Parent = ToggleIcon

local IconStroke = Instance.new("UIStroke")
IconStroke.Color = Color3.fromRGB(255, 200, 50)
IconStroke.Thickness = 2
IconStroke.Parent = ToggleIcon

makeDraggable(ToggleIcon)

-- Main Hub Window
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 340, 0, 540)
MainFrame.Position = UDim2.new(0.5, -170, 0.5, -270)
MainFrame.BackgroundColor3 = Color3.fromRGB(14, 17, 24)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(255, 200, 50)
MainStroke.Thickness = 1.6
MainStroke.Parent = MainFrame

ToggleIcon.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- Header Bar
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 46)
Header.BackgroundColor3 = Color3.fromRGB(20, 25, 36)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 14)
HeaderCorner.Parent = Header

makeDraggable(MainFrame, Header)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -76, 0, 22)
Title.Position = UDim2.new(0, 12, 0, 4)
Title.BackgroundTransparency = 1
Title.Text = "🥚 GREEDY EGGS - AUTO HUB V2.0"
Title.TextColor3 = Color3.fromRGB(255, 200, 50)
Title.TextSize = 12
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local SubTitle = Instance.new("TextLabel")
SubTitle.Size = UDim2.new(1, -76, 0, 14)
SubTitle.Position = UDim2.new(0, 12, 0, 26)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "🛒 Mua Sông Siêu Tốc & Auto Trồng / Né Sét"
SubTitle.TextColor3 = Color3.fromRGB(140, 155, 180)
SubTitle.TextSize = 10
SubTitle.Font = Enum.Font.Gotham
SubTitle.TextXAlignment = Enum.TextXAlignment.Left
SubTitle.Parent = Header

local MiniBtn = Instance.new("TextButton")
MiniBtn.Size = UDim2.new(0, 26, 0, 26)
MiniBtn.Position = UDim2.new(1, -60, 0, 10)
MiniBtn.BackgroundColor3 = Color3.fromRGB(40, 48, 68)
MiniBtn.Text = "−"
MiniBtn.TextColor3 = Color3.fromRGB(210, 225, 250)
MiniBtn.Font = Enum.Font.GothamBold
MiniBtn.TextSize = 15
MiniBtn.Parent = Header

local MiniCorner = Instance.new("UICorner")
MiniCorner.CornerRadius = UDim.new(0, 7)
MiniCorner.Parent = MiniBtn
MiniBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false end)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Position = UDim2.new(1, -30, 0, 10)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 65)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 13
CloseBtn.Parent = Header

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 7)
CloseCorner.Parent = CloseBtn
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Scrolling Body
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -16, 1, -84)
Scroll.Position = UDim2.new(0, 8, 0, 50)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 3
Scroll.ScrollBarImageColor3 = Color3.fromRGB(255, 200, 50)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.Parent = MainFrame

local Layout = Instance.new("UIListLayout")
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Padding = UDim.new(0, 6)
Layout.Parent = Scroll

-- Component: Section Header
local function createSectionHeader(titleText, accentColor)
    local col = accentColor or Color3.fromRGB(255, 200, 50)
    local secFrame = Instance.new("Frame")
    secFrame.Size = UDim2.new(1, 0, 0, 28)
    secFrame.BackgroundTransparency = 1
    secFrame.Parent = Scroll

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 3, 0, 16)
    bar.Position = UDim2.new(0, 2, 0.5, -8)
    bar.BackgroundColor3 = col
    bar.BorderSizePixel = 0
    bar.Parent = secFrame

    local bCorn = Instance.new("UICorner")
    bCorn.CornerRadius = UDim.new(1, 0)
    bCorn.Parent = bar

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -18, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = titleText
    lbl.TextColor3 = col
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = secFrame

    return secFrame
end

-- Component: Modern Toggle Card
local function createToggleButton(titleText, defaultState, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = defaultState and Color3.fromRGB(38, 32, 18) or Color3.fromRGB(20, 25, 34)
    btn.AutoButtonColor = false
    btn.Text = ""
    btn.Parent = Scroll

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = btn

    local s = Instance.new("UIStroke")
    s.Color = defaultState and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(38, 46, 62)
    s.Thickness = 1.2
    s.Parent = btn

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -72, 1, 0)
    titleLbl.Position = UDim2.new(0, 10, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = titleText
    titleLbl.TextColor3 = defaultState and Color3.fromRGB(255, 245, 220) or Color3.fromRGB(180, 192, 210)
    titleLbl.Font = Enum.Font.GothamMedium
    titleLbl.TextSize = 11
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = btn

    local badge = Instance.new("Frame")
    badge.Size = UDim2.new(0, 52, 0, 22)
    badge.Position = UDim2.new(1, -60, 0.5, -11)
    badge.BackgroundColor3 = defaultState and Color3.fromRGB(240, 180, 40) or Color3.fromRGB(35, 42, 56)
    badge.Parent = btn

    local badgeCorner = Instance.new("UICorner")
    badgeCorner.CornerRadius = UDim.new(0, 6)
    badgeCorner.Parent = badge

    local badgeText = Instance.new("TextLabel")
    badgeText.Size = UDim2.new(1, 0, 1, 0)
    badgeText.BackgroundTransparency = 1
    badgeText.Text = defaultState and "BẬT" or "TẮT"
    badgeText.TextColor3 = defaultState and Color3.fromRGB(20, 25, 35) or Color3.fromRGB(130, 142, 165)
    badgeText.Font = Enum.Font.GothamBold
    badgeText.TextSize = 10
    badgeText.Parent = badge

    local currentState = defaultState
    btn.MouseButton1Click:Connect(function()
        currentState = not currentState
        btn.BackgroundColor3 = currentState and Color3.fromRGB(38, 32, 18) or Color3.fromRGB(20, 25, 34)
        s.Color = currentState and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(38, 46, 62)
        titleLbl.TextColor3 = currentState and Color3.fromRGB(255, 245, 220) or Color3.fromRGB(180, 192, 210)
        badge.BackgroundColor3 = currentState and Color3.fromRGB(240, 180, 40) or Color3.fromRGB(35, 42, 56)
        badgeText.Text = currentState and "BẬT" or "TẮT"
        badgeText.TextColor3 = currentState and Color3.fromRGB(20, 25, 35) or Color3.fromRGB(130, 142, 165)
        callback(currentState, btn, s)
    end)

    return btn
end

-- Component: Action Button
local function createActionButton(titleText, valueText, accentColor, callback)
    local col = accentColor or Color3.fromRGB(255, 200, 50)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = Color3.fromRGB(20, 25, 34)
    btn.AutoButtonColor = false
    btn.Text = ""
    btn.Parent = Scroll

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = btn

    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(38, 46, 62)
    s.Thickness = 1
    s.Parent = btn

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -20, 0, 18)
    titleLbl.Position = UDim2.new(0, 10, 0, 2)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = titleText
    titleLbl.TextColor3 = col
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 11
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = btn

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(1, -20, 0, 15)
    valLbl.Position = UDim2.new(0, 10, 0, 18)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = valueText
    valLbl.TextColor3 = Color3.fromRGB(180, 195, 215)
    valLbl.Font = Enum.Font.Gotham
    valLbl.TextSize = 10
    valLbl.TextXAlignment = Enum.TextXAlignment.Left
    valLbl.Parent = btn

    btn.MouseButton1Click:Connect(function()
        callback(btn, valLbl, s)
    end)

    return btn, valLbl
end

-- Status Bar
local StatusFrame = Instance.new("Frame")
StatusFrame.Size = UDim2.new(1, 0, 0, 32)
StatusFrame.Position = UDim2.new(0, 0, 1, -32)
StatusFrame.BackgroundColor3 = Color3.fromRGB(10, 13, 19)
StatusFrame.BorderSizePixel = 0
StatusFrame.Parent = MainFrame

local StatusDot = Instance.new("Frame")
StatusDot.Size = UDim2.new(0, 7, 0, 7)
StatusDot.Position = UDim2.new(0, 10, 0.5, -3)
StatusDot.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
StatusDot.BorderSizePixel = 0
StatusDot.Parent = StatusFrame

local dotCorner = Instance.new("UICorner")
dotCorner.CornerRadius = UDim.new(1, 0)
dotCorner.Parent = StatusDot

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -28, 1, 0)
StatusLabel.Position = UDim2.new(0, 24, 0, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Sẵn sàng (Greedy Eggs Hub V2.0)."
StatusLabel.TextColor3 = Color3.fromRGB(200, 215, 235)
StatusLabel.TextSize = 10
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = StatusFrame

local function setStatus(txt)
    StatusLabel.Text = txt
end

-- ═══════════════════════════════════════════════════════════
-- SECTION 1: 🛒 AUTO MUA TRỨNG TRÊN SÔNG (RIVER AUTO BUY)
-- ═══════════════════════════════════════════════════════════
createSectionHeader("🛒 AUTO MUA TRỨNG TRÊN SÔNG", Color3.fromRGB(255, 200, 50))

createToggleButton("🛒 Bật Auto Mua Trứng Trên Sông", State.AutoBuy, function(v)
    State.AutoBuy = v
    setStatus(v and "Đang tự động mua trứng trôi trên sông..." or "Đã dừng Auto Mua Trứng.")
end)

createToggleButton("⚡ Auto Mua Tất Cả Trứng (Buy All)", State.AutoBuyAll, function(v)
    State.AutoBuyAll = v
    setStatus(v and "Chế độ: Mua toàn bộ trứng trôi qua sông!" or "Chế độ: Mua theo độ hiếm chọn lọc.")
end)

createToggleButton("🚀 River Assist (Lướt Nhặt Trứng Chuẩn 100%)", State.RiverProximityAssist, function(v)
    State.RiverProximityAssist = v
end)

createActionButton("⏱️ Tốc Độ Quét Mua Trứng Sông", "Hiện tại: [ " .. tostring(State.BuyDelay) .. "s ]", Color3.fromRGB(0, 255, 170), function(btn, lbl)
    State.BuyDelayIndex = State.BuyDelayIndex + 1
    if State.BuyDelayIndex > #ALL_BUY_DELAYS then State.BuyDelayIndex = 1 end
    State.BuyDelay = ALL_BUY_DELAYS[State.BuyDelayIndex]
    lbl.Text = "Hiện tại: [ " .. tostring(State.BuyDelay) .. "s ]"
end)

-- ═══════════════════════════════════════════════════════════
-- SECTION 2: 🥚 AUTO TRỒNG & THU HOẠCH (PLANT & HARVEST)
-- ═══════════════════════════════════════════════════════════
createSectionHeader("🥚 AUTO TRỒNG & THU HOẠCH NÉ SÉT", Color3.fromRGB(0, 200, 255))

createToggleButton("🌱 Bật Auto Trồng & Thu Hoạch (Auto Farm)", State.AutoPlant, function(v)
    State.AutoPlant = v
    setStatus(v and "Đang tự động gieo trứng, nuôi lớn & né sét..." or "Đã dừng Auto Farm Trứng.")
end)

createToggleButton("🛡️ Khiên Chống Sét Độc Lập 24/7", State.LightningShield247, function(v)
    State.LightningShield247 = v
    setStatus(v and "Khiên 24/7 BẬT: Bảo vệ trứng khỏi mọi tia sét!" or "Đã tắt Khiên Chống Sét 24/7.")
end)

createActionButton("⏱️ Căn Giờ Thu Hoạch Né Sét", "Thu hoạch trước khi sét đánh: [ " .. tostring(ALL_DODGE_TIMES[State.DodgeLeadTimeIndex]) .. "s ]", Color3.fromRGB(255, 140, 0), function(btn, lbl)
    State.DodgeLeadTimeIndex = State.DodgeLeadTimeIndex + 1
    if State.DodgeLeadTimeIndex > #ALL_DODGE_TIMES then State.DodgeLeadTimeIndex = 1 end
    lbl.Text = "Thu hoạch trước khi sét đánh: [ " .. tostring(ALL_DODGE_TIMES[State.DodgeLeadTimeIndex]) .. "s ]"
end)

createActionButton("🌱 Thời Gian Nuôi Trứng Tối Đa", "Thu hoạch sau khi nuôi: [ " .. tostring(ALL_GROWTH_TIMES[State.GrowthWaitIndex]) .. "s ]", Color3.fromRGB(0, 255, 170), function(btn, lbl)
    State.GrowthWaitIndex = State.GrowthWaitIndex + 1
    if State.GrowthWaitIndex > #ALL_GROWTH_TIMES then State.GrowthWaitIndex = 1 end
    lbl.Text = "Thu hoạch sau khi nuôi: [ " .. tostring(ALL_GROWTH_TIMES[State.GrowthWaitIndex]) .. "s ]"
end)

createActionButton("🥩 Thức Ăn May Mắn (Luck Food)", ALL_FOOD_DISPLAYS[State.SelectedFoodIndex], Color3.fromRGB(255, 215, 0), function(btn, lbl)
    State.SelectedFoodIndex = State.SelectedFoodIndex + 1
    if State.SelectedFoodIndex > #ALL_FOOD_TYPES then State.SelectedFoodIndex = 1 end
    lbl.Text = ALL_FOOD_DISPLAYS[State.SelectedFoodIndex]
end)

-- ═══════════════════════════════════════════════════════════
-- SECTION 3: 🦹 TRỘM TRỨNG & KINH TẾ (SELL & CASH)
-- ═══════════════════════════════════════════════════════════
createSectionHeader("🦹 TRỘM TRỨNG & KINH TẾ", Color3.fromRGB(255, 80, 120))

createToggleButton("🏃 Tự Chạy Trộm Trứng Cuối Map", State.AutoStealEndMap, function(v)
    State.AutoStealEndMap = v
    setStatus(v and "Đang bay tới bãi trộm cuối map săn trứng..." or "Đã dừng Auto Trộm Trứng.")
end)

createToggleButton("💰 Tự Hút Tiền Xu / Cash/s Trên Plot", State.AutoCollectCash, function(v)
    State.AutoCollectCash = v
end)

createToggleButton("💵 Tự Bán Thú/Trứng (Auto Sell)", State.AutoSell, function(v)
    State.AutoSell = v
end)

createToggleButton("🗑️ Tự Vứt Trứng Rác (Common/Rare)", State.AutoTrash, function(v)
    State.AutoTrash = v
end)

-- ═══════════════════════════════════════════════════════════
-- SECTION 4: 👁️ VISUALS & 3D EGG ESP
-- ═══════════════════════════════════════════════════════════
createSectionHeader("👁️ VISUALS & 3D EGG ESP", Color3.fromRGB(190, 130, 255))

local function clearESP()
    for _, h in pairs(ESPHighlights) do pcall(function() h:Destroy() end) end
    for _, b in pairs(ESPBillboards) do pcall(function() b:Destroy() end) end
    for _, c in pairs(ESPBeacons) do pcall(function() c:Destroy() end) end
    ESPHighlights = {}
    ESPBillboards = {}
    ESPBeacons = {}
end

local function updateESP(enable)
    clearESP()
    if not enable then return end

    local hrp = getRootPart()

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local nameLower = obj.Name:lower()
            if nameLower:find("egg") and not obj:IsDescendantOf(LocalPlayer) then
                pcall(function()
                    local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                    if part then
                        local rarity = detectEggRarity(obj)
                        local color = Color3.fromRGB(0, 255, 170)
                        if rarity == "Supreme" then color = Color3.fromRGB(255, 0, 128)
                        elseif rarity == "Secret" or rarity == "Divine" or rarity == "Godly" then color = Color3.fromRGB(255, 215, 0)
                        elseif rarity == "Mythical" then color = Color3.fromRGB(180, 50, 255)
                        elseif rarity == "Legendary" then color = Color3.fromRGB(255, 140, 0)
                        end

                        local hl = Instance.new("Highlight")
                        hl.Adornee = obj
                        hl.FillColor = color
                        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                        hl.FillTransparency = 0.4
                        hl.Parent = obj
                        table.insert(ESPHighlights, hl)

                        local bb = Instance.new("BillboardGui")
                        bb.Adornee = part
                        bb.AlwaysOnTop = true
                        bb.Size = UDim2.new(0, 170, 0, 42)
                        bb.StudsOffset = Vector3.new(0, 3.5, 0)
                        bb.MaxDistance = 8000
                        bb.Parent = part

                        local frame = Instance.new("Frame")
                        frame.Size = UDim2.new(1, 0, 1, 0)
                        frame.BackgroundColor3 = Color3.fromRGB(14, 18, 26)
                        frame.BackgroundTransparency = 0.25
                        frame.Parent = bb

                        local fCorner = Instance.new("UICorner")
                        fCorner.CornerRadius = UDim.new(0, 6)
                        fCorner.Parent = frame

                        local fStroke = Instance.new("UIStroke")
                        fStroke.Color = color
                        fStroke.Thickness = 1.2
                        fStroke.Parent = frame

                        local lbl = Instance.new("TextLabel")
                        lbl.Size = UDim2.new(1, 0, 0.55, 0)
                        lbl.BackgroundTransparency = 1
                        lbl.Text = "🥚 " .. obj.Name
                        lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                        lbl.Font = Enum.Font.GothamBold
                        lbl.TextSize = 10
                        lbl.Parent = frame

                        local sub = Instance.new("TextLabel")
                        sub.Size = UDim2.new(1, 0, 0.45, 0)
                        sub.Position = UDim2.new(0, 0, 0.55, 0)
                        sub.BackgroundTransparency = 1
                        local dist = hrp and math.floor((hrp.Position - part.Position).Magnitude) or 0
                        sub.Text = "[" .. rarity:upper() .. "] 📍 " .. dist .. "m"
                        sub.TextColor3 = color
                        sub.Font = Enum.Font.Gotham
                        sub.TextSize = 9
                        sub.Parent = frame

                        table.insert(ESPBillboards, bb)

                        if State.SkyBeacons and (rarity == "Supreme" or rarity == "Secret" or rarity == "Divine" or rarity == "Mythical" or rarity == "Legendary") then
                            local beacon = Instance.new("Part")
                            beacon.Size = Vector3.new(1.2, 400, 1.2)
                            beacon.CFrame = part.CFrame * CFrame.new(0, 200, 0)
                            beacon.Material = Enum.Material.Neon
                            beacon.Color = color
                            beacon.Transparency = 0.45
                            beacon.CanCollide = false
                            beacon.Anchored = true
                            beacon.Parent = Workspace
                            table.insert(ESPBeacons, beacon)
                        end
                    end
                end)
            end
        end
    end
end

createToggleButton("🔍 Bật 3D Egg ESP Xuyên Tường", State.EggESP, function(v)
    State.EggESP = v
    updateESP(v)
end)

createToggleButton("🗼 Bật Cột Sáng Lên Trời (Sky Beacon)", State.SkyBeacons, function(v)
    State.SkyBeacons = v
    updateESP(State.EggESP)
end)

createToggleButton("⚡ Chế Độ Siêu Mượt 60 FPS", State.FPSBoost, function(v)
    State.FPSBoost = v
    if v then
        pcall(function()
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            for _, fx in ipairs(Lighting:GetChildren()) do
                if fx:IsA("PostEffect") then fx.Enabled = false end
            end
            settings().Rendering.QualityLevel = 1
        end)
        setStatus("Đã bật chế độ 60 FPS siêu mượt!")
    end
end)

-- ═══════════════════════════════════════════════════════════
-- SECTION 5: 🏃 TỐC ĐỘ & TIỆN ÍCH
-- ═══════════════════════════════════════════════════════════
createSectionHeader("🏃 TỐC ĐỘ & TIỆN ÍCH", Color3.fromRGB(0, 200, 255))

createToggleButton("⚡ Bật Tăng Tốc Di Chuyển (Speed)", State.SpeedEnabled, function(v)
    State.SpeedEnabled = v
    local hum = getHumanoid()
    if hum then hum.WalkSpeed = v and State.WalkSpeed or 16 end
    setStatus(v and ("Tốc độ: " .. State.WalkSpeed) or "Đã về tốc độ bình thường.")
end)

createActionButton("⚡ Chỉnh Tốc Độ Di Chuyển", "Hiện tại: [ " .. tostring(State.WalkSpeed) .. " ]", Color3.fromRGB(0, 255, 170), function(btn, lbl)
    if State.WalkSpeed == 60 then State.WalkSpeed = 100
    elseif State.WalkSpeed == 100 then State.WalkSpeed = 150
    elseif State.WalkSpeed == 150 then State.WalkSpeed = 200
    elseif State.WalkSpeed == 200 then State.WalkSpeed = 250
    else State.WalkSpeed = 60 end
    lbl.Text = "Hiện tại: [ " .. tostring(State.WalkSpeed) .. " ]"
    if State.SpeedEnabled then
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = State.WalkSpeed end
    end
end)

createToggleButton("🦘 Nhảy Vô Hạn (Infinite Jump)", State.InfiniteJump, function(v)
    State.InfiniteJump = v
end)

createToggleButton("👻 Đi Xuyên Tường (Noclip)", State.Noclip, function(v)
    State.Noclip = v
end)

createToggleButton("🛡️ Chống Văng Game (Anti-AFK 24/7)", State.AntiAFK, function(v)
    State.AntiAFK = v
end)

-- ═══════════════════════════════════════════════════════════
-- 🔄 BACKGROUND AUTO WORKERS (ZERO LAG & HYPER RESPONSIVE)
-- ═══════════════════════════════════════════════════════════

-- 1. KHIÊN BẮT SÉT TỨC THÌ (Instant DescendantAdded 0ms)
Workspace.DescendantAdded:Connect(function(desc)
    pcall(function()
        local dName = desc.Name:lower()
        if dName:find("lightning") or dName:find("thunder") or dName:find("strike") or dName:find("storm") then
            local myPlot = getMyPlot()
            local _, harvestPrompt, padPart = getEggPadPrompts(myPlot)
            if harvestPrompt and padPart then
                local padPos = padPart:IsA("BasePart") and padPart.Position or (padPart:IsA("Model") and padPart.PrimaryPart and padPart.PrimaryPart.Position)
                if padPos and (desc:IsA("BasePart") or (desc:IsA("Model") and desc.PrimaryPart)) then
                    local dPos = desc:IsA("BasePart") and desc.Position or desc.PrimaryPart.Position
                    local dist = math.sqrt((dPos.X - padPos.X)^2 + (dPos.Z - padPos.Z)^2)
                    if dist <= 28 then
                        lastThreatDetectedTime = os.clock()
                        setStatus("🛡️ [KHIÊN 24/7] BẮT SÉT TỨC THÌ (0ms)! Thu hoạch trứng vào túi đồ an toàn!")
                        triggerPrompt(harvestPrompt)
                    end
                end
            end
        end
    end)
end)

-- 2. KHIÊN BẢO VỆ ĐỘC LẬP 24/7
task.spawn(function()
    while true do
        task.wait(0.02)
        if State.LightningShield247 and not State.AutoPlant then
            pcall(function()
                local myPlot = getMyPlot()
                local _, harvestPrompt, padPart = getEggPadPrompts(myPlot)
                if harvestPrompt then
                    local hasThreat, strikeTime = checkLightningThreat(padPart, myPlot, 0)
                    local recentThreat = (os.clock() - lastThreatDetectedTime) < 1.5
                    if hasThreat or recentThreat then
                        local info = strikeTime and (" (còn " .. string.format("%.1f", strikeTime) .. "s)") or ""
                        setStatus("🛡️ [KHIÊN 24/7] PHÁT HIỆN SÉT" .. info .. "! Đã thu hoạch trứng an toàn 100%!")
                        triggerPrompt(harvestPrompt)
                        task.wait(0.4)
                    end
                end
            end)
        end
    end
end)

-- 3. 🛒 AUTO MUA TRỨNG TRÊN SÔNG (RIVER AUTO BUY ENGINE)
task.spawn(function()
    while true do
        local delayTime = State.BuyDelay or 0.15
        task.wait(delayTime)

        if State.AutoBuy or State.AutoBuyAll then
            pcall(function()
                local prompts = getRiverPrompts()
                local hrp = getRootPart()

                for _, prompt in ipairs(prompts) do
                    if not prompt or not prompt.Parent then continue end
                    if isOtherPlayerPlot(prompt.Parent) then continue end

                    local model = prompt.Parent
                    while model and not model:IsA("Model") and model ~= Workspace do
                        model = model.Parent
                    end

                    local targetItem = (model and model:IsA("Model")) and model or prompt.Parent
                    local rarity = detectEggRarity(targetItem)
                    local shouldBuy = false

                    if State.AutoBuyAll then
                        shouldBuy = true
                    else
                        if SelectedRarities[rarity] == true then
                            shouldBuy = true
                        end
                    end

                    if shouldBuy then
                        local promptPos = prompt.Parent:IsA("BasePart") and prompt.Parent.Position or (targetItem:IsA("Model") and targetItem.PrimaryPart and targetItem.PrimaryPart.Position)

                        if State.RiverProximityAssist and hrp and promptPos then
                            local dist = (hrp.Position - promptPos).Magnitude
                            -- Nếu hơi xa (> 10 studs), lướt nhẹ đến nhặt rồi về lại plot
                            if dist > 10 and dist < 120 then
                                local origCFrame = hrp.CFrame
                                hrp.CFrame = CFrame.new(promptPos + Vector3.new(0, 3, 0))
                                task.wait(0.04)
                                triggerPrompt(prompt)
                                task.wait(0.04)

                                -- Quay về bệ đất nếu đang AutoPlant
                                if State.AutoPlant then
                                    local myPlot = getMyPlot()
                                    local _, _, padPart = getEggPadPrompts(myPlot)
                                    if padPart then
                                        local padPos = padPart:IsA("BasePart") and padPart.Position or (padPart:IsA("Model") and padPart.PrimaryPart and padPart.PrimaryPart.Position)
                                        if padPos then
                                            hrp.CFrame = CFrame.new(padPos + Vector3.new(0, 3, 0))
                                        end
                                    end
                                end
                            else
                                triggerPrompt(prompt)
                            end
                        else
                            triggerPrompt(prompt)
                        end

                        setStatus("🛒 Mua trứng trên sông: [" .. rarity .. "] " .. (targetItem and targetItem.Name or "Egg"))
                        task.wait(0.05)
                    end
                end
            end)
        end
    end
end)

-- 4. 🥚 AUTO GIEO TRỨNG & THU HOẠCH NÉ SÉT (AUTOPLANT & HARVEST ENGINE)
local plantStartTime = 0

task.spawn(function()
    while true do
        task.wait(0.02)
        if State.AutoPlant then
            pcall(function()
                local myPlot = getMyPlot()
                local plantPrompt, harvestPrompt, padPart = getEggPadPrompts(myPlot)
                local targetDodgeLead = ALL_DODGE_TIMES[State.DodgeLeadTimeIndex] or 2.0
                local targetGrowthTime = ALL_GROWTH_TIMES[State.GrowthWaitIndex] or 15
                local hrp = getRootPart()

                -- 4.1 NẾU TRỨNG ĐANG TRÊN BỆ (THEO DÕI LỚN & NÉ SÉT ĐỂ THU HOẠCH)
                if harvestPrompt then
                    if plantStartTime == 0 then plantStartTime = os.clock() end
                    local elapsedTime = os.clock() - plantStartTime
                    local hasThreat, strikeTime = checkLightningThreat(padPart, myPlot, plantStartTime)

                    if hasThreat and State.AutoDodgeLightning then
                        if strikeTime and strikeTime > targetDodgeLead then
                            setStatus("⚡ SÉT CỦA BẠN (còn " .. string.format("%.1f", strikeTime) .. "s)... Căn né trước " .. targetDodgeLead .. "s")
                        else
                            local info = strikeTime and (" (còn " .. string.format("%.1f", strikeTime) .. "s)") or ""
                            setStatus("⚡ SÉT ĐÁNH VÀO TỔ TRỨNG" .. info .. "! Thu hoạch NÉ SÉT ngay!")

                            if hrp and padPart then
                                local padPos = padPart:IsA("BasePart") and padPart.Position or (padPart:IsA("Model") and padPart.PrimaryPart and padPart.PrimaryPart.Position)
                                if padPos and (hrp.Position - padPos).Magnitude > 15 then
                                    hrp.CFrame = CFrame.new(padPos + Vector3.new(0, 3, 0))
                                end
                            end

                            triggerPrompt(harvestPrompt)
                            plantStartTime = 0
                            task.wait(0.4)
                        end
                    else
                        if elapsedTime >= targetGrowthTime then
                            setStatus("🥚 Trứng đã nuôi đủ " .. math.floor(elapsedTime) .. "s -> Thu hoạch thành công!")

                            if hrp and padPart then
                                local padPos = padPart:IsA("BasePart") and padPart.Position or (padPart:IsA("Model") and padPart.PrimaryPart and padPart.PrimaryPart.Position)
                                if padPos and (hrp.Position - padPos).Magnitude > 15 then
                                    hrp.CFrame = CFrame.new(padPos + Vector3.new(0, 3, 0))
                                end
                            end

                            triggerPrompt(harvestPrompt)
                            plantStartTime = 0
                            task.wait(0.4)
                        else
                            setStatus("🥚 Đang nuôi trứng (" .. math.floor(elapsedTime) .. "s/" .. targetGrowthTime .. "s)... Theo dõi sét ⚡")
                            task.wait(0.1)
                        end
                    end
                elseif plantPrompt then
                    -- 4.2 BỆ ĐANG TRỐNG -> TIẾN HÀNH LẤY TRỨNG TỪ TÚI ĐỒ RA GIEO
                    plantStartTime = 0
                    local bp = LocalPlayer:FindFirstChild("Backpack")
                    local char = getCharacter()
                    local eggTool = nil

                    -- Kiểm tra tool trên tay
                    if char then
                        for _, t in ipairs(char:GetChildren()) do
                            if t:IsA("Tool") then
                                local tName = t.Name:lower()
                                if tName:find("egg") or t:GetAttribute("Rarity") or t:FindFirstChild("Rarity") then
                                    eggTool = t
                                    break
                                end
                            end
                        end
                    end

                    -- Kiểm tra tool trong Backpack
                    if not eggTool and bp then
                        for _, t in ipairs(bp:GetChildren()) do
                            if t:IsA("Tool") then
                                local tName = t.Name:lower()
                                if tName:find("egg") or t:GetAttribute("Rarity") or t:FindFirstChild("Rarity") then
                                    eggTool = t
                                    break
                                end
                            end
                        end
                        -- Fallback nếu tên tool không có chữ egg
                        if not eggTool and bp then
                            for _, t in ipairs(bp:GetChildren()) do
                                if t:IsA("Tool") then
                                    eggTool = t
                                    break
                                end
                            end
                        end
                    end

                    if eggTool then
                        if char and eggTool.Parent == bp then
                            eggTool.Parent = char
                            task.wait(0.12)
                        end

                        if hrp and padPart then
                            local padPos = padPart:IsA("BasePart") and padPart.Position or (padPart:IsA("Model") and padPart.PrimaryPart and padPart.PrimaryPart.Position)
                            if padPos and (hrp.Position - padPos).Magnitude > 12 then
                                hrp.CFrame = CFrame.new(padPos + Vector3.new(0, 3, 0))
                                task.wait(0.08)
                            end
                        end

                        setStatus("🌱 Đang gieo trứng: " .. eggTool.Name .. "...")
                        triggerPrompt(plantPrompt)
                        task.wait(0.35)
                    else
                        setStatus("⏳ Túi đồ hết trứng! Đang chờ mua thêm từ sông...")
                        task.wait(0.4)
                    end
                else
                    plantStartTime = 0
                    setStatus("🔍 Đang tìm bệ trứng trên Plot của bạn...")
                    task.wait(0.5)
                end
            end)
        end
    end
end)

-- 5. AUTO TRỘM TRỨNG CUỐI MAP
task.spawn(function()
    while true do
        task.wait(1.5)
        if State.AutoStealEndMap then
            pcall(function()
                local hrp = getRootPart()
                if not hrp then return end

                local bestEggPart = nil
                local bestPrompt = nil
                local bestZ = -9e9

                for _, prompt in ipairs(Workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") then
                        local act = (prompt.ActionText or ""):lower()
                        local obj = (prompt.ObjectText or ""):lower()
                        if (act:find("steal") or act:find("trộm") or act:find("pick") or act:find("take") or obj:find("egg")) and not isOtherPlayerPlot(prompt.Parent) then
                            local part = prompt.Parent:IsA("BasePart") and prompt.Parent or prompt.Parent:FindFirstChildWhichIsA("BasePart")
                            if part and part.Position.Z > bestZ then
                                bestZ = part.Position.Z
                                bestEggPart = part
                                bestPrompt = prompt
                            end
                        end
                    end
                end

                if bestEggPart and bestPrompt then
                    setStatus("🦹 Đang bay đến trộm trứng cuối map...")
                    hrp.CFrame = bestEggPart.CFrame * CFrame.new(0, 3.5, 0)
                    task.wait(0.2)
                    triggerPrompt(bestPrompt)
                    task.wait(0.3)
                end
            end)
        end
    end
end)

-- 6. AUTO COLLECT CASH/S ORBS
task.spawn(function()
    while true do
        task.wait(0.5)
        if State.AutoCollectCash then
            pcall(function()
                local hrp = getRootPart()
                if not hrp then return end
                for _, obj in ipairs(Workspace:GetChildren()) do
                    local name = obj.Name:lower()
                    if obj:IsA("BasePart") and (name:find("coin") or name:find("cash") or name:find("gem") or name:find("orb") or name:find("drop")) then
                        obj.CFrame = hrp.CFrame
                    end
                end
            end)
        end
    end
end)

-- 7. ESP REFRESH LOOP
task.spawn(function()
    while true do
        task.wait(4)
        if State.EggESP then
            updateESP(true)
        end
    end
end)

task.defer(function()
    task.wait(1.5)
    if State.EggESP then updateESP(true) end
end)

setStatus("✅ Đã khởi chạy Greedy Eggs Hub V2.0 thành công!")
