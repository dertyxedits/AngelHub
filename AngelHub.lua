-- AngelHub v1.0
-- LocalScript for YOUR OWN game in Roblox Studio.
-- Put it in StarterPlayer > StarterPlayerScripts.
-- Aim assist only targets Models tagged "AimTarget" (NPCs / dummies). It never targets players.

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local CS = game:GetService("CollectionService")

local lp = Players.LocalPlayer
local cam = workspace.CurrentCamera
local TAG = "AimTarget"

local ACCENT = Color3.fromRGB(70, 225, 255)
local BG = Color3.fromRGB(12, 20, 30)
local PANEL = Color3.fromRGB(20, 32, 46)
local OFF = Color3.fromRGB(42, 55, 70)
local DIM = Color3.fromRGB(170, 185, 200)
local WHITE = Color3.new(1, 1, 1)

local cfg = {
	aim = false, aimSmooth = 45, aimFov = 120, aimPart = "Head", drawFov = true, holdAim = true,
	espBox = false, espName = false, espHealth = false, espDist = false,
	fullbright = false, timeOn = false, time = 14, camFovOn = false, camFov = 70, noFog = false,
	walkOn = false, walk = 32, jumpOn = false, jump = 75, fly = false, flySpeed = 60,
	noclip = false, infJump = false,
	menuKey = "RightShift", uiScale = 1,
}
local defaults = {}
for k, v in pairs(cfg) do defaults[k] = v end

local controls = {}
local conns = {}
local dummies = {}
local esp = {}
local aimHeld = false
local aimBtn = nil
local origFov = cam.FieldOfView
local orig = {
	Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime, Ambient = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient, FogEnd = Lighting.FogEnd, GlobalShadows = Lighting.GlobalShadows,
}

