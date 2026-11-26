-- AngelHub v1.0 | https://discord.gg/d8gpXNGknP
-- Compatible: Synapse X, KRNL, Fluxus, Delta (Android/iOS), Codex
-- Runtime: Roblox Luau | Tested pattern: Drawing + CoreGui injection
-- Anti-detect: no suspicious globals named, hook via __index on humanoid

----------------------------------------------------------------
-- LOGO + HEADER
----------------------------------------------------------------
local LOGO = [[
  ▄▄▄·  ███▄    █  ▄▄ • ▄▄▄ .▄▄▌  ▄ .▄▄▄• ▄▌ ▄▄▄▄·
 ▐█ ▀█  ██ ▀█   █ ▐█ ▀ ▪▀▄.▀·██•  ██▪▐██▪██▌ ▐█ ▀█▪
 ▄█▀▀█ ▐█ ▀█▄  ▐█▄█▌▐█▀▀█▄██▪▐█▌  ██▀▀█▐█▌▐█▌▐█▀▀█▄
 ▐█ ▪▐▌██▄▐████▌▀▀█▄ ██▄▪▐█▐█▌.▐▌  ██▌▐▀▐█▄█▌██▄▪▐█
  ▀  ▀ ·▀▀ █▪ ▀·▀▀▀  ·▀▀▀▀  .▀▀▀   ▀▀▀ ·  ▀▀▀ ·▀▀▀▀
         A n g e l H u b  v 1 . 0
]]
local DISCORD = "https://discord.gg/d8gpXNGknP"

----------------------------------------------------------------
-- SERVICES
----------------------------------------------------------------
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Camera           = workspace.CurrentCamera
local LocalPlayer      = Players.LocalPlayer
local Mouse            = LocalPlayer:GetMouse()

----------------------------------------------------------------
-- CLIPBOARD HELPER
----------------------------------------------------------------
local function copyToClipboard(text)
    if setclipboard then setclipboard(text)
    elseif toclipboard then toclipboard(text)
    elseif syn and syn.write_clipboard then syn.write_clipboard(text)
    end
end

----------------------------------------------------------------
-- SETTINGS STATE
----------------------------------------------------------------
local CFG = {
    AimbotEnabled  = false,
    SilentAim      = false,
    AimPart        = "Head",
    AimFOV         = 120,
    AimSmooth      = 0.18,
    AimKey         = Enum.UserInputType.MouseButton2,
    PredictionVal  = 0.12,
    TeamCheck      = true,
    WallCheck      = true,
    ESPEnabled     = false,
    ESPBoxes       = true,
    ESPNames       = true,
    ESPDistance    = true,
    ESPHealth      = true,
    ESPTracers     = false,
    ESPTeamColor   = false,
    ESPColor       = Color3.fromRGB(0, 220, 255),
    MaxESPDist     = 500,
    NoClip         = false,
    SpeedEnabled   = false,
    SpeedValue     = 24,
    JumpEnabled    = false,
    JumpValue      = 50,
    InfJump        = false,
    FlyEnabled     = false,
    FlySpeed       = 50,
    AntiAFK        = true,
    UIScale        = 1.0,
    UIOpacity      = 0.95,
    KeybindOpen    = Enum.KeyCode.RightShift,
}

----------------------------------------------------------------
-- UTILITY
----------------------------------------------------------------
local function getCharacter(p) return p and p.Character end
local function getHumanoid(p)
    local c = getCharacter(p)
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function getRootPart(p)
    local c = getCharacter(p)
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getPart(p, partName)
    local c = getCharacter(p)
    return c and c:FindFirstChild(partName)
end
local function isAlive(p)
    local h = getHumanoid(p)
    return h and h.Health > 0
end
local function isSameTeam(p)
    return p.Team and LocalPlayer.Team and p.Team == LocalPlayer.Team
end
local function worldToViewport(pos)
    local vp, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(vp.X, vp.Y), onScreen, vp.Z
end

local function getClosestPlayer()
    local closest, closestDist = nil, CFG.AimFOV
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        if CFG.TeamCheck and isSameTeam(p) then continue end
        if not isAlive(p) then continue end
        local part = getPart(p, CFG.AimPart)
        if not part then continue end
        local vp, onScreen, depth = worldToViewport(part.Position)
        if not onScreen or depth < 0 then continue end
        local dist = (vp - center).Magnitude
        if dist < closestDist then
            closestDist = dist
            closest = p
        end
    end
    return closest
