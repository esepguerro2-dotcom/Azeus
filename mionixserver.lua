-- ==========================================
--         MIONIX ZBOUNTY v2.0
--    WindUI | Auto Bounty | ESP | PVP
-- ==========================================

repeat task.wait(0.1) until game:IsLoaded() and game:GetService("Players").LocalPlayer

local HttpService       = game:GetService("HttpService")
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace         = game:GetService("Workspace")
local Lighting          = game:GetService("Lighting")
local Stats             = game:GetService("Stats")
local LocalPlayer       = Players.LocalPlayer
local Camera            = workspace.CurrentCamera

local Modules       = ReplicatedStorage:WaitForChild("Modules", 10)
local Net           = Modules and Modules:WaitForChild("Net", 10)
local RegisterAttack = Net and Net:WaitForChild("RE/RegisterAttack", 10)
local RegisterHit   = Net and Net:WaitForChild("RE/RegisterHit", 10)
local RemoteSeed    = Net and Net:FindFirstChild("seed")

-- ========================
-- ANTI DUPLICADO
-- ========================
if getgenv().MionixZbountyLoaded then
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Mionix Zbounty",
            Text  = "¡El script ya está en ejecución!",
            Duration = 3
        })
    end)
    return
end
getgenv().MionixZbountyLoaded = true

-- ========================
-- EXECUTOR CHECK
-- ========================
local executorName    = (identifyexecutor and identifyexecutor()) or "Unknown"
local lowerExec       = string.lower(executorName)
local unsupported     = {"xeno", "solara"}
local isUnsupported   = false
for _, n in ipairs(unsupported) do
    if string.find(lowerExec, n) then isUnsupported = true; break end
end
local isMissingFuncs = (hookmetamethod == nil) or (getrawmetatable == nil) or (setreadonly == nil)
local disableHook    = isUnsupported or isMissingFuncs

if disableHook then
    warn("[Mionix] Executor limitado (" .. executorName .. "). Silent Aim hooks desactivados.")
    task.spawn(function()
        task.wait(5)
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title    = "⚠️ Executor limitado",
                Text     = "Silent Aim desactivado (" .. executorName .. "). Demás funciones cargadas.",
                Duration = 10
            })
        end)
    end)
end

-- ========================
-- WIND UI
-- ========================
local WindUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
))()

local Window = WindUI:CreateWindow({
    Title         = "Mionix Zbounty",
    Icon          = "badge-dollar-sign",
    Author        = "Mionix",
    Folder        = "MionixZbounty",
    Size          = UDim2.fromOffset(700, 820),
    Transparent   = true,
    Theme         = "Dark",
    Acrylic       = false,
    HideSearchBar = false,
    SideBarWidth  = 200,
    User = {
        Enabled   = true,
        Anonymous = false,
    },
    OpenButton = {
        Title           = "Mionix Zbounty",
        CornerRadius    = UDim.new(1, 0),
        StrokeThickness = 3,
        Enabled         = true,
        OnlyMobile      = false,
        Draggable       = true,
        OnlyIcon        = false,
        Color           = ColorSequence.new(Color3.fromHex("#FF2A2A"), Color3.fromHex("#800000")),
    }
})

if not Window then
    warn("[Mionix] CreateWindow falló")
    return
end

Window:OnDestroy(function()
    getgenv().MionixZbountyLoaded = nil
end)

-- ========================
-- GLOBALS
-- ========================
_G.ServerRegion      = "Singapore"
_G.HopMinPlayers     = 6
_G.HopMaxPlayers     = 7
_G.HopMinBounty      = 3000000
_G.HopMaxBounty      = math.huge
_G.SelectTeam        = "Pirates"

-- Toggles INDIVIDUALES de ataque
_G.M1Normal          = false
_G.M1Dos             = false
_G.AttackDistance    = 500
_G.FastAttackSpeed   = 0.05

_G.FruitsM1Enable    = false
_G.FruitsM1DelayValue = 0.05

_G.ESP_Master        = true
_G.ESP_ShowName      = true
_G.ESP_ShowHealth    = true
_G.ESP_ShowDistance  = true
_G.ESP_TeamColor     = true
_G.ESP_ShowLevel     = true
_G.ESP_ShowPVPStatus = true
_G.ESP_ShowTracers   = false
_G.ESP_TracerColor   = Color3.fromRGB(255, 255, 255)
_G.ESP_HighlightColor = Color3.fromRGB(30, 30, 30)
_G.ESP_FontSize      = 12
local Tracers        = {}

_G.AutoEnablePVP     = true
_G.ServerHopEnabled  = false
_G.HopNoTargetDelay  = 30
_G.AutoBusoEnabled   = true
_G.AutoV3_Enabled    = true
_G.AutoV4_Enabled    = true
_G.AutoKenEnabled    = true
_G.AutoSoru          = false
local AutoSoruConn   = nil
local LastSoruTime   = 0
local SORU_COOLDOWN  = 10
local MAX_SORU_DISTANCE = 900

_G.Hitbox_Enabled       = false
_G.Hitbox_Size          = 1
_G.Hitbox_Transparency  = 0.5

_G.AutoFlee          = true
_G.AutoFleeHP        = 30
_G.AutoFleeConn      = nil

_G.RemoveAnim        = true
_G.RemoveAnimCharConn  = nil
_G.RemoveAnimTrackConn = nil

_G.WaterWalkEnabled  = true
_G.RemoveLavaEnabled = true
local lavaRemoved    = false
_G.RemoveGhostShipLavaEnabled = true
local ghostShipLavaRemoved    = false

_G.FTP2_Enabled            = false
_G.FTP2_FlightConn         = nil
_G.FTP2_PlayerLeaveConn    = nil
_G.FTP2_Attachment         = nil
_G.FTP2_LinearVelocity     = nil
_G.FTP2_AntiGravity        = nil
_G.FTP2_LastTeleportTicks  = {}
_G.FTP2_TeleportPauseUntil = 0
_G.FTP2_TeleportFails      = {}
_G.FTP2_BlockedEntrances   = {}
_G.FTP2_Blacklist          = {}
_G.FTP2_HasTriggeredHop    = false
_G.FTP2_TimeoutLimit       = 120
_G.FTP2_HistoryWindow      = 0.35
_G.FTP2_ClearTimeout       = 10
_G.FTP2_FlySpeed           = 195
_G.FTP2_HeightOffset       = 30
_G.FTP2_OrbitRadius        = 50
_G.FTP2_OrbitInterval      = 0.016
_G.FTP2_LowHpLockPercent   = 30
_G.FTP2_NoTeleportRange    = 300
_G.FTP2_CurrentTarget      = nil
_G.FTP2_TargetLockTime     = 0
_G.TargetHistory            = {}
_G.FTP2_StartTime          = 0
_G.FTP2_FleeReturnPos      = nil

-- Filtro de bounty para targets (default: sin filtro para no perder targets)
_G.FTP2_TargetBountyMin    = 0         -- 0 = sin límite mínimo
_G.FTP2_TargetBountyMax    = math.huge -- sin límite máximo (configurable en UI)

_G.FTP2_SafeZonePositions = {
    World1 = {
        { pos = Vector3.new(-3000, 250, 2057),  radius = 700 },
        { pos = Vector3.new(1101, 16, 1446),    radius = 400 },
    },
    World2 = {
        { pos = Vector3.new(-12, 29, 2840),     radius = 200 },
        { pos = Vector3.new(-376, 149, 307),    radius = 150 },
        { pos = Vector3.new(-6437, 306, -4730), radius = 150 },
    },
    World3 = {
        { pos = Vector3.new(-338, 21, 5539),     radius = 200 },
        { pos = Vector3.new(-12550, 337, -7506), radius = 400 },
        { pos = Vector3.new(-5046, 315, -2993),  radius = 300 },
        { pos = Vector3.new(-16228, 9, 443),     radius = 300 },
        { pos = Vector3.new(28695, 14959, -81),  radius = 10000 },
        { pos = Vector3.new(9637, -1989, 9618),  radius = 10000 },
    }
}

_G.SilentAimEnabled    = true
_G.SilentAimTargetMode = "Jugador objetivo actualmente bloqueado"
_G.SilentAimTeamCheck  = true
local currentSilentAimTarget    = nil
local currentSilentAimTargetPos = nil

_G.CamlockEnabled = false

_G.AutoSkillMainEnable = false
_G.AutoSkillWeapons = {
    ["Melee"]      = { Enable=false, Skills={ Z={Enable=false,HoldTime=0}, X={Enable=false,HoldTime=0}, C={Enable=false,HoldTime=0} } },
    ["Blox Fruit"] = { Enable=false, Skills={ Z={Enable=false,HoldTime=0}, X={Enable=false,HoldTime=0}, C={Enable=false,HoldTime=0}, V={Enable=false,HoldTime=0}, F={Enable=false,HoldTime=0} } },
    ["Gun"]        = { Enable=false, Skills={ Z={Enable=false,HoldTime=0}, X={Enable=false,HoldTime=0} } },
    ["Sword"]      = { Enable=false, Skills={ Z={Enable=false,HoldTime=0}, X={Enable=false,HoldTime=0} } },
}
local SkillKeyMap = { Z=Enum.KeyCode.Z, X=Enum.KeyCode.X, C=Enum.KeyCode.C, V=Enum.KeyCode.V, F=Enum.KeyCode.F }
local SkillCoolDownTrack = {}

_G.UnlockFPS        = true
_G.LowVisualMode    = false
_G.LowVisualConnection = nil
_G.RemoveFogEnabled = true
_G.AntiAFK_ENABLED  = true
_G.AntiAFK_Connection = nil
_G.AutoRejoinEnabled = true
_G.AutoExecute      = true
_G.AutoHideEnabled  = false
_G.CurrentKey       = "G"
_G.KeyDisabled      = false
_G.Theme            = "Dark"

local FilterParagraph = nil

-- ========================
-- CONFIG JSON
-- ========================
local ConfigFolder = "MionixZbounty_Config"
local ConfigFile   = ConfigFolder .. "/settings_" .. tostring(LocalPlayer.UserId) .. ".json"
local ConfigReady  = false
local ConfigSaving = false
local ConfigDirty  = false

local ConfigKeys = {
    "ServerRegion","HopMinPlayers","HopMaxPlayers","HopMinBounty","HopMaxBounty","SelectTeam",
    "M1Normal","M1Dos","AttackDistance","FastAttackSpeed","FruitsM1Enable","FruitsM1DelayValue",
    "ESP_Master","ESP_ShowName","ESP_ShowHealth","ESP_ShowDistance","ESP_ShowTracers","ESP_TeamColor","ESP_ShowLevel","ESP_ShowPVPStatus","ESP_FontSize",
    "AutoEnablePVP","ServerHopEnabled","HopNoTargetDelay","AutoBusoEnabled","AutoV3_Enabled","AutoV4_Enabled","AutoKenEnabled","AutoSoru",
    "Hitbox_Enabled","Hitbox_Size","Hitbox_Transparency",
    "AutoFlee","AutoFleeHP","RemoveAnim","WaterWalkEnabled","RemoveLavaEnabled","RemoveGhostShipLavaEnabled",
    "FTP2_Enabled","FTP2_FlySpeed","FTP2_HeightOffset","FTP2_OrbitRadius","FTP2_OrbitInterval",
    "FTP2_LowHpLockPercent","FTP2_NoTeleportRange","FTP2_TimeoutLimit","FTP2_HistoryWindow","FTP2_ClearTimeout",
    "FTP2_TargetBountyMin","FTP2_TargetBountyMax",
    "SilentAimEnabled","SilentAimTargetMode","SilentAimTeamCheck","CamlockEnabled",
    "AutoSkillMainEnable","AutoSkillWeapons",
    "UnlockFPS","LowVisualMode","RemoveFogEnabled","AntiAFK_ENABLED","AutoRejoinEnabled","AutoExecute",
    "Theme","AutoHideEnabled","CurrentKey","KeyDisabled",
}

local function CopyConfigValue(v)
    if type(v) ~= "table" then return v end
    local c = {}
    for k, i in pairs(v) do c[k] = CopyConfigValue(i) end
    return c
end

local function CollectConfig()
    local d = {}
    for _, k in ipairs(ConfigKeys) do
        if _G[k] ~= nil then d[k] = CopyConfigValue(_G[k]) end
    end
    return d
end

local function ApplyConfig(data)
    if type(data) ~= "table" then return end
    for _, k in ipairs(ConfigKeys) do
        if data[k] ~= nil then _G[k] = CopyConfigValue(data[k]) end
    end
end

local function SaveConfig(force)
    if ConfigSaving or (not force and not ConfigDirty) or typeof(writefile) ~= "function" then return false end
    ConfigSaving = true
    local ok = pcall(function()
        if typeof(isfolder) == "function" and typeof(makefolder) == "function" and not isfolder(ConfigFolder) then
            makefolder(ConfigFolder)
        end
        writefile(ConfigFile, HttpService:JSONEncode(CollectConfig()))
    end)
    ConfigSaving = false
    if ok then ConfigDirty = false end
    return ok
end

local function LoadConfig()
    if typeof(readfile) ~= "function" or typeof(isfile) ~= "function" or not isfile(ConfigFile) then return false end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(ConfigFile)) end)
    if ok and type(data) == "table" then ApplyConfig(data); return true end
    return false
end

local function MarkConfigDirty() ConfigDirty = true end

local InitialConfig = CollectConfig()
LoadConfig()
WindUI:SetTheme(_G.Theme or "Dark")
ConfigReady = true

task.spawn(function()
    while task.wait(3) do
        if ConfigReady and ConfigDirty then SaveConfig(true) end
    end
end)

-- ========================
-- SELECT TEAM
-- ========================
local function SelectTeam()
    local lp = Players.LocalPlayer
    if not lp.Team or lp.Team.Name ~= _G.SelectTeam then
        pcall(function()
            ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer("SetTeam2", _G.SelectTeam)
        end)
    end
end
SelectTeam()

-- ========================
-- UTILIDADES
-- ========================
local RegionValues = { "Oregon","Florida","Texas","California","HongKong","Germany","Brazil","Singapore" }

local function FormatNumber(n)
    local str = tostring(math.floor(tonumber(n) or 0))
    local k
    while true do str, k = string.gsub(str, "^(-?%d+)(%d%d%d)", "%1,%2"); if k==0 then break end end
    return str
end

local function BuildFilterText()
    local minB = tonumber(_G.HopMinBounty) or 3000000
    local maxB = _G.HopMaxBounty
    local bountyStr = (maxB == math.huge or not maxB)
        and string.format("≥ %s", FormatNumber(minB))
        or  string.format("%s ~ %s", FormatNumber(minB), FormatNumber(maxB))
    return string.format("🌐 Región｜%s\n👥 Jugadores｜%d ~ %d\n💰 Bounty｜%s",
        tostring(_G.ServerRegion),
        tonumber(_G.HopMinPlayers) or 6,
        tonumber(_G.HopMaxPlayers) or 7,
        bountyStr)
end

local function SetParagraphDesc(p, text)
    if not p then return end
    if p.SetDesc then p:SetDesc(text)
    elseif p.Set then p:Set({ Desc = text })
    elseif p.SetTitle then p:SetTitle(p.Title or "Filtro actual", text) end
end

local function RefreshFilterParagraph()
    SetParagraphDesc(FilterParagraph, BuildFilterText())
end

-- ========================
-- FORWARD DECLARATIONS
-- ========================
local GetCombatStatus
local IsInCombatState
local StartServerHop
local StopServerHop
local IsSafeToHopCheck

