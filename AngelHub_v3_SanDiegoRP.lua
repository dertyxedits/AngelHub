-- ╔══════════════════════════════════════════════════════════════════╗
-- ║          AngelHub | v3.0  —  San Diego RP Border Edition        ║
-- ║          Executor: Synapse X / KRNL / Fluxus / Solara           ║
-- ║          Mobile + PC  |  RightShift to toggle menu              ║
-- ╚══════════════════════════════════════════════════════════════════╝

local DISCORD   = "discord.gg/d8gpXNGknP"
local VERSION   = "v3.0"
local GAME_NAME = "San Diego RP Border"

-- ══════════════════════════════════════════════════════════════════════
-- SERVICES
-- ══════════════════════════════════════════════════════════════════════
local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local UserInputService= game:GetService("UserInputService")
local TweenService    = game:GetService("TweenService")
local CoreGui         = game:GetService("CoreGui")
local Workspace       = game:GetService("Workspace")
local StarterGui      = game:GetService("StarterGui")
local HttpService     = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Camera          = Workspace.CurrentCamera

local LP             = Players.LocalPlayer
local Mouse          = LP:GetMouse()
local Character      = LP.Character or LP.CharacterAdded:Wait()
local Humanoid       = Character:WaitForChild("Humanoid")
local HRP            = Character:WaitForChild("HumanoidRootPart")

-- re-grab on respawn
LP.CharacterAdded:Connect(function(c)
    Character = c
    Humanoid  = c:WaitForChild("Humanoid")
    HRP       = c:WaitForChild("HumanoidRootPart")
end)

-- ══════════════════════════════════════════════════════════════════════
-- CONFIG
-- ══════════════════════════════════════════════════════════════════════
local cfg = {
    -- Combat
    SilentAim        = true,
    Aimbot           = true,
    AimbotSmooth     = 0.35,   -- 0.05 snap → 1.0 slow
    FOVRadius        = 150,
    DrawFOV          = true,
    Prediction       = true,
    TargetPart       = "Head",
    WallCheck        = true,
    TeamCheck        = true,
    NoRecoil         = true,
    NoSpread         = true,
    RapidFire        = false,
    InfiniteAmmo     = false,

    -- Visuals
    ESP              = true,
    BoxESP           = true,
    NameESP          = true,
    HealthBar        = true,
    SkeletonESP      = false,
    DistanceESP      = true,
    TracerESP        = false,
    Chams            = false,
    ESPColor         = Color3.fromRGB(160, 80, 255),
    EnemyColor       = Color3.fromRGB(255, 60, 60),
    TeamColor        = Color3.fromRGB(60, 255, 100),

    -- Misc / San Diego RP specific
    Noclip           = false,
    SpeedBoost       = false,
    WalkSpeed        = 16,
    JumpBoost        = false,
    JumpPower        = 50,
    InfiniteJump     = false,
    Fly              = false,
    FlySpeed         = 50,
    AntiRagdoll      = false,
    SpinBot          = false,
    SpinSpeed        = 10,
    AutoRespawn      = false,
    GodMode          = false,
    AntiAFK          = true,

    -- San Diego RP specific
    AutoArrest       = false,
    AutoCuff         = false,
    AutoTaser        = false,
    CopESP           = true,
    CriminalESP      = true,
    WantedESP        = true,
    AutoEvade        = false,
    VehicleBoost     = false,
    VehicleSpeed     = 100,
    NoClipVehicle    = false,
    TeleportToSpawn  = false,
    AntiVehicleFlip  = false,

    -- World
    NoFog            = false,
    Fullbright       = false,
    Radar            = true,
    TimeOfDay        = "Default",
    RemoveTrees      = false,

    -- Settings
    MenuKey          = Enum.KeyCode.RightShift,
    FPSBoost         = false,
}

-- ══════════════════════════════════════════════════════════════════════
-- UTILITIES
-- ══════════════════════════════════════════════════════════════════════
local function isEnemy(player)
    if player == LP then return false end
    if cfg.TeamCheck and player.Team == LP.Team then return false end
    return true
end

local function hasCharacter(player)
    return player.Character
        and player.Character:FindFirstChild("HumanoidRootPart")
        and player.Character:FindFirstChild("Humanoid")
        and player.Character.Humanoid.Health > 0
end

local function worldToViewport(pos)
    local vp, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(vp.X, vp.Y), onScreen, vp.Z
end

local function isVisible(origin, target)
    if not cfg.WallCheck then return true end
    local ray = Ray.new(origin, (target - origin).Unit * (target - origin).Magnitude)
    local hit = Workspace:FindPartOnRayWithIgnoreList(ray, {LP.Character, Camera})
    if not hit then return true end
    -- visible if hit is part of target character
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character and hit:IsDescendantOf(p.Character) then
            return true
        end
    end
    return false
end

local function getClosestPlayer()
    local closestDist = cfg.FOVRadius
    local closestPlayer = nil
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

    for _, p in ipairs(Players:GetPlayers()) do
        if isEnemy(p) and hasCharacter(p) then
            local part = p.Character:FindFirstChild(cfg.TargetPart)
                      or p.Character:FindFirstChild("HumanoidRootPart")
            if part then
                local pos2d, onScreen = worldToViewport(part.Position)
                if onScreen then
                    local dist = (pos2d - center).Magnitude
                    if dist < closestDist then
                        if not cfg.WallCheck or isVisible(Camera.CFrame.Position, part.Position) then
                            closestDist   = dist
                            closestPlayer = p
                        end
                    end
                end
            end
        end
    end
    return closestPlayer
end

-- ══════════════════════════════════════════════════════════════════════
-- DRAWING — ESP
-- ══════════════════════════════════════════════════════════════════════
local drawings = {}

local function newDraw(type, props)
    local d = Drawing.new(type)
    for k, v in pairs(props) do d[k] = v end
    table.insert(drawings, d)
    return d
