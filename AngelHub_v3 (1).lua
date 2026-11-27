--[[
╔═══════════════════════════════════════════════════╗
║  AngelHub v3.0 — San Diego RP Edition             ║
║  discord.gg/d8gpXNGknP                            ║
║  Android · iOS · Windows — All Executors          ║
╚═══════════════════════════════════════════════════╝
--]]

-- ═══════════════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════════════
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local VirtualUser      = game:GetService("VirtualUser")
local ContextActionService = game:GetService("ContextActionService")
local Camera           = workspace.CurrentCamera
local LP               = Players.LocalPlayer
local Mouse            = LP:GetMouse()

local DISCORD = "https://discord.gg/d8gpXNGknP"
local VERSION = "v3.0"

-- ═══════════════════════════════════════════════════
-- MOBILE DETECTION
-- ═══════════════════════════════════════════════════
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ═══════════════════════════════════════════════════
-- CLIPBOARD
-- ═══════════════════════════════════════════════════
local function clip(t)
    if setclipboard then setclipboard(t)
    elseif toclipboard then toclipboard(t)
    elseif syn and syn.write_clipboard then syn.write_clipboard(t)
    else print("[AngelHub] Copy: "..t) end
end

-- ═══════════════════════════════════════════════════
-- CFG
-- ═══════════════════════════════════════════════════
local CFG = {
    -- COMBAT
    AimbotEnabled   = false,
    SilentAim       = false,
    AimLock         = false,
    AutoShoot       = false,
    TriggerBot      = false,
    TriggerDelay    = 0.05,
    NoRecoil        = false,
    NoSpread        = false,
    RapidFire       = false,
    InfiniteAmmo    = false,
    Prediction      = true,
    PredictionVal   = 0.10,
    AimPart         = "Head",
    AimFOV          = 150,
    AimSmooth       = 0.35,
    TeamCheck       = true,
    WallCheck       = false,
    ShowFOV         = true,
    -- VISUALS
    ESPEnabled      = false,
    ESPBoxes        = true,
    ESPNames        = true,
    ESPHealth       = true,
    ESPHealthBar    = true,
    ESPDistance     = true,
    ESPTracers      = false,
    ESPSkeleton     = false,
    ESPTeamColor    = false,
    MaxESPDist      = 800,
    ESPColor        = Color3.fromRGB(160, 80, 255),
    ESPEnemyColor   = Color3.fromRGB(255, 60, 80),
    ESPFriendColor  = Color3.fromRGB(80, 220, 120),
    -- WORLD
    FullBright      = false,
    NoFog           = false,
    NightVision     = false,
    SDCrosshair     = false,
    CrosshairSize   = 10,
    MiniRadar       = false,
    -- MISC
    NoClip          = false,
    SpeedEnabled    = false,
    SpeedVal        = 24,
    JumpEnabled     = false,
    JumpVal         = 50,
    InfJump         = false,
    BunnyHop        = false,
    FlyEnabled      = false,
    FlySpeed        = 60,
    GodMode         = false,
    InfStamina      = false,
    AntiAFK         = true,
    AutoRespawn     = false,
    -- SAN DIEGO
    SDCarBoost      = false,
    SDCarBoostPow   = 150,
    SDNoclipCar     = false,
    SDInfFuel       = false,
    SDFlipCar       = false,
    SDNPCTarget     = false,
    SDCopAlert      = false,
    SDRadar         = false,
    SDInfHealth     = false,
    SDFreezeCops    = false,
    SDTeleportBorder= false,
    -- SETTINGS
    UIScale         = 1.0,
    Theme           = "Purple",
    KeybindOpen     = Enum.KeyCode.RightShift,
}

-- ═══════════════════════════════════════════════════
-- THEME
-- ═══════════════════════════════════════════════════
local THEMES = {
    Purple = {Color3.fromRGB(140,60,255), Color3.fromRGB(90,20,180), Color3.fromRGB(180,100,255)},
    Cyan   = {Color3.fromRGB(0,200,255),  Color3.fromRGB(0,120,180), Color3.fromRGB(100,230,255)},
    Red    = {Color3.fromRGB(255,50,80),  Color3.fromRGB(180,20,40), Color3.fromRGB(255,120,140)},
    Green  = {Color3.fromRGB(50,220,120), Color3.fromRGB(20,150,70), Color3.fromRGB(120,255,180)},
    Gold   = {Color3.fromRGB(255,190,20), Color3.fromRGB(180,120,0), Color3.fromRGB(255,220,100)},
}
local function accent() return (THEMES[CFG.Theme] or THEMES.Purple)[1] end
local function accentDim() return (THEMES[CFG.Theme] or THEMES.Purple)[2] end
local function accentBright() return (THEMES[CFG.Theme] or THEMES.Purple)[3] end

local CLR = {
    BG      = Color3.fromRGB(13, 11, 20),
    BG2     = Color3.fromRGB(18, 15, 28),
    Panel   = Color3.fromRGB(22, 18, 35),
    Card    = Color3.fromRGB(28, 22, 44),
    Sidebar = Color3.fromRGB(16, 13, 26),
    Text    = Color3.fromRGB(230, 225, 245),
    Sub     = Color3.fromRGB(140, 130, 170),
    Muted   = Color3.fromRGB(55, 48, 75),
    White   = Color3.new(1,1,1),
    Red     = Color3.fromRGB(255,60,80),
    Green   = Color3.fromRGB(60,220,120),
}

local FT = Enum.Font.GothamBold
local FR = Enum.Font.Gotham
local FM = Enum.Font.Code

-- ═══════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════
local function gc(p)  return p and p.Character end
local function gh(p)
    local c = gc(p); return c and c:FindFirstChildOfClass("Humanoid")
end
local function gr(p)
    local c = gc(p)
    return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso"))
end
local function gp(p, name)
    local c = gc(p); if not c then return nil end
    return c:FindFirstChild(name)
        or c:FindFirstChild("UpperTorso")
        or c:FindFirstChild("Torso")
end
local function alive(p)
    local h = gh(p); return h and h.Health > 0
end
local function sameteam(p)
    return p.Team and LP.Team and p.Team == LP.Team
end
local function w2v(pos)
    local v, on = Camera:WorldToViewportPoint(pos)
    return Vector2.new(v.X, v.Y), on, v.Z
end
local function lerp(a,b,t) return a+(b-a)*t end
local function clrLerp(a,b,t)
    return Color3.new(lerp(a.R,b.R,t),lerp(a.G,b.G,t),lerp(a.B,b.B,t))
end
local function mk(cls, props, par)
    local i = Instance.new(cls)
    for k,v in pairs(props) do i[k]=v end
    if par then i.Parent=par end
    return i
end
local function cr(r,p) return mk("UICorner",{CornerRadius=UDim.new(0,r)},p) end
local function st(t,c,p) return mk("UIStroke",{Thickness=t,Color=c,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},p) end

-- ═══════════════════════════════════════════════════
-- SD UTILS
-- ═══════════════════════════════════════════════════
local SD_NPC_FOLDERS = {"NPCs","Civilians","Officers","Suspects","Entities","BorderAgents"}
local SD_BORDER_POS  = Vector3.new(0, 5, 0) -- approximate, update per server

local function getSDNPCs()
    local out = {}
    for _, fname in ipairs(SD_NPC_FOLDERS) do
        local f = workspace:FindFirstChild(fname)
        if f then
            for _, m in ipairs(f:GetChildren()) do
                if m:IsA("Model") and m:FindFirstChildOfClass("Humanoid") then
                    table.insert(out, m)
                end
            end
        end
    end
    return out
end

local function getPlayerCar(p)
    local char = gc(p or LP)
    if not char then return nil end
    -- SD seats the player inside a vehicle seat
    local seat = char:FindFirstChildOfClass("Seat")
        or char:FindFirstAncestorOfClass("Model")
    if seat then
        local model = seat:FindFirstAncestorOfClass("Model")
        if model and model ~= char then return model end
    end
    -- also check VehicleSeat
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("VehicleSeat") and obj.Occupant then
            local occ = Players:GetPlayerFromCharacter(obj.Occupant.Parent)
            if occ == (p or LP) then
                return obj.Parent
            end
        end
    end
    return nil
end

-- ═══════════════════════════════════════════════════
-- AIM TARGET
-- ═══════════════════════════════════════════════════
local function getTarget()
    local best, bestD = nil, CFG.AimFOV
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP then continue end
        if CFG.TeamCheck and sameteam(p) then continue end
        if not alive(p) then continue end
        local part = gp(p, CFG.AimPart)
        if not part then continue end
        if CFG.WallCheck then
            local origin = Camera.CFrame.Position
            local dir    = (part.Position - origin).Unit * 999
            local ray    = Ray.new(origin, dir)
            local hit    = workspace:FindPartOnRayWithIgnoreList(ray, {LP.Character, Camera})
            if hit and not hit:IsDescendantOf(p.Character) then continue end
        end
        local vp, on, depth = w2v(part.Position)
        if not on or depth < 0 then continue end
        local d = (vp - center).Magnitude
        if d < bestD then bestD=d; best={p=p, part=part, vp=vp} end
    end
    if CFG.SDNPCTarget then
        for _, npc in ipairs(getSDNPCs()) do
            local hum = npc:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then continue end
            local part = npc:FindFirstChild("Head") or npc:FindFirstChild("HumanoidRootPart")
            if not part then continue end
            local vp, on, depth = w2v(part.Position)
            if not on or depth < 0 then continue end
            local d = (vp - center).Magnitude
            if d < bestD then bestD=d; best={npc=npc, part=part, vp=vp} end
        end
    end
    return best
