--[[
    Handicapped Engine
    LocalScript → StarterGui → Tecla K abre/cierra
    [+] UI Seria y Plana
    [+] Fly Engine Custom (Teclado: P)
    [+] Auto Farm Players (Tween Deslizante -> TP 70m arriba)
    [+] ESP Avanzado (Ken Haki + PVP Status)
    [+] Auto Safe Bypass Server
    [+] Magnet Manual Lento (20m abajo) | Magnet Safe Rapido (30m abajo)
    [+] Dragon Gun M1 Ultra (Logica Completa Standalone)
    [+] Azucar Attack Mejorado (Anti-Bug + Skip Sin Daño 5s)
    [+] Anti-Lag Gris Total (Mapa, Cielo, Todo)
    [+] Auto Reroll Race
]]

local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local TW           = game:GetService("TweenService")
local RS           = game:GetService("RunService")
local RPS          = game:GetService("ReplicatedStorage")
local Lighting     = game:GetService("Lighting")

local lp           = Players.LocalPlayer
local pGui         = lp:WaitForChild("PlayerGui")
local Cam          = workspace.CurrentCamera

pcall(function() local o = pGui:FindFirstChild("HE_UI_SERIOUS"); if o then o:Destroy() end end)

----------------------------------------------------------------
-- SILENT AIM MODULE (Inyectado)
----------------------------------------------------------------
local SilentAimModule = (function()
    local module = {}
    local SilentAimPlayersEnabled = false
    local SilentAimNPCsEnabled    = false
    local PredictionEnabled       = true
    local PredictionAmount        = 0.12
    local ShowFOVCircle           = false
    local FOVRadius               = 100
    local FOVMode                 = "V1"
    local AimMode                 = "360"
    local SoruAutoAimEnabled      = false
    local SoruAutoAimRange        = 1000
    local SoruTargetPriority      = "Nearest"
    local SoruSelectedPlayer      = nil
    local SoruCurrentTarget       = nil
    local TracerEnabled           = false
    local tracerModel, tracerAttachment0, tracerAttachment1, tracerBeam = nil, nil, nil, nil
    local renderConnection        = nil
    local currentTool, currentToolCategory = nil, "Melee"
    local PlayersPosition, NPCPosition = nil, nil
    local characterConnections    = {}
    local Skills                  = {"X"}
    local maxRange                = 1000

    local BlacklistedKeys = {
        Melee = { Z=false, X=false, C=false },
        Sword = { Z=false, X=false },
        Fruit = { Z=false, X=false, C=false, V=false, F=false, TAP=false },
        Gun   = { Z=false, X=false }
    }

    local currentSkillKey = nil
    local SKILL_KEYS      = {"Z","X","C","V","F","TAP"}
    local lastSkillTime   = 0

    local function faceTarget(targetPos)
        if not targetPos then return end
        local char = lp.Character; if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        local currentPos = hrp.Position
        local lookVector = (Vector3.new(targetPos.X, currentPos.Y, targetPos.Z) - currentPos).Unit
        if lookVector.Magnitude < 0.001 then return end
        hrp.CFrame = CFrame.lookAt(currentPos, currentPos + lookVector, Vector3.new(0,1,0))
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.AutoRotate = true end
    end

    local function setCurrentSkillKey(key)
        currentSkillKey = key
        lastSkillTime   = os.clock()
        if SilentAimPlayersEnabled or SilentAimNPCsEnabled then
            local targetPos = PlayersPosition or NPCPosition
            if targetPos then task.spawn(function() faceTarget(targetPos) end) end
        end
        task.spawn(function()
            local myTime = lastSkillTime
            task.wait(1.5)
            if lastSkillTime == myTime and currentSkillKey == key then currentSkillKey = nil end
        end)
    end

    local guiParent = (gethui and gethui()) or game:GetService("CoreGui"):FindFirstChild("RobloxGui") or lp:WaitForChild("PlayerGui")
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SacredFOV_UI"; ScreenGui.ResetOnSpawn = false; ScreenGui.IgnoreGuiInset = true
    pcall(function() ScreenGui.Parent = guiParent end)

    local FOVFrame = Instance.new("Frame", ScreenGui)
    FOVFrame.Name = "FOVCircle"; FOVFrame.AnchorPoint = Vector2.new(0.5,0.5)
    FOVFrame.BackgroundTransparency = 1; FOVFrame.Visible = false
    local UIStroke = Instance.new("UIStroke", FOVFrame)
    UIStroke.Color = Color3.fromRGB(210,210,225); UIStroke.Thickness = 1.5
    Instance.new("UICorner", FOVFrame).CornerRadius = UDim.new(1,0)

    local PingService = game:GetService("Stats").Network.ServerStatsItem

    local function getToolCategory(tool)
        if not tool then return "Melee" end
        local name = string.lower(tool.Name)
        local gunNames   = {"guitar","rifle","cannon","gun","slingshot","kabucha","serpent bow","bow"}
        for _,g in ipairs(gunNames)   do if string.find(name,g) then return "Gun"   end end
        local meleeNames = {"claw","godhuman","superhuman","talon","step","karate","breath","kung fu","combat","fist","sanguine"}
        for _,m in ipairs(meleeNames) do if string.find(name,m) then return "Melee" end end
        if string.find(name,"fruit") or string.find(name,"-") then return "Fruit" end
        return "Sword"
    end

    local function isKeyCurrentlyBlacklisted(key)
        if not key then return false end
        local cat = currentToolCategory
        if BlacklistedKeys[cat] and BlacklistedKeys[cat][key] ~= nil then return BlacklistedKeys[cat][key] end
        return false
    end

    local function getHRP(model)
        if model and model:FindFirstChild("HumanoidRootPart") then return model.HumanoidRootPart end
        return nil
    end

    local function clearConnections()
        for _,c in ipairs(characterConnections) do pcall(function() c:Disconnect() end) end
        characterConnections = {}
    end

    local function predicted(hrp)
        if not hrp then return nil end
        local hum = hrp.Parent:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return hrp.Position end
        if not PredictionEnabled then return hrp.Position end
        local vel  = hrp.Velocity
        local ping = 0
        pcall(function() if PingService then ping = PingService:GetValue()/1000 end end)
        ping = math.clamp(ping, 0, 0.35)
        local factor = PredictionAmount + ping
        if vel.Magnitude > 100 then factor = math.min(factor, 0.15) end
        return hrp.Position + (vel * factor)
    end

    local function isEnemy(targetplayer)
        if not targetplayer or targetplayer == lp then return false end
        local char = targetplayer.Character; if not char then return false end
        if char:GetAttribute("SafeZone")==true or char:GetAttribute("PvpDisabled")==true or char:GetAttribute("CombatProtected")==true or char:GetAttribute("PVP")==false then return false end
        return true
    end

    local function getFOVCenter(mode)
        if mode == "V2" then return UIS:GetMouseLocation() end
        return workspace.CurrentCamera.ViewportSize / 2
    end

    local function isTargetValid(hrp, lpHRP, aimMode, fovRadius, fovType)
        if not hrp or not lpHRP then return false end
        if aimMode == "180" then
            local dir = (hrp.Position - lpHRP.Position).Unit
            if lpHRP.CFrame.LookVector:Dot(dir) < 0 then return false end
        elseif aimMode == "FOV" then
            local camera = workspace.CurrentCamera
            local screenPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
            if not onScreen then return false end
            local center = getFOVCenter(fovType)
            if (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude > fovRadius then return false end
        end
        return true
    end

    local function getClosestplayer(lpHRP)
        if not lpHRP then return nil end
        local valid = {}
        for _,pl in ipairs(Players:GetPlayers()) do
            if pl ~= lp and isEnemy(pl) and pl.Character and pl.Character.Parent then
                local hum = pl.Character:FindFirstChildWhichIsA("Humanoid")
                local hrp = getHRP(pl.Character)
                if hum and hum.Health > 0 and hrp and isTargetValid(hrp, lpHRP, AimMode, FOVRadius, FOVMode) then
                    local dist = (hrp.Position - lpHRP.Position).Magnitude
                    if dist <= maxRange then table.insert(valid, {Player=pl, Humanoid=hum, HRP=hrp, Distance=dist}) end
                end
            end
        end
        if #valid == 0 then return nil end
        table.sort(valid, function(a,b) return a.Distance < b.Distance end)
        return valid[1].Player
    end

    local function getClosestNPC(lpHRP)
        if not lpHRP then return nil end
        local enemiesFolder = workspace:FindFirstChild("Enemies"); if not enemiesFolder then return nil end
        local closest, closestDist = nil, math.huge
        for _,npc in ipairs(enemiesFolder:GetChildren()) do
            if npc:IsA("Model") then
                local hum = npc:FindFirstChildWhichIsA("Humanoid")
                local hrp = getHRP(npc)
                if hum and hum.Health > 0 and hrp and isTargetValid(hrp, lpHRP, AimMode, FOVRadius, FOVMode) then
                    local dist = (hrp.Position - lpHRP.Position).Magnitude
                    if dist <= maxRange and dist < closestDist then closestDist = dist; closest = npc end
                end
            end
        end
        return closest
    end

    local SoruPredictedPosition = nil
    local function getSoruTarget(lpHRP)
        if not lpHRP then return nil end
        if SoruTargetPriority == "Lock Player" then
            if SoruSelectedPlayer and SoruSelectedPlayer.Character then
                local hum = SoruSelectedPlayer.Character:FindFirstChildWhichIsA("Humanoid")
                local hrp = getHRP(SoruSelectedPlayer.Character)
                if hum and hum.Health > 0 and hrp and (hrp.Position - lpHRP.Position).Magnitude <= SoruAutoAimRange then return hrp end
            end
            return nil
        end
        local valid = {}
        for _,pl in ipairs(Players:GetPlayers()) do
            if pl ~= lp and pl.Character and pl.Character.Parent and isEnemy(pl) then
                local hum = pl.Character:FindFirstChildWhichIsA("Humanoid")
                local hrp = getHRP(pl.Character)
                if hum and hum.Health > 0 and hrp then
                    local dist = (hrp.Position - lpHRP.Position).Magnitude
                    if dist <= SoruAutoAimRange then table.insert(valid, {HRP=hrp, Humanoid=hum, Distance=dist}) end
                end
            end
        end
        if #valid == 0 then return nil end
        table.sort(valid, function(a,b) return a.Distance < b.Distance end)
        return valid[1].HRP
    end

    task.spawn(function()
        while true do task.wait(0.2)
            if SoruAutoAimEnabled then
                local myHRP    = getHRP(lp.Character)
                local targetHRP = myHRP and getSoruTarget(myHRP)
                if targetHRP then SoruPredictedPosition = targetHRP.Position; SoruCurrentTarget = targetHRP
                else SoruCurrentTarget = nil; SoruPredictedPosition = nil end
            else SoruCurrentTarget = nil; SoruPredictedPosition = nil end
        end
    end)

    local function createTracer()
        if tracerModel then return end
        tracerModel       = Instance.new("Model", workspace); tracerModel.Name = "SacredTracer"
        tracerAttachment0 = Instance.new("Attachment", tracerModel)
        tracerAttachment1 = Instance.new("Attachment", tracerModel)
        tracerBeam        = Instance.new("Beam", tracerModel)
        tracerBeam.Attachment0 = tracerAttachment0; tracerBeam.Attachment1 = tracerAttachment1
        tracerBeam.Width0 = 0.1; tracerBeam.Width1 = 0.1; tracerBeam.FaceCamera = true
        tracerBeam.Color  = ColorSequence.new(Color3.fromRGB(210,210,225))
    end

    local function destroyTracer()
        if tracerModel then tracerModel:Destroy(); tracerModel = nil; tracerAttachment0 = nil; tracerAttachment1 = nil; tracerBeam = nil end
    end

    UIS.InputBegan:Connect(function(input, gp)
        if gp then return end
        local keyMap = { [Enum.KeyCode.Z]="Z", [Enum.KeyCode.X]="X", [Enum.KeyCode.C]="C", [Enum.KeyCode.V]="V", [Enum.KeyCode.F]="F" }
        local key = keyMap[input.KeyCode]
        if key then setCurrentSkillKey(key) end
    end)

    local function hookMobileButton(btn)
        if btn:GetAttribute("Hooked_Sacred") then return end
        btn:SetAttribute("Hooked_Sacred", true)
        local key = btn.Name
        if table.find(SKILL_KEYS, key) then btn.Activated:Connect(function() setCurrentSkillKey(key) end) end
    end

    task.spawn(function()
        while not lp:FindFirstChild("PlayerGui") do task.wait(0.5) end
        local pg   = lp.PlayerGui
        local main = pg:WaitForChild("Main", 10)
        if main then
            local skills = main:WaitForChild("Skills", 10)
            if skills then
                for _,wf in ipairs(skills:GetChildren()) do if wf:IsA("GuiObject") then for _,b in ipairs(wf:GetChildren()) do if b:IsA("ImageButton") or b:IsA("TextButton") then hookMobileButton(b) end end end end
                skills.ChildAdded:Connect(function(wf) if wf:IsA("GuiObject") then for _,b in ipairs(wf:GetChildren()) do if b:IsA("ImageButton") or b:IsA("TextButton") then hookMobileButton(b) end end end end)
            end
        end
    end)

    local function getSkillKeyFromArgs(args)
        for _,arg in ipairs(args) do if type(arg) == "string" and table.find(SKILL_KEYS, arg) then return arg end end
        return nil
    end

    local function startRenderLoop()
        if not renderConnection then
            renderConnection = RS.RenderStepped:Connect(function()
                if ShowFOVCircle then
                    local center = getFOVCenter(FOVMode)
                    FOVFrame.Position = UDim2.new(0, center.X, 0, center.Y)
                    FOVFrame.Size     = UDim2.new(0, FOVRadius*2, 0, FOVRadius*2)
                    FOVFrame.Visible  = true
                else FOVFrame.Visible = false end
                pcall(function()
                    local lpChar = lp.Character; if not lpChar then return end
                    local lpHRP  = lpChar:FindFirstChild("HumanoidRootPart"); if not lpHRP then return end
                    if not SilentAimPlayersEnabled and not SilentAimNPCsEnabled then
                        if TracerEnabled and tracerBeam then tracerBeam.Enabled = false end
                        PlayersPosition = nil; NPCPosition = nil; return
                    end
                    if SilentAimPlayersEnabled then
                        local targetplayer = getClosestplayer(lpHRP)
                        if targetplayer and targetplayer.Character then PlayersPosition = predicted(getHRP(targetplayer.Character)) else PlayersPosition = nil end
                    end
                    if SilentAimNPCsEnabled then
                        local npc = getClosestNPC(lpHRP)
                        if npc then NPCPosition = predicted(getHRP(npc)) else NPCPosition = nil end
                    end
                    if TracerEnabled and tracerBeam and tracerAttachment0 and tracerAttachment1 then
                        local targetPos = PlayersPosition or NPCPosition
                        if lpHRP and targetPos then
                            tracerAttachment0.WorldPosition = lpHRP.Position
                            tracerAttachment1.WorldPosition = targetPos
                            tracerBeam.Enabled = true
                        else tracerBeam.Enabled = false end
                    end
                end)
            end)
        end
    end

    local function stopRenderLoop()
        if renderConnection then renderConnection:Disconnect(); renderConnection = nil end
        FOVFrame.Visible = false; destroyTracer(); PlayersPosition = nil; NPCPosition = nil
    end

    pcall(function()
        local mt = getrawmetatable(game); if not mt then return end
        local oldNamecall = mt.__namecall; local oldIndex = mt.__index; local Mouse = lp:GetMouse()
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local Method = getnamecallmethod(); local args = {...}
            if args[1] == "TAP" then return oldNamecall(self, ...) end
            local skillKey = getSkillKeyFromArgs(args)
            if skillKey then
                if SilentAimPlayersEnabled or SilentAimNPCsEnabled then
                    local targetPos = PlayersPosition or NPCPosition
                    if targetPos then task.spawn(function() faceTarget(targetPos) end) end
                end
                setCurrentSkillKey(skillKey)
            end
            if SoruAutoAimEnabled and SoruPredictedPosition and skillKey == "C" then
                for i,arg in ipairs(args) do if typeof(arg) == "Vector3" then args[i] = SoruPredictedPosition end end
            end
            local skip = false
            if skillKey and isKeyCurrentlyBlacklisted(skillKey) then skip = true
            elseif not skillKey and currentSkillKey and isKeyCurrentlyBlacklisted(currentSkillKey) then skip = true end
            if not skip then
                if Method == "FireServer" then
                    if typeof(args[1]) == "Vector3" then
                        if SilentAimPlayersEnabled and PlayersPosition then args[1] = PlayersPosition
                        elseif SilentAimNPCsEnabled and NPCPosition then args[1] = NPCPosition end
                    end
                elseif Method == "InvokeServer" and currentTool and currentTool.Name == "Buddy Sword" then
                    if type(args[1]) == "string" and table.find(Skills, args[1]) then
                        if SilentAimPlayersEnabled and PlayersPosition then args[2] = PlayersPosition
                        elseif SilentAimNPCsEnabled and NPCPosition then args[2] = NPCPosition end
                    end
                end
            end
            return oldNamecall(self, unpack(args))
        end)
        mt.__index = newcclosure(function(t, k)
            if SoruAutoAimEnabled and t == Mouse and SoruPredictedPosition then
                if k == "Hit" then return CFrame.new(SoruPredictedPosition) end
                if k == "Target" then return nil end
            end
            return oldIndex(t, k)
        end)
        setreadonly(mt, true)
    end)

    local function onCharacterAdded(char)
        clearConnections()
        for _,child in ipairs(char:GetChildren()) do
            if child:IsA("Tool") then currentTool = child; currentToolCategory = getToolCategory(child); currentSkillKey = nil
                table.insert(characterConnections, child.AncestryChanged:Connect(function(_,p) if not p then currentTool = nil end end)) end
        end
        table.insert(characterConnections, char.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then currentTool = child; currentToolCategory = getToolCategory(child); currentSkillKey = nil
                table.insert(characterConnections, child.AncestryChanged:Connect(function(_,p) if not p then currentTool = nil end end)) end end))
        table.insert(characterConnections, char.ChildRemoved:Connect(function(child) if child == currentTool then currentTool = nil end end))
    end
    lp.CharacterAdded:Connect(onCharacterAdded)
    if lp.Character then onCharacterAdded(lp.Character) end

    function module:SetPlayerSilentAim(state) SilentAimPlayersEnabled = state; if state then startRenderLoop() elseif not SilentAimNPCsEnabled then stopRenderLoop() end end
    function module:SetNPCSilentAim(state)    SilentAimNPCsEnabled    = state; if state then startRenderLoop() elseif not SilentAimPlayersEnabled then stopRenderLoop() end end
    function module:SetDistanceLimit(num)  if type(num) == "number" then maxRange = num end end
    function module:SetShowFOVCircle(state) ShowFOVCircle = state end
    function module:SetFOVRadius(num)       FOVRadius     = num end
    function module:SetSoruAutoAim(state)   SoruAutoAimEnabled = state; if not state then SoruCurrentTarget = nil; SoruPredictedPosition = nil end end
    function module:SetTracerEnabled(state) TracerEnabled  = state; if state then createTracer() else destroyTracer() end end
    return module
