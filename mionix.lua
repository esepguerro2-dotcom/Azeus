-- Mionix Hub | Blox Fruits
-- Wind UI

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Wind UI
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/source.lua"))()
WindUI:SetTheme("Dark")

local Window = WindUI:CreateWindow({
    Title = "Mionix",
    Icon = "rbxassetid://10723407389",
    Author = "mionix",
    Folder = "Mionix",
    Size = UDim2.fromOffset(580, 460),
    Transparent = true,
    Theme = "Dark",
})

-- Remote Events
local Net = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("Net")
local RegisterHit = Net and Net:FindFirstChild("RE/RegisterHit")
local RegisterAttack = Net and Net:FindFirstChild("RE/RegisterAttack")

-- State
local State = {
    FastAttackPlayers = false,
    FastAttackNPCs = false,
    KillauraRange = 500,
    MagnetNPCs = false,
    MagnetStrength = 0.3,
    AutoEvent = false,
    HoverCFrame = nil,
    HoverHeight = 30,
    WalkOnWater = false,
    NoClip = false,
    AntiStun = false,
    InfRange = false,
    InfRangeSize = 9e9,
    ESP = {
        Enabled = false,
        Boxes = false,
        Names = false,
        Distance = false,
        Tracers = false,
        FruitESP = false,
        EliteESP = false,
    },
    Bounce = false,
    TargetKill = nil,
    GhostTP = false,
    Spectate = nil,
    AutoV4 = false,
}

local Connections = {}
local ESPObjects = {}

-- Utility
local function GetCharacter()
    return LocalPlayer.Character
end

local function GetHRP()
    local c = GetCharacter()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function FireFastAttack(targets)
    if not RegisterAttack or not RegisterHit then return end
    if not targets or #targets == 0 then return end
    local head = targets[1]:FindFirstChild("Head")
    if not head then return end
    pcall(function()
        RegisterAttack:FireServer(0)
        RegisterHit:FireServer(head, targets)
    end)
end

local function Disconnect(key)
    if Connections[key] then
        Connections[key]:Disconnect()
        Connections[key] = nil
    end
end

-- ============================================================
-- TABS
-- ============================================================

local Tabs = {
    Players    = Window:CreateTab("Players",     "user"),
    KillauraP  = Window:CreateTab("Killaura Players", "swords"),
    KillauraNPC= Window:CreateTab("Killaura NPCs",    "shield"),
    Misc       = Window:CreateTab("Misc",        "star"),
    Teleports  = Window:CreateTab("Teleports",   "map-pin"),
    ESP        = Window:CreateTab("ESP",         "eye"),
    InfRange   = Window:CreateTab("Inf Range",   "maximize"),
    Troll      = Window:CreateTab("Troll",       "zap"),
    Settings   = Window:CreateTab("Settings",    "settings"),
}