end

-- ═══════════════════════════════════════════════════
-- MOBILE VIRTUAL CONTROLS
-- ═══════════════════════════════════════════════════
-- On mobile, Roblox fires TouchTap/TouchLongPress — we map these to
-- shooting and aiming so the aimbot/triggerbot still fires correctly
-- without needing keyboard input.

local mobileAiming   = false
local mobileShooting = false

local function setupMobileControls()
    if not isMobile then return end

    -- Right-side of screen = aim hold
    UserInputService.TouchStarted:Connect(function(touch, gp)
        if gp then return end
        local halfX = Camera.ViewportSize.X / 2
        if touch.Position.X > halfX then
            mobileAiming = true
        end
    end)
    UserInputService.TouchEnded:Connect(function(touch, gp)
        if gp then return end
        mobileAiming = false
        mobileShooting = false
    end)

    -- Bind a virtual tap-to-shoot action for auto-shoot
    ContextActionService:BindAction("AH_MobileShoot",
        function(_, state, _)
            mobileShooting = (state == Enum.UserInputState.Begin)
            return Enum.ContextActionResult.Pass
        end, false, Enum.UserInputType.Touch)
end
setupMobileControls()

local function isAiming()
    if isMobile then return mobileAiming end
    if CFG.AimbotKey == "RMB" then
        return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    elseif CFG.AimbotKey == "LMB" then
        return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    elseif CFG.AimbotKey == "Q" then
        return UserInputService:IsKeyDown(Enum.KeyCode.Q)
    elseif CFG.AimbotKey == "E" then
        return UserInputService:IsKeyDown(Enum.KeyCode.E)
    end
    return false
end

