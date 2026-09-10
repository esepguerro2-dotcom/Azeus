-- Fast Attack | Blox Fruits
-- Hits players & NPCs instantly via RegisterHit/RegisterAttack remotes

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Net = ReplicatedStorage.Modules.Net
local RegisterHit = Net["RE/RegisterHit"]
local RegisterAttack = Net["RE/RegisterAttack"]

local Config = {
    PlayerAttack = true,
    NPCAttack = true,
    Range = 5000,
    Enabled = true,
}

local function GetMyHRP()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function IsAlive(char)
    local hum = char:FindFirstChild("Humanoid")
    return hum and hum.Health > 0
end

local function FireHit(targets)
    if not targets or #targets == 0 then return end
    local first = targets[1]
    local head = first:FindFirstChild("Head")
    if not head then return end
    pcall(function()
        RegisterAttack:FireServer(0)
        RegisterHit:FireServer(head, targets)
    end)
end

local function CollectPlayerTargets(myHRP)
    local targets = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp and IsAlive(p.Character) then
                local dist = (hrp.Position - myHRP.Position).Magnitude
                if dist <= Config.Range then
                    table.insert(targets, p.Character)
                end
            end
        end
    end
    return targets
end

local function CollectNPCTargets(myHRP)
    local targets = {}
    local enemiesFolder = workspace:FindFirstChild("Enemies")
    if not enemiesFolder then return targets end
    for _, npc in pairs(enemiesFolder:GetChildren()) do
        local hrp = npc:FindFirstChild("HumanoidRootPart")
        if hrp and IsAlive(npc) then
            local dist = (hrp.Position - myHRP.Position).Magnitude
            if dist <= Config.Range then
                table.insert(targets, npc)
            end
        end
    end
    return targets
end

-- main loop
RunService.Heartbeat:Connect(function()
    if not Config.Enabled then return end
    local myHRP = GetMyHRP()
    if not myHRP then return end

    local targets = {}

    if Config.PlayerAttack then
        for _, c in pairs(CollectPlayerTargets(myHRP)) do
            table.insert(targets, c)
        end
    end

    if Config.NPCAttack then
        for _, c in pairs(CollectNPCTargets(myHRP)) do
            table.insert(targets, c)
        end
    end

    FireHit(targets)
end)

-- keybinds
local UIS = game:GetService("UserInputService")
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    -- P: toggle on/off
    if input.KeyCode == Enum.KeyCode.P then
        Config.Enabled = not Config.Enabled
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Fast Attack",
            Text = Config.Enabled and "ON" or "OFF",
            Duration = 1,
        })
    end
    -- O: toggle players only
    if input.KeyCode == Enum.KeyCode.O then
        Config.PlayerAttack = not Config.PlayerAttack
    end
    -- I: toggle npcs only
    if input.KeyCode == Enum.KeyCode.I then
        Config.NPCAttack = not Config.NPCAttack
    end
end)

print("[FastAttack] Loaded. P = toggle | O = players | I = NPCs")
print("[FastAttack] Range:", Config.Range)