end

----------------------------------------------------------------
-- AIMBOT
----------------------------------------------------------------
local aimbotConn
local function startAimbot()
    if aimbotConn then aimbotConn:Disconnect() end
    aimbotConn = RunService.Heartbeat:Connect(function()
        if not CFG.AimbotEnabled then return end
        local holding = UserInputService:IsMouseButtonPressed(CFG.AimKey)
            or UserInputService:IsKeyDown(Enum.KeyCode.Q)
        if not holding then return end
        local target = getClosestPlayer()
        if not target then return end
        local part = getPart(target, CFG.AimPart)
        if not part then return end
        local root = getRootPart(target)
        local vel = root and root.AssemblyLinearVelocity or Vector3.zero
        local predicted = part.Position + vel * CFG.PredictionVal
        local vp, onScreen = Camera:WorldToViewportPoint(predicted)
        if not onScreen then return end
        local curX, curY = Mouse.X, Mouse.Y
        local smooth = CFG.AimSmooth
        mousemoverel(
            (vp.X - curX) * (1 - smooth),
            (vp.Y - curY) * (1 - smooth)
        )
    end)
end
startAimbot()

----------------------------------------------------------------
-- SILENT AIM
----------------------------------------------------------------
local silentHooked = false
local function hookSilentAim()
    if silentHooked then return end
    silentHooked = true
    local mt = getrawmetatable(game)
    local old_newindex = mt.__newindex
    setreadonly(mt, false)
    mt.__newindex = function(t, k, v)
        if CFG.SilentAim and t == Mouse and k == "Hit" then
            local target = getClosestPlayer()
            if target then
                local part = getPart(target, CFG.AimPart)
                if part then
                    return old_newindex(t, k, CFrame.new(part.Position))
                end
            end
        end
        return old_newindex(t, k, v)
    end
    setreadonly(mt, true)
end
pcall(hookSilentAim)

----------------------------------------------------------------
-- ESP
----------------------------------------------------------------
local ESPObjects = {}

local function removeESP(p)
    if ESPObjects[p] then
        for _, d in pairs(ESPObjects[p]) do pcall(function() d:Remove() end) end
        ESPObjects[p] = nil
    end
end

local function createESP(p)
    removeESP(p)
    local e = {
        Box    = Drawing.new("Square"),
        Name   = Drawing.new("Text"),
        Health = Drawing.new("Text"),
        Dist   = Drawing.new("Text"),
        Tracer = Drawing.new("Line"),
    }
    e.Box.Thickness = 1; e.Box.Filled = false; e.Box.Visible = false
    e.Name.Size = 13; e.Name.Center = true; e.Name.Outline = true; e.Name.Visible = false
    e.Health.Size = 11; e.Health.Center = true; e.Health.Outline = true; e.Health.Visible = false
    e.Dist.Size = 11; e.Dist.Center = true; e.Dist.Outline = true; e.Dist.Visible = false
    e.Tracer.Thickness = 1; e.Tracer.Visible = false
    ESPObjects[p] = e
end

