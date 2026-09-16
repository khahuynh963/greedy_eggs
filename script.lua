--[[
    ===================================================================
    🥚 TRỨNG THAM LAM (GREEDY EGGS) - ULTIMATE AUTO HUB V2.2
    Game: Greedy Eggs 🥚 by Random Ahhh Games
    
    🎮 ĐÚNG 100% THEO CƠ CHẾ GỐC CỦA GAME:
      1. 🥚 Mua một quả trứng từ con sông (Auto Buy River Eggs)
      2. 🌱 Trồng nó trong khu đất của bạn (Auto Plant into Plot)
      3. 🥚 Xem trứng của bạn phát triển (Auto Grow Eggs)
      4. 🦖 Ấp những con vật điên rồ (Hatch Crazy Animals)
      5. ⚡ Thu hoạch trước khi sét đánh! (Harvest Before Lightning Strikes)
      6. 💰 Bán con vật & Tự hút tiền Cash/s để tái đầu tư trứng xịn hơn
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
    -- 1. Mua Trứng Từ Con Sông (River Auto Buy)
    AutoBuy = true, -- BẬT MẶC ĐỊNH
    AutoBuyAll = true,
    BuyDelayIndex = 3, -- 0.3s
    BuyDelay = 0.3,
    RiverProximityAssist = true, -- BẬT HỖ TRỢ TIẾP CẬN ĐỂ MUA ĂN NGAY 100%

    -- 2. Trồng Trứng & Thu Hoạch Né Sét (Plant & Harvest)
    AutoPlant = true, -- BẬT MẶC ĐỊNH
    LightningShield247 = true, -- Khiên bảo vệ độc lập 24/7 (Siêu tối ưu 0ms, Zero Lag)
    AutoDodgeLightning = true,
    DodgeLeadTimeIndex = 6, -- 2.0s
    GrowthWaitIndex = 4, -- 15s

    -- 3. Thức Ăn May Mắn (Luck Food)
    AutoFood = false,
    SelectedFoodIndex = 1, -- Basic (+37% Free)

    -- 4. Bán Con Vật & Thu Tiền (Economy)
    AutoCollectCash = true,
    AutoSell = false,
    AutoTrash = false,

    -- 5. Visuals & ESP (Tắt mặc định để máy siêu mượt 60 FPS)
    EggESP = false,
    SkyBeacons = false,
    FPSBoost = true, -- BẬT MẶC ĐỊNH SIÊU MƯỢT!

    -- 6. Utilities
    SpeedEnabled = false,
    WalkSpeed = 100,
    CFrameBoost = false,
    CFrameSpeed = 3,
    InfiniteJump = false,
    Noclip = false,
    AntiAFK = true
}

local cachedMyPlot = nil
local cachedPadPart = nil
local cachedPlantPrompt = nil
local cachedHarvestPrompt = nil
local cachedPadPos = nil
local cachedRiverPrompts = {}
local lastRiverScanTime = 0
local lastThreatDetectedTime = 0
local lastPlotScanTime = 0

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

-- ── Plot Detection Engine (Khu Đất Của Bạn) ──
local cachedMyPlot = nil

local function getMyPlot()
    if cachedMyPlot and cachedMyPlot.Parent then
        return cachedMyPlot
    end

    local now = os.clock()
    if now - lastPlotScanTime < 1.0 and cachedMyPlot then
        return cachedMyPlot
    end
    lastPlotScanTime = now

    local pName = LocalPlayer.Name:lower()
    local pDisp = LocalPlayer.DisplayName:lower()
    local pId = tostring(LocalPlayer.UserId)
    local targetPlotName = "Plot_" .. pId

    pcall(function()
        local plotsFolder = Workspace:FindFirstChild("Plots") or Workspace:FindFirstChild("Bases") or Workspace:FindFirstChild("Islands") or Workspace:FindFirstChild("Farms") or Workspace:FindFirstChild("Tycoons")
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

        local directWs = Workspace:FindFirstChild(targetPlotName)
        if directWs then cachedMyPlot = directWs return end

        for _, obj in ipairs(Workspace:GetChildren()) do
            local oName = obj.Name:lower()
            if (oName:find("plot") or oName:find("base") or oName:find("farm")) and (oName:find(pName) or oName:find(pId) or oName:find(pDisp)) then
                cachedMyPlot = obj return
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

-- ── 🛒 1. MUA TRỨNG TỪ CON SÔNG (RIVER BUY DETECTOR) ──
local function getRiverPrompts()
    local riverPrompts = {}
    local myPlot = getMyPlot()

    pcall(function()
        -- 1. Ưu tiên quét thư mục ConveyorOffers / River / Eggs
        local offersFolder = Workspace:FindFirstChild("ConveyorOffers") 
                          or Workspace:FindFirstChild("EggOffers") 
                          or Workspace:FindFirstChild("RiverOffers") 
                          or Workspace:FindFirstChild("Offers")
                          or Workspace:FindFirstChild("River")
                          or Workspace:FindFirstChild("Conveyor")
                          or Workspace:FindFirstChild("Eggs")
                          or Workspace:FindFirstChild("EggSpawns")

        if offersFolder then
            for _, desc in ipairs(offersFolder:GetDescendants()) do
                if desc:IsA("ProximityPrompt") then
                    local act = (desc.ActionText or ""):lower()
                    local obj = (desc.ObjectText or ""):lower()
                    if act:find("buy") or act:find("purchase") or act:find("mua") 
                       or act:find("claim") or act:find("take") or act == "" 
                       or obj:find("buy") or obj:find("egg") or obj:find("trứng") then
                        table.insert(riverPrompts, desc)
                    end
                end
            end
        end

        -- 2. Quét các Folder / Model liên quan đến sông trong Workspace
        if #riverPrompts == 0 then
            for _, child in ipairs(Workspace:GetChildren()) do
                local cName = child.Name:lower()
                if (cName:find("conveyor") or cName:find("river") or cName:find("offer") or cName:find("stream") or cName:find("egg"))
                   and child ~= myPlot and not isOtherPlayerPlot(child) then
                    for _, desc in ipairs(child:GetDescendants()) do
                        if desc:IsA("ProximityPrompt") then
                            local act = (desc.ActionText or ""):lower()
                            if act:find("buy") or act:find("purchase") or act:find("mua") or act:find("claim") or act:find("take") or act == "" then
                                table.insert(riverPrompts, desc)
                            end
                        end
                    end
                end
            end
        end

        -- 3. Fallback: Quét toàn bộ ProximityPrompt có ActionText 'Buy' (loại trừ Plot người khác & Plot mình)
        if #riverPrompts == 0 then
            for _, desc in ipairs(Workspace:GetDescendants()) do
                if desc:IsA("ProximityPrompt") and not isOtherPlayerPlot(desc.Parent) then
                    local act = (desc.ActionText or ""):lower()
                    local pName = desc.Parent and desc.Parent.Name:lower() or ""
                    if (act:find("buy") or act:find("purchase") or act:find("mua")) 
                       and not (pName:find("upgrade") or pName:find("sign") or pName:find("skin") or pName:find("gamepass")) then
                        if not (myPlot and desc:IsDescendantOf(myPlot)) then
                            table.insert(riverPrompts, desc)
                        end
                    end
                end
            end
        end
    end)

    return riverPrompts
end

-- ── 🌱 2. TRỒNG TRỨNG VÀO KHU ĐẤT (EGG PAD DETECTOR) ──
local function getEggPadPrompts(plot)
    plot = plot or getMyPlot()
    local plantPrompt, harvestPrompt = nil, nil

    local excludeKeywords = {
        "trash", "bin", "dump", "sell", "buy", "purchase", "mua", 
        "money", "cash", "coin", "collect money", "collect cash", "gom", "store", "shop", "skin", "upgrade"
    }

    -- 1. Nếu đã có cachedPadPart hợp lệ, đọc prompt trực tiếp từ bệ (chỉ 2-5 part, 0ms, không bao giờ bị khóa cache!)
    if cachedPadPart and cachedPadPart.Parent then
        pcall(function()
            for _, desc in ipairs(cachedPadPart:GetDescendants()) do
                if desc:IsA("ProximityPrompt") and desc.Enabled then
                    local act = (desc.ActionText or ""):lower()
                    local obj = (desc.ObjectText or ""):lower()

                    local isExcluded = false
                    for _, kw in ipairs(excludeKeywords) do
                        if act:find(kw) or obj:find(kw) then isExcluded = true break end
                    end

                    if not isExcluded then
                        if act:find("harvest") or act:find("claim") or act:find("take") or act:find("pick") 
                           or act:find("hatch") or act:find("collect") or act:find("thu") or act:find("ấp") or act:find("lấy") then
                            harvestPrompt = desc
                        elseif act:find("plant") or act:find("place") or act:find("deposit") 
                            or act:find("put") or act:find("gieo") or act:find("đặt") or act:find("trồng")
                            or obj:find("pad") or obj:find("grow") or obj:find("soil") or obj:find("plot") then
                            plantPrompt = desc
                        end
                    end
                end
            end
        end)

        if plantPrompt or harvestPrompt then
            return plantPrompt, harvestPrompt, cachedPadPart
        end
    end

    -- 2. Tìm bệ đất (GrowPad / EggPad / Soil / PromptAnchor) trong Plot của bạn
    local foundPad = nil
    if plot then
        pcall(function()
            foundPad = plot:FindFirstChild("GrowPad", true) 
                    or plot:FindFirstChild("EggPad", true) 
                    or plot:FindFirstChild("Soil", true) 
                    or plot:FindFirstChild("Pad", true)
                    or plot:FindFirstChild("PromptAnchor", true)

            if not foundPad then
                for _, desc in ipairs(plot:GetDescendants()) do
                    if desc:IsA("ProximityPrompt") then
                        local act = (desc.ActionText or ""):lower()
                        local obj = (desc.ObjectText or ""):lower()
                        if act:find("plant") or act:find("harvest") or obj:find("grow") or obj:find("pad") or obj:find("egg") then
                            foundPad = desc.Parent
                            break
                        end
                    end
                end
            end
        end)
    end

    -- 3. Quét xung quanh nhân vật trong bán kính 35 studs (bệ đất ngay chân người chơi)
    if not foundPad then
        local hrp = getRootPart()
        if hrp then
            pcall(function()
                for _, desc in ipairs(Workspace:GetDescendants()) do
                    if desc:IsA("ProximityPrompt") and not isOtherPlayerPlot(desc.Parent) then
                        local pPart = desc.Parent
                        local pos = pPart and (pPart:IsA("BasePart") and pPart.Position or (pPart:IsA("Model") and pPart.PrimaryPart and pPart.PrimaryPart.Position))
                        if pos and (pos - hrp.Position).Magnitude <= 35 then
                            local act = (desc.ActionText or ""):lower()
                            local obj = (desc.ObjectText or ""):lower()
                            if act:find("plant") or act:find("harvest") or act:find("thu") or act:find("trồng") or obj:find("grow") or obj:find("pad") then
                                foundPad = pPart
                                break
                            end
                        end
                    end
                end
            end)
        end
    end

    if foundPad then
        cachedPadPart = foundPad
        cachedPadPos = foundPad:IsA("BasePart") and foundPad.Position or (foundPad:IsA("Model") and foundPad.PrimaryPart and foundPad.PrimaryPart.Position)

        for _, desc in ipairs(foundPad:GetDescendants()) do
            if desc:IsA("ProximityPrompt") and desc.Enabled then
                local act = (desc.ActionText or ""):lower()
                local obj = (desc.ObjectText or ""):lower()
                if act:find("harvest") or act:find("claim") or act:find("take") or act:find("pick") or act:find("hatch") or act:find("collect") or act:find("thu") then
                    harvestPrompt = desc
                elseif act:find("plant") or act:find("place") or act:find("deposit") or act:find("gieo") or act:find("đặt") or act:find("trồng") or obj:find("pad") or obj:find("grow") then
                    plantPrompt = desc
                end
            end
        end
    end

    return plantPrompt, harvestPrompt, cachedPadPart
end

-- ── ⚡ 3. PHÁT HIỆN SÉT ĐÁNH VÀO KHU ĐẤT ──
local function checkLightningThreat(padPart, plot, plantStartTime)
    if not padPart then return false, nil end
    local padPos = cachedPadPos or (padPart:IsA("BasePart") and padPart.Position or (padPart:IsA("Model") and padPart.PrimaryPart and padPart.PrimaryPart.Position))
    if not padPos then return false, nil end

    local hasThreat = false
    local strikeTime = nil

    pcall(function()
        for _, obj in ipairs(Workspace:GetChildren()) do
            local oName = obj.Name:lower()
            if oName:find("lightning") or oName:find("thunder") or oName:find("strike") or oName:find("storm") or oName:find("cloud") then
                local oPos = obj:IsA("BasePart") and obj.Position or (obj:IsA("Model") and obj.PrimaryPart and obj.PrimaryPart.Position)
                if oPos then
                    local dx = oPos.X - padPos.X
                    local dz = oPos.Z - padPos.Z
                    if (dx*dx + dz*dz) <= 1024 then -- within 32 studs
                        hasThreat = true
                        for _, desc in ipairs(obj:GetChildren()) do
                            if desc:IsA("BillboardGui") or desc:IsA("SurfaceGui") then
                                for _, txt in ipairs(desc:GetChildren()) do
                                    if txt:IsA("TextLabel") then
                                        local num = txt.Text:match("([%d%.]+)s?")
                                        if num then strikeTime = tonumber(num) end
                                    end
                                end
                            end
                        end
                        if hasThreat then break end
                    end
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
    if not State.Noclip then return end
    local char = getCharacter()
    if char then
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") then part.CanCollide = false end
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
-- 🎨 MODERN V28 OBSIDIAN GUI (TRỨNG THAM LAM)
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

-- Floating Button
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
Title.Text = "🥚 TRỨNG THAM LAM - AUTO V2.2"
Title.TextColor3 = Color3.fromRGB(255, 200, 50)
Title.TextSize = 12
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local SubTitle = Instance.new("TextLabel")
SubTitle.Size = UDim2.new(1, -76, 0, 14)
SubTitle.Position = UDim2.new(0, 12, 0, 26)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "⚡ Mua Trứng Sông • Trồng • Ấp • Thu Hoạch Né Sét"
SubTitle.TextColor3 = Color3.fromRGB(140, 155, 180)
SubTitle.TextSize = 9.5
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
StatusLabel.Text = "Sẵn sàng (Trứng Tham Lam V2.2)."
StatusLabel.TextColor3 = Color3.fromRGB(200, 215, 235)
StatusLabel.TextSize = 10
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = StatusFrame

local function setStatus(txt)
    StatusLabel.Text = txt
end

-- ═══════════════════════════════════════════════════════════
-- SECTION 1: 🛒 MUA TRỨNG TỪ CON SÔNG (RIVER AUTO BUY)
-- ═══════════════════════════════════════════════════════════
createSectionHeader("🛒 MUA TRỨNG TỪ CON SÔNG", Color3.fromRGB(255, 200, 50))

createToggleButton("🛒 Bật Auto Mua Trứng Từ Con Sông", State.AutoBuy, function(v)
    State.AutoBuy = v
    setStatus(v and "Đang tự động mua trứng trôi trên sông..." or "Đã dừng Auto Mua Trứng Sông.")
end)

createToggleButton("⚡ Mua Tất Cả Trứng Sông (Buy All)", State.AutoBuyAll, function(v)
    State.AutoBuyAll = v
    setStatus(v and "Chế độ: Mua sạch mọi quả trứng trên sông!" or "Chế độ: Chỉ mua trứng theo độ hiếm chọn lọc.")
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
-- SECTION 2: 🌱 TRỒNG TRỨNG VÀO KHU ĐẤT & THU HOẠCH NÉ SÉT
-- ═══════════════════════════════════════════════════════════
createSectionHeader("🌱 TRỒNG VÀO KHU ĐẤT & THU HOẠCH NÉ SÉT", Color3.fromRGB(0, 200, 255))

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

createActionButton("🌱 Thời Gian Nuôi Trứng Lớn Tối Đa", "Thu hoạch sau khi nuôi: [ " .. tostring(ALL_GROWTH_TIMES[State.GrowthWaitIndex]) .. "s ]", Color3.fromRGB(0, 255, 170), function(btn, lbl)
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
-- SECTION 3: 💰 BÁN CON VẬT & THU TIỀN (ECONOMY)
-- ═══════════════════════════════════════════════════════════
createSectionHeader("💰 BÁN CON VẬT & THU TIỀN", Color3.fromRGB(255, 180, 50))

createToggleButton("💰 Tự Hút Tiền Xu / Cash Trên Khu Đất", State.AutoCollectCash, function(v)
    State.AutoCollectCash = v
end)

createToggleButton("💵 Tự Động Bán Con Vật (Auto Sell)", State.AutoSell, function(v)
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

    local count = 0
    pcall(function()
        local riverPrompts = getRiverPrompts()
        for _, prompt in ipairs(riverPrompts) do
            if count >= 12 then break end
            local part = prompt.Parent
            if part and part:IsA("BasePart") then
                count = count + 1
                local model = part
                while model and not model:IsA("Model") and model ~= Workspace do
                    model = model.Parent
                end
                local targetItem = (model and model:IsA("Model")) and model or part
                local rarity = detectEggRarity(targetItem)
                
                local color = Color3.fromRGB(0, 255, 170)
                if rarity == "Supreme" then color = Color3.fromRGB(255, 0, 128)
                elseif rarity == "Secret" or rarity == "Divine" or rarity == "Godly" then color = Color3.fromRGB(255, 215, 0)
                elseif rarity == "Mythical" then color = Color3.fromRGB(180, 50, 255)
                elseif rarity == "Legendary" then color = Color3.fromRGB(255, 140, 0)
                end

                local bb = Instance.new("BillboardGui")
                bb.Adornee = part
                bb.AlwaysOnTop = true
                bb.Size = UDim2.new(0, 140, 0, 32)
                bb.StudsOffset = Vector3.new(0, 3, 0)
                bb.MaxDistance = 500
                bb.Parent = part

                local frame = Instance.new("Frame")
                frame.Size = UDim2.new(1, 0, 1, 0)
                frame.BackgroundColor3 = Color3.fromRGB(14, 18, 26)
                frame.BackgroundTransparency = 0.25
                frame.Parent = bb

                local fCorner = Instance.new("UICorner")
                fCorner.CornerRadius = UDim.new(0, 6)
                fCorner.Parent = frame

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, 0, 1, 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = "🥚 [" .. rarity .. "] " .. targetItem.Name
                lbl.TextColor3 = color
                lbl.Font = Enum.Font.GothamBold
                lbl.TextSize = 10
                lbl.Parent = frame

                table.insert(ESPBillboards, bb)

                if State.SkyBeacons and (rarity == "Supreme" or rarity == "Secret" or rarity == "Divine") then
                    local beacon = Instance.new("Part")
                    beacon.Size = Vector3.new(1, 200, 1)
                    beacon.CFrame = part.CFrame * CFrame.new(0, 100, 0)
                    beacon.Material = Enum.Material.Neon
                    beacon.Color = color
                    beacon.Transparency = 0.5
                    beacon.CanCollide = false
                    beacon.Anchored = true
                    beacon.Parent = Workspace
                    table.insert(ESPBeacons, beacon)
                end
            end
        end
    end)
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

-- 1. KHIÊN BẮT SÉT TỨC THÌ (0ms)
Workspace.DescendantAdded:Connect(function(desc)
    if not (State.LightningShield247 or State.AutoDodgeLightning) then return end
    pcall(function()
        local dName = desc.Name:lower()
        if dName:find("lightning") or dName:find("thunder") or dName:find("strike") or dName:find("bolt") then
            if cachedPadPos then
                local dPos = desc:IsA("BasePart") and desc.Position or (desc:IsA("Model") and desc.PrimaryPart and desc.PrimaryPart.Position)
                if dPos then
                    local dx = dPos.X - cachedPadPos.X
                    local dz = dPos.Z - cachedPadPos.Z
                    if (dx*dx + dz*dz) <= 1024 then -- within 32 studs
                        lastThreatDetectedTime = os.clock()
                        if cachedHarvestPrompt and cachedHarvestPrompt.Parent then
                            setStatus("🛡️ [KHIÊN 24/7] BẮT SÉT TỨC THÌ (0ms)! Thu hoạch an toàn!")
                            triggerPrompt(cachedHarvestPrompt)
                        end
                    end
                end
            end
        end
    end)
end)

-- 2. KHIÊN BẢO VỆ ĐỘC LẬP 24/7
task.spawn(function()
    while true do
        task.wait(0.3)
        if State.LightningShield247 and not State.AutoPlant then
            pcall(function()
                local myPlot = getMyPlot()
                local _, harvestPrompt, padPart = getEggPadPrompts(myPlot)
                if harvestPrompt then
                    local hasThreat, strikeTime = checkLightningThreat(padPart, myPlot, 0)
                    local recentThreat = (os.clock() - lastThreatDetectedTime) < 2.0
                    if hasThreat or recentThreat then
                        local info = strikeTime and (" (còn " .. string.format("%.1f", strikeTime) .. "s)") or ""
                        setStatus("🛡️ [KHIÊN 24/7] PHÁT HIỆN SÉT" .. info .. "! Đã thu hoạch an toàn!")
                        triggerPrompt(harvestPrompt)
                        task.wait(1.0)
                    end
                end
            end)
        end
    end
end)

-- 3. 🛒 MUA MỘT QUẢ TRỨNG TỪ CON SÔNG (RIVER AUTO BUY)
task.spawn(function()
    while true do
        local delayTime = math.max(State.BuyDelay or 0.3, 0.25)
        task.wait(delayTime)

        if State.AutoBuy or State.AutoBuyAll then
            pcall(function()
                local prompts = getRiverPrompts()
                local hrp = getRootPart()

                if #prompts == 0 then
                    -- Nếu chưa thấy prompt mua nào trên sông
                    return
                end

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
                        local promptPos = prompt.Parent:IsA("BasePart") and prompt.Parent.Position 
                                       or (targetItem:IsA("Model") and targetItem.PrimaryPart and targetItem.PrimaryPart.Position)
                                       or (targetItem:FindFirstChildWhichIsA("BasePart") and targetItem:FindFirstChildWhichIsA("BasePart").Position)

                        if State.RiverProximityAssist and hrp and promptPos then
                            local dist = (hrp.Position - promptPos).Magnitude
                            local origCFrame = hrp.CFrame
                            if dist > 8 and dist < 250 then
                                hrp.CFrame = CFrame.new(promptPos + Vector3.new(0, 3, 0))
                                task.wait(0.06)
                                triggerPrompt(prompt)
                                task.wait(0.06)

                                if cachedPadPos then
                                    hrp.CFrame = CFrame.new(cachedPadPos + Vector3.new(0, 3.5, 0))
                                else
                                    hrp.CFrame = origCFrame
                                end
                            else
                                triggerPrompt(prompt)
                            end
                        else
                            triggerPrompt(prompt)
                        end

                        setStatus("🛒 Đã mua trứng sông: [" .. rarity .. "] " .. (targetItem and targetItem.Name or "Egg"))
                        task.wait(0.12)
                        break -- Mua 1 quả mỗi lượt để gieo trồng ngay
                    end
                end
            end)
        end
    end
end)

-- 4. 🌱 TRỒNG TRỨNG VÀO KHU ĐẤT & THU HOẠCH NÉ SÉT (PLANT & HARVEST ENGINE)
local plantStartTime = 0

task.spawn(function()
    while true do
        task.wait(0.25)
        if State.AutoPlant then
            pcall(function()
                local myPlot = getMyPlot()
                local plantPrompt, harvestPrompt, padPart = getEggPadPrompts(myPlot)
                local targetDodgeLead = ALL_DODGE_TIMES[State.DodgeLeadTimeIndex] or 2.0
                local targetGrowthTime = ALL_GROWTH_TIMES[State.GrowthWaitIndex] or 15
                local hrp = getRootPart()

                -- 4.1 TRỨNG ĐANG TRÊN KHU ĐẤT: THEO DÕI PHÁT TRIỂN & THU HOẠCH TRƯỚC KHI SÉT ĐÁNH!
                if harvestPrompt then
                    if plantStartTime == 0 then plantStartTime = os.clock() end
                    local elapsedTime = os.clock() - plantStartTime
                    local hasThreat, strikeTime = checkLightningThreat(padPart, myPlot, plantStartTime)
                    local recentThreat = (os.clock() - lastThreatDetectedTime) < 2.0

                    -- KIỂM TRA SÉT:
                    local shouldDodge = false
                    if State.AutoDodgeLightning then
                        if hasThreat then
                            if strikeTime then
                                if strikeTime <= targetDodgeLead then
                                    shouldDodge = true
                                end
                            else
                                shouldDodge = true
                            end
                        elseif recentThreat then
                            shouldDodge = true
                        end
                    end

                    if shouldDodge then
                        local info = strikeTime and (" (còn " .. string.format("%.1f", strikeTime) .. "s)") or ""
                        setStatus("⚡ PHÁT HIỆN SÉT ĐÁNH" .. info .. "! Thu hoạch né sét ngay!")
                        if hrp and cachedPadPos and (hrp.Position - cachedPadPos).Magnitude > 10 then
                            hrp.CFrame = CFrame.new(cachedPadPos + Vector3.new(0, 3, 0))
                        end
                        triggerPrompt(harvestPrompt)
                        if firetouchinterest and hrp and padPart then
                            local tp = padPart:IsA("BasePart") and padPart or padPart:FindFirstChildWhichIsA("BasePart")
                            if tp then
                                firetouchinterest(hrp, tp, 0)
                                task.wait(0.01)
                                firetouchinterest(hrp, tp, 1)
                            end
                        end
                        plantStartTime = 0
                        task.wait(0.5)
                        return
                    end

                    -- BÓN THỨC ĂN:
                    if State.AutoFood then
                        local foodType = ALL_FOOD_TYPES[State.SelectedFoodIndex] or "Basic"
                        if foodType ~= "None" and padPart then
                            pcall(function()
                                for _, d in ipairs(padPart:GetDescendants()) do
                                    if d:IsA("ProximityPrompt") and d ~= harvestPrompt then
                                        local act = (d.ActionText or ""):lower()
                                        local obj = (d.ObjectText or ""):lower()
                                        if act:find("feed") or act:find("ăn") or obj:find("feed") or obj:find("luck") then
                                            triggerPrompt(d)
                                            break
                                        end
                                    end
                                end
                            end)
                        end
                    end

                    -- ĐỦ THỜI GIAN NUÔI TRƯỞNG THÀNH:
                    if elapsedTime >= targetGrowthTime then
                        setStatus("🦖 Đã nuôi đủ " .. math.floor(elapsedTime) .. "s! Đang thu hoạch con vật...")
                        if hrp and cachedPadPos and (hrp.Position - cachedPadPos).Magnitude > 10 then
                            hrp.CFrame = CFrame.new(cachedPadPos + Vector3.new(0, 3, 0))
                        end
                        triggerPrompt(harvestPrompt)
                        if firetouchinterest and hrp and padPart then
                            local tp = padPart:IsA("BasePart") and padPart or padPart:FindFirstChildWhichIsA("BasePart")
                            if tp then
                                firetouchinterest(hrp, tp, 0)
                                task.wait(0.01)
                                firetouchinterest(hrp, tp, 1)
                            end
                        end
                        plantStartTime = 0
                        task.wait(0.6)
                        return
                    else
                        local left = math.ceil(targetGrowthTime - elapsedTime)
                        setStatus("🥚 Đang ấp trứng trên bệ... (" .. left .. "s để thu hoạch)")
                    end

                -- 4.2 BỆ ĐẤT ĐANG TRỐNG: GIEO TRỒNG TRỨNG TỪ TÚI ĐỒ VÀO KHU ĐẤT
                elseif plantPrompt then
                    plantStartTime = 0
                    local char = getCharacter()
                    local bp = getBackpack()
                    local eggTool = nil

                    if char then
                        for _, t in ipairs(char:GetChildren()) do
                            if t:IsA("Tool") and (t.Name:lower():find("egg") or t.Name:lower():find("trứng")) then
                                eggTool = t break
                            end
                        end
                    end
                    if not eggTool and bp then
                        for _, t in ipairs(bp:GetChildren()) do
                            if t:IsA("Tool") and (t.Name:lower():find("egg") or t.Name:lower():find("trứng")) then
                                eggTool = t break
                            end
                        end
                    end
                    -- Nếu không có tool nào tên "egg", lấy bất kỳ Tool nào trong túi đồ
                    if not eggTool and bp then
                        for _, t in ipairs(bp:GetChildren()) do
                            if t:IsA("Tool") then
                                eggTool = t break
                            end
                        end
                    end

                    if eggTool then
                        -- Cầm trứng trên tay
                        if char and eggTool.Parent == bp then
                            local hum = getHumanoid()
                            if hum then
                                hum:EquipTool(eggTool)
                            else
                                eggTool.Parent = char
                            end
                            task.wait(0.12)
                        end

                        -- Di chuyển ngay lên bệ đất
                        local padPos = cachedPadPos or (padPart and (padPart:IsA("BasePart") and padPart.Position or (padPart:IsA("Model") and padPart.PrimaryPart and padPart.PrimaryPart.Position)))
                        if hrp and padPos and (hrp.Position - padPos).Magnitude > 6 then
                            hrp.CFrame = CFrame.new(padPos + Vector3.new(0, 3, 0))
                            task.wait(0.08)
                        end

                        setStatus("🌱 Đang trồng trứng: " .. eggTool.Name .. "...")
                        triggerPrompt(plantPrompt)
                        pcall(function() eggTool:Activate() end)

                        if firetouchinterest and hrp and padPart then
                            local tp = padPart:IsA("BasePart") and padPart or padPart:FindFirstChildWhichIsA("BasePart")
                            if tp then
                                firetouchinterest(hrp, tp, 0)
                                task.wait(0.01)
                                firetouchinterest(hrp, tp, 1)
                            end
                        end
                        task.wait(0.4)
                    else
                        setStatus("⏳ Túi đồ hết trứng! Đang chờ mua trứng từ con sông...")
                        task.wait(0.5)
                    end
                else
                    plantStartTime = 0
                    setStatus("🔍 Đang tìm bệ trồng trên khu đất của bạn...")
                    task.wait(0.5)
                end
            end)
        end
    end
end)

-- 5. 💰 AUTO HÚT TIỀN CASH/S TRÊN KHU ĐẤT
task.spawn(function()
    while true do
        task.wait(1.5)
        if State.AutoCollectCash then
            pcall(function()
                local hrp = getRootPart()
                if not hrp then return end
                for _, obj in ipairs(Workspace:GetChildren()) do
                    if obj:IsA("BasePart") then
                        local name = obj.Name:lower()
                        if name:find("coin") or name:find("cash") or name:find("gem") or name:find("orb") or name:find("drop") then
                            obj.CFrame = hrp.CFrame
                        end
                    end
                end
            end)
        end
    end
end)

-- 6. ESP REFRESH LOOP
task.spawn(function()
    while true do
        task.wait(5.0)
        if State.EggESP then
            updateESP(true)
        end
    end
end)

-- Tự động kích hoạt FPS Boost siêu mượt ngay khi chạy
pcall(function()
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    for _, fx in ipairs(Lighting:GetChildren()) do
        if fx:IsA("PostEffect") then fx.Enabled = false end
    end
    if settings and settings().Rendering then
        settings().Rendering.QualityLevel = 1
    end
end)

setStatus("✅ Đã khởi chạy Trứng Tham Lam V2.2 (Siêu Mượt 60 FPS) thành công!")