end)()

----------------------------------------------------------------
-- SERIOUS UI COLORS & FONTS
----------------------------------------------------------------
local C = {
    bg      = Color3.fromRGB(8,   8,   8),
    bgLight = Color3.fromRGB(12,  12,  12),
    card    = Color3.fromRGB(16,  16,  16),
    cardH   = Color3.fromRGB(24,  24,  24),
    border  = Color3.fromRGB(35,  35,  35),
    white   = Color3.fromRGB(220, 220, 220),
    muted   = Color3.fromRGB(100, 100, 100),
    accent  = Color3.fromRGB(200, 25,  40),
    accentL = Color3.fromRGB(240, 40,  55),
    accentD = Color3.fromRGB(120, 15,  20),
    off     = Color3.fromRGB(25,  25,  25),
    green   = Color3.fromRGB(40,  160, 60),
    yellow  = Color3.fromRGB(200, 160, 30),
    red     = Color3.fromRGB(200, 35,  40),
    cyan    = Color3.fromRGB(35,  160, 200),
}

local FN, FN_I
pcall(function() FN   = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Bold) end)
pcall(function() FN_I = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Regular, Enum.FontStyle.Italic) end)
if not FN   then pcall(function() FN   = Font.fromEnum(Enum.Font.Code) end) end
if not FN_I then pcall(function() FN_I = Font.fromEnum(Enum.Font.Code) end) end

----------------------------------------------------------------
-- UI FRAMEWORK (SERIOUS & FLAT)
----------------------------------------------------------------
local sg = Instance.new("ScreenGui")
sg.Name = "HE_UI_SERIOUS"; sg.ResetOnSpawn = false; sg.ZIndexBehavior = Enum.ZIndexBehavior.Global
sg.DisplayOrder = 50; sg.Parent = pGui

local main = Instance.new("Frame", sg)
main.Name = "Main"; main.Size = UDim2.fromOffset(470, 340)
main.Position = UDim2.fromScale(0.5, 0.5); main.AnchorPoint = Vector2.new(0.5, 0.5)
main.BackgroundColor3 = C.bg; main.ClipsDescendants = true; main.ZIndex = 2; main.BorderSizePixel = 0
local mSt = Instance.new("UIStroke", main); mSt.Color = C.border; mSt.Thickness = 1

local glass = Instance.new("Frame", main)
glass.BackgroundColor3 = C.border; glass.BackgroundTransparency = 0.5; glass.BorderSizePixel = 0
glass.Position = UDim2.fromOffset(16, 32); glass.Size = UDim2.new(1, -32, 0, 1); glass.ZIndex = 10

local top = Instance.new("Frame", main)
top.Name = "Top"; top.BackgroundTransparency = 1; top.Size = UDim2.new(1, -16, 0, 34)
top.Position = UDim2.fromOffset(8, 0); top.ZIndex = 5

local tLbl = Instance.new("TextLabel", top)
tLbl.BackgroundTransparency = 1; tLbl.Position = UDim2.fromOffset(4, 0); tLbl.Size = UDim2.new(0, 220, 1, 0)
tLbl.Text = "HANDICAPPED ENGINE"; tLbl.TextSize = 13; tLbl.TextColor3 = C.white
tLbl.TextXAlignment = Enum.TextXAlignment.Left; tLbl.ZIndex = 5
if FN then tLbl.FontFace = FN else tLbl.Font = Enum.Font.Code end

local statusDot = Instance.new("Frame", top)
statusDot.Size = UDim2.fromOffset(6,6); statusDot.Position = UDim2.fromOffset(192, 14)
statusDot.BackgroundColor3 = C.green; statusDot.ZIndex = 5; statusDot.BorderSizePixel = 0

local fpsLabel = Instance.new("TextLabel", top)
fpsLabel.BackgroundTransparency = 1; fpsLabel.AnchorPoint = Vector2.new(1, 0.5)
fpsLabel.Position = UDim2.new(1, -65, 0.5, 0); fpsLabel.Size = UDim2.fromOffset(50, 18)
fpsLabel.Text = "0 FPS"; fpsLabel.TextSize = 10; fpsLabel.TextColor3 = Color3.new(1, 0, 0); fpsLabel.ZIndex = 5
if FN then fpsLabel.FontFace = FN else fpsLabel.Font = Enum.Font.Code end
task.spawn(function()
    local lastTime = tick()
    local frames = 0
    RS.RenderStepped:Connect(function()
        frames = frames + 1
        if tick() - lastTime >= 1 then
            pcall(function() fpsLabel.Text = frames.." FPS" end)
            frames = 0; lastTime = tick()
        end
    end)
end)