-- ========================
-- SERVER HOP
-- ========================
local function ParseServerInfo(text)
    if type(text) ~= "string" or text == "" then return nil end
    local region = text:match("Region:%s*(.-)%s*%-%s*Players:") or text:match("Region:%s*(.-)%s*$")
    local cur, max = text:match("Players:%s*(%d+)%s*/%s*(%d+)")
    local bTxt    = text:match("Bounty:%s*([%d,]+)")
    if not cur or not max or not bTxt then return nil end
    local bounty = tonumber((bTxt:gsub(",", "")))
    if not bounty then return nil end
    return { Region=region or "Unknown", Players=tonumber(cur), MaxPlayers=tonumber(max), Bounty=bounty }
end

local function IsServerAllowed(info)
    if not info then return false end
    local minP = tonumber(_G.HopMinPlayers) or 6
    local maxP = tonumber(_G.HopMaxPlayers) or 7
    local minB = tonumber(_G.HopMinBounty) or 3000000
    local maxB = tonumber(_G.HopMaxBounty) or math.huge
    if info.Players < minP or info.Players > maxP then return false end
    if (tonumber(info.MaxPlayers) or 0) > 0 and info.Players >= info.MaxPlayers then return false end
    if info.Bounty < minB or info.Bounty > maxB then return false end
    if _G.ServerRegion and _G.ServerRegion ~= "" then
        if not tostring(info.Region):lower():find(tostring(_G.ServerRegion):lower(), 1, true) then return false end
    end
    return true
end

StopServerHop = function()
    getgenv().IsServerHopping = false
    getgenv().ShuttingDown    = false
    if getgenv().ServerHopHiddenGui then
        getgenv().ServerHopHiddenGui = nil
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        local sb = pg and pg:FindFirstChild("ServerBrowser")
        if sb then
            pcall(function() sb.Enabled = false end)
            pcall(function() if sb:FindFirstChild("Frame") then sb.Frame.Visible = true end end)
        end
    end
end

StartServerHop = function()
    if getgenv().IsServerHopping == true then return end
    getgenv().IsServerHopping = true
    getgenv().ShuttingDown    = true
    local hopStart = tick()

    task.spawn(function()
        while getgenv().IsServerHopping do
            if tick() - hopStart >= 180 then
                local pid = game.PlaceId
                if table.find({7449423635, 100117331123089}, pid) then
                    pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("TravelDressrosa") end)
                elseif table.find({4442272183, 79091703265657}, pid) then
                    pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("TravelZou") end)
                else
                    pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer) end)
                end
                getgenv().IsServerHopping = false; return
            end
            task.wait(5)
        end
    end)

    if IsSafeToHopCheck and not IsSafeToHopCheck() then
        while getgenv().IsServerHopping and not IsSafeToHopCheck() do task.wait(1) end
        if not getgenv().IsServerHopping then return end
    end
    task.wait(3)

    local curJob = game.JobId
    local tried  = {}
    local SBR    = ReplicatedStorage:FindFirstChild("__ServerBrowser")
    local direct = nil

    if SBR then
        for _, method in ipairs({"getServers","fetchServers","getServerList","fetch","servers","searchServers"}) do
            local ok, result = pcall(function() return SBR:InvokeServer(method) end)
            if ok and type(result) == "table" then
                local arr = result.Servers or result.ServerList or result.Data or result
                if type(arr) == "table" then
                    local parsed = {}
                    for _, s in ipairs(arr) do
                        if type(s) == "table" then
                            local jid = s.JobId or s.Job or s.id or s.teleportData
                            if type(jid) == "string" and tostring(jid):find("-",1,true) then
                                table.insert(parsed, {
                                    JobId      = tostring(jid),
                                    Region     = tostring(s.Region or s.RegionName or s.region or ""),
                                    Players    = tonumber(s.Players or s.PlayerCount or s.CurrentPlayers or s.currentPlayers) or 0,
                                    MaxPlayers = tonumber(s.MaxPlayers or s.MaximumPlayers or s.maxPlayers) or 0,
                                    Bounty     = tonumber(s.Bounty or s.ServerBounty or s.bounty) or 0,
                                })
                            end
                        end
                    end
                    if #parsed > 0 then direct = parsed; break end
                end
            end
        end
    end

    local useGui = false
    local Inside = nil

    if not direct then
        local pg = LocalPlayer:WaitForChild("PlayerGui")
        local sb = pg:FindFirstChild("ServerBrowser")
        if not sb then getgenv().IsServerHopping = false; return end
        useGui = true
        getgenv().ServerHopHiddenGui = true
        pcall(function() if sb:FindFirstChild("Frame") then sb.Frame.Visible = false end end)
        sb.Enabled = true
        local Filters = sb.Frame and sb.Frame:FindFirstChild("Filters")
        local SR      = Filters and Filters:FindFirstChild("SearchRegion")
        local TB      = SR and SR:FindFirstChild("TextBox")
        if TB then TB.Text = _G.ServerRegion end
        local SF = sb.Frame and sb.Frame:FindFirstChild("ScrollingFrame")
        local FS = sb.Frame and sb.Frame:FindFirstChild("FakeScroll")
        Inside   = FS and FS:FindFirstChild("Inside")
        task.spawn(function()
            while getgenv().IsServerHopping do
                if SF then SF.CanvasPosition = Vector2.new(0, math.random(100, 7000)) end
                task.wait(0.3)
            end
        end)
    end

    task.wait(0.5)
    task.spawn(function()
        while getgenv().IsServerHopping do
            local candidate = nil
            if direct then
                for _, s in ipairs(direct) do
                    if s.JobId ~= curJob and not tried[s.JobId] then
                        if IsServerAllowed({Region=s.Region,Players=s.Players,MaxPlayers=s.MaxPlayers,Bounty=s.Bounty}) then
                            candidate = { job=s.JobId }; break
                        end
                    end
                end
            elseif useGui and Inside then
                for _, tmpl in ipairs(Inside:GetChildren()) do
                    if tmpl.Name == "Template" then
                        local btn  = tmpl:FindFirstChild("Join")
                        local lbl  = tmpl:FindFirstChild("TextLabel")
                        local info = lbl and ParseServerInfo(lbl.Text)
                        if btn and info and IsServerAllowed(info) then
                            local job = btn:GetAttribute("Job")
                            if job and tostring(job):find("-",1,true) then
                                job = tostring(job)
                                if job ~= curJob and not tried[job] then
                                    candidate = { job=job }; break
                                end
                            end
                        end
                    end
                end
            end
            if candidate and getgenv().IsServerHopping and IsSafeToHopCheck() then
                pcall(function() if SBR then SBR:InvokeServer("teleport", candidate.job) end end)
                tried[candidate.job] = true
            end
            task.wait(5)
        end
    end)
end

-- ========================
-- FAST ATTACK
-- ========================
local FAState = {
    FoundRemote=nil, FoundRemoteId=nil,
    consecutiveFailures=0, maxConsecutiveFailures=5,
    M1_Remotes=nil, M1_Net=nil, M1_RegisterAttack=nil, M1_RegisterHit=nil, M1_Enemies=nil
}

local function IsAlive(char)
    if not char then return false end
    local h = char:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end

local function GetRandomValidPart(target)
    if not target then return nil end
    local hrp = target:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local parts = {target:FindFirstChild("Head"),target:FindFirstChild("UpperTorso"),target:FindFirstChild("LowerTorso"),target:FindFirstChild("Torso"),hrp}
    local valid = {}
    for _, p in ipairs(parts) do if p and p:IsA("BasePart") then table.insert(valid,p) end end
    return #valid > 0 and valid[math.random(1,#valid)] or hrp
end

task.spawn(function()
    local folders = {ReplicatedStorage:FindFirstChild("Util"),ReplicatedStorage:FindFirstChild("Common"),ReplicatedStorage:FindFirstChild("Remotes"),ReplicatedStorage:FindFirstChild("Assets"),ReplicatedStorage:FindFirstChild("FX")}
    local function checkChild(child)
        if child:IsA("RemoteEvent") and child:GetAttribute("Id") then
            FAState.FoundRemoteId = child:GetAttribute("Id")
            FAState.FoundRemote   = child
        end
    end
    for _, folder in ipairs(folders) do
        if folder then
            for _, child in ipairs(folder:GetChildren()) do checkChild(child) end
            folder.ChildAdded:Connect(checkChild)
        end
    end
end)

local function M1_CheckAndGetCoreComponents()
    if FAState.M1_Remotes and FAState.M1_Net and FAState.M1_RegisterAttack and FAState.M1_RegisterHit and FAState.M1_Enemies then
        return FAState.M1_Remotes, FAState.M1_Net, FAState.M1_RegisterAttack, FAState.M1_RegisterHit, FAState.M1_Enemies
    end
    local Rem  = ReplicatedStorage:FindFirstChild("Remotes")
    local Mod  = ReplicatedStorage:FindFirstChild("Modules")
    local NetI = Mod and Mod:FindFirstChild("Net")
    local RegA = NetI and (NetI:FindFirstChild("RE/RegisterAttack") or NetI:FindFirstChild("RegisterAttack"))
    local RegH = NetI and (NetI:FindFirstChild("RE/RegisterHit") or NetI:FindFirstChild("RegisterHit"))
    local Enem = workspace:FindFirstChild("Enemies") or workspace:FindFirstChild("NPCs")
    if Rem and Mod and NetI and RegA and RegH and Enem then
        FAState.M1_Remotes=Rem; FAState.M1_Net=NetI; FAState.M1_RegisterAttack=RegA; FAState.M1_RegisterHit=RegH; FAState.M1_Enemies=Enem
        return Rem, NetI, RegA, RegH, Enem
    end
    return nil,nil,nil,nil,nil
end

local function PerformAttackMode1()
    local char    = LocalPlayer.Character
    local Equipped = char and IsAlive(char) and char:FindFirstChildOfClass("Tool")
    if not Equipped or Equipped.ToolTip == "Gun" then return end
    local OthersEnemies = {}
    local _, _, regA, regH, EF = M1_CheckAndGetCoreComponents()
    local myPos = char and char.PrimaryPart and char.PrimaryPart.Position
    if myPos then
        if EF then
            for _, Enemy in ipairs(EF:GetChildren()) do
                if Enemy == char or not IsAlive(Enemy) then continue end
                local er = Enemy:FindFirstChild("HumanoidRootPart")
                if er and (er.Position - myPos).Magnitude < _G.AttackDistance then
                    local fp = GetRandomValidPart(Enemy)
                    if fp then table.insert(OthersEnemies, {Enemy, fp}) end
                end
            end
        end
        for _, op in ipairs(Players:GetPlayers()) do
            if op == LocalPlayer then continue end
            local oc = op.Character
            if not IsAlive(oc) then continue end
            local er = oc and oc:FindFirstChild("HumanoidRootPart")
            if er and (er.Position - myPos).Magnitude < _G.AttackDistance then
                local fp = GetRandomValidPart(oc)
                if fp then table.insert(OthersEnemies, {oc, fp}) end
            end
        end
    end
    if #OthersEnemies > 0 and regA and regH then
        local ok = pcall(function() regA:FireServer(0.3); regH:FireServer(OthersEnemies[1][2], OthersEnemies) end)
        if not ok then FAState.M1_RegisterAttack=nil; FAState.M1_RegisterHit=nil end
    end
end

local function GetMode2Targets()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return {} end
    local targets = {}
    local myPos   = root.Position
    local folders = {workspace:FindFirstChild("Enemies"),workspace:FindFirstChild("NPCs"),workspace:FindFirstChild("Characters")}
    local function checkModel(model)
        if not model or model == char then return end
        local tRoot = model:FindFirstChild("HumanoidRootPart")
        local tHum  = model:FindFirstChild("Humanoid")
        if tRoot and tHum and tHum.Health > 0 and (tRoot.Position - myPos).Magnitude <= _G.AttackDistance then
            table.insert(targets, {Model=model, Root=tRoot, Head=model:FindFirstChild("Head") or tRoot})
        end
    end
    for _, folder in ipairs(folders) do
        if folder then for _, m in ipairs(folder:GetChildren()) do if #targets >= 20 then break end; checkModel(m) end end
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if #targets >= 20 then break end
        if plr ~= LocalPlayer and plr.Character then checkModel(plr.Character) end
    end
    return targets
end

local function PerformAttackMode2()
    local char = LocalPlayer.Character
    if not char or not (char:FindFirstChildOfClass("Tool") or char:FindFirstChild("EquippedWeapon")) then return end
    local targets = GetMode2Targets()
    if #targets == 0 then return end
    local main    = targets[1]
    local hitList = {}
    for _, t in ipairs(targets) do table.insert(hitList, {t.Model, t.Root}) end
    RegisterAttack:FireServer(0)
    local fakeHash = tostring(LocalPlayer.UserId):sub(2,4) .. tostring(math.random(10000,99999))
    pcall(function() RegisterHit:FireServer(main.Head, hitList, {}, fakeHash) end)
    if FAState.FoundRemote and FAState.FoundRemoteId then
        pcall(function()
            local seed    = RemoteSeed and RemoteSeed:InvokeServer() or 1
            local encId   = bit32.bxor(FAState.FoundRemoteId + 909090, seed * 2)
            local rawName = "RE/RegisterHit"
            local ts      = math.floor(workspace:GetServerTimeNow() / 10 % 10) + 1
            local encName = string.gsub(rawName, ".", function(c) return string.char(bit32.bxor(string.byte(c), ts)) end)
            FAState.FoundRemote:FireServer(encName, encId, main.Head, hitList)
        end)
    end
end

local function PerformAttack()
    if _G.M1Normal then pcall(PerformAttackMode1) end
    if _G.M1Dos    then pcall(PerformAttackMode2) end
end

local manualConnection = nil
local function stopManual() if manualConnection then manualConnection:Disconnect(); manualConnection=nil end end
local function startManual()
    if manualConnection then return end
    manualConnection = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if _G.M1Normal or _G.M1Dos then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then pcall(PerformAttack) end
    end)
end
if not (_G.M1Normal or _G.M1Dos) then startManual() end
LocalPlayer.CharacterRemoving:Connect(stopManual)
LocalPlayer.CharacterAdded:Connect(function()
    if not (_G.M1Normal or _G.M1Dos) then startManual() end
end)

task.spawn(function()
    while true do
        local s = tick()
        if _G.M1Normal or _G.M1Dos then pcall(PerformAttack) end
        task.wait(math.max((_G.FastAttackSpeed or 0.05) - (tick()-s), 0.001))
    end
end)

-- ========================
-- FRUIT M1
-- ========================
local function GetFruitRemote()
    for _, loc in ipairs({LocalPlayer.Character, LocalPlayer:FindFirstChild("Backpack")}) do
        if loc then
            for _, tool in ipairs(loc:GetChildren()) do
                local remote = tool:IsA("Tool") and tool:FindFirstChild("LeftClickRemote", true)
                if remote then return remote, tool.Name end
            end
        end
    end
    return nil, "No es fruta M1"
end

task.spawn(function()
    while true do
        if _G.FruitsM1Enable then
            local char   = LocalPlayer.Character
            local hrp    = char and char:FindFirstChild("HumanoidRootPart")
            local remote = GetFruitRemote()
            if hrp and remote then remote:FireServer(-hrp.CFrame.UpVector, 2, true) end
        end
        task.wait(_G.FruitsM1DelayValue)
    end
end)