-- ============================================================
-- PLAYERS TAB
-- ============================================================
do
    local T = Tabs.Players

    T:CreateSection("Target")

    T:CreateInput({
        Name = "Target Kill (username)",
        PlaceholderText = "Player name...",
        Callback = function(v)
            for _, p in pairs(Players:GetPlayers()) do
                if p.Name:lower():find(v:lower()) then
                    State.TargetKill = p
                    break
                end
            end
        end,
    })

    T:CreateToggle({
        Name = "Kill Target Loop",
        CurrentValue = false,
        Callback = function(v)
            Disconnect("TargetKill")
            if v then
                Connections.TargetKill = RunService.Heartbeat:Connect(function()
                    local t = State.TargetKill
                    if not t or not t.Character then return end
                    local hrp = t.Character:FindFirstChild("HumanoidRootPart")
                    local head = t.Character:FindFirstChild("Head")
                    if not hrp or not head then return end
                    pcall(function()
                        RegisterAttack:FireServer(0)
                        RegisterHit:FireServer(head, {t.Character})
                    end)
                end)
            end
        end,
    })

    T:CreateSection("Ghost TP")

    T:CreateToggle({
        Name = "Ghost TP (follow target)",
        CurrentValue = false,
        Callback = function(v)
            State.GhostTP = v
            Disconnect("GhostTP")
            if v then
                Connections.GhostTP = RunService.Heartbeat:Connect(function()
                    local t = State.TargetKill
                    if not t or not t.Character then return end
                    local myHRP = GetHRP()
                    local tHRP = t.Character:FindFirstChild("HumanoidRootPart")
                    if not myHRP or not tHRP then return end
                    pcall(function()
                        myHRP.CFrame = tHRP.CFrame * CFrame.new(3, 0, 3)
                    end)
                end)
            end
        end,
    })

    T:CreateSection("Spectate")

    T:CreateInput({
        Name = "Spectate Player",
        PlaceholderText = "Player name...",
        Callback = function(v)
            for _, p in pairs(Players:GetPlayers()) do
                if p.Name:lower():find(v:lower()) and p ~= LocalPlayer then
                    State.Spectate = p
                    break
                end
            end
        end,
    })

    T:CreateToggle({
        Name = "Enable Spectate",
        CurrentValue = false,
        Callback = function(v)
            Disconnect("Spectate")
            if v and State.Spectate then
                Connections.Spectate = RunService.RenderStepped:Connect(function()
                    local t = State.Spectate
                    if not t or not t.Character then return end
                    local tHRP = t.Character:FindFirstChild("HumanoidRootPart")
                    if not tHRP then return end
                    Camera.CFrame = CFrame.new(tHRP.Position + Vector3.new(0, 10, 15), tHRP.Position)
                end)
            end
        end,
    })

    T:CreateSection("Smooth TP")

    T:CreateButton({
        Name = "Smooth TP to Target",
        Callback = function()
            local t = State.TargetKill
            if not t or not t.Character then return end
            local myHRP = GetHRP()
            local tHRP = t.Character:FindFirstChild("HumanoidRootPart")
            if not myHRP or not tHRP then return end
            local steps = 20
            local start = myHRP.CFrame
            local goal = tHRP.CFrame * CFrame.new(4, 0, 4)
            local i = 0
            local conn
            conn = RunService.Heartbeat:Connect(function()
                i = i + 1
                myHRP.CFrame = start:Lerp(goal, i / steps)
                if i >= steps then conn:Disconnect() end
            end)
        end,
    })
end

-- ============================================================
-- KILLAURA PLAYERS TAB
-- ============================================================
do
    local T = Tabs.KillauraP

    T:CreateSection("Fast Attack - Players")

    T:CreateToggle({
        Name = "Fast Attack Players",
        CurrentValue = false,
        Callback = function(v)
            State.FastAttackPlayers = v
            Disconnect("FastAttackPlayers")
            if v then
                Connections.FastAttackPlayers = RunService.Heartbeat:Connect(function()
                    local myHRP = GetHRP()
                    if not myHRP then return end
                    local targets = {}
                    for _, p in pairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer and p.Character then
                            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                            local hum = p.Character:FindFirstChild("Humanoid")
                            if hrp and hum and hum.Health > 0 then
                                local dist = (hrp.Position - myHRP.Position).Magnitude
                                if dist <= State.KillauraRange then
                                    table.insert(targets, p.Character)
                                end
                            end
                        end
                    end
                    FireFastAttack(targets)
                end)
            end
        end,
    })

    T:CreateSlider({
        Name = "Killaura Range (Players)",
        Range = {10, 5000},
        Increment = 10,
        CurrentValue = 500,
        Callback = function(v)
            State.KillauraRange = v
        end,
    })

    T:CreateSection("Magnet Players")

    T:CreateToggle({
        Name = "Magnet Players",
        CurrentValue = false,
        Callback = function(v)
            Disconnect("MagnetPlayers")
            if v then
                Connections.MagnetPlayers = RunService.Heartbeat:Connect(function()
                    local myHRP = GetHRP()
                    if not myHRP then return end
                    for _, p in pairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer and p.Character then
                            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                            if hrp then
                                local dist = (hrp.Position - myHRP.Position).Magnitude
                                if dist <= State.KillauraRange then
                                    pcall(function()
                                        hrp.CFrame = CFrame.new(hrp.Position:Lerp(myHRP.Position, 0.15))
                                    end)
                                end
                            end
                        end
                    end
                end)
            end
        end,
    })

    T:CreateSection("Bounty Farm")

    T:CreateToggle({
        Name = "Bounty Farm Loop",
        CurrentValue = false,
        Callback = function(v)
            State.Bounce = v
            Disconnect("BountyFarm")
            if v then
                Connections.BountyFarm = RunService.Heartbeat:Connect(function()
                    local myHRP = GetHRP()
                    if not myHRP then return end
                    local targets = {}
                    for _, p in pairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer and p.Character then
                            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                            local hum = p.Character:FindFirstChild("Humanoid")
                            if hrp and hum and hum.Health > 0 then
                                table.insert(targets, p.Character)
                            end
                        end
                    end
                    FireFastAttack(targets)
                end)
            end
        end,
    })
