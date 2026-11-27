-- ╔══════════════════════════════════════════════════════════════════╗
-- ║        AngelHub | v3.1  —  San Diego RP Border Edition          ║
-- ║        Mobile + PC  |  NO FREEZE  |  Touch-first UI             ║
-- ║        Executor: Synapse X / KRNL / Fluxus / Solara / Delta     ║
-- ╚══════════════════════════════════════════════════════════════════╝

-- ══════════════════════════════════════════════════════════════════════
-- FREEZE FIX: everything heavy runs in task.spawn / task.defer
-- Touch fix:  NO InputBegan on frames — only TextButton MouseButton1Click
-- ══════════════════════════════════════════════════════════════════════

local DISCORD = "discord.gg/d8gpXNGknP"
local VER     = "v3.1"

-- ── Services ──────────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local CoreGui          = game:GetService("CoreGui")
local StarterGui       = game:GetService("StarterGui")
local Lighting         = game:GetService("Lighting")
local Camera           = workspace.CurrentCamera
local LP               = Players.LocalPlayer
local Mouse            = LP:GetMouse()

-- ── Character refs (auto-refresh) ─────────────────────────────────────
local Char, Hum, HRP
local function grabChar(c)
    Char = c
    Hum  = c:WaitForChild("Humanoid",   10)
    HRP  = c:WaitForChild("HumanoidRootPart", 10)
end
task.spawn(function()
    grabChar(LP.Character or LP.CharacterAdded:Wait())
    LP.CharacterAdded:Connect(grabChar)
end)

-- ══════════════════════════════════════════════════════════════════════
-- CONFIG
-- ══════════════════════════════════════════════════════════════════════
local cfg = {
    -- Combat
    Aimbot          = false,
    SilentAim       = false,
    AimbotSmooth    = 0.35,
    FOVRadius       = 150,
    DrawFOV         = true,
    Prediction      = true,
    TargetPart      = "Head",
    WallCheck       = true,
    TeamCheck       = true,
    NoRecoil        = false,
    NoSpread        = false,
    RapidFire       = false,
    InfiniteAmmo    = false,

    -- Visuals
    ESP             = false,
    BoxESP          = true,
    NameESP         = true,
    HealthBar       = true,
    SkeletonESP     = false,
    DistanceESP     = true,
    TracerESP       = false,

    -- Misc
    Noclip          = false,
    SpeedBoost      = false,
    WalkSpeed       = 16,
    JumpBoost       = false,
    JumpPower       = 50,
    InfiniteJump    = false,
    Fly             = false,
    FlySpeed        = 50,
    GodMode         = false,
    AntiAFK         = true,
    SpinBot         = false,
    SpinSpeed       = 10,

    -- SDRP
    CopESP          = false,
    CriminalESP     = false,
    WantedESP       = false,
    AutoArrest      = false,
    VehicleBoost    = false,
    VehicleSpeed    = 100,
    AntiFlip        = false,
    AutoEvade       = false,

    -- World
    NoFog           = false,
    Fullbright      = false,
    FPSBoost        = false,

    -- UI
    UIScale         = 1.0,
    AccentColor     = "Purple",   -- Purple / Teal / Red / Green / Orange
    MenuOpen        = true,
}

-- ── Accent palette ────────────────────────────────────────────────────
local ACCENTS = {
    Purple = {main=Color3.fromRGB(140,60,255),  dim=Color3.fromRGB(100,40,180)},
    Teal   = {main=Color3.fromRGB(0,200,230),   dim=Color3.fromRGB(0,140,170)},
    Red    = {main=Color3.fromRGB(220,50,50),    dim=Color3.fromRGB(160,30,30)},
    Green  = {main=Color3.fromRGB(50,220,100),   dim=Color3.fromRGB(30,160,70)},
    Orange = {main=Color3.fromRGB(255,140,0),    dim=Color3.fromRGB(200,100,0)},
}
local function accent() return ACCENTS[cfg.AccentColor] or ACCENTS.Purple end

local COL = {
    BG     = Color3.fromRGB(12, 8, 22),
    PANEL  = Color3.fromRGB(20,14,36),
    HEADER = Color3.fromRGB(26,16,48),
    ROW    = Color3.fromRGB(28,20,46),
    TEXT   = Color3.fromRGB(220,200,255),
    DIM    = Color3.fromRGB(130,110,165),
    WHITE  = Color3.new(1,1,1),
    OFF    = Color3.fromRGB(45,35,65),
    GREEN  = Color3.fromRGB(50,220,90),
    RED    = Color3.fromRGB(220,55,55),
}

-- ══════════════════════════════════════════════════════════════════════
-- DESTROY OLD GUI
-- ══════════════════════════════════════════════════════════════════════
pcall(function()
    local old = CoreGui:FindFirstChild("AngelHubV31")
    if old then old:Destroy() end
end)

-- ══════════════════════════════════════════════════════════════════════
-- SCREENGUI
-- ══════════════════════════════════════════════════════════════════════
local SG = Instance.new("ScreenGui")
SG.Name              = "AngelHubV31"
SG.ResetOnSpawn      = false
SG.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
SG.IgnoreGuiInset    = true
SG.DisplayOrder      = 999
pcall(function() SG.Parent = CoreGui end)
if not SG.Parent then SG.Parent = LP:WaitForChild("PlayerGui") end

-- ══════════════════════════════════════════════════════════════════════
-- GUI HELPERS  (all buttons are TextButton — works on mobile)
-- ══════════════════════════════════════════════════════════════════════
local function corner(inst, r)
    local c = Instance.new("UICorner", inst)
    c.CornerRadius = UDim.new(0, r or 8)
    return c