-- ========================
-- CHECK PVP
-- ========================
local function CheckPVP(plr)
    -- En Blox Fruit: PvpDisabled=true significa PVP OFF, nil/false significa PVP ON
    local pvpDisabled = plr:GetAttribute("PvpDisabled")

    -- Explícitamente desactivado
    if pvpDisabled == true then return false end

    -- En combate activo = PVP implícito
    if plr:GetAttribute("InCombat") == true then return true end
    if plr:GetAttribute("CombatPd") == true then return true end

    -- Buscar atributos relacionados
    local attrs = plr:GetAttributes()
    for name, value in pairs(attrs) do
        local lower = string.lower(name)
        -- PvpEnabled=true → PVP activo
        if string.find(lower, "pvpenabled") then
            if value == true then return true end
            if value == false then return false end
        end
        -- PvpDisabled=true → PVP desactivado
        if string.find(lower, "pvpdisabled") or string.find(lower, "pvp_disabled") then
            if value == true then return false end
        end
    end

    -- leaderstats fallback
    local ls = plr:FindFirstChild("leaderstats")
    if ls then
        local pvpStat = ls:FindFirstChild("PVP")
        if pvpStat then
            local v = pvpStat.Value
            if v == "Disabled" or v == false or v == "OFF" or v == "off" then return false end
            if v == "Enabled" or v == true  or v == "ON"  or v == "on"  then return true end
        end
    end

    -- Si no hay atributo PvpDisabled → asumimos PVP ACTIVO (comportamiento por defecto en BF)
    return pvpDisabled ~= true
end

-- ========================
-- BOUNTY DEL TARGET
-- ========================
local function GetPlayerBounty(plr)
    -- Buscar en múltiples lugares donde Blox Fruit guarda el bounty
    local data = plr:FindFirstChild("Data")
    if data then
        local b = data:FindFirstChild("Bounty") or data:FindFirstChild("bounty")
            or data:FindFirstChild("BountyPoints") or data:FindFirstChild("Honor")
        if b then return tonumber(b.Value) or 0 end
    end
    local ls = plr:FindFirstChild("leaderstats")
    if ls then
        local b = ls:FindFirstChild("Bounty") or ls:FindFirstChild("bounty")
            or ls:FindFirstChild("BountyPoints") or ls:FindFirstChild("Honor")
        if b then return tonumber(b.Value) or 0 end
    end
    -- Atributos directos
    local attr = plr:GetAttribute("Bounty") or plr:GetAttribute("bounty")
        or plr:GetAttribute("BountyPoints") or plr:GetAttribute("Honor")
    if attr then return tonumber(attr) or 0 end
    -- Si no encontramos nada, asumir que tiene suficiente bounty (no bloquear)
    return -1
end

local function IsInBountyRange(plr)
    local b    = GetPlayerBounty(plr)
    -- Si no se pudo leer el bounty (-1), dejamos pasar al jugador
    if b == -1 then return true end
    local minB = _G.FTP2_TargetBountyMin or 0        -- default 0 = sin límite mínimo
    local maxB = _G.FTP2_TargetBountyMax or math.huge -- default sin límite máximo
    return b >= minB and b <= maxB
end

-- ========================
-- ESP
-- ========================
local function removeTracer(p)
    if Tracers[p] then Tracers[p].Visible=false; Tracers[p]:Remove(); Tracers[p]=nil end
end

local function removeESP(p)
    removeTracer(p)
    if p.Character then
        local h = p.Character:FindFirstChild("ESP_Highlight")
        if h then h:Destroy() end
        local head = p.Character:FindFirstChild("Head")
        if head then local b = head:FindFirstChild("ESP_Billboard"); if b then b:Destroy() end end
    end
end

local function createESP(p)
    if p == LocalPlayer or not _G.ESP_Master then return end
    local char = p.Character; if not char then return end
    local head = char:FindFirstChild("Head"); if not head then return end

    if not char:FindFirstChild("ESP_Highlight") then
        local h = Instance.new("Highlight")
        h.Name = "ESP_Highlight"
        h.FillColor = _G.ESP_HighlightColor
        h.OutlineColor = Color3.fromRGB(255,255,255)
        h.FillTransparency = 0.55
        h.OutlineTransparency = 0.1
        h.Adornee = char
        h.Parent  = char
    end

    if not head:FindFirstChild("ESP_Billboard") then
        local bill = Instance.new("BillboardGui")
        bill.Name = "ESP_Billboard"
        bill.AlwaysOnTop = true
        bill.Size = UDim2.new(0,200,0,110)
        bill.StudsOffset = Vector3.new(0,4.5,0)
        bill.Adornee = head
        bill.Parent  = head

        local text = Instance.new("TextLabel", bill)
        text.Name = "InfoLabel"
        text.Size = UDim2.new(1,0,0,80)
        text.BackgroundTransparency = 1
        text.TextStrokeTransparency = 0.1
        text.TextStrokeColor3 = Color3.fromRGB(0,0,0)
        text.Font = Enum.Font.GothamBold
        text.TextSize = _G.ESP_FontSize
        text.TextColor3 = Color3.fromRGB(255,255,255)
        text.RichText = true
        text.TextYAlignment = Enum.TextYAlignment.Bottom

        local barBG = Instance.new("Frame", bill)
        barBG.Name = "HealthBarBG"
        barBG.Size = UDim2.new(0,110,0,5)
        barBG.Position = UDim2.new(0.5,-55,0,90)
        barBG.BackgroundColor3 = Color3.fromRGB(25,25,25)
        barBG.BorderSizePixel = 0
        barBG.Visible = false
        Instance.new("UICorner", barBG).CornerRadius = UDim.new(1,0)

        local barFG = Instance.new("Frame", barBG)
        barFG.Name = "HealthBarFG"
        barFG.Size = UDim2.new(1,0,1,0)
        barFG.BackgroundColor3 = Color3.fromRGB(0,255,130)
        barFG.BorderSizePixel = 0
        Instance.new("UICorner", barFG).CornerRadius = UDim.new(1,0)
    end
end

local function updateTracer(p, targetHRP)
    if not _G.ESP_ShowTracers or not _G.ESP_Master then removeTracer(p); return end
    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if myHRP and targetHRP then
        local cam = workspace.CurrentCamera
        local startPos, startEv = cam:WorldToViewportPoint(myHRP.Position)
        local endPos, ev        = cam:WorldToViewportPoint(targetHRP.Position)
        if ev and startEv then
            local tr = Tracers[p] or Drawing.new("Line")
            Tracers[p] = tr
            tr.Visible = true
            tr.From = Vector2.new(startPos.X, startPos.Y)
            tr.To   = Vector2.new(endPos.X, endPos.Y)
            tr.Color = (_G.ESP_TeamColor and p.TeamColor) and p.TeamColor.Color or _G.ESP_TracerColor
            tr.Thickness = 1.8
            tr.Transparency = 0.75
        else removeTracer(p) end
    else removeTracer(p) end
end

RunService.RenderStepped:Connect(function()
    if not _G.ESP_Master then return end
    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        local char = p.Character
        if not char then removeESP(p); continue end
        local head = char:FindFirstChild("Head")
        local hrp2 = char:FindFirstChild("HumanoidRootPart")
        local hum2 = char:FindFirstChildOfClass("Humanoid")
        if not (head and hrp2 and hum2) then removeESP(p); continue end
        createESP(p)
        if _G.ESP_ShowTracers then updateTracer(p, hrp2) else removeTracer(p) end

        local bill = head:FindFirstChild("ESP_Billboard")
        local h    = char:FindFirstChild("ESP_Highlight")
        if not (bill and h) then continue end

        if _G.ESP_TeamColor and p.TeamColor then h.OutlineColor = p.TeamColor.Color
        else h.OutlineColor = Color3.fromRGB(255,255,255) end

        local info  = bill:FindFirstChild("InfoLabel")
        local barBG = bill:FindFirstChild("HealthBarBG")
        local barFG = barBG and barBG:FindFirstChild("HealthBarFG")

        if info then
            local display = ""
            if _G.ESP_ShowName then display = display .. "<b>" .. p.Name .. "</b>\n" end
            if _G.ESP_ShowLevel then
                local lv = "???"
                local data = p:FindFirstChild("Data") or p:FindFirstChild("leaderstats")
                if data and data:FindFirstChild("Level") then lv = data.Level.Value end
                display = display .. '<font color="#FFFFFF">Lv. ' .. tostring(lv) .. '</font>\n'
            end
            if _G.ESP_ShowPVPStatus then
                if CheckPVP(p) then
                    display = display .. '<font color="#00FF88">[ PVP: ON ]</font>\n'
                else
                    display = display .. '<font color="#FF4D4D">[ PVP: OFF ]</font>\n'
                end
            end
            local hpText, distText = "", ""
            if _G.ESP_ShowHealth then
                hpText = '<font color="#FFFFFF">HP: '..math.floor(hum2.Health).."/"..math.floor(hum2.MaxHealth)..'</font> '
            end
            if _G.ESP_ShowDistance and myHRP then
                distText = '<font color="#FFFFFF">['..math.floor((myHRP.Position - hrp2.Position).Magnitude)..'m]</font>'
            end
            if _G.ESP_ShowHealth or _G.ESP_ShowDistance then display = display .. hpText .. distText .. "\n" end
            info.Text = display
            info.TextSize = _G.ESP_FontSize
        end
        if barBG and barFG then
            if _G.ESP_ShowHealth then
                barBG.Visible = true
                local pct = math.clamp(hum2.Health / hum2.MaxHealth, 0, 1)
                barFG.Size = UDim2.fromScale(pct, 1)
                barFG.BackgroundColor3 = pct > 0.5
                    and Color3.fromRGB(255*(1-pct)*2, 255, 50)
                    or  Color3.fromRGB(255, 255*pct*2, 50)
            else barBG.Visible = false end
        end
    end
end)

local PlayerCharConns = {}
Players.PlayerRemoving:Connect(function(p) removeESP(p); if PlayerCharConns[p] then PlayerCharConns[p]:Disconnect(); PlayerCharConns[p]=nil end end)
Players.PlayerAdded:Connect(function(p)
    if PlayerCharConns[p] then PlayerCharConns[p]:Disconnect() end
    PlayerCharConns[p] = p.CharacterAdded:Connect(function() task.wait(0.5); if _G.ESP_Master then createESP(p) end end)
end)

-- ========================
-- AUTO PVP
-- ========================
local function GetCommF()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    return remotes and remotes:FindFirstChild("CommF_")
end

task.spawn(function()
    while true do
        if _G.AutoEnablePVP and not getgenv().IsServerHopping then
            local remote = GetCommF()
            if remote then pcall(function() remote:InvokeServer("EnablePvp") end) end
        end
        task.wait(1)
    end
end)

-- ========================
-- AUTO BUSO
-- ========================
task.spawn(function()
    while task.wait(1) do
        if _G.AutoBusoEnabled then
            local plr = LocalPlayer
            if plr and plr.Character and not plr.Character:FindFirstChild("HasBuso") then
                pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso") end)
            end
        end
    end
end)

-- ========================
-- AUTO V3
-- ========================
local function toggleV3()
    if UserInputService:GetFocusedTextBox() then return end
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.T, false, game)
    task.wait(1)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.T, false, game)
end
task.spawn(function()
    while task.wait(0.5) do
        if _G.AutoV3_Enabled then toggleV3(); task.wait(1) end
    end
end)

-- ========================
-- AUTO V4
-- ========================
local function GetAwakeningRemote()
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local aw = bp and bp:FindFirstChild("Awakening")
    if aw and aw:FindFirstChild("RemoteFunction") then return aw.RemoteFunction end
    local ch = LocalPlayer.Character
    local ca = ch and ch:FindFirstChild("Awakening")
    if ca and ca:FindFirstChild("RemoteFunction") then return ca.RemoteFunction end
    return nil
end
task.spawn(function()
    while true do
        task.wait(0.1)
        if _G.AutoV4_Enabled then
            local remote = GetAwakeningRemote()
            if remote then task.spawn(function() pcall(function() remote:InvokeServer(true) end) end) end
        end
    end
end)

-- ========================
-- AUTO KEN
-- ========================
local function toggleKenVision()
    if UserInputService:GetFocusedTextBox() then return end
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end
task.spawn(function()
    while task.wait(0.1) do
        if not LocalPlayer or not LocalPlayer:IsDescendantOf(Players) then break end
        if not _G.AutoKenEnabled then continue end
        local kl = LocalPlayer:GetAttribute("KenDodgesLeft")
        local ka = LocalPlayer:GetAttribute("KenActive")
        if kl ~= nil then
            if not ka then toggleKenVision(); task.wait(0.5) end
        else
            toggleKenVision(); task.wait(2.0)
        end
    end
end)

-- ========================
-- AUTO SORU
-- ========================
local function SoruTo(targetPosition)
    local Character = LocalPlayer and LocalPlayer.Character
    if not Character then return false end
    local HRP = Character:FindFirstChild("HumanoidRootPart")
    local Hum = Character:FindFirstChild("Humanoid")
    if not HRP or not Hum or Hum.Health <= 0 then return false end
    local startCFrame = HRP.CFrame
    local finalCFrame = (startCFrame - startCFrame.Position) + targetPosition + Vector3.new(0, HRP.Size.Y * 1.5, 0)
    ReplicatedStorage.Remotes.CommE:FireServer("Soru", startCFrame, finalCFrame, workspace:GetServerTimeNow(), math.random(1,999999999))
    return true
end

local function GetClosestPlayerForSoru()
    local closest, shortest = nil, math.huge
    local char = LocalPlayer and LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil, math.huge end
    local myPos = char.HumanoidRootPart.Position
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local oc = plr.Character
            local oh = oc and oc:FindFirstChild("Humanoid")
            local or_ = oc and oc:FindFirstChild("HumanoidRootPart")
            if oh and or_ and oh.Health > 0 then
                local d = (or_.Position - myPos).Magnitude
                if d < shortest then shortest = d; closest = plr end
            end
        end
    end
    return closest, shortest
end

local function SoruToClosestPlayer()
    if tick() - LastSoruTime < SORU_COOLDOWN then return end
    local tp, dist = GetClosestPlayerForSoru()
    if not tp or dist > MAX_SORU_DISTANCE then return end
    local tc = tp.Character
    if tc and tc:FindFirstChild("HumanoidRootPart") then
        local pos = (tc.HumanoidRootPart.CFrame * CFrame.new(0,0,3)).Position
        if SoruTo(pos) then
            LastSoruTime = tick()
            WindUI:Notify({ Title="Auto Soru", Content=string.format("Activado: %s (%dm)", tp.Name, math.floor(dist)), Duration=3, Icon="zap" })
        end
    end
end

local function StartAutoSoru()
    if AutoSoruConn then return end
    AutoSoruConn = task.spawn(function()
        while _G.AutoSoru do pcall(SoruToClosestPlayer); task.wait(1) end
        AutoSoruConn = nil
    end)
end
local function StopAutoSoru()
    if AutoSoruConn then task.cancel(AutoSoruConn); AutoSoruConn = nil end
end
if _G.AutoSoru then StartAutoSoru() end

-- ========================
-- HITBOX
-- ========================
local function applyHitboxToPlayer(plr)
    if plr == LocalPlayer or not plr.Character then return end
    local r = plr.Character:FindFirstChild("HumanoidRootPart")
    if r and r:IsA("BasePart") then
        r.CanCollide = false
        if _G.Hitbox_Enabled then
            r.Size = Vector3.new(_G.Hitbox_Size, _G.Hitbox_Size, _G.Hitbox_Size)
            r.Transparency = _G.Hitbox_Transparency
        else
            r.Size = Vector3.new(2, 2, 1)
            r.Transparency = 0
        end
    end