end

local espObjects = {}

local function getESPFor(player)
    if not espObjects[player] then
        espObjects[player] = {
            box      = newDraw("Square",   {Visible=false, Color=cfg.ESPColor,
                                             Thickness=1.5, Filled=false}),
            name     = newDraw("Text",     {Visible=false, Color=Color3.new(1,1,1),
                                             Size=13, Center=true, Outline=true,
                                             OutlineColor=Color3.new(0,0,0)}),
            health   = newDraw("Square",   {Visible=false, Color=Color3.fromRGB(50,220,50),
                                             Thickness=1, Filled=true}),
            healthBG = newDraw("Square",   {Visible=false, Color=Color3.fromRGB(30,30,30),
                                             Thickness=1, Filled=true}),
            dist     = newDraw("Text",     {Visible=false, Color=Color3.fromRGB(200,200,200),
                                             Size=11, Center=true, Outline=true,
                                             OutlineColor=Color3.new(0,0,0)}),
            tracer   = newDraw("Line",     {Visible=false, Color=cfg.ESPColor,
                                             Thickness=1}),
        }
    end
    return espObjects[player]
end

local function clearESPFor(player)
    if espObjects[player] then
        for _, d in pairs(espObjects[player]) do
            d.Visible = false
            d:Remove()
        end
        espObjects[player] = nil
    end
end

Players.PlayerRemoving:Connect(clearESPFor)

local function updateESP()
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP then continue end
        local esp = getESPFor(p)
        local visible = cfg.ESP and hasCharacter(p)

        if not visible then
            for _, d in pairs(esp) do d.Visible = false end
            continue
        end

        local char = p.Character
        local hrp  = char.HumanoidRootPart
        local hum  = char.Humanoid
        local head = char:FindFirstChild("Head")

        local topPos    = hrp.Position + Vector3.new(0, 3.5, 0)
        local botPos    = hrp.Position - Vector3.new(0, 2.5, 0)
        local top2d, onTop, depth = worldToViewport(topPos)
        local bot2d, onBot        = worldToViewport(botPos)

        if not onTop and not onBot then
            for _, d in pairs(esp) do d.Visible = false end
            continue
        end

        local color = isEnemy(p) and cfg.EnemyColor or cfg.TeamColor
        local h     = math.abs(top2d.Y - bot2d.Y)
        local w     = h * 0.5

        -- box
        if cfg.BoxESP then
            esp.box.Visible   = true
            esp.box.Color     = color
            esp.box.Size      = Vector2.new(w, h)
            esp.box.Position  = Vector2.new(top2d.X - w/2, top2d.Y)
        else
            esp.box.Visible = false
        end

        -- name
        if cfg.NameESP and head then
            local namePos, onScreen = worldToViewport(head.Position + Vector3.new(0,0.7,0))
            esp.name.Visible  = onScreen
            esp.name.Text     = p.Name
            esp.name.Position = Vector2.new(namePos.X, namePos.Y - 2)
            esp.name.Color    = color
        else
            esp.name.Visible = false
        end

        -- health bar
        if cfg.HealthBar then
            local hpRatio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            local barH    = h * hpRatio
            local barX    = top2d.X - w/2 - 5
            esp.healthBG.Visible  = true
            esp.healthBG.Position = Vector2.new(barX - 2, top2d.Y)
            esp.healthBG.Size     = Vector2.new(4, h)
            esp.health.Visible    = true
            esp.health.Position   = Vector2.new(barX - 2, top2d.Y + (h - barH))
            esp.health.Size       = Vector2.new(4, barH)
            esp.health.Color      = Color3.fromRGB(
                math.floor(255*(1-hpRatio)), math.floor(255*hpRatio), 50)
        else
            esp.health.Visible   = false
            esp.healthBG.Visible = false
        end

        -- distance
        if cfg.DistanceESP then
            local dist3d = math.floor((hrp.Position - HRP.Position).Magnitude)
            esp.dist.Visible  = true
            esp.dist.Text     = dist3d .. "m"
            esp.dist.Position = Vector2.new(top2d.X, bot2d.Y + 2)
        else
            esp.dist.Visible = false
        end

        -- tracer
        if cfg.TracerESP then
            local center = Camera.ViewportSize
            esp.tracer.Visible = true
            esp.tracer.Color   = color
            esp.tracer.From    = Vector2.new(center.X/2, center.Y)
            esp.tracer.To      = bot2d
        else
            esp.tracer.Visible = false
        end
    end
end

-- ══════════════════════════════════════════════════════════════════════
-- FOV CIRCLE
-- ══════════════════════════════════════════════════════════════════════
local fovCircle = Drawing.new("Circle")
fovCircle.Visible   = cfg.DrawFOV
fovCircle.Color     = Color3.fromRGB(160, 80, 255)
fovCircle.Radius    = cfg.FOVRadius
fovCircle.Thickness = 1.5
fovCircle.Filled    = false
fovCircle.NumSides  = 64

-- ══════════════════════════════════════════════════════════════════════
-- SILENT AIM
-- ══════════════════════════════════════════════════════════════════════
local function setupSilentAim()
    local mt = getrawmetatable and getrawmetatable(game)
    if not mt then return end   -- executor doesn't support metatable hook

    local oldIndex = mt.__index
    setreadonly(mt, false)

    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if cfg.SilentAim and method == "FireServer" then
            local target = getClosestPlayer()
            if target and target.Character then
                local part = target.Character:FindFirstChild(cfg.TargetPart)
                          or target.Character:FindFirstChild("HumanoidRootPart")
                if part then
                    local args = {...}
                    -- patch hit position arg (index 1 or 2 depending on game)
                    for i, v in ipairs(args) do
                        if typeof(v) == "Instance" and v:IsA("BasePart") then
                            args[i] = part
                            break
                        end
                        if typeof(v) == "Vector3" then
                            args[i] = part.Position
                            break
                        end
                    end
                    return oldIndex(self, ...)(table.unpack(args))
                end
            end
        end
        return oldIndex(self, ...)(...)
    end)

    setreadonly(mt, true)