local closeB = Instance.new("TextButton", top); closeB.BackgroundTransparency = 1
closeB.AnchorPoint = Vector2.new(1, 0.5); closeB.Position = UDim2.new(1, 0, 0.5, 0)
closeB.Size = UDim2.fromOffset(24, 24); closeB.Text = "X"; closeB.TextColor3 = C.muted; closeB.TextSize = 14; closeB.ZIndex = 5
if FN then closeB.FontFace = FN else closeB.Font = Enum.Font.Code end
closeB.MouseEnter:Connect(function()  TW:Create(closeB, TweenInfo.new(0.1), {TextColor3 = C.red}):Play() end)
closeB.MouseLeave:Connect(function()  TW:Create(closeB, TweenInfo.new(0.1), {TextColor3 = C.muted}):Play() end)
closeB.MouseButton1Click:Connect(function() sg.Enabled = false end)

local minB = Instance.new("TextButton", top); minB.BackgroundTransparency = 1
minB.AnchorPoint = Vector2.new(1, 0.5); minB.Position = UDim2.new(1, -30, 0.5, 0)
minB.Size = UDim2.fromOffset(24, 24); minB.Text = "-"; minB.TextColor3 = C.muted; minB.TextSize = 16; minB.ZIndex = 5
if FN then minB.FontFace = FN else minB.Font = Enum.Font.Code end
local isMin, szBefore = false, nil
minB.MouseButton1Click:Connect(function()
    isMin = not isMin
    if isMin then szBefore = main.Size; TW:Create(main, TweenInfo.new(0.2), {Size = UDim2.new(main.Size.X.Scale, main.Size.X.Offset, 0, 34)}):Play()
    else TW:Create(main, TweenInfo.new(0.2), {Size = szBefore or UDim2.fromOffset(470, 340)}):Play() end
end)

do local dg, ds, sp = false, nil, nil
    top.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dg = true; ds = i.Position; sp = main.Position end end)
    UIS.InputChanged:Connect(function(i) if dg and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = i.Position - ds; main.Position = UDim2.new(sp.X.Scale, sp.X.Offset+d.X, sp.Y.Scale, sp.Y.Offset+d.Y) end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dg = false end end)
end

local tabFrame = Instance.new("Frame", main)
tabFrame.BackgroundTransparency = 1; tabFrame.Position = UDim2.fromOffset(8, 42)
tabFrame.Size = UDim2.new(1, -16, 0, 24); tabFrame.ZIndex = 5
local tabLay = Instance.new("UIListLayout", tabFrame)
tabLay.FillDirection = Enum.FillDirection.Horizontal; tabLay.Padding = UDim.new(0, 2)

local sep = Instance.new("Frame", main)
sep.BackgroundColor3 = C.border; sep.BackgroundTransparency = 0.5; sep.BorderSizePixel = 0
sep.Position = UDim2.fromOffset(8, 68); sep.Size = UDim2.new(1, -16, 0, 1); sep.ZIndex = 5

local TAB_NAMES = {"PVP", "Combat", "Teleports", "Utility", "Settings"}
local tabBtns, pages = {}, {}
local curTab = nil

local pagesH = Instance.new("Frame", main)
pagesH.BackgroundTransparency = 1; pagesH.Position = UDim2.fromOffset(8, 74)
pagesH.Size = UDim2.new(1, -16, 1, -80); pagesH.ClipsDescendants = true; pagesH.ZIndex = 3

local function selectTab(name)
    curTab = name
    for n, pg  in pairs(pages)   do pg.Visible  = (n == name) end
    for n, btn in pairs(tabBtns) do
        local active = (n == name)
        btn.TextColor3        = active and C.white  or C.muted
        btn.BackgroundColor3  = active and C.accent or C.bg
        btn.BackgroundTransparency = active and 0.85 or 1
    end
end

for _, name in ipairs(TAB_NAMES) do
    local b = Instance.new("TextButton", tabFrame)
    b.BackgroundTransparency = 1; b.BackgroundColor3 = C.bg; b.AutomaticSize = Enum.AutomaticSize.X
    b.Size = UDim2.fromOffset(0, 22); b.Text = "  "..name.."  "; b.TextSize = 11; b.TextColor3 = C.muted; b.ZIndex = 5
    if FN then b.FontFace = FN else b.Font = Enum.Font.Code end
    b.MouseButton1Click:Connect(function() selectTab(name) end)
    tabBtns[name] = b

    local pg = Instance.new("ScrollingFrame", pagesH)
    pg.BackgroundTransparency = 1; pg.Size = UDim2.fromScale(1,1); pg.Visible = false
    pg.ScrollBarThickness = 3; pg.ScrollBarImageColor3 = C.accent
    pg.CanvasSize = UDim2.new(); pg.AutomaticCanvasSize = Enum.AutomaticSize.Y; pg.ZIndex = 3; pg.BorderSizePixel = 0
    local lay = Instance.new("UIListLayout", pg); lay.Padding = UDim.new(0,5); lay.SortOrder = Enum.SortOrder.LayoutOrder
    local pad = Instance.new("UIPadding", pg); pad.PaddingBottom = UDim.new(0,10)
    pages[name] = pg
end
selectTab("PVP")

local function mkRow(parent, ht, ord)
    local f  = Instance.new("Frame", parent); f.Size = UDim2.new(1,0,0,ht or 28); f.BackgroundColor3 = C.card
    f.LayoutOrder = ord or 0; f.ZIndex = 3; f.BorderSizePixel = 0
    local st = Instance.new("UIStroke", f); st.Color = C.border; st.Thickness = 1
    local ac = Instance.new("Frame", f); ac.BorderSizePixel = 0; ac.Position = UDim2.fromOffset(0,0)
    ac.Size = UDim2.new(0,3,1,0); ac.BackgroundColor3 = C.accent; ac.ZIndex = 4
    return f
end

local function section(parent, text, ord)
    local f  = Instance.new("Frame", parent); f.BackgroundTransparency = 1; f.Size = UDim2.new(1,0,0,20)
    f.LayoutOrder = ord or 0; f.ZIndex = 3
    local lL = Instance.new("Frame", f); lL.BackgroundColor3 = C.accent; lL.BackgroundTransparency = 0.5; lL.BorderSizePixel = 0
    lL.AnchorPoint = Vector2.new(0,0.5); lL.Position = UDim2.fromScale(0,0.5); lL.Size = UDim2.new(0.2,0,0,1)
    local lb = Instance.new("TextLabel", f); lb.BackgroundTransparency = 1; lb.AnchorPoint = Vector2.new(0.5,0.5)
    lb.Position = UDim2.fromScale(0.5,0.5); lb.Size = UDim2.fromOffset(160,18); lb.Text = text; lb.TextSize = 11
    lb.TextColor3 = C.white; lb.ZIndex = 3
    if FN then lb.FontFace = FN else lb.Font = Enum.Font.Code end
    local lR = Instance.new("Frame", f); lR.BackgroundColor3 = C.accent; lR.BackgroundTransparency = 0.5; lR.BorderSizePixel = 0
    lR.AnchorPoint = Vector2.new(1,0.5); lR.Position = UDim2.fromScale(1,0.5); lR.Size = UDim2.new(0.2,0,0,1)
end

local function addBtn(parent, text, cb, ord)
    local f  = mkRow(parent, 28, ord)
    local lb = Instance.new("TextLabel", f); lb.BackgroundTransparency = 1; lb.Position = UDim2.fromOffset(10,0)
    lb.Size = UDim2.new(1,-30,1,0); lb.Text = text; lb.TextSize = 12; lb.TextColor3 = C.white
    lb.TextXAlignment = Enum.TextXAlignment.Left; lb.ZIndex = 4
    if FN then lb.FontFace = FN else lb.Font = Enum.Font.Code end
    local ch = Instance.new("TextLabel", f); ch.BackgroundTransparency = 1; ch.AnchorPoint = Vector2.new(1,0.5)
    ch.Position = UDim2.new(1,-8,0.5,0); ch.Size = UDim2.fromOffset(12,18); ch.Text = ">"; ch.TextSize = 14; ch.TextColor3 = C.muted; ch.ZIndex = 4
    if FN then ch.FontFace = FN end
    local cl = Instance.new("TextButton", f); cl.BackgroundTransparency = 1; cl.Text = ""; cl.Size = UDim2.fromScale(1,1); cl.ZIndex = 5
    cl.MouseEnter:Connect(function()  TW:Create(f, TweenInfo.new(0.1), {BackgroundColor3 = C.cardH}):Play(); ch.TextColor3 = C.accentL end)
    cl.MouseLeave:Connect(function()  TW:Create(f, TweenInfo.new(0.1), {BackgroundColor3 = C.card}):Play();  ch.TextColor3 = C.muted  end)
    cl.MouseButton1Click:Connect(function() if cb then pcall(cb, lb, f) end end)
end

local function addTgl(parent, text, data, ord)
    if data._state == nil then data._state = (data.default == true) end
    local state = data._state
    local f  = mkRow(parent, 28, ord)
    local lb = Instance.new("TextLabel", f); lb.BackgroundTransparency = 1; lb.Position = UDim2.fromOffset(10,0)
    lb.Size = UDim2.new(1,-56,1,0); lb.Text = text; lb.TextSize = 12; lb.TextColor3 = C.white
    lb.TextXAlignment = Enum.TextXAlignment.Left; lb.ZIndex = 4
    if FN then lb.FontFace = FN else lb.Font = Enum.Font.Code end
    local pl = Instance.new("Frame", f); pl.AnchorPoint = Vector2.new(1,0.5); pl.Position = UDim2.new(1,-8,0.5,0)
    pl.Size = UDim2.fromOffset(34,16); pl.BackgroundColor3 = state and C.accent or C.off; pl.ZIndex = 4; pl.BorderSizePixel = 0
    local kn = Instance.new("Frame", pl); kn.Size = UDim2.fromOffset(12,12)
    kn.Position = state and UDim2.fromOffset(20,2) or UDim2.fromOffset(2,2)
    kn.BackgroundColor3 = C.white; kn.ZIndex = 5; kn.BorderSizePixel = 0
    local function render(a)
        local gp = state and UDim2.fromOffset(20,2) or UDim2.fromOffset(2,2)
        if a then TW:Create(kn, TweenInfo.new(0.12), {Position = gp}):Play() else kn.Position = gp end
        pl.BackgroundColor3 = state and C.accent or C.off
    end
    local cl = Instance.new("TextButton", f); cl.BackgroundTransparency = 1; cl.Text = ""; cl.Size = UDim2.fromScale(1,1); cl.ZIndex = 5
    cl.MouseEnter:Connect(function()  TW:Create(f, TweenInfo.new(0.1), {BackgroundColor3 = C.cardH}):Play() end)
    cl.MouseLeave:Connect(function()  TW:Create(f, TweenInfo.new(0.1), {BackgroundColor3 = C.card}):Play()  end)
    cl.MouseButton1Click:Connect(function() state = not state; data._state = state; render(true); if data.cb then pcall(data.cb, state) end end)
    if state and data.cb then task.defer(function() pcall(data.cb, state) end) end
end

