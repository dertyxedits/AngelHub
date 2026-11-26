--[[
    AngelHub V3 | Roblox Studio LocalScript
    Discord: https://discord.gg/d8gpXNGknP

    INSTALL:
    Place this LocalScript in StarterPlayer > StarterPlayerScripts
    This is intended for your OWN Roblox experience. For production games,
    validate movement and permissions on the server as well.
]]

local DISCORD_LINK = "https://discord.gg/d8gpXNGknP" -- Discord invite (kept at top)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local oldGui = player:WaitForChild("PlayerGui"):FindFirstChild("AngelHubV3")
if oldGui then oldGui:Destroy() end

local C = {
    bg = Color3.fromRGB(10, 15, 25), panel = Color3.fromRGB(16, 25, 39),
    panel2 = Color3.fromRGB(22, 34, 51), accent = Color3.fromRGB(0, 190, 255),
    accent2 = Color3.fromRGB(60, 225, 255), text = Color3.fromRGB(235, 246, 255),
    muted = Color3.fromRGB(130, 155, 177), good = Color3.fromRGB(50, 220, 160),
}
local state = {
    fly=false, noclip=false, esp=false, names=true, distance=true,
    noFog=false, noAtmosphere=false, fullbright=false, noClouds=false,
    fpsHud=false, crosshair=false, targetMarker=false,
    walkSpeed=16, jumpPower=50, flySpeed=55, uiScale=65,
}
local connections = {}
local highlights = {}
local originalLighting = {
    FogStart=Lighting.FogStart, FogEnd=Lighting.FogEnd,
    Brightness=Lighting.Brightness, ClockTime=Lighting.ClockTime,
    Ambient=Lighting.Ambient, OutdoorAmbient=Lighting.OutdoorAmbient,
}
local atmosphereStates = {}
local cloudStates = {}

local gui = Instance.new("ScreenGui")
gui.Name = "AngelHubV3"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local function corner(obj, radius)
    local x = Instance.new("UICorner") x.CornerRadius = UDim.new(0, radius or 10) x.Parent = obj
end
local function stroke(obj, color, transparency)
    local s = Instance.new("UIStroke") s.Color = color or C.accent s.Transparency = transparency or 0.45 s.Thickness = 1 s.Parent = obj return s
