--[[
    AngelHub v3.3  |  San Diego RP Border  |  WindUI edition
    Mobile + PC.  UI: WindUI (Footagesus).  ESP/FOV are plain GUI objects, so no Drawing library is needed.

    NOT TESTED IN A REAL EXECUTOR. Written without access to Roblox or an executor.
    WindUI calls are wrapped in pcall, so one API difference won't kill the rest of the script.
    Silent aim, gun mods, wanted detection and role detection are generic heuristics. Check the status labels.
]]

local VERSION     = "v3.3"
local DISCORD_URL = "https://discord.gg/d8gpXNGknP"
local WIND_URL    = "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"

-- ============================================================ single instance / unload
local GENV = (type(getgenv) == "function" and getgenv()) or nil
if GENV and type(GENV.__AngelHubUnload) == "function" then pcall(GENV.__AngelHubUnload) end

local cloneref = cloneref or function(o) return o end
local function svc(n) local ok, s = pcall(function() return cloneref(game:GetService(n)) end) return ok and s or nil end

local Players, RunService, UIS = svc("Players"), svc("RunService"), svc("UserInputService")
local Lighting, CoreGui, StarterGui = svc("Lighting"), svc("CoreGui"), svc("StarterGui")
local PPS, Teams, Workspace = svc("ProximityPromptService"), svc("Teams"), svc("Workspace")
local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local IS_MOBILE = UIS.TouchEnabled and not UIS.KeyboardEnabled and not UIS.MouseEnabled