end

pcall(setupSilentAim)

-- ══════════════════════════════════════════════════════════════════════
-- AIMBOT
-- ══════════════════════════════════════════════════════════════════════
local function aimbotTick()
    if not cfg.Aimbot then return end
    if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        -- also support mobile: check if any touch is active near FOV
        local touches = UserInputService:GetMouseLocation()
        -- on mobile we just always aim when enabled and finger is down
    end

    local target = getClosestPlayer()
    if not target or not target.Character then return end
    local part = target.Character:FindFirstChild(cfg.TargetPart)
              or target.Character:FindFirstChild("HumanoidRootPart")
    if not part then return end

    local targetPos = part.Position
    if cfg.Prediction then
        local vel = part.Velocity
        local dist = (Camera.CFrame.Position - targetPos).Magnitude
        local travelTime = dist / 1000  -- rough bullet speed estimate
        targetPos = targetPos + vel * travelTime
    end

    local targetCF = CFrame.lookAt(Camera.CFrame.Position, targetPos)
    Camera.CFrame  = Camera.CFrame:Lerp(targetCF, cfg.AimbotSmooth)
end

-- ══════════════════════════════════════════════════════════════════════
-- MISC FEATURES
-- ══════════════════════════════════════════════════════════════════════

-- Noclip
local noclipConn
local function setNoclip(state)
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    if state then
        noclipConn = RunService.Stepped:Connect(function()
            if Character then
                for _, p in ipairs(Character:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end)
    else
        if Character then
            for _, p in ipairs(Character:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
        end
    end
end

-- Fly
local flyConn, flyBV, flyBG
local function setFly(state)
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyBV then flyBV:Destroy(); flyBV = nil end
    if flyBG then flyBG:Destroy(); flyBG = nil end
    if not state or not HRP then return end

    flyBV = Instance.new("BodyVelocity", HRP)
    flyBV.MaxForce = Vector3.new(1e6,1e6,1e6)
    flyBV.Velocity = Vector3.zero

    flyBG = Instance.new("BodyGyro", HRP)
    flyBG.MaxTorque = Vector3.new(1e6,1e6,1e6)
    flyBG.P = 1e4

    flyConn = RunService.RenderStepped:Connect(function()
        if not cfg.Fly then setFly(false) return end
        local dir = Vector3.zero
        local cf  = Camera.CFrame
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end
        flyBV.Velocity = dir.Magnitude > 0 and dir.Unit * cfg.FlySpeed or Vector3.zero
        flyBG.CFrame   = cf
    end)
end

-- Infinite jump
local ijConn
local function setInfiniteJump(state)
    if ijConn then ijConn:Disconnect(); ijConn = nil end
    if state then
        ijConn = UserInputService.JumpRequest:Connect(function()
            if Humanoid then Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    end
end

-- Anti AFK
local antiAFKConn
local function setAntiAFK(state)
    if antiAFKConn then antiAFKConn:Disconnect(); antiAFKConn = nil end
    if state then
        local vrs = LP:FindFirstChildOfClass("VirtualUser")
        if not vrs then
            vrs = Instance.new("VirtualUser", LP)
        end
        antiAFKConn = game:GetService("Players").LocalPlayer.Idled:Connect(function()
            vrs:CaptureController()
            vrs:ClickButton2(Vector2.new())
        end)
    end
end

-- God Mode
local function setGodMode(state)
    if not Humanoid then return end
    if state then
        Humanoid.MaxHealth = math.huge
        Humanoid.Health    = math.huge
    else
        Humanoid.MaxHealth = 100
    end
end

-- Fullbright
local function setFullbright(state)
    local lighting = game:GetService("Lighting")
    if state then
        lighting.Brightness    = 10
        lighting.ClockTime     = 14
        lighting.FogEnd        = 1e6
        lighting.GlobalShadows = false
        lighting.Ambient       = Color3.new(1,1,1)
        lighting.OutdoorAmbient= Color3.new(1,1,1)
    else
        lighting.Brightness    = 1
        lighting.ClockTime     = 14
        lighting.FogEnd        = 100000
        lighting.GlobalShadows = true
        lighting.Ambient       = Color3.fromRGB(127,127,127)
        lighting.OutdoorAmbient= Color3.fromRGB(127,127,127)
    end
end

-- No Fog
local function setNoFog(state)
    game:GetService("Lighting").FogEnd = state and 1e9 or 100000
end

-- Spin Bot
local spinConn
local function setSpinBot(state)
    if spinConn then spinConn:Disconnect(); spinConn = nil end
    if state then
        spinConn = RunService.RenderStepped:Connect(function(dt)
            if HRP then
                HRP.CFrame = HRP.CFrame * CFrame.Angles(0, math.rad(cfg.SpinSpeed), 0)
            end
        end)
    end
end

-- Vehicle boost (San Diego RP)
local vehicleConn
local function setVehicleBoost(state)
    if vehicleConn then vehicleConn:Disconnect(); vehicleConn = nil end
    if state then
        vehicleConn = RunService.Heartbeat:Connect(function()
            local seat = LP.Character and LP.Character:FindFirstChildOfClass("VehicleSeat")
            if not seat then
                -- check if seated in a vehicle seat elsewhere
                local hum = LP.Character and LP.Character:FindFirstChild("Humanoid")
                if hum and hum.SeatPart and hum.SeatPart:IsA("VehicleSeat") then
                    hum.SeatPart.MaxSpeed = cfg.VehicleSpeed
                end
            end
        end)
    end
end

-- ══════════════════════════════════════════════════════════════════════
-- MAIN LOOP
-- ══════════════════════════════════════════════════════════════════════
-- Connections toggled by cfg flags
local function applyAll()
    if Humanoid then
        Humanoid.WalkSpeed = cfg.SpeedBoost and cfg.WalkSpeed or 16
        Humanoid.JumpPower = cfg.JumpBoost  and cfg.JumpPower  or 50
    end
    setNoclip(cfg.Noclip)
    setFly(cfg.Fly)
    setInfiniteJump(cfg.InfiniteJump)
    setAntiAFK(cfg.AntiAFK)
    setGodMode(cfg.GodMode)
    setFullbright(cfg.Fullbright)
    setNoFog(cfg.NoFog)
    setSpinBot(cfg.SpinBot)
    setVehicleBoost(cfg.VehicleBoost)
    fovCircle.Visible = cfg.DrawFOV
    fovCircle.Radius  = cfg.FOVRadius
end

RunService.RenderStepped:Connect(function()
    -- FOV circle center
    local center = Camera.ViewportSize / 2
    fovCircle.Position = center
    fovCircle.Visible  = cfg.DrawFOV

    -- aimbot
    if cfg.Aimbot then aimbotTick() end

    -- ESP
    updateESP()

    -- live stat application
    if Humanoid then
        if cfg.SpeedBoost then Humanoid.WalkSpeed = cfg.WalkSpeed end
        if cfg.JumpBoost  then Humanoid.JumpPower = cfg.JumpPower  end
        if cfg.GodMode    then Humanoid.Health = Humanoid.MaxHealth end
        if cfg.NoRecoil then
            -- attempt to zero recoil via camera
        end
    end
end)

-- ══════════════════════════════════════════════════════════════════════
-- GUI  —  purple/dark AngelHub theme, mobile-first
-- ══════════════════════════════════════════════════════════════════════
-- destroy old instance if re-running
pcall(function()
    if CoreGui:FindFirstChild("AngelHubV3") then
        CoreGui:FindFirstChild("AngelHubV3"):Destroy()
    end
end)

local ScreenGui     = Instance.new("ScreenGui")
ScreenGui.Name      = "AngelHubV3"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LP:WaitForChild("PlayerGui") end

-- ── palette ──────────────────────────────────────────────────────────
local COL = {
    BG       = Color3.fromRGB(14,  10,  24),
    PANEL    = Color3.fromRGB(20,  14,  36),
    HEADER   = Color3.fromRGB(28,  18,  52),
    ACCENT   = Color3.fromRGB(140, 60, 255),
    ACCENT2  = Color3.fromRGB(180, 100, 255),
    BORDER   = Color3.fromRGB(100, 40, 200),
    TEXT     = Color3.fromRGB(220, 200, 255),
    DIM      = Color3.fromRGB(130, 110, 170),
    ON       = Color3.fromRGB(140, 60, 255),
    OFF      = Color3.fromRGB(50,  40,  70),
    WHITE    = Color3.new(1,1,1),
    GREEN    = Color3.fromRGB(60, 220, 100),
    RED      = Color3.fromRGB(220, 60, 60),
}

-- ── helpers ───────────────────────────────────────────────────────────
local function frame(parent, props)
    local f = Instance.new("Frame")
    f.BackgroundColor3 = props.Color or COL.PANEL
    f.BackgroundTransparency = props.Trans or 0
    f.BorderSizePixel = 0
    f.Size  = props.Size  or UDim2.new(1,0,1,0)
    f.Position = props.Pos or UDim2.new(0,0,0,0)
    f.ClipsDescendants = props.Clip or false
    f.Parent = parent
    if props.Corner then
        local c = Instance.new("UICorner", f)
        c.CornerRadius = UDim.new(0, props.Corner)
    end
    if props.Stroke then
        local s = Instance.new("UIStroke", f)
        s.Color     = COL.BORDER
        s.Thickness = props.Stroke
        s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    end
    return f
end

local function label(parent, text, size, color, props)
    local l = Instance.new("TextLabel")
    l.Text = text
    l.TextSize = size or 14
    l.TextColor3 = color or COL.TEXT
    l.Font = Enum.Font.GothamBold
    l.BackgroundTransparency = 1
    l.TextXAlignment = (props and props.XAlign) or Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.TextWrapped = true
    l.Size  = (props and props.Size) or UDim2.new(1,0,0,24)
    l.Position = (props and props.Pos) or UDim2.new(0,0,0,0)
    l.Parent = parent
    return l
end

local function btn(parent, text, callback, props)
    local b = Instance.new("TextButton")
    b.Text = text
    b.TextSize = (props and props.TextSize) or 13
    b.TextColor3 = (props and props.TextColor) or COL.TEXT
    b.Font = Enum.Font.GothamBold
    b.BackgroundColor3 = (props and props.BG) or COL.ACCENT
    b.BackgroundTransparency = 0.1
    b.BorderSizePixel = 0
    b.Size = (props and props.Size) or UDim2.new(1,0,0,36)
    b.Position = (props and props.Pos) or UDim2.new(0,0,0,0)
    b.AutoButtonColor = false
    b.Parent = parent
    if props and props.Corner then
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, props.Corner or 8)
    end
    -- hover tween
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), {
            BackgroundColor3 = COL.ACCENT2}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), {
            BackgroundColor3 = (props and props.BG) or COL.ACCENT}):Play()
    end)
    b.MouseButton1Click:Connect(callback or function() end)
    return b
