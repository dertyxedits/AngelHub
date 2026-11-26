-- AngelHub v2.1 -- Universal Mobile Executor Script
-- Discord: https://discord.gg/d8gpXNGknP
-- Executor required (Delta, Fluxus, etc.)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local DiscordLink = "https://discord.gg/d8gpXNGknP"

-- Config
local Config = {
    Combat = { 
        Enabled = false, Smoothness = 45, FOV = 150, Bone = "Head", TeamCheck = true, 
        DrawFOV = true, Key = "Always", WallCheck = false
    },
    Visuals = { 
        Enabled = false, Box = true, Name = true, Health = true, Distance = true, Tracer = false 
    },
    World = { 
        WalkSpeed = 16, JumpPower = 50, Gravity = 196.2, Fullbright = false, NoFog = false 
    },
    Misc = { 
        AntiAFK = false, Fly = false, FlySpeed = 50, Noclip = false, InfJump = false 
    }
}

-- Theme
local Theme = {
    BG = Color3.fromRGB(12, 12, 18),
    TabBG = Color3.fromRGB(20, 20, 28),
    Accent = Color3.fromRGB(0, 220, 255),
    AccentDark = Color3.fromRGB(0, 150, 180),
    Text = Color3.fromRGB(240, 240, 240),
    SubText = Color3.fromRGB(140, 140, 150),
    ToggleOn = Color3.fromRGB(0, 220, 255),
    ToggleOff = Color3.fromRGB(40, 40, 50),
    Stroke = Color3.fromRGB(45, 45, 60)
}

-- Cleanup
if CoreGui:FindFirstChild("AngelHub") then CoreGui.AngelHub:Destroy() end

local function Create(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props) do inst[k] = v end
    return inst
end

-- Main GUI
local ScreenGui = Create("ScreenGui", {Name = "AngelHub", Parent = CoreGui, ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling})
local Main = Create("Frame", {
    Parent = ScreenGui, Size = UDim2.new(0, 580, 0, 420), Position = UDim2.new(0.5, -290, 0.5, -210),
    BackgroundColor3 = Theme.BG, BorderSizePixel = 0, ClipsDescendants = true
})
Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = Main})
local MainStroke = Create("UIStroke", {Color = Theme.Accent, Thickness = 2, Parent = Main})
Create("UIGradient", {Color = ColorSequence.new(Theme.Accent, Theme.AccentDark), Rotation = 45, Parent = MainStroke})

-- Mobile scaling
if Camera.ViewportSize.X < 800 then
    Main.Size = UDim2.new(0, 420, 0, 340)
    Main.Position = UDim2.new(0.5, -210, 0.5, -170)
end

-- Top Bar (Drag)
local Header = Create("Frame", {Parent = Main, Size = UDim2.new(1, 0, 0, 75), BackgroundColor3 = Theme.TabBG, BorderSizePixel = 0})
Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = Header})
Create("Frame", {Parent = Header, Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 1, -20), BackgroundColor3 = Theme.TabBG, BorderSizePixel = 0})

local Title = Create("TextLabel", {
    Parent = Header, Size = UDim2.new(1, -50, 0, 30), Position = UDim2.new(0, 20, 0, 5),
    BackgroundTransparency = 1, Text = "AngelHub | v2.1", TextColor3 = Theme.Accent,
    Font = Enum.Font.GothamBlack, TextSize = 22, TextXAlignment = Enum.TextXAlignment.Left
})
Create("UIGradient", {Color = ColorSequence.new(Theme.Text, Theme.Accent), Parent = Title})

-- Discord Copy Button
local DiscordBtn = Create("TextButton", {
    Parent = Header, Size = UDim2.new(0, 250, 0, 24), Position = UDim2.new(0, 20, 0, 38),
    BackgroundColor3 = Theme.BG, Text = "Discord: " .. DiscordLink, TextColor3 = Theme.SubText,
    Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0
})
Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = DiscordBtn})
Create("UIStroke", {Color = Theme.Stroke, Thickness = 1, Parent = DiscordBtn})

DiscordBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(DiscordLink)
        DiscordBtn.Text = "Copied to clipboard!"
        DiscordBtn.TextColor3 = Theme.Accent
        task.wait(1.5)
        DiscordBtn.Text = "Discord: " .. DiscordLink
        DiscordBtn.TextColor3 = Theme.SubText
    else
        DiscordBtn.Text = "Clipboard not supported"
        task.wait(1.5)
        DiscordBtn.Text = "Discord: " .. DiscordLink
    end
end)

local CloseBtn = Create("TextButton", {
    Parent = Header, Size = UDim2.new(0, 40, 0, 40), Position = UDim2.new(1, -45, 0, 5),
    BackgroundTransparency = 1, Text = "✕", TextColor3 = Theme.SubText, Font = Enum.Font.GothamBold, TextSize = 18
})
CloseBtn.MouseEnter:Connect(function() TweenService:Create(CloseBtn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 50, 50)}):Play() end)
CloseBtn.MouseLeave:Connect(function() TweenService:Create(CloseBtn, TweenInfo.new(0.2), {TextColor3 = Theme.SubText}):Play() end)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Drag Logic (PC & Mobile)
local dragging, dragInput, dragStart, startPos
Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
Header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Sidebar
local Sidebar = Create("Frame", {Parent = Main, Size = UDim2.new(0, 140, 1, -90), Position = UDim2.new(0, 10, 0, 85), BackgroundTransparency = 1})
local TabContainer = Create("Frame", {Parent = Main, Size = UDim2.new(1, -160, 1, -95), Position = UDim2.new(0, 150, 0, 85), BackgroundColor3 = Theme.TabBG, BorderSizePixel = 0})
Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = TabContainer})
Create("UIStroke", {Color = Theme.Stroke, Thickness = 1, Parent = TabContainer})

local Tabs = {}
local ActiveTab = nil

local function CreateTab(name)
    local Btn = Create("TextButton", {
        Parent = Sidebar, Size = UDim2.new(1, 0, 0, 35), BackgroundColor3 = Theme.BG,
        Text = "  " .. name, TextColor3 = Theme.SubText, Font = Enum.Font.GothamMedium, TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = Btn})
    local Stroke = Create("UIStroke", {Color = Theme.Stroke, Thickness = 1, Transparency = 1, Parent = Btn})
    
    local Page = Create("ScrollingFrame", {
        Parent = TabContainer, Size = UDim2.new(1, -20, 1, -20), Position = UDim2.new(0, 10, 0, 10),
        BackgroundTransparency = 1, ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.Accent, Visible = false,
        CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 0
    })
    
    Btn.MouseButton1Click:Connect(function()
        if ActiveTab then
            TweenService:Create(ActiveTab.Btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.BG, TextColor3 = Theme.SubText}):Play()
            TweenService:Create(ActiveTab.Stroke, TweenInfo.new(0.2), {Transparency = 1}):Play()
            ActiveTab.Page.Visible = false
        end
        TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.TabBG, TextColor3 = Theme.Accent}):Play()
        TweenService:Create(Stroke, TweenInfo.new(0.2), {Transparency = 0}):Play()
        Page.Visible = true
        ActiveTab = {Btn = Btn, Page = Page, Stroke = Stroke}
    end)
    
    Create("Frame", {Parent = Sidebar, Size = UDim2.new(1, 0, 0, 5), BackgroundTransparency = 1})
    
    Tabs[name] = {Btn = Btn, Page = Page, Stroke = Stroke}
    return Page
end

-- UI Elements
local function AddToggle(parent, text, default, callback)
    local Frame = Create("Frame", {Parent = parent, Size = UDim2.new(1, 0, 0, 35), BackgroundTransparency = 1})
    Create("TextLabel", {Parent = Frame, Size = UDim2.new(1, -60, 1, 0), BackgroundTransparency = 1, Text = text, TextColor3 = Theme.Text, Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left})
    
    local Toggle = Create("TextButton", {Parent = Frame, Size = UDim2.new(0, 44, 0, 22), Position = UDim2.new(1, -44, 0.5, -11), BackgroundColor3 = default and Theme.ToggleOn or Theme.ToggleOff, Text = "", BorderSizePixel = 0})
    Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = Toggle})
    local Dot = Create("Frame", {Parent = Toggle, Size = UDim2.new(0, 18, 0, 18), Position = default and UDim2.new(1, -20, 0, 2) or UDim2.new(0, 2, 0, 2), BackgroundColor3 = Theme.Text, BorderSizePixel = 0})
    Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = Dot})
    
    local state = default
    Toggle.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(Toggle, TweenInfo.new(0.2), {BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff}):Play()
        TweenService:Create(Dot, TweenInfo.new(0.2), {Position = state and UDim2.new(1, -20, 0, 2) or UDim2.new(0, 2, 0, 2)}):Play()
        callback(state)
    end)
