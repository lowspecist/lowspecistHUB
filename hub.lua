-- lowspecistHUB v5 — tüm özellikler
-- Xeno Executor uyumlu

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local function safeCall(func, ...)
	local ok, res = pcall(func, ...)
	return ok and res or nil
end
local function getHui()
	return safeCall(gethui) or game.CoreGui
end
local function rndName()
	return string.char(97+math.random(25))..tostring(math.random(100000,999999))
end

-- ===== Config =====
local defaultConfig = {
	Fly = { enabled = false, speed = 50 },
	Movement = { walkSpeed = 16, jumpPower = 50, jumpHeight = false, infiniteJump = false, noclip = false },
	ESP = { enabled = false, box = true, name = true, health = true, distance = true, tracers = false, snaplines = false, skeleton = false, chams = false, teamCheck = false },
	Aimbot = { enabled = false, fov = 100, smooth = 0.2, showFOV = false, silentAim = false },
	Triggerbot = { enabled = false, delay = 0 },
	Player = { godmode = false, invisibility = false, antiFling = false, clickTP = false, spectate = false, teleportTo = false },
	Server = { antiAFK = false, fullbright = false },
	Performance = { mode = false },
	Stealth = { hidden = false },
}

local cfg = getgenv().lowspecistHUB_Config or {}
for k, v in pairs(defaultConfig) do
	if cfg[k] == nil then cfg[k] = v end
	if type(v) == "table" then
		for sk, sv in pairs(v) do
			if cfg[k][sk] == nil then cfg[k][sk] = sv end
		end
	end
end
getgenv().lowspecistHUB_Config = cfg

-- ===== Cleanup =====
local CleanUp = {}
local activeConns = {}
local function regConn(c) table.insert(activeConns, c); return c end
local function regClean(obj) table.insert(CleanUp, obj); return obj end
local function cleanConns()
	for _, c in ipairs(activeConns) do
		if typeof(c) == "RBXScriptConnection" then pcall(function() c:Disconnect() end) end
	end
	activeConns = {}
	for _, c in ipairs(CleanUp) do
		if typeof(c) == "RBXScriptConnection" then pcall(function() c:Disconnect() end) end
	end
	CleanUp = {}
end

-- ===== UI Builders =====
local function createToggle(parent, text, configTable, key, callback)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, -10, 0, 28)
	f.BackgroundTransparency = 1
	f.Parent = parent

	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, 40, 0, 18)
	b.Position = UDim2.new(0, 0, 0, 5)
	b.BorderSizePixel = 0
	b.Parent = f

	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, -50, 0, 28)
	l.Position = UDim2.new(0, 50, 0, 0)
	l.BackgroundTransparency = 1
	l.TextColor3 = Color3.fromRGB(255,255,255)
	l.Text = text
	l.Font = Enum.Font.SourceSans
	l.TextSize = 14
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = f

	local function upd()
		b.BackgroundColor3 = configTable[key] and Color3.fromRGB(0,170,0) or Color3.fromRGB(170,0,0)
	end
	upd()

	b.MouseButton1Click:Connect(function()
		configTable[key] = not configTable[key]
		upd()
		if callback then pcall(callback, configTable[key]) end
	end)
	task.defer(function()
		if callback then pcall(callback, configTable[key]) end
	end)
	return f
end