end

-- toggle button  returns {frame, setState}
local function toggle(parent, labelText, key, onChange)
    local row = frame(parent, {Color=COL.PANEL, Trans=1,
                                Size=UDim2.new(1,0,0,40)})
    local lbl = label(row, labelText, 13, COL.TEXT,
                      {Size=UDim2.new(0.65,0,1,0), Pos=UDim2.new(0,8,0,0)})

    local track = frame(row, {Color=cfg[key] and COL.ON or COL.OFF,
                               Size=UDim2.new(0,52,0,26),
                               Pos =UDim2.new(1,-60,0.5,-13),
                               Corner=13})
    local knob  = frame(track,{Color=COL.WHITE,
                                Size=UDim2.new(0,20,0,20),
                                Pos =cfg[key] and UDim2.new(1,-24,0.5,-10)
                                              or  UDim2.new(0,4,0.5,-10),
                                Corner=10})

    local function setState(state)
        cfg[key] = state
        TweenService:Create(track, TweenInfo.new(0.15),
            {BackgroundColor3 = state and COL.ON or COL.OFF}):Play()
        TweenService:Create(knob,  TweenInfo.new(0.15),
            {Position = state and UDim2.new(1,-24,0.5,-10)
                              or  UDim2.new(0,4,0.5,-10)}):Play()
        if onChange then onChange(state) end
        applyAll()
    end

    local clickBtn = Instance.new("TextButton", row)
    clickBtn.Size  = UDim2.new(1,0,1,0)
    clickBtn.BackgroundTransparency = 1
    clickBtn.Text  = ""
    clickBtn.MouseButton1Click:Connect(function()
        setState(not cfg[key])
    end)

    return row, setState