local connections, cleanups = {}, {}
local function conn(c) connections[#connections + 1] = c return c end
local function onUnload(f) cleanups[#cleanups + 1] = f end

local function rnd(n) local t = {} for i = 1, n do t[i] = string.char(math.random(97, 122)) end return table.concat(t) end

-- ============================================================ config
local cfg = {
    Aimbot = false, AimMode = "Hold", AimFOV = 150, AimSmooth = 35, AimPart = "Head",
    DrawFOV = true, FillFOV = false, WallCheck = true, TeamCheck = true, Prediction = false, PredictMs = 100,
    TargetFilter = "All",
    Silent = false, SilentFOV = 120, SilentPart = "Head", SilentHit = 100, SilentDrawFOV = false, SilentMethod = "Auto",
    NoRecoil = false, NoSpread = false, InfAmmo = false,

    ESP = false, ESPBox = true, ESPName = true, ESPHealth = true, ESPDist = true, ESPTracer = false,
    ESPSkeleton = false, ESPChams = false, ESPMaxDist = 1500,
    ShowCops = true, ShowCriminals = true, ShowOthers = true, WantedTag = true, Radar = false, RadarRange = 200,

    Noclip = false, Speed = false, SpeedMode = "WalkSpeed", SpeedVal = 40,
    Jump = false, JumpVal = 80, InfJump = false,
    Fly = false, FlySpeed = 60, AntiRagdoll = false, AntiAFK = true, Spin = false, SpinSpeed = 20,

    Fullbright = false, NoFog = false, TimeOfDay = "Default",

    VehicleBoost = false, VehicleSpeed = 120, AntiFlip = false,
    CopAlert = false, CopAlertDist = 80, InstantPrompts = false, AutoArrest = false,

    MobileHUD = IS_MOBILE,
    TeamRoles = {},
}
local CFG_FILE = "AngelHub_v33.json"

-- ============================================================ helpers
local G_WIND, G_ERR_SHOWN
local function notify(title, content, dur)
    if G_WIND and G_WIND.Notify then
        pcall(function() G_WIND:Notify({ Title = title, Content = content, Duration = dur or 3 }) end)
    else
        pcall(function() StarterGui:SetCore("SendNotification", { Title = title, Text = content, Duration = dur or 3 }) end)
    end
end

local function copyText(s)
    local fns = { setclipboard, toclipboard, set_clipboard, (type(Clipboard) == "table" and Clipboard.set) or nil }
    for _, f in pairs(fns) do
        if type(f) == "function" then
            local ok = pcall(f, s)
            if ok then return true end
        end
    end
    return false
end

local function char() return LP.Character end
local function hum() local c = LP.Character return c and c:FindFirstChildOfClass("Humanoid") end
local function root() local c = LP.Character return c and c:FindFirstChild("HumanoidRootPart") end

local function alive(p)
    local c = p.Character
    if not c then return nil end
    local h = c:FindFirstChildOfClass("Humanoid")
    local r = c:FindFirstChild("HumanoidRootPart")
    if h and r and h.Health > 0 then return c, h, r end
    return nil
end

-- ============================================================ roles / wanted
local COP_LONG  = { "police", "sheriff", "patrol", "trooper", "deputy", "officer", "border", "military", "marine", "army", "guard", "security", "enforcement", "swat", "customs" }
local COP_WORD  = { cop = true, cbp = true, ice = true, fbi = true, dea = true, atf = true, lapd = true, sdpd = true, usbp = true }
local CRIM_LONG = { "criminal", "cartel", "gang", "mafia", "smuggler", "thief", "robber", "outlaw", "inmate", "prisoner", "convict", "felon", "bandit", "terror", "suspect", "wanted" }
local CRIM_WORD = { mob = true }

local function words(s) local t = {} for w in string.gmatch(string.lower(s), "%a+") do t[w] = true end return t end

local function teamRole(name)
    local m = cfg.TeamRoles[name]
    if m and m ~= "Auto" then return m end
    local low, w = string.lower(name), words(name)
    for _, k in ipairs(CRIM_LONG) do if string.find(low, k, 1, true) then return "Criminal" end end
    for k in pairs(CRIM_WORD) do if w[k] then return "Criminal" end end
    for _, k in ipairs(COP_LONG) do if string.find(low, k, 1, true) then return "Cop" end end
    for k in pairs(COP_WORD) do if w[k] then return "Cop" end end
    return "Other"
end

local function roleOf(p)
    local t = p.Team
    if not t then return "Other" end
    return teamRole(t.Name)
end

local WANT_KEYS = { "wanted", "bounty", "crime", "heat", "stars" }
local wantedCache = {}
local function matchesWanted(name) local l = string.lower(name) for _, k in ipairs(WANT_KEYS) do if string.find(l, k, 1, true) then return true end end return false end

local function isWanted(p)
    local now = os.clock()
    local c = wantedCache[p]
    if c and now - c.t < 1 then return c.v end
    local v = false
    pcall(function()
        local ls = p:FindFirstChild("leaderstats")
        if ls then
            for _, x in ipairs(ls:GetChildren()) do
                if matchesWanted(x.Name) and x.Value ~= nil and x.Value ~= 0 and x.Value ~= false and x.Value ~= "" then v = true end
            end
        end
        for n, val in pairs(p:GetAttributes()) do
            if matchesWanted(n) and val ~= 0 and val ~= false and val ~= "" then v = true end
        end
        local ch = p.Character
        if ch then
            for n, val in pairs(ch:GetAttributes()) do
                if matchesWanted(n) and val ~= 0 and val ~= false and val ~= "" then v = true end
            end
        end
    end)
    wantedCache[p] = { t = now, v = v }
    return v
end

local function passesFilter(p, f)
    if f == "All" then return true end
    if f == "Wanted" then return isWanted(p) end
    if f == "Cops" then return roleOf(p) == "Cop" end
    if f == "Criminals" then return roleOf(p) == "Criminal" end
    return true
end

-- ============================================================ targeting
local function fovCenter()
    if IS_MOBILE then return Camera.ViewportSize / 2 end
    return UIS:GetMouseLocation()
end

local function resolvePart(c, mode)
    if mode == "Head" then return c:FindFirstChild("Head") end
    if mode == "Torso" then return c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso") end
    if mode == "Root" then return c:FindFirstChild("HumanoidRootPart") end
    return c:FindFirstChild("Head") or c:FindFirstChild("HumanoidRootPart")
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
local function visible(part, tchar)
    local origin = Camera.CFrame.Position
    local ignore = { LP.Character, Camera }
    for _ = 1, 4 do
        rayParams.FilterDescendantsInstances = ignore
        local res = Workspace:Raycast(origin, part.Position - origin, rayParams)
        if not res then return true end
        local h = res.Instance
        if h:IsDescendantOf(tchar) then return true end
        if h.Transparency >= 0.9 or not h.CanCollide then ignore[#ignore + 1] = h else return false end
    end
    return false
end

local function aimPos(part)
    local p = part.Position
    if cfg.Prediction then p = p + part.AssemblyLinearVelocity * (cfg.PredictMs / 1000) end
    return p
end

local function pickTarget(fov, partMode, wall)
    local center = fovCenter()
    local cands = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and not (cfg.TeamCheck and LP.Team ~= nil and p.Team == LP.Team) and passesFilter(p, cfg.TargetFilter) then
            local c = alive(p)
            if c then
                local part = resolvePart(c, partMode)
                if part then
                    local v, on = Camera:WorldToViewportPoint(part.Position)
                    if on then
                        local d = (Vector2.new(v.X, v.Y) - Vector2.new(center.X, center.Y)).Magnitude
                        if d <= fov then cands[#cands + 1] = { d = d, part = part, char = c, plr = p } end
                    end
                end
            end
        end
    end
    table.sort(cands, function(a, b) return a.d < b.d end)
    for _, t in ipairs(cands) do
        if not wall or visible(t.part, t.char) then return t end
    end
    return nil
end

-- ============================================================ overlay (GUI only, no Drawing)
local function guiParent()
    if type(gethui) == "function" then local ok, h = pcall(gethui) if ok and h then return h end end
    if CoreGui then
        local ok = pcall(function() local t = Instance.new("Folder") t.Parent = CoreGui t:Destroy() end)
        if ok then return CoreGui end
    end
    return LP:WaitForChild("PlayerGui")
end
local GUI_PARENT = guiParent()

local overlay = Instance.new("ScreenGui")
overlay.Name = rnd(10); overlay.ResetOnSpawn = false; overlay.IgnoreGuiInset = true
overlay.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; overlay.DisplayOrder = 20
if type(syn) == "table" and syn.protect_gui then pcall(syn.protect_gui, overlay) end
overlay.Parent = GUI_PARENT
onUnload(function() overlay:Destroy() end)

local ACCENT = Color3.fromRGB(140, 60, 255)
local COLORS = { Cop = Color3.fromRGB(70, 140, 255), Criminal = Color3.fromRGB(255, 70, 70), Other = Color3.fromRGB(235, 235, 235), Wanted = Color3.fromRGB(255, 200, 0) }

local function mkFrame(parent, name)
    local f = Instance.new("Frame")
    f.Name = name or "f"; f.BackgroundTransparency = 1; f.BorderSizePixel = 0; f.Visible = false
    f.Parent = parent
    return f
end
local function mkText(parent, size)
    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1; t.Font = Enum.Font.GothamBold; t.TextSize = size or 13
    t.TextStrokeTransparency = 0.3; t.Visible = false; t.Size = UDim2.fromOffset(160, 14)
    t.AnchorPoint = Vector2.new(0.5, 0); t.Text = ""
    t.Parent = parent
    return t
end
local function mkLine(parent)
    local f = Instance.new("Frame")
    f.BorderSizePixel = 0; f.AnchorPoint = Vector2.new(0.5, 0.5); f.Visible = false
    f.Parent = parent
    return f
end
local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end
local function setLine(f, x1, y1, x2, y2, th, col)
    local dx, dy = x2 - x1, y2 - y1
    f.Size = UDim2.fromOffset(math.sqrt(dx * dx + dy * dy), th)
    f.Position = UDim2.fromOffset((x1 + x2) / 2, (y1 + y2) / 2)
    f.Rotation = math.deg(atan2(dy, dx))
    f.BackgroundColor3 = col
    f.Visible = true
end

-- FOV circles
local function mkCircle(color)
    local f = Instance.new("Frame")
    f.AnchorPoint = Vector2.new(0.5, 0.5); f.BackgroundColor3 = color; f.BackgroundTransparency = 1
    f.BorderSizePixel = 0; f.Visible = false; f.Parent = overlay
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(1, 0) c.Parent = f
    local s = Instance.new("UIStroke") s.Color = color s.Thickness = 1.5 s.Parent = f
    return f, s
end
local aimCircle, aimStroke = mkCircle(ACCENT)
local silentCircle = mkCircle(Color3.fromRGB(255, 90, 90))

-- Cop alert label
local alertLabel = mkText(overlay, 18)
alertLabel.AnchorPoint = Vector2.new(0.5, 0); alertLabel.Position = UDim2.new(0.5, 0, 0, 40)
alertLabel.Size = UDim2.fromOffset(300, 24); alertLabel.TextColor3 = COLORS.Cop

-- radar
local radar = Instance.new("Frame")
radar.Size = UDim2.fromOffset(130, 130); radar.Position = UDim2.fromOffset(12, 90)
radar.BackgroundColor3 = Color3.fromRGB(10, 8, 20); radar.BackgroundTransparency = 0.25; radar.Visible = false
radar.Parent = overlay
do
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(1, 0) c.Parent = radar
    local s = Instance.new("UIStroke") s.Color = ACCENT s.Thickness = 1.5 s.Parent = radar
    local me = Instance.new("Frame") me.Size = UDim2.fromOffset(6, 6) me.AnchorPoint = Vector2.new(0.5, 0.5)
    me.Position = UDim2.fromScale(0.5, 0.5) me.BackgroundColor3 = Color3.new(1, 1, 1) me.BorderSizePixel = 0 me.Parent = radar
end
local radarDots = {}

-- mobile HUD buttons (hold AIM, fly up/down)
local hud = { aimHeld = false, up = false, down = false }
local function mkHudButton(text, ypos, key)
    local b = Instance.new("TextButton")
    b.Text = text; b.Size = UDim2.fromOffset(64, 64); b.AnchorPoint = Vector2.new(1, 0.5)
    b.Position = UDim2.new(1, -14, ypos, 0); b.BackgroundColor3 = Color3.fromRGB(25, 18, 45)
    b.BackgroundTransparency = 0.15; b.TextColor3 = Color3.new(1, 1, 1); b.Font = Enum.Font.GothamBold; b.TextSize = 16
    b.AutoButtonColor = false; b.Visible = false; b.Parent = overlay
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(1, 0) c.Parent = b
    local s = Instance.new("UIStroke") s.Color = ACCENT s.Thickness = 2 s.Parent = b
    conn(b.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then hud[key] = true end
    end))
    conn(b.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then hud[key] = false end
    end))
    return b
end
local btnAim  = mkHudButton("AIM", 0.40, "aimHeld")
local btnUp   = mkHudButton("UP", 0.56, "up")
local btnDown = mkHudButton("DOWN", 0.72, "down")

-- ============================================================ ESP
local esp = {}
local SKEL_R15 = { { "Head", "UpperTorso" }, { "UpperTorso", "LowerTorso" }, { "UpperTorso", "LeftUpperArm" }, { "LeftUpperArm", "LeftLowerArm" }, { "LeftLowerArm", "LeftHand" },
    { "UpperTorso", "RightUpperArm" }, { "RightUpperArm", "RightLowerArm" }, { "RightLowerArm", "RightHand" }, { "LowerTorso", "LeftUpperLeg" }, { "LeftUpperLeg", "LeftLowerLeg" },
    { "LeftLowerLeg", "LeftFoot" }, { "LowerTorso", "RightUpperLeg" }, { "RightUpperLeg", "RightLowerLeg" }, { "RightLowerLeg", "RightFoot" } }
local SKEL_R6 = { { "Head", "Torso" }, { "Torso", "Left Arm" }, { "Torso", "Right Arm" }, { "Torso", "Left Leg" }, { "Torso", "Right Leg" } }

local function newESP()
    local o = {}
    o.box = mkFrame(overlay, "b")
    local st = Instance.new("UIStroke") st.Thickness = 1.5 st.Parent = o.box o.stroke = st
    o.name = mkText(overlay, 13); o.dist = mkText(overlay, 11); o.tag = mkText(overlay, 12)
    o.hpBack = mkFrame(overlay, "hb"); o.hpBack.BackgroundColor3 = Color3.fromRGB(20, 20, 20); o.hpBack.BackgroundTransparency = 0.2
    o.hp = mkFrame(overlay, "h"); o.hp.BackgroundTransparency = 0
    o.tracer = mkLine(overlay)
    o.skel = {}
    return o
end
local function hideESP(o)
    o.box.Visible = false o.name.Visible = false o.dist.Visible = false o.tag.Visible = false
    o.hpBack.Visible = false o.hp.Visible = false o.tracer.Visible = false
    for _, l in ipairs(o.skel) do l.Visible = false end
    if o.hl then o.hl.Enabled = false end
end
local function destroyESP(p)
    local o = esp[p]
    if not o then return end
    pcall(function()
        o.box:Destroy() o.name:Destroy() o.dist:Destroy() o.tag:Destroy() o.hpBack:Destroy() o.hp:Destroy() o.tracer:Destroy()
        for _, l in ipairs(o.skel) do l:Destroy() end
        if o.hl then o.hl:Destroy() end
    end)
    esp[p] = nil
end
conn(Players.PlayerRemoving:Connect(function(p) destroyESP(p) wantedCache[p] = nil end))
onUnload(function() for p in pairs(esp) do destroyESP(p) end end)

local function roleAllowed(role)
    if role == "Cop" then return cfg.ShowCops end
    if role == "Criminal" then return cfg.ShowCriminals end
    return cfg.ShowOthers
end

local function updateESP()
    local myRoot = root()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local o = esp[p]
            if not o then o = newESP() esp[p] = o end
            local c, h, r = alive(p)
            local role = roleOf(p)
            local wanted = cfg.WantedTag and isWanted(p)
            local show = cfg.ESP and c and (roleAllowed(role) or wanted)
            if show and myRoot and (r.Position - myRoot.Position).Magnitude > cfg.ESPMaxDist then show = false end
            if not show then
                hideESP(o)
            else
                local head = c:FindFirstChild("Head")
                local topW = (head and head.Position or r.Position + Vector3.new(0, 2.5, 0)) + Vector3.new(0, 0.7, 0)
                local botW = r.Position - Vector3.new(0, math.max(3, h.HipHeight + r.Size.Y / 2), 0)
                local tv, tOn = Camera:WorldToViewportPoint(topW)
                local bv, bOn = Camera:WorldToViewportPoint(botW)
                if not (tOn or bOn) or tv.Z <= 0 or bv.Z <= 0 then
                    hideESP(o)
                else
                    local col = wanted and COLORS.Wanted or COLORS[role] or COLORS.Other
                    local ht = math.max(8, bv.Y - tv.Y)
                    local w = ht * 0.55
                    local x, y = tv.X, tv.Y
                    if cfg.ESPBox then
                        o.box.Position = UDim2.fromOffset(x - w / 2, y); o.box.Size = UDim2.fromOffset(w, ht)
                        o.stroke.Color = col; o.box.Visible = true
                    else o.box.Visible = false end
                    if cfg.ESPName then
                        local label = p.DisplayName
                        if role == "Cop" then label = "[COP] " .. label elseif role == "Criminal" then label = "[CRIM] " .. label end
                        o.name.Text = label; o.name.TextColor3 = col
                        o.name.Position = UDim2.fromOffset(x, y - 15); o.name.Visible = true
                    else o.name.Visible = false end
                    if wanted then
                        o.tag.Text = "WANTED"; o.tag.TextColor3 = COLORS.Wanted
                        o.tag.Position = UDim2.fromOffset(x, y - 28); o.tag.Visible = true
                    else o.tag.Visible = false end
                    if cfg.ESPDist and myRoot then
                        o.dist.Text = math.floor((r.Position - myRoot.Position).Magnitude) .. "m"
                        o.dist.TextColor3 = Color3.fromRGB(210, 210, 210)
                        o.dist.Position = UDim2.fromOffset(x, y + ht + 1); o.dist.Visible = true
                    else o.dist.Visible = false end
                    if cfg.ESPHealth then
                        local f = math.clamp(h.Health / math.max(1, h.MaxHealth), 0, 1)
                        o.hpBack.Position = UDim2.fromOffset(x - w / 2 - 6, y); o.hpBack.Size = UDim2.fromOffset(3, ht); o.hpBack.Visible = true
                        o.hp.Position = UDim2.fromOffset(x - w / 2 - 6, y + ht * (1 - f)); o.hp.Size = UDim2.fromOffset(3, ht * f)
                        o.hp.BackgroundColor3 = Color3.fromRGB(math.floor(255 * (1 - f)), math.floor(255 * f), 40); o.hp.Visible = true
                    else o.hpBack.Visible = false o.hp.Visible = false end
                    if cfg.ESPTracer then
                        local vs = Camera.ViewportSize
                        setLine(o.tracer, vs.X / 2, vs.Y, x, y + ht, 1.5, col)
                    else o.tracer.Visible = false end
                    if cfg.ESPSkeleton then
                        local list = c:FindFirstChild("UpperTorso") and SKEL_R15 or SKEL_R6
                        for i, pair in ipairs(list) do
                            local a, b = c:FindFirstChild(pair[1]), c:FindFirstChild(pair[2])
                            local ln = o.skel[i]
                            if not ln then ln = mkLine(overlay) o.skel[i] = ln end
                            if a and b then
                                local av, aon = Camera:WorldToViewportPoint(a.Position)
                                local bv2, bon = Camera:WorldToViewportPoint(b.Position)
                                if aon and bon then setLine(ln, av.X, av.Y, bv2.X, bv2.Y, 1.2, col) else ln.Visible = false end
                            else ln.Visible = false end
                        end
                    else for _, l in ipairs(o.skel) do l.Visible = false end end
                    if cfg.ESPChams then
                        if not o.hl then
                            local hl = Instance.new("Highlight")
                            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.FillTransparency = 0.55; hl.OutlineTransparency = 0
                            local ok = pcall(function() hl.Parent = CoreGui end)
                            if not ok then hl.Parent = GUI_PARENT end
                            o.hl = hl
                        end
                        o.hl.Adornee = c; o.hl.FillColor = col; o.hl.OutlineColor = col; o.hl.Enabled = true
                    elseif o.hl then o.hl.Enabled = false end
                end
            end
        end
    end
end

local function updateRadar()
    radar.Visible = cfg.Radar
    if not cfg.Radar then return end
    local myRoot = root()
    if not myRoot then return end
    local look = Camera.CFrame.LookVector
    local fwd = Vector3.new(look.X, 0, look.Z)
    if fwd.Magnitude < 0.01 then return end
    fwd = fwd.Unit
    local right = Vector3.new(-fwd.Z, 0, fwd.X)
    local half = 65
    local used = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local c, _, r = alive(p)
            if c then
                local d = radarDots[p]
                if not d then
                    d = Instance.new("Frame") d.Size = UDim2.fromOffset(6, 6) d.AnchorPoint = Vector2.new(0.5, 0.5) d.BorderSizePixel = 0
                    local cc = Instance.new("UICorner") cc.CornerRadius = UDim.new(1, 0) cc.Parent = d
                    d.Parent = radar radarDots[p] = d
                end
                local rel = r.Position - myRoot.Position
                local rx, ry = rel:Dot(right) / cfg.RadarRange * half, -rel:Dot(fwd) / cfg.RadarRange * half
                local len = math.sqrt(rx * rx + ry * ry)
                if len > half - 4 then rx, ry = rx / len * (half - 4), ry / len * (half - 4) end
                d.Position = UDim2.new(0.5, rx, 0.5, ry)
                d.BackgroundColor3 = isWanted(p) and COLORS.Wanted or COLORS[roleOf(p)] or COLORS.Other
                d.Visible = true
                used[p] = true
            end
        end
    end
    for p, d in pairs(radarDots) do if not used[p] then d.Visible = false end end
end

-- ============================================================ combat
local aimLook = nil
local silentTarget = nil       -- Vector3 world position or nil
local silentStats = { Raycast = 0, Mouse = 0, Remote = 0 }
local silentInstalled, silentErr = false, nil

local function aimHeld()
    if cfg.AimMode == "Always" then return true end
    if hud.aimHeld then return true end
    if not IS_MOBILE and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return true end
    return false
end

local function combatStep(dt)
    Camera = Workspace.CurrentCamera
    local c = fovCenter()
    -- FOV circles
    aimCircle.Visible = cfg.Aimbot and cfg.DrawFOV
    aimCircle.Position = UDim2.fromOffset(c.X, c.Y); aimCircle.Size = UDim2.fromOffset(cfg.AimFOV * 2, cfg.AimFOV * 2)
    aimCircle.BackgroundTransparency = cfg.FillFOV and 0.85 or 1
    silentCircle.Visible = cfg.Silent and cfg.SilentDrawFOV
    silentCircle.Position = UDim2.fromOffset(c.X, c.Y); silentCircle.Size = UDim2.fromOffset(cfg.SilentFOV * 2, cfg.SilentFOV * 2)
    silentCircle.BackgroundTransparency = cfg.FillFOV and 0.9 or 1

    -- aimbot
    if cfg.Aimbot and aimHeld() then
        local t = pickTarget(cfg.AimFOV, cfg.AimPart, cfg.WallCheck)
        if t then
            local camPos = Camera.CFrame.Position
            local want = aimPos(t.part) - camPos
            if want.Magnitude > 0.01 then
                want = want.Unit
                if not aimLook then aimLook = Camera.CFrame.LookVector end
                local rem = math.clamp(cfg.AimSmooth / 100, 0, 0.98) ^ (math.max(dt, 0.001) * 60)
                aimLook = aimLook:Lerp(want, 1 - rem)
                if aimLook.Magnitude < 0.001 then aimLook = want end
                aimLook = aimLook.Unit
                Camera.CFrame = CFrame.lookAt(camPos, camPos + aimLook)
            end
        else aimLook = nil end
    else aimLook = nil end

    -- silent target cache (hooks only read this, they never raycast)
    if cfg.Silent then
        local t = pickTarget(cfg.SilentFOV, cfg.SilentPart, cfg.WallCheck)
        if t and math.random(1, 100) <= cfg.SilentHit then silentTarget = aimPos(t.part) else silentTarget = nil end
    else silentTarget = nil end
end

local function installSilent()
    if silentInstalled then return true end
    if not (hookmetamethod and getnamecallmethod and checkcaller) then
        silentErr = "executor lacks hookmetamethod/getnamecallmethod/checkcaller"
        return false
    end
    local nc = newcclosure or function(f) return f end
    local mouse = LP:GetMouse()
    local REMOTE_KW = { "shoot", "fire", "hit", "damage", "bullet", "gun", "weapon", "attack", "shot" }
    local function wantMethod(m) return cfg.SilentMethod == "Auto" or cfg.SilentMethod == m end
    local oldNC
    local ok1, err1 = pcall(function()
        oldNC = hookmetamethod(game, "__namecall", nc(function(self, ...)
            local method = getnamecallmethod()
            local tgt = silentTarget
            if tgt and cfg.Silent and not checkcaller() then
                if method == "Raycast" and self == Workspace and wantMethod("Raycast") then
                    local origin, dir, params = ...
                    if typeof(origin) == "Vector3" and typeof(dir) == "Vector3" and dir.Magnitude > 50 then
                        silentStats.Raycast = silentStats.Raycast + 1
                        return oldNC(self, origin, (tgt - origin).Unit * dir.Magnitude, params)
                    end
                elseif (method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist") and self == Workspace and wantMethod("Raycast") then
                    local ray, a, b, c2 = ...
                    if typeof(ray) == "Ray" and ray.Direction.Magnitude > 50 then
                        silentStats.Raycast = silentStats.Raycast + 1
                        return oldNC(self, Ray.new(ray.Origin, (tgt - ray.Origin).Unit * ray.Direction.Magnitude), a, b, c2)
                    end
                elseif (method == "FireServer" or method == "InvokeServer") and wantMethod("Remote") then
                    local nm = string.lower(tostring(self.Name))
                    local match = false
                    for _, k in ipairs(REMOTE_KW) do if string.find(nm, k, 1, true) then match = true break end end
                    if match then
                        local args, changed = { ... }, false
                        for i = 1, #args do
                            if typeof(args[i]) == "Vector3" then args[i] = tgt changed = true break end
                        end
                        if changed then
                            silentStats.Remote = silentStats.Remote + 1
                            return oldNC(self, table.unpack(args))
                        end
                    end
                end
            end
            return oldNC(self, ...)
        end))
    end)
    if not ok1 then silentErr = "namecall hook failed: " .. tostring(err1) return false end

    local oldIdx
    local ok2 = pcall(function()
        oldIdx = hookmetamethod(game, "__index", nc(function(self, key)
            if (key == "Hit" or key == "Target") and silentTarget and cfg.Silent and self == mouse and wantMethod("Mouse") and not checkcaller() then
                silentStats.Mouse = silentStats.Mouse + 1
                if key == "Hit" then return CFrame.new(silentTarget) end
            end
            return oldIdx(self, key)
        end))
    end)
    if not ok2 then silentErr = "mouse hook unavailable (raycast/remote hooks active)" end
    silentInstalled = true
    return true
end

-- ============================================================ gun mods (generic heuristic)
local modOrig = {}     -- [tbl_or_instance][key] = original
local modApplied = 0
local function remember(container, key, old)
    modOrig[container] = modOrig[container] or {}
    if modOrig[container][key] == nil then modOrig[container][key] = old end
end
local function lowerHas(name, list) local l = string.lower(name) for _, k in ipairs(list) do if string.find(l, k, 1, true) then return true end end return false end
local K_RECOIL, K_SPREAD, K_AMMO = { "recoil" }, { "spread", "bloom" }, { "ammo", "magazine", "clip" }

local function wantedValue(key)
    if cfg.NoRecoil and lowerHas(key, K_RECOIL) then return 0 end
    if cfg.NoSpread and lowerHas(key, K_SPREAD) then return 0 end
    if cfg.InfAmmo and lowerHas(key, K_AMMO) and not lowerHas(key, { "max", "reserve" }) then return 9999 end
    return nil
end

local function applyGunMods()
    modApplied = 0
    local c = char()
    if not c then return end
    local tool = c:FindFirstChildOfClass("Tool")
    if not tool then return end
    for _, d in ipairs(tool:GetDescendants()) do
        if (d:IsA("NumberValue") or d:IsA("IntValue")) then
            local w = wantedValue(d.Name)
            if w ~= nil then remember(d, "Value", d.Value) d.Value = w modApplied = modApplied + 1 end
        elseif d:IsA("ModuleScript") then
            local ok, t = pcall(require, d)
            if ok and type(t) == "table" then
                for k, v in pairs(t) do
                    if type(k) == "string" and type(v) == "number" then
                        local w = wantedValue(k)
                        if w ~= nil then remember(t, k, v) t[k] = w modApplied = modApplied + 1 end
                    end
                end
            end
        end
    end
    pcall(function()
        for k, v in pairs(tool:GetAttributes()) do
            if type(v) == "number" then
                local w = wantedValue(k)
                if w ~= nil then remember(tool, k, v) tool:SetAttribute(k, w) modApplied = modApplied + 1 end
            end
        end
    end)
end
local function restoreGunMods()
    for container, keys in pairs(modOrig) do
        for k, v in pairs(keys) do
            pcall(function()
                if typeof(container) == "Instance" then
                    if k == "Value" then container.Value = v else container:SetAttribute(k, v) end
                else container[k] = v end
            end)
        end
    end
    modOrig = {}
end
onUnload(restoreGunMods)

-- ============================================================ misc features
local noclipOrig = setmetatable({}, { __mode = "k" })
local function noclipStep()
    local c = char()
    if not c then return end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") and p.CanCollide then noclipOrig[p] = true p.CanCollide = false end
    end
end
local function noclipRestore() for p in pairs(noclipOrig) do pcall(function() p.CanCollide = true end) end noclipOrig = setmetatable({}, { __mode = "k" }) end
onUnload(noclipRestore)

local speedOrig, jumpOrig = nil, nil
local function speedStep(dt)
    local h, r = hum(), root()
    if not h then return end
    if cfg.Speed then
        if cfg.SpeedMode == "WalkSpeed" then
            if not speedOrig then speedOrig = h.WalkSpeed end
            h.WalkSpeed = cfg.SpeedVal
        elseif r and h.MoveDirection.Magnitude > 0 then
            r.CFrame = r.CFrame + h.MoveDirection * cfg.SpeedVal * dt
        end
    elseif speedOrig then h.WalkSpeed = speedOrig speedOrig = nil end
    if cfg.Jump then
        if h.UseJumpPower then
            if not jumpOrig then jumpOrig = { true, h.JumpPower } end
            h.JumpPower = cfg.JumpVal
        else
            if not jumpOrig then jumpOrig = { false, h.JumpHeight } end
            h.JumpHeight = (cfg.JumpVal * cfg.JumpVal) / (2 * Workspace.Gravity)
        end
    elseif jumpOrig then
        if jumpOrig[1] then h.JumpPower = jumpOrig[2] else h.JumpHeight = jumpOrig[2] end
        jumpOrig = nil
    end
end
onUnload(function()
    local h = hum()
    if h then
        if speedOrig then h.WalkSpeed = speedOrig end
        if jumpOrig then if jumpOrig[1] then h.JumpPower = jumpOrig[2] else h.JumpHeight = jumpOrig[2] end end
    end
end)

conn(UIS.JumpRequest:Connect(function()
    if cfg.InfJump then local h = hum() if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end
end))

-- fly (uses MoveDirection so the mobile thumbstick works; HUD UP/DOWN for height)
local flyBV = nil
local function flyStop()
    if flyBV then flyBV:Destroy() flyBV = nil end
    local h = hum()
    if h then h.PlatformStand = false end
end
local function flyStep()
    local h, r = hum(), root()
    if not (h and r) then return end
    if not flyBV or flyBV.Parent ~= r then
        if flyBV then flyBV:Destroy() end
        flyBV = Instance.new("BodyVelocity")
        flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9); flyBV.Velocity = Vector3.zero; flyBV.Parent = r
    end
    local cf = Camera.CFrame
    local md = h.MoveDirection
    local dir = Vector3.zero
    if md.Magnitude > 0.05 then
        local flat = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
        flat = flat.Magnitude > 0.01 and flat.Unit or Vector3.new(0, 0, -1)
        dir = cf.LookVector * md:Dot(flat) + cf.RightVector * md:Dot(cf.RightVector)
    end
    if hud.up or UIS:IsKeyDown(Enum.KeyCode.Space) or h.Jump then dir = dir + Vector3.new(0, 1, 0) end
    if hud.down or UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end
    flyBV.Velocity = dir.Magnitude > 0.05 and dir.Unit * cfg.FlySpeed or Vector3.zero
    h.PlatformStand = false
end
onUnload(flyStop)

local ragStates = { Enum.HumanoidStateType.FallingDown, Enum.HumanoidStateType.Ragdoll, Enum.HumanoidStateType.PlatformStanding }
local function setAntiRagdoll(on)
    local h = hum()
    if not h then return end
    for _, s in ipairs(ragStates) do pcall(function() h:SetStateEnabled(s, not on) end) end
end

local afkConn
local function setAntiAFK(on)
    if afkConn then afkConn:Disconnect() afkConn = nil end
    if on then
        local VU = svc("VirtualUser")
        if VU then afkConn = LP.Idled:Connect(function() pcall(function() VU:CaptureController() VU:ClickButton2(Vector2.new()) end) end) end
    end
end
onUnload(function() if afkConn then afkConn:Disconnect() end end)

local lightOrig = nil
local function setLighting()
    if cfg.Fullbright or cfg.NoFog or cfg.TimeOfDay ~= "Default" then
        if not lightOrig then
            lightOrig = { B = Lighting.Brightness, A = Lighting.Ambient, O = Lighting.OutdoorAmbient, S = Lighting.GlobalShadows, F = Lighting.FogEnd, C = Lighting.ClockTime }
        end
    end
    if cfg.Fullbright then
        Lighting.Brightness = 3; Lighting.Ambient = Color3.new(1, 1, 1); Lighting.OutdoorAmbient = Color3.new(1, 1, 1); Lighting.GlobalShadows = false
    elseif lightOrig then
        Lighting.Brightness = lightOrig.B; Lighting.Ambient = lightOrig.A; Lighting.OutdoorAmbient = lightOrig.O; Lighting.GlobalShadows = lightOrig.S
    end
    if lightOrig then
        Lighting.FogEnd = cfg.NoFog and 1e9 or lightOrig.F
        local tod = { Morning = 7, Noon = 12, Evening = 18, Night = 0 }
        Lighting.ClockTime = tod[cfg.TimeOfDay] or lightOrig.C
    end
end
onUnload(function() cfg.Fullbright = false cfg.NoFog = false cfg.TimeOfDay = "Default" setLighting() end)

-- vehicle
local lastFlip = 0
local function vehicleStep(dt)
    local h = hum()
    local seat = h and h.SeatPart
    if not seat then return end
    if cfg.VehicleBoost then
        local thr = 0
        if seat:IsA("VehicleSeat") then thr = seat.Throttle
        else thr = h.MoveDirection:Dot(seat.CFrame.LookVector) end
        if math.abs(thr) > 0.1 then
            local v = seat.AssemblyLinearVelocity
            local look = seat.CFrame.LookVector
            local flat = Vector3.new(look.X, 0, look.Z)
            if flat.Magnitude > 0.01 then
                flat = flat.Unit * (thr > 0 and 1 or -1) * cfg.VehicleSpeed
                seat.AssemblyLinearVelocity = Vector3.new(flat.X, v.Y, flat.Z)
            end
        end
    end
    if cfg.AntiFlip and seat.CFrame.UpVector.Y < 0.25 and os.clock() - lastFlip > 1 then
        lastFlip = os.clock()
        local m = seat:FindFirstAncestorOfClass("Model")
        local pos = seat.Position + Vector3.new(0, 4, 0)
        local look = seat.CFrame.LookVector
        local yaw = CFrame.lookAt(pos, pos + Vector3.new(look.X, 0, look.Z))
        pcall(function() if m then m:PivotTo(yaw) else seat.CFrame = yaw end end)
    end
end

-- cop alert
local function copAlertStep()
    if not cfg.CopAlert then alertLabel.Visible = false return end
    local myRoot = root()
    if not myRoot then return end
    local best, bd = nil, cfg.CopAlertDist
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and roleOf(p) == "Cop" and roleOf(LP) ~= "Cop" then
            local _, _, r = alive(p)
            if r then
                local d = (r.Position - myRoot.Position).Magnitude
                if d < bd then bd = d best = p end
            end
        end
    end
    if best then alertLabel.Text = "COP NEARBY: " .. best.DisplayName .. " (" .. math.floor(bd) .. "m)" alertLabel.Visible = true
    else alertLabel.Visible = false end
end

-- prompts
local promptOrig = setmetatable({}, { __mode = "k" })
local ARREST_KW = { "arrest", "cuff", "detain", "search", "frisk", "restrain" }
if PPS then
    conn(PPS.PromptShown:Connect(function(prompt)
        if cfg.InstantPrompts then
            if promptOrig[prompt] == nil then promptOrig[prompt] = prompt.HoldDuration end
            prompt.HoldDuration = 0
        end
        if cfg.AutoArrest and type(fireproximityprompt) == "function" then
            local txt = string.lower((prompt.ActionText or "") .. " " .. (prompt.ObjectText or ""))
            for _, k in ipairs(ARREST_KW) do
                if string.find(txt, k, 1, true) then pcall(fireproximityprompt, prompt) break end
            end
        end
    end))
end
onUnload(function() for p, v in pairs(promptOrig) do pcall(function() p.HoldDuration = v end) end end)

-- teleports
local function tpTo(cf) local r = root() if r then r.CFrame = cf end end
local function nearestPlayer()
    local myRoot = root()
    if not myRoot then return nil end
    local best, bd
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local _, _, r = alive(p)
            if r then local d = (r.Position - myRoot.Position).Magnitude if not bd or d < bd then bd = d best = r end end
        end
    end
    return best
end

-- ============================================================ main loops
local stepName = "ah_" .. rnd(8)
RunService:BindToRenderStep(stepName, Enum.RenderPriority.Camera.Value + 1, function(dt)
    local ok, err = pcall(function()
        combatStep(dt)
        updateESP()
        updateRadar()
        btnAim.Visible = cfg.MobileHUD and cfg.Aimbot and cfg.AimMode == "Hold"
        btnUp.Visible = cfg.MobileHUD and cfg.Fly
        btnDown.Visible = cfg.MobileHUD and cfg.Fly
    end)
    if not ok and not G_ERR_SHOWN then G_ERR_SHOWN = true notify("AngelHub error", tostring(err), 8) end
end)
onUnload(function() pcall(function() RunService:UnbindFromRenderStep(stepName) end) end)

local acc = 0
conn(RunService.Heartbeat:Connect(function(dt)
    pcall(function()
        if cfg.Noclip then noclipStep() end
        speedStep(dt)
        if cfg.Fly then flyStep() elseif flyBV then flyStop() end
        if cfg.Spin then local r = root() if r then r.CFrame = r.CFrame * CFrame.Angles(0, math.rad(cfg.SpinSpeed), 0) end end
        vehicleStep(dt)
        acc = acc + dt
        if acc > 0.25 then
            acc = 0
            copAlertStep()
            if cfg.NoRecoil or cfg.NoSpread or cfg.InfAmmo then applyGunMods() end
        end
    end)
end))
conn(LP.CharacterAdded:Connect(function() task.wait(0.5) if cfg.AntiRagdoll then setAntiRagdoll(true) end speedOrig, jumpOrig = nil, nil end))

-- ============================================================ config save/load
local function saveCfg()
    if not (writefile and game:GetService("HttpService")) then notify("Config", "writefile not supported by this executor", 4) return end
    local ok = pcall(function() writefile(CFG_FILE, game:GetService("HttpService"):JSONEncode(cfg)) end)
    notify("Config", ok and "Saved" or "Save failed", 3)
end
local function loadCfg()
    if not (readfile and isfile and isfile(CFG_FILE)) then notify("Config", "No saved config", 3) return end
    local ok, data = pcall(function() return game:GetService("HttpService"):JSONDecode(readfile(CFG_FILE)) end)
    if ok and type(data) == "table" then
        for k, v in pairs(data) do if cfg[k] ~= nil then cfg[k] = v end end
        notify("Config", "Loaded. Reopen the menu toggles to see values.", 4)
    else notify("Config", "Load failed", 3) end
end

-- ============================================================ UI (WindUI)
local okW, WindUI = pcall(function() return loadstring(game:HttpGet(WIND_URL))() end)
if not okW or type(WindUI) ~= "table" then
    notify("AngelHub", "Could not load WindUI (" .. tostring(WindUI) .. "). Features still run with current settings; no menu.", 8)
    return
end
G_WIND = WindUI

local Window
local okWin, errWin = pcall(function()
    Window = WindUI:CreateWindow({
        Title = "AngelHub  |  " .. VERSION, Icon = "shield", Author = "San Diego RP Border",
        Folder = "AngelHub", Size = UDim2.fromOffset(IS_MOBILE and 470 or 580, IS_MOBILE and 330 or 440),
        Theme = "Dark", Transparent = true, SideBarWidth = IS_MOBILE and 150 or 190,
    })
end)
if not okWin or not Window then notify("AngelHub", "WindUI CreateWindow failed: " .. tostring(errWin), 8) return end

pcall(function() Window:SetToggleKey(Enum.KeyCode.RightShift) end)
pcall(function()
    Window:EditOpenButton({ Title = "AngelHub", Icon = "shield", CornerRadius = UDim.new(0, 16), StrokeThickness = 2,
        Color = ColorSequence.new(Color3.fromHex("8C3CFF"), Color3.fromHex("C77DFF")), Draggable = true, Enabled = true, OnlyMobile = false })
end)
onUnload(function() pcall(function() Window:Destroy() end) end)

local function tab(title, icon) local t local ok = pcall(function() t = Window:Tab({ Title = title, Icon = icon }) end) return ok and t or nil end
local function section(t, title) pcall(function() t:Section({ Title = title }) end) end
local function toggle(t, title, key, cb)
    pcall(function()
        t:Toggle({ Title = title, Value = cfg[key], Callback = function(v) cfg[key] = v if cb then cb(v) end end })
    end)
end
local function slider(t, title, key, mn, mx, cb)
    pcall(function()
        t:Slider({ Title = title, Step = 1, Value = { Min = mn, Max = mx, Default = cfg[key] }, Callback = function(v) cfg[key] = v if cb then cb(v) end end })
    end)
end
local function dropdown(t, title, key, values, cb)
    pcall(function()
        t:Dropdown({ Title = title, Values = values, Value = cfg[key], Callback = function(v) cfg[key] = v if cb then cb(v) end end })
    end)
end
local function button(t, title, cb) pcall(function() t:Button({ Title = title, Callback = cb }) end) end
local function para(t, title, desc) pcall(function() t:Paragraph({ Title = title, Desc = desc }) end) end

-- Combat
local tCombat = tab("Combat", "crosshair")
section(tCombat, "Aimbot")
toggle(tCombat, "Aimbot", "Aimbot")
dropdown(tCombat, "Aim Mode (Hold = RMB / AIM button)", "AimMode", { "Hold", "Always" })
slider(tCombat, "Aimbot FOV", "AimFOV", 20, 500)
slider(tCombat, "Smoothness (0 = snap)", "AimSmooth", 0, 95)
dropdown(tCombat, "Aim Part", "AimPart", { "Head", "Torso", "Root" })
toggle(tCombat, "Draw FOV", "DrawFOV")
toggle(tCombat, "Fill FOV", "FillFOV")
section(tCombat, "Targeting")
toggle(tCombat, "Team Check", "TeamCheck")
toggle(tCombat, "Wall Check", "WallCheck")
dropdown(tCombat, "Target Filter", "TargetFilter", { "All", "Criminals", "Cops", "Wanted" })
toggle(tCombat, "Prediction", "Prediction")
slider(tCombat, "Prediction (ms)", "PredictMs", 0, 250)
section(tCombat, "Silent Aim")
toggle(tCombat, "Silent Aim", "Silent", function(v)
    if v then
        local ok = installSilent()
        if not ok then cfg.Silent = false notify("Silent Aim", "Unavailable: " .. tostring(silentErr), 6) end
    end
end)
slider(tCombat, "Silent FOV", "SilentFOV", 20, 500)
slider(tCombat, "Hit Chance %", "SilentHit", 1, 100)
dropdown(tCombat, "Silent Part", "SilentPart", { "Head", "Torso", "Root" })
dropdown(tCombat, "Silent Method", "SilentMethod", { "Auto", "Raycast", "Mouse", "Remote" })
toggle(tCombat, "Draw Silent FOV", "SilentDrawFOV")
button(tCombat, "Show silent redirect counters", function()
    notify("Silent Aim", "Raycast " .. silentStats.Raycast .. " | Mouse " .. silentStats.Mouse .. " | Remote " .. silentStats.Remote ..
        "\nAll 0 while shooting = this game's guns use a method not covered yet.", 7)
end)
section(tCombat, "Gun mods (generic, equipped tool only)")
toggle(tCombat, "No Recoil", "NoRecoil", function(v) if not v then restoreGunMods() applyGunMods() end end)
toggle(tCombat, "No Spread", "NoSpread", function(v) if not v then restoreGunMods() applyGunMods() end end)
toggle(tCombat, "Infinite Ammo (client value)", "InfAmmo", function(v) if not v then restoreGunMods() applyGunMods() end end)
button(tCombat, "Gun mod status", function() notify("Gun mods", modApplied > 0 and (modApplied .. " values edited on equipped tool") or "Nothing editable found: this game's gun system isn't generic", 5) end)

-- Visuals
local tVis = tab("Visuals", "eye")
section(tVis, "ESP")
toggle(tVis, "ESP Master", "ESP")
toggle(tVis, "Box", "ESPBox")
toggle(tVis, "Name", "ESPName")
toggle(tVis, "Health Bar", "ESPHealth")
toggle(tVis, "Distance", "ESPDist")
toggle(tVis, "Tracers", "ESPTracer")
toggle(tVis, "Skeleton", "ESPSkeleton")
toggle(tVis, "Chams (Highlight)", "ESPChams")
slider(tVis, "Max Distance", "ESPMaxDist", 100, 5000)
section(tVis, "Radar")
toggle(tVis, "Radar", "Radar")
slider(tVis, "Radar Range", "RadarRange", 50, 600)

-- San Diego
local tSD = tab("San Diego", "badge-alert")
section(tSD, "Role ESP")
toggle(tSD, "Show Cops", "ShowCops")
toggle(tSD, "Show Criminals", "ShowCriminals")
toggle(tSD, "Show Others", "ShowOthers")
toggle(tSD, "Wanted tag + always show wanted", "WantedTag")
para(tSD, "Turn ESP Master on in Visuals", "Role colors: Cop blue, Criminal red, Wanted gold. Assign unknown teams below.")
section(tSD, "Team roles (tap to assign)")
do
    local list = {}
    pcall(function() list = Teams:GetTeams() end)
    if #list == 0 then para(tSD, "No teams found", "This game has no Teams, so roles fall back to Other. Wanted detection still works.") end
    for _, team in ipairs(list) do
        local nm = team.Name
        pcall(function()
            tSD:Dropdown({ Title = nm, Values = { "Auto", "Cop", "Criminal", "Other" }, Value = cfg.TeamRoles[nm] or "Auto",
                Callback = function(v) cfg.TeamRoles[nm] = v end })
        end)
    end
end
section(tSD, "Law enforcement")
toggle(tSD, "Cop proximity alert", "CopAlert")
slider(tSD, "Alert distance", "CopAlertDist", 20, 300)
toggle(tSD, "Instant prompts (no hold)", "InstantPrompts")
toggle(tSD, "Auto arrest prompts (arrest/cuff/detain/search)", "AutoArrest")
section(tSD, "Vehicle")
toggle(tSD, "Vehicle boost", "VehicleBoost")
slider(tSD, "Vehicle speed (studs/s)", "VehicleSpeed", 40, 400)
toggle(tSD, "Anti flip", "AntiFlip")
section(tSD, "Teleport")
button(tSD, "Teleport to nearest player", function() local r = nearestPlayer() if r then tpTo(r.CFrame * CFrame.new(0, 0, 5)) else notify("Teleport", "No player found", 3) end end)
button(tSD, "Teleport to spawn", function()
    local sp = Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
    if sp then tpTo(sp.CFrame + Vector3.new(0, 5, 0)) else notify("Teleport", "No SpawnLocation found", 3) end
end)

-- Misc
local tMisc = tab("Misc", "wrench")
section(tMisc, "Movement")
toggle(tMisc, "Noclip", "Noclip", function(v) if not v then noclipRestore() end end)
toggle(tMisc, "Speed", "Speed")
dropdown(tMisc, "Speed mode", "SpeedMode", { "WalkSpeed", "CFrame" })
slider(tMisc, "Speed value", "SpeedVal", 16, 250)
toggle(tMisc, "Jump boost", "Jump")
slider(tMisc, "Jump power", "JumpVal", 50, 300)
toggle(tMisc, "Infinite jump", "InfJump")
toggle(tMisc, "Fly (thumbstick + UP/DOWN buttons)", "Fly", function(v) if not v then flyStop() end end)
slider(tMisc, "Fly speed", "FlySpeed", 10, 250)
toggle(tMisc, "Spin", "Spin")
slider(tMisc, "Spin speed", "SpinSpeed", 1, 60)
section(tMisc, "Player")
toggle(tMisc, "Anti ragdoll", "AntiRagdoll", setAntiRagdoll)
toggle(tMisc, "Anti AFK", "AntiAFK", setAntiAFK)
section(tMisc, "World")
toggle(tMisc, "Fullbright", "Fullbright", setLighting)
toggle(tMisc, "No fog", "NoFog", setLighting)
dropdown(tMisc, "Time of day", "TimeOfDay", { "Default", "Morning", "Noon", "Evening", "Night" }, setLighting)

-- Settings
local tSet = tab("Settings", "settings")
section(tSet, "AngelHub")
para(tSet, "AngelHub " .. VERSION, "Discord: " .. DISCORD_URL)
button(tSet, "Copy Discord link", function()
    if copyText(DISCORD_URL) then notify("Discord", "Link copied", 3) else notify("Discord", "Clipboard unsupported here. Link: " .. DISCORD_URL, 10) end
end)
toggle(tSet, "Mobile HUD buttons (AIM / UP / DOWN)", "MobileHUD")
button(tSet, "Save config", saveCfg)
button(tSet, "Load config", loadCfg)
section(tSet, "Diagnostics")
button(tSet, "Executor capabilities", function()
    local function y(f) return f and "yes" or "no" end
    notify("Capabilities", "clipboard " .. y(setclipboard or toclipboard) .. " | hooks " .. y(hookmetamethod) .. " | files " .. y(writefile) ..
        " | fireprompt " .. y(fireproximityprompt) .. " | mobile " .. tostring(IS_MOBILE), 8)
end)
button(tSet, "Unload AngelHub", function() if GENV and GENV.__AngelHubUnload then GENV.__AngelHubUnload() end end)

-- apply persisted toggles that need side effects
setAntiAFK(cfg.AntiAFK)

local unloaded = false
local function unload()
    if unloaded then return end
    unloaded = true
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    for i = #cleanups, 1, -1 do pcall(cleanups[i]) end
    if GENV then GENV.__AngelHubUnload = nil end
end
if GENV then GENV.__AngelHubUnload = unload end

notify("AngelHub " .. VERSION, IS_MOBILE and "Loaded. Tap the AngelHub button to open the menu." or "Loaded. RightShift toggles the menu.", 5)