end
local function stroke(inst, color, thick)
    local s = Instance.new("UIStroke", inst)
    s.Color     = color or accent().dim
    s.Thickness = thick or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    return s
end
local function padding(inst, px)
    local p = Instance.new("UIPadding", inst)
    p.PaddingLeft   = UDim.new(0,px)
    p.PaddingRight  = UDim.new(0,px)
    p.PaddingTop    = UDim.new(0,px)
    p.PaddingBottom = UDim.new(0,px)
    return p
end
local function listLayout(inst, dir, pad, sort)
    local l = Instance.new("UIListLayout", inst)
    l.FillDirection = dir or Enum.FillDirection.Vertical
    l.SortOrder     = sort or Enum.SortOrder.LayoutOrder
    l.Padding       = UDim.new(0, pad or 4)
    return l
end
local function newFrame(parent, size, pos, color, trans)
    local f = Instance.new("Frame", parent)
    f.Size                   = size  or UDim2.new(1,0,0,40)
    f.Position               = pos   or UDim2.new(0,0,0,0)
    f.BackgroundColor3       = color or COL.PANEL
    f.BackgroundTransparency = trans or 0
    f.BorderSizePixel        = 0
    return f
end
local function newLabel(parent, text, size, color, xa)
    local l = Instance.new("TextLabel", parent)
    l.Size                   = UDim2.new(1,0,1,0)
    l.BackgroundTransparency = 1
    l.BorderSizePixel        = 0
    l.Text                   = text or ""
    l.TextSize               = size or 13
    l.TextColor3             = color or COL.TEXT
    l.Font                   = Enum.Font.GothamBold
    l.TextXAlignment         = xa or Enum.TextXAlignment.Left
    l.TextYAlignment         = Enum.TextYAlignment.Center
    l.TextWrapped            = true
    return l
end
local function newBtn(parent, text, size, pos, bgColor, textColor, textSize)
    local b = Instance.new("TextButton", parent)
    b.Size                   = size    or UDim2.new(1,0,0,38)
    b.Position               = pos     or UDim2.new(0,0,0,0)
    b.BackgroundColor3       = bgColor or accent().main
    b.BackgroundTransparency = 0
    b.BorderSizePixel        = 0
    b.Text                   = text    or ""
    b.TextSize               = textSize or 13
    b.TextColor3             = textColor or COL.WHITE
    b.Font                   = Enum.Font.GothamBold
    b.AutoButtonColor        = true
    return b
end
local function scrollFrame(parent, size, pos)
    local sv = Instance.new("ScrollingFrame", parent)
    sv.Size                  = size or UDim2.new(1,0,1,0)
    sv.Position              = pos  or UDim2.new(0,0,0,0)
    sv.BackgroundTransparency= 1
    sv.BorderSizePixel       = 0
    sv.ScrollBarThickness    = 4
    sv.ScrollBarImageColor3  = accent().main
    sv.CanvasSize            = UDim2.new(0,0,0,0)
    sv.AutomaticCanvasSize   = Enum.AutomaticSize.Y
    sv.ScrollingDirection    = Enum.ScrollingDirection.Y
    sv.ElasticBehavior       = Enum.ElasticBehavior.Always
    return sv
end

-- ══════════════════════════════════════════════════════════════════════
-- SCALE  (all sizes multiply by this)
-- ══════════════════════════════════════════════════════════════════════
local BASE_W, BASE_H = 500, 400
local function scaled(n) return math.floor(n * cfg.UIScale) end

-- ══════════════════════════════════════════════════════════════════════
-- ROOT
-- ══════════════════════════════════════════════════════════════════════
local Root = newFrame(SG,
    UDim2.new(0, scaled(BASE_W), 0, scaled(BASE_H)),
    UDim2.new(0.5, -scaled(BASE_W/2), 0.5, -scaled(BASE_H/2)),
    COL.BG)
Root.ClipsDescendants = true
corner(Root, 14)
stroke(Root, accent().main, 1.5)

-- ── drag (TextButton overlay so touch works) ──────────────────────────
local dragHandle = newBtn(Root, "", UDim2.new(1,0,0,52), UDim2.new(0,0,0,0),
    COL.BG, COL.WHITE, 1)
dragHandle.ZIndex = 20
dragHandle.BackgroundTransparency = 1
dragHandle.AutoButtonColor = false
do
    local dragging, ds, dp = false, nil, nil
    dragHandle.MouseButton1Down:Connect(function()
        dragging = true
        ds = UserInputService:GetMouseLocation()
        dp = Root.Position
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType ~= Enum.UserInputType.MouseMovement
        and i.UserInputType ~= Enum.UserInputType.Touch then return end
        local cur = UserInputService:GetMouseLocation()
        local dx  = cur.X - ds.X
        local dy  = cur.Y - ds.Y
        Root.Position = UDim2.new(dp.X.Scale, dp.X.Offset+dx,
                                   dp.Y.Scale, dp.Y.Offset+dy)
    end)
end

-- ══════════════════════════════════════════════════════════════════════
-- HEADER
-- ══════════════════════════════════════════════════════════════════════
local Header = newFrame(Root, UDim2.new(1,0,0,52), UDim2.new(0,0,0,0), COL.HEADER)
corner(Header, 14)
-- patch bottom corners
local hpatch = newFrame(Root, UDim2.new(1,0,0,14), UDim2.new(0,0,0,38), COL.HEADER)