end

-- ============================================================
-- KILLAURA NPCs TAB
-- ============================================================
do
    local T = Tabs.KillauraNPC

    T:CreateSection("Fast Attack - NPCs")

    T:CreateToggle({
        Name = "Fast Attack NPCs",
        CurrentValue = false,
        Callback = function(v)
            State.FastAttackNPCs = v
            Disconnect("FastAttackNPCs")
            if v then
                Connections.FastAttackNPCs = RunService.Heartbeat:Connect(function()
                    local myHRP = GetHRP()
                    if not myHRP then return end
                    local folder = Workspace:FindFirstChild("Enemies")
                    if not folder then return end
                    local targets = {}
                    for _, npc in pairs(folder:GetChildren()) do
                        local hrp = npc:FindFirstChild("HumanoidRootPart")
                        local hum = npc:FindFirstChild("Humanoid")
                        if hrp and hum and hum.Health > 0 then
                            local dist = (hrp.Position - myHRP.Position).Magnitude
                            if dist <= State.KillauraRange then
                                table.insert(targets, npc)
                            end
                        end
                    end
                    FireFastAttack(targets)
                end)
            end
        end,
    })

    T:CreateSection("Magnet NPCs")

    T:CreateToggle({
        Name = "Magnet NPCs",
        CurrentValue = false,
        Callback = function(v)
            State.MagnetNPCs = v
            Disconnect("MagnetNPCs")
            if v then
                Connections.MagnetNPCs = RunService.Heartbeat:Connect(function()
                    local myHRP = GetHRP()
                    if not myHRP then return end
                    local folder = Workspace:FindFirstChild("Enemies")
                    if not folder then return end
                    for _, npc in pairs(folder:GetChildren()) do
                        local hrp = npc:FindFirstChild("HumanoidRootPart")
                        local hum = npc:FindFirstChild("Humanoid")
                        if hrp and hum and hum.Health > 0 then
                            local dist = (hrp.Position - myHRP.Position).Magnitude
                            if dist <= State.KillauraRange then
                                pcall(function()
                                    hrp.CFrame = CFrame.new(hrp.Position:Lerp(myHRP.Position, State.MagnetStrength))
                                end)
                            end
                        end
                    end
                end)
            end
        end,
    })

    T:CreateSlider({
        Name = "Magnet Strength",
        Range = {0.01, 1},
        Increment = 0.01,
        CurrentValue = 0.3,
        Callback = function(v)
            State.MagnetStrength = v
        end,
    })

    T:CreateSection("Auto Event (P key)")

    T:CreateToggle({
        Name = "Auto Event",
        CurrentValue = false,
        Callback = function(v)
            State.AutoEvent = v
            Disconnect("AutoEvent")
            if v then
                local myChar = GetCharacter()
                local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
                if myHRP then
                    State.HoverCFrame = myHRP.CFrame + Vector3.new(0, State.HoverHeight, 0)
                    pcall(function() myHRP.CFrame = State.HoverCFrame end)
                end
                Connections.AutoEvent = RunService.Heartbeat:Connect(function()
                    local hrp = GetHRP()
                    if not hrp then return end
                    if State.HoverCFrame then
                        pcall(function()
                            hrp.CFrame = State.HoverCFrame
                            hrp.AssemblyLinearVelocity = Vector3.zero
                        end)
                    end
                    local folder = Workspace:FindFirstChild("Enemies")
                    if not folder then return end
                    local targets = {}
                    local pullPoint = hrp.Position
                    for _, npc in pairs(folder:GetChildren()) do
                        local nhrp = npc:FindFirstChild("HumanoidRootPart")
                        local hum = npc:FindFirstChild("Humanoid")
                        if nhrp and hum and hum.Health > 0 then
                            local dist = (nhrp.Position - hrp.Position).Magnitude
                            if dist <= State.KillauraRange then
                                pcall(function()
                                    nhrp.CFrame = CFrame.new(nhrp.Position:Lerp(pullPoint, State.MagnetStrength))
                                end)
                                table.insert(targets, npc)
                            end
                        end
                    end
                    FireFastAttack(targets)
                end)
            else
                State.HoverCFrame = nil
            end
        end,
    })

    T:CreateSlider({
        Name = "Hover Height",
        Range = {5, 100},
        Increment = 5,
        CurrentValue = 30,
        Callback = function(v)
            State.HoverHeight = v
        end,
    })

    T:CreateSlider({
        Name = "NPC Range",
        Range = {50, 5000},
        Increment = 50,
        CurrentValue = 500,
        Callback = function(v)
            State.KillauraRange = v
        end,
    })