end
local function applyHitboxAll() for _, plr in pairs(Players:GetPlayers()) do applyHitboxToPlayer(plr) end end
local function setupPlayerHitbox(plr)
    if plr == LocalPlayer then return end
    plr.CharacterAdded:Connect(function() task.wait(0.5); applyHitboxToPlayer(plr) end)
    if plr.Character then applyHitboxToPlayer(plr) end
end
for _, plr in pairs(Players:GetPlayers()) do setupPlayerHitbox(plr) end
Players.PlayerAdded:Connect(setupPlayerHitbox)
Players.PlayerRemoving:Connect(function() task.defer(applyHitboxAll) end)
local hitboxTick = 0
RunService.Heartbeat:Connect(function()
    if not _G.Hitbox_Enabled then return end
    hitboxTick = hitboxTick + 1
    if hitboxTick % 30 ~= 0 then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then applyHitboxToPlayer(plr) end
    end
end)

-- ========================
-- AUTO FLEE
-- ========================
local function SetCharNoclip(char, enabled)
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = not enabled end
    end
end

local function StartAutoFlee()
    if _G.AutoFleeConn then return end
    _G.AutoFleeConn = task.spawn(function()
        local wasFleeing = false
        local fleeAtt, fleeLV, fleeAG = nil, nil, nil

        local function SetupFleeComponents(hrp)
            if fleeLV then fleeLV:Destroy(); fleeLV=nil end
            if fleeAG then fleeAG:Destroy(); fleeAG=nil end
            if fleeAtt then fleeAtt:Destroy(); fleeAtt=nil end
            local att = Instance.new("Attachment"); att.Name="AutoFlee_Attachment"; att.Parent=hrp; fleeAtt=att
            local lv  = Instance.new("LinearVelocity"); lv.Name="AutoFlee_LinearVelocity"; lv.MaxForce=math.huge
            lv.VelocityConstraintMode=Enum.VelocityConstraintMode.Vector; lv.VectorVelocity=Vector3.new(0,0,0)
            lv.Attachment0=att; lv.Parent=hrp; fleeLV=lv
            local totalMass = 0
            if hrp.Parent then
                for _, part in ipairs(hrp.Parent:GetDescendants()) do
                    if part:IsA("BasePart") and not part.Massless then totalMass = totalMass + part:GetMass() end
                end
            end
            local vf = Instance.new("VectorForce"); vf.Name="AutoFlee_AntiGravity"; vf.ApplyAtCenterOfMass=true
            vf.Attachment0=att; vf.Force=Vector3.new(0, totalMass*workspace.Gravity, 0); vf.Parent=hrp; fleeAG=vf
        end

        local function ClearFleeComponents()
            if fleeLV then fleeLV:Destroy(); fleeLV=nil end
            if fleeAG then fleeAG:Destroy(); fleeAG=nil end
            if fleeAtt then fleeAtt:Destroy(); fleeAtt=nil end
        end

        while _G.AutoFlee do
            task.wait(0.05)
            pcall(function()
                if _G.FTP2_Enabled then
                    if wasFleeing then wasFleeing=false; ClearFleeComponents(); SetCharNoclip(LocalPlayer.Character, false) end
                    return
                end
                local char = LocalPlayer.Character
                local hum  = char and char:FindFirstChildOfClass("Humanoid")
                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                if not hum or not hrp or hum.Health <= 0 then
                    if wasFleeing then wasFleeing=false; ClearFleeComponents(); SetCharNoclip(char, false) end
                    return
                end
                local hp = (hum.Health / hum.MaxHealth) * 100
                if hp <= _G.AutoFleeHP then
                    if not wasFleeing then wasFleeing=true; SetCharNoclip(char, true); SetupFleeComponents(hrp)
                    elseif not fleeLV or fleeLV.Parent ~= hrp then SetupFleeComponents(hrp) end
                    if fleeLV then fleeLV.VectorVelocity = Vector3.new(0, 195, 0) end
                elseif wasFleeing then
                    wasFleeing=false; ClearFleeComponents(); SetCharNoclip(char, false)
                end
            end)
        end
        pcall(function()
            if wasFleeing then SetCharNoclip(LocalPlayer.Character, false) end
            if fleeLV then fleeLV:Destroy() end
            if fleeAG then fleeAG:Destroy() end
            if fleeAtt then fleeAtt:Destroy() end
        end)
        _G.AutoFleeConn = nil
    end)
end
local function StopAutoFlee() _G.AutoFleeConn=nil; pcall(function() SetCharNoclip(LocalPlayer.Character, false) end) end
if _G.AutoFlee then StartAutoFlee() end

-- ========================
-- REMOVE ANIM
-- ========================
local function DisableAnimForChar(char)
    if not char then return end
    local hum = char:WaitForChild("Humanoid", 5); if not hum then return end
    local anim = hum:WaitForChild("Animator", 5); if not anim then return end
    for _, t in pairs(anim:GetPlayingAnimationTracks()) do t:Stop() end
    if _G.RemoveAnimTrackConn then _G.RemoveAnimTrackConn:Disconnect(); _G.RemoveAnimTrackConn=nil end
    _G.RemoveAnimTrackConn = anim.AnimationPlayed:Connect(function(t) if _G.RemoveAnim then t:Stop() end end)
end
local function StartRemoveAnim()
    if _G.RemoveAnimCharConn then return end
    if LocalPlayer and LocalPlayer.Character then DisableAnimForChar(LocalPlayer.Character) end
    _G.RemoveAnimCharConn = LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(0.5); if _G.RemoveAnim then DisableAnimForChar(char) end
    end)
end
local function StopRemoveAnim()
    if _G.RemoveAnimTrackConn then _G.RemoveAnimTrackConn:Disconnect(); _G.RemoveAnimTrackConn=nil end
    if _G.RemoveAnimCharConn then _G.RemoveAnimCharConn:Disconnect(); _G.RemoveAnimCharConn=nil end
end
if _G.RemoveAnim then StartRemoveAnim() end

-- ========================
-- WATER WALK
-- ========================
task.spawn(function()
    local lastSize = -1
    while task.wait(0.5) do
        local wp = Workspace.Map and Workspace.Map:FindFirstChild("WaterBase-Plane")
        if wp then
            local ts = _G.WaterWalkEnabled and 112 or 80
            if ts ~= lastSize then lastSize=ts; wp.Size=Vector3.new(1000,ts,1000) end
        end
    end
end)

-- ========================
-- REMOVE LAVA
-- ========================
local function removeLava()
    for _, v in pairs(Workspace:GetDescendants()) do
        if v.Name=="LavaParts" and v.Parent and v.Parent.Name=="CircleIsland" and v.Parent.Parent and v.Parent.Parent.Name=="Map" then v:Destroy() end
    end
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v.Name=="LavaParts" and v.Parent and v.Parent.Name=="CircleIsland" and v.Parent.Parent and v.Parent.Parent.Name=="Map" then v:Destroy() end
    end
end
task.spawn(function()
    while task.wait(0.5) do
        if _G.RemoveLavaEnabled and not lavaRemoved then
            lavaRemoved=true; removeLava()
            WindUI:Notify({Title="Lava eliminada", Content="Objetos de lava eliminados", Duration=3})
        elseif not _G.RemoveLavaEnabled then lavaRemoved=false end
    end
end)

local function removeGhostShipLava()
    if Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("GhostShipInterior") and Workspace.Map.GhostShipInterior:FindFirstChild("LavaParts") then
        local folder = Workspace.Map.GhostShipInterior.LavaParts
        local children = folder:GetChildren()
        for _, idx in ipairs({3,4,5,6,7,8,9,10,11,12,13}) do
            local p = children[idx]; if p then p:Destroy() end
        end
        local lava = folder:FindFirstChild("Lava"); if lava then lava:Destroy() end
    end
end
task.spawn(function()
    while task.wait(0.5) do
        if _G.RemoveGhostShipLavaEnabled and not ghostShipLavaRemoved then
            ghostShipLavaRemoved=true; removeGhostShipLava()
            WindUI:Notify({Title="Ghost Ship lava eliminada", Content="Daño del Barco Fantasma eliminado", Duration=3, Type="Success"})
        elseif not _G.RemoveGhostShipLavaEnabled then ghostShipLavaRemoved=false end
    end
end)

-- ========================
-- COMBAT STATE
-- ========================
GetCombatStatus = function()
    local mainUI     = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("Main")
    local bottomHUD  = mainUI and mainUI:FindFirstChild("BottomHUDList")
    local inCombatUI = bottomHUD and bottomHUD:FindFirstChild("InCombat")
    if inCombatUI and inCombatUI.Visible then
        local rawText = ""
        if inCombatUI:IsA("TextLabel") then rawText = inCombatUI.Text
        else
            local c = inCombatUI:FindFirstChildWhichIsA("TextLabel", true)
            if c then rawText = c.Text end
        end
        local low = string.lower(rawText)
        if string.find(low, "bounty at risk") or string.find(low, "honor at risk") then return "BountyAtRisk" end
        return "InCombatNoRisk"
    end
    return "NotInCombat"
end

local FTP2_CombatCache     = "NotInCombat"
local FTP2_CombatCacheTime = 0

IsInCombatState = function()
    local now = os.clock()
    if now - FTP2_CombatCacheTime >= 0.5 then
        FTP2_CombatCacheTime = now
        FTP2_CombatCache = GetCombatStatus()
    end
    return FTP2_CombatCache ~= "NotInCombat"
end

IsSafeToHopCheck = function()
    if not LocalPlayer or not LocalPlayer:IsDescendantOf(Players) then return false end
    local pg      = LocalPlayer:FindFirstChild("PlayerGui")
    local main    = pg and pg:FindFirstChild("Main")
    local hud     = main and main:FindFirstChild("BottomHUDList")
    local inCombat = hud and hud:FindFirstChild("InCombat")
    if inCombat then
        for _, child in ipairs(inCombat:GetDescendants()) do
            if child:IsA("TextLabel") then
                local txt = child.Text:lower()
                if (txt:find("no salgas") or txt:find("don't leave") or txt:find("bounty at risk") or txt:find("honor at risk"))
                and child.Visible and child.TextTransparency < 0.9 then
                    return false
                end
            end
        end
    end
    local status = GetCombatStatus()
    if status == "BountyAtRisk" or status == "InCombatNoRisk" then return false end
    return true
end

-- ========================
-- AUTO BOUNTY FARM — VALIDACIÓN
-- ========================
local function IsInSafeZone(plr)
    if not plr or not plr.Character then return false end
    local hrp = plr.Character:FindFirstChild("HumanoidRootPart"); if not hrp then return false end
    local placeId = game.PlaceId
    local zones = {}
    if table.find({2753915549, 85211729168715}, placeId) then zones = _G.FTP2_SafeZonePositions.World1
    elseif table.find({4442272183, 79091703265657}, placeId) then zones = _G.FTP2_SafeZonePositions.World2
    elseif table.find({7449423635, 100117331123089}, placeId) then zones = _G.FTP2_SafeZonePositions.World3 end
    local pos = hrp.Position
    for _, zone in ipairs(zones) do if (pos - zone.pos).Magnitude <= zone.radius then return true end end
    return false
end

local function GetLevel(plr)
    if not plr then return nil end
    local obj = (plr:FindFirstChild("Data") and plr.Data:FindFirstChild("Level"))
              or (plr:FindFirstChild("leaderstats") and plr.leaderstats:FindFirstChild("Level"))
    return obj and obj.Value or nil
end

local function IsPlayerAlly(player)
    if not player then return false end
    local main = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("Main")
    if not main then return false end
    local allies    = main:FindFirstChild("Allies")
    local container = allies and allies:FindFirstChild("Container")
    local subAllies = container and container:FindFirstChild("Allies")
    if not subAllies then return false end
    local frame = subAllies:FindFirstChild("Frame")
        or (subAllies:FindFirstChild("ScrollingFrame") and subAllies.ScrollingFrame:FindFirstChild("Frame"))
    if not frame then return false end
    return frame:FindFirstChild(player.Name) ~= nil
end

local function IsValidTarget(plr)
    if not plr or plr == LocalPlayer then return false end
    if _G.FTP2_Blacklist[plr] then return false end
    local char = plr.Character; if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return false end

    -- Blacklist permanente solo para cosas definitivas (raiding, forcefield)
    if plr:GetAttribute("IslandRaiding") == true then
        _G.FTP2_Blacklist[plr] = true; return false
    end
    if char:FindFirstChildOfClass("ForceField") then
        _G.FTP2_Blacklist[plr] = true; return false
    end

    -- Safe zone: temporal, NO blacklistear
    local combatLock = (plr == _G.FTP2_CurrentTarget) and IsInCombatState()
    if not combatLock then
        if plr:GetAttribute("SafeZone")==true or plr:GetAttribute("InSafeZone")==true then return false end
        if IsInSafeZone(plr) then return false end
    end

    -- PVP: temporal, NO blacklistear (puede activarse)
    if not CheckPVP(plr) then return false end

    -- Bounty del target: temporal (puede no haber cargado aún), NO blacklistear
    if not IsInBountyRange(plr) then return false end

    -- Equipo marine vs marine: blacklist permanente
    local mt = LocalPlayer.Team; local tt = plr.Team
    if mt and tt and mt.Name=="Marines" and tt.Name=="Marines" then
        _G.FTP2_Blacklist[plr] = true; return false
    end

    -- Aliado: blacklist permanente
    if IsPlayerAlly(plr) then
        _G.FTP2_Blacklist[plr] = true; return false
    end

    -- Nivel: temporal (puede no haber cargado), si falla simplemente pasar
    local myLv = GetLevel(LocalPlayer)
    local tgLv = GetLevel(plr)
    if myLv and tgLv then
        -- Aquí es donde está el bug principal: 550 niveles de diferencia es MUY restrictivo
        -- Si alguien tiene nivel 2500 y tú 2550, solo 50 de diferencia → OK
        -- Pero si tu nivel no cargó → antes lo bloqueaba permanentemente
        if math.abs(myLv - tgLv) > 550 then return false end  -- temporal, no blacklist
    end
    -- Si no se pudo obtener el nivel, igual intentamos atacar (es mejor que ignorar a todos)

    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if myHRP and (myHRP.Position - hrp.Position).Magnitude > 30000 then return false end

    return true
end

local ValidTargetCache     = {}
local ValidTargetCacheTime = 0
local function IsValidTargetFast(plr)
    local now = os.clock()
    -- Cache de 0.3s para no spammear IsValidTarget cada frame pero sin ser demasiado lento
    if now - ValidTargetCacheTime > 0.3 then ValidTargetCacheTime=now; table.clear(ValidTargetCache) end
    if ValidTargetCache[plr] ~= nil then return ValidTargetCache[plr] end
    local v = IsValidTarget(plr); ValidTargetCache[plr] = v; return v
end

local function IsTargetLowHP(plr)
    if not plr then return false end
    local char = plr.Character; local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 or hum.MaxHealth <= 0 then return false end
    return (hum.Health / hum.MaxHealth) * 100 < (_G.FTP2_LowHpLockPercent or 30)
end