local function createSlider(parent, text, configTable, key, min, max, callback)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, -10, 0, 45)
	f.BackgroundTransparency = 1
	f.Parent = parent

	local val = configTable[key] or min
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, 0, 0, 18)
	l.BackgroundTransparency = 1
	l.TextColor3 = Color3.fromRGB(255,255,255)
	l.Text = text..": "..val
	l.Font = Enum.Font.SourceSans
	l.TextSize = 14
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = f

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, 0, 0, 8)
	bar.Position = UDim2.new(0, 0, 0, 22)
	bar.BackgroundColor3 = Color3.fromRGB(50,50,50)
	bar.BorderSizePixel = 0
	bar.Parent = f

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new((val-min)/(max-min), 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(0,100,255)
	fill.BorderSizePixel = 0
	fill.Parent = bar

	local knob = Instance.new("TextButton")
	knob.Size = UDim2.new(0, 12, 0, 12)
	knob.Position = UDim2.new((val-min)/(max-min), -6, 0.5, -6)
	knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
	knob.Text = ""
	knob.BorderSizePixel = 0
	knob.Parent = bar

	local dragging = false
	local function update(inp)
		local p = math.clamp((inp.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
		local v = math.floor(min + (max-min)*p)
		knob.Position = UDim2.new(p, -6, 0.5, -6)
		fill.Size = UDim2.new(p, 0, 1, 0)
		l.Text = text..": "..v
		configTable[key] = v
		if callback then pcall(callback, v) end
	end

	knob.MouseButton1Down:Connect(function() dragging = true end)
	UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
	UserInputService.InputChanged:Connect(function(inp)
		if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
			update({Position = Vector2.new(inp.Position.X, inp.Position.Y)})
		end
	end)
	task.defer(function()
		if callback then pcall(callback, val) end
	end)
	return f
end

local function createButton(parent, text, callback)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, -10, 0, 28)
	b.BackgroundColor3 = Color3.fromRGB(40,40,40)
	b.TextColor3 = Color3.fromRGB(255,255,255)
	b.Text = text
	b.Font = Enum.Font.SourceSans
	b.TextSize = 14
	b.BorderSizePixel = 0
	b.Parent = parent
	b.MouseButton1Click:Connect(function() pcall(callback) end)
	return b
end

local function createDropdown(parent, text, options, configTable, key, callback)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, -10, 0, 28)
	f.BackgroundTransparency = 1
	f.Parent = parent

	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(0.5, 0, 1, 0)
	l.BackgroundTransparency = 1
	l.TextColor3 = Color3.fromRGB(255,255,255)
	l.Text = text
	l.Font = Enum.Font.SourceSans
	l.TextSize = 14
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = f

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.5, -5, 0, 22)
	btn.Position = UDim2.new(0.5, 0, 0, 3)
	btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
	btn.TextColor3 = Color3.fromRGB(255,255,255)
	btn.Text = configTable[key] or options[1]
	btn.Font = Enum.Font.SourceSans
	btn.TextSize = 13
	btn.BorderSizePixel = 0
	btn.Parent = f

	local idx = 1
	btn.MouseButton1Click:Connect(function()
		idx = idx % #options + 1
		configTable[key] = options[idx]
		btn.Text = options[idx]
		if callback then pcall(callback, options[idx]) end
	end)
	task.defer(function()
		if callback then pcall(callback, configTable[key] or options[1]) end
	end)
	return f
end

-- ===== GUI =====
local gui = Instance.new("ScreenGui")
gui.Name = "lowspecistHUB"
gui.Parent = getHui()
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Enabled = true

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 620, 0, 420)
mainFrame.Position = UDim2.new(0.5, -310, 0.5, -210)
mainFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)
mainFrame.BorderSizePixel = 0
mainFrame.BackgroundTransparency = 0.1
mainFrame.ClipsDescendants = true
mainFrame.Parent = gui

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.BackgroundColor3 = Color3.fromRGB(0,0,0)
titleBar.BackgroundTransparency = 0.4
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -30, 1, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(0,200,255)
title.Text = "lowspecistHUB v5"
title.Font = Enum.Font.Code
title.TextSize = 16
title.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 1, 0)
closeBtn.Position = UDim2.new(1, -30, 0, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 16
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar
closeBtn.MouseButton1Click:Connect(function() gui.Enabled = false end)

-- Drag
local dragging, dragStart, frameStart = false, nil, nil
titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		frameStart = mainFrame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local d = input.Position - dragStart
		mainFrame.Position = UDim2.new(frameStart.X.Scale, frameStart.X.Offset+d.X, frameStart.Y.Scale, frameStart.Y.Offset+d.Y)
	end
end)

-- Side panel
local sidePanel = Instance.new("ScrollingFrame")
sidePanel.Size = UDim2.new(0, 130, 1, -30)
sidePanel.Position = UDim2.new(0, 0, 0, 30)
sidePanel.BackgroundColor3 = Color3.fromRGB(15,15,15)
sidePanel.BorderSizePixel = 0
sidePanel.ScrollBarThickness = 4
sidePanel.CanvasSize = UDim2.new(0,0,0,0)
sidePanel.Parent = mainFrame

local sideLayout = Instance.new("UIListLayout")
sideLayout.Parent = sidePanel
sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
sideLayout.Padding = UDim.new(0,2)

-- Content
local contentContainer = Instance.new("ScrollingFrame")
contentContainer.Size = UDim2.new(1, -130, 1, -30)
contentContainer.Position = UDim2.new(0, 130, 0, 30)
contentContainer.BackgroundColor3 = Color3.fromRGB(25,25,25)
contentContainer.BorderSizePixel = 0
contentContainer.ScrollBarThickness = 4
contentContainer.CanvasSize = UDim2.new(0,0,0,0)
contentContainer.ClipsDescendants = true
contentContainer.Parent = mainFrame

-- ===== Categories =====
local categories = {"Movement", "Visual", "Combat", "Player", "Server", "Admin", "Extra"}
local categoryButtons = {}
local categoryFrames = {}
local selectedCategory = nil

local function switchCategory(name)
	if selectedCategory == name then return end
	selectedCategory = name
	for _, e in ipairs(categoryButtons) do
		e.button.BackgroundColor3 = (e.category == name) and Color3.fromRGB(0,100,200) or Color3.fromRGB(30,30,30)
	end
	for cat, frame in pairs(categoryFrames) do
		frame.Visible = (cat == name)
	end
	task.defer(function()
		local vf = categoryFrames[name]
		if vf then
			local lay = vf:FindFirstChildOfClass("UIListLayout")
			if lay then
				contentContainer.CanvasSize = UDim2.new(0,0,0,lay.AbsoluteContentSize.Y + 20)
			end
		end
	end)