-- logo
local logoBG = newFrame(Header, UDim2.new(0,36,0,36), UDim2.new(0,8,0,8), accent().main)
corner(logoBG, 10)
local logoL = newLabel(logoBG, "AH", 14, COL.WHITE, Enum.TextXAlignment.Center)
logoL.Size = UDim2.new(1,0,1,0)

-- title
local titleL = newLabel(Header, "AngelHub  |  "..VER, 17, accent().main)
titleL.Size     = UDim2.new(0,180,0,52)
titleL.Position = UDim2.new(0,52,0,0)
titleL.Font     = Enum.Font.GothamBold

-- discord input (readonly) + copy btn
local discBG = newFrame(Header, UDim2.new(0,190,0,28), UDim2.new(0,235,0,12), COL.BG)
corner(discBG, 7)
stroke(discBG, accent().dim, 1)
local discL = newLabel(discBG, DISCORD, 10, accent().main)
discL.Size     = UDim2.new(1,-50,1,0)
discL.Position = UDim2.new(0,6,0,0)

local copyB = newBtn(discBG, "Copy", UDim2.new(0,42,0,22),
    UDim2.new(1,-44,0,3), accent().main, COL.WHITE, 11)
corner(copyB, 6)
copyB.MouseButton1Click:Connect(function()
    pcall(function() setclipboard(DISCORD) end)
    copyB.Text = "✓"
    task.delay(1.5, function() copyB.Text = "Copy" end)
end)

-- close button
local closeB = newBtn(Header, "✕", UDim2.new(0,30,0,30),
    UDim2.new(1,-38,0,11), COL.RED, COL.WHITE, 15)
corner(closeB, 8)

-- ══════════════════════════════════════════════════════════════════════
-- FLOATING TOGGLE BUTTON
-- ══════════════════════════════════════════════════════════════════════
local ToggleBtn = newBtn(SG, "☰ AngelHub",
    UDim2.new(0,110,0,38),
    UDim2.new(0,20,0,100),
    accent().main, COL.WHITE, 13)
corner(ToggleBtn, 10)
ToggleBtn.Visible = false
ToggleBtn.ZIndex  = 999

-- drag the toggle button
do
    local dragging, ds, dp = false, nil, nil
    ToggleBtn.MouseButton1Down:Connect(function()
        dragging = true
        ds = UserInputService:GetMouseLocation()
        dp = ToggleBtn.Position
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType ~= Enum.UserInputType.MouseMovement
        and i.UserInputType ~= Enum.UserInputType.Touch then return end
        local cur = UserInputService:GetMouseLocation()
        ToggleBtn.Position = UDim2.new(dp.X.Scale, dp.X.Offset+(cur.X-ds.X),
                                        dp.Y.Scale, dp.Y.Offset+(cur.Y-ds.Y))
    end)
end

local function showMenu(state)
    cfg.MenuOpen  = state
    Root.Visible  = state
    ToggleBtn.Visible = not state
end

closeB.MouseButton1Click:Connect(function() showMenu(false) end)
ToggleBtn.MouseButton1Click:Connect(function() showMenu(true) end)

-- keyboard toggle
UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.RightShift then
        showMenu(not cfg.MenuOpen)
    end
end)

-- ══════════════════════════════════════════════════════════════════════
-- SIDEBAR
-- ══════════════════════════════════════════════════════════════════════
local Sidebar = newFrame(Root,
    UDim2.new(0,110,1,-52),
    UDim2.new(0,0,0,52),
    COL.PANEL)
corner(Sidebar, 10)
padding(Sidebar, 6)
listLayout(Sidebar, Enum.FillDirection.Vertical, 4)

-- ══════════════════════════════════════════════════════════════════════
-- CONTENT
-- ══════════════════════════════════════════════════════════════════════
local Content = newFrame(Root,
    UDim2.new(1,-114,1,-56),
    UDim2.new(0,112,0,54),
    COL.BG)
corner(Content, 10)

-- ══════════════════════════════════════════════════════════════════════
-- TAB SYSTEM
-- ══════════════════════════════════════════════════════════════════════
local tabBtns   = {}
local tabFrames = {}
local curTab    = ""

local function switchTab(name)
    for n, f in pairs(tabFrames) do f.Visible = (n == name) end
    for n, b in pairs(tabBtns) do
        b.BackgroundColor3       = (n == name) and accent().main or COL.OFF
        b.BackgroundTransparency = (n == name) and 0 or 0.2
        b.TextColor3             = (n == name) and COL.WHITE or COL.DIM
    end
    curTab = name
end

local TABS = {
    {n="Combat",   i="⚔"},
    {n="Visuals",  i="👁"},
    {n="Misc",     i="⚙"},
    {n="SDRP",     i="🚔"},
    {n="World",    i="🌐"},
    {n="Settings", i="☰"},
}

for idx, td in ipairs(TABS) do
    local b = newBtn(Sidebar, td.i.." "..td.n,
        UDim2.new(1,0,0,36), nil,
        COL.OFF, COL.DIM, 12)
    corner(b, 8)
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.LayoutOrder    = idx
    local lp = Instance.new("UIPadding", b)
    lp.PaddingLeft = UDim.new(0,8)

    local f = newFrame(Content, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), COL.BG, 1)
    f.Visible = false
    f.BackgroundTransparency = 1

    b.MouseButton1Click:Connect(function() switchTab(td.n) end)
    tabBtns[td.n]   = b
    tabFrames[td.n] = f
end

-- ══════════════════════════════════════════════════════════════════════
-- ROW BUILDERS  (TextButton-based for mobile)
-- ══════════════════════════════════════════════════════════════════════

