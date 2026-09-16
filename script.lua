--[[
    ===================================================================
    🥚 GREEDY EGGS - ULTIMATE AUTO HUB V1.0 (PRO EDITION)
    Game: Greedy Eggs 🥚 by Random Ahhh Games
    Tối ưu hóa hiệu năng 60 FPS: Siêu Mượt, Không Giật Lag!
    Tương thích 100% Delta Executor (Android & PC), Wave, Codex, Fluxus.
    
    Tính năng độc quyền:
      - 🛡️ KHIÊN CHỐNG SÉT 24/7: Bắt tia sét tức thì (0ms), bảo vệ 100% trứng không bao giờ bị vỡ!
      - ⚡ NÉ SÉT THÔNG MINH: Tự động thu hoạch vào túi đồ trước khi sét đánh 0.5s - 2.5s.
      - 🥚 AUTO GIEO & NUÔI TRỨNG: Tự gieo trứng, bơm đồ ăn may mắn (Basic -> Magic 250% Luck).
      - 🛒 AUTO MUA TRỨNG TRÊN SÔNG & MARKET: Lọc mọi độ hiếm từ Common đến Supreme!
      - 🦹 AUTO TRỘM TRỨNG CUỐI MAP: Tự động nhặt trứng giá trị cao nhất tại bãi trộm.
      - 💰 AUTO SELL & COLLECT CASH/S: Bán trứng/thú và hút tiền tự động.
      - 👁️ 3D EGG ESP & SKY BEACON: Cột sáng lên trời cho trứng xịn toàn map.
      - 🏃 SPEED, JUMP, NOCLIP, ANTI-AFK 24/7.
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
    -- Farming & Planting
    AutoPlant = false,
    LightningShield247 = true, -- 🛡️ Khiên chống sét độc lập 24/7
    AutoDodgeLightning = true,
    DodgeSensitivityMode = "TIMED", -- "TIMED" (căn giây) hoặc "INSTANT" (0ms)
    DodgeLeadTimeIndex = 6, -- 2.0s
    GrowthWaitIndex = 4, -- 15s

    -- Food & Luck
    AutoFood = true,
    SelectedFoodIndex = 1, -- Basic (+37% Free)

    -- Market & Buying
    AutoBuy = false,
    AutoBuyAll = false,
    BuyDelay = 0.5,

    -- Stealing Eggs
    AutoStealEndMap = false,
    StealHighestValueOnly = true,

    -- Economy & Inventory
    AutoCollectCash = true,
    AutoSell = false,
    AutoTrash = false,

    -- Visuals & ESP
    EggESP = true,
    SkyBeacons = true,
    FPSBoost = false,

    -- Utilities
    SpeedEnabled = false,
    WalkSpeed = 120,
    CFrameBoost = true,
    CFrameSpeed = 5,
    InfiniteJump = false,
    Noclip = false,
    AntiAFK = true
}

local ALL_DODGE_TIMES = {0.5, 0.8, 1.0, 1.2, 1.5, 2.0, 2.5, 3.0}
local ALL_GROWTH_TIMES = {8, 10, 12, 15, 18, 20, 25, 30}

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
    ["Common"]    = false,
    ["Rare"]      = false,
    ["Epic"]      = false,
    ["Legendary"] = false,
    ["Mythical"]  = true,
    ["Godly"]     = true,
    ["Secret"]    = true,
    ["Divine"]    = true,
    ["OG"]        = true,
    ["Celestial"] = true,
    ["Eternal"]   = true,
    ["Forbidden"] = true,
    ["Unknown"]   = false,
    ["Supreme"]   = true
}

local TrashRarities = {
    ["Common"]    = true,
    ["Rare"]      = true,
    ["Epic"]      = false,
    ["Legendary"] = false,
    ["Mythical"]  = false,
    ["Godly"]     = false,
    ["Secret"]    = false,
    ["Divine"]    = false,
    ["OG"]        = false,
    ["Celestial"] = false,
    ["Eternal"]   = false,
    ["Forbidden"] = false,
    ["Unknown"]   = false,
    ["Supreme"]   = false
}