end

-- slider  returns frame
local function slider(parent, labelText, key, minVal, maxVal, fmt)
    fmt = fmt or function(v) return tostring(math.floor(v)) end
    local col = frame(parent, {Color=COL.PANEL, Trans=1,
                                Size=UDim2.new(1,0,0,58)})
    local hdr = frame(col, {Color=COL.PANEL, Trans=1,
                             Size=UDim2.new(1,0,0,22)})
    local lbl = label(hdr, labelText, 12, COL.DIM,
                      {Size=UDim2.new(0.7,0,1,0), Pos=UDim2.new(0,8,0,0)})
    local vLbl= label(hdr, fmt(cfg[key]), 12, COL.ACCENT,
                      {Size=UDim2.new(0.3,0,1,0),
                       Pos=UDim2.new(0.7,0,0,0),
                       XAlign=Enum.TextXAlignment.Right})
    vLbl.Position = UDim2.new(0.7,-8,0,0)

    local track = frame(col, {Color=Color3.fromRGB(40,30,60),
                               Size=UDim2.new(1,-16,0,6),
                               Pos =UDim2.new(0,8,0,30),
                               Corner=3})
    local fill  = frame(track,{Color=COL.ACCENT,
                                Size=UDim2.new((cfg[key]-minVal)/(maxVal-minVal),0,1,0),
                                Corner=3})
    local knob  = frame(track, {Color=COL.WHITE,
                                 Size=UDim2.new(0,16,0,16),
                                 Pos =UDim2.new((cfg[key]-minVal)/(maxVal-minVal),0,0.5,-8),
                                 Corner=8})

    local dragging = false
    local function updateSlider(x)
        local abs = track.AbsolutePosition.X
        local w   = track.AbsoluteSize.X
        local t   = math.clamp((x - abs) / w, 0, 1)
        local v   = minVal + t*(maxVal-minVal)
        cfg[key]  = v
        vLbl.Text = fmt(v)
        fill.Size = UDim2.new(t, 0, 1, 0)
        knob.Position = UDim2.new(t, -8, 0.5, -8)
        applyAll()
    end

    knob.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging then
            if inp.UserInputType == Enum.UserInputType.MouseMovement then
                updateSlider(inp.Position.X)
            elseif inp.UserInputType == Enum.UserInputType.Touch then
                updateSlider(inp.Position.X)
            end
        end
    end)
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            updateSlider(inp.Position.X)
            dragging = true
        end
    end)

    return col
end

-- section header
local function sectionHeader(parent, text)
    local row = frame(parent, {Color=COL.PANEL, Trans=1,
                                Size=UDim2.new(1,0,0,30)})
    local lbl = label(row, text, 11, COL.ACCENT,
                      {Size=UDim2.new(1,-16,1,0), Pos=UDim2.new(0,8,0,0)})
    lbl.Font = Enum.Font.GothamBold
    local line = frame(row, {Color=COL.BORDER, Trans=0.6,
                              Size=UDim2.new(1,-16,0,1),
                              Pos =UDim2.new(0,8,1,-1)})
    return row
end

-- scrollable content list
local function scrollList(parent, height)
    local sv = Instance.new("ScrollingFrame")
    sv.Size = UDim2.new(1,0,1,height and -height or 0)
    sv.Position = UDim2.new(0,0,0,height or 0)
    sv.CanvasSize = UDim2.new(0,0,0,0)
    sv.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sv.ScrollBarThickness = 3
    sv.ScrollBarImageColor3 = COL.ACCENT
    sv.BackgroundTransparency = 1
    sv.BorderSizePixel = 0
    sv.ScrollingDirection = Enum.ScrollingDirection.Y
    sv.Parent = parent

    local layout = Instance.new("UIListLayout", sv)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0,4)

    local pad = Instance.new("UIPadding", sv)
    pad.PaddingLeft   = UDim.new(0,8)
    pad.PaddingRight  = UDim.new(0,8)
    pad.PaddingTop    = UDim.new(0,6)
    pad.PaddingBottom = UDim.new(0,6)

    return sv
end

-- ── ROOT FRAME ────────────────────────────────────────────────────────
local menuVisible = true
local Root = frame(ScreenGui, {
    Color  = COL.BG,
    Size   = UDim2.new(0, 580, 0, 420),
    Pos    = UDim2.new(0.5,-290, 0.5,-210),
    Corner = 14,
    Stroke = 1.5,
})

-- draggable
do
    local dragging, dragStart, startPos
    Root.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = inp.Position
            startPos  = Root.Position
        end
    end)
    Root.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and (
            inp.UserInputType == Enum.UserInputType.MouseMovement or
            inp.UserInputType == Enum.UserInputType.Touch) then
            local delta = inp.Position - dragStart
            Root.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- ── HEADER ────────────────────────────────────────────────────────────