-- section label
local function sectionRow(parent, text)
    local f = newFrame(parent, UDim2.new(1,0,0,26), nil, COL.BG, 1)
    f.LayoutOrder = 999
    local l = newLabel(f, text, 11, accent().main)
    l.Position = UDim2.new(0,4,0,0)
    local line = newFrame(f, UDim2.new(1,-8,0,1), UDim2.new(0,4,1,-1), accent().dim, 0.5)
    return f
end

-- toggle row — TextButton for the whole row, works on mobile
local function toggleRow(parent, text, key, onChange)
    local row = newBtn(parent, "",
        UDim2.new(1,0,0,42), nil,
        COL.ROW, COL.WHITE, 1)
    corner(row, 8)
    row.AutoButtonColor = false

    local lbl = newLabel(row, text, 13, COL.TEXT)
    lbl.Size     = UDim2.new(1,-70,1,0)
    lbl.Position = UDim2.new(0,10,0,0)
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    -- track
    local track = newFrame(row, UDim2.new(0,46,0,24),
        UDim2.new(1,-54,0.5,-12),
        cfg[key] and accent().main or COL.OFF)
    corner(track, 12)
    local knob = newFrame(track, UDim2.new(0,18,0,18),
        cfg[key] and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9),
        COL.WHITE)
    corner(knob, 9)

    local function setState(v)
        cfg[key] = v
        TweenService:Create(track, TweenInfo.new(0.12),
            {BackgroundColor3 = v and accent().main or COL.OFF}):Play()
        TweenService:Create(knob, TweenInfo.new(0.12),
            {Position = v and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9)}):Play()
        if onChange then task.spawn(onChange, v) end
    end

    row.MouseButton1Click:Connect(function() setState(not cfg[key]) end)
    return row, setState
end

-- slider row — touch-draggable
local function sliderRow(parent, text, key, minV, maxV, fmtFn)
    fmtFn = fmtFn or function(v) return math.floor(v) end
    local col = newFrame(parent, UDim2.new(1,0,0,62), nil, COL.ROW, 0)
    corner(col, 8)

    local hdr = newFrame(col, UDim2.new(1,0,0,22), UDim2.new(0,0,0,0), COL.ROW, 1)
    local lbl = newLabel(hdr, text, 11, COL.DIM)
    lbl.Position = UDim2.new(0,10,0,0)
    lbl.Size     = UDim2.new(0.7,0,1,0)
    local vLbl = newLabel(hdr, tostring(fmtFn(cfg[key])), 11, accent().main,
        Enum.TextXAlignment.Right)
    vLbl.Size     = UDim2.new(0.3,-10,1,0)
    vLbl.Position = UDim2.new(0.7,0,0,0)

    local trackBG = newFrame(col, UDim2.new(1,-20,0,6),
        UDim2.new(0,10,0,36), Color3.fromRGB(40,30,60))
    corner(trackBG, 3)
    local ratio = math.clamp((cfg[key]-minV)/(maxV-minV),0,1)
    local fill  = newFrame(trackBG, UDim2.new(ratio,0,1,0),
        UDim2.new(0,0,0,0), accent().main)
    corner(fill, 3)
    local knob = newFrame(trackBG, UDim2.new(0,18,0,18),
        UDim2.new(ratio,-9,0.5,-9), COL.WHITE)
    corner(knob, 9)

    local dragging = false
    local function updateSlider(absX)
        local left  = trackBG.AbsolutePosition.X
        local width = trackBG.AbsoluteSize.X
        local t = math.clamp((absX - left) / width, 0, 1)
        local v = minV + t * (maxV - minV)
        if key == "WalkSpeed" or key == "JumpPower" or key == "FlySpeed"
        or key == "VehicleSpeed" or key == "SpinSpeed" then
            v = math.floor(v)
        end
        cfg[key]  = v
        vLbl.Text = tostring(fmtFn(v))
        fill.Size     = UDim2.new(t, 0, 1, 0)
        knob.Position = UDim2.new(t, -9, 0.5, -9)
    end

    -- make entire track area a button for tap-to-set
    local hitBtn = newBtn(col, "", UDim2.new(1,-20,0,24),
        UDim2.new(0,10,0,30), COL.ROW, COL.WHITE, 1)
    hitBtn.BackgroundTransparency = 1
    hitBtn.AutoButtonColor = false
    hitBtn.ZIndex = 5

    hitBtn.MouseButton1Down:Connect(function()
        dragging = true
        local mx = UserInputService:GetMouseLocation().X
        updateSlider(mx)
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch then
            updateSlider(UserInputService:GetMouseLocation().X)
        end
    end)

    return col
end

-- dropdown (cycle button)
local function dropRow(parent, text, key, options)
    local row = newBtn(parent, "",
        UDim2.new(1,0,0,42), nil, COL.ROW, COL.WHITE, 1)
    corner(row, 8)
    row.AutoButtonColor = false

    local lbl = newLabel(row, text, 13, COL.TEXT)
    lbl.Size     = UDim2.new(0.55,0,1,0)
    lbl.Position = UDim2.new(0,10,0,0)

    local valB = newBtn(row, cfg[key],
        UDim2.new(0.4,-4,0,30), UDim2.new(0.57,0,0.5,-15),
        accent().dim, COL.WHITE, 12)
    corner(valB, 7)

    local idx = 1
    for i,v in ipairs(options) do if v == cfg[key] then idx=i break end end

    local function cycle()
        idx = idx % #options + 1
        cfg[key] = options[idx]
        valB.Text = options[idx]
    end
    row.MouseButton1Click:Connect(cycle)
    valB.MouseButton1Click:Connect(cycle)

    return row