-- ========================
-- PREDICCIÓN
-- ========================
-- Entradas de isla configurables desde la UI
_G.WorldEntrances = {
    World1 = {
        { Arg=Vector3.new(61163.85,11.68,1819.78),  Dest=Vector3.new(61164,5,1820),    Label="W1 - Portal 1" },
        { Arg=Vector3.new(3864.68,6.73,-1926.21),   Dest=Vector3.new(3865,5,-1926),    Label="W1 - Portal 2" },
        { Arg=Vector3.new(-4607.82,874.39,-1667.55),Dest=Vector3.new(-4608,873,-1668), Label="W1 - Portal 3" },
        { Arg=Vector3.new(-7894.61,5547.14,-380.29),Dest=Vector3.new(-7895,5546,-380), Label="W1 - Portal 4" },
    },
    World2 = {
        { Arg=Vector3.new(2285,15,882),    Dest=Vector3.new(2285,15,882),    Label="W2 - Portal 1" },
        { Arg=Vector3.new(-380,350,630),   Dest=Vector3.new(-380,350,630),   Label="W2 - Portal 2" },
        { Arg=Vector3.new(924,125,32882),  Dest=Vector3.new(924,125,32882),  Label="W2 - Portal 3" },
        { Arg=Vector3.new(-6491,116,-107), Dest=Vector3.new(-6491,116,-107), Label="W2 - Portal 4" },
    },
    World3 = {
        { Arg=Vector3.new(5678,1013,-312),   Dest=Vector3.new(5678,1013,-312),   Label="W3 - Portal 1" },
        { Arg=Vector3.new(-12551,337,-7507), Dest=Vector3.new(-12551,337,-7507), Label="W3 - Portal 2" },
        { Arg=Vector3.new(-5038,315,-3135),  Dest=Vector3.new(-5038,315,-3135),  Label="W3 - Portal 3" },
        { Arg=Vector3.new(-5098,317,-3179),  Dest=Vector3.new(-16813,58,305),    Label="W3 - Portal 4" },
    },
}

-- Cuáles portales están habilitados
_G.WorldEntrancesEnabled = {
    World1 = {true, true, true, true},
    World2 = {true, true, true, true},
    World3 = {true, true, true, true},
}

local function GetCurrentWorldEntrances()
    local pool    = {}
    local placeId = game.PlaceId
    local worldKey = nil
    if table.find({2753915549, 85211729168715}, placeId) then
        worldKey = "World1"
    elseif table.find({4442272183, 79091703265657}, placeId) then
        worldKey = "World2"
    elseif table.find({7449423635, 100117331123089}, placeId) then
        worldKey = "World3"
    end
    if not worldKey then return pool end
    local entries  = _G.WorldEntrances[worldKey] or {}
    local enabled  = _G.WorldEntrancesEnabled[worldKey] or {}
    for i, e in ipairs(entries) do
        if enabled[i] ~= false then
            table.insert(pool, { Arg=e.Arg, Dest=e.Dest })
        end
    end
    return pool
end

local function UpdatePositionHistory()
    local now = os.clock()
    local active = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            active[plr] = true
            local char = plr.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                if not _G.TargetHistory[plr] then _G.TargetHistory[plr] = {} end
                local h = _G.TargetHistory[plr]
                table.insert(h, {time=now, pos=hrp.Position, vel=hrp.AssemblyLinearVelocity})
                while #h > 0 and (now - h[1].time) > _G.FTP2_HistoryWindow do table.remove(h, 1) end
            end
        end
    end
    for plr, h in pairs(_G.TargetHistory) do
        if not active[plr] or not plr:IsDescendantOf(Players) then _G.TargetHistory[plr]=nil
        elseif #h==0 or (now - h[#h].time) > _G.FTP2_ClearTimeout then _G.TargetHistory[plr]=nil end
    end
end

local function GetPredictedPosition2(plr)
    if not plr or not plr.Character then return nil end
    local hrp = plr.Character:FindFirstChild("HumanoidRootPart"); if not hrp then return nil end
    local history    = _G.TargetHistory[plr]
    local currentPos = hrp.Position
    local currentVel = hrp.AssemblyLinearVelocity
    local ping       = 0.04
    pcall(function() ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000 end)
    if not history or #history < 3 then
        local t = math.clamp(ping, 0.03, 0.25)
        local pos = currentPos + (currentVel * t)
        if pos.Y < hrp.Position.Y then pos = Vector3.new(pos.X, hrp.Position.Y, pos.Z) end
        return pos
    end
    local count = #history
    local now   = os.clock()
    local totalWeight = 0; local weightedVel = Vector3.new(0,0,0)
    for i = 2, count do
        local prev = history[i-1]; local curr = history[i]
        local dt = curr.time - prev.time
        if dt > 0.001 then
            local instVel = (curr.pos - prev.pos) / dt
            local weight  = math.exp((curr.time - now) / 0.1)
            weightedVel   = weightedVel + (instVel * weight)
            totalWeight   = totalWeight + weight
        end
    end
    local historyVel = (totalWeight > 0) and (weightedVel / totalWeight) or currentVel
    local finalVel   = historyVel:Lerp(currentVel, 0.3)
    if finalVel.Magnitude > 195 then finalVel = finalVel.Unit * 195 end
    local oldest = history[1]; local mid = history[math.floor(count/2)]; local newest = history[count]
    local dt1 = mid.time - oldest.time; local dt2 = newest.time - mid.time
    local accel = Vector3.new(0,0,0)
    if dt1 > 0.005 and dt2 > 0.005 then
        local v1 = (mid.pos - oldest.pos) / dt1; local v2 = (newest.pos - mid.pos) / dt2
        accel = (v2 - v1) / ((dt1 + dt2) * 0.5)
    end
    if accel.Magnitude > 195 then accel = accel.Unit * 195 end
    local oldDir = (mid.pos - oldest.pos); local newDir = (newest.pos - mid.pos)
    if oldDir.Magnitude > 1 and newDir.Magnitude > 1 then
        accel = accel * math.clamp(oldDir.Unit:Dot(newDir.Unit), 0, 1)
    end
    local myHRP    = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local predTime = 0.15
    if myHRP then
        local dist   = (currentPos - myHRP.Position).Magnitude
        predTime = math.clamp((dist / _G.FTP2_FlySpeed * 0.55) + ping, 0.04, 0.45)
    end
    local predicted = currentPos + (finalVel * predTime) + (0.5 * accel * (predTime^2))
    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
    if hum and hum:GetState() == Enum.HumanoidStateType.Freefall then
        predicted = predicted - Vector3.new(0, 0.5*workspace.Gravity*(predTime^2), 0)
    end
    if predicted.Y < hrp.Position.Y then predicted = Vector3.new(predicted.X, hrp.Position.Y, predicted.Z) end
    return predicted
end

local function GetNearestPlayer()
    local nearest  = nil; local shortest = math.huge
    local myChar   = LocalPlayer.Character
    local myHRP    = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end
    for _, plr in ipairs(Players:GetPlayers()) do
        if IsValidTargetFast(plr) then
            local tgHRP = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
            if tgHRP then
                local dist = (tgHRP.Position - myHRP.Position).Magnitude
                if dist < shortest then shortest=dist; nearest=plr end
            end
        end
    end
    return nearest
end

-- ========================
-- VUELO
-- ========================
local function ClearFTP2FlightComponents()
    if _G.FTP2_LinearVelocity then _G.FTP2_LinearVelocity:Destroy(); _G.FTP2_LinearVelocity=nil end
    if _G.FTP2_AntiGravity    then _G.FTP2_AntiGravity:Destroy();    _G.FTP2_AntiGravity=nil end
    if _G.FTP2_Attachment     then _G.FTP2_Attachment:Destroy();     _G.FTP2_Attachment=nil end
end

local function SetupFTP2FlightComponents(hrp)
    ClearFTP2FlightComponents()
    local att = Instance.new("Attachment"); att.Name="XuHub_FlightAttachment2"; att.Parent=hrp; _G.FTP2_Attachment=att
    local lv  = Instance.new("LinearVelocity"); lv.Name="XuHub_FlightVelocity2"; lv.MaxForce=math.huge
    lv.VelocityConstraintMode=Enum.VelocityConstraintMode.Vector; lv.VectorVelocity=Vector3.new(0,0,0)
    lv.Attachment0=att; lv.Parent=hrp; _G.FTP2_LinearVelocity=lv
    local totalMass = 0
    if hrp.Parent then
        for _, part in ipairs(hrp.Parent:GetDescendants()) do
            if part:IsA("BasePart") and not part.Massless then totalMass = totalMass + part:GetMass() end
        end
    end
    local vf = Instance.new("VectorForce"); vf.Name="XuHub_AntiGravity2"; vf.ApplyAtCenterOfMass=true
    vf.Attachment0=att; vf.Force=Vector3.new(0,totalMass*workspace.Gravity,0); vf.Parent=hrp; _G.FTP2_AntiGravity=vf
end

local FTP2_OrbitOffset   = nil
local FTP2_NextOrbitTime = 0

local function FlyToTargetLogic2(plr)
    if not plr or not plr.Character then return end
    local myChar = LocalPlayer.Character
    local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local tgHRP  = plr.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP or not tgHRP then return end
    if os.clock() < _G.FTP2_TeleportPauseUntil then
        if _G.FTP2_LinearVelocity then _G.FTP2_LinearVelocity.VectorVelocity=Vector3.new(0,0,0) end
        myHRP.AssemblyLinearVelocity=Vector3.new(0,0,0); return
    end
    local rawTargetPos = GetPredictedPosition2(plr) or tgHRP.Position
    local now = os.clock()
    if not FTP2_OrbitOffset or now >= FTP2_NextOrbitTime then
        local maxR = _G.FTP2_OrbitRadius or 50
        local dist = math.random(1, maxR)
        local d    = Vector3.new(math.random()*2-1, math.random()*2-1, math.random()*2-1)
        if d.Magnitude > 0 then d = d.Unit end
        FTP2_OrbitOffset   = d * dist
        FTP2_NextOrbitTime = now + (_G.FTP2_OrbitInterval or 0.016)
    end
    local targetPos    = rawTargetPos + FTP2_OrbitOffset
    local dir          = targetPos - myHRP.Position
    local distToCenter = (rawTargetPos - myHRP.Position).Magnitude
    local bestEntrance = nil; local bestTotalTime = distToCenter / _G.FTP2_FlySpeed
    local pool = GetCurrentWorldEntrances()
    if distToCenter < (_G.FTP2_NoTeleportRange or 300) then pool = {} end
    for _, e in ipairs(pool) do
        if not _G.FTP2_BlockedEntrances[e.Arg] then
            local dDest = (e.Dest - rawTargetPos).Magnitude
            local tVia  = (dDest / _G.FTP2_FlySpeed) + 1.5
            if tVia < bestTotalTime and (distToCenter - dDest) > 150 then bestTotalTime=tVia; bestEntrance=e end
        end
    end
    if bestEntrance then
        local last = _G.FTP2_LastTeleportTicks[bestEntrance.Arg] or 0
        if os.clock() - last > 4 then
            _G.FTP2_LastTeleportTicks[bestEntrance.Arg] = os.clock()
            _G.FTP2_TeleportPauseUntil = os.clock() + 1.2
            local preDist = (myHRP.Position - bestEntrance.Dest).Magnitude
            if _G.FTP2_LinearVelocity then _G.FTP2_LinearVelocity.VectorVelocity=Vector3.new(0,0,0) end
            myHRP.AssemblyLinearVelocity=Vector3.new(0,0,0)
            task.spawn(function()
                pcall(function()
                    ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer("requestEntrance", bestEntrance.Arg)
                end)
            end)
            task.spawn(function()
                task.wait(1.5)
                local char = LocalPlayer.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local postDist = (hrp.Position - bestEntrance.Dest).Magnitude
                    if postDist > 150 and postDist >= preDist * 0.5 then
                        local fails = (_G.FTP2_TeleportFails[bestEntrance.Arg] or 0) + 1
                        _G.FTP2_TeleportFails[bestEntrance.Arg] = fails
                        if fails >= 3 then
                            _G.FTP2_BlockedEntrances[bestEntrance.Arg] = true
                            WindUI:Notify({Title="Auto Bounty", Content="Punto de teletransporte bloqueado tras 3 fallos", Duration=3})
                        end
                    end
                end
            end)
            return
        end
    end
    if not _G.FTP2_LinearVelocity or _G.FTP2_LinearVelocity.Parent ~= myHRP then SetupFTP2FlightComponents(myHRP) end
    _G.FTP2_LinearVelocity.VectorVelocity = dir.Unit * _G.FTP2_FlySpeed
    local lookAt = Vector3.new(rawTargetPos.X, myHRP.Position.Y, rawTargetPos.Z)
    if (lookAt - myHRP.Position).Magnitude > 0.1 then myHRP.CFrame = CFrame.new(myHRP.Position, lookAt) end
end

local function FleeUpLogic()
    pcall(function()
        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp or hum.Health <= 0 then return end
        SetCharNoclip(char, true)
        if not _G.FTP2_LinearVelocity or _G.FTP2_LinearVelocity.Parent ~= hrp then SetupFTP2FlightComponents(hrp) end
        _G.FTP2_LinearVelocity.VectorVelocity = Vector3.new(0, 195, 0)
    end)
end