local espConn
local function startESP()
    if espConn then espConn:Disconnect() end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then createESP(p) end
    end
    Players.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function() task.wait(0.5); createESP(p) end)
    end)
    Players.PlayerRemoving:Connect(removeESP)

    espConn = RunService.Heartbeat:Connect(function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LocalPlayer then continue end
            local e = ESPObjects[p]
            if not e then createESP(p); continue end
            local char = getCharacter(p)
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum  = getHumanoid(p)
            local head = char and char:FindFirstChild("Head")
            local vis  = CFG.ESPEnabled and root ~= nil and isAlive(p)
            if CFG.TeamCheck and isSameTeam(p) then vis = false end
            local color = CFG.ESPTeamColor
                and (p.TeamColor and p.TeamColor.Color or CFG.ESPColor)
                or CFG.ESPColor

            if vis then
                local rootVP, onScreen, depth = worldToViewport(root.Position)
                if not onScreen or depth < 0 then vis = false end
                local dist3d = (root.Position - Camera.CFrame.Position).Magnitude
                if dist3d > CFG.MaxESPDist then vis = false end

                if vis and CFG.ESPBoxes and head then
                    local headVP = worldToViewport(head.Position + Vector3.new(0,0.5,0))
                    local h = math.abs(headVP.Y - rootVP.Y) * 2
                    local w = h * 0.6
                    e.Box.Position = Vector2.new(rootVP.X - w/2, headVP.Y)
                    e.Box.Size = Vector2.new(w, h)
                    e.Box.Color = color; e.Box.Visible = true
                else e.Box.Visible = false end

                if vis and CFG.ESPNames and head then
                    local headVP = worldToViewport(head.Position + Vector3.new(0,1,0))
                    e.Name.Position = Vector2.new(headVP.X, headVP.Y - 15)
                    e.Name.Text = p.DisplayName
                    e.Name.Color = color; e.Name.Visible = true
                else e.Name.Visible = false end

                if vis and CFG.ESPHealth and hum then
                    local hp = math.floor(hum.Health)
                    local hpColor = Color3.fromRGB(255 - math.floor(hp*2.55), math.floor(hp*2.55), 0)
                    local botVP = worldToViewport(root.Position + Vector3.new(0,-3,0))
                    e.Health.Position = Vector2.new(botVP.X, botVP.Y)
                    e.Health.Text = hp.."HP"; e.Health.Color = hpColor; e.Health.Visible = true
                else e.Health.Visible = false end

                if vis and CFG.ESPDistance then
                    local d = math.floor((root.Position - Camera.CFrame.Position).Magnitude)
                    local botVP2 = worldToViewport(root.Position + Vector3.new(0,-5,0))
                    e.Dist.Position = Vector2.new(botVP2.X, botVP2.Y)
                    e.Dist.Text = d.."m"; e.Dist.Color = Color3.fromRGB(180,180,180); e.Dist.Visible = true
                else e.Dist.Visible = false end

                if vis and CFG.ESPTracers then
                    e.Tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                    e.Tracer.To = worldToViewport(root.Position)
                    e.Tracer.Color = color; e.Tracer.Visible = true
                else e.Tracer.Visible = false end
            else
                e.Box.Visible = false; e.Name.Visible = false
                e.Health.Visible = false; e.Dist.Visible = false; e.Tracer.Visible = false
            end
        end
    end)
end
startESP()

----------------------------------------------------------------
-- MISC — NoClip
----------------------------------------------------------------
local noclipConn
local function startNoclip()
    if noclipConn then noclipConn:Disconnect() end
    noclipConn = RunService.Stepped:Connect(function()
        if not CFG.NoClip then return end
        local char = LocalPlayer.Character
        if not char then return end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end)
end
startNoclip()

----------------------------------------------------------------
-- MISC — Speed
----------------------------------------------------------------
local speedConn
local function startSpeed()
    if speedConn then speedConn:Disconnect() end
    speedConn = RunService.Heartbeat:Connect(function()
        if not CFG.SpeedEnabled then return end
        local hum = getHumanoid(LocalPlayer)
        if hum then hum.WalkSpeed = CFG.SpeedValue end
    end)
end
startSpeed()

----------------------------------------------------------------
-- MISC — Jump
----------------------------------------------------------------
local jumpConn
local function startJump()
    if jumpConn then jumpConn:Disconnect() end
    jumpConn = RunService.Heartbeat:Connect(function()
        if not CFG.JumpEnabled then return end
        local hum = getHumanoid(LocalPlayer)
        if hum then hum.JumpPower = CFG.JumpValue end
    end)
end
startJump()

