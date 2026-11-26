--[[
    AngelHub V2.0 - Roblox Studio game UI + player training assist
    Install as a LocalScript in StarterPlayer > StarterPlayerScripts.
    Intended ONLY for your own Roblox experience. This is not an executor script.

    Features:
      Aimbot tab: in-game camera training assist for players, smoothness, FOV,
                  target part, team check, max range, toggle key.
      Visuals tab: player highlights, name/distance labels, health bars.
      World tab: FOV ring, crosshair, target marker, screen dim toggle.
      Settings tab: accent themes, UI scale, FPS/ping widget, draggable window.
      Misc tab: Discord invite + copy button, reset UI, hide/show.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local GuiService = game:GetService("GuiService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

local DISCORD_INVITE = "https://discord.gg/d8gpXNGknP"

local Config = {
    AimEnabled = false,
    Smoothness = 45,
    FOV = 140,
    TargetPart = "Head",
    TeamCheck = true,
    MaxDistance = 2500,
    AimKey = Enum.KeyCode.Q,

    ESPEnabled = false,
    ShowNames = true,
    ShowDistance = true,
    ShowHealth = true,
    HighlightFill = true,
    HighlightOutline = true,

    DrawFOV = true,
    Crosshair = false,
    TargetMarker = true,
    ScreenDim = false,

    AccentName = "Cyan",
    UIScale = 1,
    ShowStats = true,
}

local Themes = {
    Cyan = Color3.fromRGB(83, 222, 255),
    Blue = Color3.fromRGB(65, 135, 255),
    Purple = Color3.fromRGB(174, 112, 255),
    Green = Color3.fromRGB(83, 230, 167),
    Red = Color3.fromRGB(255, 105, 120),
    Pink = Color3.fromRGB(255, 115, 190),
    White = Color3.fromRGB(225, 240, 250),
}
local function accent()
    return Themes[Config.AccentName] or Themes.Cyan
end

local old = PlayerGui:FindFirstChild("AngelHubV2")
if old then old:Destroy() end

local Gui = Instance.new("ScreenGui")
Gui.Name = "AngelHubV2"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = PlayerGui

local function corner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = obj
    return c
end

local function stroke(obj, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or accent()
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0.15
    s.Parent = obj
    return s
end

local function make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do obj[k] = v end
    obj.Parent = parent
    return obj
end

local Main = make("Frame", {
    Name = "Main",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(760, 535),
    BackgroundColor3 = Color3.fromRGB(13, 20, 31),
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, Gui)
corner(Main, 13)
local MainStroke = stroke(Main, accent(), 2, 0.08)

local Scale = make("UIScale", {Scale = Config.UIScale}, Main)

local Top = make("Frame", {
    Name = "Top",
    Size = UDim2.new(1, 0, 0, 100),
    BackgroundColor3 = Color3.fromRGB(19, 31, 46),
    BorderSizePixel = 0,
}, Main)
corner(Top, 12)

local Logo = make("Frame", {
    Position = UDim2.fromOffset(17, 17),
    Size = UDim2.fromOffset(64, 64),
    BackgroundColor3 = Color3.fromRGB(30, 53, 72),
    BorderSizePixel = 0,
}, Top)
corner(Logo, 13)
stroke(Logo, accent(), 1.5, 0.1)
make("TextLabel", {
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1),
    Text = "AH",
    TextColor3 = accent(),
    Font = Enum.Font.GothamBlack,
    TextSize = 24,
}, Logo)

local Title = make("TextLabel", {
    Position = UDim2.fromOffset(96, 14),
    Size = UDim2.new(1, -230, 0, 52),
    BackgroundTransparency = 1,
    Text = "AngelHub | V2.0",
    TextColor3 = accent(),
    Font = Enum.Font.GothamBold,
    TextSize = 31,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Top)
local Subtitle = make("TextLabel", {
    Position = UDim2.fromOffset(99, 63),
    Size = UDim2.new(1, -230, 0, 22),
    BackgroundTransparency = 1,
    Text = "PLAYER TRAINING  •  VISUAL CONTROL CENTER",
    TextColor3 = Color3.fromRGB(125, 159, 180),
    Font = Enum.Font.GothamMedium,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Top)

local Minimize = make("TextButton", {
    Position = UDim2.new(1, -91, 0, 18),
    Size = UDim2.fromOffset(30, 28),
    BackgroundColor3 = Color3.fromRGB(34, 52, 69),
    Text = "–",
    TextColor3 = Color3.fromRGB(185, 220, 235),
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    BorderSizePixel = 0,
}, Top)
corner(Minimize, 6)

local Close = make("TextButton", {
    Position = UDim2.new(1, -52, 0, 18),
    Size = UDim2.fromOffset(30, 28),
    BackgroundColor3 = Color3.fromRGB(34, 52, 69),
    Text = "×",
    TextColor3 = Color3.fromRGB(185, 220, 235),
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    BorderSizePixel = 0,
}, Top)
corner(Close, 6)

local Sidebar = make("Frame", {
    Position = UDim2.fromOffset(13, 112),
    Size = UDim2.new(0, 172, 1, -125),
    BackgroundColor3 = Color3.fromRGB(18, 29, 43),
    BorderSizePixel = 0,
}, Main)
corner(Sidebar, 9)

local Content = make("Frame", {
    Position = UDim2.fromOffset(197, 112),
    Size = UDim2.new(1, -210, 1, -125),
    BackgroundColor3 = Color3.fromRGB(17, 27, 41),
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, Main)
corner(Content, 9)

local Page = make("ScrollingFrame", {
    Position = UDim2.fromOffset(0, 0),
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = accent(),
    CanvasSize = UDim2.fromOffset(0, 0),
}, Content)
local PageLayout = make("UIListLayout", {
    Padding = UDim.new(0, 9),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, Page)
make("UIPadding", {
    PaddingTop = UDim.new(0, 13),
    PaddingBottom = UDim.new(0, 16),
    PaddingLeft = UDim.new(0, 14),
    PaddingRight = UDim.new(0, 14),
}, Page)

PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Page.CanvasSize = UDim2.fromOffset(0, PageLayout.AbsoluteContentSize.Y + 30)
end)

local pages = {}
local activeTab = "Aimbot"
local function clearPage()
    for _, child in ipairs(Page:GetChildren()) do
        if child ~= PageLayout and not child:IsA("UIPadding") then child:Destroy() end
    end
end

local function section(text)
    local wrap = make("Frame", {
        Size = UDim2.new(1, 0, 0, 27),
        BackgroundTransparency = 1,
    }, Page)
    make("Frame", {
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(0.17, 0, 0, 1),
        BackgroundColor3 = Color3.fromRGB(58, 93, 115),
        BorderSizePixel = 0,
    }, wrap)
    make("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(0.64, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = accent(),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
    }, wrap)
    make("Frame", {
        Position = UDim2.new(0.83, 0, 0.5, 0),
        Size = UDim2.new(0.17, 0, 0, 1),
        BackgroundColor3 = Color3.fromRGB(58, 93, 115),
        BorderSizePixel = 0,
    }, wrap)
end

local function rowBase(height)
    return make("Frame", {
        Size = UDim2.new(1, 0, 0, height or 43),
        BackgroundColor3 = Color3.fromRGB(24, 38, 54),
        BorderSizePixel = 0,
    }, Page)
end

local function addLabel(text, desc)
    local f = rowBase(desc and 54 or 40)
    make("TextLabel", {
        Position = UDim2.fromOffset(12, desc and 6 or 0),
        Size = UDim2.new(1, -24, 0, 24),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Color3.fromRGB(225, 237, 245),
        Font = Enum.Font.GothamMedium,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, f)
    if desc then
        make("TextLabel", {
            Position = UDim2.fromOffset(12, 29),
            Size = UDim2.new(1, -24, 0, 18),
            BackgroundTransparency = 1,
            Text = desc,
            TextColor3 = Color3.fromRGB(128, 159, 177),
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, f)
    end
end

local function addToggle(text, key, description)
    local f = rowBase(description and 54 or 43)
    make("TextLabel", {
        Position = UDim2.fromOffset(12, description and 4 or 0),
        Size = UDim2.new(1, -105, 0, 25),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Color3.fromRGB(225, 237, 245),
        Font = Enum.Font.GothamMedium,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, f)
    if description then
        make("TextLabel", {
            Position = UDim2.fromOffset(12, 28),
            Size = UDim2.new(1, -105, 0, 17),
            BackgroundTransparency = 1,
            Text = description,
            TextColor3 = Color3.fromRGB(128, 159, 177),
            Font = Enum.Font.Gotham,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, f)
    end
    local b = make("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -11, 0.5, 0),
        Size = UDim2.fromOffset(54, 27),
        BackgroundColor3 = Config[key] and accent() or Color3.fromRGB(47, 60, 75),
        Text = Config[key] and "ON" or "OFF",
        TextColor3 = Color3.fromRGB(245, 250, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        BorderSizePixel = 0,
    }, f)
    corner(b, 14)
    b.MouseButton1Click:Connect(function()
        Config[key] = not Config[key]
        b.Text = Config[key] and "ON" or "OFF"
        b.BackgroundColor3 = Config[key] and accent() or Color3.fromRGB(47, 60, 75)
    end)
end

local function addSlider(text, key, minValue, maxValue, suffix)
    local f = rowBase(65)
    local valLabel = make("TextLabel", {
        Position = UDim2.fromOffset(12, 5),
        Size = UDim2.new(1, -24, 0, 22),
        BackgroundTransparency = 1,
        Text = text .. "  " .. tostring(Config[key]) .. (suffix or ""),
        TextColor3 = Color3.fromRGB(225, 237, 245),
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, f)
    local bar = make("TextButton", {
        Position = UDim2.fromOffset(12, 39),
        Size = UDim2.new(1, -24, 0, 9),
        BackgroundColor3 = Color3.fromRGB(47, 62, 78),
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0,
    }, f)
    corner(bar, 8)
    local fill = make("Frame", {
        Size = UDim2.new((Config[key] - minValue) / (maxValue - minValue), 0, 1, 0),
        BackgroundColor3 = accent(),
        BorderSizePixel = 0,
    }, bar)
    corner(fill, 8)
    local knob = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new((Config[key] - minValue) / (maxValue - minValue), 0, 0.5, 0),
        Size = UDim2.fromOffset(15, 15),
        BackgroundColor3 = Color3.fromRGB(235, 248, 255),
        BorderSizePixel = 0,
    }, bar)
    corner(knob, 10)
    local dragging = false
    local function update(x)
        local p = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local v = math.floor(minValue + p * (maxValue - minValue) + 0.5)
        Config[key] = v
        fill.Size = UDim2.new(p, 0, 1, 0)
        knob.Position = UDim2.new(p, 0, 0.5, 0)
        valLabel.Text = text .. "  " .. tostring(v) .. (suffix or "")
        if key == "UIScale" then
            Scale.Scale = v / 100
        end
    end
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local function addDropdown(text, key, options)
    local f = rowBase(45)
    make("TextLabel", {
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -165, 1, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Color3.fromRGB(225, 237, 245),
        Font = Enum.Font.GothamMedium,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, f)
    local b = make("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(142, 30),
        BackgroundColor3 = Color3.fromRGB(34, 53, 72),
        Text = tostring(Config[key]) .. "  ▾",
        TextColor3 = accent(),
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        BorderSizePixel = 0,
    }, f)
    corner(b, 6)
    local index = table.find(options, Config[key]) or 1
    b.MouseButton1Click:Connect(function()
        index = index % #options + 1
        Config[key] = options[index]
        b.Text = tostring(Config[key]) .. "  ▾"
    end)
end

local function addAction(text, callback, secondary)
    local f = rowBase(45)
    local b = make("TextButton", {
        Position = UDim2.fromOffset(10, 6),
        Size = UDim2.new(1, -20, 1, -12),
        BackgroundColor3 = secondary and Color3.fromRGB(36, 57, 77) or Color3.fromRGB(35, 105, 132),
        Text = text,
        TextColor3 = Color3.fromRGB(235, 249, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        BorderSizePixel = 0,
    }, f)
    corner(b, 6)
    b.MouseButton1Click:Connect(callback)
end

local function buildPage(tab)
    activeTab = tab
    clearPage()
    if tab == "Aimbot" then
        section("AIM ASSIST")
        addToggle("Enabled", "AimEnabled", "Camera training assist for players in this experience")
        addSlider("Aimbot Smoothness", "Smoothness", 0, 100, "%")
        addSlider("FOV Radius", "FOV", 20, 500, " px")
        addDropdown("Target Bone", "TargetPart", {"Head", "UpperTorso", "HumanoidRootPart"})
        addToggle("Team Check", "TeamCheck", "Ignore players on your team")
        addSlider("Maximum Distance", "MaxDistance", 100, 5000, " studs")
        addLabel("Default lock key: Q", "Aim only selects visible players inside the FOV circle.")
    elseif tab == "Visuals" then
        section("PLAYER ESP")
        addToggle("Player ESP", "ESPEnabled", "Show visual information for other players")
        addToggle("Player Names", "ShowNames")
        addToggle("Distance Labels", "ShowDistance")
        addToggle("Health Bars", "ShowHealth")
        addToggle("Highlight Fill", "HighlightFill")
        addToggle("Highlight Outline", "HighlightOutline")
        addLabel("ESP is client-side UI for your own game.", "For competitive games, consider limiting visibility by game rules.")
    elseif tab == "World" then
        section("SCREEN OVERLAYS")
        addToggle("Draw FOV Circle", "DrawFOV")
        addToggle("Center Crosshair", "Crosshair")
        addToggle("Target Marker", "TargetMarker")
        addToggle("Screen Dim", "ScreenDim", "Subtle dark overlay behind the game view")
    elseif tab == "Settings" then
        section("INTERFACE CUSTOMIZATION")
        addDropdown("Accent Color", "AccentName", {"Cyan", "Blue", "Purple", "Green", "Red", "Pink", "White"})
        addSlider("UI Scale", "UIScale", 70, 120, "%")
        addToggle("AngelHub: FPS + Ping", "ShowStats", "Show live performance in the top-right corner")
        addAction("Apply Accent Color", function()
            local c = accent()
            MainStroke.Color = c
            Title.TextColor3 = c
            Logo:FindFirstChildOfClass("UIStroke").Color = c
            Page.ScrollBarImageColor3 = c
            fovStroke.Color = c
            crosshairStroke.Color = c
            targetDot.BackgroundColor3 = c
            for _, obj in ipairs(Gui:GetDescendants()) do
                if obj:IsA("Frame") and obj.Name == "AccentFill" then obj.BackgroundColor3 = c end
            end
        end)
        addLabel("Drag the top bar to move the window.", "RightShift toggles the menu. The menu also has a mobile open button.")
    elseif tab == "Misc" then
        section("COMMUNITY")
        addLabel("AngelHub Discord", DISCORD_INVITE)
        addAction("Copy Discord Invite", function()
            local ok = pcall(function()
                if typeof(setclipboard) == "function" then
                    setclipboard(DISCORD_INVITE)
                else
                    GuiService:OpenBrowserWindow(DISCORD_INVITE)
                end
            end)
            if not ok then
                pcall(function() GuiService:OpenBrowserWindow(DISCORD_INVITE) end)
            end
        end)
        section("OTHER")
        addAction("Reset UI Position", function()
            Main.Position = UDim2.fromScale(0.5, 0.5)
        end, true)
        addAction("Hide AngelHub", function()
            Main.Visible = false
            OpenButton.Visible = true
        end, true)
        addLabel("AngelHub V2.0", "Built for your own Roblox Studio experience.")
    end
    for name, b in pairs(pages) do
        b.BackgroundColor3 = name == tab and Color3.fromRGB(40, 103, 132) or Color3.fromRGB(25, 41, 58)
        b.TextColor3 = name == tab and Color3.fromRGB(240, 251, 255) or Color3.fromRGB(158, 193, 211)
    end
end

local tabs = {
    {"Aimbot", "◉"},
    {"Visuals", "◇"},
    {"World", "◎"},
    {"Settings", "⚙"},
    {"Misc", "✣"},
}
for i, info in ipairs(tabs) do
    local name, symbol = info[1], info[2]
    local b = make("TextButton", {
        Position = UDim2.fromOffset(8, 12 + (i - 1) * 55),
        Size = UDim2.new(1, -16, 0, 46),
        BackgroundColor3 = Color3.fromRGB(25, 41, 58),
        Text = symbol .. "   " .. name,
        TextColor3 = Color3.fromRGB(158, 193, 211),
        Font = Enum.Font.GothamMedium,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        BorderSizePixel = 0,
    }, Sidebar)
    corner(b, 7)
    make("UIPadding", {PaddingLeft = UDim.new(0, 12)}, b)
    pages[name] = b
    b.MouseButton1Click:Connect(function() buildPage(name) end)
end

-- HUD widgets
local StatsLabel = make("TextLabel", {
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -14, 0, 12),
    Size = UDim2.fromOffset(190, 28),
    BackgroundColor3 = Color3.fromRGB(12, 22, 34),
    BackgroundTransparency = 0.12,
    Text = "AngelHub: -- FPS | -- ms",
    TextColor3 = accent(),
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    Visible = Config.ShowStats,
    BorderSizePixel = 0,
}, Gui)
corner(StatsLabel, 7)
stroke(StatsLabel, accent(), 1, 0.35)

local OpenButton = make("TextButton", {
    Position = UDim2.new(0, 14, 0.5, 0),
    Size = UDim2.fromOffset(112, 42),
    BackgroundColor3 = Color3.fromRGB(22, 74, 99),
    Text = "AngelHub",
    TextColor3 = Color3.fromRGB(235, 250, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    Visible = false,
    BorderSizePixel = 0,
}, Gui)
corner(OpenButton, 8)
stroke(OpenButton, accent(), 1, 0.15)
OpenButton.MouseButton1Click:Connect(function()
    Main.Visible = true
    OpenButton.Visible = false
end)

-- FOV ring and other overlays
local FOVRing = make("Frame", {
    Name = "FOVRing",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(Config.FOV * 2, Config.FOV * 2),
    BackgroundTransparency = 1,
    Visible = Config.DrawFOV,
}, Gui)
corner(FOVRing, 500)
local fovStroke = stroke(FOVRing, accent(), 1.5, 0.2)

local Crosshair = make("TextLabel", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(30, 30),
    BackgroundTransparency = 1,
    Text = "+",
    TextColor3 = accent(),
    TextSize = 26,
    Font = Enum.Font.GothamBold,
    Visible = Config.Crosshair,
}, Gui)
local crosshairStroke = {Color = accent()}

local targetDot = make("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Size = UDim2.fromOffset(9, 9),
    BackgroundColor3 = accent(),
    BorderSizePixel = 0,
    Visible = false,
}, Gui)
corner(targetDot, 10)

local Dim = make("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.new(0, 0, 0),
    BackgroundTransparency = 0.82,
    Visible = false,
    ZIndex = 0,
}, Gui)

-- Dragging support (mouse and touch)
local dragging, dragStart, startPosition
Top.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = Main.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

Minimize.MouseButton1Click:Connect(function()
    Main.Visible = false
    OpenButton.Visible = true
end)
Close.MouseButton1Click:Connect(function()
    Main.Visible = false
    OpenButton.Visible = true
end)

-- ESP objects are attached to each character locally.
local esp = {}
local function removeESP(player)
    local entry = esp[player]
    if entry then
        if entry.Highlight then entry.Highlight:Destroy() end
        if entry.Billboard then entry.Billboard:Destroy() end
        esp[player] = nil
    end
end

local function isTeammate(player)
    return LocalPlayer.Team ~= nil and player.Team == LocalPlayer.Team
end

local function createOrUpdateESP(player)
    if player == LocalPlayer or not Config.ESPEnabled then
        removeESP(player)
        return
    end
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not character or not humanoid or not root or humanoid.Health <= 0 then
        removeESP(player)
        return
    end
    if not esp[player] then esp[player] = {} end
    local entry = esp[player]
    if not entry.Highlight then
        local h = Instance.new("Highlight")
        h.Name = "AngelHubPlayerHighlight"
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = character
        entry.Highlight = h
    end
    entry.Highlight.Adornee = character
    entry.Highlight.FillTransparency = Config.HighlightFill and 0.78 or 1
    entry.Highlight.OutlineTransparency = Config.HighlightOutline and 0 or 1
    entry.Highlight.FillColor = accent()
    entry.Highlight.OutlineColor = accent()

    if not entry.Billboard then
        local bb = Instance.new("BillboardGui")
        bb.Name = "AngelHubPlayerInfo"
        bb.Size = UDim2.fromOffset(170, 48)
        bb.StudsOffset = Vector3.new(0, 3.2, 0)
        bb.AlwaysOnTop = true
        bb.Adornee = root
        local name = make("TextLabel", {
            Name = "Info",
            Size = UDim2.new(1, 0, 0, 22),
            BackgroundTransparency = 1,
            TextColor3 = accent(),
            TextStrokeTransparency = 0.3,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
        }, bb)
        local healthBack = make("Frame", {
            Name = "HealthBack",
            Position = UDim2.fromOffset(30, 25),
            Size = UDim2.fromOffset(110, 6),
            BackgroundColor3 = Color3.fromRGB(35, 42, 52),
            BorderSizePixel = 0,
        }, bb)
        corner(healthBack, 4)
        local healthFill = make("Frame", {
            Name = "HealthFill",
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.fromRGB(83, 225, 150),
            BorderSizePixel = 0,
        }, healthBack)
        corner(healthFill, 4)
        bb.Parent = Gui
        entry.Billboard = bb
    end
    local bb = entry.Billboard
    bb.Adornee = root
    local info = bb:FindFirstChild("Info")
    local healthBack = bb:FindFirstChild("HealthBack")
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local distance = myRoot and math.floor((root.Position - myRoot.Position).Magnitude) or 0
    local parts = {}
    if Config.ShowNames then table.insert(parts, player.DisplayName) end
    if Config.ShowDistance then table.insert(parts, tostring(distance) .. " studs") end
    if info then
        info.Text = table.concat(parts, "  |  ")
        info.Visible = Config.ShowNames or Config.ShowDistance
        info.TextColor3 = accent()
    end
    if healthBack then
        healthBack.Visible = Config.ShowHealth
        local fill = healthBack:FindFirstChild("HealthFill")
        if fill then fill.Size = UDim2.new(math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1), 0, 1, 0) end
    end
end

local function getAimPart(character)
    if not character then return nil end
    return character:FindFirstChild(Config.TargetPart) or character:FindFirstChild("HumanoidRootPart")
end

local function findBestTarget()
    Camera = workspace.CurrentCamera
    local center = Camera.ViewportSize / 2
    local bestPlayer, bestScreenDistance = nil, math.huge
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= LocalPlayer and (not Config.TeamCheck or not isTeammate(other)) then
            local character = other.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local part = getAimPart(character)
            if humanoid and humanoid.Health > 0 and part then
                local distance = myRoot and (part.Position - myRoot.Position).Magnitude or math.huge
                local screen, onScreen = Camera:WorldToViewportPoint(part.Position)
                local screenDistance = (Vector2.new(screen.X, screen.Y) - center).Magnitude
                if onScreen and distance <= Config.MaxDistance and screenDistance <= Config.FOV and screenDistance < bestScreenDistance then
                    bestPlayer = other
                    bestScreenDistance = screenDistance
                end
            end
        end
    end
    return bestPlayer
end

local fpsFrames, fpsTime, currentFPS = 0, 0, 0
local updateAccumulator = 0
RunService.RenderStepped:Connect(function(dt)
    Camera = workspace.CurrentCamera
    fpsFrames += 1
    fpsTime += dt
    if fpsTime >= 0.5 then
        currentFPS = math.floor(fpsFrames / fpsTime + 0.5)
        fpsFrames, fpsTime = 0, 0
    end

    FOVRing.Visible = Config.DrawFOV
    FOVRing.Size = UDim2.fromOffset(Config.FOV * 2, Config.FOV * 2)
    fovStroke.Color = accent()
    Crosshair.Visible = Config.Crosshair
    Crosshair.TextColor3 = accent()
    Dim.Visible = Config.ScreenDim
    StatsLabel.Visible = Config.ShowStats
    if Config.ShowStats then
        local ping = "--"
        pcall(function()
            local network = Stats:FindFirstChild("Network")
            local serverStats = network and network:FindFirstChild("ServerStatsItem")
            local item = serverStats and serverStats:FindFirstChild("Data Ping")
            if item then ping = tostring(math.floor(item:GetValue() + 0.5)) end
        end)
        StatsLabel.Text = "AngelHub: " .. currentFPS .. " FPS | " .. ping .. " ms"
        StatsLabel.TextColor3 = accent()
    end

    updateAccumulator += dt
    if updateAccumulator >= 0.12 then
        updateAccumulator = 0
        for _, other in ipairs(Players:GetPlayers()) do
            createOrUpdateESP(other)
        end
        for other in pairs(esp) do
            if not other.Parent then removeESP(other) end
        end
    end

    if Config.AimEnabled then
        local target = findBestTarget()
        if target and target.Character then
            local part = getAimPart(target.Character)
            if part then
                local goal = CFrame.lookAt(Camera.CFrame.Position, part.Position)
                local responsiveness = 1 - (Config.Smoothness / 100)
                local alpha = math.clamp(responsiveness * dt * 18, 0.01, 1)
                Camera.CFrame = Camera.CFrame:Lerp(goal, alpha)
                local screen, onScreen = Camera:WorldToViewportPoint(part.Position)
                targetDot.Visible = Config.TargetMarker and onScreen
                if onScreen then targetDot.Position = UDim2.fromOffset(screen.X, screen.Y) end
            else
                targetDot.Visible = false
            end
        else
            targetDot.Visible = false
        end
    else
        targetDot.Visible = false
    end
end)

Players.PlayerRemoving:Connect(removeESP)
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if Config.ESPEnabled then createOrUpdateESP(player) end
    end)
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        Main.Visible = not Main.Visible
        OpenButton.Visible = not Main.Visible
    elseif input.KeyCode == Enum.KeyCode.Q then
        Config.AimEnabled = not Config.AimEnabled
    end
end)

-- Apply current theme colors to main UI.
local function refreshAccent()
    local c = accent()
    MainStroke.Color = c
    Title.TextColor3 = c
    Logo:FindFirstChildOfClass("UIStroke").Color = c
    Page.ScrollBarImageColor3 = c
    StatsLabel.TextColor3 = c
    FOVRing:FindFirstChildOfClass("UIStroke").Color = c
    OpenButton:FindFirstChildOfClass("UIStroke").Color = c
    for _, b in pairs(pages) do
        if b.BackgroundColor3 == Color3.fromRGB(40, 103, 132) then b.BackgroundColor3 = c end
    end
end

buildPage("Aimbot")
print("AngelHub V2.0 loaded. Discord: " .. DISCORD_INVITE)