local function addSlider(parent, data, ord)
    local min, max = data.min or 0, data.max or 100
    local val = data._savedValue or data.default or min
    local f  = mkRow(parent, 38, ord)
    local tl = Instance.new("TextLabel", f); tl.BackgroundTransparency = 1; tl.Position = UDim2.fromOffset(10,1)
    tl.Size = UDim2.new(1,-16,0,14); tl.Text = data.name..": "..val; tl.TextSize = 11; tl.TextColor3 = C.white
    tl.TextXAlignment = Enum.TextXAlignment.Left; tl.ZIndex = 4
    if FN then tl.FontFace = FN else tl.Font = Enum.Font.Code end
    local tr = Instance.new("Frame", f); tr.Size = UDim2.new(1,-20,0,4); tr.Position = UDim2.new(0,10,0,24)
    tr.BackgroundColor3 = C.off; tr.BorderSizePixel = 0; tr.ZIndex = 4
    local r  = math.clamp((val - min) / math.max(max - min, 1), 0, 1)
    local fl = Instance.new("Frame", tr); fl.Size = UDim2.new(r,0,1,0); fl.BackgroundColor3 = C.accent; fl.BorderSizePixel = 0; fl.ZIndex = 4
    local kb = Instance.new("Frame", tr); kb.Size = UDim2.fromOffset(8,12); kb.AnchorPoint = Vector2.new(0.5,0.5)
    kb.Position = UDim2.new(r,0,0.5,0); kb.BackgroundColor3 = C.white; kb.ZIndex = 5; kb.BorderSizePixel = 0
    local dg = false
    local function set(x)
        local rel = math.clamp((x - tr.AbsolutePosition.X) / math.max(tr.AbsoluteSize.X,1), 0, 1)
        fl.Size = UDim2.new(rel,0,1,0); kb.Position = UDim2.new(rel,0,0.5,0)
        val = math.floor(min + (max - min) * rel); tl.Text = data.name..": "..val; data._savedValue = val
        if data.cb then pcall(data.cb, val) end
    end
    tr.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dg = true; set(i.Position.X) end end)
    UIS.InputChanged:Connect(function(i) if dg and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then set(i.Position.X) end end)
    UIS.InputEnded:Connect(function(i)   if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dg = false end end)
end