end

-- ============================================================
-- MISC TAB
-- ============================================================
do
    local T = Tabs.Misc

    T:CreateSection("Movement")

    T:CreateToggle({
        Name = "Walk On Water",
        CurrentValue = false,
        Callback = function(v)
            State.WalkOnWater = v
            Disconnect("WalkOnWater")
            if v then
                Connections.WalkOnWater = RunService.Heartbeat:Connect(function()
                    local myChar = GetCharacter()
                    if not myChar then return end
                    local hrp = myChar:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    local ray = Ray.new(hrp.Position, Vector3.new(0, -4, 0))
                    local hit = Workspace:FindPartOnRayWithIgnoreList(ray, {myChar})
                    if hit and hit.Name == "Ocean" or hit and hit.Name:find("Water") then
                        pcall(function()
                            hrp.CFrame = hrp.CFrame + Vector3.new(0, 0.1, 0)
                        end)
                    end
                end)
            end
        end,
    })

    T:CreateToggle({
        Name = "No Clip",
        CurrentValue = false,
        Callback = function(v)
            State.NoClip = v
            Disconnect("NoClip")
            if v then
                Connections.NoClip = RunService.Stepped:Connect(function()
                    local myChar = GetCharacter()
                    if not myChar then return end
                    for _, p in pairs(myChar:GetDescendants()) do
                        if p:IsA("BasePart") then
                            p.CanCollide = false
                        end
                    end
                end)
            end
        end,
    })

    T:CreateToggle({
        Name = "Anti Stun",
        CurrentValue = false,
        Callback = function(v)
            State.AntiStun = v
            Disconnect("AntiStun")
            if v then
                Connections.AntiStun = RunService.Heartbeat:Connect(function()
                    local myChar = GetCharacter()
                    if not myChar then return end
                    local hum = myChar:FindFirstChild("Humanoid")
                    if hum then
                        hum.WalkSpeed = 16
                        hum.JumpPower = 50
                    end
                end)
            end
        end,
    })

    T:CreateSection("Speed")

    T:CreateSlider({
        Name = "Walk Speed",
        Range = {16, 500},
        Increment = 1,
        CurrentValue = 16,
        Callback = function(v)
            local myChar = GetCharacter()
            local hum = myChar and myChar:FindFirstChild("Humanoid")
            if hum then hum.WalkSpeed = v end
        end,
    })

    T:CreateSlider({
        Name = "Jump Power",
        Range = {50, 500},
        Increment = 5,
        CurrentValue = 50,
        Callback = function(v)
            local myChar = GetCharacter()
            local hum = myChar and myChar:FindFirstChild("Humanoid")
            if hum then hum.JumpPower = v end
        end,
    })

    T:CreateSection("Auto V4")

    T:CreateToggle({
        Name = "Auto V4 (collect rip_indra items)",
        CurrentValue = false,
        Callback = function(v)
            State.AutoV4 = v
            Disconnect("AutoV4")
            if v then
                Connections.AutoV4 = RunService.Heartbeat:Connect(function()
                    local myHRP = GetHRP()
                    if not myHRP then return end
                    for _, obj in pairs(Workspace:GetDescendants()) do
                        if obj.Name:find("Indra") or obj.Name:find("V4") or obj.Name:find("rip_indra") then
                            local part = obj:IsA("BasePart") and obj or obj:FindFirstChild("HumanoidRootPart")
                            if part then
                                pcall(function()
                                    myHRP.CFrame = part.CFrame + Vector3.new(0, 3, 0)
                                end)
                            end
                        end
                    end
                end)
            end
        end,
    })
