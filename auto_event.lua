-- Auto Event | Blox Fruits
-- Fast Attack + Magnet NPCs

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Net = ReplicatedStorage.Modules.Net
local RegisterHit = Net["RE/RegisterHit"]
local RegisterAttack = Net["RE/RegisterAttack"]

local Config = {
    Enabled = false,
    Range = 5000,
    MagnetStrength = 0.2,
}

local Connection = nil

local function AttackTargets(targets)
    if not targets or #targets == 0 then return end
    local head = targets[1]:FindFirstChild("Head")
    if not head then return end
    pcall(function()
        RegisterAttack:FireServer(0)
        RegisterHit:FireServer(head, targets)
    end)
end

local function Start()
    if Connection then Connection:Disconnect() end
    Connection = RunService.Heartbeat:Connect(function()
        if not Config.Enabled then return end
        local myChar = LocalPlayer.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end

        local enemiesFolder = workspace:FindFirstChild("Enemies")
        if not enemiesFolder then return end

        local targets = {}
        for _, npc in pairs(enemiesFolder:GetChildren()) do
            local hrp = npc:FindFirstChild("HumanoidRootPart")
            local hum = npc:FindFirstChild("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local dist = (hrp.Position - myHRP.Position).Magnitude
                if dist <= Config.Range then
                    pcall(function()
                        hrp.CFrame = CFrame.new(hrp.Position:Lerp(myHRP.Position, Config.MagnetStrength))
                    end)
                    table.insert(targets, npc)
                end
            end
        end

        AttackTargets(targets)
    end)
end

Start()

-- keybind: P para toggle
game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.P then
        Config.Enabled = not Config.Enabled
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Auto Event",
            Text = Config.Enabled and "ON" or "OFF",
            Duration = 1,
        })
    end
end)

print("[AutoEvent] Loaded. P = toggle | Range:", Config.Range)