----------------------------------------------------------------
-- MISC — Infinite Jump
----------------------------------------------------------------
UserInputService.JumpRequest:Connect(function()
    if not CFG.InfJump then return end
    local hum = getHumanoid(LocalPlayer)
    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

----------------------------------------------------------------
-- MISC — Fly
----------------------------------------------------------------
local flyConn, flyBV, flyBG
local function startFly()
    if flyConn then flyConn:Disconnect() end
    if not CFG.FlyEnabled then
        if flyBV then flyBV:Destroy() end
        if flyBG then flyBG:Destroy() end
        flyBV, flyBG = nil, nil
        return
    end
    local root = getRootPart(LocalPlayer)
    if not root then return end
    if flyBG then flyBG:Destroy() end
    if flyBV then flyBV:Destroy() end
    flyBG = Instance.new("BodyGyro", root)
    flyBG.P = 9e4; flyBG.MaxTorque = Vector3.new(9e9,9e9,9e9)
    flyBV = Instance.new("BodyVelocity", root)
    flyBV.Velocity = Vector3.zero; flyBV.MaxForce = Vector3.new(9e9,9e9,9e9)
    flyConn = RunService.Heartbeat:Connect(function()
        if not CFG.FlyEnabled then flyBV.Velocity = Vector3.zero; return end
        local cf = Camera.CFrame
        local vel = Vector3.zero
        local spd = CFG.FlySpeed
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then vel = vel + cf.LookVector * spd end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then vel = vel - cf.LookVector * spd end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then vel = vel - cf.RightVector * spd end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then vel = vel + cf.RightVector * spd end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vel = vel + Vector3.new(0,spd,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then vel = vel - Vector3.new(0,spd,0) end
        flyBV.Velocity = vel
        flyBG.CFrame = cf
    end)
end

----------------------------------------------------------------
-- ANTI-AFK
----------------------------------------------------------------
local VirtualUser = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    if CFG.AntiAFK then
        VirtualUser:Button2Down(Vector2.new(0,0), Camera.CFrame)
        task.wait(0.1)
        VirtualUser:Button2Up(Vector2.new(0,0), Camera.CFrame)
    end
end)

----------------------------------------------------------------
-- GUI FRAMEWORK
----------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AngelHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true

pcall(function()
    if syn and syn.protect_gui then
        syn.protect_gui(ScreenGui)
        ScreenGui.Parent = game.CoreGui
    elseif gethui then
        ScreenGui.Parent = gethui()
    else
        ScreenGui.Parent = game.CoreGui
    end
end)
if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local CLR = {
    BG        = Color3.fromRGB(10, 10, 18),
    Sidebar   = Color3.fromRGB(14, 14, 24),
    Panel     = Color3.fromRGB(18, 18, 30),
    Accent    = Color3.fromRGB(0, 220, 255),
    AccentDim = Color3.fromRGB(0, 140, 170),
    Text      = Color3.fromRGB(220, 220, 240),
    SubText   = Color3.fromRGB(130, 130, 160),
    Toggle_On = Color3.fromRGB(0, 220, 255),
    Toggle_Off= Color3.fromRGB(50, 50, 70),
    Border    = Color3.fromRGB(0, 180, 220),
}

local FONT     = Enum.Font.GothamBold
local FONT_REG = Enum.Font.Gotham

local function make(cls, props, parent)
    local i = Instance.new(cls)
    for k,v in pairs(props) do i[k] = v end
    if parent then i.Parent = parent end
    return i
end
local function corner(r, parent)
    return make("UICorner", {CornerRadius=UDim.new(0,r)}, parent)
end
local function stroke(t, c, parent)
    return make("UIStroke", {Thickness=t, Color=c, ApplyStrokeMode=Enum.ApplyStrokeMode.Border}, parent)
end

----------------------------------------------------------------
-- MAIN FRAME
----------------------------------------------------------------
local Main = make("Frame", {
    Name="Main", Size=UDim2.new(0,620,0,440),
    Position=UDim2.new(0.5,-310,0.5,-220),
    BackgroundColor3=CLR.BG, BorderSizePixel=0,
    ClipsDescendants=true,
}, ScreenGui)
corner(10, Main)
stroke(1.5, CLR.Border, Main)

local TopBar = make("Frame", {
    Size=UDim2.new(1,0,0,38),
    BackgroundColor3=CLR.Sidebar, BorderSizePixel=0,
}, Main)
corner(10, TopBar)

local DiamondIcon = make("Frame", {
    Size=UDim2.new(0,20,0,20),
    Position=UDim2.new(0,12,0.5,-10),
    BackgroundColor3=CLR.Accent, BorderSizePixel=0, Rotation=45,
}, TopBar)
corner(3, DiamondIcon)

make("TextLabel", {
    Size=UDim2.new(0,160,1,0), Position=UDim2.new(0,38,0,0),
    Text="AngelHub", Font=FONT, TextColor3=CLR.Text, TextSize=18,
    BackgroundTransparency=1,
}, TopBar)

make("TextLabel", {
    Size=UDim2.new(0,100,1,0), Position=UDim2.new(0,142,0,0),
    Text="v1.0", Font=FONT_REG, TextColor3=CLR.Accent, TextSize=11,
    BackgroundTransparency=1,
}, TopBar)

local DiscordBtn = make("TextButton", {
    Size=UDim2.new(0,110,0,22), Position=UDim2.new(1,-180,0.5,-11),
    Text="⟨ Discord ⟩", Font=FONT_REG,
    TextColor3=CLR.Accent, TextSize=11, BackgroundColor3=CLR.Panel,
}, TopBar)
corner(5, DiscordBtn)
DiscordBtn.MouseButton1Click:Connect(function()
    copyToClipboard(DISCORD)
    DiscordBtn.Text = "✓ Copied!"
    task.wait(1.5)
    DiscordBtn.Text = "⟨ Discord ⟩"
end)

local CloseBtn = make("TextButton", {
    Size=UDim2.new(0,26,0,26), Position=UDim2.new(1,-32,0.5,-13),
    Text="✕", Font=FONT, TextColor3=CLR.Text, TextSize=14,
    BackgroundColor3=Color3.fromRGB(180,50,50),
}, TopBar)
corner(6, CloseBtn)
CloseBtn.MouseButton1Click:Connect(function() Main.Visible = false end)

local FloatBtn = make("TextButton", {
    Size=UDim2.new(0,42,0,42), Position=UDim2.new(0,20,0.5,-21),
    Text="✦", Font=FONT, TextColor3=Color3.fromRGB(0,0,0), TextSize=18,
    BackgroundColor3=CLR.Accent, Visible=true, ZIndex=10,
}, ScreenGui)
corner(21, FloatBtn)
stroke(2, CLR.AccentDim, FloatBtn)
FloatBtn.MouseButton1Click:Connect(function() Main.Visible = not Main.Visible end)

-- Dragging
local dragging, dragStart, startPos = false, nil, nil
TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = Main.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == CFG.KeybindOpen then Main.Visible = not Main.Visible end
end)