end

-- ============================================================
-- TELEPORTS TAB
-- ============================================================
do
    local T = Tabs.Teleports

    local function TPTo(pos)
        local hrp = GetHRP()
        if hrp then
            pcall(function() hrp.CFrame = CFrame.new(pos) end)
        end
    end

    T:CreateSection("Sea 1")
    T:CreateButton({ Name = "Starter Village", Callback = function() TPTo(Vector3.new(980, 15, 1818)) end })
    T:CreateButton({ Name = "Marine Fortress", Callback = function() TPTo(Vector3.new(-2123, 8, 1830)) end })
    T:CreateButton({ Name = "Jungle", Callback = function() TPTo(Vector3.new(-1628, 8, -733)) end })
    T:CreateButton({ Name = "Pirate Village", Callback = function() TPTo(Vector3.new(-1205, 8, 700)) end })
    T:CreateButton({ Name = "Middle Town", Callback = function() TPTo(Vector3.new(380, 8, -2250)) end })
    T:CreateButton({ Name = "Bandits / Gorilla", Callback = function() TPTo(Vector3.new(-3167, 8, -3218)) end })

    T:CreateSection("Sea 2")
    T:CreateButton({ Name = "Fountain City", Callback = function() TPTo(Vector3.new(-6800, 9, -1340)) end })
    T:CreateButton({ Name = "Graveyard", Callback = function() TPTo(Vector3.new(-3956, 52, 2478)) end })
    T:CreateButton({ Name = "Snow Mountain", Callback = function() TPTo(Vector3.new(1046, 244, -2200)) end })
    T:CreateButton({ Name = "Sky Island", Callback = function() TPTo(Vector3.new(-5027, 1060, -6282)) end })

    T:CreateSection("Sea 3")
    T:CreateButton({ Name = "Port Town", Callback = function() TPTo(Vector3.new(-15330, 101, 4540)) end })
    T:CreateButton({ Name = "Hydra Island", Callback = function() TPTo(Vector3.new(-4760, 95, -13600)) end })
    T:CreateButton({ Name = "Great Tree", Callback = function() TPTo(Vector3.new(-13130, 140, 9700)) end })
    T:CreateButton({ Name = "Floating Turtle", Callback = function() TPTo(Vector3.new(-15500, 440, -7200)) end })

    T:CreateSection("Custom")
    T:CreateButton({
        Name = "Save Position",
        Callback = function()
            local hrp = GetHRP()
            if hrp then
                _G.SavedPosition = hrp.CFrame
            end
        end,
    })
    T:CreateButton({
        Name = "Return to Saved",
        Callback = function()
            local hrp = GetHRP()
            if hrp and _G.SavedPosition then
                pcall(function() hrp.CFrame = _G.SavedPosition end)
            end
        end,
    })