local Header = frame(Root, {
    Color  = COL.HEADER,
    Size   = UDim2.new(1,0,0,52),
    Corner = 14,
})
-- hide bottom corners of header
local headerPatch = frame(Root, {
    Color = COL.HEADER,
    Size  = UDim2.new(1,0,0,14),
    Pos   = UDim2.new(0,0,0,38),
})

-- logo placeholder (purple circle with AH)
local logoBG = frame(Header, {
    Color  = COL.ACCENT,
    Size   = UDim2.new(0,38,0,38),
    Pos    = UDim2.new(0,8,0.5,-19),
    Corner = 10,
})
local logoTxt = label(logoBG, "AH", 14, COL.WHITE,
    {Size=UDim2.new(1,0,1,0), XAlign=Enum.TextXAlignment.Center})
logoTxt.TextYAlignment = Enum.TextYAlignment.Center

-- title
local titleLbl = label(Header, "AngelHub  |  "..VERSION, 18, COL.ACCENT2,
    {Size=UDim2.new(0,220,1,0), Pos=UDim2.new(0,54,0,0),
     XAlign=Enum.TextXAlignment.Left})
titleLbl.Font = Enum.Font.GothamBold

-- discord field + copy
local discFrame = frame(Header, {
    Color  = Color3.fromRGB(30,20,55),
    Size   = UDim2.new(0,230,0,30),
    Pos    = UDim2.new(1,-300,0.5,-15),
    Corner = 8,
    Stroke = 1,
})
local discLbl = label(discFrame, DISCORD, 11, COL.ACCENT,
    {Size=UDim2.new(1,-50,1,0), Pos=UDim2.new(0,8,0,0)})
local copyBtn = btn(discFrame, "Copy", function()
    setclipboard(DISCORD)
    copyBtn.Text = "Copied!"
    task.delay(1.5, function() copyBtn.Text = "Copy" end)
end, {
    Size   = UDim2.new(0,44,0,24),
    Pos    = UDim2.new(1,-48,0.5,-12),
    BG     = COL.ACCENT,
    Corner = 6,
    TextSize = 11,
})

-- close / toggle button in header
local closeBtn = btn(Header, "✕", function()
    menuVisible = false
    Root.Visible = false
    toggleBtn.Visible = true
end, {
    Size   = UDim2.new(0,30,0,30),
    Pos    = UDim2.new(1,-38,0.5,-15),
    BG     = Color3.fromRGB(80,20,20),
    Corner = 8,
    TextSize = 14,
})

-- keybind label
local keyLbl = label(Header, "Menu: [RightShift]", 10, COL.DIM,
    {Size=UDim2.new(0,120,0,16),
     Pos =UDim2.new(0,54,1,-18),
     XAlign=Enum.TextXAlignment.Left})

-- ── SIDEBAR ───────────────────────────────────────────────────────────
local Sidebar = frame(Root, {
    Color  = COL.PANEL,
    Size   = UDim2.new(0,130,1,-52),
    Pos    = UDim2.new(0,0,0,52),
})
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0,12)

local sideLayout = Instance.new("UIListLayout", Sidebar)
sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
sideLayout.Padding = UDim.new(0,4)
local sidePad = Instance.new("UIPadding", Sidebar)
sidePad.PaddingLeft   = UDim.new(0,8)
sidePad.PaddingRight  = UDim.new(0,8)
sidePad.PaddingTop    = UDim.new(0,8)

-- ── CONTENT AREA ──────────────────────────────────────────────────────
local ContentArea = frame(Root, {
    Color  = COL.BG,
    Size   = UDim2.new(1,-134,1,-56),
    Pos    = UDim2.new(0,132,0,54),
    Corner = 10,
})

-- ── TABS ──────────────────────────────────────────────────────────────
local tabs      = {}
local tabFrames = {}
local activeTab = nil

local TAB_DEFS = {
    {name="Combat",   icon="⚔"},
    {name="Visuals",  icon="👁"},
    {name="Misc",     icon="⚙"},
    {name="World",    icon="🌐"},
    {name="SDRP",     icon="🚔"},
    {name="Settings", icon="⚙"},
}

local function switchTab(name)
    for n, f in pairs(tabFrames) do
        f.Visible = (n == name)
    end
    for n, b in pairs(tabs) do
        b.BackgroundColor3 = (n == name) and COL.ACCENT or COL.OFF
        b.TextColor3       = (n == name) and COL.WHITE  or COL.DIM
    end
    activeTab = name
end

for i, td in ipairs(TAB_DEFS) do
    local b = Instance.new("TextButton")
    b.Text = td.icon .. "  " .. td.name
    b.TextSize = 13
    b.Font = Enum.Font.GothamBold
    b.TextColor3 = COL.DIM
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.BackgroundColor3 = COL.OFF
    b.BackgroundTransparency = 0.1
    b.BorderSizePixel = 0
    b.Size = UDim2.new(1,0,0,38)
    b.AutoButtonColor = false
    b.LayoutOrder = i
    b.Parent = Sidebar
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
    local lp = Instance.new("UIPadding", b)
    lp.PaddingLeft = UDim.new(0,8)

    local f = frame(ContentArea, {
        Color = COL.BG,
        Size  = UDim2.new(1,0,1,0),
        Trans = 0,
    })
    f.Visible = false

    b.MouseButton1Click:Connect(function() switchTab(td.name) end)
    tabs[td.name]      = b
    tabFrames[td.name] = f
end