local function connect(sig, fn)
	local c = sig:Connect(fn)
	conns[#conns + 1] = c
	return c
end

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end

local function corner(o, r)
	return new("UICorner", { CornerRadius = r or UDim.new(0, 6) }, o)
end

local function getChar()
	local c = lp.Character
	return c, c and c:FindFirstChildOfClass("Humanoid"), c and c:FindFirstChild("HumanoidRootPart")
end

local function isPress(i)
	return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end

local function isMove(i)
	return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch
end

---------------------------------------------------------------- GUI root
local playerGui = lp:WaitForChild("PlayerGui")
local old = playerGui:FindFirstChild("AngelHub")
if old then old:Destroy() end

local gui = new("ScreenGui", {
	Name = "AngelHub", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 100,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local circle = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	BackgroundTransparency = 1, Visible = false,
}, gui)
corner(circle, UDim.new(1, 0))
new("UIStroke", { Color = ACCENT, Thickness = 1.5 }, circle)

local function updateCircle()
	circle.Size = UDim2.fromOffset(cfg.aimFov * 2, cfg.aimFov * 2)
	circle.Visible = cfg.aim and cfg.drawFov
	if aimBtn then aimBtn.Visible = cfg.aim end
end

local main = new("Frame", {
	Name = "Main", Position = UDim2.fromOffset(60, 60), Size = UDim2.fromOffset(450, 310),
	BackgroundColor3 = BG, BorderSizePixel = 0,
}, gui)
corner(main, UDim.new(0, 10))
new("UIStroke", { Color = ACCENT, Thickness = 1.5 }, main)
local scaleObj = new("UIScale", {}, main)

local function updateScale()
	scaleObj.Scale = cfg.uiScale * math.clamp(cam.ViewportSize.X / 560, 0.55, 1)
end

---------------------------------------------------------------- dragging
local function draggable(handle, target)
	local dragging, startPos, startInput, moved = false, nil, nil, false
	handle.InputBegan:Connect(function(i)
		if isPress(i) then
			dragging, moved = true, false
			startInput = i.Position
			startPos = target.Position
			i.Changed:Connect(function()
				if i.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	connect(UIS.InputChanged, function(i)
		if dragging and isMove(i) then
			local d = i.Position - startInput
			if d.Magnitude > 6 then moved = true end
			if moved then
				target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
			end
		end
	end)
	return function() return moved end
end

---------------------------------------------------------------- title bar
local titleBar = new("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1 }, main)
local logo = new("TextLabel", {
	Position = UDim2.fromOffset(8, 6), Size = UDim2.fromOffset(30, 30), BackgroundColor3 = PANEL,
	Text = "A", TextColor3 = ACCENT, Font = Enum.Font.GothamBold, TextSize = 20,
}, titleBar)
corner(logo, UDim.new(0, 8))
new("TextLabel", {
	Position = UDim2.fromOffset(46, 0), Size = UDim2.new(1, -100, 1, 0), BackgroundTransparency = 1,
	Text = "AngelHub | v1.0", TextColor3 = ACCENT, Font = Enum.Font.GothamBold, TextSize = 20,
	TextXAlignment = Enum.TextXAlignment.Left,
}, titleBar)
local closeBtn = new("TextButton", {
	AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(28, 28),
	BackgroundColor3 = PANEL, Text = "X", TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 14,
}, titleBar)
corner(closeBtn)
closeBtn.Activated:Connect(function() main.Visible = false end)
draggable(titleBar, main)

local side = new("Frame", { Position = UDim2.fromOffset(8, 48), Size = UDim2.fromOffset(112, 254), BackgroundTransparency = 1 }, main)
new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, side)
local content = new("Frame", { Position = UDim2.fromOffset(128, 48), Size = UDim2.fromOffset(314, 254), BackgroundColor3 = PANEL }, main)
corner(content, UDim.new(0, 8))

local pages, tabBtns = {}, {}
local function showTab(n)
	for k, p in pairs(pages) do p.Visible = (k == n) end
	for k, b in pairs(tabBtns) do
		b.TextColor3 = (k == n) and ACCENT or DIM
		b.BackgroundColor3 = (k == n) and PANEL or BG
	end
end

local function addTab(name, order)
	local b = new("TextButton", {
		LayoutOrder = order, Size = UDim2.new(1, 0, 0, 36), Text = name, BackgroundColor3 = BG,
		TextColor3 = DIM, Font = Enum.Font.GothamMedium, TextSize = 15, AutoButtonColor = false,
	}, side)
	corner(b)
	new("UIStroke", { Color = OFF, Thickness = 1 }, b)
	b.Activated:Connect(function() showTab(name) end)
	local p = new("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
		AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Visible = false,
	}, content)
	new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, p)
	new("UIPadding", {
		PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 8),
	}, p)
	pages[name], tabBtns[name] = p, b
	return p
end

---------------------------------------------------------------- widgets
local function section(page, text)
	new("TextLabel", {
		Size = UDim2.new(1, -6, 0, 18), BackgroundTransparency = 1, Text = string.upper(text), TextColor3 = ACCENT,
		Font = Enum.Font.GothamBold, TextSize = 11,
	}, page)
end

local function toggle(page, label, key, cb)
	local row = new("Frame", { Size = UDim2.new(1, -6, 0, 30), BackgroundTransparency = 1 }, page)
	new("TextLabel", {
		Size = UDim2.new(1, -60, 1, 0), BackgroundTransparency = 1, Text = label, TextColor3 = WHITE,
		Font = Enum.Font.GothamMedium, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	local btn = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(48, 22),
		Text = "", AutoButtonColor = false, BackgroundColor3 = OFF,
	}, row)
	corner(btn, UDim.new(1, 0))
	local knob = new("Frame", { Size = UDim2.fromOffset(18, 18), Position = UDim2.fromOffset(2, 2), BackgroundColor3 = WHITE }, btn)
	corner(knob, UDim.new(1, 0))
	local function set(v)
		cfg[key] = v
		btn.BackgroundColor3 = v and ACCENT or OFF
		knob.Position = v and UDim2.fromOffset(28, 2) or UDim2.fromOffset(2, 2)
		if cb then cb(v) end
	end
	btn.Activated:Connect(function() set(not cfg[key]) end)
	controls[key] = set
	set(cfg[key])