local function ForceStandUp()
    local myChar = LocalPlayer.Character; if not myChar then return end
    local myHum  = myChar:FindFirstChildOfClass("Humanoid")
    local myHRP  = myChar:FindFirstChild("HumanoidRootPart")
    if not myHum or myHum.Health <= 0 then return end
    if myHum.Sit then
        myHum.Sit = false
        pcall(function() myHum.Jump = true end)
        pcall(function() myHum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        pcall(function() myHum:ChangeState(Enum.HumanoidStateType.Physics) end)
    end
    if myHRP then
        for _, child in ipairs(myHRP:GetChildren()) do
            if child:IsA("Weld") then pcall(function() child:Destroy() end)
            elseif child:IsA("Motor6D") then
                local n = string.lower(child.Name)
                if n:find("seat") or n:find("sit") or n:find("vehicle") then pcall(function() child:Destroy() end) end
            end
        end
    end
end

local FTP2_NoTargetSince    = 0
local FTP2_LastTargetSeen   = 0  -- última vez que vimos un target válido

local function CheckAndNotifyCombatStatus()
    if not _G.ServerHopEnabled then return end
    if _G.FTP2_HasTriggeredHop then return end

    -- Solo hacer hop si:
    -- 1. No estamos en combate
    -- 2. Han pasado al menos 30s desde que inició el farm
    -- 3. Han pasado HopNoTargetDelay segundos SIN VER ningún target válido
    local status = GetCombatStatus()
    if status ~= "NotInCombat" then
        -- En combate: resetear el timer, no hay que hacer hop
        FTP2_NoTargetSince = 0
        return
    end

    local now               = os.clock()
    local timeSinceStart    = now - _G.FTP2_StartTime
    local timeSinceNoTarget = FTP2_NoTargetSince > 0 and (now - FTP2_NoTargetSince) or 0

    -- No hacer hop si acabamos de empezar
    if timeSinceStart < 30 then return end

    -- No hacer hop si hace poco vimos un target (puede estar en safe zone temporalmente)
    local timeSinceLastSeen = now - FTP2_LastTargetSeen
    if timeSinceLastSeen < 10 then return end

    if timeSinceNoTarget >= (_G.HopNoTargetDelay or 30) then
        _G.FTP2_HasTriggeredHop = true
        WindUI:Notify({Title="Server Hop", Content="Sin targets por "..math.floor(timeSinceNoTarget).."s. Cambiando servidor...", Duration=5})
        task.spawn(function() if StartServerHop then StartServerHop() end end)
    end
end

-- ========================
-- LOOP PRINCIPAL
-- ========================
local function StartFTPFlight2()
    if _G.FTP2_FlightConn ~= nil then return end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    char:WaitForChild("Humanoid", 9e9)
    char:WaitForChild("HumanoidRootPart", 9e9)
    while not char.Parent do task.wait() end
    local checkHum = char:FindFirstChildOfClass("Humanoid")
    if checkHum and checkHum.Health <= 0 then
        LocalPlayer.CharacterAdded:Wait()
        return StartFTPFlight2()
    end
    if not _G.FTP2_Enabled then return end

    _G.FTP2_Enabled = true
    table.clear(_G.FTP2_LastTeleportTicks); table.clear(_G.FTP2_TeleportFails)
    table.clear(_G.FTP2_BlockedEntrances); table.clear(_G.FTP2_Blacklist)
    _G.FTP2_TeleportPauseUntil = 0; _G.FTP2_HasTriggeredHop = false
    _G.FTP2_CurrentTarget      = nil; _G.FTP2_TargetLockTime = os.clock()
    _G.FTP2_StartTime          = os.clock(); _G.FTP2_FleeReturnPos = nil
    FTP2_OrbitOffset = nil; FTP2_NextOrbitTime = 0; FTP2_NoTargetSince = 0; FTP2_LastTargetSeen = os.clock()

    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum:ChangeState(Enum.HumanoidStateType.Physics) end

    _G.FTP2_PlayerLeaveConn = Players.PlayerRemoving:Connect(function(plr)
        _G.TargetHistory[plr] = nil; _G.FTP2_Blacklist[plr] = nil
        if _G.FTP2_CurrentTarget == plr then _G.FTP2_CurrentTarget = nil end
    end)

    local lastHistoryUpdate = 0; local lastNoclipScan = 0
    local cachedChar = nil; local cachedParts = nil

    _G.FTP2_FlightConn = RunService.RenderStepped:Connect(function()
        if not _G.FTP2_Enabled then return end
        local curChar = LocalPlayer.Character
        local curHum  = curChar and curChar:FindFirstChildOfClass("Humanoid")

        ForceStandUp()

        if _G.AutoFlee and curHum and curHum.Health > 0 then
            local hp = (curHum.Health / curHum.MaxHealth) * 100
            if hp <= (_G.AutoFleeHP or 30) then
                if not _G.FTP2_FleeReturnPos then
                    local hrp = curChar:FindFirstChild("HumanoidRootPart")
                    if hrp then _G.FTP2_FleeReturnPos = hrp.Position end
                end
                FleeUpLogic(); return
            end
        end

        if _G.FTP2_FleeReturnPos then
            local fChar = LocalPlayer.Character
            local fHum  = fChar and fChar:FindFirstChildOfClass("Humanoid")
            local fHRP  = fChar and fChar:FindFirstChild("HumanoidRootPart")
            if fHRP and fHum and fHum.Health > 0 then
                fHRP.CFrame = CFrame.new(_G.FTP2_FleeReturnPos)
                _G.FTP2_FleeReturnPos = nil
                if _G.FTP2_LinearVelocity then _G.FTP2_LinearVelocity.VectorVelocity=Vector3.new(0,0,0) end
                SetCharNoclip(fChar, false)
                WindUI:Notify({Title="Auto Bounty Farm", Content="HP recuperado, regresando al farm", Duration=3})
            elseif not fHRP or not fHum or fHum.Health <= 0 then
                _G.FTP2_FleeReturnPos = nil
            end
        end

        local now = os.clock()
        if now - lastHistoryUpdate >= 0.1 then lastHistoryUpdate=now; UpdatePositionHistory() end

        pcall(function()
            local myChar = LocalPlayer.Character
            if myChar then
                local myHum = myChar:FindFirstChildOfClass("Humanoid")
                if myChar ~= cachedChar or not cachedParts or now - lastNoclipScan >= 1 then
                    lastNoclipScan = now; cachedChar = myChar; cachedParts = {}
                    for _, part in ipairs(myChar:GetDescendants()) do
                        if part:IsA("BasePart") then table.insert(cachedParts, part) end
                    end
                end
                for _, part in ipairs(cachedParts) do if part.CanCollide then part.CanCollide=false end end
                if myHum and not myHum.PlatformStand then myHum.PlatformStand = true end
            end
        end)

        if _G.FTP2_CurrentTarget and not IsValidTargetFast(_G.FTP2_CurrentTarget) then
            _G.FTP2_Blacklist[_G.FTP2_CurrentTarget] = true; _G.FTP2_CurrentTarget = nil
        end

        local oldTarget = _G.FTP2_CurrentTarget
        local lowHpLock = IsTargetLowHP(oldTarget)

        if lowHpLock then
            _G.FTP2_CurrentTarget = oldTarget
        else
            _G.FTP2_CurrentTarget = GetNearestPlayer()
        end

        if _G.FTP2_CurrentTarget then
            -- Tenemos target: resetear timers de hop
            FTP2_NoTargetSince  = 0
            FTP2_LastTargetSeen = os.clock()
            _G.FTP2_HasTriggeredHop = false  -- permitir hop futuro si volvemos a quedarnos sin targets
            if _G.FTP2_CurrentTarget ~= oldTarget then _G.FTP2_TargetLockTime = os.clock() end
            if not lowHpLock and os.clock() - _G.FTP2_TargetLockTime >= _G.FTP2_TimeoutLimit then
                _G.FTP2_Blacklist[_G.FTP2_CurrentTarget] = true
                WindUI:Notify({Title="Auto Bounty Farm", Content="Timeout: "..(_G.FTP2_CurrentTarget.Name or "?").." bloqueado", Duration=3})
                _G.FTP2_CurrentTarget = nil; _G.FTP2_TargetLockTime = os.clock()
            end
        else
            _G.FTP2_TargetLockTime = os.clock()
        end

        if _G.FTP2_CurrentTarget then
            FlyToTargetLogic2(_G.FTP2_CurrentTarget)
        else
            -- Solo empezar a contar si llevamos un momento sin target (no desde el primer frame)
            if FTP2_NoTargetSince == 0 then FTP2_NoTargetSince = os.clock() end
            FleeUpLogic()
            -- Solo verificar hop cada 5 segundos para no spammear
            if os.clock() % 5 < 0.1 then CheckAndNotifyCombatStatus() end
        end
    end)
end

local function StopFTPFlight2()
    _G.FTP2_Enabled = false
    _G.FTP2_TeleportPauseUntil = 0
    _G.FTP2_CurrentTarget = nil
    _G.FTP2_FleeReturnPos = nil
    if _G.FTP2_FlightConn then _G.FTP2_FlightConn:Disconnect(); _G.FTP2_FlightConn=nil end
    if _G.FTP2_PlayerLeaveConn then _G.FTP2_PlayerLeaveConn:Disconnect(); _G.FTP2_PlayerLeaveConn=nil end
    ClearFTP2FlightComponents()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hum then hum.PlatformStand=false; hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
        if hrp then hrp.AssemblyLinearVelocity=Vector3.new(0,0,0); hrp.AssemblyAngularVelocity=Vector3.new(0,0,0) end
    end
end

if _G.FTP2_Enabled then task.spawn(StartFTPFlight2) end

-- ========================
-- SILENT AIM
-- ========================
local function IsSilentAimEnemy(player)
    if not player or player == LocalPlayer then return false end
    if IsPlayerAlly(player) then return false end
    local mt = LocalPlayer.Team; local tt = player.Team
    if mt and tt and mt.Name=="Marines" and tt.Name=="Marines" then return false end
    return true
end

local function SilentAim_GetTargetPartAndDist()
    local myChar = LocalPlayer.Character; if not myChar then return nil, math.huge end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart"); if not myRoot then return nil, math.huge end
    if _G.SilentAimTargetMode == "Jugador objetivo actualmente bloqueado" then
        local tp = _G.FTP2_CurrentTarget
        if tp and tp.Parent and tp.Character then
            if not _G.SilentAimTeamCheck or IsSilentAimEnemy(tp) then
                local ch   = tp.Character
                local hum  = ch:FindFirstChildOfClass("Humanoid")
                local root = ch:FindFirstChild("HumanoidRootPart")
                if hum and hum.Health > 0 and root then
                    return root, (root.Position - myRoot.Position).Magnitude
                end
            end
        end
        return nil, math.huge
    end
    local closest, shortest = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and (not _G.SilentAimTeamCheck or IsSilentAimEnemy(plr)) then
            local ch = plr.Character
            if ch and IsAlive(ch) then
                local part = ch:FindFirstChild("HumanoidRootPart")
                if part then
                    local d = (part.Position - myRoot.Position).Magnitude
                    if d < shortest then closest=part; shortest=d end
                end
            end
        end
    end
    return closest, shortest
end

if not _G.SilentAimHooked and not disableHook then
    _G.SilentAimHooked = true
    task.spawn(function()
        local MM = ReplicatedStorage:WaitForChild("Mouse", 5)
        if MM then
            pcall(function()
                local MouseModule = require(MM)
                if typeof(MouseModule) == "table" then
                    local real = {Hit=rawget(MouseModule,"Hit"), Target=rawget(MouseModule,"Target")}
                    local mmt  = getrawmetatable(MouseModule) or {}
                    setreadonly(mmt, false)
                    rawset(MouseModule, "Hit", nil); rawset(MouseModule, "Target", nil)
                    mmt.__index = function(self, key)
                        if key=="Hit" then return (_G.SilentAimEnabled and currentSilentAimTargetPos) and CFrame.new(currentSilentAimTargetPos) or real.Hit
                        elseif key=="Target" then return (_G.SilentAimEnabled and currentSilentAimTarget) and currentSilentAimTarget or real.Target end
                        return rawget(self, key)
                    end
                    mmt.__newindex = function(self, key, value)
                        if key=="Hit" or key=="Target" then real[key]=value else rawset(self,key,value) end
                    end
                    setreadonly(mmt, true); setmetatable(MouseModule, mmt)
                end
            end)
        end
    end)
    local gmt = getrawmetatable(game)
    if gmt then
        setreadonly(gmt, false)
        local oldIndex = gmt.__index
        local mouse    = LocalPlayer:GetMouse()
        gmt.__index    = newcclosure(function(self, key)
            if not checkcaller() and _G.SilentAimEnabled and currentSilentAimTargetPos and self == mouse then
                local tp  = currentSilentAimTargetPos
                local cam = Camera.CFrame.Position
                if key=="Hit" then return CFrame.new(tp)
                elseif key=="Target" then return currentSilentAimTarget
                elseif key=="UnitRay" then return Ray.new(cam, (tp-cam).Unit)
                elseif key=="Origin" then return CFrame.new(cam)
                elseif key=="Direction" then return (tp-cam).Unit end
            end
            return oldIndex(self, key)
        end)
        setreadonly(gmt, true)
    end
end

if _G.SilentAimLoop then _G.SilentAimLoop:Disconnect() end
_G.SilentAimLoop = RunService.RenderStepped:Connect(function()
    if _G.SilentAimEnabled then
        currentSilentAimTarget, _  = SilentAim_GetTargetPartAndDist()
        currentSilentAimTargetPos  = currentSilentAimTarget and currentSilentAimTarget.Position or nil
        _G.SilentAimTargetPos      = currentSilentAimTargetPos
    else
        currentSilentAimTarget=nil; currentSilentAimTargetPos=nil; _G.SilentAimTargetPos=nil
    end
end)

-- ========================
-- CAMLOCK
-- ========================
local camlockWasEnabled = false
RunService.RenderStepped:Connect(function()
    if not _G.CamlockEnabled then
        if camlockWasEnabled then
            camlockWasEnabled = false
            if LocalPlayer.Character then
                for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.LocalTransparencyModifier=0 end
                end
            end
        end
        return
    end
    camlockWasEnabled = true
    if not _G.FTP2_CurrentTarget or not _G.FTP2_CurrentTarget.Character or not LocalPlayer.Character then return end
    local char = LocalPlayer.Character
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.LocalTransparencyModifier < 1 then part.LocalTransparencyModifier=1 end
    end
    local cam       = workspace.CurrentCamera
    local targetHRP = _G.FTP2_CurrentTarget.Character:FindFirstChild("HumanoidRootPart")
    local localHead = char:FindFirstChild("Head")
    if targetHRP and localHead then
        local camPos = localHead.Position + localHead.CFrame.LookVector * 1.5
        cam.CFrame   = CFrame.new(camPos, targetHRP.Position)
    end
end)

-- ========================
-- AUTO SKILLS
-- ========================
LocalPlayer.CharacterAdded:Connect(function() SkillCoolDownTrack = {} end)

local function GetMyCharacter()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChildOfClass("Humanoid") then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum.Health > 0 then return char end
    end
    return nil
end

local function getToolType(tool)
    if not tool or not tool:IsA("Tool") then return nil end
    local tType = tool:GetAttribute("Type") or tool.ToolTip
    if tType == "Fruit" then tType = "Blox Fruit" end
    return tType
end

local function SkillEquipByType(toolType)
    local char = GetMyCharacter(); if not char then return nil end
    local hum  = char:FindFirstChildOfClass("Humanoid"); if not hum then return nil end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and getToolType(tool) == toolType then return tool end
    end
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") and getToolType(tool) == toolType then
                hum:EquipTool(tool); task.wait(0.15); return tool
            end
        end
    end
    return nil
end

local function SkillPressKey(key, holdTime)
    if not key then return end
    VirtualInputManager:SendKeyEvent(true, key, false, game)
    task.wait(holdTime or 0.05)
    VirtualInputManager:SendKeyEvent(false, key, false, game)
end

local function GetAvailableSkills()
    local available   = {}
    local currentTime = os.clock()
    local myChar      = GetMyCharacter(); if not myChar then return available end
    local pg    = LocalPlayer:FindFirstChild("PlayerGui")
    local SkillF = pg and pg:FindFirstChild("Main") and pg.Main:FindFirstChild("Skills")
    for weaponName, weaponData in pairs(_G.AutoSkillWeapons) do
        if not weaponData.Enable then continue end
        local toolInst = nil
        for _, item in ipairs(myChar:GetChildren()) do
            if item:IsA("Tool") and getToolType(item) == weaponName then toolInst=item; break end
        end
        if not toolInst then
            local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
            if bp then
                for _, item in ipairs(bp:GetChildren()) do
                    if item:IsA("Tool") and getToolType(item) == weaponName then toolInst=item; break end
                end
            end
        end
        if not toolInst then continue end
        local uiF = SkillF and SkillF:FindFirstChild(toolInst.Name)
        for skillName, skillData in pairs(weaponData.Skills) do
            if not skillData.Enable then continue end
            local cdKey   = weaponName .. "_" .. skillName
            local isReady = false
            if uiF and uiF:FindFirstChild(skillName) then
                local sg       = uiF[skillName]
                local cdFrame  = sg:FindFirstChild("Cooldown", true)
                local lvlFrame = sg:FindFirstChild("Level")
                local reqLv    = lvlFrame and tonumber(lvlFrame.Text:match("%d+")) or 0
                local curLv    = toolInst:FindFirstChild("Level") and toolInst.Level.Value or 0
                if cdFrame and cdFrame.Size.X.Scale == 0 and reqLv <= curLv then
                    if currentTime >= (SkillCoolDownTrack[cdKey] or 0) then isReady=true end
                end
            else
                if currentTime >= (SkillCoolDownTrack[cdKey] or 0) then isReady=true end
            end
            if isReady then
                table.insert(available, {Weapon=weaponName,Skill=skillName,HoldTime=skillData.HoldTime,Cooldown=1.0,Tool=toolInst})
            end
        end
    end
    return available
end

task.spawn(function()
    while true do
        task.wait(0.1)
        if not _G.AutoSkillMainEnable then continue end
        local tPart = currentSilentAimTarget
        if not tPart and _G.FTP2_CurrentTarget and _G.FTP2_CurrentTarget.Character then
            tPart = _G.FTP2_CurrentTarget.Character:FindFirstChild("HumanoidRootPart")
        end
        local dist = math.huge
        if tPart and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            dist = (tPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
        end
        if tPart and dist <= 80 then
            local avail = GetAvailableSkills()
            if #avail > 0 then
                local chosen = avail[math.random(1, #avail)]
                local mc = GetMyCharacter()
                if mc then
                    local eq = SkillEquipByType(chosen.Weapon)
                    if eq then
                        local cdKey = chosen.Weapon .. "_" .. chosen.Skill
                        SkillCoolDownTrack[cdKey] = os.clock() + chosen.Cooldown + chosen.HoldTime
                        local ke = SkillKeyMap[chosen.Skill]
                        if ke then SkillPressKey(ke, chosen.HoldTime) end
                        task.wait(0.2)
                    end
                end
            end
        end
    end
end)

local function HandleSkillDropdown(weaponType, selectedValues)
    for key, data in pairs(_G.AutoSkillWeapons[weaponType].Skills) do data.Enable=false end
    for k, val in pairs(selectedValues) do
        local skillKey = type(k)=="number" and val or k
        local isEnabled = type(k)=="number" and true or val
        if isEnabled and _G.AutoSkillWeapons[weaponType].Skills[skillKey] then
            _G.AutoSkillWeapons[weaponType].Skills[skillKey].Enable = true
        end
    end
end

-- ========================
-- GRÁFICOS
-- ========================
_G.SetLowVisualState = function(state)
    _G.LowVisualMode = state
    if state then
        WindUI:Notify({Title="Modo bajo rendimiento", Content="Optimizando...", Duration=5})
        local L = game:GetService("Lighting")
        L.GlobalShadows=false; L.FogEnd=9e9; L.Brightness=1
        for _, obj in ipairs(game:GetDescendants()) do
            if obj:IsA("BasePart") then obj.Material=Enum.Material.SmoothPlastic; obj.Reflectance=0
            elseif obj:IsA("Decal") or obj:IsA("Texture") then obj:Destroy()
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then obj.Enabled=false
            elseif obj:IsA("PostEffect") or obj:IsA("BloomEffect") or obj:IsA("BlurEffect") or obj:IsA("DepthOfFieldEffect") or obj:IsA("SunRaysEffect") then obj.Enabled=false end
        end
        if not _G.LowVisualConnection then
            _G.LowVisualConnection = workspace.DescendantAdded:Connect(function(obj)
                if obj:IsA("BasePart") then obj.Material=Enum.Material.SmoothPlastic; obj.Reflectance=0
                elseif obj:IsA("Decal") or obj:IsA("Texture") then obj:Destroy()
                elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then obj.Enabled=false end
            end)
        end
    else
        if _G.LowVisualConnection then _G.LowVisualConnection:Disconnect(); _G.LowVisualConnection=nil end
    end
end

_G.ApplyRemoveFog = function()
    local L   = game:GetService("Lighting")
    local lay = L:FindFirstChild("LightingLayers"); if lay then lay:Destroy() end
    local sky = L:FindFirstChildOfClass("Sky"); if sky then sky:Destroy() end
    L.FogEnd  = 9e9
end

-- ========================
-- ANTI AFK
-- ========================
local function EnableAntiAFK()
    if _G.AntiAFK_Connection then _G.AntiAFK_Connection:Disconnect(); _G.AntiAFK_Connection=nil end
    _G.AntiAFK_Connection = LocalPlayer.Idled:Connect(function()
        local VU = game:GetService("VirtualUser")
        VU:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VU:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
    if getconnections then
        for _, conn in pairs(getconnections(LocalPlayer.Idled)) do
            if conn.Disable then conn:Disable() elseif conn.Disconnect then conn:Disconnect() end
        end
    end
end
local function DisableAntiAFK()
    if _G.AntiAFK_Connection then _G.AntiAFK_Connection:Disconnect(); _G.AntiAFK_Connection=nil end
end
if _G.AntiAFK_ENABLED then EnableAntiAFK() end

game:GetService("GuiService").ErrorMessageChanged:Connect(function()
    if not _G.AutoRejoinEnabled then return end
    pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer) end)
end)

local function startAutoHideTimer()
    task.delay(3, function()
        if _G.AutoHideEnabled then
            Window:Toggle(false)
            WindUI:Notify({Title="UI ocultada", Content="Pulsa la tecla para abrirla", Duration=5})
        end
    end)
end
if _G.AutoHideEnabled then startAutoHideTimer() end

-- ========================================
-- WIND UI TABS
-- ========================================
local availableThemes = WindUI:GetThemes()
local themeList = {}
for themeName, _ in pairs(availableThemes) do table.insert(themeList, themeName) end

local Tabs = {
    Config    = Window:Tab({ Title = "Configuración",     Icon = "wrench" }),
    Skills    = Window:Tab({ Title = "Bounty & Skills",   Icon = "zap" }),
    Teleports = Window:Tab({ Title = "Teleports",         Icon = "map-pin" }),
    Settings  = Window:Tab({ Title = "Gráficos & Ajustes", Icon = "settings" }),
}

-- ========================
-- TAB: CONFIG
-- ========================
Tabs.Config:Section({ Title = "Auto Cambio de Servidor" })

FilterParagraph = Tabs.Config:Paragraph({ Title="Filtro actual", Desc=BuildFilterText() })

Tabs.Config:Dropdown({
    Title="Seleccionar región", Values=RegionValues, Value=_G.ServerRegion,
    Callback=function(v) _G.ServerRegion=v; RefreshFilterParagraph(); MarkConfigDirty() end
})
Tabs.Config:Slider({
    Title="Jugadores mínimos", Value={Min=1,Max=20,Default=_G.HopMinPlayers},
    Callback=function(v) _G.HopMinPlayers=v; RefreshFilterParagraph(); MarkConfigDirty() end
})
Tabs.Config:Slider({
    Title="Jugadores máximos", Value={Min=1,Max=20,Default=_G.HopMaxPlayers},
    Callback=function(v) _G.HopMaxPlayers=v; RefreshFilterParagraph(); MarkConfigDirty() end
})
Tabs.Config:Slider({
    Title="Bounty mínimo del server (M)", Step=0.5, Value={Min=0,Max=50,Default=3},
    Callback=function(v) _G.HopMinBounty=v*1000000; RefreshFilterParagraph(); MarkConfigDirty() end
})
Tabs.Config:Toggle({
    Title="Server Hop automático",
    Desc="Cambia servidor automáticamente cuando no hay targets disponibles",
    Value=_G.ServerHopEnabled,
    Callback=function(v)
        _G.ServerHopEnabled = v
        if not v then StopServerHop() end
        MarkConfigDirty()
    end
})
Tabs.Config:Slider({
    Title="Tiempo sin targets para hacer hop (s)",
    Desc="Segundos sin encontrar targets antes de cambiar servidor",
    Value={Min=10, Max=120, Default=30},
    Callback=function(v) _G.HopNoTargetDelay = v; MarkConfigDirty() end
})
Tabs.Config:Button({Title="Iniciar cambio de servidor", Icon="arrow-right-left", Callback=function() StartServerHop() end})
Tabs.Config:Button({Title="Detener cambio de servidor", Icon="circle-stop", Callback=function() StopServerHop() end})

Tabs.Config:Section({ Title = "M1 (ataques básicos)" })
Tabs.Config:Toggle({
    Title="M1 Normal", Desc="Ataque M1 modo 1", Value=_G.M1Normal,
    Callback=function(v)
        _G.M1Normal=v
        if v or _G.M1Dos then stopManual() else startManual() end
        MarkConfigDirty()
    end
})
Tabs.Config:Toggle({
    Title="M1 2", Desc="Ataque M1 modo 2 (usar si el 1 no funciona)", Value=_G.M1Dos,
    Callback=function(v)
        _G.M1Dos=v
        if v or _G.M1Normal then stopManual() else startManual() end
        MarkConfigDirty()
    end
})
Tabs.Config:Slider({
    Title="Distancia de ataque", Value={Min=10,Max=3000,Default=_G.AttackDistance},
    Callback=function(v) _G.AttackDistance=v; MarkConfigDirty() end
})
Tabs.Config:Slider({
    Title="Velocidad de ataque (s)", Step=0.05, Value={Min=0.05,Max=2,Default=_G.FastAttackSpeed},
    Callback=function(v) _G.FastAttackSpeed=v; MarkConfigDirty() end
})

Tabs.Config:Section({ Title = "M1 Fruta" })
Tabs.Config:Toggle({Title="M1 Fruta", Value=_G.FruitsM1Enable, Callback=function(v) _G.FruitsM1Enable=v; MarkConfigDirty() end})
Tabs.Config:Slider({
    Title="Retraso Fruta M1", Step=0.01, Value={Min=0.01,Max=0.5,Default=_G.FruitsM1DelayValue},
    Callback=function(v) _G.FruitsM1DelayValue=v; MarkConfigDirty() end
})

Tabs.Config:Section({ Title = "Config Auto Activado" })
Tabs.Config:Toggle({
    Type="Checkbox", Title="ESP Players", Value=_G.ESP_Master,
    Callback=function(state)
        _G.ESP_Master=state; _G.ESP_ShowName=state; _G.ESP_ShowLevel=state
        _G.ESP_ShowPVPStatus=state; _G.ESP_ShowHealth=state; _G.ESP_ShowDistance=state; _G.ESP_TeamColor=state
        for _, p in ipairs(Players:GetPlayers()) do if state then createESP(p) else removeESP(p) end end
        MarkConfigDirty()
    end
})
Tabs.Config:Toggle({
    Title="Mostrar trazadores", Value=_G.ESP_ShowTracers,
    Callback=function(v)
        _G.ESP_ShowTracers=v
        if not v then for _, p in ipairs(Players:GetPlayers()) do removeTracer(p) end end
        MarkConfigDirty()
    end
})
Tabs.Config:Slider({
    Title="Tamaño fuente ESP", Value={Min=10,Max=32,Default=_G.ESP_FontSize},
    Callback=function(v) _G.ESP_FontSize=v; MarkConfigDirty() end
})
Tabs.Config:Toggle({Title="Auto Enabled PVP",Value=_G.AutoEnablePVP,Callback=function(v) _G.AutoEnablePVP=v; MarkConfigDirty() end})
Tabs.Config:Toggle({Title="Auto Buso",Value=_G.AutoBusoEnabled,Callback=function(v) _G.AutoBusoEnabled=v; MarkConfigDirty() end})
Tabs.Config:Toggle({Title="Auto V3",Value=_G.AutoV3_Enabled,Callback=function(v) _G.AutoV3_Enabled=v; MarkConfigDirty() end})
Tabs.Config:Toggle({Title="Auto V4",Value=_G.AutoV4_Enabled,Callback=function(v) _G.AutoV4_Enabled=v; MarkConfigDirty() end})
Tabs.Config:Toggle({Title="Auto Ken",Value=_G.AutoKenEnabled,Callback=function(v) _G.AutoKenEnabled=v; MarkConfigDirty() end})
Tabs.Config:Toggle({
    Title="Auto Soru", Value=_G.AutoSoru,
    Callback=function(v) _G.AutoSoru=v; if v then StartAutoSoru() else StopAutoSoru() end; MarkConfigDirty() end
})
Tabs.Config:Toggle({Title="Activar Hitbox",Value=_G.Hitbox_Enabled,Callback=function(v) _G.Hitbox_Enabled=v; applyHitboxAll(); MarkConfigDirty() end})
Tabs.Config:Slider({
    Title="Tamaño Hitbox", Value={Min=1,Max=500,Default=_G.Hitbox_Size},
    Callback=function(v) _G.Hitbox_Size=v; if _G.Hitbox_Enabled then applyHitboxAll() end; MarkConfigDirty() end
})
Tabs.Config:Toggle({
    Title="Huida automática", Value=_G.AutoFlee,
    Callback=function(v) _G.AutoFlee=v; if v then StartAutoFlee() else StopAutoFlee() end; MarkConfigDirty() end
})
Tabs.Config:Slider({
    Title="HP para huir (%)", Value={Min=1,Max=100,Default=_G.AutoFleeHP},
    Callback=function(v) _G.AutoFleeHP=v; MarkConfigDirty() end
})
Tabs.Config:Toggle({
    Title="Eliminar animaciones", Value=_G.RemoveAnim,
    Callback=function(v) _G.RemoveAnim=v; if v then StartRemoveAnim() else StopRemoveAnim() end; MarkConfigDirty() end
})
Tabs.Config:Toggle({Title="Caminar sobre el agua",Value=_G.WaterWalkEnabled,Callback=function(v) _G.WaterWalkEnabled=v; MarkConfigDirty() end})
Tabs.Config:Toggle({Title="Eliminar lava",Value=_G.RemoveLavaEnabled,Callback=function(v) _G.RemoveLavaEnabled=v; MarkConfigDirty() end})
Tabs.Config:Toggle({Title="Eliminar daño Barco Fantasma",Value=_G.RemoveGhostShipLavaEnabled,Callback=function(v) _G.RemoveGhostShipLavaEnabled=v; MarkConfigDirty() end})

-- ========================
-- TAB: BOUNTY & SKILLS
-- ========================
Tabs.Skills:Section({ Title = "Auto Bounty Farm" })
Tabs.Skills:Dropdown({
    Title="Seleccionar bando", Values={"Piratas","Marines"},
    Value=_G.SelectTeam=="Pirates" and "Piratas" or "Marines",
    Callback=function(v) _G.SelectTeam=v=="Piratas" and "Pirates" or "Marines"; SelectTeam(); MarkConfigDirty() end
})
Tabs.Skills:Toggle({
    Title="Auto Bounty Farm", Value=_G.FTP2_Enabled,
    Callback=function(v)
        _G.FTP2_Enabled=v
        if v then StartFTPFlight2(); WindUI:Notify({Title="Auto Bounty Farm", Content="Activado ✓", Duration=3})
        else StopFTPFlight2(); WindUI:Notify({Title="Auto Bounty Farm", Content="Desactivado", Duration=3}) end
        MarkConfigDirty()
    end
})

-- ========================
-- VECTORES DE CONFIGURACIÓN
-- ========================
Tabs.Skills:Section({ Title = "Vectores de vuelo" })

Tabs.Skills:Slider({
    Title="Velocidad de vuelo",
    Desc="Velocidad LinearVelocity hacia el objetivo",
    Value={Min=50,Max=400,Default=_G.FTP2_FlySpeed},
    Callback=function(v) _G.FTP2_FlySpeed=v; MarkConfigDirty() end
})
Tabs.Skills:Slider({
    Title="Radio de órbita",
    Desc="Distancia de movimiento orbital alrededor del target",
    Value={Min=5,Max=200,Default=_G.FTP2_OrbitRadius},
    Callback=function(v) _G.FTP2_OrbitRadius=v; MarkConfigDirty() end
})
Tabs.Skills:Slider({
    Title="Timeout de objetivo (s)",
    Desc="Segundos máximos persiguiendo un mismo target antes de saltar",
    Value={Min=30,Max=300,Default=_G.FTP2_TimeoutLimit},
    Callback=function(v) _G.FTP2_TimeoutLimit=v; MarkConfigDirty() end
})
Tabs.Skills:Slider({
    Title="Rango sin teleport (studs)",
    Desc="Si el target está más cerca que esto, no usa entradas de isla",
    Value={Min=50,Max=1000,Default=_G.FTP2_NoTeleportRange},
    Callback=function(v) _G.FTP2_NoTeleportRange=v; MarkConfigDirty() end
})
Tabs.Skills:Slider({
    Title="% HP para lock (bajo HP)",
    Desc="Si el target tiene menos de este % de HP, lo sigue aunque aparezca uno más cercano",
    Value={Min=1,Max=80,Default=_G.FTP2_LowHpLockPercent},
    Callback=function(v) _G.FTP2_LowHpLockPercent=v; MarkConfigDirty() end
})
Tabs.Skills:Slider({
    Title="Delay hop sin target (s)",
    Desc="Segundos sin encontrar targets antes de hacer server hop automático",
    Value={Min=10,Max=120,Default=_G.HopNoTargetDelay},
    Callback=function(v) _G.HopNoTargetDelay=v; MarkConfigDirty() end
})

-- ========================
-- FILTRO DE BOUNTY (TARGET)
-- ========================
Tabs.Skills:Section({ Title = "Filtro de targets por Bounty" })
Tabs.Skills:Paragraph({
    Title="Solo ataca jugadores con bounty en el rango configurado",
    Desc=string.format("Rango actual: %.1fM → %.1fM",
        (_G.FTP2_TargetBountyMin or 2500000)/1000000,
        (_G.FTP2_TargetBountyMax or 30000000)/1000000
    )
})
Tabs.Skills:Slider({
    Title="Bounty mínimo de target (M)",
    Desc="0 = sin límite. Solo ataca jugadores con al menos este bounty",
    Step=0.5, Value={Min=0,Max=30,Default=0},
    Callback=function(v)
        _G.FTP2_TargetBountyMin = v * 1000000
        MarkConfigDirty()
    end
})
Tabs.Skills:Toggle({
    Title="Activar límite máximo de bounty",
    Desc="Si está OFF, ataca a cualquier jugador sin importar su bounty máximo",
    Value=false,
    Callback=function(v)
        _G.FTP2_TargetBountyMax = v and 30000000 or math.huge
        MarkConfigDirty()
    end
})
Tabs.Skills:Slider({
    Title="Bounty máximo de target (M)",
    Desc="Solo activo si el toggle de arriba está ON",
    Step=1, Value={Min=1,Max=100,Default=30},
    Callback=function(v)
        if _G.FTP2_TargetBountyMax ~= math.huge then
            _G.FTP2_TargetBountyMax = v * 1000000
            MarkConfigDirty()
        end
    end
})

Tabs.Skills:Button({
    Title="Saltar objetivo actual",
    Callback=function()
        if _G.FTP2_CurrentTarget then
            local name = _G.FTP2_CurrentTarget.Name
            _G.FTP2_Blacklist[_G.FTP2_CurrentTarget]=true; _G.FTP2_CurrentTarget=nil; _G.FTP2_TargetLockTime=os.clock()
            WindUI:Notify({Title="Saltar objetivo", Content="Saltado: "..name, Duration=3})
        else
            WindUI:Notify({Title="Saltar objetivo", Content="No hay objetivo activo", Duration=3})
        end
    end
})
Tabs.Skills:Button({
    Title="Limpiar blacklist",
    Callback=function()
        table.clear(_G.FTP2_Blacklist); table.clear(_G.FTP2_BlockedEntrances)
        WindUI:Notify({Title="Blacklist", Content="Lista de bloqueados limpiada", Duration=3})
    end
})

Tabs.Skills:Section({ Title = "Silent Aim" })
Tabs.Skills:Toggle({
    Title="Activar Silent Aim", Value=_G.SilentAimEnabled,
    Locked=disableHook, LockedTitle=disableHook and ("Executor no compatible: "..tostring(executorName)) or nil,
    Callback=function(v) if disableHook then return end; _G.SilentAimEnabled=v; MarkConfigDirty() end
})
Tabs.Skills:Toggle({
    Title="Camlock (para executors sin Silent Aim)", Value=_G.CamlockEnabled,
    Callback=function(v) _G.CamlockEnabled=v; MarkConfigDirty() end
})
Tabs.Skills:Toggle({
    Title="Team Check (no apuntar aliados)", Value=_G.SilentAimTeamCheck,
    Callback=function(v) _G.SilentAimTeamCheck=v; MarkConfigDirty() end
})

Tabs.Skills:Section({ Title = "Auto Skills" })
Tabs.Skills:Toggle({
    Title="Auto Skills", Value=_G.AutoSkillMainEnable,
    Callback=function(v) _G.AutoSkillMainEnable=v; MarkConfigDirty() end
})

local function GetEnabledWeaponList()
    local list = {}
    for wn, data in pairs(_G.AutoSkillWeapons) do if data.Enable then table.insert(list, wn) end end
    return list
end
local function GetEnabledSkillList(weaponType)
    local list = {}
    local data = _G.AutoSkillWeapons[weaponType]
    if data then for sn, sd in pairs(data.Skills) do if sd.Enable then table.insert(list, sn) end end end
    return list
end

Tabs.Skills:Dropdown({
    Title="Armas activas", Multi=true, Value=GetEnabledWeaponList(),
    Values={"Melee","Blox Fruit","Sword","Gun"},
    Callback=function(v)
        for k, wd in pairs(_G.AutoSkillWeapons) do wd.Enable=false end
        for k, val in pairs(v) do
            local wName = type(k)=="number" and val or k
            if type(k)=="number" and _G.AutoSkillWeapons[wName] then _G.AutoSkillWeapons[wName].Enable=true
            elseif val and _G.AutoSkillWeapons[wName] then _G.AutoSkillWeapons[wName].Enable=true end
        end
        MarkConfigDirty()
    end
})
Tabs.Skills:Space(); Tabs.Skills:Divider(); Tabs.Skills:Space()
Tabs.Skills:Dropdown({Title="Melee",Multi=true,Value=GetEnabledSkillList("Melee"),Values={"Z","X","C"},Callback=function(v) HandleSkillDropdown("Melee",v); MarkConfigDirty() end})
Tabs.Skills:Dropdown({Title="Blox Fruit",Multi=true,Value=GetEnabledSkillList("Blox Fruit"),Values={"Z","X","C","V","F"},Callback=function(v) HandleSkillDropdown("Blox Fruit",v); MarkConfigDirty() end})
Tabs.Skills:Dropdown({Title="Sword",Multi=true,Value=GetEnabledSkillList("Sword"),Values={"Z","X"},Callback=function(v) HandleSkillDropdown("Sword",v); MarkConfigDirty() end})
Tabs.Skills:Dropdown({Title="Gun",Multi=true,Value=GetEnabledSkillList("Gun"),Values={"Z","X"},Callback=function(v) HandleSkillDropdown("Gun",v); MarkConfigDirty() end})

-- ========================
-- TAB: TELEPORTS (VECTORES)
-- ========================

-- Helper para formatear Vector3
local function fmtV3(v)
    return string.format("%.1f, %.1f, %.1f", v.X, v.Y, v.Z)
end

-- Helper para parsear "X, Y, Z" -> Vector3
local function parseV3(str)
    local x, y, z = str:match("^%s*([%-%.%d]+)%s*,%s*([%-%.%d]+)%s*,%s*([%-%.%d]+)%s*$")
    if x and y and z then
        return Vector3.new(tonumber(x), tonumber(y), tonumber(z))
    end
    return nil
end

-- Detectar world actual
local function GetCurrentWorldKey()
    local pid = game.PlaceId
    if table.find({2753915549, 85211729168715}, pid) then return "World1" end
    if table.find({4442272183, 79091703265657}, pid) then return "World2" end
    if table.find({7449423635, 100117331123089}, pid) then return "World3" end
    return nil
end

local worldKey = GetCurrentWorldKey()
local worldName = worldKey == "World1" and "Mundo 1" or worldKey == "World2" and "Mundo 2" or worldKey == "World3" and "Mundo 3" or "Desconocido"

Tabs.Teleports:Paragraph({
    Title = "Mundo detectado: " .. worldName,
    Desc  = "Los portales abajo corresponden a tu mundo actual.\nActiva/desactiva portales o edita sus coordenadas.",
})

Tabs.Teleports:Section({ Title = "Estado de portales (" .. worldName .. ")" })

-- Toggles para habilitar/deshabilitar cada portal
if worldKey then
    local entries = _G.WorldEntrances[worldKey] or {}
    for i, e in ipairs(entries) do
        local idx = i
        Tabs.Teleports:Toggle({
            Title = e.Label .. " — " .. fmtV3(e.Arg),
            Desc  = "Destino: " .. fmtV3(e.Dest),
            Value = (_G.WorldEntrancesEnabled[worldKey][idx] ~= false),
            Callback = function(v)
                _G.WorldEntrancesEnabled[worldKey][idx] = v
                -- Limpiar entradas bloqueadas al cambiar
                table.clear(_G.FTP2_BlockedEntrances)
                MarkConfigDirty()
            end
        })
    end
else
    Tabs.Teleports:Paragraph({
        Title = "Mundo no reconocido",
        Desc  = "Este PlaceId no tiene portales configurados. El script funciona sin ellos.",
    })
end

Tabs.Teleports:Section({ Title = "Teleport manual (prueba de portal)" })

Tabs.Teleports:Paragraph({
    Title = "Teletransportarte a un portal",
    Desc  = "Útil para verificar si las coordenadas son correctas en tu servidor.",
})

if worldKey then
    local entries = _G.WorldEntrances[worldKey] or {}
    for i, e in ipairs(entries) do
        Tabs.Teleports:Button({
            Title = "TP → " .. e.Label,
            Desc  = fmtV3(e.Dest),
            Callback = function()
                local char = LocalPlayer.Character
                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = CFrame.new(e.Dest)
                    WindUI:Notify({
                        Title   = "Teleport Manual",
                        Content = "Teletransportado a " .. e.Label,
                        Duration = 2,
                    })
                end
            end
        })
    end
end

Tabs.Teleports:Section({ Title = "Resetear portales bloqueados" })

Tabs.Teleports:Paragraph({
    Title = "Estado de portales bloqueados",
    Desc  = "Si un portal falla 3 veces seguidas, el script lo bloquea automáticamente.\nUsa el botón abajo para desbloquearlo.",
})

Tabs.Teleports:Button({
    Title    = "Desbloquear todos los portales",
    Icon     = "refresh-cw",
    Callback = function()
        table.clear(_G.FTP2_BlockedEntrances)
        table.clear(_G.FTP2_TeleportFails)
        WindUI:Notify({
            Title   = "Portales",
            Content = "Todos los portales desbloqueados ✓",
            Duration = 3,
        })
    end
})

Tabs.Teleports:Section({ Title = "Posiciones de Safe Zone" })

Tabs.Teleports:Paragraph({
    Title = "Zonas seguras detectadas",
    Desc  = "El script evita atacar a jugadores dentro de estas zonas.\nPuedes ver las posiciones abajo.",
})

if worldKey then
    local zones = _G.FTP2_SafeZonePositions[worldKey] or {}
    local zoneDesc = ""
    for i, z in ipairs(zones) do
        zoneDesc = zoneDesc .. string.format("Zona %d: %s (r=%d)\n", i, fmtV3(z.pos), z.radius)
    end
    Tabs.Teleports:Paragraph({
        Title = "Safe Zones — " .. worldName,
        Desc  = zoneDesc ~= "" and zoneDesc or "Ninguna configurada",
    })
end

-- ========================
-- TAB: GRÁFICOS & AJUSTES
-- ========================
Tabs.Settings:Section({ Title = "Reiniciar Script" })
Tabs.Settings:Button({
    Title="Restablecer configuración", Icon="trash-2",
    Callback=function()
        local ok = pcall(function()
            if typeof(isfolder)=="function" and typeof(makefolder)=="function" and not isfolder(ConfigFolder) then makefolder(ConfigFolder) end
            if typeof(writefile)=="function" then writefile(ConfigFile, HttpService:JSONEncode(InitialConfig)) end
        end)
        if ok then ConfigDirty=false; WindUI:Notify({Title="Config", Content="Restablecida. Aplicará al próximo inicio", Duration=4})
        else WindUI:Notify({Title="Error", Content="No se pudo guardar. Verifica permisos de escritura", Duration=4}) end
    end
})

Tabs.Settings:Section({ Title = "Gráficos" })
Tabs.Settings:Toggle({
    Title="Desbloquear FPS", Value=_G.UnlockFPS,
    Callback=function(v) _G.UnlockFPS=v; if setfpscap then setfpscap(v and 999 or 0) end; MarkConfigDirty() end
})
Tabs.Settings:Toggle({
    Title="Modo bajo rendimiento", Value=_G.LowVisualMode,
    Callback=function(v) _G.SetLowVisualState(v); MarkConfigDirty() end
})
Tabs.Settings:Toggle({
    Title="Eliminar niebla", Value=_G.RemoveFogEnabled,
    Callback=function(v) _G.RemoveFogEnabled=v; if v then _G.ApplyRemoveFog() end; MarkConfigDirty() end
})

Tabs.Settings:Section({ Title = "Ajustes del sistema" })
Tabs.Settings:Toggle({
    Title="Anti AFK", Value=_G.AntiAFK_ENABLED,
    Callback=function(v) _G.AntiAFK_ENABLED=v; if v then EnableAntiAFK() else DisableAntiAFK() end; MarkConfigDirty() end
})
Tabs.Settings:Toggle({
    Title="Reconexión automática", Value=_G.AutoRejoinEnabled,
    Callback=function(v) _G.AutoRejoinEnabled=v; MarkConfigDirty() end
})
Tabs.Settings:Toggle({
    Title="Auto-ocultar UI (3s)", Value=_G.AutoHideEnabled,
    Callback=function(v) _G.AutoHideEnabled=v; if v then startAutoHideTimer() end; MarkConfigDirty() end
})
Tabs.Settings:Dropdown({
    Title="Tema", Values=themeList, Value=_G.Theme,
    Callback=function(v) _G.Theme=v; WindUI:SetTheme(v); MarkConfigDirty() end
})
Tabs.Settings:Keybind({
    Title="Tecla de acceso rápido", Value=_G.CurrentKey,
    Callback=function(v)
        _G.CurrentKey = typeof(v)=="EnumItem" and v.Name or tostring(v)
        if not _G.KeyDisabled then
            local ok, kc = pcall(function() return Enum.KeyCode[_G.CurrentKey] end)
            if ok then Window:SetToggleKey(kc) end
        end
        MarkConfigDirty()
    end
})
Tabs.Settings:Toggle({
    Title="Desactivar tecla de acceso", Value=_G.KeyDisabled,
    Callback=function(v)
        _G.KeyDisabled=v
        if v then Window:SetToggleKey(nil)
        else
            local ok, kc = pcall(function() return Enum.KeyCode[_G.CurrentKey] end)
            if ok then Window:SetToggleKey(kc) end
        end
        MarkConfigDirty()
    end
})

-- ========================
-- INICIALIZAR
-- ========================
task.spawn(function()
    task.wait()
    if _G.LowVisualMode then _G.SetLowVisualState(true) end
    if _G.RemoveFogEnabled then _G.ApplyRemoveFog() end
    if setfpscap then setfpscap(_G.UnlockFPS and 999 or 0) end
    if _G.AntiAFK_ENABLED then EnableAntiAFK() end
    WindUI:Notify({Title="Mionix Zbounty", Content="Script cargado correctamente ✓", Duration=4})
end)

task.spawn(function()
    task.wait(0.5)
    if not _G.KeyDisabled then
        local ok, kc = pcall(function() return Enum.KeyCode[_G.CurrentKey or "G"] end)
        if ok and kc then pcall(function() Window:SetToggleKey(kc) end) end
    end
    pcall(function() Window:Toggle(true) end)
end)