end

-- ============================================================
-- ESP TAB
-- ============================================================
do
    local T = Tabs.ESP

    local function ClearESP()
        for _, obj in pairs(ESPObjects) do
            if obj then obj:Destroy() end
        end
        ESPObjects = {}
        Disconnect("ESP")
    end

    local function DrawESP()
        ClearESP()
        if not State.ESP.Enabled then return end

        Connections.ESP = RunService.RenderStepped:Connect(function()
            for _, obj in pairs(ESPObjects) do
                if obj then obj:Destroy() end
            end
            ESPObjects = {}

            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    if not hrp then continue end

                    local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                    if not onScreen then continue end

                    if State.ESP.Names then
                        local label = Drawing.new("Text")
                        label.Text = p.Name
                        label.Size = 14
                        label.Color = Color3.fromRGB(255, 255, 255)
                        label.Position = Vector2.new(pos.X, pos.Y - 40)
                        label.Outline = true
                        label.Center = true
                        label.Visible = true
                        table.insert(ESPObjects, label)
                    end

                    if State.ESP.Distance then
                        local myHRP = GetHRP()
                        if myHRP then
                            local dist = math.floor((hrp.Position - myHRP.Position).Magnitude)
                            local dl = Drawing.new("Text")
                            dl.Text = dist .. "m"
                            dl.Size = 12
                            dl.Color = Color3.fromRGB(200, 200, 200)
                            dl.Position = Vector2.new(pos.X, pos.Y + 20)
                            dl.Outline = true
                            dl.Center = true
                            dl.Visible = true
                            table.insert(ESPObjects, dl)
                        end
                    end

                    if State.ESP.Boxes then
                        local box = Drawing.new("Square")
                        box.Size = Vector2.new(50, 80)
                        box.Position = Vector2.new(pos.X - 25, pos.Y - 40)
                        box.Color = Color3.fromRGB(255, 50, 50)
                        box.Thickness = 1
                        box.Filled = false
                        box.Visible = true
                        table.insert(ESPObjects, box)
                    end

                    if State.ESP.Tracers then
                        local line = Drawing.new("Line")
                        line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        line.To = Vector2.new(pos.X, pos.Y)
                        line.Color = Color3.fromRGB(255, 50, 50)
                        line.Thickness = 1
                        line.Visible = true
                        table.insert(ESPObjects, line)
                    end
                end
            end

            if State.ESP.FruitESP then
                for _, obj in pairs(Workspace:GetDescendants()) do
                    if obj:IsA("Model") and (obj.Name:find("Fruit") or obj.Name:find("Blox")) then
                        local primary = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                        if primary then
                            local fpos, fOnScreen = Camera:WorldToViewportPoint(primary.Position)
                            if fOnScreen then
                                local fl = Drawing.new("Text")
                                fl.Text = "[Fruit] " .. obj.Name
                                fl.Size = 13
                                fl.Color = Color3.fromRGB(255, 255, 0)
                                fl.Position = Vector2.new(fpos.X, fpos.Y)
                                fl.Outline = true
                                fl.Center = true
                                fl.Visible = true
                                table.insert(ESPObjects, fl)
                            end
                        end
                    end
                end
            end

            if State.ESP.EliteESP then
                for _, npc in pairs(Workspace:GetDescendants()) do
                    if npc:IsA("Model") then
                        local hum = npc:FindFirstChild("Humanoid")
                        if hum and hum.MaxHealth >= 50000 then
                            local hrp = npc:FindFirstChild("HumanoidRootPart")
                            if hrp then
                                local epos, eOnScreen = Camera:WorldToViewportPoint(hrp.Position)
                                if eOnScreen then
                                    local el = Drawing.new("Text")
                                    el.Text = "[Elite] " .. npc.Name
                                    el.Size = 13
                                    el.Color = Color3.fromRGB(255, 100, 255)
                                    el.Position = Vector2.new(epos.X, epos.Y)
                                    el.Outline = true
                                    el.Center = true
                                    el.Visible = true
                                    table.insert(ESPObjects, el)
                                end
                            end
                        end
                    end
                end
            end
        end)
    end

    T:CreateToggle({
        Name = "ESP Enabled",
        CurrentValue = false,
        Callback = function(v)
            State.ESP.Enabled = v
            DrawESP()
        end,
    })

    T:CreateToggle({
        Name = "Boxes",
        CurrentValue = false,
        Callback = function(v) State.ESP.Boxes = v DrawESP() end,
    })

    T:CreateToggle({
        Name = "Names",
        CurrentValue = false,
        Callback = function(v) State.ESP.Names = v DrawESP() end,
    })

    T:CreateToggle({
        Name = "Distance",
        CurrentValue = false,
        Callback = function(v) State.ESP.Distance = v DrawESP() end,
    })

    T:CreateToggle({
        Name = "Tracers",
        CurrentValue = false,
        Callback = function(v) State.ESP.Tracers = v DrawESP() end,
    })

    T:CreateToggle({
        Name = "Fruit ESP",
        CurrentValue = false,
        Callback = function(v) State.ESP.FruitESP = v DrawESP() end,
    })

    T:CreateToggle({
        Name = "Elite NPC ESP",
        CurrentValue = false,
        Callback = function(v) State.ESP.EliteESP = v DrawESP() end,
    })

    T:CreateButton({
        Name = "Clear ESP",
        Callback = function()
            ClearESP()
            State.ESP.Enabled = false
        end,
    })