-- ═══════════════════════════════════════════════════
-- AIMBOT (works mobile + PC)
-- ═══════════════════════════════════════════════════
local aimbotConn
local function startAimbot()
    if aimbotConn then aimbotConn:Disconnect() end
    aimbotConn = RunService.Heartbeat:Connect(function()
        if not CFG.AimbotEnabled then return end
        if not isAiming() and not CFG.AimLock then return end
        local t = getTarget()
        if not t or not t.part then return end

        local vel = Vector3.zero
        if t.p then
            local root = gr(t.p)
            if root then vel = root.AssemblyLinearVelocity end
        end
        local pred = t.part.Position + (CFG.Prediction and vel * CFG.PredictionVal or Vector3.zero)
        local vp, on = Camera:WorldToViewportPoint(pred)
        if not on then return end

        local smooth = CFG.AimSmooth
        local dx = (vp.X - Mouse.X) * (1 - smooth)
        local dy = (vp.Y - Mouse.Y) * (1 - smooth)

        if isMobile then
            -- On mobile we move the camera CFrame directly
            -- instead of mousemoverel (which doesn't exist on mobile executors)
            local curCF  = Camera.CFrame
            local lookAt = CFrame.lookAt(curCF.Position, t.part.Position)
            Camera.CFrame = curCF:Lerp(lookAt, 1 - smooth)
        else
            if mousemoverel then mousemoverel(dx, dy) end
        end

        -- Auto shoot (mobile: mobileShooting flag; PC: check dist)
        if CFG.AutoShoot then
            local distPx = Vector2.new(vp.X - Mouse.X, vp.Y - Mouse.Y).Magnitude
            if distPx < 10 or (isMobile and mobileShooting) then
                if mouse1click then mouse1click()
                elseif fireclickdetector then
                    -- fallback
                end
            end
        end
    end)
end
startAimbot()

-- ═══════════════════════════════════════════════════
-- AIM LOCK — fix: continuously snaps camera to target
-- ═══════════════════════════════════════════════════
local aimlockConn
local function startAimLock()
    if aimlockConn then aimlockConn:Disconnect() end
    aimlockConn = RunService.RenderStepped:Connect(function()
        if not CFG.AimLock then return end
        local t = getTarget()
        if not t or not t.part then return end
        local origin = Camera.CFrame.Position
        local goal   = CFrame.new(origin, t.part.Position)
        Camera.CFrame = Camera.CFrame:Lerp(goal, 0.5)
    end)
end
startAimLock()

-- ═══════════════════════════════════════════════════
-- SILENT AIM
-- ═══════════════════════════════════════════════════
local silentHooked = false
local function hookSilent()
    if silentHooked then return end
    silentHooked = true
    pcall(function()
        local mt    = getrawmetatable(game)
        local oldNI = mt.__newindex
        setreadonly(mt, false)
        mt.__newindex = function(tbl, k, v)
            if CFG.SilentAim and tbl == Mouse and k == "Hit" then
                local tgt = getTarget()
                if tgt and tgt.part then
                    return oldNI(tbl, k, CFrame.new(tgt.part.Position))
                end
            end
            return oldNI(tbl, k, v)
        end
        setreadonly(mt, true)
    end)
end
hookSilent()

-- ═══════════════════════════════════════════════════
-- TRIGGERBOT
-- ═══════════════════════════════════════════════════
local trigConn
local function startTrigger()
    if trigConn then trigConn:Disconnect() end
    trigConn = RunService.Heartbeat:Connect(function()
        if not CFG.TriggerBot then return end
        local unitRay = Camera:ScreenPointToRay(Mouse.X, Mouse.Y)
        local ray     = Ray.new(unitRay.Origin, unitRay.Direction * 999)
        local hit     = workspace:FindPartOnRayWithIgnoreList(ray, {LP.Character})
        if not hit then return end
        local p = Players:GetPlayerFromCharacter(hit.Parent)
        if not p or p == LP then return end
        if CFG.TeamCheck and sameteam(p) then return end
        if not alive(p) then return end
        task.wait(CFG.TriggerDelay)
        if mouse1click then mouse1click() end
    end)
end
startTrigger()

-- ═══════════════════════════════════════════════════
-- NO RECOIL / NO SPREAD (camera compensation)
-- ═══════════════════════════════════════════════════
local recoilConn
local function startNoRecoil()
    if recoilConn then recoilConn:Disconnect() end
    recoilConn = RunService.RenderStepped:Connect(function()
        if not CFG.NoRecoil then return end
        -- Counteract camera pitch changes caused by recoil
        local cf = Camera.CFrame
        local _, y, _ = cf:ToEulerAnglesYXZ()
        Camera.CFrame = CFrame.new(cf.Position) * CFrame.Angles(0, y, 0)
            * CFrame.Angles(math.asin(cf.LookVector.Y * 0.95), 0, 0)
    end)
end
startNoRecoil()

-- ═══════════════════════════════════════════════════
-- GOD MODE
-- ═══════════════════════════════════════════════════
local godConn
local function startGod()
    if godConn then godConn:Disconnect() end
    godConn = RunService.Heartbeat:Connect(function()
        if not CFG.GodMode then return end
        local hum = gh(LP); if hum then hum.Health = hum.MaxHealth end
    end)
end
startGod()

-- ═══════════════════════════════════════════════════
-- NOCLIP
-- ═══════════════════════════════════════════════════
local noclipConn
local function startNoclip()
    if noclipConn then noclipConn:Disconnect() end
    noclipConn = RunService.Stepped:Connect(function()
        if not CFG.NoClip then return end
        local char = LP.Character; if not char then return end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end)
end
startNoclip()

-- ═══════════════════════════════════════════════════
-- SPEED
-- ═══════════════════════════════════════════════════
local speedConn
local function startSpeed()
    if speedConn then speedConn:Disconnect() end
    speedConn = RunService.Heartbeat:Connect(function()
        if not CFG.SpeedEnabled then return end
        local hum = gh(LP); if hum then hum.WalkSpeed = CFG.SpeedVal end
    end)
end
startSpeed()

-- ═══════════════════════════════════════════════════
-- JUMP
-- ═══════════════════════════════════════════════════
local jumpConn
local function startJump()
    if jumpConn then jumpConn:Disconnect() end
    jumpConn = RunService.Heartbeat:Connect(function()
        if not CFG.JumpEnabled then return end
        local hum = gh(LP); if hum then hum.JumpPower = CFG.JumpVal end
    end)
end
startJump()

UserInputService.JumpRequest:Connect(function()
    if not CFG.InfJump then return end
    local hum = gh(LP)
    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

local bhopConn
local function startBhop()
    if bhopConn then bhopConn:Disconnect() end
    bhopConn = RunService.Heartbeat:Connect(function()
        if not CFG.BunnyHop then return end
        local hum = gh(LP); if not hum then return end
        if hum:GetState() == Enum.HumanoidStateType.Landed then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end
startBhop()

-- ═══════════════════════════════════════════════════
-- FLY — mobile: uses camera direction via touch move
-- ═══════════════════════════════════════════════════
local flyConn, flyBV, flyBG
local function startFly()
    if flyConn then flyConn:Disconnect() end
    if not CFG.FlyEnabled then
        pcall(function() if flyBV then flyBV:Destroy() end end)
        pcall(function() if flyBG then flyBG:Destroy() end end)
        flyBV, flyBG = nil, nil
        return
    end
    local root = gr(LP); if not root then return end
    pcall(function()
        if flyBG then flyBG:Destroy() end
        if flyBV then flyBV:Destroy() end
        flyBG = Instance.new("BodyGyro", root)
        flyBG.P = 9e4; flyBG.MaxTorque = Vector3.new(9e9,9e9,9e9)
        flyBV = Instance.new("BodyVelocity", root)
        flyBV.Velocity = Vector3.zero
        flyBV.MaxForce = Vector3.new(9e9,9e9,9e9)
    end)
    flyConn = RunService.Heartbeat:Connect(function()
        if not CFG.FlyEnabled or not flyBV then return end
        local cf  = Camera.CFrame
        local vel = Vector3.zero
        local spd = CFG.FlySpeed
        -- PC controls
        if not isMobile then
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then vel += cf.LookVector*spd end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then vel -= cf.LookVector*spd end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then vel -= cf.RightVector*spd end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then vel += cf.RightVector*spd end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vel += Vector3.new(0,spd,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then vel -= Vector3.new(0,spd,0) end
        else
            -- Mobile: use thumbstick / move direction from character
            local char = LP.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                local md = hum.MoveDirection
                if md.Magnitude > 0.1 then
                    vel = md * spd
                end
            end
            -- up/down via double-jump (InfJump handles jump; fly goes up on jump input)
            if UserInputService:IsKeyDown(Enum.KeyCode.ButtonA) then
                vel += Vector3.new(0, spd, 0)
            end
        end
        flyBV.Velocity = vel
        if flyBG then flyBG.CFrame = cf end
    end)
end

-- ═══════════════════════════════════════════════════
-- STAMINA
-- ═══════════════════════════════════════════════════
local stamConn
local function startStamina()
    if stamConn then stamConn:Disconnect() end
    stamConn = RunService.Heartbeat:Connect(function()
        if not CFG.InfStamina then return end
        local char = LP.Character; if not char then return end
        for _, v in ipairs(char:GetChildren()) do
            if (v.Name:lower():find("stamina") or v.Name:lower():find("sprint"))
                and v:IsA("NumberValue") then
                v.Value = 100
            end
        end
        pcall(function()
            if char:GetAttribute("Stamina") ~= nil then char:SetAttribute("Stamina",100) end
            if char:GetAttribute("Sprint") ~= nil then char:SetAttribute("Sprint",100) end
        end)
    end)
end
startStamina()

-- ═══════════════════════════════════════════════════
-- ANTI-AFK
-- ═══════════════════════════════════════════════════
LP.Idled:Connect(function()
    if not CFG.AntiAFK then return end
    VirtualUser:Button2Down(Vector2.new(0,0), Camera.CFrame)
    task.wait(0.1)
    VirtualUser:Button2Up(Vector2.new(0,0), Camera.CFrame)
end)

-- ═══════════════════════════════════════════════════
-- AUTO RESPAWN
-- ═══════════════════════════════════════════════════
LP.CharacterRemoving:Connect(function()
    if CFG.AutoRespawn then task.wait(0.8); LP:LoadCharacter() end
end)

-- ═══════════════════════════════════════════════════
-- FULLBRIGHT / FOG
-- ═══════════════════════════════════════════════════
local origAmb, origBright, origFogEnd
local function applyLighting()
    local L = game:GetService("Lighting")
    if CFG.FullBright or CFG.NightVision then
        if not origAmb then origAmb=L.Ambient; origBright=L.Brightness end
        L.Ambient = Color3.new(1,1,1); L.Brightness = 2
        -- remove effect instances
        for _, e in ipairs(L:GetChildren()) do
            if e:IsA("BlurEffect") or e:IsA("ColorCorrectionEffect") then
                e.Enabled = false
            end
        end
    else
        if origAmb then L.Ambient=origAmb; L.Brightness=origBright; origAmb=nil end
        for _, e in ipairs(L:GetChildren()) do
            if e:IsA("BlurEffect") or e:IsA("ColorCorrectionEffect") then
                e.Enabled = true
            end
        end
    end
    if CFG.NoFog then
        if not origFogEnd then origFogEnd=L.FogEnd end
        L.FogEnd = 9e9
    else
        if origFogEnd then L.FogEnd=origFogEnd; origFogEnd=nil end
    end
end

-- ═══════════════════════════════════════════════════
-- SAN DIEGO SPECIFIC FEATURES
-- ═══════════════════════════════════════════════════

-- Car Boost
local carBoostConn
local function startCarBoost()
    if carBoostConn then carBoostConn:Disconnect() end
    carBoostConn = RunService.Heartbeat:Connect(function()
        if not CFG.SDCarBoost then return end
        local car = getPlayerCar(LP)
        if not car then return end
        local seat = car:FindFirstChildOfClass("VehicleSeat")
        if seat then
            local bv = seat:FindFirstChildOfClass("BodyVelocity")
                or Instance.new("BodyVelocity", seat)
            bv.MaxForce = Vector3.new(9e9,0,9e9)
            bv.Velocity  = seat.CFrame.LookVector * CFG.SDCarBoostPow
        end
    end)
end
startCarBoost()

-- Car Noclip
local carNoclipConn
local function startCarNoclip()
    if carNoclipConn then carNoclipConn:Disconnect() end
    carNoclipConn = RunService.Stepped:Connect(function()
        if not CFG.SDNoclipCar then return end
        local car = getPlayerCar(LP)
        if not car then return end
        for _, p in ipairs(car:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end)
end
startCarNoclip()

-- Inf Fuel
local fuelConn
local function startInfFuel()
    if fuelConn then fuelConn:Disconnect() end
    fuelConn = RunService.Heartbeat:Connect(function()
        if not CFG.SDInfFuel then return end
        local car = getPlayerCar(LP)
        if not car then return end
        for _, v in ipairs(car:GetDescendants()) do
            if (v.Name:lower():find("fuel") or v.Name:lower():find("gas"))
                and v:IsA("NumberValue") then
                v.Value = 100
            end
            pcall(function()
                if car:GetAttribute("Fuel") ~= nil then car:SetAttribute("Fuel",100) end
            end)
        end
    end)
end
startInfFuel()

-- Flip car
local function flipCar()
    local car = getPlayerCar(LP)
    if not car then return end
    local seat = car:FindFirstChildOfClass("VehicleSeat")
        or car:FindFirstChildOfClass("Seat")
    if seat then
        seat.CFrame = CFrame.new(seat.Position + Vector3.new(0,3,0))
    end
end

-- Freeze cops (SD: set walkspeed 0 on BP team)
local freezeConn
local function startFreezeCops()
    if freezeConn then freezeConn:Disconnect() end
    freezeConn = RunService.Heartbeat:Connect(function()
        if not CFG.SDFreezeCops then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LP then continue end
            if p.Team and (p.Team.Name:find("Patrol") or p.Team.Name:find("CBP") or p.Team.Name:find("Officer")) then
                local hum = gh(p)
                if hum then hum.WalkSpeed = 0 end
            end
        end
    end)
end
startFreezeCops()

-- Inf health specifically for SD (attribute-based)
local sdHealthConn
local function startSDHealth()
    if sdHealthConn then sdHealthConn:Disconnect() end
    sdHealthConn = RunService.Heartbeat:Connect(function()
        if not CFG.SDInfHealth then return end
        local char = LP.Character; if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = hum.MaxHealth end
        pcall(function()
            if char:GetAttribute("Health") ~= nil then
                char:SetAttribute("Health", char:GetAttribute("MaxHealth") or 100)
            end
        end)
    end)
end
startSDHealth()

-- Teleport to border
local SD_BORDER_LOCATIONS = {
    ["Main Gate"]    = Vector3.new(0, 5, 0),
    ["Checkpoint A"] = Vector3.new(200, 5, 50),
    ["Checkpoint B"] = Vector3.new(-200, 5, 50),
    ["Tunnel"]       = Vector3.new(50, 5, -100),
    ["Spawn"]        = Vector3.new(0, 5, 300),
}

local function teleportTo(pos)
    local root = gr(LP)
    if root then root.CFrame = CFrame.new(pos + Vector3.new(0,3,0)) end
end

-- ═══════════════════════════════════════════════════
-- ESP SYSTEM
-- ═══════════════════════════════════════════════════
local ESP = {}

local function newDraw(type, props)
    local d = Drawing.new(type)
    for k,v in pairs(props) do d[k]=v end
    return d
end

local function hideAll(e)
    for _, d in pairs(e) do pcall(function() d.Visible=false end) end
end

local function removeESP(key)
    if ESP[key] then
        for _, d in pairs(ESP[key]) do pcall(function() d:Remove() end) end
        ESP[key] = nil
    end
end

local function mkESP(p)
    removeESP(p)
    ESP[p] = {
        -- Corner box (8 lines)
        TL1=newDraw("Line",{Thickness=1.5,Visible=false}),
        TL2=newDraw("Line",{Thickness=1.5,Visible=false}),
        TR1=newDraw("Line",{Thickness=1.5,Visible=false}),
        TR2=newDraw("Line",{Thickness=1.5,Visible=false}),
        BL1=newDraw("Line",{Thickness=1.5,Visible=false}),
        BL2=newDraw("Line",{Thickness=1.5,Visible=false}),
        BR1=newDraw("Line",{Thickness=1.5,Visible=false}),
        BR2=newDraw("Line",{Thickness=1.5,Visible=false}),
        -- info
        Name   = newDraw("Text",{Size=13,Center=true,Outline=true,Visible=false}),
        Dist   = newDraw("Text",{Size=11,Center=true,Outline=true,Visible=false}),
        HP     = newDraw("Text",{Size=11,Center=true,Outline=true,Visible=false}),
        -- health bar
        HBG    = newDraw("Square",{Filled=true,Color=Color3.fromRGB(15,10,20),Visible=false}),
        HFG    = newDraw("Square",{Filled=true,Visible=false}),
        -- tracer
        Tracer = newDraw("Line",{Thickness=1,Visible=false}),
        -- skeleton
        SkH    = newDraw("Line",{Thickness=1,Color=Color3.fromRGB(255,220,50),Visible=false}),
        SkT    = newDraw("Line",{Thickness=1,Color=Color3.fromRGB(255,220,50),Visible=false}),
        SkLA   = newDraw("Line",{Thickness=1,Color=Color3.fromRGB(255,220,50),Visible=false}),
        SkRA   = newDraw("Line",{Thickness=1,Color=Color3.fromRGB(255,220,50),Visible=false}),
        SkLL   = newDraw("Line",{Thickness=1,Color=Color3.fromRGB(255,220,50),Visible=false}),
        SkRL   = newDraw("Line",{Thickness=1,Color=Color3.fromRGB(255,220,50),Visible=false}),
    }
end

local function drawCorner(e, x, y, w, h, c)
    local cw, ch = w*0.28, h*0.28
    e.TL1.From=Vector2.new(x,y);     e.TL1.To=Vector2.new(x+cw,y);   e.TL1.Color=c; e.TL1.Visible=true
    e.TL2.From=Vector2.new(x,y);     e.TL2.To=Vector2.new(x,y+ch);   e.TL2.Color=c; e.TL2.Visible=true
    e.TR1.From=Vector2.new(x+w,y);   e.TR1.To=Vector2.new(x+w-cw,y); e.TR1.Color=c; e.TR1.Visible=true
    e.TR2.From=Vector2.new(x+w,y);   e.TR2.To=Vector2.new(x+w,y+ch); e.TR2.Color=c; e.TR2.Visible=true
    e.BL1.From=Vector2.new(x,y+h);   e.BL1.To=Vector2.new(x+cw,y+h); e.BL1.Color=c; e.BL1.Visible=true
    e.BL2.From=Vector2.new(x,y+h);   e.BL2.To=Vector2.new(x,y+h-ch); e.BL2.Color=c; e.BL2.Visible=true
    e.BR1.From=Vector2.new(x+w,y+h); e.BR1.To=Vector2.new(x+w-cw,y+h);e.BR1.Color=c;e.BR1.Visible=true
    e.BR2.From=Vector2.new(x+w,y+h); e.BR2.To=Vector2.new(x+w,y+h-ch);e.BR2.Color=c;e.BR2.Visible=true
end

local function hideCorner(e)
    for _, k in ipairs({"TL1","TL2","TR1","TR2","BL1","BL2","BR1","BR2"}) do
        e[k].Visible=false
    end
end

local espConn
local function startESP()
    if espConn then espConn:Disconnect() end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then mkESP(p) end
    end
    Players.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function() task.wait(0.5); mkESP(p) end)
    end)
    Players.PlayerRemoving:Connect(removeESP)

    espConn = RunService.Heartbeat:Connect(function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LP then continue end
            local e = ESP[p]
            if not e then mkESP(p); continue end

            local char = gc(p)
            local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
            local hum  = gh(p)
            local head = char and char:FindFirstChild("Head")
            local vis  = CFG.ESPEnabled and root ~= nil and alive(p)
            if CFG.TeamCheck and sameteam(p) then vis = false end

            if not vis then hideAll(e); continue end

            local rootVP, on, depth = w2v(root.Position)
            local d3 = (root.Position - Camera.CFrame.Position).Magnitude
            if not on or depth < 0 or d3 > CFG.MaxESPDist then hideAll(e); continue end

            local col = CFG.ESPTeamColor
                and (sameteam(p) and CFG.ESPFriendColor or CFG.ESPEnemyColor)
                or CFG.ESPColor

            -- corner box
            if CFG.ESPBoxes and head then
                local headVP = w2v(head.Position + Vector3.new(0,0.7,0))
                local h = math.abs(headVP.Y - rootVP.Y) * 2.1
                local w = h * 0.55
                local x = rootVP.X - w/2
                local y = headVP.Y
                drawCorner(e, x, y, w, h, col)
                -- health bar
                if CFG.ESPHealthBar and hum then
                    local hp = math.clamp(hum.Health/hum.MaxHealth, 0, 1)
                    local bx = x - 7
                    e.HBG.Position=Vector2.new(bx,y); e.HBG.Size=Vector2.new(5,h); e.HBG.Visible=true
                    local hcol = clrLerp(CLR.Red, CLR.Green, hp)
                    e.HFG.Position=Vector2.new(bx, y+h*(1-hp))
                    e.HFG.Size=Vector2.new(5, h*hp)
                    e.HFG.Color=hcol; e.HFG.Visible=true
                else e.HBG.Visible=false; e.HFG.Visible=false end
            else
                hideCorner(e); e.HBG.Visible=false; e.HFG.Visible=false
            end

            -- name
            if CFG.ESPNames and head then
                local hVP = w2v(head.Position+Vector3.new(0,1.4,0))
                e.Name.Position=Vector2.new(hVP.X, hVP.Y)
                e.Name.Text=p.DisplayName; e.Name.Color=col; e.Name.Visible=true
            else e.Name.Visible=false end

            -- distance
            if CFG.ESPDistance then
                local bVP = w2v(root.Position+Vector3.new(0,-3.5,0))
                e.Dist.Position=Vector2.new(bVP.X,bVP.Y)
                e.Dist.Text=math.floor(d3).."m"; e.Dist.Color=CLR.Sub; e.Dist.Visible=true
            else e.Dist.Visible=false end

            -- hp text
            if CFG.ESPHealth and hum then
                local hp = math.floor(hum.Health)
                local bVP2 = w2v(root.Position+Vector3.new(0,-5,0))
                local hcol = clrLerp(CLR.Red, CLR.Green, hum.Health/hum.MaxHealth)
                e.HP.Position=Vector2.new(bVP2.X,bVP2.Y)
                e.HP.Text=hp.."❤"; e.HP.Color=hcol; e.HP.Visible=true
            else e.HP.Visible=false end

            -- tracer
            if CFG.ESPTracers then
                e.Tracer.From=Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                e.Tracer.To=rootVP; e.Tracer.Color=col; e.Tracer.Visible=true
            else e.Tracer.Visible=false end

            -- skeleton
            if CFG.ESPSkeleton and char then
                local function sk(line, a, b)
                    local pa = char:FindFirstChild(a); local pb = char:FindFirstChild(b)
                    if pa and pb then
                        line.From=w2v(pa.Position); line.To=w2v(pb.Position); line.Visible=true
                    else line.Visible=false end
                end
                sk(e.SkH,  "Head",        "UpperTorso")
                sk(e.SkT,  "UpperTorso",  "LowerTorso")
                sk(e.SkLA, "UpperTorso",  "LeftUpperArm")
                sk(e.SkRA, "UpperTorso",  "RightUpperArm")
                sk(e.SkLL, "LowerTorso",  "LeftUpperLeg")
                sk(e.SkRL, "LowerTorso",  "RightUpperLeg")
            else
                e.SkH.Visible=false; e.SkT.Visible=false; e.SkLA.Visible=false
                e.SkRA.Visible=false; e.SkLL.Visible=false; e.SkRL.Visible=false
            end
        end
    end)
end
startESP()

-- ═══════════════════════════════════════════════════
-- FOV CIRCLE
-- ═══════════════════════════════════════════════════
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness=1; fovCircle.NumSides=80
fovCircle.Filled=false; fovCircle.Visible=false

-- CROSSHAIR
local crossLines = {}
for i=1,4 do
    crossLines[i]=Drawing.new("Line")
    crossLines[i].Thickness=1.5; crossLines[i].Visible=false
end

-- RADAR
local RSIZE = 160; local RRANGE = 250
local radarObjs = {
    bg   = newDraw("Square",{Filled=true,Color=Color3.fromRGB(5,3,10),Visible=false}),
    bord = newDraw("Square",{Filled=false,Thickness=1.5,Visible=false}),
    xln  = newDraw("Line",{Thickness=1,Color=Color3.fromRGB(0,80,40),Visible=false}),
    yln  = newDraw("Line",{Thickness=1,Color=Color3.fromRGB(0,80,40),Visible=false}),
    self = newDraw("Triangle",{Filled=true,Color=Color3.fromRGB(140,60,255),Visible=false}),
}
local radarDots = {}

RunService.Heartbeat:Connect(function()
    -- FOV
    if CFG.ShowFOV and (CFG.AimbotEnabled or CFG.SilentAim or CFG.AimLock) then
        fovCircle.Radius=CFG.AimFOV
        fovCircle.Position=Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        fovCircle.Color=accent(); fovCircle.Visible=true
    else fovCircle.Visible=false end

    -- Crosshair
    local cx=Camera.ViewportSize.X/2; local cy=Camera.ViewportSize.Y/2
    local cs=CFG.CrosshairSize
    if CFG.SDCrosshair then
        crossLines[1].From=Vector2.new(cx-cs,cy); crossLines[1].To=Vector2.new(cx-3,cy)
        crossLines[2].From=Vector2.new(cx+3,cy);  crossLines[2].To=Vector2.new(cx+cs,cy)
        crossLines[3].From=Vector2.new(cx,cy-cs); crossLines[3].To=Vector2.new(cx,cy-3)
        crossLines[4].From=Vector2.new(cx,cy+3);  crossLines[4].To=Vector2.new(cx,cy+cs)
        for _,l in ipairs(crossLines) do l.Color=accent(); l.Visible=true end
    else for _,l in ipairs(crossLines) do l.Visible=false end end

    -- Radar
    if not (CFG.MiniRadar or CFG.SDRadar) then
        radarObjs.bg.Visible=false; radarObjs.bord.Visible=false
        radarObjs.xln.Visible=false; radarObjs.yln.Visible=false
        radarObjs.self.Visible=false
        for _,d in pairs(radarDots) do d.Visible=false end
        return
    end
    local vp = Camera.ViewportSize
    local rp = Vector2.new(vp.X-RSIZE-10, vp.Y-RSIZE-10)
    local rcx=rp.X+RSIZE/2; local rcy=rp.Y+RSIZE/2
    local ac = accent()
    radarObjs.bg.Position=rp; radarObjs.bg.Size=Vector2.new(RSIZE,RSIZE); radarObjs.bg.Visible=true
    radarObjs.bord.Position=rp; radarObjs.bord.Size=Vector2.new(RSIZE,RSIZE); radarObjs.bord.Color=ac; radarObjs.bord.Visible=true
    radarObjs.xln.From=Vector2.new(rcx,rp.Y); radarObjs.xln.To=Vector2.new(rcx,rp.Y+RSIZE); radarObjs.xln.Visible=true
    radarObjs.yln.From=Vector2.new(rp.X,rcy); radarObjs.yln.To=Vector2.new(rp.X+RSIZE,rcy); radarObjs.yln.Visible=true
    radarObjs.self.PointA=Vector2.new(rcx,rcy-5)
    radarObjs.self.PointB=Vector2.new(rcx-4,rcy+4)
    radarObjs.self.PointC=Vector2.new(rcx+4,rcy+4)
    radarObjs.self.Color=ac; radarObjs.self.Visible=true

    local myCF = Camera.CFrame; local half=RSIZE/2
    local plist = Players:GetPlayers()
    for i, p in ipairs(plist) do
        if p==LP then continue end
        if not radarDots[i] then
            radarDots[i]=newDraw("Square",{Filled=true,Size=Vector2.new(5,5),Visible=false})
        end
        local dot=radarDots[i]
        local root=gr(p)
        if not root or not alive(p) then dot.Visible=false; continue end
        local rel=myCF:PointToObjectSpace(root.Position)
        local rx=math.clamp(rel.X/RRANGE*half,-half+4,half-4)
        local ry=math.clamp(-rel.Z/RRANGE*half,-half+4,half-4)
        local col=sameteam(p) and CLR.Green or CLR.Red
        dot.Position=Vector2.new(rcx+rx-2,rcy+ry-2); dot.Color=col; dot.Visible=true
    end
    for i=#plist+1,#radarDots do if radarDots[i] then radarDots[i].Visible=false end end
end)

-- ═══════════════════════════════════════════════════
-- GUI SETUP
-- ═══════════════════════════════════════════════════
local SG = Instance.new("ScreenGui")
SG.Name="AngelHub"; SG.ResetOnSpawn=false
SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
SG.IgnoreGuiInset=true; SG.DisplayOrder=999

pcall(function()
    if syn and syn.protect_gui then syn.protect_gui(SG); SG.Parent=game.CoreGui
    elseif gethui then SG.Parent=gethui()
    else SG.Parent=game.CoreGui end
end)
if not SG.Parent then SG.Parent=LP:WaitForChild("PlayerGui") end

-- ═══════════════════════════════════════════════════
-- MAIN WINDOW — matches screenshot layout
-- ═══════════════════════════════════════════════════
local WIN_W, WIN_H = 760, 500

local Main = mk("Frame",{
    Name="Main", Size=UDim2.new(0,WIN_W,0,WIN_H),
    Position=UDim2.new(0.5,-WIN_W/2,0.5,-WIN_H/2),
    BackgroundColor3=CLR.BG, BorderSizePixel=0, ClipsDescendants=false,
}, SG)
cr(14, Main)

-- Purple glow border (outer)
local GlowBorder = mk("Frame",{
    Size=UDim2.new(1,6,1,6), Position=UDim2.new(0,-3,0,-3),
    BackgroundColor3=Color3.fromRGB(100,30,200), BackgroundTransparency=0.6,
    BorderSizePixel=0, ZIndex=0,
}, Main)
cr(16, GlowBorder)

-- Second glow (softer)
local GlowBorder2 = mk("Frame",{
    Size=UDim2.new(1,16,1,16), Position=UDim2.new(0,-8,0,-8),
    BackgroundColor3=Color3.fromRGB(80,20,160), BackgroundTransparency=0.85,
    BorderSizePixel=0, ZIndex=0,
}, Main)
cr(20, GlowBorder2)

local InnerClip = mk("Frame",{
    Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, ClipsDescendants=true,
}, Main)

-- ── HEADER BAR ───────────────────────────────────────────────
-- Dark header matching screenshot
local Header = mk("Frame",{
    Size=UDim2.new(1,0,0,70), BackgroundColor3=CLR.BG, BorderSizePixel=0,
}, InnerClip)

-- Purple grid pattern on header
local GridDeco = mk("Frame",{
    Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
}, Header)

-- Logo icon (matches screenshot: dark square with angel wings symbol)
local IconBox = mk("Frame",{
    Size=UDim2.new(0,52,0,52), Position=UDim2.new(0,14,0.5,-26),
    BackgroundColor3=Color3.fromRGB(20,14,36), BorderSizePixel=0,
}, Header)
cr(10, IconBox)
st(1.5, Color3.fromRGB(100,40,200), IconBox)
mk("TextLabel",{
    Size=UDim2.new(1,0,1,0), Text="✦", Font=FT,
    TextColor3=accent(), TextSize=24, BackgroundTransparency=1,
}, IconBox)

-- Title
mk("TextLabel",{
    Size=UDim2.new(0,220,0,36), Position=UDim2.new(0,74,0,10),
    Text="AngelHub | "..VERSION, Font=FT,
    TextColor3=CLR.Text, TextSize=24, BackgroundTransparency=1,
    TextXAlignment=Enum.TextXAlignment.Left,
}, Header)

-- Subtitle
mk("TextLabel",{
    Size=UDim2.new(0,220,0,16), Position=UDim2.new(0,74,0,44),
    Text="San Diego RP Edition", Font=FR,
    TextColor3=accent(), TextSize=11, BackgroundTransparency=1,
    TextXAlignment=Enum.TextXAlignment.Left,
}, Header)

-- Discord pill (matches screenshot: right side, pill shape)
local DiscordPill = mk("TextButton",{
    Size=UDim2.new(0,220,0,36), Position=UDim2.new(1,-314,0.5,-18),
    Text="  discord.gg/d8gpXNGknP", Font=FR,
    TextColor3=CLR.Text, TextSize=12,
    BackgroundColor3=Color3.fromRGB(18,14,30),
}, Header)
cr(18, DiscordPill)
st(1.5, Color3.fromRGB(80,30,160), DiscordPill)

-- Discord icon on pill
mk("TextLabel",{
    Size=UDim2.new(0,30,1,0), Position=UDim2.new(1,-30,0,0),
    Text="⬡", Font=FR, TextColor3=accent(), TextSize=14,
    BackgroundColor3=Color3.fromRGB(80,30,160), BackgroundTransparency=0,
}, DiscordPill):Parent = DiscordPill
-- fix: simple text instead of frame
DiscordPill.Text = "discord.gg/d8gpXNGknP  ⬡"

DiscordPill.MouseButton1Click:Connect(function()
    clip(DISCORD)
    DiscordPill.Text = "✓ Copied!  ⬡"
    DiscordPill.TextColor3 = CLR.Green
    task.wait(2)
    DiscordPill.Text = "discord.gg/d8gpXNGknP  ⬡"
    DiscordPill.TextColor3 = CLR.Text
end)

-- Window controls (—  □  ✕ like screenshot)
local function winBtn(sym, bgCol, xOff, cb)
    local b = mk("TextButton",{
        Size=UDim2.new(0,28,0,28), Position=UDim2.new(1,xOff,0.5,-14),
        Text=sym, Font=FT, TextColor3=CLR.Text, TextSize=13,
        BackgroundColor3=bgCol,
    }, Header)
    cr(6,b); b.MouseButton1Click:Connect(cb); return b
end
winBtn("✕", Color3.fromRGB(180,40,60), -38, function() Main.Visible=false end)
winBtn("□", Color3.fromRGB(50,40,70),  -72, function()
    -- maximize/restore
    Main.Size = Main.Size == UDim2.new(0,WIN_W,0,WIN_H)
        and UDim2.new(0,WIN_W*1.2,0,WIN_H*1.2)
        or  UDim2.new(0,WIN_W,0,WIN_H)
end)
local minimized = false
local bodyFrame
winBtn("—", Color3.fromRGB(50,40,70),  -106, function()
    minimized = not minimized
    if bodyFrame then bodyFrame.Visible = not minimized end
    Main.Size = minimized and UDim2.new(0,WIN_W,0,70) or UDim2.new(0,WIN_W,0,WIN_H)
end)

-- Header bottom border (purple line)
mk("Frame",{
    Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,0),
    BackgroundColor3=Color3.fromRGB(80,30,160), BorderSizePixel=0,
}, Header)

-- Drag via header
local drag,dragS,dragP=false
Header.InputBegan:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1
    or inp.UserInputType==Enum.UserInputType.Touch then
        drag=true; dragS=inp.Position; dragP=Main.Position
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if drag and (inp.UserInputType==Enum.UserInputType.MouseMovement
        or inp.UserInputType==Enum.UserInputType.Touch) then
        local d=inp.Position-dragS
        Main.Position=UDim2.new(dragP.X.Scale,dragP.X.Offset+d.X,dragP.Y.Scale,dragP.Y.Offset+d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1
    or inp.UserInputType==Enum.UserInputType.Touch then drag=false end
end)
UserInputService.InputBegan:Connect(function(inp,gp)
    if gp then return end
    if inp.KeyCode==CFG.KeybindOpen then Main.Visible=not Main.Visible end
end)

-- ── BODY ─────────────────────────────────────────────────────
bodyFrame = mk("Frame",{
    Size=UDim2.new(1,0,1,-70-44), Position=UDim2.new(0,0,0,70),
    BackgroundTransparency=1, ClipsDescendants=true,
}, InnerClip)

-- ── SIDEBAR ──────────────────────────────────────────────────
local SideW = 160
local Sidebar = mk("Frame",{
    Size=UDim2.new(0,SideW,1,0), BackgroundColor3=CLR.Sidebar, BorderSizePixel=0,
}, bodyFrame)
mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,4)},Sidebar)
mk("UIPadding",{PaddingTop=UDim.new(0,10),PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8)},Sidebar)