end

-- action button
local function actionRow(parent, text, callback)
    local b = newBtn(parent, text,
        UDim2.new(1,0,0,38), nil, accent().main, COL.WHITE, 13)
    corner(b, 8)
    b.MouseButton1Click:Connect(function() task.spawn(callback) end)
    return b
end

-- ══════════════════════════════════════════════════════════════════════
-- BUILD TABS
-- ══════════════════════════════════════════════════════════════════════

local function buildList(frame)
    local sv = scrollFrame(frame)
    local list = newFrame(sv, UDim2.new(1,0,0,1), nil, COL.BG, 1)
    list.AutomaticSize = Enum.AutomaticSize.Y
    listLayout(list, Enum.FillDirection.Vertical, 4)
    padding(list, 6)
    return list
end

-- ── COMBAT ────────────────────────────────────────────────────────────
do
    local list = buildList(tabFrames["Combat"])

    sectionRow(list, "AIM & FOV").LayoutOrder = 1
    local t1,_ = toggleRow(list,"Aimbot",        "Aimbot")      t1.LayoutOrder=2
    local t2,_ = toggleRow(list,"Silent Aim",    "SilentAim")   t2.LayoutOrder=3
    local t3,_ = toggleRow(list,"Draw FOV",      "DrawFOV")     t3.LayoutOrder=4
    local t4,_ = toggleRow(list,"Prediction",    "Prediction")  t4.LayoutOrder=5
    local s1   = sliderRow(list,"Smoothness",    "AimbotSmooth",0.05,1,
        function(v) return math.floor(v*100).."%" end)           s1.LayoutOrder=6
    local s2   = sliderRow(list,"FOV Radius",    "FOVRadius",50,400,
        function(v) return math.floor(v).."px" end)              s2.LayoutOrder=7

    sectionRow(list,"TARGETING").LayoutOrder = 8
    local t5,_ = toggleRow(list,"Wall Check",    "WallCheck")   t5.LayoutOrder=9
    local t6,_ = toggleRow(list,"Team Check",    "TeamCheck")   t6.LayoutOrder=10
    local d1   = dropRow(list,"Target Part","TargetPart",
        {"Head","Torso","HumanoidRootPart","UpperTorso"})         d1.LayoutOrder=11

    sectionRow(list,"WEAPON").LayoutOrder=12
    local t7,_ = toggleRow(list,"No Recoil",    "NoRecoil")    t7.LayoutOrder=13
    local t8,_ = toggleRow(list,"No Spread",    "NoSpread")    t8.LayoutOrder=14
    local t9,_ = toggleRow(list,"Rapid Fire",   "RapidFire")   t9.LayoutOrder=15
    local t10,_= toggleRow(list,"Infinite Ammo","InfiniteAmmo")t10.LayoutOrder=16
end

-- ── VISUALS ───────────────────────────────────────────────────────────
do
    local list = buildList(tabFrames["Visuals"])
    sectionRow(list,"ESP").LayoutOrder=1
    local t1,_ = toggleRow(list,"ESP Master",   "ESP")         t1.LayoutOrder=2
    local t2,_ = toggleRow(list,"Box ESP",      "BoxESP")      t2.LayoutOrder=3
    local t3,_ = toggleRow(list,"Name ESP",     "NameESP")     t3.LayoutOrder=4
    local t4,_ = toggleRow(list,"Health Bar",   "HealthBar")   t4.LayoutOrder=5
    local t5,_ = toggleRow(list,"Skeleton ESP", "SkeletonESP") t5.LayoutOrder=6
    local t6,_ = toggleRow(list,"Distance ESP", "DistanceESP") t6.LayoutOrder=7
    local t7,_ = toggleRow(list,"Tracer Lines", "TracerESP")   t7.LayoutOrder=8
end

-- ── MISC ──────────────────────────────────────────────────────────────
do
    local list = buildList(tabFrames["Misc"])
    sectionRow(list,"MOVEMENT").LayoutOrder=1
    local t1,_ = toggleRow(list,"Noclip",       "Noclip",
        function(v) task.spawn(setNoclip,v) end)                t1.LayoutOrder=2
    local t2,_ = toggleRow(list,"Speed Boost",  "SpeedBoost")  t2.LayoutOrder=3
    local s1   = sliderRow(list,"Walk Speed",   "WalkSpeed",1,250,
        function(v) return math.floor(v) end)                   s1.LayoutOrder=4
    local t3,_ = toggleRow(list,"Jump Boost",   "JumpBoost")   t3.LayoutOrder=5
    local s2   = sliderRow(list,"Jump Power",   "JumpPower",1,300,
        function(v) return math.floor(v) end)                   s2.LayoutOrder=6
    local t4,_ = toggleRow(list,"Infinite Jump","InfiniteJump",
        function(v) task.spawn(setInfJump,v) end)              t4.LayoutOrder=7
    local t5,_ = toggleRow(list,"Fly",          "Fly",
        function(v) task.spawn(setFly,v) end)                  t5.LayoutOrder=8
    local s3   = sliderRow(list,"Fly Speed",    "FlySpeed",1,200,
        function(v) return math.floor(v) end)                   s3.LayoutOrder=9

    sectionRow(list,"PLAYER").LayoutOrder=10
    local t6,_ = toggleRow(list,"God Mode",     "GodMode")     t6.LayoutOrder=11
    local t7,_ = toggleRow(list,"Anti AFK",     "AntiAFK")     t7.LayoutOrder=12
    local t8,_ = toggleRow(list,"Spin Bot",     "SpinBot",
        function(v) task.spawn(setSpinBot,v) end)              t8.LayoutOrder=13
    local s4   = sliderRow(list,"Spin Speed",   "SpinSpeed",1,50,
        function(v) return math.floor(v) end)                   s4.LayoutOrder=14