end

-- ============================================================
-- INF RANGE TAB
-- ============================================================
do
    local T = Tabs.InfRange

    T:CreateSection("Hit Range")

    T:CreateToggle({
        Name = "Infinite Range",
        CurrentValue = false,
        Callback = function(v)
            State.InfRange = v
            Disconnect("InfRange")
            if v then
                Connections.InfRange = RunService.Heartbeat:Connect(function()
                    local myChar = GetCharacter()
                    if not myChar then return end
                    for _, desc in pairs(myChar:GetDescendants()) do
                        if desc:IsA("SelectionBox") or desc.Name == "HitPart" then
                            if desc:IsA("BasePart") then
                                pcall(function()
                                    desc.Size = Vector3.new(State.InfRangeSize, State.InfRangeSize, State.InfRangeSize)
                                end)
                            end
                        end
                    end
                end)
            end
        end,
    })

    T:CreateSlider({
        Name = "Range Size",
        Range = {100, 99999},
        Increment = 100,
        CurrentValue = 9999,
        Callback = function(v)
            State.InfRangeSize = v
        end,
    })

    T:CreateSection("Hit Offset")

    T:CreateToggle({
        Name = "TP to Target on Attack",
        CurrentValue = false,
        Callback = function(v)
            Disconnect("TPOnAttack")
            if v then
                Connections.TPOnAttack = UserInputService.InputBegan:Connect(function(input, gp)
                    if gp then return end
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        local t = State.TargetKill
                        if t and t.Character then
                            local hrp = GetHRP()
                            local thrp = t.Character:FindFirstChild("HumanoidRootPart")
                            if hrp and thrp then
                                pcall(function()
                                    hrp.CFrame = thrp.CFrame * CFrame.new(3, 0, 3)
                                end)
                            end
                        end
                    end
                end)
            end
        end,
    })
end