-- Right border on sidebar
mk("Frame",{
    Size=UDim2.new(0,1,1,0), Position=UDim2.new(1,0,0,0),
    BackgroundColor3=Color3.fromRGB(60,20,120), BorderSizePixel=0,
}, Sidebar)

-- ── CONTENT ──────────────────────────────────────────────────
local Content = mk("Frame",{
    Size=UDim2.new(1,-SideW,1,0), Position=UDim2.new(0,SideW,0,0),
    BackgroundColor3=CLR.BG2, BorderSizePixel=0, ClipsDescendants=true,
}, bodyFrame)

-- ── BOTTOM STATUS BAR ────────────────────────────────────────
-- matches screenshot: "Menu Keybind: [RightShift]" bar
local StatusBar = mk("Frame",{
    Size=UDim2.new(1,0,0,44), Position=UDim2.new(0,0,1,-44),
    BackgroundColor3=CLR.BG, BorderSizePixel=0,
}, InnerClip)
mk("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=Color3.fromRGB(60,20,120),BorderSizePixel=0},StatusBar)

-- Keybind display pill
local KeyPill = mk("TextButton",{
    Size=UDim2.new(0,240,0,28), Position=UDim2.new(0.5,-120,0.5,-14),
    Text="Menu Keybind: [RightShift]", Font=FM,
    TextColor3=CLR.Sub, TextSize=12,
    BackgroundColor3=Color3.fromRGB(20,16,32),
}, StatusBar)
cr(14,KeyPill); st(1,Color3.fromRGB(60,20,120),KeyPill)

-- Status indicators left side
local statusTxt = mk("TextLabel",{
    Size=UDim2.new(0.4,0,1,0), Position=UDim2.new(0,12,0,0),
    Text="● AngelHub Active", Font=FR, TextColor3=accent(), TextSize=11,
    BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left,
}, StatusBar)

-- Platform indicator right
mk("TextLabel",{
    Size=UDim2.new(0,120,1,0), Position=UDim2.new(1,-130,0,0),
    Text=isMobile and "📱 Mobile" or "🖥 PC", Font=FR,
    TextColor3=CLR.Sub, TextSize=11,
    BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Right,
}, StatusBar)

-- ── FLOAT BUTTON (mobile) ────────────────────────────────────
local FloatBtn = mk("TextButton",{
    Size=UDim2.new(0,52,0,52), Position=UDim2.new(0,20,0.85,-26),
    Text="✦", Font=FT, TextColor3=CLR.BG, TextSize=22,
    BackgroundColor3=accent(), ZIndex=25,
}, SG)
cr(26,FloatBtn); st(2,accentDim(),FloatBtn)
local fbG=mk("Frame",{
    Size=UDim2.new(1,18,1,18),Position=UDim2.new(0,-9,0,-9),
    BackgroundColor3=accent(),BackgroundTransparency=0.78,
    BorderSizePixel=0,ZIndex=24,
},FloatBtn); cr(32,fbG)
FloatBtn.MouseButton1Click:Connect(function() Main.Visible=not Main.Visible end)

-- ═══════════════════════════════════════════════════
-- TAB SYSTEM
-- ═══════════════════════════════════════════════════
local Pages = {}
local TabBtns = {}

local function switchTab(name)
    for n,f in pairs(Pages) do f.Visible=(n==name) end
    for n,b in pairs(TabBtns) do
        local ac=b:FindFirstChild("Ac")
        local lbl=b:FindFirstChild("Lbl")
        local ico=b:FindFirstChild("Ico")
        if ac then ac.Visible=(n==name) end
        b.BackgroundColor3=(n==name) and CLR.Card or CLR.Sidebar
        b.BackgroundTransparency=(n==name) and 0 or 1
        if lbl then lbl.TextColor3=(n==name) and CLR.Text or CLR.Sub end
        if ico then ico.TextColor3=(n==name) and accent() or CLR.Muted end
    end
end

local function makeTab(name, icon, order)
    local btn=mk("TextButton",{
        Size=UDim2.new(1,0,0,42), BackgroundColor3=CLR.Sidebar,
        BackgroundTransparency=1, BorderSizePixel=0, Text="", LayoutOrder=order,
    }, Sidebar)
    cr(10,btn)
    mk("Frame",{Name="Ac",Size=UDim2.new(0,3,0.6,0),Position=UDim2.new(0,0,0.2,0),
        BackgroundColor3=accent(),Visible=false,BorderSizePixel=0},btn)
    mk("TextLabel",{Name="Ico",Size=UDim2.new(0,26,1,0),Position=UDim2.new(0,10,0,0),
        Text=icon,Font=FR,TextColor3=Color3.fromRGB(55,48,75),TextSize=16,BackgroundTransparency=1},btn)
    mk("TextLabel",{Name="Lbl",Size=UDim2.new(1,-40,1,0),Position=UDim2.new(0,38,0,0),
        Text=name,Font=FR,TextColor3=CLR.Sub,TextSize=13,BackgroundTransparency=1,
        TextXAlignment=Enum.TextXAlignment.Left},btn)
    btn.MouseButton1Click:Connect(function() switchTab(name) end)
    TabBtns[name]=btn

    local page=mk("ScrollingFrame",{
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
        ScrollBarThickness=4, ScrollBarImageColor3=accent(),
        BorderSizePixel=0, Visible=false,
        CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y,
        ScrollingDirection=Enum.ScrollingDirection.Y,
    }, Content)
    mk("UIPadding",{PaddingTop=UDim.new(0,14),PaddingLeft=UDim.new(0,14),
        PaddingRight=UDim.new(0,16),PaddingBottom=UDim.new(0,14)},page)
    mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,8)},page)
    Pages[name]=page
    return page
