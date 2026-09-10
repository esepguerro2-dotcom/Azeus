-- Auto Event | Blox Fruits
-- P: sube 15 studs, fija posicion, magnet NPCs abajo, fast attack

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Net = ReplicatedStorage.Modules.Net
local RegisterHit = Net["RE/RegisterHit"]
local RegisterAttack = Net["RE/RegisterAttack"]

local Config = {
    Enabled = false,
    Range = 50,
    MagnetStrength = 0.3,
    HoverHeight = 15,
    PullOffset = 30,    -- studs debajo del jugador donde se juntan los NPCs
}

local Connection = nil
local HoverCFrame = nil  -- posicion fija en el aire mientras esta activo

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

        -- mantener jugador en el aire fijo
        if HoverCFrame then
            pcall(function()
                myHRP.CFrame = HoverCFrame
                myHRP.AssemblyLinearVelocity = Vector3.zero
            end)
        end

        local enemiesFolder = workspace:FindFirstChild("Enemies")
        if not enemiesFolder then return end

        -- punto donde caen los NPCs = debajo del jugador en el suelo
        local pullPoint = myHRP.Position - Vector3.new(0, Config.PullOffset, 0)

        local targets = {}
        for _, npc in pairs(enemiesFolder:GetChildren()) do
            local hrp = npc:FindFirstChild("HumanoidRootPart")
            local hum = npc:FindFirstChild("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local dist = (hrp.Position - myHRP.Position).Magnitude
                if dist <= Config.Range then
                    pcall(function()
                        -- jala el NPC hacia el punto justo debajo del jugador
                        hrp.CFrame = CFrame.new(hrp.Position:Lerp(pullPoint, Config.MagnetStrength))
                    end)
                    table.insert(targets, npc)
                end
            end
        end

        AttackTargets(targets)
    end)
end

Start()

UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.P then
        Config.Enabled = not Config.Enabled

        if Config.Enabled then
            -- al activar: subir 15 studs y guardar esa posicion
            local myChar = LocalPlayer.Character
            local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if myHRP then
                HoverCFrame = myHRP.CFrame + Vector3.new(0, Config.HoverHeight, 0)
                pcall(function()
                    myHRP.CFrame = HoverCFrame
                end)
            end
        else
            HoverCFrame = nil
        end

        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Auto Event",
            Text = Config.Enabled and "ON - volando" or "OFF",
            Duration = 1,
        })
    end
end)

print("[AutoEvent] Loaded. P = toggle")
