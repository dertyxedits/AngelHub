--[[
    ╔═══════════════════════════════════════════════════════════╗
    ║                                                           ║
    ║   █████╗ ███╗   ██╗ ██████╗ ███████╗██╗                 ║
    ║  ██╔══██╗████╗  ██║██╔════╝ ██╔════╝██║                 ║
    ║  ███████║██╔██╗ ██║██║  ███╗█████╗  ██║                 ║
    ║  ██╔══██║██║╚██╗██║██║   ██║██╔══╝  ██║                 ║
    ║  ██║  ██║██║ ╚████║╚██████╔╝███████╗███████╗            ║
    ║  ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚══════╝╚══════╝           ║
    ║                                                           ║
    ║   ██╗  ██╗██╗   ██╗██████╗                              ║
    ║   ██║  ██║██║   ██║██╔══██╗                             ║
    ║   ███████║██║   ██║██████╔╝                             ║
    ║   ██╔══██║██║   ██║██╔══██╗                             ║
    ║   ██║  ██║╚██████╔╝██████╔╝                             ║
    ║   ╚═╝  ╚═╝ ╚═════╝ ╚═════╝                             ║
    ║                                                           ║
    ║   AngelHub v2.0 — San Diego RP Edition                   ║
    ║   Discord: https://discord.gg/d8gpXNGknP                 ║
    ║   Android / iOS / Windows — All Executors               ║
    ╚═══════════════════════════════════════════════════════════╝
]]

local DISCORD = "https://discord.gg/d8gpXNGknP"
local VERSION = "v2.0 SD"

-- ══════════════════════════════════════════════════════════════
-- SERVICES
-- ══════════════════════════════════════════════════════════════
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")
local VirtualUser      = game:GetService("VirtualUser")
local Camera           = workspace.CurrentCamera
local LP               = Players.LocalPlayer
local Mouse            = LP:GetMouse()

-- ══════════════════════════════════════════════════════════════
-- SAN DIEGO RP — GAME SPECIFIC CONFIG
-- ══════════════════════════════════════════════════════════════
-- SD uses custom character rigs; common hitbox part names:
local SD_HIT_PARTS = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "Torso"}
-- SD vehicles are models tagged with these names in workspace:
local SD_VEHICLE_TAGS = {"Car", "Vehicle", "Truck", "Police", "Border"}
-- SD NPC folder names:
local SD_NPC_FOLDERS = {"NPCs", "Civilians", "Officers", "Suspects", "Entities"}
-- SD teams (border RP):
local SD_TEAMS = {
    CBP   = "Customs and Border Protection",
    BP    = "Border Patrol",
    CIVIL = "Civilian",
    SUSP  = "Suspect",
    DEA   = "DEA",
    SWAT  = "SWAT",
}

-- ══════════════════════════════════════════════════════════════
-- CFG STATE
-- ══════════════════════════════════════════════════════════════
local CFG = {
    -- COMBAT
    AimbotEnabled   = false,
    SilentAim       = false,
    AimbotKey       = "RMB",        -- RMB / Q / E / LMB
    AimPart         = "Head",
    AimFOV          = 150,
    AimSmooth       = 0.15,
    PredictionVal   = 0.10,
    TeamCheck       = true,
    WallCheck       = false,
    AutoShoot       = false,
    TriggerBot      = false,
    TriggerDelay    = 0.05,
    AimLock         = false,
    CriticalHit     = false,        -- always aim head snap
    SDNPCTarget     = false,        -- include SD NPCs as targets
    ShowFOVCircle   = true,
    -- VISUALS
    ESPEnabled      = false,
    ESPBoxes        = true,
    ESPBoxStyle     = "Corner",     -- Corner / Full / 3D
    ESPNames        = true,
    ESPDistance     = true,
    ESPHealth       = true,
    ESPHealthBar    = true,
    ESPTracers      = false,
    ESPTracerOrigin = "Bottom",     -- Bottom / Center / Top
    ESPTeamColor    = false,
    ESPSkeleton     = false,
    ESPChams        = false,
    ESPNPCs         = false,
    ESPVehicles     = false,
    MaxESPDist      = 800,
    ESPColor        = Color3.fromRGB(0, 220, 255),
    ESPEnemyColor   = Color3.fromRGB(255, 60, 60),
    ESPFriendColor  = Color3.fromRGB(60, 255, 120),
    -- MISC
    NoClip          = false,
    SpeedEnabled    = false,
    SpeedValue      = 24,
    JumpEnabled     = false,
    JumpValue       = 50,
    InfJump         = false,
    FlyEnabled      = false,
    FlySpeed        = 60,
    AntiAFK         = true,
    GodMode         = false,
    BunnyHop        = false,
    NightVision     = false,
    FullBright      = false,
    NoFog           = false,
    InfStamina      = false,        -- SD has stamina system
    AutoRespawn     = false,
    -- SD SPECIFIC
    SDRadarEnabled  = false,
    SDAutoHandsUp   = false,        -- auto /handsup when aimed at
    SDGhostMode     = false,        -- invisible to other clients (server-side only partial)
    SDCopAlert      = false,        -- notify when cop aims at you
    SDVehicleESP    = false,
    SDCrosshair     = false,
    SDCrosshairSize = 10,
    SDCrosshairColor= Color3.fromRGB(255,255,255),
    -- SETTINGS
    UIScale         = 1.0,
    UIOpacity       = 1.0,
    KeybindOpen     = Enum.KeyCode.RightShift,
    Theme           = "Cyan",       -- Cyan / Purple / Red / Green / Gold
    RainbowMode     = false,
}

-- ══════════════════════════════════════════════════════════════
-- THEME SYSTEM
-- ══════════════════════════════════════════════════════════════
local THEMES = {
    Cyan   = {a=Color3.fromRGB(0,220,255),   b=Color3.fromRGB(0,140,170)},
    Purple = {a=Color3.fromRGB(180,80,255),  b=Color3.fromRGB(120,40,200)},
    Red    = {a=Color3.fromRGB(255,60,60),   b=Color3.fromRGB(180,30,30)},
    Green  = {a=Color3.fromRGB(60,255,120),  b=Color3.fromRGB(30,180,80)},
    Gold   = {a=Color3.fromRGB(255,200,30),  b=Color3.fromRGB(180,130,10)},
}

local function getAccent()
    if CFG.RainbowMode then
        local t = tick() % 5 / 5
        return Color3.fromHSV(t, 1, 1)
    end
    return THEMES[CFG.Theme] and THEMES[CFG.Theme].a or THEMES.Cyan.a
end

local CLR = {
    BG        = Color3.fromRGB(8, 8, 14),
    BG2       = Color3.fromRGB(12, 12, 20),
    Sidebar   = Color3.fromRGB(11, 11, 19),
    Panel     = Color3.fromRGB(15, 15, 25),
    Card      = Color3.fromRGB(18, 18, 30),
    Border    = Color3.fromRGB(30, 30, 50),
    Text      = Color3.fromRGB(230, 230, 245),
    SubText   = Color3.fromRGB(120, 120, 150),
    Muted     = Color3.fromRGB(60, 60, 80),
    White     = Color3.new(1,1,1),
    Red       = Color3.fromRGB(255,60,60),
    Green     = Color3.fromRGB(60,255,120),
}

local FONT     = Enum.Font.GothamBold
local FONT_REG = Enum.Font.Gotham
local FONT_MONO= Enum.Font.Code

-- ══════════════════════════════════════════════════════════════
-- CLIPBOARD
-- ══════════════════════════════════════════════════════════════
local function clip(text)
    if setclipboard then setclipboard(text)
    elseif toclipboard then toclipboard(text)
    elseif syn and syn.write_clipboard then syn.write_clipboard(text)
    elseif rbxassetid then -- fallback: print to console for manual copy
        print("[AngelHub] Copy: "..text)
    end
end

-- ══════════════════════════════════════════════════════════════
-- UTILITY
-- ══════════════════════════════════════════════════════════════
local function getChar(p)  return p and p.Character end
local function getHum(p)
    local c = getChar(p)
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function getRoot(p)
    local c = getChar(p)
    return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso"))
end
local function getPart(p, name)
    local c = getChar(p)
    if not c then return nil end
    return c:FindFirstChild(name) or c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso")
end
local function isAlive(p)
    local h = getHum(p)
    return h and h.Health > 0
end
local function sameTeam(p)
    return p.Team and LP.Team and p.Team == LP.Team