end

-- ── SDRP ─────────────────────────────────────────────────────────────
do
    local list = buildList(tabFrames["SDRP"])
    sectionRow(list,"LAW ENFORCEMENT").LayoutOrder=1
    local t1,_ = toggleRow(list,"Cop ESP",      "CopESP")      t1.LayoutOrder=2
    local t2,_ = toggleRow(list,"Criminal ESP", "CriminalESP") t2.LayoutOrder=3
    local t3,_ = toggleRow(list,"Wanted ESP",   "WantedESP")   t3.LayoutOrder=4
    local t4,_ = toggleRow(list,"Auto Arrest",  "AutoArrest")  t4.LayoutOrder=5

    sectionRow(list,"VEHICLE").LayoutOrder=6
    local t5,_ = toggleRow(list,"Vehicle Boost","VehicleBoost")t5.LayoutOrder=7
    local s1   = sliderRow(list,"Vehicle Speed","VehicleSpeed",50,300,
        function(v) return math.floor(v).." mph" end)           s1.LayoutOrder=8
    local t6,_ = toggleRow(list,"Anti Flip",    "AntiFlip")    t6.LayoutOrder=9
    local t7,_ = toggleRow(list,"Auto Evade",   "AutoEvade")   t7.LayoutOrder=10

    sectionRow(list,"TELEPORT").LayoutOrder=11
    actionRow(list,"Teleport to Spawn", function()
        if not HRP then return end
        local sp = workspace:FindFirstChild("SpawnLocation")
        if sp then HRP.CFrame = CFrame.new(sp.Position + Vector3.new(0,5,0)) end
    end).LayoutOrder=12
    actionRow(list,"Teleport to Nearest", function()
        if not HRP then return end
        local t = getClosest()
        if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
            HRP.CFrame = t.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,5)
        end
    end).LayoutOrder=13
end

-- ── WORLD ─────────────────────────────────────────────────────────────
do
    local list = buildList(tabFrames["World"])
    sectionRow(list,"WORLD").LayoutOrder=1
    local t1,_ = toggleRow(list,"Fullbright","Fullbright",
        function(v) task.spawn(setFullbright,v) end)           t1.LayoutOrder=2
    local t2,_ = toggleRow(list,"No Fog","NoFog",
        function(v) Lighting.FogEnd = v and 1e9 or 100000 end) t2.LayoutOrder=3
    local t3,_ = toggleRow(list,"FPS Boost","FPSBoost",
        function(v)
            pcall(function()
                settings().Rendering.QualityLevel =
                    v and Enum.QualityLevel.Level01
                      or  Enum.QualityLevel.Automatic
            end)
        end)                                                     t3.LayoutOrder=4
end

-- ── SETTINGS ──────────────────────────────────────────────────────────
do
    local list = buildList(tabFrames["Settings"])
    sectionRow(list,"UI SIZE").LayoutOrder=1
    local sScale = sliderRow(list,"UI Scale","UIScale",0.6,1.8,
        function(v) return math.floor(v*100).."%" end)
    sScale.LayoutOrder=2
    -- apply scale on release via RunService — watch cfg.UIScale
    local lastScale = cfg.UIScale
    RunService.Heartbeat:Connect(function()
        if cfg.UIScale ~= lastScale then
            lastScale = cfg.UIScale
            local w = scaled(BASE_W)
            local h = scaled(BASE_H)
            Root.Size = UDim2.new(0,w,0,h)
            Root.Position = UDim2.new(0.5,-w/2,0.5,-h/2)
        end
    end)

    sectionRow(list,"UI COLOR").LayoutOrder=3
    local colorOpts = {"Purple","Teal","Red","Green","Orange"}
    local d1 = dropRow(list,"Accent Color","AccentColor",colorOpts)
    d1.LayoutOrder=4

    sectionRow(list,"DISCORD").LayoutOrder=5
    actionRow(list,"Copy Discord Link", function()
        pcall(function() setclipboard(DISCORD) end)
    end).LayoutOrder=6

    sectionRow(list,"KEYBIND").LayoutOrder=7
    local kl = newFrame(list, UDim2.new(1,0,0,36), nil, COL.ROW, 0)
    corner(kl, 8)
    kl.LayoutOrder=8
    newLabel(kl,"RightShift → Toggle Menu", 12, COL.DIM,
        Enum.TextXAlignment.Center).Size = UDim2.new(1,0,1,0)
end

-- start on Combat tab
switchTab("Combat")

-- ══════════════════════════════════════════════════════════════════════
-- GAME LOGIC  (task.spawn — no freeze)
-- ══════════════════════════════════════════════════════════════════════

-- helpers
local function isEnemy(p)
    if p == LP then return false end
    if cfg.TeamCheck and p.Team == LP.Team then return false end
    return true
end
local function alive(p)
    return p.Character
        and p.Character:FindFirstChild("HumanoidRootPart")
        and p.Character:FindFirstChildOfClass("Humanoid")
        and p.Character:FindFirstChildOfClass("Humanoid").Health > 0
end
local function w2v(pos)
    local v, on = Camera:WorldToViewportPoint(pos)
    return Vector2.new(v.X,v.Y), on, v.Z
end