end

-- ═══════════════════════════════════════════════════
-- TWO-PANEL LAYOUT (matches screenshot)
-- Each tab page is split: left panel + right panel
-- ═══════════════════════════════════════════════════
local widgetOrd = {}
local function wo(p) widgetOrd[p]=(widgetOrd[p] or 0)+1; return widgetOrd[p] end

-- Creates a two-panel row inside a page
local function twoPanel(page, leftTitle, rightTitle)
    local o=wo(page)
    local row=mk("Frame",{
        Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1, LayoutOrder=o,
    },page)
    mk("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,
        SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,10)},row)

    local function panel(title, lo)
        local p=mk("Frame",{
            Size=UDim2.new(0.5,-5,0,0), AutomaticSize=Enum.AutomaticSize.Y,
            BackgroundColor3=CLR.Panel, BorderSizePixel=0, LayoutOrder=lo,
        },row)
        cr(10,p); st(1,Color3.fromRGB(60,20,120),p)
        mk("UIPadding",{PaddingTop=UDim.new(0,10),PaddingLeft=UDim.new(0,10),
            PaddingRight=UDim.new(0,10),PaddingBottom=UDim.new(0,10)},p)
        local ll=mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,8)},p)
        -- panel title
        local hdr=mk("TextLabel",{
            Size=UDim2.new(1,0,0,22), Text=title, Font=FT,
            TextColor3=accent(), TextSize=11, BackgroundTransparency=1,
            TextXAlignment=Enum.TextXAlignment.Center, LayoutOrder=0,
        },p)
        -- separator
        mk("Frame",{Size=UDim2.new(0.8,0,0,1),Position=UDim2.new(0.1,0,0,0),
            BackgroundColor3=Color3.fromRGB(60,20,120),BorderSizePixel=0},hdr)
        return p, ll
    end

    local lp, ll = panel(leftTitle, 1)
    local rp, rl = panel(rightTitle, 2)
    return row, lp, rp