end
local function tween(obj, props, duration)
    TweenService:Create(obj, TweenInfo.new(duration or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end
local function make(class, props, parent)
    local obj = Instance.new(class)
    for k,v in pairs(props or {}) do obj[k] = v end
    obj.Parent = parent
    return obj
end

local main = make("Frame", {Name="Main", AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromScale(0.5,0.5), Size=UDim2.fromOffset(590,420), BackgroundColor3=C.bg, BorderSizePixel=0}, gui)
corner(main, 15) stroke(main, C.accent, 0.22)
local sizeConstraint = Instance.new("UISizeConstraint") sizeConstraint.MinSize=Vector2.new(300,300) sizeConstraint.MaxSize=Vector2.new(650,520) sizeConstraint.Parent=main
local scale = Instance.new("UIScale") scale.Scale = UserInputService.TouchEnabled and 0.65 or 1 scale.Parent = main

local top = make("Frame", {Name="TopBar", Size=UDim2.new(1,0,0,54), BackgroundColor3=C.panel, BorderSizePixel=0}, main)
corner(top, 15)
local topCover = make("Frame", {Position=UDim2.new(0,0,1,-15), Size=UDim2.new(1,0,0,15), BackgroundColor3=C.panel, BorderSizePixel=0}, top)
local logo = make("TextLabel", {BackgroundTransparency=1, Position=UDim2.fromOffset(16,5), Size=UDim2.fromOffset(180,25), Font=Enum.Font.GothamBold, Text="ANGELHUB", TextColor3=C.text, TextSize=19, TextXAlignment=Enum.TextXAlignment.Left}, top)
local version = make("TextLabel", {BackgroundTransparency=1, Position=UDim2.fromOffset(17,29), Size=UDim2.fromOffset(150,16), Font=Enum.Font.Gotham, Text="V3  •  CONTROL CENTER", TextColor3=C.accent2, TextSize=9, TextXAlignment=Enum.TextXAlignment.Left}, top)
local close = make("TextButton", {AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-12,0.5,0), Size=UDim2.fromOffset(32,30), BackgroundColor3=C.panel2, Text="×", TextColor3=C.text, Font=Enum.Font.GothamBold, TextSize=21, AutoButtonColor=false}, top)
corner(close,8)

local sidebar = make("Frame", {Position=UDim2.fromOffset(12,66), Size=UDim2.new(0,132,1,-78), BackgroundColor3=C.panel, BorderSizePixel=0}, main)
corner(sidebar,12)
local sideList = make("UIListLayout", {Padding=UDim.new(0,6), SortOrder=Enum.SortOrder.LayoutOrder}, sidebar)
make("UIPadding", {PaddingTop=UDim.new(0,10), PaddingLeft=UDim.new(0,8), PaddingRight=UDim.new(0,8)}, sidebar)
local content = make("ScrollingFrame", {Position=UDim2.fromOffset(155,66), Size=UDim2.new(1,-167,1,-78), BackgroundColor3=C.panel, BorderSizePixel=0, ScrollBarThickness=3, ScrollBarImageColor3=C.accent, CanvasSize=UDim2.new()}, main)
corner(content,12)
local contentPadding = make("UIPadding", {PaddingTop=UDim.new(0,12), PaddingLeft=UDim.new(0,12), PaddingRight=UDim.new(0,12), PaddingBottom=UDim.new(0,12)}, content)
local contentList = make("UIListLayout", {Padding=UDim.new(0,8), SortOrder=Enum.SortOrder.LayoutOrder}, content)
contentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() content.CanvasSize=UDim2.new(0,0,0,contentList.AbsoluteContentSize.Y+24) end)

local pages, tabButtons = {}, {}
local currentPage
local function clearPage()
    for _,v in ipairs(content:GetChildren()) do if v:IsA("GuiObject") and v ~= contentPadding and v ~= contentList then v:Destroy() end end
end
local function section(title)
    local label=make("TextLabel", {Size=UDim2.new(1,-4,0,25), BackgroundTransparency=1, Font=Enum.Font.GothamBold, Text=title:upper(), TextColor3=C.accent2, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left}, content)
    return label
end
local function rowBase(title, description)
    local row=make("Frame", {Size=UDim2.new(1,-4,0,description and 56 or 42), BackgroundColor3=C.panel2, BorderSizePixel=0}, content)
    corner(row,9)
    make("TextLabel", {BackgroundTransparency=1, Position=UDim2.fromOffset(11,description and 7 or 0), Size=UDim2.new(1,-105,0,22), Font=Enum.Font.GothamSemibold, Text=title, TextColor3=C.text, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left}, row)
    if description then make("TextLabel", {BackgroundTransparency=1, Position=UDim2.fromOffset(11,29), Size=UDim2.new(1,-22,0,17), Font=Enum.Font.Gotham, Text=description, TextColor3=C.muted, TextSize=9, TextXAlignment=Enum.TextXAlignment.Left}, row) end
    return row
end
local function toggle(title, key, description, callback)
    local row=rowBase(title,description)
    local b=make("TextButton", {AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-10,0.5,0), Size=UDim2.fromOffset(42,22), BackgroundColor3=state[key] and C.accent or Color3.fromRGB(55,68,82), Text="", AutoButtonColor=false}, row)
    corner(b,20)
    local knob=make("Frame", {Position=state[key] and UDim2.new(1,-19,0,3) or UDim2.fromOffset(3,3), Size=UDim2.fromOffset(16,16), BackgroundColor3=Color3.new(1,1,1), BorderSizePixel=0}, b) corner(knob,20)
    local function update(value)
        state[key]=value
        tween(b,{BackgroundColor3=value and C.accent or Color3.fromRGB(55,68,82)})
        tween(knob,{Position=value and UDim2.new(1,-19,0,3) or UDim2.fromOffset(3,3)})
        if callback then callback(value) end
    end
    b.Activated:Connect(function() update(not state[key]) end)
    return update
