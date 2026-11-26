-- AngelHub v1.0
-- LocalScript for YOUR OWN game. Put it in StarterPlayer > StarterPlayerScripts.
--
-- Player targeting (aimbot + ESP on other players) is locked to games you own:
--   * it works in Roblox Studio, or
--   * in places whose PlaceId is listed below.
-- Put your PlaceId(s) here after publishing, e.g.  { 1234567890 }
-- Tell your players in the game description that aimbot is enabled.
-- You can switch player targeting off at runtime from a server script:
--   workspace:SetAttribute("AngelHubPvP", false)
-- NPC / dummy targets: tag a Model (with Humanoid) "AimTarget" via CollectionService.

local ALLOWED_PLACE_IDS = {}

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local CS = game:GetService("CollectionService")

local lp = Players.LocalPlayer
local cam = workspace.CurrentCamera
local TAG = "AimTarget"

local PVP_OK = RS:IsStudio() or table.find(ALLOWED_PLACE_IDS, game.PlaceId) ~= nil
local function pvpEnabled()
	return PVP_OK and workspace:GetAttribute("AngelHubPvP") ~= false
end

local ACCENT = Color3.fromRGB(70, 225, 255)
local BG = Color3.fromRGB(11, 19, 29)
local PANEL = Color3.fromRGB(18, 30, 44)
local OFF = Color3.fromRGB(38, 52, 68)
local DIM = Color3.fromRGB(165, 182, 198)
local WHITE = Color3.new(1, 1, 1)
local ENEMY = Color3.fromRGB(255, 90, 90)

local cfg = {
	aim = false, aimSmooth = 45, aimFov = 120, useFov = true, aimPart = "Head", drawFov = true,
	teamCheck = true, wallCheck = false,
	espBox = false, espName = false, espHealth = false, espDist = false, espMax = 1000,
	fullbright = false, timeOn = false, time = 14, camFovOn = false, camFov = 70, noFog = false,
	unlockZoom = false, gravOn = false, gravity = 120,
	walkOn = false, walk = 32, jumpOn = false, jump = 75, fly = false, flySpeed = 60,
	noclip = false, infJump = false,
	crosshair = false, crossSize = 10, hud = false,
	menuKey = "RightShift", uiScale = 1,
}
local defaults = {}
for k, v in pairs(cfg) do defaults[k] = v end

local controls = {}
local conns = {}
local dummies = {}
local esp = {}
local origFov = cam.FieldOfView
local orig = {
	Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime, Ambient = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient, FogEnd = Lighting.FogEnd, GlobalShadows = Lighting.GlobalShadows,
	Gravity = workspace.Gravity,
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
	circle.Visible = cfg.aim and cfg.drawFov and cfg.useFov
end

local main = new("Frame", {
	Name = "Main", Position = UDim2.fromOffset(60, 50), Size = UDim2.fromOffset(520, 350),
	BackgroundColor3 = BG, BorderSizePixel = 0,
}, gui)
corner(main, UDim.new(0, 14))
local mainStroke = new("UIStroke", { Color = ACCENT, Thickness = 2.5 }, main)
new("UIGradient", {
	Color = ColorSequence.new(Color3.fromRGB(140, 245, 255), Color3.fromRGB(30, 120, 200)), Rotation = 45,
}, mainStroke)
new("UIGradient", {
	Color = ColorSequence.new(Color3.fromRGB(17, 30, 46), Color3.fromRGB(8, 14, 22)), Rotation = 90,
}, main)
local glow = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 0 }, main)
corner(glow, UDim.new(0, 14))
new("UIStroke", { Color = ACCENT, Thickness = 9, Transparency = 0.85 }, glow)
local scaleObj = new("UIScale", {}, main)