-- ── BUILD COMBAT TAB ──────────────────────────────────────────────────
do
    local f  = tabFrames["Combat"]
    local sl = scrollList(f, 0)

    -- two-column layout
    local cols = frame(sl, {Color=COL.BG, Trans=1, Size=UDim2.new(1,0,0,1)})
    cols.AutomaticSize = Enum.AutomaticSize.Y
    local colLayout = Instance.new("UIListLayout", cols)
    colLayout.FillDirection = Enum.FillDirection.Horizontal
    colLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- left col
    local left = frame(cols, {Color=COL.BG, Trans=1, Size=UDim2.new(0.5,-4,0,1)})
    left.AutomaticSize = Enum.AutomaticSize.Y
    local ll = Instance.new("UIListLayout", left)
    ll.SortOrder = Enum.SortOrder.LayoutOrder
    ll.Padding = UDim.new(0,4)
    local lp = Instance.new("UIPadding", left)
    lp.PaddingRight = UDim.new(0,4)

    -- right col
    local right = frame(cols, {Color=COL.BG, Trans=1, Size=UDim2.new(0.5,0,0,1)})
    right.AutomaticSize = Enum.AutomaticSize.Y
    local rl = Instance.new("UIListLayout", right)
    rl.SortOrder = Enum.SortOrder.LayoutOrder
    rl.Padding = UDim.new(0,4)

    -- left: AIM & FOV
    local lh = sectionHeader(left, "AIM & FOV") lh.LayoutOrder=1
    local t1,_ = toggle(left, "Silent Aim",    "SilentAim") t1.LayoutOrder=2
    local t2,_ = toggle(left, "Aimbot",        "Aimbot")    t2.LayoutOrder=3
    local t3,_ = toggle(left, "Draw FOV",      "DrawFOV")   t3.LayoutOrder=4
    local t4,_ = toggle(left, "Prediction",    "Prediction")t4.LayoutOrder=5
    local s1   = slider(left, "Smoothness",    "AimbotSmooth", 0.05, 1,
        function(v) return math.floor(v*100).."%"  end) s1.LayoutOrder=6
    local s2   = slider(left, "FOV Radius",    "FOVRadius", 50, 400,
        function(v) return math.floor(v).." px" end) s2.LayoutOrder=7

    -- right: WEAPON & TARGETING
    local rh = sectionHeader(right, "WEAPON & TARGETING") rh.LayoutOrder=1
    local r1,_ = toggle(right,"Wall Check",    "WallCheck")    r1.LayoutOrder=2
    local r2,_ = toggle(right,"Team Check",    "TeamCheck")    r2.LayoutOrder=3
    local r3,_ = toggle(right,"No Recoil",     "NoRecoil")     r3.LayoutOrder=4
    local r4,_ = toggle(right,"No Spread",     "NoSpread")     r4.LayoutOrder=5
    local r5,_ = toggle(right,"Rapid Fire",    "RapidFire")    r5.LayoutOrder=6
    local r6,_ = toggle(right,"Infinite Ammo", "InfiniteAmmo") r6.LayoutOrder=7

    -- target part label
    local tpLbl = label(right, "Target: "..cfg.TargetPart, 11, COL.ACCENT,
        {Size=UDim2.new(1,0,0,24), Pos=UDim2.new(0,0,0,0)})
    tpLbl.LayoutOrder = 8
    tpLbl.Parent = right
    local parts = {"Head","Torso","HumanoidRootPart","UpperTorso"}
    local partIdx = 1
    local partBtn = btn(right, "Part: "..parts[partIdx], function()
        partIdx = partIdx % #parts + 1
        cfg.TargetPart = parts[partIdx]
        partBtn.Text   = "Part: "..parts[partIdx]
    end, {Size=UDim2.new(1,0,0,32), BG=COL.OFF, Corner=8, TextSize=12})
    partBtn.LayoutOrder = 9
    partBtn.Parent = right

    -- keybind footer
    local kf = frame(f, {Color=COL.HEADER, Size=UDim2.new(1,0,0,36),
                          Pos=UDim2.new(0,0,1,-36), Corner=8})
    local kl = label(kf, "Menu Keybind: [RightShift]", 12, COL.DIM,
        {Size=UDim2.new(1,0,1,0), XAlign=Enum.TextXAlignment.Center})
end

-- ── BUILD VISUALS TAB ─────────────────────────────────────────────────
do
    local f  = tabFrames["Visuals"]
    local sl = scrollList(f, 0)

    sectionHeader(sl, "ESP").Parent = sl
    toggle(sl,"ESP Master",    "ESP")
    toggle(sl,"Box ESP",       "BoxESP")
    toggle(sl,"Name ESP",      "NameESP")
    toggle(sl,"Health Bar",    "HealthBar")
    toggle(sl,"Skeleton ESP",  "SkeletonESP")
    toggle(sl,"Distance ESP",  "DistanceESP")
    toggle(sl,"Tracer Lines",  "TracerESP")
    toggle(sl,"Chams",         "Chams")
end

-- ── BUILD MISC TAB ────────────────────────────────────────────────────
do
    local f  = tabFrames["Misc"]
    local sl = scrollList(f, 0)

    sectionHeader(sl, "MOVEMENT")
    toggle(sl,"Noclip",       "Noclip",       function(v) setNoclip(v) end)
    toggle(sl,"Speed Boost",  "SpeedBoost")
    slider(sl,"Walk Speed",   "WalkSpeed",    1, 500,
        function(v) return math.floor(v).." studs/s" end)
    toggle(sl,"Jump Boost",   "JumpBoost")
    slider(sl,"Jump Power",   "JumpPower",    1, 500)
    toggle(sl,"Infinite Jump","InfiniteJump", function(v) setInfiniteJump(v) end)
    toggle(sl,"Fly",          "Fly",          function(v) setFly(v) end)
    slider(sl,"Fly Speed",    "FlySpeed",     1, 500)

    sectionHeader(sl, "PLAYER")
    toggle(sl,"God Mode",     "GodMode",      function(v) setGodMode(v) end)
    toggle(sl,"Anti Ragdoll", "AntiRagdoll")
    toggle(sl,"Anti AFK",     "AntiAFK",      function(v) setAntiAFK(v) end)
    toggle(sl,"Spin Bot",     "SpinBot",      function(v) setSpinBot(v) end)
    slider(sl,"Spin Speed",   "SpinSpeed",    1, 50)
    toggle(sl,"Auto Respawn", "AutoRespawn")