end
local function w2v(pos)
    local v, on = Camera:WorldToViewportPoint(pos)
    return Vector2.new(v.X, v.Y), on, v.Z
end
local function dist3D(p)
    local r = getRoot(p)
    if not r then return 9999 end
    return (r.Position - Camera.CFrame.Position).Magnitude
end
local function lerp(a, b, t) return a + (b-a)*t end
local function colorLerp(a, b, t)
    return Color3.new(lerp(a.R,b.R,t), lerp(a.G,b.G,t), lerp(a.B,b.B,t))
end

-- SD: get all NPC models
local function getSDNPCs()
    local npcs = {}
    for _, folder in ipairs(SD_NPC_FOLDERS) do
        local f = workspace:FindFirstChild(folder)
        if f then
            for _, m in ipairs(f:GetChildren()) do
                if m:IsA("Model") and m:FindFirstChildOfClass("Humanoid") then
                    table.insert(npcs, m)
                end
            end
        end
    end
    return npcs
end

-- SD: get all vehicles
local function getSDVehicles()
    local vehicles = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            for _, tag in ipairs(SD_VEHICLE_TAGS) do
                if obj.Name:find(tag) then
                    table.insert(vehicles, obj)
                    break
                end
            end
        end
    end
    return vehicles
end

-- ══════════════════════════════════════════════════════════════
-- AIM TARGET RESOLVER
-- ══════════════════════════════════════════════════════════════
local function getAimTarget()
    local best, bestDist = nil, CFG.AimFOV
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

    -- players
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP then continue end
        if CFG.TeamCheck and sameTeam(p) then continue end
        if not isAlive(p) then continue end
        local part = getPart(p, CFG.AimPart)
        if not part then continue end
        local vp, on, depth = w2v(part.Position)
        if not on or depth < 0 then continue end
        if CFG.WallCheck then
            local ray = Ray.new(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position).Unit * 999)
            local hit = workspace:FindPartOnRayWithIgnoreList(ray, {LP.Character, Camera})
            if hit and not hit:IsDescendantOf(p.Character) then continue end
        end
        local d = (vp - center).Magnitude
        if d < bestDist then bestDist = d; best = {player=p, part=part, vp=vp} end
    end

    -- SD NPCs
    if CFG.SDNPCTarget then
        for _, npc in ipairs(getSDNPCs()) do
            local hum = npc:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then continue end
            local part = npc:FindFirstChild("Head") or npc:FindFirstChild("HumanoidRootPart")
            if not part then continue end
            local vp, on, depth = w2v(part.Position)
            if not on or depth < 0 then continue end
            local d = (vp - center).Magnitude
            if d < bestDist then bestDist = d; best = {npc=npc, part=part, vp=vp} end
        end
    end

    return best
end

-- ══════════════════════════════════════════════════════════════
-- AIMBOT
-- ══════════════════════════════════════════════════════════════
local aimbotConn
local function startAimbot()
    if aimbotConn then aimbotConn:Disconnect() end
    aimbotConn = RunService.Heartbeat:Connect(function()
        if not CFG.AimbotEnabled then return end
        local keyHeld = false
        if CFG.AimbotKey == "RMB" then
            keyHeld = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        elseif CFG.AimbotKey == "LMB" then
            keyHeld = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
        elseif CFG.AimbotKey == "Q" then
            keyHeld = UserInputService:IsKeyDown(Enum.KeyCode.Q)
        elseif CFG.AimbotKey == "E" then
            keyHeld = UserInputService:IsKeyDown(Enum.KeyCode.E)
        end
        if not keyHeld and not CFG.AimLock then return end
        local t = getAimTarget()
        if not t then return end
        local part = t.part
        local root = t.player and getRoot(t.player)
        local vel  = root and root.AssemblyLinearVelocity or Vector3.zero
        local pred = part.Position + vel * CFG.PredictionVal
        local vp, on = Camera:WorldToViewportPoint(pred)
        if not on then return end
        local smooth = CFG.AimSmooth
        local dx = (vp.X - Mouse.X) * (1 - smooth)
        local dy = (vp.Y - Mouse.Y) * (1 - smooth)
        if mousemoverel then
            mousemoverel(dx, dy)
        end
        -- Auto shoot
        if CFG.AutoShoot then
            local d = Vector2.new(vp.X - Mouse.X, vp.Y - Mouse.Y).Magnitude
            if d < 8 then
                mouse1click()
            end
        end
    end)
end
startAimbot()

-- ══════════════════════════════════════════════════════════════
-- TRIGGERBOT
-- ══════════════════════════════════════════════════════════════
local triggerConn
local function startTrigger()
    if triggerConn then triggerConn:Disconnect() end
    triggerConn = RunService.Heartbeat:Connect(function()
        if not CFG.TriggerBot then return end
        local unitRay = Camera:ScreenPointToRay(Mouse.X, Mouse.Y)
        local ray = Ray.new(unitRay.Origin, unitRay.Direction * 999)
        local hit = workspace:FindPartOnRayWithIgnoreList(ray, {LP.Character})
        if not hit then return end
        local p = Players:GetPlayerFromCharacter(hit.Parent)
        if not p or p == LP then return end
        if CFG.TeamCheck and sameTeam(p) then return end
        if not isAlive(p) then return end
        task.wait(CFG.TriggerDelay)
        if mouse1click then mouse1click() end
    end)
end
startTrigger()

-- ══════════════════════════════════════════════════════════════
-- SILENT AIM
-- ══════════════════════════════════════════════════════════════
local silentHooked = false
local function hookSilent()
    if silentHooked then return end
    silentHooked = true
    local ok = pcall(function()
        local mt = getrawmetatable(game)
        local oldNI = mt.__newindex
        setreadonly(mt, false)
        mt.__newindex = function(t, k, v)
            if CFG.SilentAim and t == Mouse and k == "Hit" then
                local tgt = getAimTarget()
                if tgt and tgt.part then
                    return oldNI(t, k, CFrame.new(tgt.part.Position))
                end
            end
            return oldNI(t, k, v)
        end
        setreadonly(mt, true)
    end)
    if not ok then silentHooked = false end
end
hookSilent()

-- ══════════════════════════════════════════════════════════════
-- GOD MODE
-- ══════════════════════════════════════════════════════════════
local godConn
local function startGod()
    if godConn then godConn:Disconnect() end
    godConn = RunService.Heartbeat:Connect(function()
        if not CFG.GodMode then return end
        local hum = getHum(LP)
        if hum then
            hum.Health = hum.MaxHealth
        end
    end)
end
startGod()

-- ══════════════════════════════════════════════════════════════
-- NOCLIP
-- ══════════════════════════════════════════════════════════════
local noclipConn
local function startNoclip()
    if noclipConn then noclipConn:Disconnect() end
    noclipConn = RunService.Stepped:Connect(function()
        if not CFG.NoClip then return end
        local char = LP.Character
        if not char then return end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end)
end
startNoclip()

-- ══════════════════════════════════════════════════════════════
-- SPEED
-- ══════════════════════════════════════════════════════════════
local speedConn
local function startSpeed()
    if speedConn then speedConn:Disconnect() end
    speedConn = RunService.Heartbeat:Connect(function()
        if not CFG.SpeedEnabled then return end
        local hum = getHum(LP)
        if hum then hum.WalkSpeed = CFG.SpeedValue end
    end)
end
startSpeed()

-- ══════════════════════════════════════════════════════════════
-- JUMP
-- ══════════════════════════════════════════════════════════════
local jumpConn
local function startJump()
    if jumpConn then jumpConn:Disconnect() end
    jumpConn = RunService.Heartbeat:Connect(function()
        if not CFG.JumpEnabled then return end
        local hum = getHum(LP)
        if hum then hum.JumpPower = CFG.JumpValue end
    end)
end
startJump()