end

local function AddSlider(parent, text, min, max, default, callback)
    local Frame = Create("Frame", {Parent = parent, Size = UDim2.new(1, 0, 0, 50), BackgroundTransparency = 1})
    Create("TextLabel", {Parent = Frame, Size = UDim2.new(1, -50, 0, 20), BackgroundTransparency = 1, Text = text, TextColor3 = Theme.Text, Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left})
    local ValueLabel = Create("TextLabel", {Parent = Frame, Size = UDim2.new(0, 50, 0, 20), Position = UDim2.new(1, -50, 0, 0), BackgroundTransparency = 1, Text = tostring(default), TextColor3 = Theme.Accent, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Right})
    
    local Bar = Create("Frame", {Parent = Frame, Size = UDim2.new(1, 0, 0, 8), Position = UDim2.new(0, 0, 0, 30), BackgroundColor3 = Theme.ToggleOff, BorderSizePixel = 0})
    Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = Bar})
    local Fill = Create("Frame", {Parent = Bar, Size = UDim2.new((default - min) / (max - min), 0, 1, 0), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0})
    Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = Fill})
    
    local dragging = false
    local function update(input)
        local pos = math.clamp((input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max - min) * pos)
        Fill.Size = UDim2.new(pos, 0, 1, 0)
        ValueLabel.Text = tostring(val)
        callback(val)
    end
    
    Bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then update(input) end
    end)
end

local function AddDropdown(parent, text, options, default, callback)
    local Frame = Create("Frame", {Parent = parent, Size = UDim2.new(1, 0, 0, 35), BackgroundTransparency = 1, ClipsDescendants = false, ZIndex = 5})
    Create("TextLabel", {Parent = Frame, Size = UDim2.new(0.5, 0, 1, 0), BackgroundTransparency = 1, Text = text, TextColor3 = Theme.Text, Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6})
    local Btn = Create("TextButton", {Parent = Frame, Size = UDim2.new(0.45, 0, 0, 26), Position = UDim2.new(0.55, 0, 0.5, -13), BackgroundColor3 = Theme.ToggleOff, Text = default, TextColor3 = Theme.Text, Font = Enum.Font.Gotham, TextSize = 13, BorderSizePixel = 0, ZIndex = 6})
    Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = Btn})
    
    local open = false
    local Dropdown = Create("ScrollingFrame", {Parent = Frame, Size = UDim2.new(0.45, 0, 0, 120), Position = UDim2.new(0.55, 0, 1, 2), BackgroundColor3 = Theme.BG, Visible = false, ZIndex = 10, BorderSizePixel = 0, ScrollBarThickness = 2, CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y})
    Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = Dropdown})
    Create("UIStroke", {Color = Theme.Accent, Thickness = 1, Parent = Dropdown})
    
    for _, opt in pairs(options) do
        local OptBtn = Create("TextButton", {Parent = Dropdown, Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Text = opt, TextColor3 = Theme.Text, Font = Enum.Font.Gotham, TextSize = 13, ZIndex = 11})
        OptBtn.MouseButton1Click:Connect(function()
            Btn.Text = opt
            Dropdown.Visible = false
            open = false
            callback(opt)
        end)
    end
    
    Btn.MouseButton1Click:Connect(function()
        open = not open
        Dropdown.Visible = open
    end)
end

-- Build Tabs
local CombatPage = CreateTab("Combat")
local VisPage = CreateTab("Visuals")
local WorldPage = CreateTab("World")
local MiscPage = CreateTab("Misc")
local SetPage = CreateTab("Settings")