local function updateScale()
	scaleObj.Scale = cfg.uiScale * math.clamp(cam.ViewportSize.X / 640, 0.5, 1)
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
local titleBar = new("Frame", { Size = UDim2.new(1, 0, 0, 58), BackgroundTransparency = 1 }, main)
local logo = new("TextLabel", {
	Position = UDim2.fromOffset(12, 7), Size = UDim2.fromOffset(44, 44), BackgroundColor3 = Color3.fromRGB(40, 90, 130),
	Text = "AH", TextColor3 = WHITE, Font = Enum.Font.GothamBlack, TextSize = 20,
}, titleBar)
corner(logo, UDim.new(0, 11))
new("UIStroke", { Color = ACCENT, Thickness = 1.5 }, logo)
new("UIGradient", {
	Color = ColorSequence.new(Color3.fromRGB(160, 235, 255), Color3.fromRGB(40, 110, 190)), Rotation = 60,
}, logo)
local title = new("TextLabel", {
	Position = UDim2.fromOffset(68, 0), Size = UDim2.new(1, -170, 1, 0), BackgroundTransparency = 1,
	Text = "AngelHub | v1.0", TextColor3 = ACCENT, Font = Enum.Font.Michroma, TextSize = 24,
	TextXAlignment = Enum.TextXAlignment.Left,
}, titleBar)
new("UIStroke", { Color = ACCENT, Thickness = 1.2, Transparency = 0.55 }, title)
new("Frame", {
	Position = UDim2.new(0, 10, 1, -1), Size = UDim2.new(1, -20, 0, 1), BackgroundColor3 = Color3.fromRGB(50, 120, 150),
	BorderSizePixel = 0,
}, titleBar)

local function winBtn(text, xOff)
	return new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, xOff, 0.5, 0), Size = UDim2.fromOffset(28, 28),
		BackgroundTransparency = 1, Text = text, TextColor3 = DIM, Font = Enum.Font.GothamBold, TextSize = 15,
	}, titleBar)
end
local closeBtn = winBtn("X", -10)
local maxBtn = winBtn("O", -40)
local minBtn = winBtn("-", -70)
closeBtn.Activated:Connect(function() main.Visible = false end)
draggable(titleBar, main)

local side = new("Frame", { Position = UDim2.fromOffset(12, 68), Size = UDim2.fromOffset(128, 270), BackgroundTransparency = 1 }, main)
new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, side)
local content = new("Frame", { Position = UDim2.fromOffset(150, 68), Size = UDim2.fromOffset(358, 270), BackgroundColor3 = PANEL }, main)
corner(content, UDim.new(0, 10))
new("UIStroke", { Color = OFF, Thickness = 1 }, content)

local collapsed = false
minBtn.Activated:Connect(function()
	collapsed = not collapsed
	side.Visible = not collapsed
	content.Visible = not collapsed
	main.Size = collapsed and UDim2.fromOffset(520, 58) or UDim2.fromOffset(520, 350)
end)
maxBtn.Activated:Connect(function()
	if controls.uiScale then controls.uiScale(cfg.uiScale >= 1.15 and 1 or 1.2) end
end)

---------------------------------------------------------------- tabs
local pages, tabBtns, tabStrokes = {}, {}, {}
local function showTab(n)
	for k, p in pairs(pages) do p.Visible = (k == n) end
	for k, b in pairs(tabBtns) do
		local sel = (k == n)
		b.TextColor3 = sel and ACCENT or DIM
		b.BackgroundColor3 = sel and Color3.fromRGB(26, 62, 86) or BG
		tabStrokes[k].Color = sel and ACCENT or OFF
		tabStrokes[k].Thickness = sel and 2 or 1
	end
end

local function addTab(name, icon, order)
	local b = new("TextButton", {
		LayoutOrder = order, Size = UDim2.new(1, 0, 0, 42), Text = icon .. "  " .. name, BackgroundColor3 = BG,
		TextColor3 = DIM, Font = Enum.Font.GothamMedium, TextSize = 15, AutoButtonColor = false,
	}, side)
	corner(b, UDim.new(0, 9))
	tabStrokes[name] = new("UIStroke", { Color = OFF, Thickness = 1 }, b)
	b.Activated:Connect(function() showTab(name) end)
	local p = new("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
		ScrollBarImageColor3 = ACCENT, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Visible = false,
	}, content)
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, p)
	new("UIPadding", {
		PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingBottom = UDim.new(0, 10),
	}, p)
	pages[name], tabBtns[name] = p, b
	return p
end