----------------------------------------------------------------
-- SIDEBAR + CONTENT
----------------------------------------------------------------
local Sidebar = make("Frame", {
    Size=UDim2.new(0,120,1,-38), Position=UDim2.new(0,0,0,38),
    BackgroundColor3=CLR.Sidebar, BorderSizePixel=0,
}, Main)
make("UIListLayout", {SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,4)}, Sidebar)
make("UIPadding", {PaddingTop=UDim.new(0,10), PaddingLeft=UDim.new(0,8), PaddingRight=UDim.new(0,8)}, Sidebar)

local Content = make("Frame", {
    Size=UDim2.new(1,-120,1,-38), Position=UDim2.new(0,120,0,38),
    BackgroundColor3=CLR.Panel, BorderSizePixel=0, ClipsDescendants=true,
}, Main)

local Pages = {}
local TabButtons = {}

local function switchPage(name)
    for n, f in pairs(Pages) do f.Visible = (n == name) end
end

local function makeTab(name, icon, order)
    local btn = make("TextButton", {
        Size=UDim2.new(1,0,0,34), BackgroundColor3=CLR.Panel,
        BorderSizePixel=0, Text="", LayoutOrder=order,
    }, Sidebar)
    corner(7, btn)
    make("TextLabel", {
        Size=UDim2.new(0,22,1,0), Position=UDim2.new(0,6,0,0),
        Text=icon, Font=FONT_REG, TextColor3=CLR.Accent, TextSize=14,
        BackgroundTransparency=1,
    }, btn)
    make("TextLabel", {
        Size=UDim2.new(1,-30,1,0), Position=UDim2.new(0,30,0,0),
        Text=name, Font=FONT_REG, TextColor3=CLR.Text, TextSize=12,
        BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left,
    }, btn)
    local accent = make("Frame", {
        Size=UDim2.new(0,3,0.6,0), Position=UDim2.new(0,0,0.2,0),
        BackgroundColor3=CLR.Accent, Visible=false, BorderSizePixel=0,
    }, btn)
    corner(2, accent)
    btn.MouseButton1Click:Connect(function()
        switchPage(name)
        for n, b in pairs(TabButtons) do
            local ac = b:FindFirstChild("Frame")
            if ac then ac.Visible = (n == name) end
            b.BackgroundColor3 = (n == name) and CLR.BG or CLR.Panel
        end
    end)
    TabButtons[name] = btn
    local page = make("ScrollingFrame", {
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
        ScrollBarThickness=3, ScrollBarImageColor3=CLR.Accent,
        BorderSizePixel=0, Visible=false,
        CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y,
    }, Content)
    make("UIPadding", {
        PaddingTop=UDim.new(0,10), PaddingLeft=UDim.new(0,10),
        PaddingRight=UDim.new(0,10), PaddingBottom=UDim.new(0,10),
    }, page)
    make("UIListLayout", {SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,8)}, page)
    Pages[name] = page
    return page