end

for i, cat in ipairs(categories) do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -4, 0, 30)
	btn.BackgroundColor3 = Color3.fromRGB(30,30,30)
	btn.TextColor3 = Color3.fromRGB(255,255,255)
	btn.Text = cat
	btn.Font = Enum.Font.SourceSans
	btn.TextSize = 14
	btn.BorderSizePixel = 0
	btn.LayoutOrder = i
	btn.Parent = sidePanel
	table.insert(categoryButtons, {button = btn, category = cat})
	btn.MouseButton1Click:Connect(function() switchCategory(cat) end)

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundTransparency = 1
	frame.Visible = false
	frame.Parent = contentContainer
	local fl = Instance.new("UIListLayout")
	fl.Parent = frame
	fl.SortOrder = Enum.SortOrder.LayoutOrder
	fl.Padding = UDim.new(0, 4)
	categoryFrames[cat] = frame
end

switchCategory("Movement")

-- Toggle GUI (RShift / X)
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.RightShift or input.KeyCode == Enum.KeyCode.X then
		gui.Enabled = not gui.Enabled
	end
end)

-- ===== Module Variables =====
local noclipConn = nil
local ijConn = nil
local flyEnabled = false
local flyBodyGyro, flyBodyVel, flyHeartbeat
local espDrawings = {}
local espName = rndName()
local aimbotActive = false
local aimbotName = rndName()
local fovCircle = nil
local chamsHL = {}
local spectating = nil
local savedMaxHP = nil

-- ===== FLY =====
local function startFly()
	if flyEnabled then return end
	local char = LocalPlayer.Character
	if not char then return end
	local hum = char:FindFirstChild("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	if not hum or not root then return end
	flyBodyGyro = Instance.new("BodyGyro")
	flyBodyGyro.MaxTorque = Vector3.new(400000,400000,400000)
	flyBodyGyro.P = 30000
	flyBodyGyro.CFrame = root.CFrame
	flyBodyGyro.Parent = root
	flyBodyVel = Instance.new("BodyVelocity")
	flyBodyVel.MaxForce = Vector3.new(400000,400000,400000)
	flyBodyVel.Velocity = Vector3.zero
	flyBodyVel.Parent = root
	hum.PlatformStand = true
	flyEnabled = true
	flyHeartbeat = RunService.Heartbeat:Connect(function()
		if not flyEnabled then return end
		local dir = Vector3.zero
		local cf = Camera.CFrame
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cf.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cf.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cf.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cf.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0,1,0) end
		flyBodyVel.Velocity = (dir.Magnitude > 0 and dir.Unit or Vector3.zero) * cfg.Fly.speed
		flyBodyGyro.CFrame = CFrame.new(Vector3.zero, cf.LookVector)
	end)
	regConn(flyHeartbeat)
end
local function stopFly()
	if not flyEnabled then return end
	flyEnabled = false
	if flyHeartbeat then flyHeartbeat:Disconnect() flyHeartbeat = nil end
	if flyBodyGyro then pcall(function() flyBodyGyro:Destroy() end) flyBodyGyro = nil end
	if flyBodyVel then pcall(function() flyBodyVel:Destroy() end) flyBodyVel = nil end
	local char = LocalPlayer.Character
	if char and char:FindFirstChild("Humanoid") then char.Humanoid.PlatformStand = false end
end

-- ===== ESP =====
local function removeESP()
	pcall(function() RunService:UnbindFromRenderStep(espName) end)
	for _, d in ipairs(espDrawings) do pcall(function() d:Remove() end) end
	espDrawings = {}