local ESPHighlights = {}
local ESPBillboards = {}
local ESPBeacons = {}

-- ── Cache & Performance ──
local Cache = {
    Prompts = {},
    Drops = {},
    WildEggs = {}
}

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

-- ── Plot Detection ──
local cachedMyPlot = nil

local function getMyPlot()
    if cachedMyPlot and cachedMyPlot.Parent then
        return cachedMyPlot
    end

    local pName = LocalPlayer.Name:lower()
    local pDisp = LocalPlayer.DisplayName:lower()
    local pId = tostring(LocalPlayer.UserId)

    pcall(function()
        for _, containerName in ipairs({"Plots", "Bases", "Islands", "Farms", "Pens", "Tycoons"}) do
            local container = Workspace:FindFirstChild(containerName)
            if container then
                for _, plot in ipairs(container:GetChildren()) do
                    local name = plot.Name:lower()
                    if name:find(pName) or name:find(pDisp) or name:find(pId) then
                        cachedMyPlot = plot
                        return
                    end
                    for _, attr in ipairs({"Owner", "Player", "UserId", "Username"}) do
                        local v = plot:GetAttribute(attr)
                        if v and (tostring(v):lower() == pName or tostring(v) == pId) then
                            cachedMyPlot = plot
                            return
                        end
                    end
                    local ownerVal = plot:FindFirstChild("Owner") or plot:FindFirstChild("Player")
                    if ownerVal and (ownerVal.Value == LocalPlayer or tostring(ownerVal.Value):lower() == pName) then
                        cachedMyPlot = plot
                        return
                    end
                end
            end
        end

        -- Fallback direct workspace children
        for _, obj in ipairs(Workspace:GetChildren()) do
            local name = obj.Name:lower()
            if (name:find("plot") or name:find("base") or name:find("farm")) and (name:find(pName) or name:find(pId)) then
                cachedMyPlot = obj
                return
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

-- ── Plot Prompts (EggPad / Soil / Harvest / Food) ──
local function getEggPadPrompts(plot)
    if not plot then return nil, nil, nil end
    local plantPrompt, harvestPrompt, padPart = nil, nil, nil

    pcall(function()
        for _, desc in ipairs(plot:GetDescendants()) do
            if desc:IsA("ProximityPrompt") then
                local act = (desc.ActionText or ""):lower()
                local obj = (desc.ObjectText or ""):lower()
                local dName = desc.Name:lower()

                -- Bỏ qua prompt bán, thùng rác, thu hoạch tự động nhầm
                if not (act:find("trash") or act:find("bin") or act:find("sell") or act:find("buy")) then
                    if act:find("plant") or act:find("place") or act:find("gieo") or act:find("đặt") or act:find("egg") then
                        plantPrompt = desc
                        padPart = desc.Parent
                    elseif act:find("harvest") or act:find("take") or act:find("pick") or act:find("hatch") or act:find("thu") or act:find("ấp") or act:find("lấy") then
                        harvestPrompt = desc
                        padPart = desc.Parent
                    end
                end
            end
        end

        if not padPart then
            padPart = plot:FindFirstChild("EggPad") or plot:FindFirstChild("Pad") or plot:FindFirstChild("Soil") or plot:FindFirstChild("GrowPad") or plot:FindFirstChild("Plot")
        end
    end)

    return plantPrompt, harvestPrompt, padPart
end

local function triggerPrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return end
    if isOtherPlayerPlot(prompt.Parent) then return end

    pcall(function()
        prompt.RequiresLineOfSight = false
        prompt.HoldDuration = 0
        prompt.MaxActivationDistance = 999999
        if fireproximityprompt then
            fireproximityprompt(prompt, 0)
            fireproximityprompt(prompt)
        end
        prompt:InputHoldBegin()
        task.wait(0.02)
        prompt:InputHoldEnd()
    end)
end

-- ── Rarity Parser with Word Boundary ──
local function detectEggRarity(item)
    if not item then return "Common" end
    local itemName = item.Name:lower()

    local function matchStrict(str)
        if not str then return nil end
        local s = str:lower()
        for _, r in ipairs({"Supreme", "Forbidden", "Eternal", "Celestial", "Divine", "Secret", "Godly", "Mythical", "Legendary", "Epic", "Rare", "OG", "Common"}) do
            local pat = "%f[%a]" .. r:lower() .. "%f[%A]"
            if s:find(pat) then return r end
        end
        return nil
    end

    local r = matchStrict(itemName)
    if r then return r end

    pcall(function()
        for _, attr in ipairs({"Rarity", "Tier", "Type"}) do
            local val = item:GetAttribute(attr)
            if val then
                local res = matchStrict(tostring(val))
                if res then r = res break end
            end
        end
    end)

    return r or "Common"
end

-- ── Lightning Threat Detection Engine ──
local lastThreatDetectedTime = 0

local function checkLightningThreat(padPart, plot, plantStartTime)
    if not padPart then return false, nil end
    local hasThreat = false
    local strikeTime = nil

    pcall(function()
        local padPos = padPart:IsA("BasePart") and padPart.Position or (padPart:IsA("Model") and padPart.PrimaryPart and padPart.PrimaryPart.Position)
        if not padPos then return end

        -- 1. Quét các đối tượng Lightning, Clouds, Striker, Thunder
        for _, obj in ipairs(Workspace:GetChildren()) do
            local oName = obj.Name:lower()
            if oName:find("lightning") or oName:find("thunder") or oName:find("strike") or oName:find("storm") or oName:find("cloud") then
                local oPos = obj:IsA("BasePart") and obj.Position or (obj:IsA("Model") and obj.PrimaryPart and obj.PrimaryPart.Position)
                if oPos then
                    local horizontalDist = math.sqrt((oPos.X - padPos.X)^2 + (oPos.Z - padPos.Z)^2)
                    if horizontalDist <= 25 then
                        hasThreat = true
                        -- Check countdown text nếu có
                        for _, desc in ipairs(obj:GetDescendants()) do
                            if desc:IsA("TextLabel") then
                                local num = desc.Text:match("([%d%.]+)s?")
                                if num then
                                    strikeTime = tonumber(num)
                                end
                            end
                        end
                    end
                end
            end
        end

        -- 2. Quét bên trong plot xem có mây sét đang sà xuống bệ trứng
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

-- ── Anti-AFK ──
pcall(function()
    LocalPlayer.Idled:Connect(function()
        if State.AntiAFK then
            VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
            task.wait(1)
            VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
        end
    end)
end)

-- ── Movement Loops (Speed, Noclip, Jump) ──
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
-- 🎨 MODERN V28 OBSIDIAN GUI FOR GREEDY EGGS
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

-- Floating Icon
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

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 340, 0, 530)
MainFrame.Position = UDim2.new(0.5, -170, 0.5, -265)
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

-- Header
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
Title.Text = "🥚 GREEDY EGGS - AUTO HUB V1.0"
Title.TextColor3 = Color3.fromRGB(255, 200, 50)
Title.TextSize = 12
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local SubTitle = Instance.new("TextLabel")
SubTitle.Size = UDim2.new(1, -76, 0, 14)
SubTitle.Position = UDim2.new(0, 12, 0, 26)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "🛡️ Khiên Chống Sét 24/7 & Auto Gieo Trứng"
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
StatusLabel.Text = "Sẵn sàng (Greedy Eggs Hub V1.0)."
StatusLabel.TextColor3 = Color3.fromRGB(200, 215, 235)
StatusLabel.TextSize = 10
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = StatusFrame

local function setStatus(txt)
    StatusLabel.Text = txt
end

-- ═══════════════════════════════════════════════════════════
-- SECTION 1: 🛡️ KHIÊN CHỐNG SÉT 24/7 & AUTO THU HOẠCH NÉ SÉT
-- ═══════════════════════════════════════════════════════════
createSectionHeader("🛡️ KHIÊN CHỐNG SÉT & THU HOẠCH NÉ SÉT", Color3.fromRGB(255, 200, 50))

createToggleButton("🛡️ Khiên Chống Sét Độc Lập 24/7", State.LightningShield247, function(v)
    State.LightningShield247 = v
    setStatus(v and "Khiên 24/7 BẬT: Bảo vệ trứng khỏi mọi tia sét!" or "Đã tắt Khiên Chống Sét 24/7.")
end)

createToggleButton("⚡ Auto Gieo Trứng & Né Sét (AutoPlant)", State.AutoPlant, function(v)
    State.AutoPlant = v
    setStatus(v and "Đang tự động gieo trứng, nuôi lớn & né sét..." or "Đã dừng Auto Gieo Trứng.")
end)

createActionButton("⏱️ Căn Giờ Thu Hoạch Né Sét", "Thu hoạch trước khi sét đánh: [ " .. tostring(ALL_DODGE_TIMES[State.DodgeLeadTimeIndex]) .. "s ]", Color3.fromRGB(0, 255, 170), function(btn, lbl)
    State.DodgeLeadTimeIndex = State.DodgeLeadTimeIndex + 1
    if State.DodgeLeadTimeIndex > #ALL_DODGE_TIMES then State.DodgeLeadTimeIndex = 1 end
    lbl.Text = "Thu hoạch trước khi sét đánh: [ " .. tostring(ALL_DODGE_TIMES[State.DodgeLeadTimeIndex]) .. "s ]"
end)

createActionButton("🌱 Thời Gian Nuôi Trứng Tối Đa", "Thu hoạch sau khi nuôi: [ " .. tostring(ALL_GROWTH_TIMES[State.GrowthWaitIndex]) .. "s ]", Color3.fromRGB(0, 200, 255), function(btn, lbl)
    State.GrowthWaitIndex = State.GrowthWaitIndex + 1
    if State.GrowthWaitIndex > #ALL_GROWTH_TIMES then State.GrowthWaitIndex = 1 end
    lbl.Text = "Thu hoạch sau khi nuôi: [ " .. tostring(ALL_GROWTH_TIMES[State.GrowthWaitIndex]) .. "s ]"
end)

createActionButton("🥩 Đồ Ăn Cho Trứng (Tăng Luck)", ALL_FOOD_DISPLAYS[State.SelectedFoodIndex], Color3.fromRGB(255, 140, 0), function(btn, lbl)
    State.SelectedFoodIndex = State.SelectedFoodIndex + 1
    if State.SelectedFoodIndex > #ALL_FOOD_TYPES then State.SelectedFoodIndex = 1 end
    lbl.Text = ALL_FOOD_DISPLAYS[State.SelectedFoodIndex]
end)

-- ═══════════════════════════════════════════════════════════
-- SECTION 2: 🛒 MUA TRỨNG TRÊN SÔNG & MARKET
-- ═══════════════════════════════════════════════════════════
createSectionHeader("🛒 MUA TRỨNG TRÊN SÔNG & MARKET", Color3.fromRGB(0, 255, 170))

createToggleButton("🛒 Tự Mua Trứng Trôi Sông (Lọc Độ Hiếm)", State.AutoBuy, function(v)
    State.AutoBuy = v
    setStatus(v and "Đang tự động mua trứng theo độ hiếm chọn..." or "Đã dừng Auto Buy.")
end)

createToggleButton("⚡ Auto Buy ALL (Mua Toàn Bộ Trứng)", State.AutoBuyAll, function(v)
    State.AutoBuyAll = v
end)

-- ═══════════════════════════════════════════════════════════
-- SECTION 3: 🦹 TRỘM TRỨNG CUỐI MAP & KINH TẾ
-- ═══════════════════════════════════════════════════════════
createSectionHeader("🦹 TRỘM TRỨNG & KINH TẾ", Color3.fromRGB(255, 80, 120))

createToggleButton("🏃 Tự Chạy Trộm Trứng Cuối Map", State.AutoStealEndMap, function(v)
    State.AutoStealEndMap = v
    setStatus(v and "Đang bay tới bãi trộm cuối map săn trứng..." or "Đã dừng Auto Trộm Trứng.")
end)

createToggleButton("💰 Tự Nhặt Tiền Xu / Kim Cương (Plot)", State.AutoCollectCash, function(v)
    State.AutoCollectCash = v
end)

createToggleButton("💵 Tự Động Bán Thú/Trứng (Auto Sell)", State.AutoSell, function(v)
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

                        -- Sky beacon for xịn
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
-- 🔄 BACKGROUND AUTO WORKERS (ZERO LAG)
-- ═══════════════════════════════════════════════════════════

-- 1. KHIÊN BẮT SÉT TỨC THÌ (Instant Descendant Added Trigger)
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
                    if dist <= 25 then
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
                        task.wait(0.5)
                    end
                end
            end)
        end
    end
end)