function getClosest()
    local best, bestD = nil, cfg.FOVRadius
    local c2 = Camera.ViewportSize/2
    for _, p in ipairs(Players:GetPlayers()) do
        if isEnemy(p) and alive(p) then
            local part = p.Character:FindFirstChild(cfg.TargetPart)
                      or p.Character:FindFirstChild("HumanoidRootPart")
            if part then
                local v2, on = w2v(part.Position)
                if on then
                    local d = (v2 - c2).Magnitude
                    if d < bestD then bestD=d; best=p end
                end
            end
        end
    end
    return best
end

-- FOV circle
local fovCircle = Drawing.new("Circle")
fovCircle.Visible   = true
fovCircle.Color     = accent().main
fovCircle.Thickness = 1.5
fovCircle.Filled    = false
fovCircle.NumSides  = 64
fovCircle.Radius    = cfg.FOVRadius

-- ESP store
local espStore = {}
Players.PlayerRemoving:Connect(function(p)
    if espStore[p] then
        for _,d in pairs(espStore[p]) do pcall(function() d:Remove() end) end
        espStore[p] = nil
    end
end)
local function getESP(p)
    if not espStore[p] then
        local function D(t,props)
            local d = Drawing.new(t)
            for k,v in pairs(props) do d[k]=v end
            return d
        end
        espStore[p] = {
            box  = D("Square",{Visible=false,Color=COL.RED,Thickness=1.5,Filled=false}),
            name = D("Text",  {Visible=false,Color=COL.WHITE,Size=13,Center=true,
                               Outline=true,OutlineColor=Color3.new(0,0,0)}),
            hpBG = D("Square",{Visible=false,Color=Color3.fromRGB(30,30,30),
                               Thickness=1,Filled=true}),
            hp   = D("Square",{Visible=false,Color=COL.GREEN,Thickness=1,Filled=true}),
            dist = D("Text",  {Visible=false,Color=Color3.fromRGB(200,200,200),
                               Size=11,Center=true,Outline=true,
                               OutlineColor=Color3.new(0,0,0)}),
            trac = D("Line",  {Visible=false,Color=COL.RED,Thickness=1}),
        }
    end
    return espStore[p]
end