end
local function createESP()
	removeESP()
	if not cfg.ESP.enabled then return end
	RunService:BindToRenderStep(espName, 1, function()
		for _, d in ipairs(espDrawings) do pcall(function() d:Remove() end) end
		espDrawings = {}
		pcall(function()
			local myTeam = LocalPlayer.Team
			local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= LocalPlayer then
					if cfg.ESP.teamCheck and p.Team == myTeam then continue end
					local ch = p.Character
					if ch and ch:FindFirstChild("Head") and ch:FindFirstChild("HumanoidRootPart") and ch:FindFirstChild("Humanoid") then
						if ch.Humanoid.Health <= 0 then continue end
						local hp, onScr = Camera:WorldToViewportPoint(ch.Head.Position)
						if not onScr then continue end
						local fp = Camera:WorldToViewportPoint((ch.HumanoidRootPart.CFrame * CFrame.new(0,-3,0)).Position)
						local h = math.abs(fp.Y - hp.Y)
						if cfg.ESP.box then
							local bx = Drawing.new("Square")
							bx.Visible=true; bx.Color=Color3.fromRGB(255,0,0); bx.Thickness=2; bx.Filled=false
							local sw = h/2
							bx.Position = Vector2.new(hp.X-sw/2, hp.Y)
							bx.Size = Vector2.new(sw, h)
							table.insert(espDrawings, bx)
						end
						if cfg.ESP.name then
							local nm = Drawing.new("Text")
							nm.Visible=true; nm.Color=Color3.fromRGB(255,255,255); nm.Center=true; nm.Outline=true; nm.Size=16
							nm.Position = Vector2.new(hp.X, hp.Y-10); nm.Text=p.Name
							table.insert(espDrawings, nm)
						end
						if cfg.ESP.health then
							local hm = ch.Humanoid
							if hm.MaxHealth > 0 then
								local hb = Drawing.new("Square"); hb.Filled=true
								local hp2 = hm.Health/hm.MaxHealth
								hb.Position = Vector2.new(hp.X-5-h/4-2, hp.Y+h*(1-hp2))
								hb.Size = Vector2.new(4, h*hp2)
								hb.Color = Color3.fromRGB(255*(1-hp2), 255*hp2, 0)
								table.insert(espDrawings, hb)
							end
						end
						if cfg.ESP.distance then
							local dd = Drawing.new("Text")
							dd.Visible=true; dd.Color=Color3.fromRGB(200,200,200); dd.Center=true; dd.Size=14
							local dist = myRoot and math.floor((myRoot.Position-ch.HumanoidRootPart.Position).Magnitude) or 0
							dd.Position = Vector2.new(hp.X, hp.Y+10); dd.Text=dist.."m"
							table.insert(espDrawings, dd)
						end
						if cfg.ESP.tracers then
							local tr = Drawing.new("Line")
							tr.Visible=true; tr.Color=Color3.fromRGB(255,0,0); tr.Thickness=1
							local sm = myRoot and Camera:WorldToViewportPoint(myRoot.Position)
							local st = Camera:WorldToViewportPoint(ch.HumanoidRootPart.Position)
							if sm and sm.Z>0 and st.Z>0 then
								tr.From=Vector2.new(sm.X,sm.Y); tr.To=Vector2.new(st.X,st.Y)
							end
							table.insert(espDrawings, tr)
						end
						if cfg.ESP.snaplines then
							local sl = Drawing.new("Line")
							sl.Visible=true; sl.Color=Color3.fromRGB(0,255,0); sl.Thickness=1
							local bot = Camera:WorldToViewportPoint(ch.HumanoidRootPart.Position)
							sl.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
							sl.To = Vector2.new(bot.X, bot.Y)
							table.insert(espDrawings, sl)
						end
						if cfg.ESP.skeleton then
							local function skLine(a, b)
								local pa, va = Camera:WorldToViewportPoint(a)
								local pb, vb = Camera:WorldToViewportPoint(b)
								if va and vb then
									local ln = Drawing.new("Line")
									ln.Visible=true; ln.Color=Color3.fromRGB(255,255,255); ln.Thickness=1
									ln.From=Vector2.new(pa.X,pa.Y); ln.To=Vector2.new(pb.X,pb.Y)
									table.insert(espDrawings, ln)
								end
							end
							local h = ch:FindFirstChild("Head")
							local t = ch:FindFirstChild("Torso") or ch:FindFirstChild("UpperTorso")
							local ra = ch:FindFirstChild("Right Arm") or ch:FindFirstChild("RightUpperArm")
							local la = ch:FindFirstChild("Left Arm") or ch:FindFirstChild("LeftUpperArm")
							local rl = ch:FindFirstChild("Right Leg") or ch:FindFirstChild("RightUpperLeg")
							local ll = ch:FindFirstChild("Left Leg") or ch:FindFirstChild("LeftUpperLeg")
							if h and t then
								skLine(h.Position, t.Position)
								if ra then skLine(t.Position, ra.Position) end
								if la then skLine(t.Position, la.Position) end
								if rl then skLine(t.Position, rl.Position) end
								if ll then skLine(t.Position, ll.Position) end
							end
						end
					end
				end
			end
		end)
	end)
end

-- ===== CHAMS =====
local function applyChams()
	for _, hl in ipairs(chamsHL) do pcall(function() hl:Destroy() end) end
	chamsHL = {}
	if not cfg.ESP.chams then return end
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character then
			local hl = Instance.new("Highlight")
			hl.Name = rndName()
			hl.FillColor = Color3.fromRGB(255,0,0)
			hl.OutlineColor = Color3.fromRGB(255,0,0)
			hl.FillTransparency = 0.5
			hl.OutlineTransparency = 0
			hl.Parent = p.Character
			table.insert(chamsHL, hl)
		end
	end
end