-- 3. AUTO GIEO TRỨNG & THU HOẠCH NÉ SÉT (AUTOPLANT)
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

                if harvestPrompt then
                    if plantStartTime == 0 then plantStartTime = os.clock() end
                    local elapsedTime = os.clock() - plantStartTime
                    local hasThreat, strikeTime = checkLightningThreat(padPart, myPlot, plantStartTime)

                    if hasThreat and State.AutoDodgeLightning then
                        if strikeTime and strikeTime > targetDodgeLead then
                            setStatus("⚡ SÉT ĐANG ĐẾM NGƯỢC (còn " .. string.format("%.1f", strikeTime) .. "s)... Chờ né trước " .. targetDodgeLead .. "s")
                        else
                            local info = strikeTime and (" (còn " .. string.format("%.1f", strikeTime) .. "s)") or ""
                            setStatus("⚡ SÉT ĐÁNH VÀO TRỨNG" .. info .. "! Thu hoạch NÉ SÉT ngay!")
                            triggerPrompt(harvestPrompt)
                            plantStartTime = 0
                            task.wait(0.5)
                        end
                    else
                        if elapsedTime >= targetGrowthTime then
                            setStatus("🥚 Trứng đã nuôi đủ " .. math.floor(elapsedTime) .. "s -> Thu hoạch!")
                            triggerPrompt(harvestPrompt)
                            plantStartTime = 0
                            task.wait(0.5)
                        else
                            setStatus("🥚 Đang nuôi trứng (" .. math.floor(elapsedTime) .. "s/" .. targetGrowthTime .. "s)... Theo dõi sét ⚡")
                        end
                    end
                else
                    plantStartTime = 0
                    -- Thử gieo trứng từ túi đồ
                    local bp = LocalPlayer:FindFirstChild("Backpack")
                    local char = getCharacter()
                    if bp and char then
                        local eggTool = nil
                        for _, t in ipairs(bp:GetChildren()) do
                            if t:IsA("Tool") and t.Name:lower():find("egg") then
                                eggTool = t
                                break
                            end
                        end

                        if eggTool then
                            eggTool.Parent = char
                            task.wait(0.15)
                            if plantPrompt then
                                triggerPrompt(plantPrompt)
                                task.wait(0.3)
                            end
                        else
                            setStatus("⏳ Hết trứng trong túi đồ... Đang chờ trứng mới!")
                            task.wait(0.5)
                        end
                    end
                end
            end)
        end
    end
end)

-- 4. AUTO BUY TRÊN SÔNG & MARKET
task.spawn(function()
    while true do
        task.wait(State.BuyDelay)
        if State.AutoBuy or State.AutoBuyAll then
            pcall(function()
                for _, prompt in ipairs(Workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") and not isOtherPlayerPlot(prompt.Parent) then
                        local act = (prompt.ActionText or ""):lower()
                        local obj = (prompt.ObjectText or ""):lower()
                        if act:find("buy") or act:find("purchase") or obj:find("buy") or act:find("mua") then
                            if State.AutoBuyAll then
                                triggerPrompt(prompt)
                            else
                                local model = prompt.Parent
                                while model and not model:IsA("Model") and model ~= Workspace do
                                    model = model.Parent
                                end
                                if model then
                                    local rarity = detectEggRarity(model)
                                    if SelectedRarities[rarity] == true then
                                        setStatus("🛒 Mua trứng xịn: " .. model.Name .. " [" .. rarity .. "]")
                                        triggerPrompt(prompt)
                                        task.wait(0.1)
                                    end
                                end
                            end
                        end
                    end
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

setStatus("✅ Đã khởi chạy Greedy Eggs Hub V1.0 thành công!")