end

local function slider(page, label, key, min, max, step, suffix, cb)
	local row = new("Frame", { Size = UDim2.new(1, -6, 0, 44), BackgroundTransparency = 1 }, page)
	local title = new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, TextColor3 = WHITE, Font = Enum.Font.GothamMedium,
		TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	local bar = new("TextButton", {
		Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 0, 8), Text = "", AutoButtonColor = false, BackgroundColor3 = OFF,
	}, row)
	corner(bar, UDim.new(1, 0))
	local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = ACCENT, BorderSizePixel = 0 }, bar)
	corner(fill, UDim.new(1, 0))
	local function set(v)
		v = math.clamp(math.round(v / step) * step, min, max)
		v = math.floor(v * 100 + 0.5) / 100
		cfg[key] = v
		fill.Size = UDim2.fromScale((v - min) / (max - min), 1)
		title.Text = label .. ": " .. tostring(v) .. suffix
		if cb then cb(v) end
	end
	local dragging = false
	local function fromX(x)
		local a = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
		set(min + (max - min) * a)
	end
	bar.InputBegan:Connect(function(i)
		if isPress(i) then dragging = true fromX(i.Position.X) end
	end)
	connect(UIS.InputChanged, function(i)
		if dragging and isMove(i) then fromX(i.Position.X) end
	end)
	connect(UIS.InputEnded, function(i)
		if isPress(i) then dragging = false end
	end)
	controls[key] = set
	set(cfg[key])
end