-- Infinite jump
UserInputService.JumpRequest:Connect(function()
    if not CFG.InfJump then return end
    local hum = getHum(LP)
    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

-- Bunny hop
local bhopConn
local function startBhop()
    if bhopConn then bhopConn:Disconnect() end
    bhopConn = RunService.Heartbeat:Connect(function()
        if not CFG.BunnyHop then return end
        local hum = getHum(LP)
        if not hum then return end
        if hum:GetState() == Enum.HumanoidStateType.Landed then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end
startBhop()

-- ══════════════════════════════════════════════════════════════
-- FLY
-- ══════════════════════════════════════════════════════════════
local flyConn, flyBV, flyBG
local function startFly()
    if flyConn then flyConn:Disconnect() end
    if not CFG.FlyEnabled then
        if flyBV then pcall(function() flyBV:Destroy() end) end
        if flyBG then pcall(function() flyBG:Destroy() end) end
        flyBV, flyBG = nil, nil
        return
    end
    local root = getRoot(LP)
    if not root then return end
    pcall(function()
        if flyBG then flyBG:Destroy() end
        if flyBV then flyBV:Destroy() end
        flyBG = Instance.new("BodyGyro", root)
        flyBG.P = 9e4; flyBG.MaxTorque = Vector3.new(9e9,9e9,9e9)
        flyBV = Instance.new("BodyVelocity", root)
        flyBV.Velocity = Vector3.zero; flyBV.MaxForce = Vector3.new(9e9,9e9,9e9)
    end)
    flyConn = RunService.Heartbeat:Connect(function()
        if not CFG.FlyEnabled or not flyBV then return end
        local cf = Camera.CFrame
        local vel = Vector3.zero
        local spd = CFG.FlySpeed
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then vel += cf.LookVector * spd end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then vel -= cf.LookVector * spd end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then vel -= cf.RightVector * spd end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then vel += cf.RightVector * spd end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vel += Vector3.new(0,spd,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then vel -= Vector3.new(0,spd,0) end
        flyBV.Velocity = vel
        if flyBG then flyBG.CFrame = cf end
    end)
end

-- ══════════════════════════════════════════════════════════════
-- FULLBRIGHT / NIGHT VISION / NO FOG
-- ══════════════════════════════════════════════════════════════
local origAmb, origBrightness, origFogEnd
local function applyVisualMods()
    local lighting = game:GetService("Lighting")
    if CFG.FullBright or CFG.NightVision then
        if not origAmb then
            origAmb = lighting.Ambient
            origBrightness = lighting.Brightness
        end
        lighting.Ambient = Color3.new(1,1,1)
        lighting.Brightness = 2
    else
        if origAmb then
            lighting.Ambient = origAmb
            lighting.Brightness = origBrightness
            origAmb = nil
        end
    end
    if CFG.NoFog then
        if not origFogEnd then origFogEnd = lighting.FogEnd end
        lighting.FogEnd = 9e9
    else
        if origFogEnd then lighting.FogEnd = origFogEnd; origFogEnd = nil end
    end
end

-- ══════════════════════════════════════════════════════════════
-- INF STAMINA (SD specific — hook stamina attribute)
-- ══════════════════════════════════════════════════════════════
local staminaConn
local function startStamina()
    if staminaConn then staminaConn:Disconnect() end
    staminaConn = RunService.Heartbeat:Connect(function()
        if not CFG.InfStamina then return end
        local char = LP.Character
        if not char then return end
        -- SD stores stamina as an attribute or a NumberValue
        local sv = char:FindFirstChild("Stamina") or char:FindFirstChild("Sprint")
        if sv and sv:IsA("NumberValue") then sv.Value = sv.Value > 10 and sv.Value or 100 end
        -- also try attribute
        pcall(function()
            if char:GetAttribute("Stamina") ~= nil then
                char:SetAttribute("Stamina", 100)
            end
        end)
    end)
end
startStamina()

-- ══════════════════════════════════════════════════════════════
-- ANTI-AFK
-- ══════════════════════════════════════════════════════════════
LP.Idled:Connect(function()
    if CFG.AntiAFK then
        VirtualUser:Button2Down(Vector2.new(0,0), Camera.CFrame)
        task.wait(0.1)
        VirtualUser:Button2Up(Vector2.new(0,0), Camera.CFrame)
    end
end)

-- ══════════════════════════════════════════════════════════════
-- AUTO RESPAWN
-- ══════════════════════════════════════════════════════════════
LP.CharacterRemoving:Connect(function()
    if CFG.AutoRespawn then
        task.wait(1)
        LP:LoadCharacter()
    end
end)

-- ══════════════════════════════════════════════════════════════
-- ESP SYSTEM — UPGRADED
-- ══════════════════════════════════════════════════════════════
local ESPPool = {}

local function newDraw(type, props)
    local d = Drawing.new(type)
    for k,v in pairs(props) do d[k]=v end
    return d
end

local function removeESP(key)
    if ESPPool[key] then
        for _, d in pairs(ESPPool[key]) do pcall(function() d:Remove() end) end
        ESPPool[key] = nil
    end
end

local function createPlayerESP(p)
    removeESP(p)
    ESPPool[p] = {
        BoxTL   = newDraw("Line",{Thickness=1.5,Visible=false}),
        BoxTR   = newDraw("Line",{Thickness=1.5,Visible=false}),
        BoxBL   = newDraw("Line",{Thickness=1.5,Visible=false}),
        BoxBR   = newDraw("Line",{Thickness=1.5,Visible=false}),
        BoxTT   = newDraw("Line",{Thickness=1.5,Visible=false}),
        BoxBB   = newDraw("Line",{Thickness=1.5,Visible=false}),
        BoxLL   = newDraw("Line",{Thickness=1.5,Visible=false}),
        BoxRR   = newDraw("Line",{Thickness=1.5,Visible=false}),
        Name    = newDraw("Text",{Size=13,Center=true,Outline=true,Visible=false,Font=Drawing.Fonts.Plex}),
        Dist    = newDraw("Text",{Size=11,Center=true,Outline=true,Visible=false,Font=Drawing.Fonts.Plex}),
        Health  = newDraw("Text",{Size=11,Center=true,Outline=true,Visible=false,Font=Drawing.Fonts.Plex}),
        HBarBG  = newDraw("Square",{Filled=true,Visible=false,Color=Color3.fromRGB(20,20,20)}),
        HBarFG  = newDraw("Square",{Filled=true,Visible=false}),
        Tracer  = newDraw("Line",{Thickness=1,Visible=false}),
        -- skeleton lines (SD has HumanoidRootPart + UpperTorso + Head)
        SkHead  = newDraw("Line",{Thickness=1,Visible=false,Color=Color3.fromRGB(255,255,100)}),
        SkTorso = newDraw("Line",{Thickness=1,Visible=false,Color=Color3.fromRGB(255,255,100)}),
        SkLArm  = newDraw("Line",{Thickness=1,Visible=false,Color=Color3.fromRGB(255,255,100)}),
        SkRArm  = newDraw("Line",{Thickness=1,Visible=false,Color=Color3.fromRGB(255,255,100)}),
        SkLLeg  = newDraw("Line",{Thickness=1,Visible=false,Color=Color3.fromRGB(255,255,100)}),
        SkRLeg  = newDraw("Line",{Thickness=1,Visible=false,Color=Color3.fromRGB(255,255,100)}),
    }
end

local function hideESP(e)
    for _, d in pairs(e) do pcall(function() d.Visible = false end) end
end

local function drawCornerBox(e, x, y, w, h, color)
    local cw = w * 0.25
    local ch = h * 0.25
    -- Top-left corner
    e.BoxTL.From=Vector2.new(x,y);       e.BoxTL.To=Vector2.new(x+cw,y);    e.BoxTL.Color=color; e.BoxTL.Visible=true
    e.BoxTT.From=Vector2.new(x,y);       e.BoxTT.To=Vector2.new(x,y+ch);    e.BoxTT.Color=color; e.BoxTT.Visible=true
    -- Top-right
    e.BoxTR.From=Vector2.new(x+w,y);     e.BoxTR.To=Vector2.new(x+w-cw,y);  e.BoxTR.Color=color; e.BoxTR.Visible=true
    e.BoxBB.From=Vector2.new(x+w,y);     e.BoxBB.To=Vector2.new(x+w,y+ch);  e.BoxBB.Color=color; e.BoxBB.Visible=true
    -- Bottom-left
    e.BoxBL.From=Vector2.new(x,y+h);     e.BoxBL.To=Vector2.new(x+cw,y+h);  e.BoxBL.Color=color; e.BoxBL.Visible=true
    e.BoxLL.From=Vector2.new(x,y+h);     e.BoxLL.To=Vector2.new(x,y+h-ch);  e.BoxLL.Color=color; e.BoxLL.Visible=true
    -- Bottom-right
    e.BoxBR.From=Vector2.new(x+w,y+h);  e.BoxBR.To=Vector2.new(x+w-cw,y+h);e.BoxBR.Color=color; e.BoxBR.Visible=true
    e.BoxRR.From=Vector2.new(x+w,y+h);  e.BoxRR.To=Vector2.new(x+w,y+h-ch);e.BoxRR.Color=color; e.BoxRR.Visible=true
end

local function hideCornerBox(e)
    e.BoxTL.Visible=false; e.BoxTR.Visible=false; e.BoxBL.Visible=false; e.BoxBR.Visible=false
    e.BoxTT.Visible=false; e.BoxBB.Visible=false; e.BoxLL.Visible=false; e.BoxRR.Visible=false
end

local espConn
local function startESP()
    if espConn then espConn:Disconnect() end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then createPlayerESP(p) end
    end
    Players.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function() task.wait(0.5); createPlayerESP(p) end)
    end)
    Players.PlayerRemoving:Connect(function(p) removeESP(p) end)

    espConn = RunService.Heartbeat:Connect(function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LP then continue end
            local e = ESPPool[p]
            if not e then createPlayerESP(p); continue end

            local char = getChar(p)
            local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
            local hum  = getHum(p)
            local head = char and char:FindFirstChild("Head")

            local vis = CFG.ESPEnabled and root ~= nil and isAlive(p)
            if CFG.TeamCheck and sameTeam(p) then vis = false end

            if vis then
                local rootVP, onScreen, depth = w2v(root.Position)
                local d3 = (root.Position - Camera.CFrame.Position).Magnitude
                if not onScreen or depth < 0 or d3 > CFG.MaxESPDist then
                    hideESP(e); continue
                end

                -- color
                local color
                if CFG.ESPTeamColor then
                    color = sameTeam(p) and CFG.ESPFriendColor or CFG.ESPEnemyColor
                else
                    color = getAccent()
                end

                -- box
                if CFG.ESPBoxes and head then
                    local headVP = w2v(head.Position + Vector3.new(0,0.7,0))
                    local h = math.abs(headVP.Y - rootVP.Y) * 2.1
                    local w = h * 0.55
                    local x = rootVP.X - w/2
                    local y = headVP.Y
                    drawCornerBox(e, x, y, w, h, color)
                    -- health bar
                    if CFG.ESPHealthBar and hum then
                        local hp  = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                        local bx  = x - 7
                        e.HBarBG.Position = Vector2.new(bx,y)
                        e.HBarBG.Size = Vector2.new(4, h)
                        e.HBarBG.Visible = true
                        local hpColor = colorLerp(CLR.Red, CLR.Green, hp)
                        e.HBarFG.Position = Vector2.new(bx, y + h*(1-hp))
                        e.HBarFG.Size = Vector2.new(4, h*hp)
                        e.HBarFG.Color = hpColor
                        e.HBarFG.Visible = true
                    else
                        e.HBarBG.Visible=false; e.HBarFG.Visible=false
                    end
                else
                    hideCornerBox(e); e.HBarBG.Visible=false; e.HBarFG.Visible=false
                end

                -- name
                if CFG.ESPNames and head then
                    local hVP = w2v(head.Position + Vector3.new(0,1.3,0))
                    e.Name.Position = Vector2.new(hVP.X, hVP.Y)
                    e.Name.Text = p.DisplayName
                    e.Name.Color = color; e.Name.Visible = true
                else e.Name.Visible = false end

                -- distance
                if CFG.ESPDistance then
                    local bVP = w2v(root.Position + Vector3.new(0,-3.5,0))
                    e.Dist.Position = Vector2.new(bVP.X, bVP.Y)
                    e.Dist.Text = math.floor(d3).."m"
                    e.Dist.Color = CLR.SubText; e.Dist.Visible = true
                else e.Dist.Visible = false end

                -- health text
                if CFG.ESPHealth and hum then
                    local bVP2 = w2v(root.Position + Vector3.new(0,-5,0))
                    local hp = math.floor(hum.Health)
                    local hpColor = colorLerp(CLR.Red, CLR.Green, hum.Health/hum.MaxHealth)
                    e.Health.Position = Vector2.new(bVP2.X, bVP2.Y)
                    e.Health.Text = hp.."❤"
                    e.Health.Color = hpColor; e.Health.Visible = true
                else e.Health.Visible = false end

                -- tracer
                if CFG.ESPTracers then
                    local fromY = CFG.ESPTracerOrigin == "Top" and 0
                        or CFG.ESPTracerOrigin == "Center" and Camera.ViewportSize.Y/2
                        or Camera.ViewportSize.Y
                    e.Tracer.From = Vector2.new(Camera.ViewportSize.X/2, fromY)
                    e.Tracer.To   = rootVP
                    e.Tracer.Color= color; e.Tracer.Visible = true
                else e.Tracer.Visible = false end

                -- skeleton (SD R6/R15)
                if CFG.ESPSkeleton and char then
                    local function sk(e_line, a_name, b_name)
                        local a = char:FindFirstChild(a_name)
                        local b = char:FindFirstChild(b_name)
                        if a and b then
                            local av = w2v(a.Position)
                            local bv = w2v(b.Position)
                            e_line.From=av; e_line.To=bv; e_line.Visible=true
                        else e_line.Visible=false end
                    end
                    sk(e.SkHead,  "Head",       "UpperTorso")
                    sk(e.SkTorso, "UpperTorso", "LowerTorso")
                    sk(e.SkLArm,  "UpperTorso", "LeftUpperArm")
                    sk(e.SkRArm,  "UpperTorso", "RightUpperArm")
                    sk(e.SkLLeg,  "LowerTorso", "LeftUpperLeg")
                    sk(e.SkRLeg,  "LowerTorso", "RightUpperLeg")
                else
                    e.SkHead.Visible=false; e.SkTorso.Visible=false
                    e.SkLArm.Visible=false; e.SkRArm.Visible=false
                    e.SkLLeg.Visible=false; e.SkRLeg.Visible=false
                end
            else
                hideESP(e)
            end
        end
    end)
end
startESP()

-- ══════════════════════════════════════════════════════════════
-- FOV CIRCLE
-- ══════════════════════════════════════════════════════════════
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1; fovCircle.NumSides = 64
fovCircle.Filled = false; fovCircle.Visible = false
RunService.Heartbeat:Connect(function()
    if CFG.ShowFOVCircle and (CFG.AimbotEnabled or CFG.SilentAim) then
        fovCircle.Radius = CFG.AimFOV
        fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        fovCircle.Color = getAccent()
        fovCircle.Visible = true
    else
        fovCircle.Visible = false
    end
end)

-- ══════════════════════════════════════════════════════════════
-- SD CROSSHAIR
-- ══════════════════════════════════════════════════════════════
local crosshairLines = {
    Drawing.new("Line"), Drawing.new("Line"),
    Drawing.new("Line"), Drawing.new("Line"),
}
for _, l in ipairs(crosshairLines) do l.Thickness=1.5; l.Visible=false end

RunService.Heartbeat:Connect(function()
    local cx = Camera.ViewportSize.X/2
    local cy = Camera.ViewportSize.Y/2
    local s  = CFG.SDCrosshairSize
    local c  = CFG.SDCrosshairColor
    local vis= CFG.SDCrosshair
    -- horizontal
    crosshairLines[1].From=Vector2.new(cx-s,cy); crosshairLines[1].To=Vector2.new(cx-3,cy)
    crosshairLines[2].From=Vector2.new(cx+3,cy); crosshairLines[2].To=Vector2.new(cx+s,cy)
    -- vertical
    crosshairLines[3].From=Vector2.new(cx,cy-s); crosshairLines[3].To=Vector2.new(cx,cy-3)
    crosshairLines[4].From=Vector2.new(cx,cy+3); crosshairLines[4].To=Vector2.new(cx,cy+s)
    for _, l in ipairs(crosshairLines) do l.Color=c; l.Visible=vis end
end)

-- ══════════════════════════════════════════════════════════════
-- SD MINI RADAR
-- ══════════════════════════════════════════════════════════════
-- drawn via Drawing, bottom-right corner
local RADAR_SIZE = 160
local RADAR_RANGE = 200
local radarDots = {}

local radarBG   = newDraw("Square",{Filled=true,Color=Color3.fromRGB(5,5,10),Visible=false,ZIndex=1})
local radarBord = newDraw("Square",{Filled=false,Thickness=1.5,Visible=false})
local radarLine = newDraw("Line",{Thickness=1,Visible=false,Color=Color3.fromRGB(0,100,50)})
local radarLine2= newDraw("Line",{Thickness=1,Visible=false,Color=Color3.fromRGB(0,100,50)})
local radarSelf = newDraw("Triangle",{Filled=true,Color=Color3.fromRGB(0,220,255),Visible=false})

local function getRadarPos()
    local vp = Camera.ViewportSize
    return Vector2.new(vp.X - RADAR_SIZE - 10, vp.Y - RADAR_SIZE - 10)
end

RunService.Heartbeat:Connect(function()
    if not CFG.SDRadarEnabled then
        radarBG.Visible=false; radarBord.Visible=false
        radarLine.Visible=false; radarLine2.Visible=false; radarSelf.Visible=false
        for _, d in pairs(radarDots) do d.Visible=false end
        return
    end
    local rp = getRadarPos()
    local cx = rp.X + RADAR_SIZE/2
    local cy = rp.Y + RADAR_SIZE/2
    local accentColor = getAccent()

    radarBG.Position=rp; radarBG.Size=Vector2.new(RADAR_SIZE,RADAR_SIZE); radarBG.Visible=true
    radarBord.Position=rp; radarBord.Size=Vector2.new(RADAR_SIZE,RADAR_SIZE); radarBord.Color=accentColor; radarBord.Visible=true
    radarLine.From=Vector2.new(cx,rp.Y); radarLine.To=Vector2.new(cx,rp.Y+RADAR_SIZE); radarLine.Visible=true
    radarLine2.From=Vector2.new(rp.X,cy); radarLine2.To=Vector2.new(rp.X+RADAR_SIZE,cy); radarLine2.Visible=true

    -- self dot (triangle pointing forward)
    local half = RADAR_SIZE/2
    radarSelf.PointA=Vector2.new(cx,cy-5)
    radarSelf.PointB=Vector2.new(cx-4,cy+4)
    radarSelf.PointC=Vector2.new(cx+4,cy+4)
    radarSelf.Visible=true

    local myRoot = getRoot(LP)
    local myCF   = Camera.CFrame

    for i, p in ipairs(Players:GetPlayers()) do
        if p == LP then continue end
        if not radarDots[i] then
            radarDots[i] = newDraw("Square",{Filled=true,Size=Vector2.new(5,5),Visible=false})
        end
        local dot = radarDots[i]
        local root = getRoot(p)
        if not root or not isAlive(p) then dot.Visible=false; continue end

        local relPos = myCF:PointToObjectSpace(root.Position)
        local rx = relPos.X / RADAR_RANGE * half
        local ry = -relPos.Z / RADAR_RANGE * half
        rx = math.clamp(rx, -half+4, half-4)
        ry = math.clamp(ry, -half+4, half-4)

        local color = sameTeam(p) and CFG.ESPFriendColor or CFG.ESPEnemyColor
        dot.Position = Vector2.new(cx+rx-2, cy+ry-2)
        dot.Color = color; dot.Visible = true
    end
    -- clear excess
    for i = #Players:GetPlayers()+1, #radarDots do
        if radarDots[i] then radarDots[i].Visible=false end
    end
end)

-- ══════════════════════════════════════════════════════════════
-- GUI FRAMEWORK — UPGRADED UI
-- ══════════════════════════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AngelHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true

pcall(function()
    if syn and syn.protect_gui then
        syn.protect_gui(ScreenGui); ScreenGui.Parent = game.CoreGui
    elseif gethui then
        ScreenGui.Parent = gethui()
    else
        ScreenGui.Parent = game.CoreGui
    end
end)
if not ScreenGui.Parent then ScreenGui.Parent = LP:WaitForChild("PlayerGui") end

local function mk(cls, props, parent)
    local i = Instance.new(cls)
    for k,v in pairs(props) do i[k]=v end
    if parent then i.Parent=parent end
    return i
end
local function cr(r, p) return mk("UICorner",{CornerRadius=UDim.new(0,r)},p) end
local function st(t,c,p) return mk("UIStroke",{Thickness=t,Color=c,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},p) end
local function grd(p, c1, c2, rot)
    local g = mk("UIGradient",{Color=ColorSequence.new(c1,c2), Rotation=rot or 90},p)
    return g
end

-- ── MAIN WINDOW ──────────────────────────────────────────────
local Main = mk("Frame",{
    Name="Main", Size=UDim2.new(0,680,0,480),
    Position=UDim2.new(0.5,-340,0.5,-240),
    BackgroundColor3=CLR.BG, BorderSizePixel=0, ClipsDescendants=false,
}, ScreenGui)
cr(14, Main)
st(1.5, Color3.fromRGB(0,180,220), Main)

-- glow effect frame behind main
local Glow = mk("Frame",{
    Size=UDim2.new(1,30,1,30), Position=UDim2.new(0,-15,0,-15),
    BackgroundColor3=Color3.fromRGB(0,100,140), BackgroundTransparency=0.85,
    BorderSizePixel=0, ZIndex=0,
}, Main)
cr(20, Glow)

-- inner clip
local InnerClip = mk("Frame",{
    Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, ClipsDescendants=true,
}, Main)

-- ── TOP BAR ──────────────────────────────────────────────────
local TopBar = mk("Frame",{
    Size=UDim2.new(1,0,0,46), BackgroundColor3=CLR.Sidebar, BorderSizePixel=0,
}, InnerClip)
cr(14, TopBar)
-- bottom fill to square off bottom of topbar
mk("Frame",{Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,1,-14),BackgroundColor3=CLR.Sidebar,BorderSizePixel=0},TopBar)