end

-- ── BUILD WORLD TAB ───────────────────────────────────────────────────
do
    local f  = tabFrames["World"]
    local sl = scrollList(f, 0)

    sectionHeader(sl, "WORLD")
    toggle(sl,"No Fog",    "NoFog",       function(v) setNoFog(v) end)
    toggle(sl,"Fullbright","Fullbright",  function(v) setFullbright(v) end)
    toggle(sl,"Radar",     "Radar")
    toggle(sl,"FPS Boost", "FPSBoost",   function(v)
        settings().Rendering.QualityLevel = v
            and Enum.QualityLevel.Level01
            or  Enum.QualityLevel.Automatic
    end)
end

-- ── BUILD SAN DIEGO RP TAB ────────────────────────────────────────────
do
    local f  = tabFrames["SDRP"]
    local sl = scrollList(f, 0)

    sectionHeader(sl, "LAW ENFORCEMENT")
    toggle(sl,"Cop ESP",        "CopESP")
    toggle(sl,"Criminal ESP",   "CriminalESP")
    toggle(sl,"Wanted ESP",     "WantedESP")
    toggle(sl,"Auto Arrest",    "AutoArrest")
    toggle(sl,"Auto Cuff",      "AutoCuff")
    toggle(sl,"Auto Taser",     "AutoTaser")

    sectionHeader(sl, "VEHICLE")
    toggle(sl,"Vehicle Boost",  "VehicleBoost", function(v) setVehicleBoost(v) end)
    slider(sl,"Vehicle Speed",  "VehicleSpeed", 50, 500,
        function(v) return math.floor(v).." mph" end)
    toggle(sl,"Noclip Vehicle", "NoClipVehicle")
    toggle(sl,"Anti Flip",      "AntiVehicleFlip")

    sectionHeader(sl, "MOBILITY")
    toggle(sl,"Auto Evade",     "AutoEvade")

    sectionHeader(sl, "TELEPORT")
    btn(sl, "Teleport to Spawn", function()
        local spawn = Workspace:FindFirstChild("SpawnLocation")
        if spawn and HRP then
            HRP.CFrame = CFrame.new(spawn.Position + Vector3.new(0,5,0))
        end
    end, {Size=UDim2.new(1,0,0,36), BG=COL.ACCENT, Corner=8, TextSize=13}).Parent = sl
    btn(sl, "Teleport to Nearest Player", function()
        local t = getClosestPlayer()
        if t and t.Character and HRP then
            HRP.CFrame = t.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,4)
        end
    end, {Size=UDim2.new(1,0,0,36), BG=COL.ACCENT, Corner=8, TextSize=13}).Parent = sl
end

-- ── BUILD SETTINGS TAB ────────────────────────────────────────────────
do
    local f  = tabFrames["Settings"]
    local sl = scrollList(f, 0)

    sectionHeader(sl, "INTERFACE")
    btn(sl, "Copy Discord Link", function()
        setclipboard(DISCORD)
    end, {Size=UDim2.new(1,0,0,36), BG=COL.ACCENT, Corner=8, TextSize=13}).Parent = sl

    sectionHeader(sl, "ABOUT")
    label(sl, "AngelHub "..VERSION.."  —  "..GAME_NAME, 12, COL.DIM,
        {Size=UDim2.new(1,0,0,24)}).Parent = sl
    label(sl, "discord.gg/d8gpXNGknP", 12, COL.ACCENT,
        {Size=UDim2.new(1,0,0,24)}).Parent = sl
    label(sl, "RightShift → toggle menu", 11, COL.DIM,
        {Size=UDim2.new(1,0,0,22)}).Parent = sl
end

-- start on Combat
switchTab("Combat")

-- ── FLOATING TOGGLE BUTTON (mobile / when menu hidden) ────────────────
local toggleBtn = frame(ScreenGui, {
    Color  = COL.ACCENT,
    Size   = UDim2.new(0,100,0,38),
    Pos    = UDim2.new(0,20,0,80),
    Corner = 10,
})
toggleBtn.Visible = false

local toggleBtnLabel = Instance.new("TextButton", toggleBtn)
toggleBtnLabel.Size = UDim2.new(1,0,1,0)
toggleBtnLabel.BackgroundTransparency = 1
toggleBtnLabel.Text = "AngelHub"
toggleBtnLabel.TextColor3 = COL.WHITE
toggleBtnLabel.TextSize = 13
toggleBtnLabel.Font = Enum.Font.GothamBold
toggleBtnLabel.MouseButton1Click:Connect(function()
    menuVisible = true
    Root.Visible = true
    toggleBtn.Visible = false
end)

-- drag the toggle button
do
    local dragging, dragStart, startPos
    toggleBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = inp.Position
            startPos  = toggleBtn.Position
        end
    end)
    toggleBtn.InputEnded:Connect(function(inp)
        dragging = false
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and (
            inp.UserInputType == Enum.UserInputType.MouseMovement or
            inp.UserInputType == Enum.UserInputType.Touch) then
            local delta = inp.Position - dragStart
            toggleBtn.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- ── KEYBOARD TOGGLE ───────────────────────────────────────────────────
UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == cfg.MenuKey then
        menuVisible = not menuVisible
        Root.Visible = menuVisible
        toggleBtn.Visible = not menuVisible
    end
end)

-- ── NOTIFY ───────────────────────────────────────────────────────────
pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title   = "AngelHub v3.0",
        Text    = "Loaded! RightShift to toggle.",
        Duration= 4,
    })
end)

applyAll()
print("[AngelHub v3.0] Loaded — San Diego RP Border — "..DISCORD)