-- Combat Tab
AddToggle(CombatPage, "Enabled", false, function(v) Config.Combat.Enabled = v end)
AddSlider(CombatPage, "Smoothness", 1, 100, 45, function(v) Config.Combat.Smoothness = v end)
AddSlider(CombatPage, "FOV Radius", 20, 600, 150, function(v) Config.Combat.FOV = v end)
AddDropdown(CombatPage, "Target Bone", {"Head", "HumanoidRootPart", "UpperTorso"}, "Head", function(v) Config.Combat.Bone = v end)
AddToggle(CombatPage, "Team Check", true, function(v) Config.Combat.TeamCheck = v end)
AddToggle(CombatPage, "Wall Check", false, function(v) Config.Combat.WallCheck = v end)
AddToggle(CombatPage, "Draw FOV", true, function(v) Config.Combat.DrawFOV = v end)
AddDropdown(CombatPage, "Aim Key", {"Always", "E", "Q", "MouseButton2"}, "Always", function(v) 
    if v == "Always" then Config.Combat.Key = nil 
    elseif v == "MouseButton2" then Config.Combat.Key = Enum.UserInputType.MouseButton2 
    else Config.Combat.Key = Enum.KeyCode[v] end
end)

-- Visuals Tab
AddToggle(VisPage, "ESP Enabled", false, function(v) Config.Visuals.Enabled = v end)
AddToggle(VisPage, "Box ESP", true, function(v) Config.Visuals.Box = v end)
AddToggle(VisPage, "Name ESP", true, function(v) Config.Visuals.Name = v end)
AddToggle(VisPage, "Health ESP", true, function(v) Config.Visuals.Health = v end)
AddToggle(VisPage, "Distance ESP", true, function(v) Config.Visuals.Distance = v end)
AddToggle(VisPage, "Tracers", false, function(v) Config.Visuals.Tracer = v end)

-- World Tab
AddSlider(WorldPage, "WalkSpeed", 16, 500, 16, function(v) 
    Config.World.WalkSpeed = v
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = v
    end
end)
AddSlider(WorldPage, "JumpPower", 50, 1000, 50, function(v) 
    Config.World.JumpPower = v
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.JumpPower = v
    end
end)
AddSlider(WorldPage, "Gravity", 1, 196.2, 196.2, function(v) 
    Config.World.Gravity = v
    workspace.Gravity = v
end)
AddToggle(WorldPage, "Fullbright", false, function(v) 
    Config.World.Fullbright = v
    Lighting.Ambient = v and Color3.fromRGB(255,255,255) or Color3.fromRGB(70,70,70)
    Lighting.OutdoorAmbient = v and Color3.fromRGB(255,255,255) or Color3.fromRGB(70,70,70)
end)
AddToggle(WorldPage, "No Fog", false, function(v)
    Config.World.NoFog = v
    Lighting.FogEnd = v and 100000 or 1000
end)

-- Misc Tab (Fly, Noclip, Inf Jump)
AddToggle(MiscPage, "Fly (WASD/Space/Ctrl)", false, function(v) 
    Config.Misc.Fly = v 
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    if v then
        local bg = Instance.new("BodyGyro", hrp)
        bg.Name = "FlyGyro"
        bg.P = 9e4
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.CFrame = hrp.CFrame
        
        local bv = Instance.new("BodyVelocity", hrp)
        bv.Name = "FlyVel"
        bv.Velocity = Vector3.zero
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        
        RunService.RenderStepped:Connect(function()
            if not Config.Misc.Fly or not hrp.Parent then
                if bg then bg:Destroy() end
                if bv then bv:Destroy() end
                return
            end
            bg.CFrame = Camera.CFrame
            local move = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0,1,0) end
            bv.Velocity = move * Config.Misc.FlySpeed
        end)
    else
        if hrp:FindFirstChild("FlyGyro") then hrp.FlyGyro:Destroy() end
        if hrp:FindFirstChild("FlyVel") then hrp.FlyVel:Destroy() end
    end