-- logo area
local LogoFrame = mk("Frame",{
    Size=UDim2.new(0,180,1,0), BackgroundTransparency=1,
}, TopBar)

-- Diamond icon (layered for glow)
local DiamondOuter = mk("Frame",{
    Size=UDim2.new(0,26,0,26), Position=UDim2.new(0,14,0.5,-13),
    BackgroundColor3=Color3.fromRGB(0,180,220), BackgroundTransparency=0.5,
    BorderSizePixel=0, Rotation=45,
}, LogoFrame)
cr(4, DiamondOuter)
local DiamondInner = mk("Frame",{
    Size=UDim2.new(0,18,0,18), Position=UDim2.new(0.5,-9,0.5,-9),
    BackgroundColor3=Color3.fromRGB(0,220,255), BorderSizePixel=0, Rotation=0,
}, DiamondOuter)
cr(3, DiamondInner)

mk("TextLabel",{
    Size=UDim2.new(0,120,0,22), Position=UDim2.new(0,46,0.5,-12),
    Text="AngelHub", Font=FONT, TextColor3=CLR.Text, TextSize=20,
    BackgroundTransparency=1,
}, LogoFrame)
mk("TextLabel",{
    Size=UDim2.new(0,60,0,14), Position=UDim2.new(0,46,0.5,8),
    Text=VERSION.." • SD", Font=FONT_REG, TextColor3=getAccent(), TextSize=10,
    BackgroundTransparency=1,
}, LogoFrame)