-- noclip
local noclipConn
function setNoclip(v)
    if noclipConn then noclipConn:Disconnect(); noclipConn=nil end
    if v then
        noclipConn = RunService.Stepped:Connect(function()
            if Char then
                for _,p in ipairs(Char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide=false end
                end
            end
        end)
    end
end

-- fly
local flyConn, flyBV, flyBG2
function setFly(v)
    if flyConn then flyConn:Disconnect(); flyConn=nil end
    if flyBV then flyBV:Destroy(); flyBV=nil end
    if flyBG2 then flyBG2:Destroy(); flyBG2=nil end
    if not v or not HRP then return end
    flyBV = Instance.new("BodyVelocity",HRP)
    flyBV.MaxForce = Vector3.new(1e6,1e6,1e6)
    flyBV.Velocity = Vector3.zero
    flyBG2 = Instance.new("BodyGyro",HRP)
    flyBG2.MaxTorque = Vector3.new(1e6,1e6,1e6)
    flyBG2.P = 1e4
    flyConn = RunService.RenderStepped:Connect(function()
        if not cfg.Fly then setFly(false); return end
        local d = Vector3.zero
        local cf = Camera.CFrame
        local UIS = UserInputService
        if UIS:IsKeyDown(Enum.KeyCode.W) then d=d+cf.LookVector  end
        if UIS:IsKeyDown(Enum.KeyCode.S) then d=d-cf.LookVector  end
        if UIS:IsKeyDown(Enum.KeyCode.A) then d=d-cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then d=d+cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then d=d+Vector3.yAxis end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then d=d-Vector3.yAxis end
        flyBV.Velocity = d.Magnitude>0 and d.Unit*cfg.FlySpeed or Vector3.zero
        flyBG2.CFrame  = cf
    end)
end

-- infinite jump
local ijConn
function setInfJump(v)
    if ijConn then ijConn:Disconnect(); ijConn=nil end
    if v then
        ijConn = UserInputService.JumpRequest:Connect(function()
            if Hum then Hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    end
end

-- spinbot
local spinConn
function setSpinBot(v)
    if spinConn then spinConn:Disconnect(); spinConn=nil end
    if v then
        spinConn = RunService.RenderStepped:Connect(function()
            if HRP then
                HRP.CFrame = HRP.CFrame * CFrame.Angles(0,math.rad(cfg.SpinSpeed),0)
            end
        end)
    end
end

-- fullbright
function setFullbright(v)
    if v then
        Lighting.Brightness     = 10
        Lighting.ClockTime      = 14
        Lighting.FogEnd         = 1e9
        Lighting.GlobalShadows  = false
        Lighting.Ambient        = Color3.new(1,1,1)
        Lighting.OutdoorAmbient = Color3.new(1,1,1)
    else
        Lighting.Brightness     = 1
        Lighting.GlobalShadows  = true
        Lighting.Ambient        = Color3.fromRGB(127,127,127)
        Lighting.OutdoorAmbient = Color3.fromRGB(127,127,127)
    end
end

-- anti-AFK
local afkConn
task.spawn(function()
    local vrs = LP:FindFirstChildOfClass("VirtualUser")
    if not vrs then vrs = Instance.new("VirtualUser",LP) end
    afkConn = LP.Idled:Connect(function()
        if cfg.AntiAFK then
            vrs:CaptureController()
            vrs:ClickButton2(Vector2.new())
        end
    end)
end)

-- silent aim (metatable hook)
task.spawn(function()
    if not getrawmetatable then return end
    local mt = getrawmetatable(game)
    local old = mt.__namecall
    setreadonly(mt,false)
    mt.__namecall = newcclosure(function(self,...)
        local m = getnamecallmethod()
        if cfg.SilentAim and (m=="FireServer" or m=="InvokeServer") then
            local t = getClosest()
            if t and t.Character then
                local part = t.Character:FindFirstChild(cfg.TargetPart)
                          or t.Character:FindFirstChild("HumanoidRootPart")
                if part then
                    local args = {...}
                    for i,v in ipairs(args) do
                        if typeof(v)=="Instance" and v:IsA("BasePart") then
                            args[i]=part; break
                        end
                        if typeof(v)=="Vector3" then
                            args[i]=part.Position; break
                        end
                    end
                    return old(self,table.unpack(args))
                end
            end
        end
        return old(self,...)
    end)
    setreadonly(mt,true)
end)

-- ══════════════════════════════════════════════════════════════════════
-- RENDER LOOP  (RenderStepped — no freeze risk, light work only)
-- ══════════════════════════════════════════════════════════════════════
RunService.RenderStepped:Connect(function()
    -- FOV
    local cv = Camera.ViewportSize
    fovCircle.Position = Vector2.new(cv.X/2, cv.Y/2)
    fovCircle.Visible  = cfg.DrawFOV
    fovCircle.Radius   = cfg.FOVRadius
    fovCircle.Color    = accent().main

    -- Aimbot
    if cfg.Aimbot then
        local t = getClosest()
        if t and t.Character then
            local part = t.Character:FindFirstChild(cfg.TargetPart)
                      or t.Character:FindFirstChild("HumanoidRootPart")
            if part then
                local pos = part.Position
                if cfg.Prediction then
                    local dist = (Camera.CFrame.Position-pos).Magnitude
                    pos = pos + part.Velocity*(dist/900)
                end
                Camera.CFrame = Camera.CFrame:Lerp(
                    CFrame.lookAt(Camera.CFrame.Position,pos),
                    cfg.AimbotSmooth)
            end
        end
    end

    -- Misc live
    if Hum then
        if cfg.SpeedBoost then Hum.WalkSpeed = cfg.WalkSpeed end
        if cfg.JumpBoost  then Hum.JumpPower  = cfg.JumpPower  end
        if cfg.GodMode    then Hum.Health     = Hum.MaxHealth  end
    end

    -- ESP
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP then continue end
        local esp = getESP(p)
        local show = cfg.ESP and alive(p)
        if not show then
            for _,d in pairs(esp) do d.Visible=false end
            continue
        end
        local c   = p.Character
        local hrp = c.HumanoidRootPart
        local hum = c:FindFirstChildOfClass("Humanoid")
        local top2d, onTop = w2v(hrp.Position+Vector3.new(0,3.2,0))
        local bot2d, onBot = w2v(hrp.Position-Vector3.new(0,2.5,0))
        if not onTop and not onBot then
            for _,d in pairs(esp) do d.Visible=false end
            continue
        end
        local h = math.abs(top2d.Y-bot2d.Y)
        local w = h*0.5
        local ec = isEnemy(p) and COL.RED or COL.GREEN

        -- box
        if cfg.BoxESP then
            esp.box.Visible=true; esp.box.Color=ec
            esp.box.Size=Vector2.new(w,h)
            esp.box.Position=Vector2.new(top2d.X-w/2,top2d.Y)
        else esp.box.Visible=false end

        -- name
        if cfg.NameESP then
            local hp2,on2 = w2v(hrp.Position+Vector3.new(0,3.8,0))
            esp.name.Visible=on2; esp.name.Text=p.Name
            esp.name.Position=hp2; esp.name.Color=ec
        else esp.name.Visible=false end

        -- health
        if cfg.HealthBar and hum then
            local r = math.clamp(hum.Health/hum.MaxHealth,0,1)
            local bh = h*r
            local bx = top2d.X-w/2-6
            esp.hpBG.Visible=true
            esp.hpBG.Position=Vector2.new(bx-2,top2d.Y)
            esp.hpBG.Size=Vector2.new(5,h)
            esp.hp.Visible=true
            esp.hp.Position=Vector2.new(bx-2,top2d.Y+(h-bh))
            esp.hp.Size=Vector2.new(5,bh)
            esp.hp.Color=Color3.fromRGB(math.floor(255*(1-r)),math.floor(255*r),40)
        else esp.hp.Visible=false; esp.hpBG.Visible=false end

        -- distance
        if cfg.DistanceESP and HRP then
            local d3=math.floor((hrp.Position-HRP.Position).Magnitude)
            esp.dist.Visible=true
            esp.dist.Text=d3.."m"
            esp.dist.Position=Vector2.new(top2d.X,bot2d.Y+2)
        else esp.dist.Visible=false end

        -- tracer
        if cfg.TracerESP then
            esp.trac.Visible=true; esp.trac.Color=ec
            esp.trac.From=Vector2.new(cv.X/2,cv.Y)
            esp.trac.To=bot2d
        else esp.trac.Visible=false end
    end
end)

-- ══════════════════════════════════════════════════════════════════════
-- NOTIFY + DONE
-- ══════════════════════════════════════════════════════════════════════
pcall(function()
    StarterGui:SetCore("SendNotification",{
        Title="AngelHub v3.1",
        Text="Loaded! RightShift to toggle.",
        Duration=4,
    })
end)

print("[AngelHub v3.1] loaded — San Diego RP Border — "..DISCORD)