end)
AddSlider(MiscPage, "Fly Speed", 10, 300, 50, function(v) Config.Misc.FlySpeed = v end)
AddToggle(MiscPage, "Noclip", false, function(v) Config.Misc.Noclip = v end)
AddToggle(MiscPage, "Infinite Jump", false, function(v) Config.Misc.InfJump = v end)
AddToggle(MiscPage, "Anti-AFK", false, function(v)
    Config.Misc.AntiAFK = v
    if v then
        LocalPlayer.Idled:Connect(function()
            if Config.Misc.AntiAFK then
                local vu = game:GetService("VirtualUser")
                vu:CaptureController()
                vu:ClickButton2(Vector2.new())
            end
        end)
    end
end)

-- Settings Tab
local toggleGui = false
AddToggle(SetPage, "Hide GUI (Right Shift)", false, function(v)
    toggleGui = v
    Main.Visible = not v
end)

-- Default Tab
if Tabs["Combat"] then
    Tabs["Combat"].Btn.BackgroundColor3 = Theme.TabBG
    Tabs["Combat"].Btn.TextColor3 = Theme.Accent
    Tabs["Combat"].Page.Visible = true
    ActiveTab = {Btn = Tabs["Combat"].Btn, Page = Tabs["Combat"].Page, Stroke = Tabs["Combat"].Stroke}
    Tabs["Combat"].Stroke.Transparency = 0
end

-- FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.Color = Theme.Accent
FOVCircle.Filled = false
FOVCircle.Visible = false

-- Target Selection Logic
local function GetTarget()
    local closest = nil
    local shortest = Config.Combat.FOV
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hum = p.Character:FindFirstChild("Humanoid")
            local bone = p.Character:FindFirstChild(Config.Combat.Bone) or p.Character:FindFirstChild("HumanoidRootPart")
            
            if hum and hum.Health > 0 and bone then
                if Config.Combat.TeamCheck and p.Team == LocalPlayer.Team then continue end
                
                local pos, onScreen = Camera:WorldToViewportPoint(bone.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if dist < shortest then
                        if Config.Combat.WallCheck then
                            local rayParams = RaycastParams.new()
                            rayParams.FilterDescendantsInstances = {LocalPlayer.Character, p.Character}
                            rayParams.FilterType = Enum.RaycastFilterType.Exclude
                            local ray = workspace:Raycast(Camera.CFrame.Position, bone.Position - Camera.CFrame.Position, rayParams)
                            if ray then continue end
                        end
                        shortest = dist
                        closest = bone
                    end
                end
            end
        end
    end
    return closest
end

-- Main Loop
RunService.RenderStepped:Connect(function()
    -- Noclip
    if Config.Misc.Noclip and LocalPlayer.Character then
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") and v.CanCollide then
                v.CanCollide = false
            end
        end
    end

    -- FOV
    if Config.Combat.DrawFOV and Config.Combat.Enabled then
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        FOVCircle.Radius = Config.Combat.FOV
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end

    -- Combat
    if Config.Combat.Enabled then
        local isKeyDown = true
        if Config.Combat.Key then
            if type(Config.Combat.Key) == "EnumItem" then
                if Config.Combat.Key.EnumType == Enum.KeyCode then
                    isKeyDown = UserInputService:IsKeyDown(Config.Combat.Key)
                else
                    isKeyDown = UserInputService:IsMouseButtonPressed(Config.Combat.Key)
                end
            end
        end
        
        if isKeyDown then
            local target = GetTarget()
            if target then
                local targetPos = target.Position
                local camPos = Camera.CFrame.Position
                local newCFrame = CFrame.new(camPos, targetPos)
                local smoothFactor = 1 - (Config.Combat.Smoothness / 100)
                Camera.CFrame = Camera.CFrame:Lerp(newCFrame, smoothFactor * 0.5)
            end
        end
    end
end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if Config.Misc.InfJump and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- Character update for World tab
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    if char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = Config.World.WalkSpeed
        char.Humanoid.JumpPower = Config.World.JumpPower
    end
end)

-- Hide GUI Keybind
UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.RightShift then
        toggleGui = not toggleGui
        Main.Visible = not toggleGui
    end
end)