end

-- ═══════════════════════════════════════════════════
-- WIDGETS (panel-aware)
-- ═══════════════════════════════════════════════════
local pwo = {} -- per-panel order
local function pOrd(p) pwo[p]=(pwo[p] or 0)+1; return pwo[p] end

local function tog(label, cfgKey, panel, cb)
    local o=pOrd(panel)
    local row=mk("Frame",{
        Size=UDim2.new(1,0,0,34), BackgroundColor3=CLR.Card,
        BorderSizePixel=0, LayoutOrder=o,
    },panel)
    cr(7,row)
    mk("TextLabel",{
        Size=UDim2.new(1,-52,1,0), Position=UDim2.new(0,10,0,0),
        Text=label, Font=FR, TextColor3=CLR.Text, TextSize=12,
        BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left,
    },row)
    local bg=mk("Frame",{
        Size=UDim2.new(0,40,0,20), Position=UDim2.new(1,-48,0.5,-10),
        BackgroundColor3=CFG[cfgKey] and accent() or CLR.Muted, BorderSizePixel=0,
    },row); cr(10,bg)
    local knob=mk("Frame",{
        Size=UDim2.new(0,14,0,14),
        Position=CFG[cfgKey] and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7),
        BackgroundColor3=CLR.White, BorderSizePixel=0,
    },bg); cr(7,knob); st(1,Color3.fromRGB(0,0,0),knob)
    local b=mk("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text=""},bg)
    b.MouseButton1Click:Connect(function()
        CFG[cfgKey]=not CFG[cfgKey]; local on=CFG[cfgKey]
        TweenService:Create(bg,TweenInfo.new(0.16),{BackgroundColor3=on and accent() or CLR.Muted}):Play()
        TweenService:Create(knob,TweenInfo.new(0.16),{Position=on and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)}):Play()
        if cb then cb(on) end
    end)
    return row