end
local function slider(title, key, min, max, description, callback)
    local row=rowBase(title,description) row.Size=UDim2.new(1,-4,0,65)
    local value=make("TextLabel", {BackgroundTransparency=1, AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,-12,0,5), Size=UDim2.fromOffset(65,18), Font=Enum.Font.GothamBold, Text=tostring(state[key]), TextColor3=C.accent2, TextSize=11, TextXAlignment=Enum.TextXAlignment.Right}, row)
    local bar=make("Frame", {Position=UDim2.new(0,12,1,-18), Size=UDim2.new(1,-24,0,5), BackgroundColor3=Color3.fromRGB(55,70,85), BorderSizePixel=0}, row) corner(bar,5)
    local fill=make("Frame", {Size=UDim2.new((state[key]-min)/(max-min),0,1,0), BackgroundColor3=C.accent, BorderSizePixel=0}, bar) corner(fill,5)
    local dragging=false
    local function setFromX(x)
        local pct=math.clamp((x-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1)
        local n=math.floor(min+(max-min)*pct+0.5) state[key]=n value.Text=tostring(n) fill.Size=UDim2.new(pct,0,1,0)
        if callback then callback(n) end
    end
    bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true setFromX(i.Position.X) end end)
    UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then setFromX(i.Position.X) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
end
local function action(title, label, callback, description)
    local row=rowBase(title,description)
    local b=make("TextButton", {AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-9,0.5,0), Size=UDim2.fromOffset(82,27), BackgroundColor3=C.accent, Text=label, TextColor3=Color3.fromRGB(4,18,28), Font=Enum.Font.GothamBold, TextSize=10, AutoButtonColor=false}, row)
    corner(b,7) b.Activated:Connect(callback)
end

local function applyWalk()
    local char=player.Character local hum=char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed=state.walkSpeed hum.UseJumpPower=true hum.JumpPower=state.jumpPower end
end
local function setAtmosphere(enabled)
    for _,obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Atmosphere") then
            if atmosphereStates[obj]==nil then atmosphereStates[obj]=obj.Enabled end
            obj.Enabled=not enabled and atmosphereStates[obj] or false
        end
    end
end
local function setClouds(enabled)
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Clouds") then
            if cloudStates[obj]==nil then cloudStates[obj]=obj.Enabled end
            obj.Enabled=not enabled and cloudStates[obj] or false
        end
    end
end
local function applyWorld()
    if state.noFog then Lighting.FogStart=0 Lighting.FogEnd=100000 else Lighting.FogStart=originalLighting.FogStart Lighting.FogEnd=originalLighting.FogEnd end
    setAtmosphere(state.noAtmosphere)
    setClouds(state.noClouds)
    if state.fullbright then Lighting.Brightness=3 Lighting.ClockTime=14 Lighting.Ambient=Color3.fromRGB(190,190,190) Lighting.OutdoorAmbient=Color3.fromRGB(190,190,190)
    else Lighting.Brightness=originalLighting.Brightness Lighting.ClockTime=originalLighting.ClockTime Lighting.Ambient=originalLighting.Ambient Lighting.OutdoorAmbient=originalLighting.OutdoorAmbient end
end

local function clearHighlights()
    for p,h in pairs(highlights) do if h and h.Parent then h:Destroy() end highlights[p]=nil end
end
local function refreshHighlights()
    clearHighlights()
    if not state.esp then return end
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=player and p.Character then
            local h=Instance.new("Highlight") h.Name="AngelHub_PlayerHighlight" h.FillColor=C.accent h.OutlineColor=C.accent2 h.FillTransparency=0.78 h.OutlineTransparency=0.1 h.Adornee=p.Character h.Parent=gui highlights[p]=h
        end
    end