---------------------------------------------------------------- widgets
local function section(page, text)
	local row = new("Frame", { Size = UDim2.new(1, -6, 0, 20), BackgroundTransparency = 1 }, page)
	new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Color3.fromRGB(50, 120, 150), BorderSizePixel = 0, ZIndex = 1,
	}, row)
	new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 18), BackgroundColor3 = PANEL, BorderSizePixel = 0, ZIndex = 2,
		Text = "  " .. string.upper(text) .. "  ", TextColor3 = ACCENT, Font = Enum.Font.GothamMedium, TextSize = 11,
	}, row)
end

local function note(page, text, color)
	new("TextLabel", {
		Size = UDim2.new(1, -6, 0, 40), BackgroundTransparency = 1, TextWrapped = true, Text = text,
		TextColor3 = color or DIM, Font = Enum.Font.Gotham, TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
	}, page)
end

local function toggle(page, label, key, cb)
	local row = new("Frame", { Size = UDim2.new(1, -6, 0, 30), BackgroundTransparency = 1 }, page)
	new("TextLabel", {
		Size = UDim2.new(1, -64, 1, 0), BackgroundTransparency = 1, Text = label, TextColor3 = WHITE,
		Font = Enum.Font.GothamMedium, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	local btn = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(52, 26),
		Text = "", AutoButtonColor = false, BackgroundColor3 = OFF,
	}, row)
	corner(btn, UDim.new(1, 0))
	new("UIStroke", { Color = ACCENT, Thickness = 1, Transparency = 0.5 }, btn)
	local knob = new("Frame", { Size = UDim2.fromOffset(20, 20), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = WHITE }, btn)
	corner(knob, UDim.new(1, 0))
	local function set(v)
		cfg[key] = v
		btn.BackgroundColor3 = v and Color3.fromRGB(50, 170, 195) or OFF
		knob.Position = v and UDim2.fromOffset(29, 3) or UDim2.fromOffset(3, 3)
		if cb then cb(v) end
	end
	btn.Activated:Connect(function() set(not cfg[key]) end)
	controls[key] = set
	set(cfg[key])
end

local function slider(page, label, key, min, max, step, suffix, cb)
	local row = new("Frame", { Size = UDim2.new(1, -6, 0, 46), BackgroundTransparency = 1 }, page)
	new("TextLabel", {
		Size = UDim2.new(0.7, 0, 0, 20), BackgroundTransparency = 1, Text = label, TextColor3 = WHITE,
		Font = Enum.Font.GothamMedium, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	local val = new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0.3, 0, 0, 20),
		BackgroundTransparency = 1, TextColor3 = DIM, Font = Enum.Font.GothamMedium, TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Right,
	}, row)
	local bar = new("TextButton", {
		Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 0, 8), Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.fromRGB(8, 14, 22),
	}, row)
	corner(bar, UDim.new(1, 0))
	local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = ACCENT, BorderSizePixel = 0 }, bar)
	corner(fill, UDim.new(1, 0))
	new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(150, 245, 255), Color3.fromRGB(50, 190, 225)) }, fill)
	local knob = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(16, 16), BackgroundColor3 = WHITE,
	}, bar)
	corner(knob, UDim.new(1, 0))
	local function set(v)
		v = math.clamp(math.round(v / step) * step, min, max)
		v = math.floor(v * 100 + 0.5) / 100
		cfg[key] = v
		local a = (v - min) / (max - min)
		fill.Size = UDim2.fromScale(a, 1)
		knob.Position = UDim2.fromScale(a, 0.5)
		val.Text = tostring(v) .. suffix
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