-- Discord copy button (top bar, center)
local DiscordBtn = mk("TextButton",{
    Size=UDim2.new(0,130,0,26), Position=UDim2.new(0.5,-65,0.5,-13),
    Text="⬡  discord.gg/d8gpXNGknP", Font=FONT_REG,
    TextColor3=Color3.fromRGB(0,220,255), TextSize=10,
    BackgroundColor3=Color3.fromRGB(14,20,40),
}, TopBar)
cr(8, DiscordBtn)
st(1, Color3.fromRGB(0,100,160), DiscordBtn)
DiscordBtn.MouseButton1Click:Connect(function()
    clip(DISCORD)
    DiscordBtn.Text = "✓  Copied to clipboard!"
    DiscordBtn.TextColor3 = CLR.Green
    task.wait(2)
    DiscordBtn.Text = "⬡  discord.gg/d8gpXNGknP"
    DiscordBtn.TextColor3 = Color3.fromRGB(0,220,255)
end)

-- Right controls
local CloseBtn = mk("TextButton",{
    Size=UDim2.new(0,30,0,30), Position=UDim2.new(1,-38,0.5,-15),
    Text="✕", Font=FONT, TextColor3=CLR.White, TextSize=14,
    BackgroundColor3=Color3.fromRGB(180,40,40),
}, TopBar)
cr(8, CloseBtn)
CloseBtn.MouseButton1Click:Connect(function() Main.Visible = false end)