-- ============================================================
-- TROLL TAB
-- ============================================================
do
    local T = Tabs.Troll

    T:CreateSection("Crash")

    T:CreateButton({
        Name = "Crash Client (self)",
        Callback = function()
            pcall(function()
                for i = 1, 1e9 do
                    Instance.new("Part", Workspace)
                end
            end)
        end,
    })

    T:CreateSection("Chat Spam")

    local SpamMsg = "Mionix"
    T:CreateInput({
        Name = "Spam Message",
        PlaceholderText = "Message...",
        Callback = function(v) SpamMsg = v end,
    })

    T:CreateToggle({
        Name = "Chat Spam",
        CurrentValue = false,
        Callback = function(v)
            Disconnect("ChatSpam")
            if v then
                Connections.ChatSpam = RunService.Heartbeat:Connect(function()
                    game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents") and
                    game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(SpamMsg, "All")
                end)
            end
        end,
    })

    T:CreateSection("Sky / Visual")

    T:CreateToggle({
        Name = "Full Bright",
        CurrentValue = false,
        Callback = function(v)
            Lighting.Ambient = v and Color3.fromRGB(255,255,255) or Color3.fromRGB(70,70,70)
            Lighting.Brightness = v and 10 or 2
        end,
    })

    T:CreateToggle({
        Name = "Remove Fog",
        CurrentValue = false,
        Callback = function(v)
            Lighting.FogEnd = v and 9e9 or 1000
            Lighting.FogStart = v and 9e9 or 0
        end,
    })
end

-- ============================================================
-- SETTINGS TAB
-- ============================================================
do
    local T = Tabs.Settings

    T:CreateSection("Config")

    T:CreateButton({
        Name = "Save Config",
        Callback = function()
            WindUI:SaveConfig("MionixConfig")
        end,
    })

    T:CreateButton({
        Name = "Load Config",
        Callback = function()
            WindUI:LoadConfig("MionixConfig")
        end,
    })

    T:CreateSection("UI")

    T:CreateToggle({
        Name = "Rainbow Theme",
        CurrentValue = false,
        Callback = function(v)
            Disconnect("Rainbow")
            if v then
                local hue = 0
                Connections.Rainbow = RunService.Heartbeat:Connect(function()
                    hue = (hue + 0.001) % 1
                    WindUI:SetAccentColor(Color3.fromHSV(hue, 1, 1))
                end)
            end
        end,
    })

    T:CreateButton({
        Name = "Destroy Hub",
        Callback = function()
            for _, c in pairs(Connections) do
                if c then c:Disconnect() end
            end
            WindUI:Destroy()
        end,
    })
end

-- ============================================================
-- KEYBINDS
-- ============================================================
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.P then
        -- Auto Event toggle (same as the KillauraNPC tab toggle)
        State.AutoEvent = not State.AutoEvent
        Disconnect("AutoEvent")
        if State.AutoEvent then
            local myChar = GetCharacter()
            local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if myHRP then
                State.HoverCFrame = myHRP.CFrame + Vector3.new(0, State.HoverHeight, 0)
                pcall(function() myHRP.CFrame = State.HoverCFrame end)
            end
            Connections.AutoEvent = RunService.Heartbeat:Connect(function()
                local hrp = GetHRP()
                if not hrp then return end
                if State.HoverCFrame then
                    pcall(function()
                        hrp.CFrame = State.HoverCFrame
                        hrp.AssemblyLinearVelocity = Vector3.zero
                    end)
                end
                local folder = Workspace:FindFirstChild("Enemies")
                if not folder then return end
                local targets = {}
                local pullPoint = hrp.Position
                for _, npc in pairs(folder:GetChildren()) do
                    local nhrp = npc:FindFirstChild("HumanoidRootPart")
                    local hum = npc:FindFirstChild("Humanoid")
                    if nhrp and hum and hum.Health > 0 then
                        local dist = (nhrp.Position - hrp.Position).Magnitude
                        if dist <= State.KillauraRange then
                            pcall(function()
                                nhrp.CFrame = CFrame.new(nhrp.Position:Lerp(pullPoint, State.MagnetStrength))
                            end)
                            table.insert(targets, npc)
                        end
                    end
                end
                FireFastAttack(targets)
            end)
        else
            State.HoverCFrame = nil
        end
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Mionix",
            Text = "Auto Event: " .. (State.AutoEvent and "ON" or "OFF"),
            Duration = 1,
        })
    end

    if input.KeyCode == Enum.KeyCode.RightBracket then
        WindUI:ToggleUI()
    end
end)

print("[Mionix] Loaded. ] = toggle UI | P = Auto Event")