-- ===== AIMBOT =====
local function startAimbot()
	if aimbotActive then return end
	aimbotActive = true
	-- FOV circle
	if cfg.Aimbot.showFOV then
		fovCircle = Drawing.new("Circle")
		fovCircle.Visible = true
		fovCircle.Color = Color3.fromRGB(255,255,255)
		fovCircle.Thickness = 1
		fovCircle.Filled = false
		fovCircle.Radius = cfg.Aimbot.fov
		fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
	end
	RunService:BindToRenderStep(aimbotName, 2, function()
		pcall(function()
			-- update FOV circle
			if fovCircle then
				fovCircle.Radius = cfg.Aimbot.fov
				fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
			end
			if not cfg.Aimbot.enabled and not cfg.Triggerbot.enabled then return end
			local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			if not myRoot then return end
			local best, bestDist = nil, cfg.Aimbot.fov
			local sc = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= LocalPlayer then
					local ch = p.Character
					if ch and ch:FindFirstChild("Head") and ch:FindFirstChild("Humanoid") and ch.Humanoid.Health > 0 then
						local sp, onS = Camera:WorldToViewportPoint(ch.Head.Position)
						if onS then
							local d = (Vector2.new(sp.X,sp.Y)-sc).Magnitude
							if d < bestDist then bestDist=d; best=p end
						end
					end
				end
			end
			-- Aimbot
			if cfg.Aimbot.enabled and best then
				local tc = best.Character
				if tc and tc:FindFirstChild("Head") then
					Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, tc.Head.Position), cfg.Aimbot.smooth)
				end
			end
			-- Triggerbot
			if cfg.Triggerbot.enabled and best then
				local tc = best.Character
				if tc and tc:FindFirstChild("Head") and tc:FindFirstChild("Humanoid") and tc.Humanoid.Health > 0 then
					local sp, onS = Camera:WorldToViewportPoint(tc.Head.Position)
					if onS then
						if cfg.Triggerbot.delay > 0 then task.wait(cfg.Triggerbot.delay/1000) end
						pcall(function()
							mouse1press()
							task.wait(0.05)
							mouse1release()
						end)
					end
				end
			end
			-- Silent Aim
			if cfg.Aimbot.silentAim and best then
				local tc = best.Character
				if tc and tc:FindFirstChild("Head") then
					-- hook namecall to redirect raycast
					local oldNamecall
					oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
						local method = getnamecallmethod()
						if method == "FindPartOnRay" or method == "Raycast" then
							local args = {...}
							if args[1] == workspace then
								args[2] = Ray.new(Camera.CFrame.Position, (tc.Head.Position - Camera.CFrame.Position).Unit * 1000)
								return oldNamecall(self, unpack(args))
							end
						end
						return oldNamecall(self, ...)
					end))
					regClean(oldNamecall)
				end
			end
		end)
	end)
end
local function stopAimbot()
	aimbotActive = false
	pcall(function() RunService:UnbindFromRenderStep(aimbotName) end)
	if fovCircle then pcall(function() fovCircle:Remove() end) fovCircle = nil end
end

-- ===== PLAYER EFFECTS =====
local function applyGodmode(on)
	if on then
		local function mk(char)
			local h = char:WaitForChild("Humanoid")
			if not savedMaxHP then savedMaxHP = h.MaxHealth end
			h.MaxHealth = math.huge
			h.Health = math.huge
			local c = h.HealthChanged:Connect(function() h.Health = math.huge end)
			regClean(c)
		end
		if LocalPlayer.Character then mk(LocalPlayer.Character) end
		local c = LocalPlayer.CharacterAdded:Connect(mk)
		regClean(c)
	else
		local ch = LocalPlayer.Character
		if ch and ch:FindFirstChild("Humanoid") then
			local restore = savedMaxHP or 100
			ch.Humanoid.MaxHealth = restore
			ch.Humanoid.Health = restore
			savedMaxHP = nil
		end
	end
end

local function applyInvisibility(on)
	local tr = on and 0.9 or 0
	local function set(char)
		for _, p in ipairs(char:GetDescendants()) do
			if p:IsA("BasePart") and p.Transparency < 1 then p.Transparency = tr end
		end
	end
	if LocalPlayer.Character then set(LocalPlayer.Character) end
	local c = LocalPlayer.CharacterAdded:Connect(set)
	regClean(c)
end

local function applyAntiFling(on)
	if on then
		local char = LocalPlayer.Character
		if not char then return end
		local root = char:FindFirstChild("HumanoidRootPart")
		if not root then return end
		local lastSafe = root.Velocity
		local c = RunService.Heartbeat:Connect(function()
			if not root or not root.Parent then return end
			pcall(function()
				if root.Velocity.Magnitude > 200 then root.Velocity = lastSafe
				else lastSafe = root.Velocity end
			end)
		end)
		regConn(c)
	end
end