local MinBtn = mk("TextButton",{
    Size=UDim2.new(0,30,0,30), Position=UDim2.new(1,-74,0.5,-15),
    Text="—", Font=FONT, TextColor3=CLR.White, TextSize=12,
    BackgroundColor3=Color3.fromRGB(50,50,70),
}, TopBar)
cr(8, MinBtn)
local minimized = false
local contentArea
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if contentArea then contentArea.Visible = not minimized end
    Main.Size = minimized and UDim2.new(0,680,0,46) or UDim2.new(0,680,0,480)
end)

-- Float button (mobile)
local FloatBtn = mk("TextButton",{
    Size=UDim2.new(0,50,0,50), Position=UDim2.new(0,16,0.5,-25),
    Text="✦", Font=FONT, TextColor3=CLR.BG, TextSize=20,
    BackgroundColor3=Color3.fromRGB(0,220,255), ZIndex=20, Visible=true,
}, ScreenGui)
cr(25, FloatBtn)
st(2, Color3.fromRGB(0,140,170), FloatBtn)

-- glow on float
local fbGlow = mk("Frame",{
    Size=UDim2.new(1,16,1,16),Position=UDim2.new(0,-8,0,-8),
    BackgroundColor3=Color3.fromRGB(0,180,220),BackgroundTransparency=0.75,
    BorderSizePixel=0, ZIndex=19,
},FloatBtn)
cr(30, fbGlow)

FloatBtn.MouseButton1Click:Connect(function() Main.Visible = not Main.Visible end)

-- Drag
local dragging, dragStart, startPos2 = false
TopBar.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        dragging=true; dragStart=inp.Position; startPos2=Main.Position
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if dragging and (inp.UserInputType==Enum.UserInputType.MouseMovement
        or inp.UserInputType==Enum.UserInputType.Touch) then
        local d = inp.Position - dragStart
        Main.Position = UDim2.new(startPos2.X.Scale,startPos2.X.Offset+d.X,startPos2.Y.Scale,startPos2.Y.Offset+d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1
    or inp.UserInputType==Enum.UserInputType.Touch then dragging=false end
end)
UserInputService.InputBegan:Connect(function(inp,gp)
    if gp then return end
    if inp.KeyCode == CFG.KeybindOpen then Main.Visible = not Main.Visible end
end)

-- ── CONTENT AREA ─────────────────────────────────────────────
contentArea = mk("Frame",{
    Size=UDim2.new(1,0,1,-46), Position=UDim2.new(0,0,0,46),
    BackgroundTransparency=1, ClipsDescendants=true,
}, InnerClip)

-- ── SIDEBAR ───────────────────────────────────────────────────
local Sidebar = mk("Frame",{
    Size=UDim2.new(0,130,1,0), BackgroundColor3=CLR.Sidebar, BorderSizePixel=0,
}, contentArea)
mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,3)},Sidebar)
mk("UIPadding",{PaddingTop=UDim.new(0,10),PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8)},Sidebar)

-- right border on sidebar
mk("Frame",{
    Size=UDim2.new(0,1,1,0),Position=UDim2.new(1,0,0,0),
    BackgroundColor3=Color3.fromRGB(0,80,120),BorderSizePixel=0,
},Sidebar)

local Content = mk("Frame",{
    Size=UDim2.new(1,-130,1,0), Position=UDim2.new(0,130,0,0),
    BackgroundColor3=CLR.BG2, BorderSizePixel=0, ClipsDescendants=true,
}, contentArea)

local Pages = {}
local TabBtns = {}

local function switchTab(name)
    for n,f in pairs(Pages) do f.Visible=(n==name) end
    for n,b in pairs(TabBtns) do
        local ac = b:FindFirstChild("Accent")
        local ic = b:FindFirstChild("Icon")
        local tx = b:FindFirstChild("Label")
        if ac then ac.Visible=(n==name) end
        b.BackgroundColor3 = (n==name) and CLR.Card or CLR.Sidebar
        b.BackgroundTransparency = (n==name) and 0 or 1
        if tx then tx.TextColor3 = (n==name) and CLR.Text or CLR.SubText end
        if ic then ic.TextColor3 = (n==name) and getAccent() or CLR.Muted end
    end
end

local function makeTab(name, icon, order)
    local btn = mk("TextButton",{
        Size=UDim2.new(1,0,0,38), BackgroundColor3=CLR.Sidebar,
        BackgroundTransparency=1, BorderSizePixel=0, Text="", LayoutOrder=order,
    }, Sidebar)
    cr(8, btn)

    local ac = mk("Frame",{
        Name="Accent", Size=UDim2.new(0,3,0.65,0), Position=UDim2.new(0,0,0.175,0),
        BackgroundColor3=getAccent(), Visible=false, BorderSizePixel=0,
    }, btn)
    cr(2,ac)

    mk("TextLabel",{
        Name="Icon", Size=UDim2.new(0,24,1,0), Position=UDim2.new(0,10,0,0),
        Text=icon, Font=FONT_REG, TextColor3=CLR.Muted, TextSize=15,
        BackgroundTransparency=1,
    }, btn)
    mk("TextLabel",{
        Name="Label", Size=UDim2.new(1,-38,1,0), Position=UDim2.new(0,36,0,0),
        Text=name, Font=FONT_REG, TextColor3=CLR.SubText, TextSize=12,
        BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left,
    }, btn)

    btn.MouseButton1Click:Connect(function() switchTab(name) end)
    TabBtns[name] = btn

    local page = mk("ScrollingFrame",{
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
        ScrollBarThickness=3, ScrollBarImageColor3=getAccent(),
        BorderSizePixel=0, Visible=false,
        CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y,
        ScrollingDirection=Enum.ScrollingDirection.Y,
    }, Content)
    mk("UIPadding",{PaddingTop=UDim.new(0,12),PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,14),PaddingBottom=UDim.new(0,12)},page)
    mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,6)},page)
    Pages[name] = page
    return page
end

-- ══════════════════════════════════════════════════════════════
-- WIDGETS v2
-- ══════════════════════════════════════════════════════════════
local widgetOrder = {}
local function nextOrder(page)
    widgetOrder[page] = (widgetOrder[page] or 0) + 1
    return widgetOrder[page]
end

local function section(text, page)
    local o = nextOrder(page)
    local f = mk("Frame",{
        Size=UDim2.new(1,0,0,28), BackgroundTransparency=1, LayoutOrder=o,
    }, page)
    local line = mk("Frame",{
        Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,0.5,0),
        BackgroundColor3=Color3.fromRGB(0,80,120), BorderSizePixel=0,
    }, f)
    mk("TextLabel",{
        Size=UDim2.new(0,0,1,0), AutomaticSize=Enum.AutomaticSize.X,
        Position=UDim2.new(0,0,0,0),
        Text=" "..text.." ", Font=FONT, TextColor3=getAccent(), TextSize=10,
        BackgroundColor3=CLR.BG2, BorderSizePixel=0,
    }, f)
end

local function toggle(label, cfgKey, page, cb)
    local o = nextOrder(page)
    local row = mk("Frame",{
        Size=UDim2.new(1,0,0,36), BackgroundColor3=CLR.Card, BorderSizePixel=0, LayoutOrder=o,
    }, page)
    cr(8, row)

    mk("TextLabel",{
        Size=UDim2.new(1,-58,1,0), Position=UDim2.new(0,12,0,0),
        Text=label, Font=FONT_REG, TextColor3=CLR.Text, TextSize=12,
        BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left,
    }, row)

    local bg = mk("Frame",{
        Size=UDim2.new(0,42,0,22), Position=UDim2.new(1,-50,0.5,-11),
        BackgroundColor3=CFG[cfgKey] and getAccent() or CLR.Muted, BorderSizePixel=0,
    }, row)
    cr(11, bg)

    local knob = mk("Frame",{
        Size=UDim2.new(0,16,0,16),
        Position=CFG[cfgKey] and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8),
        BackgroundColor3=CLR.White, BorderSizePixel=0,
    }, bg)
    cr(8, knob)
    -- knob shadow
    st(1, Color3.fromRGB(0,0,0), knob)

    local btn = mk("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text=""},bg)
    btn.MouseButton1Click:Connect(function()
        CFG[cfgKey] = not CFG[cfgKey]
        local on = CFG[cfgKey]
        TweenService:Create(bg,TweenInfo.new(0.18),{BackgroundColor3=on and getAccent() or CLR.Muted}):Play()
        TweenService:Create(knob,TweenInfo.new(0.18),{Position=on and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)}):Play()
        if cb then cb(on) end
    end)
    return row
end