end

local function sld(label, cfgKey, minV, maxV, panel, fmt, cb)
    local o=pOrd(panel)
    local row=mk("Frame",{
        Size=UDim2.new(1,0,0,52), BackgroundColor3=CLR.Card, BorderSizePixel=0, LayoutOrder=o,
    },panel); cr(7,row)
    local vl=mk("TextLabel",{
        Size=UDim2.new(0,52,0,16), Position=UDim2.new(1,-58,0,8),
        Text=string.format(fmt or "%.0f",CFG[cfgKey]),
        Font=FM, TextColor3=accent(), TextSize=11,
        BackgroundColor3=CLR.BG, BackgroundTransparency=0,
        TextXAlignment=Enum.TextXAlignment.Center,
    },row); cr(4,vl)
    mk("TextLabel",{
        Size=UDim2.new(1,-68,0,16), Position=UDim2.new(0,10,0,8),
        Text=label, Font=FR, TextColor3=CLR.Text, TextSize=12, BackgroundTransparency=1,
        TextXAlignment=Enum.TextXAlignment.Left,
    },row)
    local track=mk("Frame",{
        Size=UDim2.new(1,-20,0,5), Position=UDim2.new(0,10,1,-17),
        BackgroundColor3=CLR.Muted, BorderSizePixel=0,
    },row); cr(3,track)
    local pct=math.clamp((CFG[cfgKey]-minV)/(maxV-minV),0,1)
    local fill=mk("Frame",{Size=UDim2.new(pct,0,1,0),BackgroundColor3=accent(),BorderSizePixel=0},track); cr(3,fill)
    local thumb=mk("Frame",{
        Size=UDim2.new(0,14,0,14), Position=UDim2.new(pct,-7,0.5,-7),
        BackgroundColor3=CLR.White, BorderSizePixel=0,
    },track); cr(7,thumb); st(1.5,accent(),thumb)
    local sl=false
    local function upd(ix)
        local t=math.clamp((ix-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
        local v=minV+t*(maxV-minV); CFG[cfgKey]=v
        fill.Size=UDim2.new(t,0,1,0); thumb.Position=UDim2.new(t,-7,0.5,-7)
        vl.Text=string.format(fmt or "%.0f",v); if cb then cb(v) end
    end
    local tb=mk("TextButton",{Size=UDim2.new(1,0,0,26),Position=UDim2.new(0,0,-0.5,0),BackgroundTransparency=1,Text=""},track)
    tb.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            sl=true; upd(inp.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if sl and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
            upd(inp.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then sl=false end
    end)
    return row
end

local function drp(label, cfgKey, opts, panel, cb)
    local o=pOrd(panel)
    local row=mk("Frame",{
        Size=UDim2.new(1,0,0,34), BackgroundColor3=CLR.Card, BorderSizePixel=0,
        LayoutOrder=o, ClipsDescendants=false, ZIndex=5,
    },panel); cr(7,row)
    mk("TextLabel",{
        Size=UDim2.new(0.5,0,1,0), Position=UDim2.new(0,10,0,0),
        Text=label, Font=FR, TextColor3=CLR.Text, TextSize=12,
        BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=5,
    },row)
    local sel=mk("TextButton",{
        Size=UDim2.new(0.44,0,0,24), Position=UDim2.new(0.54,0,0.5,-12),
        Text=tostring(CFG[cfgKey]).." ▾", Font=FR, TextColor3=accent(), TextSize=11,
        BackgroundColor3=CLR.BG, ZIndex=5,
    },row); cr(6,sel); st(1,accentDim(),sel)
    local dd=mk("Frame",{
        Size=UDim2.new(0.44,0,0,0), Position=UDim2.new(0.54,0,1,2),
        BackgroundColor3=CLR.BG2, BorderSizePixel=0, Visible=false, ZIndex=20, ClipsDescendants=true,
    },row); cr(6,dd); st(1,accent(),dd)
    mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder},dd)
    for i,opt in ipairs(opts) do
        local ob=mk("TextButton",{
            Size=UDim2.new(1,0,0,26), Text="  "..opt, Font=FR,
            TextColor3=CLR.Text, TextSize=11, BackgroundTransparency=1, ZIndex=20, LayoutOrder=i,
            TextXAlignment=Enum.TextXAlignment.Left,
        },dd)
        ob.MouseEnter:Connect(function() ob.BackgroundTransparency=0.85; ob.BackgroundColor3=accent() end)
        ob.MouseLeave:Connect(function() ob.BackgroundTransparency=1 end)
        ob.MouseButton1Click:Connect(function()
            CFG[cfgKey]=opt; sel.Text=opt.." ▾"
            dd.Visible=false; dd.Size=UDim2.new(0.44,0,0,0)
            if cb then cb(opt) end
        end)
    end
    sel.MouseButton1Click:Connect(function()
        dd.Visible=not dd.Visible
        TweenService:Create(dd,TweenInfo.new(0.14),{Size=UDim2.new(0.44,0,0,dd.Visible and #opts*26 or 0)}):Play()
    end)
    return row
end

local function abtn(label, panel, cb, hi)
    local o=pOrd(panel)
    local b=mk("TextButton",{
        Size=UDim2.new(1,0,0,32), Text=label, Font=FR,
        TextColor3=hi and CLR.BG or CLR.Text, TextSize=12,
        BackgroundColor3=hi and accent() or CLR.Card, BorderSizePixel=0, LayoutOrder=o,
    },panel); cr(7,b)
    if not hi then st(1,accentDim(),b) end
    b.MouseButton1Click:Connect(cb); return b
end

local function lbl(text, panel, col)
    local o=pOrd(panel)
    return mk("TextLabel",{
        Size=UDim2.new(1,0,0,20), Text=text, Font=FR,
        TextColor3=col or CLR.Sub, TextSize=11, BackgroundTransparency=1,
        TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=o,
    },panel)
end

local function sep(panel)
    local o=pOrd(panel)
    mk("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=Color3.fromRGB(50,20,80),BorderSizePixel=0,LayoutOrder=o},panel)
end

-- ═══════════════════════════════════════════════════
-- BUILD PAGES
-- ═══════════════════════════════════════════════════
local CombatPg  = makeTab("Combat",   "⊕", 1)
local VisualsPg = makeTab("Visuals",  "◈", 2)
local MiscPg    = makeTab("Misc",     "⚙", 3)
local SDPg      = makeTab("San Diego","⬡", 4)
local WorldPg   = makeTab("World",    "🌐",5)
local SettingsPg= makeTab("Settings", "✦", 6)

-- ══ COMBAT (two panels like screenshot) ═════════════
local _, aimPanel, weapPanel = twoPanel(CombatPg, "AIM & FOV", "WEAPON & TARGETING")

tog("Silent Aim",   "SilentAim",     aimPanel)
tog("Aimbot",       "AimbotEnabled", aimPanel, startAimbot)
tog("Aim Lock",     "AimLock",       aimPanel, startAimLock)
tog("Draw FOV Circle","ShowFOV",     aimPanel)
tog("Prediction",   "Prediction",    aimPanel)
sld("Smoothness",   "AimSmooth",  0.01,0.98, aimPanel,"%.0f%%", nil)
-- convert to % display
do
    -- re-do smoothness slider with % format
end
sld("FOV Radius",   "AimFOV",    10, 500, aimPanel,"%.0f px")
sld("Prediction",   "PredictionVal",0,0.5,aimPanel,"%.3f")

drp("Target Part",  "AimPart", {"Head","UpperTorso","HumanoidRootPart","Neck"}, weapPanel)
tog("Wall Check",   "WallCheck",  weapPanel)
tog("Team Check",   "TeamCheck",  weapPanel)
tog("No Recoil",    "NoRecoil",   weapPanel, startNoRecoil)
tog("No Spread",    "NoSpread",   weapPanel)
tog("Rapid Fire",   "RapidFire",  weapPanel)
tog("Infinite Ammo","InfiniteAmmo",weapPanel)
tog("Auto Shoot",   "AutoShoot",  weapPanel)
tog("Triggerbot",   "TriggerBot", weapPanel, startTrigger)
sld("Trigger Delay","TriggerDelay",0,0.5,weapPanel,"%.2f s")

-- add aim key dropdown below panels
local aimKeyRow=mk("Frame",{
    Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
    BackgroundColor3=CLR.Panel,BorderSizePixel=0,LayoutOrder=wo(CombatPg),
},CombatPg); cr(10,aimKeyRow)
mk("UIPadding",{PaddingTop=UDim.new(0,10),PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10),PaddingBottom=UDim.new(0,10)},aimKeyRow)
mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,8)},aimKeyRow)
st(1,accentDim(),aimKeyRow)
mk("TextLabel",{Size=UDim2.new(1,0,0,20),Text="AIM KEY (PC) / Right side of screen (Mobile)",
    Font=FT,TextColor3=accent(),TextSize=10,BackgroundTransparency=1,LayoutOrder=1},aimKeyRow)
drp("Aim Key","AimbotKey",{"RMB","LMB","Q","E"},aimKeyRow)
lbl("Mobile: hold right side of screen to aim",aimKeyRow,CLR.Sub)

-- ══ VISUALS ══════════════════════════════════════════
local _, espPanel, espCfgPanel = twoPanel(VisualsPg, "ESP", "ESP CONFIG")

tog("ESP Enabled",  "ESPEnabled",  espPanel, startESP)
tog("Boxes",        "ESPBoxes",    espPanel)
tog("Names",        "ESPNames",    espPanel)
tog("Health Text",  "ESPHealth",   espPanel)
tog("Health Bar",   "ESPHealthBar",espPanel)
tog("Distance",     "ESPDistance", espPanel)
tog("Tracers",      "ESPTracers",  espPanel)
tog("Skeleton",     "ESPSkeleton", espPanel)
tog("Team Color",   "ESPTeamColor",espPanel)
tog("Target SD NPCs","SDNPCTarget",espPanel)

tog("Crosshair",    "SDCrosshair", espCfgPanel)
sld("Crosshair Size","CrosshairSize",4,30,espCfgPanel,"%.0f")
sld("Max ESP Dist", "MaxESPDist",50,2000,espCfgPanel,"%.0f m")
tog("Mini Radar",   "MiniRadar",   espCfgPanel)
lbl("ESP Color: edit CFG.ESPColor in script",espCfgPanel,CLR.Sub)
lbl("Enemy Color: red  |  Friend Color: green",espCfgPanel,CLR.Sub)

-- ══ MISC ════════════════════════════════════════════
local _, movePanel, playerPanel = twoPanel(MiscPg, "MOVEMENT", "PLAYER")

tog("No Clip",     "NoClip",      movePanel, startNoclip)
tog("Speed Hack",  "SpeedEnabled",movePanel, startSpeed)
sld("Walk Speed",  "SpeedVal",    16,250,    movePanel,"%.0f")
tog("Jump Boost",  "JumpEnabled", movePanel, startJump)
sld("Jump Power",  "JumpVal",     50,500,    movePanel,"%.0f")
tog("Infinite Jump","InfJump",    movePanel)
tog("Bunny Hop",   "BunnyHop",   movePanel, startBhop)
tog("Fly",         "FlyEnabled",  movePanel, function(v) CFG.FlyEnabled=v; startFly() end)
sld("Fly Speed",   "FlySpeed",    10,350,    movePanel,"%.0f")

tog("God Mode",    "GodMode",     playerPanel, startGod)
tog("Inf Stamina", "InfStamina",  playerPanel, startStamina)
tog("Anti-AFK",    "AntiAFK",     playerPanel)
tog("Auto Respawn","AutoRespawn", playerPanel)
sep(playerPanel)
abtn("Teleport Spawn", playerPanel, function()
    local r=gr(LP); if r then r.CFrame=CFrame.new(0,10,0) end
end)
abtn("Rejoin Server", playerPanel, function()
    game:GetService("TeleportService"):Teleport(game.PlaceId,LP)
end)
abtn("Reset Character", playerPanel, function()
    local h=gh(LP); if h then h.Health=0 end
end)
abtn("Copy Username", playerPanel, function() clip(LP.Name) end)

-- ══ SAN DIEGO ════════════════════════════════════════
local _, carPanel, sdMiscPanel = twoPanel(SDPg, "VEHICLE", "SD MISC")

tog("Car Boost",        "SDCarBoost",    carPanel, startCarBoost)
sld("Boost Power",      "SDCarBoostPow", 50,500,  carPanel,"%.0f")
tog("Car Noclip",       "SDNoclipCar",   carPanel, startCarNoclip)
tog("Infinite Fuel",    "SDInfFuel",     carPanel, startInfFuel)
abtn("Flip Car",        carPanel, flipCar)
abtn("Max Speed Boost", carPanel, function()
    CFG.SDCarBoost=true; CFG.SDCarBoostPow=500; startCarBoost()
end, true)

tog("Freeze Cops",      "SDFreezeCops",  sdMiscPanel, startFreezeCops)
tog("SD Inf Health",    "SDInfHealth",   sdMiscPanel, startSDHealth)
tog("NPC Target",       "SDNPCTarget",   sdMiscPanel)
tog("Cop Alert",        "SDCopAlert",    sdMiscPanel)
tog("SD Radar",         "SDRadar",       sdMiscPanel)
sep(sdMiscPanel)
lbl("TELEPORT LOCATIONS", sdMiscPanel, accent())
for locName, pos in pairs(SD_BORDER_LOCATIONS) do
    local p2=pos -- capture
    abtn("→ "..locName, sdMiscPanel, function() teleportTo(p2) end)
end
sep(sdMiscPanel)
abtn("Print Player Teams", sdMiscPanel, function()
    for _,p in ipairs(Players:GetPlayers()) do
        print(p.Name.." | "..(p.Team and p.Team.Name or "no team"))
    end
end)
abtn("Print SD NPCs", sdMiscPanel, function()
    print("[AngelHub] SD NPCs: "..#getSDNPCs())
end)

-- ══ WORLD ════════════════════════════════════════════
local _, lightPanel, decoPanel = twoPanel(WorldPg, "LIGHTING", "DECORATION")

tog("Fullbright",   "FullBright",  lightPanel, function() applyLighting() end)
tog("Night Vision", "NightVision", lightPanel, function() applyLighting() end)
tog("Remove Fog",   "NoFog",       lightPanel, function() applyLighting() end)

lbl("Lighting applied on toggle",lightPanel,CLR.Sub)
lbl("Revert by toggling off",    lightPanel,CLR.Sub)

lbl("World features",decoPanel,accent())
lbl("Coming soon: custom skybox",decoPanel,CLR.Sub)
lbl("Coming soon: time control", decoPanel,CLR.Sub)
lbl("Coming soon: weather control",decoPanel,CLR.Sub)

-- ══ SETTINGS ═════════════════════════════════════════
local _, uiPanel, credPanel = twoPanel(SettingsPg, "INTERFACE", "CREDITS")

sld("UI Scale","UIScale",0.5,2.0,uiPanel,"%.1f",function(v)
    Main.Size=UDim2.new(0,WIN_W*v,0,minimized and 70 or WIN_H*v)
end)
drp("Theme","Theme",{"Purple","Cyan","Red","Green","Gold"},uiPanel)
tog("Rainbow Mode","RainbowMode",uiPanel)
lbl("Keybind: RightShift (PC)",uiPanel,CLR.Sub)
lbl("Mobile: tap ✦ float button",uiPanel,CLR.Sub)
abtn("Copy Discord", uiPanel, function() clip(DISCORD) end, true)

lbl("AngelHub "..VERSION,credPanel,accent())
lbl("San Diego RP Edition",credPanel,CLR.Text)
lbl("discord.gg/d8gpXNGknP",credPanel,CLR.Sub)
sep(credPanel)
lbl("Executors:",credPanel,accent())
lbl("Synapse X | KRNL | Fluxus",credPanel,CLR.Sub)
lbl("Delta | Codex | Arceus X",credPanel,CLR.Sub)
sep(credPanel)
lbl("Platform:",credPanel,accent())
lbl("Android · iOS · Windows",credPanel,CLR.Sub)

-- ═══════════════════════════════════════════════════
-- RAINBOW UPDATER
-- ═══════════════════════════════════════════════════
local rainbowConn
RunService.Heartbeat:Connect(function()
    if not CFG.RainbowMode then return end
    local t=tick()%5/5
    local c=Color3.fromHSV(t,1,1)
    -- update accent references on accents
    for _,b in pairs(TabBtns) do
        local ac=b:FindFirstChild("Ac")
        if ac and ac.Visible then ac.BackgroundColor3=c end
    end
    fovCircle.Color=c
end)

-- ═══════════════════════════════════════════════════
-- ACTIVATE
-- ═══════════════════════════════════════════════════
switchTab("Combat")
TabBtns["Combat"].BackgroundColor3=CLR.Card
TabBtns["Combat"].BackgroundTransparency=0
local initAc=TabBtns["Combat"]:FindFirstChild("Ac")
if initAc then initAc.Visible=true end
local initIc=TabBtns["Combat"]:FindFirstChild("Ico")
if initIc then initIc.TextColor3=accent() end
local initLb=TabBtns["Combat"]:FindFirstChild("Lbl")
if initLb then initLb.TextColor3=CLR.Text end

-- ═══════════════════════════════════════════════════
-- STARTUP
-- ═══════════════════════════════════════════════════
print([[
╔══════════════════════════════════════════╗
║  AngelHub v3.0 — San Diego RP Edition    ║
║  discord.gg/d8gpXNGknP                   ║
║  Toggle: RightShift | Mobile: ✦ button   ║
║  Platform: ]]..( isMobile and "Mobile (touch controls)" or "PC (keyboard+mouse)")..[[
╚══════════════════════════════════════════╝
]])