local function applyClickTP(on)
	if on then
		local c = UserInputService.InputBegan:Connect(function(input, gp)
			if gp then return end
			if input.UserInputType == Enum.UserInputType.MouseButton1 and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
				local mp = UserInputService:GetMouseLocation()
				local ray = Camera:ScreenPointToRay(mp.X, mp.Y)
				local params = RaycastParams.new()
				params.FilterType = Enum.RaycastFilterType.Exclude
				local ign = {}
				if LocalPlayer.Character then
					for _, ch in ipairs(LocalPlayer.Character:GetChildren()) do
						if ch:IsA("BasePart") then table.insert(ign, ch) end
					end
				end
				params.FilterDescendantsInstances = ign
				local res = workspace:Raycast(ray.Origin, ray.Direction*1000, params)
				if res and res.Position then
					local ch = LocalPlayer.Character
					if ch and ch:FindFirstChild("HumanoidRootPart") then
						ch.HumanoidRootPart.CFrame = CFrame.new(res.Position+Vector3.new(0,3,0))
					end
				end
			end
		end)
		regClean(c)
	end
end

-- SPECTATE
local spectateTarget = nil
local spectateConn = nil
local function startSpectate(target)
	if spectateTarget then stopSpectate() end
	spectateTarget = target
	local ch = target.Character
	if not ch or not ch:FindFirstChild("Humanoid") then return end
	Camera.CameraSubject = ch.Humanoid
	spectateConn = target.CharacterAdded:Connect(function(newCh)
		task.wait(0.5)
		if newCh:FindFirstChild("Humanoid") then
			Camera.CameraSubject = newCh.Humanoid
		end
	end)
	regConn(spectateConn)
end
function stopSpectate()
	spectateTarget = nil
	if spectateConn then spectateConn:Disconnect(); spectateConn = nil end
	local myChar = LocalPlayer.Character
	if myChar and myChar:FindFirstChild("Humanoid") then
		Camera.CameraSubject = myChar.Humanoid
	end
end

-- TELEPORT TO PLAYER
local function teleportToPlayer(target)
	local ch = target.Character
	local myCh = LocalPlayer.Character
	if ch and ch:FindFirstChild("HumanoidRootPart") and myCh and myCh:FindFirstChild("HumanoidRootPart") then
		myCh.HumanoidRootPart.CFrame = ch.HumanoidRootPart.CFrame + Vector3.new(3, 0, 0)
	end
end

-- ===== SERVER =====
local function rejoin()
	TeleportService:Teleport(game.PlaceId, LocalPlayer)
end
local function serverHop()
	local myId = game.JobId
	local servers = {}
	local function fetch(cursor)
		local url = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?limit=100"..(cursor and "&cursor="..cursor or "")
		local ok, resp = pcall(function()
			local body = game:HttpGet(url)
			return HttpService:JSONDecode(body)
		end)
		if ok and resp and resp.data then
			for _, s in ipairs(resp.data) do
				if s.playing < s.maxPlayers and s.id ~= myId then
					table.insert(servers, s.id)
				end
			end
			if #servers < 10 and resp.nextPageCursor then fetch(resp.nextPageCursor) end
		end
	end
	fetch()
	if #servers > 0 then
		TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1,#servers)], LocalPlayer)
	end
end
local function enableAntiAFK()
	local c = LocalPlayer.Idled:Connect(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end)
	regConn(c)
end
local function enableFullbright(on)
	if on then
		Lighting.Brightness = 2
		Lighting.ClockTime = 14
		Lighting.FogEnd = 100000
		Lighting.GlobalShadows = false
		Lighting.Ambient = Color3.fromRGB(178,178,178)
	else
		Lighting.Brightness = 1
		Lighting.ClockTime = 12
		Lighting.FogEnd = 100000
		Lighting.GlobalShadows = true
		Lighting.Ambient = Color3.fromRGB(0,0,0)
	end
end

-- ===== CHARACTER DEATH/RESPAWN =====
local function onCharDeath()
	if flyEnabled then
		if flyHeartbeat then flyHeartbeat:Disconnect() flyHeartbeat = nil end
		if flyBodyGyro then pcall(function() flyBodyGyro:Destroy() end) flyBodyGyro = nil end
		if flyBodyVel then pcall(function() flyBodyVel:Destroy() end) flyBodyVel = nil end
		flyEnabled = false
	end
	cleanConns()
end

local function onCharSpawn(char)
	if cfg.Fly.enabled then
		task.defer(function()
			if char:FindFirstChild("HumanoidRootPart") then startFly() end
		end)
	end
	if cfg.Movement.noclip then
		task.defer(function()
			noclipConn = RunService.Stepped:Connect(function()
				local c = LocalPlayer.Character
				if c then
					for _, p in ipairs(c:GetDescendants()) do
						if p:IsA("BasePart") then p.CanCollide = false end
					end
				end
			end)
			regConn(noclipConn)
		end)
	end
	if cfg.Movement.infiniteJump then
		task.defer(function()
			ijConn = UserInputService.JumpRequest:Connect(function()
				local c = LocalPlayer.Character
				if c and c:FindFirstChild("Humanoid") then c.Humanoid.Jump = true end
			end)
			regConn(ijConn)
		end)
	end
	if cfg.Player.godmode then
		task.defer(function()
			local h = char:WaitForChild("Humanoid", 3)
			if h then
				if not savedMaxHP then savedMaxHP = h.MaxHealth end
				h.MaxHealth = math.huge; h.Health = math.huge
			end
		end)
	end
	if cfg.Server.fullbright then
		task.defer(function() enableFullbright(true) end)
	end