local function slider(label, cfgKey, minV, maxV, page, fmt, cb)
    local o = nextOrder(page)
    local row = mk("Frame",{
        Size=UDim2.new(1,0,0,52), BackgroundColor3=CLR.Card, BorderSizePixel=0, LayoutOrder=o,
    }, page)
    cr(8, row)

    local valLabel = mk("TextLabel",{
        Size=UDim2.new(0,55,0,18), Position=UDim2.new(1,-63,0,8),
        Text=string.format(fmt or "%.0f", CFG[cfgKey]),
        Font=FONT_MONO, TextColor3=getAccent(), TextSize=11,
        BackgroundColor3=CLR.BG, BackgroundTransparency=0,
        TextXAlignment=Enum.TextXAlignment.Center,
    }, row)
    cr(4, valLabel)

    mk("TextLabel",{
        Size=UDim2.new(1,-70,0,18), Position=UDim2.new(0,12,0,8),
        Text=label, Font=FONT_REG, TextColor3=CLR.Text, TextSize=12,
        BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left,
    }, row)

    local track = mk("Frame",{
        Size=UDim2.new(1,-24,0,5), Position=UDim2.new(0,12,1,-17),
        BackgroundColor3=CLR.Muted, BorderSizePixel=0,
    }, row)
    cr(3, track)

    local pct = math.clamp((CFG[cfgKey]-minV)/(maxV-minV),0,1)
    local fill = mk("Frame",{Size=UDim2.new(pct,0,1,0),BackgroundColor3=getAccent(),BorderSizePixel=0},track)
    cr(3,fill)
    local thumb = mk("Frame",{
        Size=UDim2.new(0,14,0,14),Position=UDim2.new(pct,-7,0.5,-7),
        BackgroundColor3=CLR.White,BorderSizePixel=0,
    },track)
    cr(7,thumb)
    st(1.5,getAccent(),thumb)

    local sliding=false
    local function upd(ix)
        local t = math.clamp((ix-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
        local v = minV + t*(maxV-minV)
        CFG[cfgKey] = v
        fill.Size=UDim2.new(t,0,1,0)
        thumb.Position=UDim2.new(t,-7,0.5,-7)
        valLabel.Text=string.format(fmt or "%.0f",v)
        if cb then cb(v) end
    end
    local tb=mk("TextButton",{Size=UDim2.new(1,0,0,24),Position=UDim2.new(0,0,-1,0),BackgroundTransparency=1,Text=""},track)
    tb.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            sliding=true; upd(inp.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if sliding and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
            upd(inp.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then sliding=false end
    end)
end

local function dropdown(label, cfgKey, opts, page, cb)
    local o = nextOrder(page)
    local row = mk("Frame",{
        Size=UDim2.new(1,0,0,36), BackgroundColor3=CLR.Card,
        BorderSizePixel=0, LayoutOrder=o, ClipsDescendants=false, ZIndex=5,
    }, page)
    cr(8, row)

    mk("TextLabel",{
        Size=UDim2.new(0.5,0,1,0), Position=UDim2.new(0,12,0,0),
        Text=label, Font=FONT_REG, TextColor3=CLR.Text, TextSize=12,
        BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=5,
    }, row)

    local sel = mk("TextButton",{
        Size=UDim2.new(0.42,0,0,26), Position=UDim2.new(0.56,0,0.5,-13),
        Text=tostring(CFG[cfgKey]).." ▾", Font=FONT_REG,
        TextColor3=getAccent(), TextSize=11,
        BackgroundColor3=CLR.BG, ZIndex=5,
    }, row)
    cr(6, sel)
    st(1,Color3.fromRGB(0,80,120),sel)

    local dd = mk("Frame",{
        Size=UDim2.new(0.42,0,0,0), Position=UDim2.new(0.56,0,1,2),
        BackgroundColor3=CLR.BG2, BorderSizePixel=0, Visible=false, ZIndex=20,
        ClipsDescendants=true,
    }, row)
    cr(6,dd); st(1,getAccent(),dd)
    mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder},dd)

    for i,opt in ipairs(opts) do
        local ob = mk("TextButton",{
            Size=UDim2.new(1,0,0,28), Text="  "..opt, Font=FONT_REG,
            TextColor3=CLR.Text, TextSize=11, BackgroundTransparency=1,
            ZIndex=20, LayoutOrder=i, TextXAlignment=Enum.TextXAlignment.Left,
        }, dd)
        ob.MouseEnter:Connect(function() ob.BackgroundTransparency=0.85; ob.BackgroundColor3=getAccent() end)
        ob.MouseLeave:Connect(function() ob.BackgroundTransparency=1 end)
        ob.MouseButton1Click:Connect(function()
            CFG[cfgKey]=opt; sel.Text=opt.." ▾"
            dd.Visible=false; dd.Size=UDim2.new(0.42,0,0,0)
            if cb then cb(opt) end
        end)
    end
    sel.MouseButton1Click:Connect(function()
        dd.Visible = not dd.Visible
        local h = dd.Visible and (#opts*28) or 0
        TweenService:Create(dd,TweenInfo.new(0.14),{Size=UDim2.new(0.42,0,0,h)}):Play()
    end)
end

local function btn(label, page, cb, accent)
    local o = nextOrder(page)
    local b = mk("TextButton",{
        Size=UDim2.new(1,0,0,34), Text=label, Font=FONT_REG,
        TextColor3=accent and CLR.BG or CLR.Text, TextSize=12,
        BackgroundColor3=accent and getAccent() or CLR.Card,
        BorderSizePixel=0, LayoutOrder=o,
    }, page)
    cr(8,b)
    if not accent then st(1,Color3.fromRGB(0,80,120),b) end
    b.MouseButton1Click:Connect(cb)
    return b
end

local function lbl(text, page, color)
    local o = nextOrder(page)
    return mk("TextLabel",{
        Size=UDim2.new(1,0,0,22), Text=text, Font=FONT_REG,
        TextColor3=color or CLR.SubText, TextSize=11, BackgroundTransparency=1,
        TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=o,
    }, page)
end

local function colorDisplay(cfgKey, page)
    local o = nextOrder(page)
    local row = mk("Frame",{Size=UDim2.new(1,0,0,34),BackgroundColor3=CLR.Card,BorderSizePixel=0,LayoutOrder=o},page)
    cr(8,row)
    local swatch = mk("Frame",{
        Size=UDim2.new(0,22,0,22),Position=UDim2.new(1,-30,0.5,-11),
        BackgroundColor3=CFG[cfgKey],BorderSizePixel=0,
    },row)
    cr(5,swatch); st(1,CLR.Border,swatch)
    mk("TextLabel",{
        Size=UDim2.new(1,-40,1,0),Position=UDim2.new(0,12,0,0),
        Text="ESP Color (edit CFG.ESPColor in script)",Font=FONT_REG,
        TextColor3=CLR.SubText,TextSize=11,BackgroundTransparency=1,
        TextXAlignment=Enum.TextXAlignment.Left,
    },row)
end

-- ══════════════════════════════════════════════════════════════
-- BUILD TABS
-- ══════════════════════════════════════════════════════════════
local CombatPage   = makeTab("Combat",   "⊕", 1)
local VisualsPage  = makeTab("Visuals",  "◈", 2)
local MiscPage     = makeTab("Misc",     "⚙", 3)
local SDPage       = makeTab("San Diego","⬡", 4)
local SettingsPage = makeTab("Settings", "✦", 5)

-- ── COMBAT ───────────────────────────────────────────────────
section("AIMBOT", CombatPage)
toggle("Aimbot", "AimbotEnabled", CombatPage, startAimbot)
toggle("Silent Aim", "SilentAim", CombatPage)
toggle("Aim Lock (no key hold)", "AimLock", CombatPage)
toggle("Auto Shoot", "AutoShoot", CombatPage)
toggle("Triggerbot", "TriggerBot", CombatPage, startTrigger)
toggle("Target SD NPCs", "SDNPCTarget", CombatPage)
toggle("Show FOV Circle", "ShowFOVCircle", CombatPage)

section("AIM SETTINGS", CombatPage)
dropdown("Aim Key",   "AimbotKey",  {"RMB","LMB","Q","E"},  CombatPage)
dropdown("Aim Part",  "AimPart",    {"Head","UpperTorso","HumanoidRootPart","Neck","LowerTorso"}, CombatPage)
slider("FOV Radius",    "AimFOV",       10,  500, CombatPage, "%.0f px")
slider("Smooth",        "AimSmooth",    0.01,0.98,CombatPage, "%.2f")
slider("Prediction",    "PredictionVal",0,   0.5, CombatPage, "%.3f")
slider("Trigger Delay", "TriggerDelay", 0,   0.5, CombatPage, "%.2f s")

section("FILTERS", CombatPage)
toggle("Team Check",  "TeamCheck",  CombatPage)
toggle("Wall Check",  "WallCheck",  CombatPage)

-- ── VISUALS ──────────────────────────────────────────────────
section("ESP", VisualsPage)
toggle("ESP Enabled",  "ESPEnabled",  VisualsPage, startESP)
toggle("Boxes",        "ESPBoxes",    VisualsPage)
toggle("Names",        "ESPNames",    VisualsPage)
toggle("Health Text",  "ESPHealth",   VisualsPage)
toggle("Health Bar",   "ESPHealthBar",VisualsPage)
toggle("Distance",     "ESPDistance", VisualsPage)
toggle("Tracers",      "ESPTracers",  VisualsPage)
toggle("Skeleton",     "ESPSkeleton", VisualsPage)
toggle("Team Color",   "ESPTeamColor",VisualsPage)
toggle("NPC ESP",      "ESPNPCs",     VisualsPage)

section("ESP SETTINGS", VisualsPage)
dropdown("Box Style",      "ESPBoxStyle",    {"Corner","Full"},    VisualsPage)
dropdown("Tracer Origin",  "ESPTracerOrigin",{"Bottom","Center","Top"}, VisualsPage)
slider("Max Distance", "MaxESPDist", 50, 2000, VisualsPage, "%.0f m")
colorDisplay("ESPColor", VisualsPage)

section("WORLD", VisualsPage)
toggle("Fullbright",    "FullBright",   VisualsPage, function() applyVisualMods() end)
toggle("Night Vision",  "NightVision",  VisualsPage, function() applyVisualMods() end)
toggle("Remove Fog",    "NoFog",        VisualsPage, function() applyVisualMods() end)
toggle("SD Crosshair",  "SDCrosshair",  VisualsPage)
slider("Crosshair Size","SDCrosshairSize",4,30,VisualsPage,"%.0f")
toggle("Mini Radar",    "SDRadarEnabled",VisualsPage)

-- ── MISC ─────────────────────────────────────────────────────
section("MOVEMENT", MiscPage)
toggle("No Clip",      "NoClip",      MiscPage, startNoclip)
toggle("Speed Hack",   "SpeedEnabled",MiscPage, startSpeed)
slider("Walk Speed",   "SpeedValue",  16, 250, MiscPage, "%.0f")
toggle("Jump Boost",   "JumpEnabled", MiscPage, startJump)
slider("Jump Power",   "JumpValue",   50, 500, MiscPage, "%.0f")
toggle("Infinite Jump","InfJump",     MiscPage)
toggle("Bunny Hop",    "BunnyHop",    MiscPage, startBhop)
toggle("Fly",          "FlyEnabled",  MiscPage, function(v) CFG.FlyEnabled=v; startFly() end)
slider("Fly Speed",    "FlySpeed",    10, 350, MiscPage, "%.0f")

section("PLAYER", MiscPage)
toggle("God Mode",     "GodMode",     MiscPage, startGod)
toggle("Inf Stamina (SD)", "InfStamina", MiscPage, startStamina)
toggle("Anti-AFK",     "AntiAFK",     MiscPage)
toggle("Auto Respawn", "AutoRespawn", MiscPage)

section("QUICK ACTIONS", MiscPage)
btn("Teleport to Spawn", MiscPage, function()
    local root = getRoot(LP)
    if root then root.CFrame = CFrame.new(0,10,0) end
end)
btn("Rejoin Server", MiscPage, function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LP)
end)
btn("Reset Character", MiscPage, function()
    local h = getHum(LP)
    if h then h.Health=0 end
end)
btn("Copy Username", MiscPage, function()
    clip(LP.Name)
end)
btn("Copy UserID", MiscPage, function()
    clip(tostring(LP.UserId))
end)

-- ── SAN DIEGO ────────────────────────────────────────────────
section("SD BORDER RP", SDPage)
lbl("San Diego RP specific features", SDPage, CLR.Accent)
toggle("Cop Alert (console warn)",  "SDCopAlert",    SDPage)
toggle("Ghost Mode (partial)",      "SDGhostMode",   SDPage)
toggle("Mini Radar",                "SDRadarEnabled",SDPage)
toggle("Vehicle ESP",               "SDVehicleESP",  SDPage)

section("SD INFO", SDPage)
lbl("Game uses R15 rigs — Head + UpperTorso confirmed", SDPage)
lbl("Stamina: attribute + NumberValue both patched",    SDPage)
lbl("Border Patrol team: "..SD_TEAMS.BP,               SDPage)
lbl("Civilian team: "..SD_TEAMS.CIVIL,                 SDPage)
lbl("Aimbot key E recommended for SD (less obvious)",   SDPage)

section("SD QUICK", SDPage)
btn("Print All Player Teams", SDPage, function()
    for _,p in ipairs(Players:GetPlayers()) do
        print(p.Name.." | Team: "..(p.Team and p.Team.Name or "none"))
    end
end)
btn("Print NPC Count", SDPage, function()
    local npcs = getSDNPCs()
    print("[AngelHub] SD NPCs found: "..#npcs)
end)
btn("Print Vehicle Count", SDPage, function()
    local v = getSDVehicles()
    print("[AngelHub] SD Vehicles found: "..#v)
end)

-- ── SETTINGS ─────────────────────────────────────────────────
section("INTERFACE", SettingsPage)
slider("UI Scale",   "UIScale",   0.5, 2.0, SettingsPage, "%.1f", function(v)
    Main.Size = minimized
        and UDim2.new(0,680*v,0,46)
        or  UDim2.new(0,680*v,0,480*v)
end)
slider("UI Opacity", "UIOpacity", 0.2, 1.0, SettingsPage, "%.2f", function(v)
    Main.BackgroundTransparency = 1-v
    Sidebar.BackgroundTransparency = 1-v
end)

section("THEME", SettingsPage)
dropdown("Color Theme", "Theme", {"Cyan","Purple","Red","Green","Gold"}, SettingsPage)
toggle("Rainbow Mode",  "RainbowMode", SettingsPage)

section("KEYBIND", SettingsPage)
lbl("Toggle GUI: RightShift (default)", SettingsPage)
lbl("Mobile: tap the ✦ floating button", SettingsPage)

section("DISCORD", SettingsPage)
btn("Copy Discord Link — discord.gg/d8gpXNGknP", SettingsPage, function()
    clip(DISCORD)
end, true)

section("CREDITS", SettingsPage)
lbl("AngelHub "..VERSION.." — San Diego RP Edition", SettingsPage, CLR.Accent)
lbl("Executor: Synapse X / KRNL / Fluxus / Delta / Codex", SettingsPage)
lbl("Platform: Android • iOS • Windows", SettingsPage)

-- ══════════════════════════════════════════════════════════════
-- RAINBOW ACCENT UPDATER
-- ══════════════════════════════════════════════════════════════
RunService.Heartbeat:Connect(function()
    if not CFG.RainbowMode then return end
    local c = getAccent()
    -- update sidebar accents
    for _, b in pairs(TabBtns) do
        local ac = b:FindFirstChild("Accent")
        if ac and ac.Visible then ac.BackgroundColor3=c end
    end
    fovCircle.Color = c
end)

-- ══════════════════════════════════════════════════════════════
-- ACTIVATE
-- ══════════════════════════════════════════════════════════════
switchTab("Combat")
TabBtns["Combat"].BackgroundColor3 = CLR.Card
TabBtns["Combat"].BackgroundTransparency = 0
local firstAc = TabBtns["Combat"]:FindFirstChild("Accent")
if firstAc then firstAc.Visible=true end
local firstIc = TabBtns["Combat"]:FindFirstChild("Icon")
if firstIc then firstIc.TextColor3=getAccent() end
local firstLb = TabBtns["Combat"]:FindFirstChild("Label")
if firstLb then firstLb.TextColor3=CLR.Text end

-- ══════════════════════════════════════════════════════════════
-- STARTUP
-- ══════════════════════════════════════════════════════════════
print([[
╔══════════════════════════════════════╗
║   AngelHub v2.0 — San Diego Edition  ║
║   discord.gg/d8gpXNGknP              ║
║   Toggle: RightShift | Mobile: ✦     ║
╚══════════════════════════════════════╝
]])