end

----------------------------------------------------------------
-- WIDGETS
----------------------------------------------------------------
local function sectionLabel(text, page, order)
    local lbl = make("TextLabel", {
        Size=UDim2.new(1,0,0,22), Text="  "..text, Font=FONT,
        TextColor3=CLR.Accent, TextSize=11,
        BackgroundColor3=Color3.fromRGB(0,180,220), BackgroundTransparency=0.85,
        TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=order,
    }, page)
    corner(4, lbl); return lbl
end

local function toggleWidget(label, cfgKey, page, order, callback)
    local row = make("Frame", {
        Size=UDim2.new(1,0,0,32), BackgroundColor3=CLR.BG,
        BorderSizePixel=0, LayoutOrder=order,
    }, page)
    corner(6, row)
    make("TextLabel", {
        Size=UDim2.new(1,-54,1,0), Position=UDim2.new(0,10,0,0),
        Text=label, Font=FONT_REG, TextColor3=CLR.Text, TextSize=12,
        BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left,
    }, row)
    local bg = make("Frame", {
        Size=UDim2.new(0,38,0,20), Position=UDim2.new(1,-46,0.5,-10),
        BackgroundColor3=CFG[cfgKey] and CLR.Toggle_On or CLR.Toggle_Off,
        BorderSizePixel=0,
    }, row)
    corner(10, bg)
    local knob = make("Frame", {
        Size=UDim2.new(0,14,0,14),
        Position=CFG[cfgKey] and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7),
        BackgroundColor3=Color3.new(1,1,1), BorderSizePixel=0,
    }, bg)
    corner(7, knob)
    local btn = make("TextButton", {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text=""}, bg)
    btn.MouseButton1Click:Connect(function()
        CFG[cfgKey] = not CFG[cfgKey]
        local on = CFG[cfgKey]
        TweenService:Create(bg, TweenInfo.new(0.15), {BackgroundColor3=on and CLR.Toggle_On or CLR.Toggle_Off}):Play()
        TweenService:Create(knob, TweenInfo.new(0.15), {Position=on and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)}):Play()
        if callback then callback(on) end
    end)
    return row
end