local function addDropdown(parent, text, options, cb, ord)
    local f = mkRow(parent, 28, ord)
    local fZ = f.ZIndex
    local lb = Instance.new("TextLabel", f); lb.BackgroundTransparency = 1; lb.Position = UDim2.fromOffset(10,0)
    lb.Size = UDim2.new(1,-30,1,0); lb.Text = text .. ": None"; lb.TextSize = 11; lb.TextColor3 = C.white
    lb.TextXAlignment = Enum.TextXAlignment.Left; lb.ZIndex = fZ+1
    if FN then lb.FontFace = FN else lb.Font = Enum.Font.Code end
    local ch = Instance.new("TextLabel", f); ch.BackgroundTransparency = 1; ch.AnchorPoint = Vector2.new(1,0.5)
    ch.Position = UDim2.new(1,-8,0.5,0); ch.Size = UDim2.fromOffset(12,18); ch.Text = "V"; ch.TextSize = 12; ch.TextColor3 = C.muted; ch.ZIndex = fZ+1
    
    local dropFrame = Instance.new("ScrollingFrame", f)
    dropFrame.Size = UDim2.new(1, 0, 0, 100); dropFrame.Position = UDim2.new(0, 0, 1, 0)
    dropFrame.BackgroundColor3 = C.cardH; dropFrame.BorderSizePixel = 0; dropFrame.ZIndex = 9999
    dropFrame.Visible = false; dropFrame.ScrollBarThickness = 2; dropFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    local dropLay = Instance.new("UIListLayout", dropFrame)
    local dropStroke = Instance.new("UIStroke", dropFrame); dropStroke.Color = C.border; dropStroke.Thickness = 1
    
    local isOpen = false
    local cl = Instance.new("TextButton", f); cl.BackgroundTransparency = 1; cl.Text = ""; cl.Size = UDim2.fromScale(1,1); cl.ZIndex = fZ+2
    cl.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        dropFrame.Visible = isOpen
        ch.Text = isOpen and "^" or "V"
    end)
    
    local api = {}
    function api:Refresh(newOptions)
        for _, v in pairs(dropFrame:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
        for _, opt in ipairs(newOptions) do
            local ob = Instance.new("TextButton", dropFrame)
            ob.Size = UDim2.new(1, 0, 0, 24); ob.BackgroundColor3 = C.card; ob.BorderSizePixel = 0
            ob.Text = "  " .. opt; ob.TextColor3 = C.muted; ob.TextSize = 11; ob.TextXAlignment = Enum.TextXAlignment.Left; ob.ZIndex = dropFrame.ZIndex+1
            if FN then ob.FontFace = FN else ob.Font = Enum.Font.Code end
            ob.MouseEnter:Connect(function() ob.BackgroundColor3 = C.cardH; ob.TextColor3 = C.white end)
            ob.MouseLeave:Connect(function() ob.BackgroundColor3 = C.card; ob.TextColor3 = C.muted end)
            ob.MouseButton1Click:Connect(function()
                isOpen = false; dropFrame.Visible = false; ch.Text = "V"
                lb.Text = text .. ": " .. opt
                if cb then pcall(cb, opt) end
            end)
        end
    end
    api:Refresh(options)
    return api
end

----------------------------------------------------------------
-- STATE
----------------------------------------------------------------
local FastAtkOn, FastAtkRange = false, 5000
local DashOn, DashDist, DashConn = false, 1, nil
local Unbr, UnbrConn = false, nil
local autoV4, v4Conn = false, nil
local DGunOn = false
local DG_Mobs, DG_Players, DG_Sea = true, true, true
local DG_Range, DG_Burst = 400, 3
-- Magnet separado
local MagnetManualOn  = false
local MagnetSafeOn    = false
local MagnetRange     = 2500
local MagnetManualDist = 20   -- metros abajo (lento)
local MagnetSafeDist   = 30   -- metros abajo (rápido)
local TrackerOn, TrackerTarget, TrackerConn = false, nil, nil
local ESPOn, ESPObj  = false, {}
local _WS, _WSOn, _JV, _JOn, _Noclip = 16, false, 50, false, false
local AutoFarmPlayersOn = false
local AutoSafeHealth    = false
local IsTeleportingToSafety = false


----------------------------------------------------------------
-- REMOTES
----------------------------------------------------------------
local RegAttack, RegHit, CommF_
pcall(function()
    local M = RPS:FindFirstChild("Modules"); local N = M and M:FindFirstChild("Net")
    if N then RegAttack = N:FindFirstChild("RE/RegisterAttack"); RegHit = N:FindFirstChild("RE/RegisterHit") end
end)
pcall(function() local R = RPS:FindFirstChild("Remotes"); if R then CommF_ = R:FindFirstChild("CommF_") end end)

-- Helper: obtiene remotes en caliente si aún son nil
local function ensureNetRemotes()
    if RegAttack and RegHit then return end
    pcall(function()
        local M = RPS:FindFirstChild("Modules"); local N = M and M:FindFirstChild("Net")
        if N then
            RegAttack = RegAttack or N:FindFirstChild("RE/RegisterAttack")
            RegHit    = RegHit    or N:FindFirstChild("RE/RegisterHit")
        end
    end)
end

----------------------------------------------------------------
-- DRAGON GUN M1 (Lógica Completa Standalone)
----------------------------------------------------------------
local ShootGunEv, Valid2
pcall(function()
    local M = RPS:FindFirstChild("Modules"); local N = M and M:FindFirstChild("Net")
    if N then ShootGunEv = N:FindFirstChild("RE/ShootGunEvent") end
    local R = RPS:FindFirstChild("Remotes")
    if R then Valid2 = R:FindFirstChild("Validator2") end
end)
-- WaitForChild fallback en background
task.spawn(function()
    if not ShootGunEv then
        local M = RPS:WaitForChild("Modules", 10); local N = M and M:WaitForChild("Net", 10)
        if N then ShootGunEv = ShootGunEv or N:WaitForChild("RE/ShootGunEvent", 10) end
    end
    if not Valid2 then
        local R = RPS:WaitForChild("Remotes", 10)
        if R then Valid2 = Valid2 or R:WaitForChild("Validator2", 10) end
    end
end)

local gUV, sUV, gUVs
pcall(function() gUV  = debug.getupvalue  or getupvalue  end)
pcall(function() sUV  = debug.setupvalue  or setupvalue  end)
pcall(function() gUVs = debug.getupvalues or getupvalues end)

local ShootFn
local VI = {v26=12, v22=13, v25=14, v21=15, v23=16, v24=17, v27=18}

local function InitDG()
    pcall(function()
        local C2 = RPS:FindFirstChild("Controllers"); local CC = C2 and C2:FindFirstChild("CombatController")
        if not CC then return end
        local ok, r = pcall(require, CC)
        if ok and type(r) == "table" and r.Attack and gUV then ShootFn = gUV(r.Attack, 9) end
    end)
end
InitDG()

local function NextVal()
    if not ShootFn then InitDG() end
    if not ShootFn or not gUVs or not sUV or not gUV then return 0, 0 end
    local ok, cd, ct = pcall(function()
        local up = gUVs(ShootFn); if not up then return 0, 0 end
        if up[VI.v21] ~= 727595 then
            for i, v in pairs(up) do
                if v == 727595 then
                    local off = i - 15
                    VI.v21=i; VI.v22=13+off; VI.v23=16+off; VI.v24=17+off; VI.v26=12+off; VI.v25=14+off; VI.v27=18+off
                    break
                end
            end
        end
        local a,b,c,d,e,f,g = gUV(ShootFn,VI.v21),gUV(ShootFn,VI.v22),gUV(ShootFn,VI.v23),gUV(ShootFn,VI.v24),gUV(ShootFn,VI.v25),gUV(ShootFn,VI.v26),gUV(ShootFn,VI.v27)
        if not (a and b and c and d and e and f and g) then InitDG(); return 0, 0 end
        local h = f*b; local j = (e*b+f*a)%c; j = (j*c+h)%d
        e = math.floor(j/c); f = j-e*c; g = g+1
        sUV(ShootFn,VI.v25,e); sUV(ShootFn,VI.v26,f); sUV(ShootFn,VI.v27,g)
        return math.floor(j/d*16777215), g
    end)
    return ok and cd or 0, ok and ct or 0
end

-- GetEntityPart (mejor que solo HumanoidRootPart)
local function GetEntityPart(entity)
    return entity:FindFirstChild("HumanoidRootPart")
        or entity:FindFirstChild("Engine")
        or entity:FindFirstChild("Head")
        or entity:FindFirstChild("Base")
        or entity.PrimaryPart
end

-- GetClosestTarget — lógica completa standalone con SeaEvents por nombre
local function ClosestGT()
    local ch   = lp.Character
    local root = ch and ch:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local best, bd = nil, DG_Range
    local myPos    = root.Position

    -- Mobs (Enemies folder)
    if DG_Mobs then
        pcall(function()
            local ef = workspace:FindFirstChild("Enemies")
            if ef then
                for _, en in pairs(ef:GetChildren()) do pcall(function()
                    local hum = en:FindFirstChildOfClass("Humanoid"); local r = GetEntityPart(en)
                    if hum and hum.Health > 0 and r then
                        local d = (r.Position - myPos).Magnitude
                        if d < bd then bd = d; best = r end
                    end end) end
            end
        end)
    end

    -- Sea Events (por folder + por nombre en workspace)
    if DG_Sea then
        pcall(function()
            for _, fn in pairs({"SeaBeasts","SeaEvents"}) do
                local f = workspace:FindFirstChild(fn)
                if f then
                    for _, m in pairs(f:GetChildren()) do pcall(function()
                        local hum = m:FindFirstChildOfClass("Humanoid"); local r = GetEntityPart(m)
                        if r and (not hum or hum.Health > 0) then
                            local d = (r.Position - myPos).Magnitude
                            if d < bd then bd = d; best = r end
                        end end) end
                end
            end
            -- Buscar por nombre en workspace raíz
            for _, obj in pairs(workspace:GetChildren()) do
                if obj:IsA("Model") and obj ~= ch then
                    local name = obj.Name:lower()
                    if name:find("ship") or name:find("boat") or name:find("beast") or name:find("terror") or name:find("piranha") or name:find("leviathan") then
                        pcall(function()
                            local hum = obj:FindFirstChildOfClass("Humanoid"); local r = GetEntityPart(obj)
                            if r and (not hum or hum.Health > 0) then
                                local d = (r.Position - myPos).Magnitude
                                if d < bd then bd = d; best = r end
                            end
                        end)
                    end
                end
            end
        end)
    end

    -- Players
    if DG_Players then
        pcall(function()
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= lp and p.Character then pcall(function()
                    local hum = p.Character:FindFirstChildOfClass("Humanoid")
                    local r   = p.Character:FindFirstChild("HumanoidRootPart")
                    if hum and hum.Health > 0 and r then
                        local d = (r.Position - myPos).Magnitude
                        if d < bd then bd = d; best = r end
                    end end) end
            end
        end)
    end

    return best
end

----------------------------------------------------------------
-- TELEPORT
----------------------------------------------------------------
local Islands = {
    ["Skypiea"]           = Vector3.new(-4607,  872,  -1667),
    ["Skypiea Alta"]      = Vector3.new(-7894,  5547,  -380),
    ["Underwater City"]   = Vector3.new(61163,  11,    1819),
    ["Reino de Rosa"]     = Vector3.new(-387,   324,    650),
    ["Graveyard"]         = Vector3.new(-6511.497, 87.605, -140.652),
    ["Isla Olvidada"]     = Vector3.new(-3054,  235, -10142),
    ["Cursed Ship"]       = Vector3.new(923.212, 126.976, 32852.832),
    ["Snow Mountain"]     = Vector3.new(609,    400,  -5372),
    ["Port Town"]         = Vector3.new(-450,   107,   5950),
    ["Turtle Island"]     = Vector3.new(-13234, 331,  -7625),
    ["Castle on the Sea"] = Vector3.new(-5039,  27,    4324),
    ["Haunted Castle"]    = Vector3.new(-9479,  141,   5566),
    ["Tiki Outpost"]      = Vector3.new(-16547, 61,    -173),
    ["Mansion Swan"]      = Vector3.new(2066,   29,     642),
}

local function TPTo(name)
    local pos = Islands[name]; if not pos then return end
    pcall(function() if CommF_ then CommF_:InvokeServer("requestEntrance", pos) end end)
    task.wait(0.15)
    pcall(function()
        local h = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if h and (h.Position - pos).Magnitude > 150 then h.CFrame = CFrame.new(pos) end
    end)
end

----------------------------------------------------------------
-- FLY ENGINE (BODYVELOCITY)
----------------------------------------------------------------
local FLY_SPEED = 350
local flyOn     = false
local flyBV, flyBG = nil, nil
local flyLoopConn, flyNoclipConn, flyCharConn = nil, nil, nil

local function destroyFlyEngine()
    if flyLoopConn   then flyLoopConn:Disconnect();   flyLoopConn   = nil end
    if flyNoclipConn then flyNoclipConn:Disconnect(); flyNoclipConn = nil end
    if flyCharConn   then flyCharConn:Disconnect();   flyCharConn   = nil end
    if flyBV then flyBV:Destroy(); flyBV = nil end
    if flyBG then flyBG:Destroy(); flyBG = nil end
    pcall(function()
        local char = lp.Character; if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid"); local hrp = char:FindFirstChild("HumanoidRootPart")
        if hum then hum.PlatformStand = false; pcall(function() hum:ChangeState(Enum.HumanoidStateType.Freefall) end) end
        if hrp then
            hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
            for _, v in pairs(hrp:GetChildren()) do
                if v.Name == "Darling_FlyVelocity" or v.Name == "Darling_FlyGyro" then v:Destroy() end
            end
        end
    end)
end

local function startFlyEngine()
    local char = lp.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    if flyBV then flyBV:Destroy(); flyBV = nil end
    if flyBG then flyBG:Destroy(); flyBG = nil end
    pcall(function() hum:ChangeState(Enum.HumanoidStateType.Physics) end)
    flyBV = Instance.new("BodyVelocity"); flyBV.Name = "Darling_FlyVelocity"
    flyBV.MaxForce = Vector3.new(1e9,1e9,1e9); flyBV.Velocity = Vector3.new(0,0,0); flyBV.Parent = hrp
    flyBG = Instance.new("BodyGyro");     flyBG.Name = "Darling_FlyGyro"
    flyBG.MaxTorque = Vector3.new(1e9,1e9,1e9); flyBG.P = 9e4; flyBG.CFrame = hrp.CFrame; flyBG.Parent = hrp
    if flyNoclipConn then flyNoclipConn:Disconnect() end
    flyNoclipConn = RS.Stepped:Connect(function()
        if not flyOn then return end
        local c = lp.Character; if not c then return end
        for _, part in pairs(c:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end
    end)
    if flyLoopConn then flyLoopConn:Disconnect() end
    flyLoopConn = RS.RenderStepped:Connect(function()
        if not flyOn then destroyFlyEngine(); return end
        local c   = lp.Character
        local h   = c and c:FindFirstChild("HumanoidRootPart")
        local hm  = c and c:FindFirstChildOfClass("Humanoid")
        local cam = workspace.CurrentCamera
        if not h or not hm or not cam then return end
        if not flyBV or not flyBV.Parent or flyBV.Parent ~= h then startFlyEngine(); return end
        pcall(function() hm:ChangeState(Enum.HumanoidStateType.Physics) end)
        local camCF  = cam.CFrame; local forward = camCF.LookVector; local right = camCF.RightVector
        local moveDir = Vector3.new(0,0,0)
        pcall(function()
            if UIS:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + forward end
            if UIS:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - forward end
            if UIS:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + right   end
            if UIS:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - right   end
        end)
        pcall(function()
            if hm.MoveDirection.Magnitude > 0.05 then
                local md       = hm.MoveDirection
                local flatLook = Vector3.new(forward.X,0,forward.Z).Unit
                local flatR    = Vector3.new(right.X,  0,right.Z  ).Unit
                moveDir = (forward * md:Dot(flatLook) + right * md:Dot(flatR))
            end
        end)
        local upDir = Vector3.new(0,0,0)
        pcall(function()
            if UIS:IsKeyDown(Enum.KeyCode.Space)    then upDir = upDir + Vector3.new(0,1,0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
                upDir = upDir - Vector3.new(0,1,0) end
        end)
        local finalDir = Vector3.new(0,0,0)
        if moveDir.Magnitude > 0.05 then finalDir = finalDir + moveDir.Unit end
        if upDir.Magnitude    > 0.05 then finalDir = finalDir + upDir.Unit  end
        if finalDir.Magnitude > 0.05 then flyBV.Velocity = finalDir.Unit * FLY_SPEED
        else flyBV.Velocity = Vector3.new(0,0,0) end
        flyBG.CFrame = camCF
    end)
end

local function startFly()
    flyOn = true; startFlyEngine()
    if flyCharConn then flyCharConn:Disconnect() end
    flyCharConn = lp.CharacterAdded:Connect(function() task.wait(0.5); if flyOn then startFlyEngine() end end)
end
local function stopFly() flyOn = false; destroyFlyEngine() end

----------------------------------------------------------------
-- PVP / SAFEZONE HELPERS (usados por ESP + Auto Farm)
----------------------------------------------------------------
local function AX_ReadPvPState(target)
    local ok, on = pcall(function()
        local attr = target:GetAttribute("PvpDisabled")
        if attr ~= nil then return attr ~= true end
        local main = target:FindFirstChild("PlayerGui") and target.PlayerGui:FindFirstChild("Main")
        if main then
            local dis = main:FindFirstChild("PvpDisabled")
            if dis then return not dis.Visible end
            local pvp = main:FindFirstChild("Pvp")
            if pvp then
                local frame = pvp:FindFirstChild("Frame")
                if frame then
                    local btn = frame:FindFirstChild("PvpButton") or frame:FindFirstChildOfClass("TextButton")
                    if btn and btn:IsA("TextButton") then
                        local txt = tostring(btn.Text or ""):upper()
                        if txt:find("OFF") then return false end
                        if txt:find("ON") then return true end
                    end
                end
            end
        end
        return true
    end)
    return not ok or on
end

local function AX_InSafeZone(target)
    local ok, inZone = pcall(function()
        local char = target.Character; if not char then return false end
        local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return false end
        local wo = workspace:FindFirstChild("_WorldOrigin"); if not wo then return false end
        local safeZones = wo:FindFirstChild("SafeZones")
        if safeZones then
            for _, zone in pairs(safeZones:GetChildren()) do
                local mesh = zone:FindFirstChild("Mesh")
                if mesh and mesh:IsA("SpecialMesh") then
                    local radius = (zone.Size.X * mesh.Scale.X) / 2
                    if radius and radius > 0 and (zone.Position - hrp.Position).Magnitude <= radius then
                        return true
                    end
                end
            end
        end
        return false
    end)
    return ok and inZone
end

----------------------------------------------------------------
-- ESP (AVANZADO: +KEN, +PVP STATUS)
----------------------------------------------------------------
local function hpCol(p) if p>0.6 then return C.green elseif p>0.3 then return C.yellow else return C.red end end
local function ClearESP() for _,o in pairs(ESPObj) do pcall(function() o:Destroy() end) end; ESPObj = {} end
local function MkESP(p)
    pcall(function()
        if not p.Character or not p.Character:FindFirstChild("Head") then return end
        if p.Character.Head:FindFirstChild("HE_ESP") then return end
        local bb = Instance.new("BillboardGui", p.Character.Head)
        bb.Name = "HE_ESP"; bb.Size = UDim2.new(0,120,0,105)
        bb.StudsOffset = Vector3.new(0,3.5,0); bb.AlwaysOnTop = true
        local af = Instance.new("Frame", bb); af.Size = UDim2.new(0,24,0,24); af.AnchorPoint = Vector2.new(0.5,0)
        af.Position = UDim2.new(0.5,0,0,0); af.BackgroundColor3 = Color3.fromRGB(25,25,30); af.BorderSizePixel = 0
        Instance.new("UICorner", af).CornerRadius = UDim.new(0.5,0)
        local ai = Instance.new("ImageLabel", af); ai.Size = UDim2.new(1,0,1,0); ai.BackgroundTransparency = 1
        ai.Image = "rbxthumb://type=AvatarHeadShot&id="..p.UserId.."&w=150&h=150"
        Instance.new("UICorner", ai).CornerRadius = UDim.new(0.5,0)
        local nl = Instance.new("TextLabel", bb); nl.Size = UDim2.new(1,0,0,12); nl.Position = UDim2.new(0,0,0,26)
        nl.BackgroundTransparency = 1; nl.Font = Enum.Font.Code; nl.TextSize = 10; nl.TextStrokeTransparency = 0.2
        nl.TextColor3 = C.white; nl.Text = p.DisplayName
        local hpBg = Instance.new("Frame", bb); hpBg.Size = UDim2.new(0.75,0,0,4); hpBg.AnchorPoint = Vector2.new(0.5,0)
        hpBg.Position = UDim2.new(0.5,0,0,40); hpBg.BackgroundColor3 = Color3.fromRGB(35,35,40); hpBg.BorderSizePixel = 0
        local hpF = Instance.new("Frame", hpBg); hpF.Size = UDim2.new(1,0,1,0); hpF.BackgroundColor3 = C.green; hpF.BorderSizePixel = 0
        local hpL = Instance.new("TextLabel", bb); hpL.Size = UDim2.new(1,0,0,10); hpL.Position = UDim2.new(0,0,0,46)
        hpL.BackgroundTransparency = 1; hpL.Font = Enum.Font.Code; hpL.TextSize = 9; hpL.TextStrokeTransparency = 0.2; hpL.TextColor3 = Color3.fromRGB(180,180,180)
        local dL  = Instance.new("TextLabel", bb); dL.Size = UDim2.new(1,0,0,10); dL.Position = UDim2.new(0,0,0,58)
        dL.BackgroundTransparency = 1; dL.Font = Enum.Font.Code; dL.TextSize = 9; dL.TextStrokeTransparency = 0.2; dL.TextColor3 = C.cyan
        local wpL = Instance.new("TextLabel", bb); wpL.Size = UDim2.new(1,0,0,10); wpL.Position = UDim2.new(0,0,0,70)
        wpL.BackgroundTransparency = 1; wpL.Font = Enum.Font.Code; wpL.TextSize = 9; wpL.TextStrokeTransparency = 0.2; wpL.TextColor3 = Color3.fromRGB(200, 200, 200)
        local pvpL = Instance.new("TextLabel", bb); pvpL.Size = UDim2.new(1,0,0,10); pvpL.Position = UDim2.new(0,0,0,82)
        pvpL.BackgroundTransparency = 1; pvpL.Font = Enum.Font.Code; pvpL.TextSize = 9; pvpL.TextStrokeTransparency = 0.2
        local kenL = Instance.new("TextLabel", bb); kenL.Size = UDim2.new(1,0,0,10); kenL.Position = UDim2.new(0,0,0,94)
        kenL.BackgroundTransparency = 1; kenL.Font = Enum.Font.Code; kenL.TextSize = 9; kenL.TextStrokeTransparency = 0.2
        task.spawn(function() while bb and bb.Parent and ESPOn do pcall(function()
            local ch  = p.Character; if not ch then return end
            local hum = ch:FindFirstChildOfClass("Humanoid")
            local mh  = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            local th  = ch:FindFirstChild("HumanoidRootPart")
            if hum then
                local pct = math.clamp(hum.Health/hum.MaxHealth, 0, 1)
                hpF.Size = UDim2.new(pct,0,1,0); hpF.BackgroundColor3 = hpCol(pct)
                hpL.Text = math.floor(hum.Health).."/"..math.floor(hum.MaxHealth); hpL.TextColor3 = hpCol(pct)
            end
            if mh and th then dL.Text = "["..math.floor((mh.Position-th.Position).Magnitude).."m]" end
            
            -- PVP real usando AX_ReadPvPState + AX_InSafeZone
            local pvpOn = AX_ReadPvPState(p) and not AX_InSafeZone(p)
            pvpL.Text = pvpOn and "⚔ PVP: ON" or "🛡 PVP: OFF"
            pvpL.TextColor3 = pvpOn and C.green or C.red
            
            -- Ken Haki con número de esquives
            local dodges = 0
            local kenActive = false
            local dodgeVal = ch:GetAttribute("Dodges") or ch:GetAttribute("Ken") or ch:GetAttribute("KenHaki")
            if dodgeVal ~= nil then
                kenActive = true
                if type(dodgeVal) == "number" then dodges = dodgeVal end
            end
            local kenObj = ch:FindFirstChild("Ken") or ch:FindFirstChild("KenHaki") or ch:FindFirstChild("DodgeCalculus")
            if kenObj then
                kenActive = true
                if kenObj:IsA("IntValue") or kenObj:IsA("NumberValue") then dodges = kenObj.Value end
            end
            if kenActive then
                kenL.Text = "👁 KEN: ON ("..dodges.." esquives)"
                kenL.TextColor3 = Color3.fromRGB(255, 170, 0)
            else
                kenL.Text = "👁 KEN: OFF"
                kenL.TextColor3 = C.muted
            end
            
            -- Arma equipada
            local tool = ch:FindFirstChildOfClass("Tool")
            if tool then
                wpL.Text = "🗡 " .. tool.Name
                wpL.TextColor3 = C.yellow
            else
                wpL.Text = "👊 Ninguna"
                wpL.TextColor3 = C.muted
            end
        end); task.wait(0.25) end; pcall(function() bb:Destroy() end) end)
        table.insert(ESPObj, bb)
    end)
end
local function RefESP() ClearESP(); if not ESPOn then return end; for _,p in pairs(Players:GetPlayers()) do if p ~= lp then MkESP(p) end end end

----------------------------------------------------------------
-- FILL TABS
----------------------------------------------------------------
local n = 0; local function no() n=n+1; return n end

-- ===== PVP =====
n = 0
section(pages.PVP, "SILENT AIM", no())
addTgl(pages.PVP, "Silent Aim Players",   {cb=function(v) SilentAimModule:SetPlayerSilentAim(v) end}, no())
addTgl(pages.PVP, "Silent Aim NPCs",      {cb=function(v) SilentAimModule:SetNPCSilentAim(v)    end}, no())
addTgl(pages.PVP, "Show FOV Circle",      {cb=function(v) SilentAimModule:SetShowFOVCircle(v)   end}, no())
addSlider(pages.PVP, {name="FOV Radius",  min=10, max=1000, default=100, cb=function(v) SilentAimModule:SetFOVRadius(v) end}, no())
addTgl(pages.PVP, "Soru Auto Aim (C)",    {cb=function(v) SilentAimModule:SetSoruAutoAim(v)     end}, no())
addTgl(pages.PVP, "Tracers (Lines)",      {cb=function(v) SilentAimModule:SetTracerEnabled(v)   end}, no())

section(pages.PVP, "AZUCAR ATTACK", no())
addTgl(pages.PVP, "Azucar Attack", {cb = function(Value)
    FastAtkOn = Value
    if FastAtkOn then
        task.spawn(function()
            while FastAtkOn do
                task.wait(0.08)
                pcall(function()
                    local char = lp.Character
                    if not char then return end
                    local myHRP = char:FindFirstChild("HumanoidRootPart")
                    if not myHRP then return end

                    local Modules = RPS:WaitForChild("Modules", 3)
                    if not Modules then return end
                    local Net = Modules:WaitForChild("Net", 3)
                    if not Net then return end

                    local RegisterAttack = Net:FindFirstChild("RE/RegisterAttack")
                    local RegisterHit    = Net:FindFirstChild("RE/RegisterHit")
                    if not RegisterAttack or not RegisterHit then return end

                    local myPos      = myHRP.Position
                    local allTargets = {}

                    for _, player in pairs(Players:GetPlayers()) do
                        if player ~= lp and player.Character then
                            local pHum  = player.Character:FindFirstChild("Humanoid")
                            local pHRP  = player.Character:FindFirstChild("HumanoidRootPart")
                            local pHead = player.Character:FindFirstChild("Head")
                            if pHum and pHRP and pHead and pHum.Health > 0 then
                                if (pHRP.Position - myPos).Magnitude <= FastAtkRange then
                                    table.insert(allTargets, {player.Character, pHead})
                                end
                            end
                        end
                    end

                    local enemies = workspace:FindFirstChild("Enemies")
                    if enemies then
                        for _, npc in pairs(enemies:GetChildren()) do
                            local nHum  = npc:FindFirstChild("Humanoid")
                            local nHRP  = npc:FindFirstChild("HumanoidRootPart")
                            local nHead = npc:FindFirstChild("Head")
                            if nHum and nHRP and nHead and nHum.Health > 0 then
                                if (nHRP.Position - myPos).Magnitude <= FastAtkRange then
                                    table.insert(allTargets, {npc, nHead})
                                end
                            end
                        end
                    end

                    if #allTargets > 0 then
                        RegisterAttack:FireServer(0)
                        for _, targetPair in pairs(allTargets) do
                            RegisterHit:FireServer(targetPair[2], allTargets)
                        end
                    end
                end)
            end
        end)
    end
end}, no())
addSlider(pages.PVP, {name="Attack Range", min=100, max=10000, default=5000, cb=function(v) FastAtkRange = v end}, no())

section(pages.PVP, "DRAGON GUN M1 (BURST)", no())
addTgl(pages.PVP, "Dragon Gun M1",    {cb=function(s) DGunOn = s end},    no())
addTgl(pages.PVP, "M1 → Mobs",       {default=true, cb=function(s) DG_Mobs    = s end}, no())
addTgl(pages.PVP, "M1 → Players",    {default=true, cb=function(s) DG_Players = s end}, no())
addTgl(pages.PVP, "M1 → Sea Events", {default=true, cb=function(s) DG_Sea     = s end}, no())
addSlider(pages.PVP, {name="Burst Shots", min=1, max=10, default=3, cb=function(v) DG_Burst = v end}, no())
addSlider(pages.PVP, {name="M1 Range",    min=50, max=3000, default=400, cb=function(v) DG_Range = v end}, no())

section(pages.PVP, "MOVIMIENTO", no())
addTgl(pages.PVP, "Vuelo (Teclado: P)", {cb=function(s) if s then startFly() else stopFly() end end}, no())
addSlider(pages.PVP, {name="Vel. Vuelo", min=10, max=500, default=350, cb=function(v) FLY_SPEED = v end}, no())
addTgl(pages.PVP, "Speed Hack",  {cb=function(s) _WSOn = s end}, no())
addSlider(pages.PVP, {name="WalkSpeed",  min=16, max=5000, default=16, cb=function(v) _WS = v end}, no())
addTgl(pages.PVP, "Super Jump",  {cb=function(s) _JOn = s end}, no())
addSlider(pages.PVP, {name="JumpPower",  min=50, max=5000, default=50, cb=function(v) _JV = v end}, no())
addTgl(pages.PVP, "Noclip",      {cb=function(s) _Noclip = s end}, no())

-- ===== COMBAT =====
n = 0
section(pages.Combat, "AUTO FARM", no())
addTgl(pages.Combat, "Auto Farm (Players)", {cb=function(s) AutoFarmPlayersOn = s end}, no())

section(pages.Combat, "TARGET INDIVIDUAL", no())
local targetPlayerName = ""
local TpToSelectedOn = false
local playerDrop = nil

addBtn(pages.Combat, "Actualizar Lista Jugadores", function(lb, f)
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp then table.insert(list, p.DisplayName) end
    end
    if playerDrop then playerDrop:Refresh(list) end
    lb.Text = "Actualizado!"
    task.delay(1, function() if lb then lb.Text = "Actualizar Lista Jugadores" end end)
end, no())

playerDrop = addDropdown(pages.Combat, "Jugador", {}, function(val) targetPlayerName = val end, no())

addTgl(pages.Combat, "Ir por Jugador (AutoFarm)", {cb = function(s) TpToSelectedOn = s end}, no())
addTgl(pages.Combat, "Spectate Jugador", {cb = function(s) 
    SpectateOn = s
    if not s then
        pcall(function() workspace.CurrentCamera.CameraSubject = lp.Character.Humanoid end)
    end
end}, no())

section(pages.Combat, "DASH", no())
addTgl(pages.Combat, "Dash Length", {cb=function(s) DashOn = s
    if s then
        if DashConn then pcall(task.cancel, DashConn) end
        DashConn = task.spawn(function() while DashOn do task.wait(0.1) pcall(function()
            local c = lp.Character; if c then c:SetAttribute("DashLength",DashDist); c:SetAttribute("DashLengthAir",DashDist) end end) end end)
    else
        pcall(function() lp.Character:SetAttribute("DashLength",1); lp.Character:SetAttribute("DashLengthAir",1) end)
        if DashConn then pcall(task.cancel, DashConn); DashConn = nil end
    end end}, no())
addSlider(pages.Combat, {name="Dash Dist", min=1, max=100, default=1, cb=function(v) DashDist = v end}, no())

section(pages.Combat, "DEFENSAS", no())
addTgl(pages.Combat, "Anti Mover", {cb=function(v)
    if v then
        local function add(c) if not c:FindFirstChild("AntiMover") then Instance.new("Folder", c).Name = "AntiMover" end end
        if lp.Character then add(lp.Character) end; _G._HE_AMConn = lp.CharacterAdded:Connect(add)
    else
        if _G._HE_AMConn then _G._HE_AMConn:Disconnect() end
        pcall(function() if lp.Character:FindFirstChild("AntiMover") then lp.Character.AntiMover:Destroy() end end)
    end end}, no())
addTgl(pages.Combat, "Unbreakable", {cb=function(s) Unbr = s
    if s then
        if UnbrConn then pcall(task.cancel, UnbrConn) end
        UnbrConn = task.spawn(function() while Unbr do task.wait(0.1) pcall(function() lp.Character:SetAttribute("UnbreakableAll",true) end) end end)
    else
        if UnbrConn then pcall(task.cancel, UnbrConn); UnbrConn = nil end
        pcall(function() lp.Character:SetAttribute("UnbreakableAll",false) end)
    end end}, no())
addTgl(pages.Combat, "Auto V4", {cb=function(s) autoV4 = s
    if s then
        if v4Conn then pcall(task.cancel, v4Conn) end
        v4Conn = task.spawn(function() while autoV4 do task.wait(0.5)
            pcall(function() lp:WaitForChild("Backpack"):WaitForChild("Awakening"):WaitForChild("RemoteFunction"):InvokeServer(true) end) end end)
    else if v4Conn then pcall(task.cancel, v4Conn); v4Conn = nil end end end}, no())

section(pages.Combat, "MAGNET NPCs", no())
addTgl(pages.Combat, "Magnet NPCs (150m, 20m abajo)", {cb=function(s) MagnetManualOn = s end}, no())

section(pages.Combat, "AUTO SAFE (BYPASS)", no())
addTgl(pages.Combat, "Auto Safe (40%→TP Cursed)", {cb=function(s) AutoSafeHealth = s end}, no())

section(pages.Combat, "TRACKER (H key)", no())
addTgl(pages.Combat, "Enable H Tracker", {cb=function(s)
    TrackerOn = s
    if not s and TrackerTarget then
        TrackerTarget = nil
        if TrackerConn then TrackerConn:Disconnect(); TrackerConn = nil end
    end end}, no())

-- ===== TELEPORTS =====
n = 0
section(pages.Teleports, "THIRD SEA", no())
for _, nm in ipairs({"Port Town","Turtle Island","Castle on the Sea","Haunted Castle","Tiki Outpost"}) do
    addBtn(pages.Teleports, nm, function() TPTo(nm) end, no()) end
section(pages.Teleports, "SECOND SEA", no())
for _, nm in ipairs({"Reino de Rosa","Graveyard","Isla Olvidada","Cursed Ship","Snow Mountain"}) do
    addBtn(pages.Teleports, nm, function() TPTo(nm) end, no()) end
section(pages.Teleports, "FIRST SEA", no())
for _, nm in ipairs({"Skypiea","Skypiea Alta","Underwater City"}) do
    addBtn(pages.Teleports, nm, function() TPTo(nm) end, no()) end
section(pages.Teleports, "SCRIPTS", no())
addBtn(pages.Teleports, "Barco, Rosa (loadstring)", function()
    pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/azucarfake-ui/barco-rosa-/refs/heads/main/barco%20%2C%20rosa"))() end) end, no())

-- ===== UTILITY =====
n = 0
section(pages.Utility, "ESP", no())
addTgl(pages.Utility, "ESP Avanzado (+Ken/PVP)", {cb=function(s) ESPOn = s; if s then RefESP() else ClearESP() end end}, no())

section(pages.Utility, "ANTI-LAG", no())
addTgl(pages.Utility, "Anti-Lag Básico", {cb=function(s)
    if s then pcall(function()
        Lighting.GlobalShadows = false; Lighting.FogEnd = 9e8
        for _, v in pairs(game:GetDescendants()) do pcall(function()
            if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then v.Enabled = false
            elseif v:IsA("Atmosphere") or v:IsA("Clouds") then v:Destroy() end end) end
    end) end end}, no())
addTgl(pages.Utility, "Anti-Lag Avanzado", {cb=function(s)
    if s then pcall(function()
        for _, v in pairs(workspace:GetDescendants()) do 
            pcall(function() 
                if v:IsA("BasePart") then
                    v.Material = Enum.Material.SmoothPlastic
                    v.Reflectance = 0
                    v.CastShadow = false
                elseif v:IsA("Decal") or v:IsA("Texture") then 
                    v.Transparency = 1 
                end 
            end) 
        end
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
    end) end end}, no())

-- ANTI-LAG GRIS TOTAL (nuevo)
addTgl(pages.Utility, "Anti-Lag Gris Total (Mapa+Cielo)", {cb=function(s)
    if s then
        pcall(function()
            -- ColorCorrectionEffect → desaturar todo a gris
            local cc = Lighting:FindFirstChild("HE_GrayCC")
            if not cc then
                cc      = Instance.new("ColorCorrectionEffect", Lighting)
                cc.Name = "HE_GrayCC"
            end
            cc.Saturation = -1
            cc.Brightness = -0.05
            cc.Contrast   = 0.15

            -- Mover cielo fuera de Lighting (lo deshabilita)
            _G._HE_SkySave = _G._HE_SkySave or {}
            for _, sky in pairs(Lighting:GetChildren()) do
                if sky:IsA("Sky") then
                    sky.Parent = workspace
                    table.insert(_G._HE_SkySave, sky)
                end
            end

            -- Calidad mínima
            pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
            Lighting.GlobalShadows    = false
            Lighting.FogEnd           = 9e8
            Lighting.Ambient          = Color3.fromRGB(130, 130, 130)
            Lighting.OutdoorAmbient   = Color3.fromRGB(130, 130, 130)
            Lighting.Brightness       = 2

            -- Eliminar partículas, humo, fuego, atmosphere, clouds
            for _, v in pairs(game:GetDescendants()) do pcall(function()
                if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
                    v.Enabled = false
                elseif v:IsA("Atmosphere") or v:IsA("Clouds") then
                    v:Destroy()
                end end)
            end
        end)
    else
        pcall(function()
            local cc = Lighting:FindFirstChild("HE_GrayCC"); if cc then cc:Destroy() end
            -- Restaurar cielo
            if _G._HE_SkySave then
                for _, sky in pairs(_G._HE_SkySave) do
                    pcall(function() sky.Parent = Lighting end)
                end
                _G._HE_SkySave = {}
            end
        end)
    end end}, no())

addBtn(pages.Utility, "Remove Fog",     function() pcall(function() Lighting.FogEnd = 1e9 end) end, no())
addBtn(pages.Utility, "Remove Sounds",  function()
    for _, s in pairs(game:GetDescendants()) do if s:IsA("Sound") then pcall(function() s:Stop(); s.Volume = 0 end) end end end, no())
addBtn(pages.Utility, "Remove Touch Interest", function()
    for _, d in pairs(game:GetDescendants()) do if d:IsA("TouchTransmitter") then pcall(function() d:Destroy() end) end end end, no())
addSlider(pages.Utility, {name="Camera Max Zoom", min=0, max=5000, default=400, cb=function(v) lp.CameraMaxZoomDistance = v end}, no())
addSlider(pages.Utility, {name="FPS Cap", min=30, max=240, default=60, cb=function(v) pcall(function() setfpscap(v) end) end}, no())

-- ===== SETTINGS =====
n = 0
section(pages.Settings, "BANDO", no())
addBtn(pages.Settings, "Ser Pirata",  function() pcall(function() if CommF_ then CommF_:InvokeServer("SetTeam","Pirates") end end) end, no())
addBtn(pages.Settings, "Ser Marine",  function() pcall(function() if CommF_ then CommF_:InvokeServer("SetTeam","Marines") end end) end, no())
section(pages.Settings, "RACE", no())
addBtn(pages.Settings, "Race Changer", function(lb, f)
    lb.Text = "Rerolling..."; f.BackgroundColor3 = Color3.fromRGB(255,170,0)
    task.spawn(function()
        pcall(function()
            local remotes = RPS:FindFirstChild("Remotes")
            local commF   = remotes and remotes:FindFirstChild("CommF")
            if not commF then commF = RPS:FindFirstChild("CommF_", true) end
            if commF then
                commF:InvokeServer("BlackbeardReward","Reroll","1")
                commF:InvokeServer("BlackbeardReward","Reroll","2")
                commF:InvokeServer("BlackbeardReward","Reroll")
                commF:InvokeServer("Reroll","1")
                commF:InvokeServer("Reroll","2")
            end
        end)
        task.wait(0.7)
        lb.Text = "Race Changer"; f.BackgroundColor3 = C.card
    end)
end, no())

----------------------------------------------------------------
-- RUNTIME LOOPS
----------------------------------------------------------------

-- Speed, Jump, Noclip
pcall(function() RS.Stepped:Connect(function() pcall(function()
    local c = lp.Character; if not c then return end
    local h = c:FindFirstChildOfClass("Humanoid"); if not h then return end
    if _WSOn    then h.WalkSpeed = _WS end
    if _JOn     then h.UseJumpPower = true; h.JumpPower = _JV; h.JumpHeight = _JV end
    if _Noclip  then for _, v in pairs(c:GetDescendants()) do if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then v.CanCollide = false end end end
end) end) end)

-- Lógica de Ataque Instantánea ligada a RenderStepped (ULTRA FAST)
pcall(function()
    RS.RenderStepped:Connect(function()
        if not DGunOn then return end
        
        local char = lp.Character
        local tool = char and char:FindFirstChildOfClass("Tool")
        
        if tool and (tool.ToolTip == "Gun" or tool.Name:lower():find("gun")) then
            local target = ClosestGT()
            if target then
                -- Bucle de ráfaga interna por frame
                for i = 1, DG_Burst do
                    local code, count = NextVal()
                    if code ~= 0 and Valid2 then 
                        Valid2:FireServer(code, count) 
                    end
                    
                    tool:SetAttribute("LocalOverheat", 0)
                    tool:SetAttribute("LocalTotalShots", (tool:GetAttribute("LocalTotalShots") or 0) + 1)
                    
                    if ShootGunEv then
                        ShootGunEv:FireServer(target.Position, { target })
                    end
                end
            end
        end
    end)
end)

-- Magnet NPCs (150m rango -> TP 20m abajo)
pcall(function() task.spawn(function() while task.wait(0.05) do
    if MagnetManualOn and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        pcall(function()
            local myPos = lp.Character.HumanoidRootPart.Position
            local ef    = workspace:FindFirstChild("Enemies")
            if ef then
                for _, np in pairs(ef:GetChildren()) do pcall(function()
                    local hr = np:FindFirstChild("HumanoidRootPart")
                    local hm = np:FindFirstChild("Humanoid")
                    if hr and hm and hm.Health > 0 and (hr.Position - myPos).Magnitude <= 150 then
                        local hd = np:FindFirstChild("Head")
                        -- TP instantáneo 20m abajo
                        local tp = myPos - Vector3.new(0, 20, 0)
                        hr.CFrame = CFrame.new(tp)
                        hr.CanCollide = false
                        if hd then hd.CanCollide = false end
                    end end) end
            end
        end)
    end
end end) end)

-- Auto Safe Health (Bypass Servidor)
local function TeleportToCursedShipSafe()
    local char = lp.Character; if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp  = char.HumanoidRootPart
    pcall(function() CommF_:InvokeServer("requestEntrance", Vector3.new(923.212, 126.976, 32852.832)) end)
    task.wait(0.2)
    if (hrp.Position - Vector3.new(923.212, 126.976, 32852.832)).Magnitude > 150 then
        pcall(function() hrp.CFrame = CFrame.new(Vector3.new(923.212, 126.976, 32852.832)) end)
    end
end
pcall(function() task.spawn(function() while task.wait(0.2) do
    if AutoSafeHealth and not IsTeleportingToSafety then pcall(function()
        local char = lp.Character
        if char and char:FindFirstChild("Humanoid") then
            local hum = char.Humanoid
            if hum.Health > 0 and (hum.Health/hum.MaxHealth) <= 0.40 then
                IsTeleportingToSafety = true
                TeleportToCursedShipSafe()
                task.wait(5)
                IsTeleportingToSafety = false
            end
        end
    end) end
end end) end)

-- H KEY TRACKER
pcall(function() UIS.InputBegan:Connect(function(i, g)
    if g then return end
    if i.KeyCode == Enum.KeyCode.H and TrackerOn then
        if TrackerTarget then TrackerTarget = nil; if TrackerConn then TrackerConn:Disconnect(); TrackerConn = nil end; return end
        pcall(function()
            local mh = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart"); if not mh then return end
            local bestP, bestDot = nil, -1
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= lp and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local dir = (p.Character.HumanoidRootPart.Position - Cam.CFrame.Position).Unit
                    local dot = Cam.CFrame.LookVector:Dot(dir)
                    if dot > bestDot then bestDot = dot; bestP = p end
                end
            end
            if bestP and bestDot > 0.7 then
                TrackerTarget = bestP
                if TrackerConn then TrackerConn:Disconnect() end
                TrackerConn = RS.Heartbeat:Connect(function()
                    if not TrackerTarget then if TrackerConn then TrackerConn:Disconnect(); TrackerConn = nil end; return end
                    pcall(function()
                        if not TrackerTarget.Character or not TrackerTarget.Character:FindFirstChild("HumanoidRootPart") then return end
                        local mhr = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                        local thr = TrackerTarget.Character.HumanoidRootPart
                        if not mhr then return end
                        local dist = (mhr.Position - thr.Position).Magnitude
                        if dist > 650 then
                            local dir     = (thr.Position - mhr.Position).Unit
                            local tPos    = mhr.Position + dir * math.min(dist - 640, 200)
                            mhr.CFrame    = CFrame.new(tPos)
                        else
                            for _, v in pairs(lp.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
                            -- Copiar velocidad y suavizar la posición (fly suave)
                            mhr.Velocity = thr.Velocity
                            local targetCF = thr.CFrame * CFrame.new(0, 60, 15)
                            mhr.CFrame = mhr.CFrame:Lerp(targetCF, 0.4)
                        end
                    end)
                end)
            end
        end)
    end
end) end)


-- NOTIFICACIÓN EN PANTALLA (Auto Farm)
local farmNotifLabel = nil
pcall(function()
    local nf = Instance.new("TextLabel", sg)
    nf.Name = "FarmNotif"; nf.BackgroundColor3 = Color3.fromRGB(15,15,20); nf.BackgroundTransparency = 0.3
    nf.BorderSizePixel = 0; nf.AnchorPoint = Vector2.new(0.5, 0)
    nf.Position = UDim2.new(0.5, 0, 0, 8); nf.Size = UDim2.new(0, 320, 0, 24)
    nf.TextSize = 11; nf.TextColor3 = C.white; nf.Font = Enum.Font.Code
    nf.TextStrokeTransparency = 0.3; nf.Text = ""; nf.Visible = false; nf.ZIndex = 10
    Instance.new("UICorner", nf).CornerRadius = UDim.new(0, 6)
    local ns = Instance.new("UIStroke", nf); ns.Color = C.accent; ns.Thickness = 1
    farmNotifLabel = nf
end)

local lastFarmNotifText = ""
local function farmNotif(txt)
    if txt == lastFarmNotifText then return end
    lastFarmNotifText = txt
    pcall(function()
        if farmNotifLabel then
            farmNotifLabel.Text = txt; farmNotifLabel.Visible = (txt ~= "")
        end
    end)
end

-- AUTO FARM PLAYERS
local lastIslandTP = 0
local flySpeed = 180
local farmCurrentPlayerName = ""

-- Helper: detectar la isla de las 3 permitidas más cercana a una posición
local function getNearestIsland(pos)
    local bestIsland = nil
    local bestDist = math.huge
    local allowedIslands = {"Reino de Rosa", "Cursed Ship", "Graveyard"}
    
    for _, name in ipairs(allowedIslands) do
        local coords = Islands[name]
        if coords then
            local dist = (pos - coords).Magnitude
            if dist < bestDist then
                bestDist = dist
                bestIsland = name
            end
        end
    end
    -- Si la isla permitida más cercana está a más de 3000m, volar directo
    if bestDist > 3000 then return nil end
    return bestIsland
end

-- Helper: buscar TODOS los jugadores con PVP ON (sin límite de distancia, sin filtros falsos)
local function findAllPvPTargets(hrp)
    local targets = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= lp then
            pcall(function()
                local ch = p.Character
                if not ch then return end
                local thum = ch:FindFirstChildOfClass("Humanoid")
                local thrp = ch:FindFirstChild("HumanoidRootPart")
                if not thum or thum.Health <= 0 or not thrp then return end
                -- Solo filtrar: PVP activo y NO en zona segura
                if AX_ReadPvPState(p) and not AX_InSafeZone(p) then
                    table.insert(targets, {player = p, hrp = thrp, dist = (hrp.Position - thrp.Position).Magnitude})
                end
            end)
        end
    end
    table.sort(targets, function(a,b) return a.dist < b.dist end)
    return targets
end

RS.Heartbeat:Connect(function(dt)
    if AutoFarmPlayersOn or TpToSelectedOn then
        pcall(function()
            local char = lp.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
            for _, v in pairs(char:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
            
            local myHum = char:FindFirstChildOfClass("Humanoid")
            if myHum then
                local hpPct = myHum.Health / math.max(myHum.MaxHealth, 1)
                if hpPct <= 0.4 then
                    _G.FleeingToShip = true
                elseif hpPct >= 0.8 then
                    _G.FleeingToShip = false
                end
                
                if _G.FleeingToShip then
                    farmNotif("⚠️ VIDA BAJA! Escapando a Barco...")
                    task.spawn(function() TPTo("Cursed Ship") end)
                    return -- Ignore auto farm logic until we heal
                end
            end
            
            local targets = {}
            if TpToSelectedOn and targetPlayerName ~= "" then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p.DisplayName == targetPlayerName and p.Character then
                        local thrp = p.Character:FindFirstChild("HumanoidRootPart")
                        local thum = p.Character:FindFirstChildOfClass("Humanoid")
                        if thrp and thum and thum.Health > 0 then
                            table.insert(targets, {player = p, hrp = thrp, dist = (hrp.Position - thrp.Position).Magnitude})
                        end
                    end
                end
            elseif AutoFarmPlayersOn then
                targets = findAllPvPTargets(hrp)
            else
                return -- None are active or valid
            end
            
            if #targets > 0 then
                local best = targets[1]

                local bestTarget = best.hrp
                local bestPlayer = best.player
                local distToTarget = best.dist
                
                local newName = bestPlayer.DisplayName
                if newName ~= farmCurrentPlayerName then
                    farmCurrentPlayerName = newName
                    farmNotif("⚔ Atacando: "..newName.." ["..math.floor(distToTarget).."m]")
                    _G.LastFarmTargetPos = nil
                    _G.WaitFarmTime = nil
                end
                
                local currentTargetPos = bestTarget.Position
                local shouldTweenToOldPos = false
                
                if _G.LastFarmTargetPos then
                    local targetDistDiff = (_G.LastFarmTargetPos - currentTargetPos).Magnitude
                    if targetDistDiff > 1000 then
                        -- El objetivo se teletransportó muy lejos
                        if not _G.WaitFarmTime then 
                            _G.WaitFarmTime = tick()
                        end
                        
                        if tick() - _G.WaitFarmTime < 2 then
                            shouldTweenToOldPos = true
                            farmNotif("⚠️ "..newName.." huyó! Buscando en última pos...")
                        else
                            -- Pasaron 2 segundos, lo soltamos
                            _G.LastFarmTargetPos = currentTargetPos
                            _G.WaitFarmTime = nil
                        end
                    else
                        _G.LastFarmTargetPos = currentTargetPos
                        _G.WaitFarmTime = nil
                    end
                else
                    _G.LastFarmTargetPos = currentTargetPos
                end
                
                local actualTargetCFrame = shouldTweenToOldPos and CFrame.new(_G.LastFarmTargetPos) or bestTarget.CFrame
                local hoverPos = actualTargetCFrame * CFrame.new(0, 70, 0)
                
                -- Smart TP Global: busca la isla de las 3 permitidas más cercana al objetivo
                if distToTarget > 2000 and tick() - lastIslandTP > 3 then
                    local myIsland = getNearestIsland(hrp.Position)
                    local targetIsland = getNearestIsland(bestTarget.Position)
                    
                    if targetIsland and targetIsland ~= myIsland then
                        lastIslandTP = tick()
                        farmNotif("🚀 TP → "..targetIsland.." (siguiendo a "..newName..")")
                        task.spawn(function() TPTo(targetIsland) end)
                        return
                    elseif myIsland == "Cursed Ship" and not targetIsland then
                        lastIslandTP = tick()
                        farmNotif("🚀 Saliendo de Barco → Reino de Rosa")
                        task.spawn(function() TPTo("Reino de Rosa") end)
                        return
                    end
                end

                if distToTarget > 150 then
                    local dir = (hoverPos.Position - hrp.Position).Unit
                    local step = dir * (flySpeed * dt)
                    hrp.CFrame = CFrame.new(hrp.Position + step, Vector3.new(hoverPos.Position.X, hrp.Position.Y, hoverPos.Position.Z))
                    hrp.Velocity = Vector3.zero
                    -- Actualizar distancia en notificación cada cierto tiempo
                    if math.floor(distToTarget) % 50 < 2 then
                        farmNotif("⚔ Volando → "..newName.." ["..math.floor(distToTarget).."m]")
                    end
                else
                    hrp.CFrame = hoverPos
                    hrp.Velocity = Vector3.zero
                    farmNotif("⚔ Encima de "..newName.." — Atacando!")
                end
            else
                farmCurrentPlayerName = ""
                -- No hay targets → si estamos en barco, salir a rosa
                local myIsland = getNearestIsland(hrp.Position)
                if myIsland == "Cursed Ship" then
                    if tick() - lastIslandTP > 5 then
                        lastIslandTP = tick()
                        farmNotif("🔄 Sin targets en Barco → TP a Reino de Rosa")
                        task.spawn(function() TPTo("Reino de Rosa") end)
                    end
                else
                    if tick() - lastIslandTP > 5 then
                        lastIslandTP = tick()
                        farmNotif("🔍 Buscando jugadores PVP ON...")
                        TPTo("Reino de Rosa")
                    end
                end
            end
        end)
    else
        if farmNotifLabel and farmNotifLabel.Visible then
            farmNotif("")
            farmCurrentPlayerName = ""
        end
    end
end)

-- Spectate loop
RS.RenderStepped:Connect(function()
    if SpectateOn and targetPlayerName ~= "" then
        pcall(function()
            for _, p in ipairs(Players:GetPlayers()) do
                if p.DisplayName == targetPlayerName and p.Character then
                    local hum = p.Character:FindFirstChildOfClass("Humanoid")
                    if hum then
                        workspace.CurrentCamera.CameraSubject = hum
                    end
                end
            end
        end)
    end
end)

-- ESP refresh
pcall(function() task.spawn(function() while true do task.wait(3); if ESPOn then RefESP() end end end) end)
pcall(function() Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function() if ESPOn then task.wait(0.3); MkESP(p) end end) end) end)

-- CharacterAdded
pcall(function() lp.CharacterAdded:Connect(function(c) task.wait(0.5) pcall(function()
    local h = c:FindFirstChildOfClass("Humanoid")
    if h and _JOn  then h.UseJumpPower = true; h.JumpPower = _JV end
    if h and _WSOn then h.WalkSpeed = _WS end
    if flyOn then stopFly(); startFly() end
end) end) end)

-- Anti AFK
pcall(function() lp.Idled:Connect(function()
    pcall(function() local vu = game:GetService("VirtualUser"); vu:CaptureController(); vu:ClickButton2(Vector2.new(0,0)) end) end) end)

----------------------------------------------------------------
-- KEYBINDS GLOBALES (K, P, X, Z, C)
----------------------------------------------------------------
UIS.InputBegan:Connect(function(i, g)
    if g then return end
    if i.KeyCode == Enum.KeyCode.K then
        sg.Enabled = not sg.Enabled
    elseif i.KeyCode == Enum.KeyCode.P then
        if flyOn then stopFly() else startFly() end
    elseif i.KeyCode == Enum.KeyCode.X then
        TPTo("Reino de Rosa")
    elseif i.KeyCode == Enum.KeyCode.Z then
        TPTo("Cursed Ship")
    elseif i.KeyCode == Enum.KeyCode.C then
        TPTo("Graveyard")
    end
end)