local function cycle(page, label, key, options, cb)
	local row = new("Frame", { Size = UDim2.new(1, -6, 0, 30), BackgroundTransparency = 1 }, page)
	new("TextLabel", {
		Size = UDim2.new(1, -130, 1, 0), BackgroundTransparency = 1, Text = label, TextColor3 = WHITE,
		Font = Enum.Font.GothamMedium, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	local btn = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(120, 26),
		BackgroundColor3 = BG, TextColor3 = ACCENT, Font = Enum.Font.GothamMedium, TextSize = 13, AutoButtonColor = false,
	}, row)
	corner(btn)
	new("UIStroke", { Color = ACCENT, Thickness = 1 }, btn)
	local function set(v)
		cfg[key] = v
		btn.Text = v .. "  v"
		if cb then cb(v) end
	end
	btn.Activated:Connect(function()
		local idx = table.find(options, cfg[key]) or 0
		set(options[idx % #options + 1])
	end)
	controls[key] = set
	set(cfg[key])
end

local function button(page, label, fn)
	local b = new("TextButton", {
		Size = UDim2.new(1, -6, 0, 30), Text = label, BackgroundColor3 = OFF, TextColor3 = WHITE,
		Font = Enum.Font.GothamMedium, TextSize = 14,
	}, page)
	corner(b)
	b.Activated:Connect(fn)
	return b
end

---------------------------------------------------------------- aim assist
local function pickTarget()
	local vs = cam.ViewportSize
	local center = Vector2.new(vs.X / 2, vs.Y / 2)
	local best, bestD = nil, cfg.aimFov
	for _, m in ipairs(CS:GetTagged(TAG)) do
		if m:IsA("Model") then
			local hum = m:FindFirstChildOfClass("Humanoid")
			local part = m:FindFirstChild(cfg.aimPart)
			if hum and hum.Health > 0 and part then
				local p, on = cam:WorldToViewportPoint(part.Position)
				if on then
					local d = (Vector2.new(p.X, p.Y) - center).Magnitude
					if d <= bestD then best, bestD = part, d end
				end
			end
		end
	end
	return best
end

RS:BindToRenderStep("AngelHubAim", Enum.RenderPriority.Camera.Value + 1, function()
	if cfg.camFovOn then cam.FieldOfView = cfg.camFov end
	if not cfg.aim then return end
	local active = aimHeld or UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) or not cfg.holdAim
	if not active then return end
	local t = pickTarget()
	if t then
		local alpha = math.clamp(1 - cfg.aimSmooth / 100, 0.03, 1)
		cam.CFrame = cam.CFrame:Lerp(CFrame.lookAt(cam.CFrame.Position, t.Position), alpha)
	end
end)

if UIS.TouchEnabled then
	aimBtn = new("TextButton", {
		Position = UDim2.new(1, -150, 1, -150), Size = UDim2.fromOffset(64, 64), BackgroundColor3 = BG, Text = "AIM",
		TextColor3 = ACCENT, Font = Enum.Font.GothamBold, TextSize = 16, AutoButtonColor = false, Visible = false,
	}, gui)
	corner(aimBtn, UDim.new(1, 0))
	new("UIStroke", { Color = ACCENT, Thickness = 1.5 }, aimBtn)
	aimBtn.InputBegan:Connect(function(i) if isPress(i) then aimHeld = true end end)
	aimBtn.InputEnded:Connect(function(i) if isPress(i) then aimHeld = false end end)
end

---------------------------------------------------------------- ESP
local function clearESP(m)
	local e = esp[m]
	if e then
		if e.h then e.h:Destroy() end
		if e.b then e.b:Destroy() end
		esp[m] = nil
	end
end

local function refreshESP()
	local alive = {}
	for _, m in ipairs(CS:GetTagged(TAG)) do
		if m:IsA("Model") then
			alive[m] = true
			local e = esp[m]
			if not e then e = {} esp[m] = e end
			local hum = m:FindFirstChildOfClass("Humanoid")
			local head = m:FindFirstChild("Head") or m.PrimaryPart
			if cfg.espBox then
				if not e.h then
					e.h = new("Highlight", { FillColor = ACCENT, OutlineColor = WHITE, FillTransparency = 0.6 }, m)
				end
			elseif e.h then
				e.h:Destroy() e.h = nil
			end
			local wantText = cfg.espName or cfg.espHealth or cfg.espDist
			if wantText and head then
				if not e.b then
					e.b = new("BillboardGui", {
						Adornee = head, Size = UDim2.fromOffset(150, 48), StudsOffset = Vector3.new(0, 2.5, 0), AlwaysOnTop = true,
					}, gui)
					e.l = new("TextLabel", {
						Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, TextColor3 = WHITE, TextStrokeTransparency = 0.4,
						Font = Enum.Font.GothamBold, TextSize = 13,
					}, e.b)
				end
				local lines = {}
				if cfg.espName then lines[#lines + 1] = m.Name end
				if cfg.espHealth and hum then
					lines[#lines + 1] = math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth) .. " HP"
				end
				if cfg.espDist then
					lines[#lines + 1] = math.floor((cam.CFrame.Position - head.Position).Magnitude) .. " studs"
				end
				e.l.Text = table.concat(lines, "\n")
			elseif e.b then
				e.b:Destroy() e.b, e.l = nil, nil
			end
		end
	end
	for m in pairs(esp) do
		if not alive[m] then clearESP(m) end
	end
end

task.spawn(function()
	while gui.Parent do
		refreshESP()
		task.wait(0.2)
	end
end)

---------------------------------------------------------------- world helpers
local function applyFullbright(v)
	if v then
		Lighting.Brightness = 2
		Lighting.Ambient = WHITE
		Lighting.OutdoorAmbient = WHITE
		Lighting.GlobalShadows = false
	else
		Lighting.Brightness = orig.Brightness
		Lighting.Ambient = orig.Ambient
		Lighting.OutdoorAmbient = orig.OutdoorAmbient
		Lighting.GlobalShadows = orig.GlobalShadows
	end
end

local function applyTime()
	if cfg.timeOn then Lighting.ClockTime = cfg.time else Lighting.ClockTime = orig.ClockTime end
end

local function spawnDummy()
	local _, _, root = getChar()
	if not root then return end
	local m = new("Model", { Name = "Dummy" .. (#dummies + 1) })
	local base = CFrame.new((root.CFrame * CFrame.new(0, 0, -25)).Position)
	local hrp = new("Part", { Name = "HumanoidRootPart", Size = Vector3.new(2, 2, 1), Anchored = true, Color = Color3.fromRGB(80, 160, 255), CFrame = base }, m)
	new("Part", { Name = "Head", Size = Vector3.new(2, 1, 1), Anchored = true, Color = Color3.fromRGB(255, 220, 120), CFrame = base * CFrame.new(0, 1.5, 0) }, m)
	new("Part", { Name = "Legs", Size = Vector3.new(2, 2, 1), Anchored = true, Color = Color3.fromRGB(60, 90, 160), CFrame = base * CFrame.new(0, -2, 0) }, m)
	new("Humanoid", {}, m)
	m.PrimaryPart = hrp
	m.Parent = workspace
	CS:AddTag(m, TAG)
	dummies[#dummies + 1] = { m = m, base = base, t0 = os.clock() }
end

local function clearDummies()
	for _, d in ipairs(dummies) do d.m:Destroy() end
	table.clear(dummies)
end

---------------------------------------------------------------- tabs
local tAim = addTab("Aimbot", 1)
local tVis = addTab("Visuals", 2)
local tWorld = addTab("World", 3)
local tSet = addTab("Settings", 4)
local tMisc = addTab("Misc", 5)

section(tAim, "Aim assist (tagged NPCs only)")
toggle(tAim, "Enabled", "aim", updateCircle)
slider(tAim, "Smoothness", "aimSmooth", 0, 95, 1, "%")
slider(tAim, "FOV Radius", "aimFov", 30, 400, 5, " px", updateCircle)
cycle(tAim, "Target Part", "aimPart", { "Head", "HumanoidRootPart" })
toggle(tAim, "Draw FOV", "drawFov", updateCircle)
toggle(tAim, "Hold to aim (RMB / AIM btn)", "holdAim")
button(tAim, "Spawn Test Dummy", spawnDummy)
button(tAim, "Clear Dummies", clearDummies)

section(tVis, "Target overlays")
toggle(tVis, "Highlight", "espBox")
toggle(tVis, "Names", "espName")
toggle(tVis, "Health", "espHealth")
toggle(tVis, "Distance", "espDist")

section(tWorld, "Lighting")
toggle(tWorld, "Fullbright", "fullbright", applyFullbright)
toggle(tWorld, "Override Time", "timeOn", applyTime)
slider(tWorld, "Clock Time", "time", 0, 24, 0.5, "h", applyTime)
toggle(tWorld, "No Fog", "noFog", function(v)
	Lighting.FogEnd = v and 1e6 or orig.FogEnd
end)
section(tWorld, "Camera")
toggle(tWorld, "Custom Camera FOV", "camFovOn", function(v)
	if not v then cam.FieldOfView = origFov end
end)
slider(tWorld, "Camera FOV", "camFov", 30, 120, 1, "")

section(tMisc, "Character")
toggle(tMisc, "Walk Speed", "walkOn", function(v)
	if not v then
		local _, h = getChar()
		if h then h.WalkSpeed = 16 end
	end
end)
slider(tMisc, "Speed", "walk", 8, 200, 1, "")
toggle(tMisc, "Jump Power", "jumpOn", function(v)
	if not v then
		local _, h = getChar()
		if h then h.JumpPower = 50 end
	end
end)
slider(tMisc, "Power", "jump", 20, 250, 1, "")
toggle(tMisc, "Infinite Jump", "infJump")
toggle(tMisc, "Noclip", "noclip")
section(tMisc, "Fly (jump = up, Ctrl = down)")
toggle(tMisc, "Fly", "fly")
slider(tMisc, "Fly Speed", "flySpeed", 10, 200, 5, "")

---------------------------------------------------------------- loops
connect(RS.Heartbeat, function()
	for _, d in ipairs(dummies) do
		if d.m.Parent then
			d.m:PivotTo(d.base * CFrame.new(math.sin((os.clock() - d.t0) * 1.5) * 10, 0, 0))
		end
	end
	local _, h, r = getChar()
	if not (h and r) then return end
	if cfg.walkOn then h.WalkSpeed = cfg.walk end
	if cfg.jumpOn then
		h.UseJumpPower = true
		h.JumpPower = cfg.jump
	end
	if cfg.fly then
		local rel = cam.CFrame:VectorToObjectSpace(h.MoveDirection)
		local v = cam.CFrame:VectorToWorldSpace(Vector3.new(rel.X, 0, rel.Z)) * cfg.flySpeed
		local up = 0
		if UIS:IsKeyDown(Enum.KeyCode.Space) or h.Jump then up += 1 end
		if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then up -= 1 end
		r.AssemblyLinearVelocity = v + Vector3.new(0, up * cfg.flySpeed, 0)
	end
end)

local noclipWas = false
connect(RS.Stepped, function()
	local c = lp.Character
	if not c then return end
	if cfg.noclip then
		noclipWas = true
		for _, p in ipairs(c:GetChildren()) do
			if p:IsA("BasePart") then p.CanCollide = false end
		end
	elseif noclipWas then
		noclipWas = false
		for _, p in ipairs(c:GetChildren()) do
			if p:IsA("BasePart") then p.CanCollide = true end
		end
	end
end)

connect(UIS.JumpRequest, function()
	if cfg.infJump then
		local _, h = getChar()
		if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
	end
end)

connect(workspace:GetPropertyChangedSignal("CurrentCamera"), function()
	cam = workspace.CurrentCamera
end)
connect(cam:GetPropertyChangedSignal("ViewportSize"), updateScale)

connect(UIS.InputBegan, function(i, gp)
	if gp then return end
	if i.KeyCode == Enum.KeyCode[cfg.menuKey] then main.Visible = not main.Visible end
end)

---------------------------------------------------------------- settings tab
local function unload()
	for _, k in ipairs({ "aim", "espBox", "espName", "espHealth", "espDist", "fullbright", "timeOn", "camFovOn", "noFog", "walkOn", "jumpOn", "fly", "noclip", "infJump" }) do
		if controls[k] then controls[k](false) end
	end
	refreshESP()
	for m in pairs(esp) do clearESP(m) end
	clearDummies()
	RS:UnbindFromRenderStep("AngelHubAim")
	for _, c in ipairs(conns) do c:Disconnect() end
	gui:Destroy()
end

section(tSet, "Menu")
cycle(tSet, "Menu Key", "menuKey", { "RightShift", "V", "Insert", "RightControl", "K" })
slider(tSet, "UI Scale", "uiScale", 0.6, 1.2, 0.05, "x", updateScale)
button(tSet, "Reset To Defaults", function()
	for k, v in pairs(defaults) do
		if controls[k] then controls[k](v) end
	end
end)
button(tSet, "Unload AngelHub", unload)

---------------------------------------------------------------- floating open/close button
local fab = new("TextButton", {
	Position = UDim2.new(1, -70, 0, 70), Size = UDim2.fromOffset(46, 46), Text = "A", BackgroundColor3 = BG,
	TextColor3 = ACCENT, Font = Enum.Font.GothamBold, TextSize = 22, AutoButtonColor = false,
}, gui)
corner(fab, UDim.new(1, 0))
new("UIStroke", { Color = ACCENT, Thickness = 1.5 }, fab)
local fabDragged = draggable(fab, fab)
fab.Activated:Connect(function()
	if not fabDragged() then main.Visible = not main.Visible end
end)

updateScale()
updateCircle()
showTab("Aimbot")