end

LocalPlayer.CharacterAdded:Connect(function(char)
	onCharDeath()
	local h = char:WaitForChild("Humanoid", 10)
	if h then h.Died:Connect(onCharDeath) end
	onCharSpawn(char)
end)

-- ===== FILL CATEGORIES =====
do
	-- MOVEMENT
	local mf = categoryFrames["Movement"]
	createToggle(mf, "Fly", cfg.Fly, "enabled", function(on) if on then startFly() else stopFly() end end)
	createSlider(mf, "Fly Speed", cfg.Fly, "speed", 10, 200)
	createSlider(mf, "WalkSpeed", cfg.Movement, "walkSpeed", 1, 200, function(val)
		local ch = LocalPlayer.Character
		if ch and ch:FindFirstChild("Humanoid") then ch.Humanoid.WalkSpeed = val end
	end)
	createSlider(mf, "JumpPower", cfg.Movement, "jumpPower", 0, 500, function(val)
		local ch = LocalPlayer.Character
		if ch and ch:FindFirstChild("Humanoid") then ch.Humanoid.JumpPower = val end
	end)
	createToggle(mf, "JumpHeight", cfg.Movement, "jumpHeight", function(on)
		local ch = LocalPlayer.Character
		if ch and ch:FindFirstChild("Humanoid") then
			ch.Humanoid.UseJumpPower = not on
			if on then ch.Humanoid.JumpHeight = 50 else ch.Humanoid.JumpPower = cfg.Movement.jumpPower end
		end
	end)
	createToggle(mf, "Infinite Jump", cfg.Movement, "infiniteJump", function(on)
		if ijConn then ijConn:Disconnect(); ijConn = nil end
		if on then
			ijConn = UserInputService.JumpRequest:Connect(function()
				local c = LocalPlayer.Character
				if c and c:FindFirstChild("Humanoid") then c.Humanoid.Jump = true end
			end)
			regConn(ijConn)
		end
	end)
	createToggle(mf, "NoClip", cfg.Movement, "noclip", function(on)
		if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
		if on then
			noclipConn = RunService.Stepped:Connect(function()
				local c = LocalPlayer.Character
				if c then
					for _, p in ipairs(c:GetDescendants()) do
						if p:IsA("BasePart") then p.CanCollide = false end
					end
				end
			end)
			regConn(noclipConn)
		end
	end)

	-- VISUAL
	local vf = categoryFrames["Visual"]
	createToggle(vf, "ESP Master", cfg.ESP, "enabled", function() createESP() end)
	createToggle(vf, "Box", cfg.ESP, "box", function() createESP() end)
	createToggle(vf, "Name", cfg.ESP, "name", function() createESP() end)
	createToggle(vf, "Health", cfg.ESP, "health", function() createESP() end)
	createToggle(vf, "Distance", cfg.ESP, "distance", function() createESP() end)
	createToggle(vf, "Tracers", cfg.ESP, "tracers", function() createESP() end)
	createToggle(vf, "Snaplines", cfg.ESP, "snaplines", function() createESP() end)
	createToggle(vf, "Skeleton", cfg.ESP, "skeleton", function() createESP() end)
	createToggle(vf, "Chams", cfg.ESP, "chams", function() applyChams() end)
	createToggle(vf, "Team Check", cfg.ESP, "teamCheck", function() createESP(); applyChams() end)
	createToggle(vf, "Fullbright", cfg.Server, "fullbright", function(on) enableFullbright(on) end)

	-- COMBAT
	local cf = categoryFrames["Combat"]
	createToggle(cf, "Aimbot", cfg.Aimbot, "enabled", function(on) if on then startAimbot() else stopAimbot() end end)
	createSlider(cf, "FOV", cfg.Aimbot, "fov", 10, 360, function() if fovCircle then fovCircle.Radius = cfg.Aimbot.fov end end)
	createSlider(cf, "Smooth", cfg.Aimbot, "smooth", 0.01, 1)
	createToggle(cf, "Show FOV", cfg.Aimbot, "showFOV", function(on)
		if on and aimbotActive then
			fovCircle = Drawing.new("Circle")
			fovCircle.Visible = true
			fovCircle.Color = Color3.fromRGB(255,255,255)
			fovCircle.Thickness = 1
			fovCircle.Filled = false
			fovCircle.Radius = cfg.Aimbot.fov
			fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
		elseif fovCircle then
			pcall(function() fovCircle:Remove() end); fovCircle = nil
		end
	end)
	createToggle(cf, "Silent Aim", cfg.Aimbot, "silentAim", function(on)
		if on and not aimbotActive then startAimbot() end
	end)
	createToggle(cf, "Triggerbot", cfg.Triggerbot, "enabled", function(on)
		if on and not aimbotActive then startAimbot() end
	end)
	createSlider(cf, "Trigger Delay (ms)", cfg.Triggerbot, "delay", 0, 500)

	-- PLAYER
	local pf = categoryFrames["Player"]
	createToggle(pf, "Godmode", cfg.Player, "godmode", applyGodmode)
	createToggle(pf, "Invisibility", cfg.Player, "invisibility", applyInvisibility)
	createToggle(pf, "Anti-Fling", cfg.Player, "antiFling", applyAntiFling)
	createToggle(pf, "Click TP (Ctrl+LMB)", cfg.Player, "clickTP", applyClickTP)
	-- Spectate dropdown
	local playerList = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then table.insert(playerList, p.Name) end
	end
	if #playerList == 0 then table.insert(playerList, "none") end
	createDropdown(pf, "Spectate", playerList, cfg.Player, "spectate", function(name)
		if name == "none" then stopSpectate(); return end
		local target = Players:FindFirstChild(name)
		if target then startSpectate(target) end
	end)
	createDropdown(pf, "Teleport To", playerList, cfg.Player, "teleportTo", function(name)
		local target = Players:FindFirstChild(name)
		if target then teleportToPlayer(target) end
	end)
	createButton(pf, "Stop Spectate", function() stopSpectate() end)

	-- SERVER
	local sf = categoryFrames["Server"]
	createButton(sf, "Rejoin", rejoin)
	createButton(sf, "Server Hop", serverHop)
	createToggle(sf, "Anti-AFK", cfg.Server, "antiAFK", function(on) if on then enableAntiAFK() end end)

	-- ADMIN
	local af = categoryFrames["Admin"]
	local cmdBox = Instance.new("TextBox")
	cmdBox.Size = UDim2.new(1, -10, 0, 28)
	cmdBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
	cmdBox.TextColor3 = Color3.fromRGB(255,255,255)
	cmdBox.PlaceholderText = "cmd: rejoin | speed <n> | jump <n> | tp <player> | fly | noclip | bright"
	cmdBox.Font = Enum.Font.Code
	cmdBox.TextSize = 12
	cmdBox.ClearTextOnFocus = true
	cmdBox.Parent = af
	cmdBox.FocusLost:Connect(function(ep)
		if not ep then return end
		local txt = cmdBox.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")
		local ch = LocalPlayer.Character
		local hum = ch and ch:FindFirstChild("Humanoid")
		if txt == "rejoin" then
			rejoin()
		elseif txt:sub(1,6) == "speed " and hum then
			local v = tonumber(txt:sub(7))
			if v then hum.WalkSpeed = v end
		elseif txt:sub(1,5) == "jump " and hum then
			local v = tonumber(txt:sub(6))
			if v then hum.JumpPower = v end
		elseif txt:sub(1,3) == "tp " then
			local target = Players:FindFirstChild(txt:sub(4))
			if target then teleportToPlayer(target) end
		elseif txt == "fly" then
			if flyEnabled then stopFly() else startFly() end
		elseif txt == "noclip" then
			if noclipConn then noclipConn:Disconnect(); noclipConn = nil
			else
				noclipConn = RunService.Stepped:Connect(function()
					local c = LocalPlayer.Character
					if c then for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
				end)
				regConn(noclipConn)
			end
		elseif txt == "bright" then
			cfg.Server.fullbright = not cfg.Server.fullbright
			enableFullbright(cfg.Server.fullbright)
		elseif txt == "god" then
			cfg.Player.godmode = not cfg.Player.godmode
			applyGodmode(cfg.Player.godmode)
		elseif txt == "invisible" then
			cfg.Player.invisibility = not cfg.Player.invisibility
			applyInvisibility(cfg.Player.invisibility)
		end
		cmdBox.Text = ""
	end)

	-- EXTRA
	local ef = categoryFrames["Extra"]
	createButton(ef, "Export Config", function()
		local json = HttpService:JSONEncode(cfg)
		if setclipboard then setclipboard(json) end
	end)
	createButton(ef, "Import Config", function()
		if getclipboard then
			local ok, data = pcall(function() return HttpService:JSONDecode(getclipboard()) end)
			if ok and data then
				for k, v in pairs(data) do cfg[k] = v end
			end
		end
	end)
	createToggle(ef, "Performance Mode", cfg.Performance, "mode", function(on)
		pcall(function()
			local s = UserSettings():GetService("UserGameSettings")
			s.RenderingQualityLevel = on and Enum.QualityLevel.Level01 or Enum.QualityLevel.Level21
		end)
	end)
	createButton(ef, "Destroy GUI", function()
		cleanConns()
		stopFly()
		stopAimbot()
		removeESP()
		for _, hl in ipairs(chamsHL) do pcall(function() hl:Destroy() end) end
		gui:Destroy()
	end)
end

-- Teleport cleanup
LocalPlayer.OnTeleport:Connect(function()
	cleanConns()
	stopFly()
	stopAimbot()
	removeESP()
	for _, hl in ipairs(chamsHL) do pcall(function() hl:Destroy() end) end
	chamsHL = {}
end)