local function dropdown(page, label, key, options, cb)
	local holder = new("Frame", {
		Size = UDim2.new(1, -6, 0, 30), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y,
	}, page)
	new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, holder)
	local head = new("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, LayoutOrder = 1 }, holder)
	new("TextLabel", {
		Size = UDim2.new(1, -150, 1, 0), BackgroundTransparency = 1, Text = label, TextColor3 = WHITE,
		Font = Enum.Font.GothamMedium, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left,
	}, head)
	local btn = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(140, 28),
		BackgroundColor3 = BG, TextColor3 = WHITE, Font = Enum.Font.GothamMedium, TextSize = 14, AutoButtonColor = false,
	}, head)
	corner(btn, UDim.new(0, 7))
	new("UIStroke", { Color = ACCENT, Thickness = 1.5 }, btn)
	local list = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = false, LayoutOrder = 2,
	}, holder)
	new("UIListLayout", {
		Padding = UDim.new(0, 3), HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder,
	}, list)
	local function set(v)
		cfg[key] = v
		btn.Text = v .. "   v"
		list.Visible = false
		if cb then cb(v) end
	end
	for n, o in ipairs(options) do
		local ob = new("TextButton", {
			LayoutOrder = n, Size = UDim2.fromOffset(140, 26), Text = o, BackgroundColor3 = BG, TextColor3 = ACCENT,
			Font = Enum.Font.GothamMedium, TextSize = 13, AutoButtonColor = false,
		}, list)
		corner(ob, UDim.new(0, 6))
		ob.Activated:Connect(function() set(o) end)
	end
	btn.Activated:Connect(function() list.Visible = not list.Visible end)
	controls[key] = set
	set(cfg[key])
end

local function cycle(page, label, key, options, cb)
	local row = new("Frame", { Size = UDim2.new(1, -6, 0, 30), BackgroundTransparency = 1 }, page)
	new("TextLabel", {
		Size = UDim2.new(1, -150, 1, 0), BackgroundTransparency = 1, Text = label, TextColor3 = WHITE,
		Font = Enum.Font.GothamMedium, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	local btn = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(140, 28),
		BackgroundColor3 = BG, TextColor3 = WHITE, Font = Enum.Font.GothamMedium, TextSize = 14, AutoButtonColor = false,
	}, row)
	corner(btn, UDim.new(0, 7))
	new("UIStroke", { Color = ACCENT, Thickness = 1.5 }, btn)
	local function set(v)
		cfg[key] = v
		btn.Text = v .. "   >"
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
		Size = UDim2.new(1, -6, 0, 32), Text = label, BackgroundColor3 = OFF, TextColor3 = WHITE,
		Font = Enum.Font.GothamMedium, TextSize = 14, AutoButtonColor = true,
	}, page)
	corner(b, UDim.new(0, 8))
	b.Activated:Connect(fn)
	return b
end

---------------------------------------------------------------- targets
local function getTargets()
	local list = {}
	for _, m in ipairs(CS:GetTagged(TAG)) do
		if m:IsA("Model") then
			list[#list + 1] = { model = m, name = m.Name, color = ACCENT }
		end
	end
	if pvpEnabled() then
		for _, p in ipairs(Players:GetPlayers()) do
			local c = p.Character
			if p ~= lp and c then
				local sameTeam = cfg.teamCheck and lp.Team ~= nil and p.Team == lp.Team
				if not sameTeam then
					list[#list + 1] = { model = c, name = p.DisplayName, color = ENEMY }
				end
			end
		end
	end
	return list
end

local function visibleTo(part, model)
	if not cfg.wallCheck then return true end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local c = lp.Character
	params.FilterDescendantsInstances = c and { c } or {}
	local origin = cam.CFrame.Position
	local res = workspace:Raycast(origin, part.Position - origin, params)
	return res == nil or res.Instance:IsDescendantOf(model)
end

local function pickTarget()
	local vs = cam.ViewportSize
	local center = Vector2.new(vs.X / 2, vs.Y / 2)
	local best, bestD = nil, math.huge
	for _, t in ipairs(getTargets()) do
		local hum = t.model:FindFirstChildOfClass("Humanoid")
		local part = t.model:FindFirstChild(cfg.aimPart) or t.model:FindFirstChild("HumanoidRootPart")
		if hum and hum.Health > 0 and part then
			local p, on = cam:WorldToViewportPoint(part.Position)
			if on then
				local d = (Vector2.new(p.X, p.Y) - center).Magnitude
				if (not cfg.useFov or d <= cfg.aimFov) and d < bestD and visibleTo(part, t.model) then
					best, bestD = part, d
				end
			end
		end
	end
	return best
end

RS:BindToRenderStep("AngelHubAim", Enum.RenderPriority.Camera.Value + 1, function()
	if cfg.camFovOn then cam.FieldOfView = cfg.camFov end
	if not cfg.aim then return end
	local t = pickTarget()
	if t then
		local alpha = math.clamp(1 - cfg.aimSmooth / 100, 0.03, 1)
		cam.CFrame = cam.CFrame:Lerp(CFrame.lookAt(cam.CFrame.Position, t.Position), alpha)
	end
end)

---------------------------------------------------------------- crosshair + HUD
local cross = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, Visible = false,
}, gui)
local function updateCross()
	cross.Visible = cfg.crosshair
	local s = cfg.crossSize
	local total = s * 2 + 8
	cross.Size = UDim2.fromOffset(total, total)
	for _, c in ipairs(cross:GetChildren()) do c:Destroy() end
	local function bar(x, y, w, h)
		new("Frame", {
			BackgroundColor3 = ACCENT, BorderSizePixel = 0, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h),
		}, cross)
	end
	local c = s + 4
	bar(c - 1, 0, 2, s)
	bar(c - 1, s + 8, 2, s)
	bar(0, c - 1, s, 2)
	bar(s + 8, c - 1, s, 2)