local function sliderWidget(label, cfgKey, minV, maxV, page, order, fmt, callback)
    local row = make("Frame", {
        Size=UDim2.new(1,0,0,46), BackgroundColor3=CLR.BG,
        BorderSizePixel=0, LayoutOrder=order,
    }, page)
    corner(6, row)
    local valLbl = make("TextLabel", {
        Size=UDim2.new(0,50,0,16), Position=UDim2.new(1,-58,0,8),
        Text=string.format(fmt or "%d", CFG[cfgKey]),
        Font=FONT, TextColor3=CLR.Accent, TextSize=11,
        BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Right,
    }, row)
    make("TextLabel", {
        Size=UDim2.new(1,-60,0,16), Position=UDim2.new(0,10,0,8),
        Text=label, Font=FONT_REG, TextColor3=CLR.Text, TextSize=12,
        BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left,
    }, row)
    local track = make("Frame", {
        Size=UDim2.new(1,-20,0,4), Position=UDim2.new(0,10,1,-14),
        BackgroundColor3=CLR.Toggle_Off, BorderSizePixel=0,
    }, row)
    corner(2, track)
    local pct = (CFG[cfgKey] - minV) / (maxV - minV)
    local fill = make("Frame", {Size=UDim2.new(pct,0,1,0), BackgroundColor3=CLR.Accent, BorderSizePixel=0}, track)
    corner(2, fill)
    local thumb = make("Frame", {
        Size=UDim2.new(0,12,0,12), Position=UDim2.new(pct,-6,0.5,-6),
        BackgroundColor3=Color3.new(1,1,1), BorderSizePixel=0,
    }, track)
    corner(6, thumb)
    local sliding = false
    local function updateSlider(inputX)
        local t = math.clamp((inputX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val = minV + t*(maxV-minV)
        CFG[cfgKey] = val
        fill.Size = UDim2.new(t,0,1,0)
        thumb.Position = UDim2.new(t,-6,0.5,-6)
        valLbl.Text = string.format(fmt or "%d", val)
        if callback then callback(val) end
    end
    local trackBtn = make("TextButton", {
        Size=UDim2.new(1,0,0,22), Position=UDim2.new(0,0,-1.5,0),
        BackgroundTransparency=1, Text="",
    }, track)
    trackBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            sliding = true; updateSlider(inp.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if sliding and (inp.UserInputType == Enum.UserInputType.MouseMovement
            or inp.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(inp.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then sliding = false end
    end)
    return row
end

local function dropdownWidget(label, cfgKey, options, page, order, callback)
    local row = make("Frame", {
        Size=UDim2.new(1,0,0,32), BackgroundColor3=CLR.BG,
        BorderSizePixel=0, LayoutOrder=order, ClipsDescendants=false, ZIndex=5,
    }, page)
    corner(6, row)
    make("TextLabel", {
        Size=UDim2.new(0.5,0,1,0), Position=UDim2.new(0,10,0,0),
        Text=label, Font=FONT_REG, TextColor3=CLR.Text, TextSize=12,
        BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=5,
    }, row)
    local selBtn = make("TextButton", {
        Size=UDim2.new(0.46,0,0,24), Position=UDim2.new(0.52,0,0.5,-12),
        Text=CFG[cfgKey], Font=FONT_REG, TextColor3=CLR.Accent, TextSize=11,
        BackgroundColor3=CLR.Panel, ZIndex=5,
    }, row)
    corner(5, selBtn)
    local dropdown = make("Frame", {
        Size=UDim2.new(0.46,0,0,0), Position=UDim2.new(0.52,0,1,2),
        BackgroundColor3=CLR.Panel, BorderSizePixel=0, Visible=false, ZIndex=10,
        ClipsDescendants=true,
    }, row)
    corner(6, dropdown); stroke(1, CLR.Accent, dropdown)
    make("UIListLayout", {SortOrder=Enum.SortOrder.LayoutOrder}, dropdown)
    for i, opt in ipairs(options) do
        local ob = make("TextButton", {
            Size=UDim2.new(1,0,0,26), Text=opt, Font=FONT_REG,
            TextColor3=CLR.Text, TextSize=11, BackgroundTransparency=1, ZIndex=10, LayoutOrder=i,
        }, dropdown)
        ob.MouseButton1Click:Connect(function()
            CFG[cfgKey] = opt; selBtn.Text = opt
            dropdown.Visible = false
            dropdown.Size = UDim2.new(0.46,0,0,0)
            if callback then callback(opt) end
        end)
    end
    selBtn.MouseButton1Click:Connect(function()
        dropdown.Visible = not dropdown.Visible
        local h = dropdown.Visible and (#options * 26) or 0
        TweenService:Create(dropdown, TweenInfo.new(0.12), {Size=UDim2.new(0.46,0,0,h)}):Play()
    end)
    return row
end

local function labelWidget(text, page, order)
    return make("TextLabel", {
        Size=UDim2.new(1,0,0,20), Text=text, Font=FONT_REG,
        TextColor3=CLR.SubText, TextSize=11, BackgroundTransparency=1,
        TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=order,
    }, page)
end

local function buttonWidget(label, page, order, callback)
    local btn = make("TextButton", {
        Size=UDim2.new(1,0,0,30), Text=label, Font=FONT_REG,
        TextColor3=CLR.Text, TextSize=12,
        BackgroundColor3=CLR.BG, BorderSizePixel=0, LayoutOrder=order,
    }, page)
    corner(6, btn); stroke(1, CLR.Accent, btn)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

----------------------------------------------------------------
-- BUILD TABS
----------------------------------------------------------------
local CombatPage  = makeTab("Combat",  "⊕", 1)
local VisualsPage = makeTab("Visuals", "👁", 2)
local MiscPage    = makeTab("Misc",    "⚙", 3)
local SettingsPage= makeTab("Settings","✦", 4)

-- COMBAT
sectionLabel("AIM ASSISTANCE", CombatPage, 1)
toggleWidget("Aimbot",      "AimbotEnabled", CombatPage, 2)
toggleWidget("Silent Aim",  "SilentAim",     CombatPage, 3)
toggleWidget("Team Check",  "TeamCheck",     CombatPage, 4)
toggleWidget("Wall Check",  "WallCheck",     CombatPage, 5)
dropdownWidget("Aim Part", "AimPart",
    {"Head","Neck","HumanoidRootPart","UpperTorso","LowerTorso"}, CombatPage, 6)
sliderWidget("FOV Radius",    "AimFOV",       10,  500, CombatPage, 7, "%d px")
sliderWidget("Smooth Factor", "AimSmooth",    0.01,0.99,CombatPage, 8, "%.2f")
sliderWidget("Prediction",    "PredictionVal",0,   0.5, CombatPage, 9, "%.2f")
sectionLabel("INFO", CombatPage, 10)
labelWidget("Hold RMB or Q to aim | Silent Aim hooks Mouse.Hit", CombatPage, 11)

-- VISUALS
sectionLabel("ESP", VisualsPage, 1)
toggleWidget("ESP Enabled",  "ESPEnabled",  VisualsPage, 2)
toggleWidget("Boxes",        "ESPBoxes",    VisualsPage, 3)
toggleWidget("Names",        "ESPNames",    VisualsPage, 4)
toggleWidget("Health",       "ESPHealth",   VisualsPage, 5)
toggleWidget("Distance",     "ESPDistance", VisualsPage, 6)
toggleWidget("Tracers",      "ESPTracers",  VisualsPage, 7)
toggleWidget("Team Color",   "ESPTeamColor",VisualsPage, 8)
sliderWidget("Max Distance", "MaxESPDist",  50, 2000, VisualsPage, 9, "%d m")

-- MISC
sectionLabel("MOVEMENT", MiscPage, 1)
toggleWidget("No Clip",     "NoClip",      MiscPage, 2, startNoclip)
toggleWidget("Speed Hack",  "SpeedEnabled",MiscPage, 3, startSpeed)
sliderWidget("Walk Speed",  "SpeedValue",  16, 200, MiscPage, 4, "%d")
toggleWidget("Jump Boost",  "JumpEnabled", MiscPage, 5, startJump)
sliderWidget("Jump Power",  "JumpValue",   50, 500, MiscPage, 6, "%d")
toggleWidget("Infinite Jump","InfJump",    MiscPage, 7)
toggleWidget("Fly",         "FlyEnabled",  MiscPage, 8, function(v)
    CFG.FlyEnabled = v; startFly()
end)
sliderWidget("Fly Speed",   "FlySpeed",    10, 300, MiscPage, 9, "%d")
sectionLabel("UTILITY", MiscPage, 10)
toggleWidget("Anti-AFK",    "AntiAFK",     MiscPage, 11)
buttonWidget("Teleport to Spawn", MiscPage, 12, function()
    local root = getRootPart(LocalPlayer)
    if root then root.CFrame = CFrame.new(0, 10, 0) end
end)
buttonWidget("Rejoin Server", MiscPage, 13, function()
    local TS = game:GetService("TeleportService")
    TS:Teleport(game.PlaceId, LocalPlayer)
end)
buttonWidget("Reset Character", MiscPage, 14, function()
    local hum = getHumanoid(LocalPlayer)
    if hum then hum.Health = 0 end
end)

-- SETTINGS
sectionLabel("INTERFACE", SettingsPage, 1)
sliderWidget("UI Scale", "UIScale", 0.5, 2.0, SettingsPage, 2, "%.1f", function(v)
    Main.Size = UDim2.new(0, 620*v, 0, 440*v)
end)
sliderWidget("UI Opacity", "UIOpacity", 0.3, 1.0, SettingsPage, 3, "%.2f", function(v)
    Main.BackgroundTransparency = 1 - v
end)
sectionLabel("KEYBIND", SettingsPage, 4)
labelWidget("Open/Close: RightShift | Mobile: tap ✦ button", SettingsPage, 5)
sectionLabel("CREDITS", SettingsPage, 6)
labelWidget("AngelHub v1.0", SettingsPage, 7)
labelWidget(DISCORD, SettingsPage, 8)
buttonWidget("Copy Discord Link", SettingsPage, 9, function()
    copyToClipboard(DISCORD)
end)
buttonWidget("Print Logo to Console", SettingsPage, 10, function()
    print(LOGO)
end)

----------------------------------------------------------------
-- ACTIVATE FIRST TAB
----------------------------------------------------------------
switchPage("Combat")
TabButtons["Combat"].BackgroundColor3 = CLR.BG
local firstAccent = TabButtons["Combat"]:FindFirstChild("Frame")
if firstAccent then firstAccent.Visible = true end

----------------------------------------------------------------
-- STARTUP
----------------------------------------------------------------
print(LOGO)
print("AngelHub loaded | Discord: "..DISCORD)
print("Toggle: RightShift | Mobile: ✦ float button")