end
Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(function() task.wait(0.5) refreshHighlights() end) end)
Players.PlayerRemoving:Connect(function(p) if highlights[p] then highlights[p]:Destroy() highlights[p]=nil end end)

local flyAttachment, flyVelocity, flyConnection
local flyUpHeld, flyDownHeld = false, false
local collisionDefaults = {}
local function stopFly()
    if flyConnection then flyConnection:Disconnect() flyConnection=nil end
    if flyVelocity then flyVelocity:Destroy() flyVelocity=nil end
    if flyAttachment then flyAttachment:Destroy() flyAttachment=nil end
end
local function startFly()
    stopFly()
    local char=player.Character local root=char and char:FindFirstChild("HumanoidRootPart") local hum=char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then state.fly=false return end
    flyAttachment=Instance.new("Attachment") flyAttachment.Name="AngelHubFlyAttachment" flyAttachment.Parent=root
    flyVelocity=Instance.new("LinearVelocity") flyVelocity.Name="AngelHubFlyVelocity" flyVelocity.Attachment0=flyAttachment flyVelocity.RelativeTo=Enum.ActuatorRelativeTo.World flyVelocity.MaxForce=1000000 flyVelocity.VectorVelocity=Vector3.zero flyVelocity.Parent=root
    hum:ChangeState(Enum.HumanoidStateType.Physics)
    flyConnection=RunService.RenderStepped:Connect(function()
        if not root.Parent then stopFly() return end
        local move=Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move+=camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move-=camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move-=camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move+=camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) or flyUpHeld then move+=Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or flyDownHeld then move-=Vector3.yAxis end
        flyVelocity.VectorVelocity=move.Magnitude>0 and move.Unit*state.flySpeed or Vector3.zero
    end)
end

