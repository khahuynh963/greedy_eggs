--[[
    ===================================================================
    🥚 GREEDY EGGS - ULTIMATE AUTO HUB (FAST LOADER V1.0)
    Tương thích: Delta Executor (Android & PC), Wave, Codex, Fluxus
    ===================================================================
--]]
pcall(function()
    local container = (gethui and gethui()) or game:GetService("CoreGui")
    if container and container:FindFirstChild("GreedyEggsGui") then
        container.GreedyEggsGui:Destroy()
    end
    local pl = game:GetService("Players").LocalPlayer
    if pl and pl:FindFirstChild("PlayerGui") and pl.PlayerGui:FindFirstChild("GreedyEggsGui") then
        pl.PlayerGui.GreedyEggsGui:Destroy()
    end
end)

loadstring(game:HttpGet("https://raw.githubusercontent.com/khahuynh963/greedy_eggs/main/script.lua?" .. math.random(1, 999999)))()