end

local hud = new("TextLabel", {
	Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(230, 24), BackgroundColor3 = BG, BackgroundTransparency = 0.15,
	TextColor3 = ACCENT, Font = Enum.Font.GothamBold, TextSize = 13, Visible = false, Text = "AngelHub",
}, gui)
corner(hud, UDim.new(0, 6))
new("UIStroke", { Color = ACCENT, Thickness = 1 }, hud)

local frames = 0
connect(RS.RenderStepped, function() frames += 1 end)
task.spawn(function()
	while gui.Parent do
		task.wait(0.5)
		hud.Visible = cfg.hud
		hud.Text = "AngelHub  |  " .. math.floor(frames * 2) .. " FPS  |  " .. math.floor(lp:GetNetworkPing() * 1000) .. " ms"
		frames = 0
	end
end)

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
	for _, t in ipairs(getTargets()) do
		local m = t.model
		local hum = m:FindFirstChildOfClass("Humanoid")
		local head = m:FindFirstChild("Head") or m.PrimaryPart or m:FindFirstChild("HumanoidRootPart")
		local dist = head and (cam.CFrame.Position - head.Position).Magnitude or math.huge
		if head and dist <= cfg.espMax and hum and hum.Health > 0 then
			alive[m] = true
			local e = esp[m]
			if not e then e = {} esp[m] = e end
			if cfg.espBox then
				if not e.h then
					e.h = new("Highlight", { FillTransparency = 0.6, OutlineColor = WHITE }, m)
				end
				e.h.FillColor = t.color
			elseif e.h then
				e.h:Destroy() e.h = nil
			end
			if cfg.espName or cfg.espHealth or cfg.espDist then
				if not e.b then
					e.b = new("BillboardGui", {
						Adornee = head, Size = UDim2.fromOffset(160, 50), StudsOffset = Vector3.new(0, 2.6, 0), AlwaysOnTop = true,
					}, gui)
					e.l = new("TextLabel", {
						Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, TextStrokeTransparency = 0.4,
						Font = Enum.Font.GothamBold, TextSize = 13,
					}, e.b)
				end
				e.l.TextColor3 = t.color
				local lines = {}
				if cfg.espName then lines[#lines + 1] = t.name end
				if cfg.espHealth then
					lines[#lines + 1] = math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth) .. " HP"
				end
				if cfg.espDist then lines[#lines + 1] = math.floor(dist) .. " studs" end
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
local tAim = addTab("Aimbot", "(+)", 1)
local tVis = addTab("Visuals", "[o]", 2)
local tWorld = addTab("World", "(@)", 3)
local tSet = addTab("Settings", "{*}", 4)
local tMisc = addTab("Misc", "<x>", 5)

section(tAim, "Aimbot settings")
if not PVP_OK then
	note(tAim, "Player targeting is locked. Add your game's PlaceId to ALLOWED_PLACE_IDS at the top of the script. NPC targets still work.", Color3.fromRGB(255, 190, 90))
end
toggle(tAim, "Enabled", "aim", updateCircle)
slider(tAim, "Aimbot Smoothness", "aimSmooth", 0, 95, 1, "%")
toggle(tAim, "Use FOV", "useFov", updateCircle)
slider(tAim, "FOV Radius", "aimFov", 30, 400, 5, " px", updateCircle)
dropdown(tAim, "Target Bone", "aimPart", { "Head", "HumanoidRootPart" })
toggle(tAim, "Team Check", "teamCheck")
toggle(tAim, "Visible Check", "wallCheck")
toggle(tAim, "Draw FOV", "drawFov", updateCircle)
button(tAim, "Spawn Test Dummy", spawnDummy)
button(tAim, "Clear Dummies", clearDummies)
local capturing = false
local keyBtn
keyBtn = button(tAim, "Adjust Keys or Keybind: [" .. cfg.menuKey .. "]", function()
	capturing = true
	keyBtn.Text = "Press a key..."
end)
keyBtn.BackgroundColor3 = BG
keyBtn.TextColor3 = ACCENT
new("UIStroke", { Color = ACCENT, Thickness = 1.5 }, keyBtn)

section(tVis, "Target overlays")
toggle(tVis, "Highlight", "espBox")
toggle(tVis, "Names", "espName")
toggle(tVis, "Health", "espHealth")
toggle(tVis, "Distance", "espDist")
slider(tVis, "ESP Max Distance", "espMax", 50, 3000, 50, "")
section(tVis, "Screen")
toggle(tVis, "Crosshair", "crosshair", updateCross)
slider(tVis, "Crosshair Size", "crossSize", 4, 30, 1, " px", updateCross)
toggle(tVis, "FPS / Ping HUD", "hud", function(v) hud.Visible = v end)

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
toggle(tWorld, "Unlock Camera Zoom", "unlockZoom", function(v)
	lp.CameraMaxZoomDistance = v and 400 or 128
end)
section(tWorld, "Physics")
toggle(tWorld, "Custom Gravity", "gravOn", function(v)
	workspace.Gravity = v and cfg.gravity or orig.Gravity
end)
slider(tWorld, "Gravity", "gravity", 10, 300, 5, "", function(v)
	if cfg.gravOn then workspace.Gravity = v end
end)

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
	if capturing and i.UserInputType == Enum.UserInputType.Keyboard then
		capturing = false
		cfg.menuKey = i.KeyCode.Name
		keyBtn.Text = "Adjust Keys or Keybind: [" .. cfg.menuKey .. "]"
		return
	end
	if gp then return end
	if i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode.Name == cfg.menuKey then
		main.Visible = not main.Visible
	end
end)

---------------------------------------------------------------- settings tab
local function unload()
	for _, k in ipairs({
		"aim", "espBox", "espName", "espHealth", "espDist", "fullbright", "timeOn", "camFovOn", "noFog",
		"walkOn", "jumpOn", "fly", "noclip", "infJump", "crosshair", "hud", "gravOn", "unlockZoom",
	}) do
		if controls[k] then controls[k](false) end
	end
	for m in pairs(esp) do clearESP(m) end
	clearDummies()
	RS:UnbindFromRenderStep("AngelHubAim")
	for _, c in ipairs(conns) do c:Disconnect() end
	gui:Destroy()
end

section(tSet, "Menu")
cycle(tSet, "Menu Key", "menuKey", { "RightShift", "V", "Insert", "RightControl", "K" }, function(v)
	keyBtn.Text = "Adjust Keys or Keybind: [" .. v .. "]"
end)
slider(tSet, "UI Scale", "uiScale", 0.6, 1.2, 0.05, "x", updateScale)
button(tSet, "Reset To Defaults", function()
	for k, v in pairs(defaults) do
		if controls[k] then controls[k](v) end
	end
end)
button(tSet, "Unload AngelHub", unload)

---------------------------------------------------------------- floating open/close button
local fab = new("TextButton", {
	Position = UDim2.new(1, -70, 0, 70), Size = UDim2.fromOffset(46, 46), Text = "AH", BackgroundColor3 = BG,
	TextColor3 = ACCENT, Font = Enum.Font.GothamBlack, TextSize = 16, AutoButtonColor = false,
}, gui)
corner(fab, UDim.new(1, 0))
new("UIStroke", { Color = ACCENT, Thickness = 1.5 }, fab)
local fabDragged = draggable(fab, fab)
fab.Activated:Connect(function()
	if not fabDragged() then main.Visible = not main.Visible end
end)

updateScale()
updateCircle()
updateCross()
showTab("Aimbot")