local crosshair, targetDot, flyUpButton, flyDownButton
local function showPage(name)
    currentPage=name clearPage()
    for n,b in pairs(tabButtons) do b.BackgroundColor3=(n==name) and C.accent or C.panel2 b.TextColor3=(n==name) and Color3.fromRGB(5,20,30) or C.text end
    if name=="Home" then
        section("Welcome to AngelHub")
        action("Discord community","COPY LINK",function()
            local box=make("TextBox",{Size=UDim2.new(1,-4,0,38),BackgroundColor3=C.panel2,Text=DISCORD_LINK,TextColor3=C.text,Font=Enum.Font.Gotham,TextSize=11,ClearTextOnFocus=false},content) corner(box,8) box:CaptureFocus() box.CursorPosition=#DISCORD_LINK+1
        end,"Opens a selectable invite field for mobile copy/paste")
        section("Quick controls")
        toggle("FPS + ping HUD","fpsHud","Show performance information")
        toggle("Center crosshair","crosshair","Simple center-screen aiming reference",function(v) crosshair.Visible=v end)
        toggle("Target marker","targetMarker","Show a small marker at screen center",function(v) targetDot.Visible=v end)
    elseif name=="Visuals" then
        section("Player visuals")
        toggle("Player highlights","esp","Developer/debug highlights for your own experience",function() refreshHighlights() end)
        toggle("Show player names","names","Reserved for the in-game player overlay")
        toggle("Show distance","distance","Reserved for the in-game player overlay")
        action("Refresh highlights","REFRESH",refreshHighlights,"Rebuild highlights for currently spawned players")
    elseif name=="World" then
        section("Environment")
        toggle("No fog","noFog","Remove distance fog",applyWorld)
        toggle("Disable atmosphere","noAtmosphere","Turn off Atmosphere effects",applyWorld)
        toggle("Fullbright","fullbright","Increase brightness and ambient lighting",applyWorld)
        toggle("Disable clouds","noClouds","Hide Terrain cloud layers",applyWorld)
        action("Restore environment","RESTORE",function() state.noFog=false state.noAtmosphere=false state.fullbright=false state.noClouds=false applyWorld() showPage("World") end,"Restore the original Lighting and cloud settings")
        section("World note")
        local note=make("TextLabel",{Size=UDim2.new(1,-4,0,45),BackgroundColor3=C.panel2,Text="These options change the local view only. For consistent gameplay, configure Lighting and atmosphere in Roblox Studio too.",TextColor3=C.muted,Font=Enum.Font.Gotham,TextSize=10,TextWrapped=true},content) corner(note,8)
    elseif name=="Misc" then
        section("Movement controls")
        toggle("Fly","fly","WASD to move • on-screen UP/DOWN on mobile",function(v) flyUpButton.Visible=v and UserInputService.TouchEnabled flyDownButton.Visible=v and UserInputService.TouchEnabled if v then startFly() else stopFly() flyUpHeld=false flyDownHeld=false local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid") if h then h:ChangeState(Enum.HumanoidStateType.GettingUp) end end end)
        slider("Fly speed","flySpeed",10,120,"Adjust flying movement speed")
        slider("Walk speed","walkSpeed",8,50,"Default Roblox speed is 16",function() applyWalk() end)
        slider("Jump power","jumpPower",20,120,"Default jump power is 50",function() applyWalk() end)
        toggle("Noclip","noclip","Pass through parts locally (testing only)",function(enabled)
            local char=player.Character
            if enabled and char then
                for _,part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then collisionDefaults[part]=part.CanCollide part.CanCollide=false end end
            else
                for part,canCollide in pairs(collisionDefaults) do if part and part.Parent then part.CanCollide=canCollide end end
                table.clear(collisionDefaults)
            end
        end)
        action("Reset movement","RESET",function() state.fly=false state.noclip=false state.walkSpeed=16 state.jumpPower=50 stopFly()
            for part,canCollide in pairs(collisionDefaults) do if part and part.Parent then part.CanCollide=canCollide end end table.clear(collisionDefaults)
            applyWalk() showPage("Misc") end,"Restore default movement values")
        section("Utilities")
        toggle("FPS + ping HUD","fpsHud","Display current FPS and network ping")
    elseif name=="Settings" then
        section("Interface")
        slider("UI scale","uiScale",55,110,"Resize the panel to fit your screen",function(v) scale.Scale=v/100 end)
        action("Reset window position","RESET",function() main.Position=UDim2.fromScale(0.5,0.5) end)
        action("Accent: cyan","CYAN",function() C.accent=Color3.fromRGB(0,190,255) C.accent2=Color3.fromRGB(60,225,255) stroke(main,C.accent,0.22) end)
        section("About")
        local about=make("TextLabel",{Size=UDim2.new(1,-4,0,48),BackgroundColor3=C.panel2,Text="AngelHub V3 • Mobile responsive • Built for your own Roblox experience",TextColor3=C.muted,Font=Enum.Font.Gotham,TextSize=10,TextWrapped=true},content) corner(about,8)
    end
end

for i,name in ipairs({"Home","Visuals","World","Misc","Settings"}) do
    local b=make("TextButton",{Name=name,Size=UDim2.new(1,0,0,34),BackgroundColor3=C.panel2,Text=name,TextColor3=C.text,Font=Enum.Font.GothamSemibold,TextSize=11,AutoButtonColor=false,LayoutOrder=i},sidebar)
    corner(b,8) tabButtons[name]=b b.Activated:Connect(function() showPage(name) end)
end

-- Floating open/close button (draggable on touch and mouse)
local openButton=make("TextButton",{Name="AngelHubToggle",AnchorPoint=Vector2.new(0,0),Position=UDim2.new(0,0,0.42,0),Size=UDim2.fromOffset(48,48),BackgroundColor3=C.panel,Text="A",TextColor3=C.accent2,Font=Enum.Font.GothamBlack,TextSize=22,AutoButtonColor=false},gui)
corner(openButton,14) stroke(openButton,C.accent,0.15)
local function makeDraggable(handle, target)
    local dragging=false local dragStart local startPos local inputObject
    handle.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true dragStart=input.Position startPos=target.Position inputObject=input
            input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then dragging=false end end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
            local delta=input.Position-dragStart target.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
        end
    end)
end
makeDraggable(top,main) makeDraggable(openButton,openButton)
local function setOpen(value)
    main.Visible=value
    openButton.Visible=not value
end
close.Activated:Connect(function() setOpen(false) end)
openButton.Activated:Connect(function() setOpen(true) end)
UserInputService.InputBegan:Connect(function(input,processed)
    if processed then return end
    if input.KeyCode==Enum.KeyCode.RightShift then setOpen(not main.Visible) end
end)

crosshair=make("TextLabel",{Name="AngelHubCrosshair",AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(24,24),BackgroundTransparency=1,Text="+",TextColor3=C.accent2,TextStrokeTransparency=0.3,Font=Enum.Font.GothamBold,TextSize=22,Visible=false},gui)
targetDot=make("Frame",{Name="AngelHubTargetMarker",AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(7,7),BackgroundColor3=C.accent2,BorderSizePixel=0,Visible=false},gui) corner(targetDot,10)
flyUpButton=make("TextButton",{Name="FlyUp",AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-18,1,-115),Size=UDim2.fromOffset(48,42),BackgroundColor3=C.panel,Text="UP",TextColor3=C.accent2,Font=Enum.Font.GothamBold,TextSize=11,Visible=false},gui) corner(flyUpButton,9) stroke(flyUpButton,C.accent,0.35)
flyDownButton=make("TextButton",{Name="FlyDown",AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-18,1,-65),Size=UDim2.fromOffset(48,42),BackgroundColor3=C.panel,Text="DOWN",TextColor3=C.accent2,Font=Enum.Font.GothamBold,TextSize=10,Visible=false},gui) corner(flyDownButton,9) stroke(flyDownButton,C.accent,0.35)
flyUpButton.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then flyUpHeld=true end end)
flyUpButton.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then flyUpHeld=false end end)
flyDownButton.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then flyDownHeld=true end end)
flyDownButton.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then flyDownHeld=false end end)
local hud=make("TextLabel",{Name="AngelHubStats",AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-12,0,12),Size=UDim2.fromOffset(150,36),BackgroundColor3=C.panel,Text="FPS: --  |  Ping: --",TextColor3=C.text,Font=Enum.Font.GothamSemibold,TextSize=10,Visible=false},gui) corner(hud,8) stroke(hud,C.accent,0.5)
local frames=0 local last= os.clock()
RunService.RenderStepped:Connect(function(dt)
    frames+=1
    if os.clock()-last>=1 then
        local fps=math.floor(frames/(os.clock()-last)) frames=0 last=os.clock()
        local ping="--"
        pcall(function() ping=math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
        hud.Text="FPS: "..fps.."  |  Ping: "..ping.." ms"
        hud.Visible=state.fpsHud
    end
    if state.noclip then
        local char=player.Character
        if char then for _,part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then if collisionDefaults[part]==nil then collisionDefaults[part]=part.CanCollide end part.CanCollide=false end end end
    end
end)

player.CharacterAdded:Connect(function() task.wait(0.35) applyWalk() if state.fly then startFly() end end)
showPage("Home")

-- Keep all controls and local effects tidy if the GUI is removed.
gui.Destroying:Connect(function()
    stopFly() clearHighlights()
    Lighting.FogStart=originalLighting.FogStart Lighting.FogEnd=originalLighting.FogEnd
    Lighting.Brightness=originalLighting.Brightness Lighting.ClockTime=originalLighting.ClockTime
    Lighting.Ambient=originalLighting.Ambient Lighting.OutdoorAmbient=originalLighting.OutdoorAmbient
    setAtmosphere(false) setClouds(false)
end)
