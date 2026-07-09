-- v1pro — stealth visual + movement hub
-- Client-side features, stealth optimized

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
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

-- ===== LOADING SCREEN =====
local loadingGui = Instance.new("ScreenGui")
loadingGui.Name = rndName()
loadingGui.Parent = getHui()
loadingGui.IgnoreGuiInset = true
loadingGui.DisplayOrder = 999

local loadingBg = Instance.new("Frame")
loadingBg.Size = UDim2.new(1, 0, 1, 0)
loadingBg.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
loadingBg.BorderSizePixel = 0
loadingBg.Parent = loadingGui

local loadingTitle = Instance.new("TextLabel")
loadingTitle.Size = UDim2.new(0.8, 0, 0, 50)
loadingTitle.Position = UDim2.new(0.1, 0, 0.32, 0)
loadingTitle.BackgroundTransparency = 1
loadingTitle.Text = "LowspecistHUB"
loadingTitle.TextColor3 = Color3.fromRGB(0, 200, 255)
loadingTitle.Font = Enum.Font.Code
loadingTitle.TextSize = 38
loadingTitle.Parent = loadingBg

local loadingVersion = Instance.new("TextLabel")
loadingVersion.Size = UDim2.new(0.8, 0, 0, 25)
loadingVersion.Position = UDim2.new(0.1, 0, 0.40, 0)
loadingVersion.BackgroundTransparency = 1
loadingVersion.Text = "v1pro"
loadingVersion.TextColor3 = Color3.fromRGB(80, 80, 100)
loadingVersion.Font = Enum.Font.Code
loadingVersion.TextSize = 18
loadingVersion.Parent = loadingBg

local loadingBarBg = Instance.new("Frame")
loadingBarBg.Size = UDim2.new(0.35, 0, 0, 5)
loadingBarBg.Position = UDim2.new(0.325, 0, 0.52, 0)
loadingBarBg.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
loadingBarBg.BorderSizePixel = 0
loadingBarBg.Parent = loadingBg

local loadingBarFill = Instance.new("Frame")
loadingBarFill.Size = UDim2.new(0, 0, 1, 0)
loadingBarFill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
loadingBarFill.BorderSizePixel = 0
loadingBarFill.Parent = loadingBarBg

local loadingStatus = Instance.new("TextLabel")
loadingStatus.Size = UDim2.new(0.8, 0, 0, 20)
loadingStatus.Position = UDim2.new(0.1, 0, 0.57, 0)
loadingStatus.BackgroundTransparency = 1
loadingStatus.Text = "Yükleniyor..."
loadingStatus.TextColor3 = Color3.fromRGB(100, 100, 120)
loadingStatus.Font = Enum.Font.SourceSans
loadingStatus.TextSize = 14
loadingStatus.Parent = loadingBg

local function loadProgress(percent, text)
	loadingStatus.Text = text or ""
	local tween = TweenService:Create(loadingBarFill, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(percent, 0, 1, 0)})
	tween:Play()
	tween.Completed:Wait()
	task.wait(0.08)
end

loadProgress(0.1, "Servisler yükleniyor...")
loadProgress(0.25, "Yapılandırma okunuyor...")
loadProgress(0.4, "Movement modülü...")
loadProgress(0.55, "ESP modülü...")
loadProgress(0.7, "Aimbot modülü...")
loadProgress(0.85, "Ek modüller...")
loadProgress(0.95, "Tamamlandı!")
task.wait(0.2)
loadingGui:Destroy()

-- ===== Config =====
local defaultConfig = {
	Fly = { enabled = false, speed = 50 },
	Movement = { walkSpeed = 16, jumpPower = 50, jumpHeight = false, infiniteJump = false, noclip = false, gravity = 196.2, spinBot = false, speedForce = false },
	ESP = { enabled = false, box = true, boxStyle = "Corner", name = true, health = true, distance = true, tracers = false, snaplines = false, skeleton = false, headDot = false, chams = false, teamCheck = false, crosshair = false, throttle = false, boxColor = "accent", nameColor = "white" },
	Aimbot = { enabled = false, fov = 100, smooth = 0.2, showFOV = false, teamCheck = false, prediction = false, bindKey = "MouseButton2" },
	Player = { thirdPerson = false, thirdPersonDist = 12, fovChanger = false, fovValue = 70, godmode = false },
	Server = { antiAFK = false, fullbright = false },
	Performance = { mode = false },
}

local cfgKey = rndName()
local cfg = getgenv()[cfgKey] or {}
for k, v in pairs(defaultConfig) do
	if cfg[k] == nil then cfg[k] = v end
	if type(v) == "table" then
		for sk, sv in pairs(v) do
			if cfg[k][sk] == nil then cfg[k][sk] = sv end
		end
	end
end
getgenv()[cfgKey] = cfg

-- Auto-save config
local function autoSave()
	pcall(function()
		if setfflag then setfflag("DebugLuaPrint", "false") end
	end)
end

-- ===== Cleanup =====
local activeConns = {}
local function regConn(c) table.insert(activeConns, c); return c end
local function cleanConns()
	for _, c in ipairs(activeConns) do
		if typeof(c) == "RBXScriptConnection" then pcall(function() c:Disconnect() end) end
	end
	activeConns = {}
end

-- ===== Notifications =====
local notifGui = Instance.new("ScreenGui")
notifGui.Name = rndName()
notifGui.Parent = getHui()
notifGui.ResetOnSpawn = false
notifGui.DisplayOrder = 998

local function notify(text, duration)
	task.spawn(function()
		local n = Instance.new("TextLabel")
		n.Size = UDim2.new(0, 0, 0, 28)
		n.Position = UDim2.new(0.5, 0, 0.85, 0)
		n.AnchorPoint = Vector2.new(0.5, 0.5)
		n.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
		n.TextColor3 = Color3.fromRGB(0, 200, 255)
		n.Text = text
		n.Font = Enum.Font.Gotham
		n.TextSize = 13
		n.BorderSizePixel = 0
		n.Parent = notifGui
		n.Size = UDim2.new(0, n.TextBounds.X + 20, 0, 28)
		TweenService:Create(n, TweenInfo.new(0.2), {BackgroundTransparency = 0.1}):Play()
		task.wait(duration or 2)
		TweenService:Create(n, TweenInfo.new(0.3), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
		task.wait(0.3)
		n:Destroy()
	end)
end

-- ===== Color Map =====
local colorMap = {
	accent = theme.accent,
	red = Color3.fromRGB(255, 0, 0),
	green = Color3.fromRGB(0, 255, 0),
	blue = Color3.fromRGB(0, 100, 255),
	yellow = Color3.fromRGB(255, 255, 0),
	purple = Color3.fromRGB(180, 0, 255),
	white = Color3.fromRGB(255, 255, 255),
	black = Color3.fromRGB(0, 0, 0),
	cyan = Color3.fromRGB(0, 255, 255),
	pink = Color3.fromRGB(255, 100, 200),
	orange = Color3.fromRGB(255, 165, 0),
}
local function getESPColor(key)
	return colorMap[cfg.ESP[key]] or theme.accent
end

-- ===== UI Theme =====
local theme = {
	bg = Color3.fromRGB(12, 12, 18), panelBg = Color3.fromRGB(18, 18, 25), sideBg = Color3.fromRGB(10, 10, 15),
	titleBg = Color3.fromRGB(6, 6, 10), accent = Color3.fromRGB(0, 180, 255), accentDim = Color3.fromRGB(0, 90, 160),
	btnOn = Color3.fromRGB(0, 150, 55), btnOff = Color3.fromRGB(150, 35, 35), text = Color3.fromRGB(235, 235, 240),
	textDim = Color3.fromRGB(120, 120, 140), sliderFill = Color3.fromRGB(0, 130, 210), sliderBg = Color3.fromRGB(35, 35, 45),
	inputBg = Color3.fromRGB(30, 30, 40), closeBtn = Color3.fromRGB(190, 40, 40),
}

-- ===== UI Builders =====
local function createToggle(parent, text, configTable, key, callback)
	local f = Instance.new("Frame"); f.Size = UDim2.new(1, -10, 0, 30); f.BackgroundTransparency = 1; f.Parent = parent
	local b = Instance.new("TextButton"); b.Size = UDim2.new(0, 44, 0, 20); b.Position = UDim2.new(0, 0, 0, 5); b.BorderSizePixel = 0; b.Parent = f
	local l = Instance.new("TextLabel"); l.Size = UDim2.new(1, -54, 0, 30); l.Position = UDim2.new(0, 54, 0, 0); l.BackgroundTransparency = 1; l.TextColor3 = theme.text; l.Text = text; l.Font = Enum.Font.Gotham; l.TextSize = 13; l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = f
	local function upd() b.BackgroundColor3 = configTable[key] and theme.btnOn or theme.btnOff end
	upd()
	b.MouseButton1Click:Connect(function() configTable[key] = not configTable[key]; upd(); if callback then pcall(callback, configTable[key]) end end)
	task.defer(function() if callback then pcall(callback, configTable[key]) end end)
	return f
end

local function createSlider(parent, text, configTable, key, min, max, callback)
	local f = Instance.new("Frame"); f.Size = UDim2.new(1, -10, 0, 48); f.BackgroundTransparency = 1; f.Parent = parent
	local val = configTable[key] or min; local range = math.max(max - min, 1)
	local l = Instance.new("TextLabel"); l.Size = UDim2.new(1, 0, 0, 20); l.BackgroundTransparency = 1; l.TextColor3 = theme.text; l.Text = text..": "..val; l.Font = Enum.Font.Gotham; l.TextSize = 13; l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = f
	local bar = Instance.new("Frame"); bar.Size = UDim2.new(1, 0, 0, 6); bar.Position = UDim2.new(0, 0, 0, 24); bar.BackgroundColor3 = theme.sliderBg; bar.BorderSizePixel = 0; bar.Parent = f
	local fill = Instance.new("Frame"); fill.Size = UDim2.new((val-min)/range, 0, 1, 0); fill.BackgroundColor3 = theme.sliderFill; fill.BorderSizePixel = 0; fill.Parent = bar
	local knob = Instance.new("TextButton"); knob.Size = UDim2.new(0, 14, 0, 14); knob.Position = UDim2.new((val-min)/range, -7, 0.5, -7); knob.BackgroundColor3 = Color3.fromRGB(255,255,255); knob.Text = ""; knob.BorderSizePixel = 0; knob.Parent = bar
	local dragging = false
	local function update(inp)
		local p = math.clamp((inp.Position.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
		local v = math.floor(min + range * p); knob.Position = UDim2.new(p, -7, 0.5, -7); fill.Size = UDim2.new(p, 0, 1, 0); l.Text = text..": "..v; configTable[key] = v
		if callback then pcall(callback, v) end
	end
	knob.MouseButton1Down:Connect(function() dragging = true end)
	local c1 = UserInputService.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
	local c2 = UserInputService.InputChanged:Connect(function(inp) if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then update({Position = Vector2.new(inp.Position.X, inp.Position.Y)}) end end)
	pcall(function() f.Destroying:Connect(function() c1:Disconnect(); c2:Disconnect() end) end)
	task.defer(function() if callback then pcall(callback, val) end end)
	return f
end

local function createButton(parent, text, callback)
	local b = Instance.new("TextButton"); b.Size = UDim2.new(1, -10, 0, 30); b.BackgroundColor3 = theme.inputBg; b.TextColor3 = theme.text; b.Text = text; b.Font = Enum.Font.Gotham; b.TextSize = 13; b.BorderSizePixel = 0; b.Parent = parent
	b.MouseButton1Click:Connect(function() pcall(callback) end)
	return b
end

local function createDropdown(parent, text, options, configTable, key, callback, skipInit)
	local f = Instance.new("Frame"); f.Size = UDim2.new(1, -10, 0, 30); f.BackgroundTransparency = 1; f.Parent = parent
	local l = Instance.new("TextLabel"); l.Size = UDim2.new(0.45, 0, 1, 0); l.BackgroundTransparency = 1; l.TextColor3 = theme.text; l.Text = text; l.Font = Enum.Font.Gotham; l.TextSize = 13; l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = f
	local btn = Instance.new("TextButton"); btn.Size = UDim2.new(0.55, -5, 0, 24); btn.Position = UDim2.new(0.45, 0, 0, 3); btn.BackgroundColor3 = theme.inputBg; btn.TextColor3 = theme.text; btn.Text = configTable[key] or options[1]; btn.Font = Enum.Font.Gotham; btn.TextSize = 12; btn.BorderSizePixel = 0; btn.Parent = f
	local idx = 0
	btn.MouseButton1Click:Connect(function() idx = idx % #options + 1; configTable[key] = options[idx]; btn.Text = options[idx]; if callback then pcall(callback, options[idx]) end end)
	task.defer(function() if callback and not skipInit then pcall(callback, configTable[key] or options[1]) end end)
	return f
end

-- ===== Forward Declarations =====
local disableAllFeatures, stopAimbot, removeESP
local chamsHL = {}

-- ===== GUI =====
local guiDestroyed = false
local gui = Instance.new("ScreenGui"); gui.Name = rndName(); gui.Parent = getHui(); gui.ResetOnSpawn = false; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; gui.Enabled = true

-- Watermark
local watermark = Instance.new("TextLabel")
watermark.Size = UDim2.new(0, 160, 0, 20); watermark.Position = UDim2.new(0, 10, 0, 10); watermark.BackgroundTransparency = 1
watermark.Text = "LowspecistHUB v1pro"; watermark.TextColor3 = Color3.fromRGB(0, 180, 255); watermark.Font = Enum.Font.Code; watermark.TextSize = 14; watermark.TextXAlignment = Enum.TextXAlignment.Left
watermark.TextStrokeTransparency = 0.5; watermark.TextStrokeColor3 = Color3.fromRGB(0, 0, 0); watermark.Parent = gui

local mainFrame = Instance.new("Frame"); mainFrame.Size = UDim2.new(0, 580, 0, 420); mainFrame.Position = UDim2.new(0.5, -290, 0.5, -210); mainFrame.BackgroundColor3 = theme.bg; mainFrame.BorderSizePixel = 0; mainFrame.ClipsDescendants = true; mainFrame.Parent = gui

-- Title bar
local titleBar = Instance.new("Frame"); titleBar.Size = UDim2.new(1, 0, 0, 30); titleBar.BackgroundColor3 = theme.titleBg; titleBar.BorderSizePixel = 0; titleBar.Parent = mainFrame
local title = Instance.new("TextLabel"); title.Size = UDim2.new(1, -35, 1, 0); title.BackgroundTransparency = 1; title.TextColor3 = theme.accent; title.Text = "LowspecistHUB v1pro"; title.Font = Enum.Font.Code; title.TextSize = 14; title.Parent = titleBar
local closeBtn = Instance.new("TextButton"); closeBtn.Size = UDim2.new(0, 30, 0, 30); closeBtn.Position = UDim2.new(1, -30, 0, 0); closeBtn.BackgroundColor3 = theme.closeBtn; closeBtn.TextColor3 = Color3.fromRGB(255,255,255); closeBtn.Text = "X"; closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextSize = 13; closeBtn.BorderSizePixel = 0; closeBtn.Parent = titleBar
closeBtn.MouseButton1Click:Connect(function() guiDestroyed=true; disableAllFeatures(); cleanConns(); stopAimbot(); removeESP(); for _,hl in ipairs(chamsHL) do pcall(function() hl:Destroy() end) end; gui:Destroy() end)

-- Drag
local dragging, dragStart, frameStart = false, nil, nil
titleBar.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; dragStart=input.Position; frameStart=mainFrame.Position; input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then dragging=false end end) end end)
UserInputService.InputChanged:Connect(function(input) if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then local d=input.Position-dragStart; mainFrame.Position=UDim2.new(frameStart.X.Scale,frameStart.X.Offset+d.X,frameStart.Y.Scale,frameStart.Y.Offset+d.Y) end end)

-- Side panel
local sidePanel = Instance.new("ScrollingFrame"); sidePanel.Size=UDim2.new(0,130,1,-30); sidePanel.Position=UDim2.new(0,0,0,30); sidePanel.BackgroundColor3=theme.sideBg; sidePanel.BorderSizePixel=0; sidePanel.ScrollBarThickness=3; sidePanel.ScrollBarImageColor3=theme.accent; sidePanel.CanvasSize=UDim2.new(0,0,0,0); sidePanel.Parent=mainFrame
local sideLayout = Instance.new("UIListLayout"); sideLayout.Parent=sidePanel; sideLayout.SortOrder=Enum.SortOrder.LayoutOrder; sideLayout.Padding=UDim.new(0,3)
sideLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() sidePanel.CanvasSize=UDim2.new(0,0,0,sideLayout.AbsoluteContentSize.Y+10) end)

-- Content
local contentContainer = Instance.new("ScrollingFrame"); contentContainer.Size=UDim2.new(1,-130,1,-30); contentContainer.Position=UDim2.new(0,130,0,30); contentContainer.BackgroundColor3=theme.panelBg; contentContainer.BorderSizePixel=0; contentContainer.ScrollBarThickness=3; contentContainer.ScrollBarImageColor3=theme.accent; contentContainer.CanvasSize=UDim2.new(0,0,0,0); contentContainer.ClipsDescendants=true; contentContainer.Parent=mainFrame

-- ===== Categories =====
local categories = {"Movement","Visual","Combat","Player","Server","Extra"}
local categoryButtons, categoryFrames, selectedCategory = {}, {}, nil

local function switchCategory(name)
	if selectedCategory==name then return end; selectedCategory=name
	for _,e in ipairs(categoryButtons) do e.button.BackgroundColor3=(e.category==name) and theme.accentDim or theme.sideBg; e.button.TextColor3=(e.category==name) and Color3.fromRGB(255,255,255) or theme.textDim end
	for cat,frame in pairs(categoryFrames) do frame.Visible=(cat==name) end
	task.defer(function() local vf=categoryFrames[name]; if vf then local lay=vf:FindFirstChildOfClass("UIListLayout"); if lay then contentContainer.CanvasSize=UDim2.new(0,0,0,lay.AbsoluteContentSize.Y+20) end end end)
end

for i,cat in ipairs(categories) do
	local btn=Instance.new("TextButton"); btn.Size=UDim2.new(1,-6,0,30); btn.BackgroundColor3=theme.sideBg; btn.TextColor3=theme.textDim; btn.Text=cat; btn.Font=Enum.Font.Gotham; btn.TextSize=13; btn.BorderSizePixel=0; btn.LayoutOrder=i; btn.Parent=sidePanel
	table.insert(categoryButtons,{button=btn,category=cat}); btn.MouseButton1Click:Connect(function() switchCategory(cat) end)
	local frame=Instance.new("Frame"); frame.Size=UDim2.new(1,0,1,0); frame.BackgroundTransparency=1; frame.Visible=false; frame.Parent=contentContainer
	local fl=Instance.new("UIListLayout"); fl.Parent=frame; fl.SortOrder=Enum.SortOrder.LayoutOrder; fl.Padding=UDim.new(0,3); categoryFrames[cat]=frame
end
switchCategory("Movement")

-- ===== Module Variables =====
local noclipConn, ijConn, flyEnabled, flyBodyGyro, flyBodyVel, flyHeartbeat
local espDrawings, espName = {}, rndName()
local aimbotActive, aimbotName = false, rndName()
local fovCircle, chamsHL2 = nil, {}
local spinConn, spinAngle = nil, 0
local originalLighting = nil
local godmodeConns = {}
local speedForceConn = nil
local espFrameCount = 0
local crosshairDrawings = {}
local serverInfoLabel = nil

-- ===== FLY =====
local function startFly()
	if flyEnabled then return end
	local char=LocalPlayer.Character; if not char then return end
	local hum=char:FindFirstChild("Humanoid"); local root=char:FindFirstChild("HumanoidRootPart")
	if not hum or not root then return end
	flyBodyGyro=Instance.new("BodyGyro"); flyBodyGyro.MaxTorque=Vector3.new(400000,400000,400000); flyBodyGyro.P=30000; flyBodyGyro.CFrame=root.CFrame; flyBodyGyro.Parent=root
	flyBodyVel=Instance.new("BodyVelocity"); flyBodyVel.MaxForce=Vector3.new(400000,400000,400000); flyBodyVel.Velocity=Vector3.zero; flyBodyVel.Parent=root
	hum.PlatformStand=true; flyEnabled=true
	flyHeartbeat=RunService.Heartbeat:Connect(function()
		if not flyEnabled then return end
		local dir=Vector3.zero; local cf=Camera.CFrame
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir+=cf.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir-=cf.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir-=cf.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir+=cf.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir+=Vector3.new(0,1,0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir-=Vector3.new(0,1,0) end
		flyBodyVel.Velocity=(dir.Magnitude>0 and dir.Unit or Vector3.zero)*cfg.Fly.speed
		flyBodyGyro.CFrame=CFrame.new(Vector3.zero,cf.LookVector)
	end)
	regConn(flyHeartbeat)
end
local function stopFly()
	if not flyEnabled then return end; flyEnabled=false
	if flyHeartbeat then flyHeartbeat:Disconnect(); flyHeartbeat=nil end
	if flyBodyGyro then pcall(function() flyBodyGyro:Destroy() end); flyBodyGyro=nil end
	if flyBodyVel then pcall(function() flyBodyVel:Destroy() end); flyBodyVel=nil end
	local ch=LocalPlayer.Character; if ch and ch:FindFirstChild("Humanoid") then ch.Humanoid.PlatformStand=false end
end

-- ===== ESP =====
local function safeDrawing(type) local ok,d=pcall(function() return Drawing.new(type) end); return ok and d or nil end
local function jitter() return (math.random()-0.5)*0.4 end
removeESP=function()
	pcall(function() RunService:UnbindFromRenderStep(espName) end)
	for _,d in ipairs(espDrawings) do pcall(function() d:Remove() end) end; espDrawings={}
end
local function createESP()
	removeESP(); if not cfg.ESP.enabled then return end
	espFrameCount=0
	RunService:BindToRenderStep(espName,1,function()
		-- Throttle: her 2. frame'de güncelle
		espFrameCount=espFrameCount+1
		if cfg.ESP.throttle and espFrameCount%2~=0 then return end
		for _,d in ipairs(espDrawings) do pcall(function() d:Remove() end) end; espDrawings={}
		pcall(function()
			local myTeam=LocalPlayer.Team; local myRoot=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			for _,p in ipairs(Players:GetPlayers()) do
				if p~=LocalPlayer then
					if cfg.ESP.teamCheck and p.Team==myTeam then continue end
					local ch=p.Character
					if ch and ch:FindFirstChild("Head") and ch:FindFirstChild("HumanoidRootPart") and ch:FindFirstChild("Humanoid") then
						if ch.Humanoid.Health<=0 then continue end
						local hp,onScr=Camera:WorldToViewportPoint(ch.Head.Position); if not onScr then continue end
						local fp=Camera:WorldToViewportPoint((ch.HumanoidRootPart.CFrame*CFrame.new(0,-3,0)).Position)
						local boxH=math.abs(fp.Y-hp.Y); if boxH<=0 then continue end
						if cfg.ESP.box then
							if cfg.ESP.boxStyle=="Corner" then
								local sw=boxH/2; local cs=math.max(sw*0.2,4)
								local corners={{Vector2.new(hp.X-sw/2,hp.Y),Vector2.new(hp.X-sw/2+cs,hp.Y),Vector2.new(hp.X-sw/2,hp.Y+cs)},{Vector2.new(hp.X+sw/2,hp.Y),Vector2.new(hp.X+sw/2-cs,hp.Y),Vector2.new(hp.X+sw/2,hp.Y+cs)},{Vector2.new(hp.X-sw/2,hp.Y+boxH),Vector2.new(hp.X-sw/2+cs,hp.Y+boxH),Vector2.new(hp.X-sw/2,hp.Y+boxH-cs)},{Vector2.new(hp.X+sw/2,hp.Y+boxH),Vector2.new(hp.X+sw/2-cs,hp.Y+boxH),Vector2.new(hp.X+sw/2,hp.Y+boxH-cs)}}
								for _,c in ipairs(corners) do
									local ln=safeDrawing("Line"); if ln then ln.Visible=true; ln.Color=getESPColor("boxColor"); ln.Thickness=2; ln.From=c[1]; ln.To=c[2]; table.insert(espDrawings,ln) end
									local ln2=safeDrawing("Line"); if ln2 then ln2.Visible=true; ln2.Color=getESPColor("boxColor"); ln2.Thickness=2; ln2.From=c[1]; ln2.To=c[3]; table.insert(espDrawings,ln2) end
								end
							else local bx=safeDrawing("Square"); if bx then bx.Visible=true; bx.Color=getESPColor("boxColor"); bx.Thickness=1; bx.Filled=false; bx.Position=Vector2.new(hp.X-boxH/4+jitter(),hp.Y+jitter()); bx.Size=Vector2.new(boxH/2,boxH); table.insert(espDrawings,bx) end end
						end
						if cfg.ESP.name then local nm=safeDrawing("Text"); if nm then nm.Visible=true; nm.Color=getESPColor("nameColor"); nm.Center=true; nm.Outline=true; nm.Size=14; nm.Position=Vector2.new(hp.X+jitter(),hp.Y-12); nm.Text=p.Name; table.insert(espDrawings,nm) end end
						if cfg.ESP.health then local hm=ch.Humanoid; if hm.MaxHealth>0 then local hpPct=hm.Health/hm.MaxHealth; local hbBg=safeDrawing("Square"); if hbBg then hbBg.Filled=true; hbBg.Position=Vector2.new(hp.X-boxH/2-6,hp.Y); hbBg.Size=Vector2.new(3,boxH); hbBg.Color=Color3.fromRGB(0,0,0); table.insert(espDrawings,hbBg) end; local hb=safeDrawing("Square"); if hb then hb.Filled=true; hb.Position=Vector2.new(hp.X-boxH/2-6,hp.Y+boxH*(1-hpPct)); hb.Size=Vector2.new(3,boxH*hpPct); hb.Color=Color3.fromRGB(255*(1-hpPct),255*hpPct,0); table.insert(espDrawings,hb) end end end
						if cfg.ESP.distance then local dd=safeDrawing("Text"); if dd then dd.Visible=true; dd.Color=theme.textDim; dd.Center=true; dd.Size=12; local dist=myRoot and math.floor((myRoot.Position-ch.HumanoidRootPart.Position).Magnitude) or 0; dd.Position=Vector2.new(hp.X,hp.Y+boxH+4); dd.Text=dist.."m"; table.insert(espDrawings,dd) end end
						if cfg.ESP.tracers then local tr=safeDrawing("Line"); if tr then tr.Visible=true; tr.Color=theme.accent; tr.Thickness=1; local sm=myRoot and Camera:WorldToViewportPoint(myRoot.Position); local st=Camera:WorldToViewportPoint(ch.HumanoidRootPart.Position); if sm and sm.Z>0 and st.Z>0 then tr.From=Vector2.new(sm.X,sm.Y); tr.To=Vector2.new(st.X,st.Y) end; table.insert(espDrawings,tr) end end
						if cfg.ESP.snaplines then local sl=safeDrawing("Line"); if sl then sl.Visible=true; sl.Color=theme.accent; sl.Thickness=1; sl.Transparency=0.5; local bot=Camera:WorldToViewportPoint(ch.HumanoidRootPart.Position); sl.From=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y); sl.To=Vector2.new(bot.X+jitter(),bot.Y+jitter()); table.insert(espDrawings,sl) end end
						if cfg.ESP.headDot then local hd=safeDrawing("Circle"); if hd then hd.Visible=true; hd.Color=Color3.fromRGB(255,255,255); hd.Filled=true; hd.Radius=3; hd.Position=Vector2.new(hp.X+jitter(),hp.Y+jitter()); table.insert(espDrawings,hd) end end
						if cfg.ESP.skeleton then
							local function skLine(a,b) local pa,va=Camera:WorldToViewportPoint(a); local pb,vb=Camera:WorldToViewportPoint(b); if va and vb then local ln=safeDrawing("Line"); if ln then ln.Visible=true; ln.Color=Color3.fromRGB(180,180,180); ln.Thickness=1; ln.From=Vector2.new(pa.X+jitter(),pa.Y+jitter()); ln.To=Vector2.new(pb.X+jitter(),pb.Y+jitter()); table.insert(espDrawings,ln) end end end
							local head=ch:FindFirstChild("Head"); local torso=ch:FindFirstChild("Torso") or ch:FindFirstChild("UpperTorso")
							local ra=ch:FindFirstChild("Right Arm") or ch:FindFirstChild("RightUpperArm"); local la=ch:FindFirstChild("Left Arm") or ch:FindFirstChild("LeftUpperArm")
							local rl=ch:FindFirstChild("Right Leg") or ch:FindFirstChild("RightUpperLeg"); local ll=ch:FindFirstChild("Left Leg") or ch:FindFirstChild("LeftUpperLeg")
							if head and torso then skLine(head.Position,torso.Position); if ra then skLine(torso.Position,ra.Position) end; if la then skLine(torso.Position,la.Position) end; if rl then skLine(torso.Position,rl.Position) end; if ll then skLine(torso.Position,ll.Position) end end
						end
					end
				end
			end
		end)
	end)
end

-- ===== CROSSHAIR =====
local function updateCrosshair()
	for _,d in ipairs(crosshairDrawings) do pcall(function() d:Remove() end) end; crosshairDrawings={}
	if not cfg.ESP.crosshair then return end
	local cx=Camera.ViewportSize.X/2; local cy=Camera.ViewportSize.Y/2; local s=10; local gap=4
	local lines={{Vector2.new(cx-gap,cy),Vector2.new(cx-gap-s,cy)},{Vector2.new(cx+gap,cy),Vector2.new(cx+gap+s,cy)},{Vector2.new(cx,cy-gap),Vector2.new(cx,cy-gap-s)},{Vector2.new(cx,cy+gap),Vector2.new(cx,cy+gap+s)}}
	for _,l in ipairs(lines) do local ln=safeDrawing("Line"); if ln then ln.Visible=true; ln.Color=Color3.fromRGB(255,255,255); ln.Thickness=1; ln.From=l[1]; ln.To=l[2]; table.insert(crosshairDrawings,ln) end end
end

-- ===== CHAMS =====
local function applyChams()
	for _,hl in ipairs(chamsHL) do pcall(function() hl:Destroy() end) end; chamsHL={}
	if not cfg.ESP.chams then return end
	for _,p in ipairs(Players:GetPlayers()) do
		if p~=LocalPlayer and p.Character then
			local hl=Instance.new("Highlight"); hl.Name=rndName(); hl.FillColor=theme.accent; hl.OutlineColor=theme.accent; hl.FillTransparency=0.5; hl.OutlineTransparency=0; hl.Parent=p.Character
			table.insert(chamsHL,hl)
		end
	end
end
-- Auto-refresh chams on player join/leave
Players.PlayerAdded:Connect(function(p)
	p.CharacterAdded:Connect(function()
		task.wait(1)
		if cfg.ESP.chams then applyChams() end
	end)
end)
Players.PlayerRemoving:Connect(function()
	if cfg.ESP.chams then task.defer(function() applyChams() end) end
end)

-- ===== AIMBOT =====
local aimbotHolding = false
-- Bind key detection
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.UserInputType.Name == cfg.Aimbot.bindKey or input.KeyCode.Name == cfg.Aimbot.bindKey then
		aimbotHolding = true
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType.Name == cfg.Aimbot.bindKey or input.KeyCode.Name == cfg.Aimbot.bindKey then
		aimbotHolding = false
	end
end)

local function startAimbot()
	if aimbotActive then return end; aimbotActive=true
	if cfg.Aimbot.showFOV then fovCircle=safeDrawing("Circle"); if fovCircle then fovCircle.Visible=true; fovCircle.Color=theme.accent; fovCircle.Thickness=1; fovCircle.Filled=false; fovCircle.Radius=cfg.Aimbot.fov; fovCircle.Position=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2) end end
	RunService:BindToRenderStep(aimbotName,2,function()
		pcall(function()
			if fovCircle then fovCircle.Radius=cfg.Aimbot.fov; fovCircle.Position=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2) end
			if cfg.ESP.crosshair then updateCrosshair() end
			if not cfg.Aimbot.enabled then return end
			if not aimbotHolding then return end -- Sadece tuşa basılıyken çalış
			local myRoot=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			if not myRoot then return end
			local myTeam=LocalPlayer.Team; local best, bestDist=nil, cfg.Aimbot.fov
			local sc=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
			for _,p in ipairs(Players:GetPlayers()) do
				if p~=LocalPlayer then
					if cfg.Aimbot.teamCheck and p.Team==myTeam then continue end
					local ch=p.Character
					if ch and ch:FindFirstChild("Head") and ch:FindFirstChild("Humanoid") and ch.Humanoid.Health>0 then
						local targetPos=ch.Head.Position
						-- Prediction: hedefin hızına göre öngörü
						if cfg.Aimbot.prediction then
							local hrp=ch:FindFirstChild("HumanoidRootPart")
							if hrp then targetPos=targetPos+hrp.Velocity*0.1 end
						end
						local sp,onS=Camera:WorldToViewportPoint(targetPos)
						if onS then local d=(Vector2.new(sp.X,sp.Y)-sc).Magnitude; if d<bestDist then bestDist=d; best={player=p,predictedPos=targetPos} end end
					end
				end
			end
			if best then
				local targetPos=best.predictedPos
				Camera.CFrame=Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position,targetPos),cfg.Aimbot.smooth)
			end
		end)
	end)
end
stopAimbot=function()
	aimbotActive=false; pcall(function() RunService:UnbindFromRenderStep(aimbotName) end)
	if fovCircle then pcall(function() fovCircle:Remove() end); fovCircle=nil end
	for _,d in ipairs(crosshairDrawings) do pcall(function() d:Remove() end) end; crosshairDrawings={}
end

-- ===== FULLBRIGHT =====
local function enableFullbright(on)
	if on then
		if not originalLighting then originalLighting={Brightness=Lighting.Brightness,ClockTime=Lighting.ClockTime,FogEnd=Lighting.FogEnd,GlobalShadows=Lighting.GlobalShadows,Ambient=Lighting.Ambient} end
		Lighting.Brightness=2; Lighting.ClockTime=14; Lighting.FogEnd=100000; Lighting.GlobalShadows=false; Lighting.Ambient=Color3.fromRGB(178,178,178)
	else
		if originalLighting then Lighting.Brightness=originalLighting.Brightness; Lighting.ClockTime=originalLighting.ClockTime; Lighting.FogEnd=originalLighting.FogEnd; Lighting.GlobalShadows=originalLighting.GlobalShadows; Lighting.Ambient=originalLighting.Ambient; originalLighting=nil end
	end
end

-- ===== GODMODE (safe) =====
local function applyGodmode(on)
	for _,c in ipairs(godmodeConns) do pcall(function() c:Disconnect() end) end; godmodeConns={}
	if on then
		local function setup(char)
			local hum=char:WaitForChild("Humanoid",5); if not hum then return end
			hum.BreakJointsOnDeath=false
			pcall(function() hum.RequiresNeck=false end)
			local maxHP=hum.MaxHealth
			local c1=hum.HealthChanged:Connect(function(newHP)
				if not cfg.Player.godmode then return end
				if newHP<maxHP then task.defer(function() pcall(function() if hum and hum.Parent then hum.Health=maxHP; hum.BreakJointsOnDeath=false end end) end) end
			end)
			table.insert(godmodeConns,c1)
			local c2=hum.StateChanged:Connect(function(_,newState)
				if not cfg.Player.godmode then return end
				if newState==Enum.HumanoidStateType.Dead then pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end) end
			end)
			table.insert(godmodeConns,c2)
		end
		if LocalPlayer.Character then setup(LocalPlayer.Character) end
		local c=LocalPlayer.CharacterAdded:Connect(function(char) task.wait(0.5); setup(char) end)
		table.insert(godmodeConns,c)
	end
end

-- ===== SPEED FORCE =====
local function startSpeedForce()
	if speedForceConn then return end
	speedForceConn=RunService.Heartbeat:Connect(function()
		local ch=LocalPlayer.Character
		if ch and ch:FindFirstChild("Humanoid") then
			local hum=ch.Humanoid
			if hum.WalkSpeed~=cfg.Movement.walkSpeed then hum.WalkSpeed=cfg.Movement.walkSpeed end
			if hum.JumpPower~=cfg.Movement.jumpPower then hum.JumpPower=cfg.Movement.jumpPower end
		end
	end)
	regConn(speedForceConn)
end
local function stopSpeedForce() if speedForceConn then speedForceConn:Disconnect(); speedForceConn=nil end end

-- ===== ANTI-AFK =====
local function enableAntiAFK()
	local c=LocalPlayer.Idled:Connect(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end)
	regConn(c)
end

-- ===== SERVER INFO =====
local function updateServerInfo()
	if not serverInfoLabel or not serverInfoLabel.Parent then return end
	local ping = LocalPlayer:GetNetworkPing()
	local playerCount = #Players:GetPlayers()
	serverInfoLabel.Text = string.format("Ping: %dms | Players: %d | Server: %s", math.floor(ping*1000), playerCount, game.JobId:sub(1,8))
end

-- ===== DISABLE ALL =====
disableAllFeatures=function()
	if flyEnabled then stopFly() end
	if noclipConn then noclipConn:Disconnect(); noclipConn=nil; cfg.Movement.noclip=false end
	if ijConn then ijConn:Disconnect(); ijConn=nil; cfg.Movement.infiniteJump=false end
	if spinConn then spinConn:Disconnect(); spinConn=nil; cfg.Movement.spinBot=false end
	if cfg.Player.godmode then cfg.Player.godmode=false; applyGodmode(false) end
	stopSpeedForce()
	if cfg.ESP.enabled then cfg.ESP.enabled=false; removeESP() end
	if cfg.ESP.crosshair then cfg.ESP.crosshair=false; for _,d in ipairs(crosshairDrawings) do pcall(function() d:Remove() end) end; crosshairDrawings={} end
	if cfg.ESP.chams then cfg.ESP.chams=false; for _,hl in ipairs(chamsHL) do pcall(function() hl:Destroy() end) end; chamsHL={} end
	if cfg.Aimbot.enabled then cfg.Aimbot.enabled=false; stopAimbot() end
	if cfg.Server.fullbright then cfg.Server.fullbright=false; enableFullbright(false) end
	if cfg.Movement.gravity~=196.2 then cfg.Movement.gravity=196.2; Workspace.Gravity=196.2 end
	local ch=LocalPlayer.Character
	if ch and ch:FindFirstChild("Humanoid") then ch.Humanoid.WalkSpeed=16; ch.Humanoid.JumpPower=50; cfg.Movement.walkSpeed=16; cfg.Movement.jumpPower=50 end
end

-- ===== TOGGLE GUI (RightCtrl + X) + PANIC KEY =====
UserInputService.InputBegan:Connect(function(input,gp)
	if guiDestroyed then return end; if gp then return end
	-- Panic Key: P tuşu — tüm özellikleri anında kapat
	if input.KeyCode==Enum.KeyCode.P then disableAllFeatures(); notify("PANIC: Tüm özellikler kapatıldı",1.5); return end
	if input.KeyCode==Enum.KeyCode.RightControl then if gui.Enabled then disableAllFeatures(); gui.Enabled=false; notify("GUI kapatıldı",1) else gui.Enabled=true; notify("GUI açıldı",1) end end
	if input.KeyCode==Enum.KeyCode.X then guiDestroyed=true; disableAllFeatures(); cleanConns(); stopAimbot(); removeESP(); for _,hl in ipairs(chamsHL) do pcall(function() hl:Destroy() end) end; gui:Destroy() end
end)

-- ===== FILL CATEGORIES =====
do
	-- MOVEMENT
	local mf=categoryFrames["Movement"]
	createToggle(mf,"Fly",cfg.Fly,"enabled",function(on) if on then startFly() else stopFly() end end)
	createSlider(mf,"Fly Speed",cfg.Fly,"speed",10,200)
	createSlider(mf,"WalkSpeed",cfg.Movement,"walkSpeed",1,1000,function(val) local ch=LocalPlayer.Character; if ch and ch:FindFirstChild("Humanoid") then ch.Humanoid.WalkSpeed=val end end)
	createSlider(mf,"JumpPower",cfg.Movement,"jumpPower",0,2000,function(val) local ch=LocalPlayer.Character; if ch and ch:FindFirstChild("Humanoid") then ch.Humanoid.JumpPower=val end end)
	createSlider(mf,"Gravity",cfg.Movement,"gravity",0,500,function(val) Workspace.Gravity=val end)
	createToggle(mf,"JumpHeight",cfg.Movement,"jumpHeight",function(on) local ch=LocalPlayer.Character; if ch and ch:FindFirstChild("Humanoid") then ch.Humanoid.UseJumpPower=not on; if on then ch.Humanoid.JumpHeight=50 else ch.Humanoid.JumpPower=cfg.Movement.jumpPower end end end)
	createToggle(mf,"Infinite Jump",cfg.Movement,"infiniteJump",function(on) if ijConn then ijConn:Disconnect(); ijConn=nil end; if on then ijConn=UserInputService.JumpRequest:Connect(function() local c=LocalPlayer.Character; if c and c:FindFirstChild("Humanoid") then c.Humanoid.Jump=true end end); regConn(ijConn) end end)
	createToggle(mf,"NoClip",cfg.Movement,"noclip",function(on) if noclipConn then noclipConn:Disconnect(); noclipConn=nil end; if on then noclipConn=RunService.Stepped:Connect(function() local c=LocalPlayer.Character; if c then for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end end); regConn(noclipConn) end end)
	createToggle(mf,"Spin Bot",cfg.Movement,"spinBot",function(on) if spinConn then spinConn:Disconnect(); spinConn=nil end; if on then spinAngle=0; spinConn=RunService.Heartbeat:Connect(function(dt) spinAngle=spinAngle+dt*360; local ch=LocalPlayer.Character; if ch and ch:FindFirstChild("HumanoidRootPart") then ch.HumanoidRootPart.CFrame=CFrame.new(ch.HumanoidRootPart.Position)*CFrame.Angles(0,math.rad(spinAngle),0) end end); regConn(spinConn) end end)
	createButton(mf,"Speed Force (toggle)",function() if speedForceConn then stopSpeedForce(); cfg.Movement.speedForce=false; notify("Speed Force kapatıldı",1) else startSpeedForce(); cfg.Movement.speedForce=true; notify("Speed Force açıldı",1) end end)

	-- VISUAL
	local vf=categoryFrames["Visual"]
	createToggle(vf,"ESP Master",cfg.ESP,"enabled",function() createESP() end)
	createToggle(vf,"Box",cfg.ESP,"box",function() createESP() end)
	createDropdown(vf,"Box Style",{"Corner","Full"},cfg.ESP,"boxStyle",function() createESP() end)
	createToggle(vf,"Name",cfg.ESP,"name",function() createESP() end)
	createToggle(vf,"Health",cfg.ESP,"health",function() createESP() end)
	createToggle(vf,"Distance",cfg.ESP,"distance",function() createESP() end)
	createToggle(vf,"Tracers",cfg.ESP,"tracers",function() createESP() end)
	createToggle(vf,"Snaplines",cfg.ESP,"snaplines",function() createESP() end)
	createToggle(vf,"Head Dot",cfg.ESP,"headDot",function() createESP() end)
	createToggle(vf,"Skeleton",cfg.ESP,"skeleton",function() createESP() end)
	createToggle(vf,"Chams",cfg.ESP,"chams",function() applyChams() end)
	createToggle(vf,"Team Check",cfg.ESP,"teamCheck",function() createESP(); applyChams() end)
	createToggle(vf,"Crosshair",cfg.ESP,"crosshair",function() end)
	createToggle(vf,"Frame Throttle",cfg.ESP,"throttle",function() end)
	createToggle(vf,"Fullbright",cfg.Server,"fullbright",function(on) enableFullbright(on) end)

	-- COMBAT
	local cf=categoryFrames["Combat"]
	createToggle(cf,"Aimbot",cfg.Aimbot,"enabled",function(on) if on then startAimbot() else stopAimbot() end end)
	createSlider(cf,"FOV",cfg.Aimbot,"fov",10,360,function() if fovCircle then fovCircle.Radius=cfg.Aimbot.fov end end)
	createSlider(cf,"Smooth",cfg.Aimbot,"smooth",0.01,1)
	createToggle(cf,"Show FOV",cfg.Aimbot,"showFOV",function(on) if on and aimbotActive then fovCircle=safeDrawing("Circle"); if fovCircle then fovCircle.Visible=true; fovCircle.Color=theme.accent; fovCircle.Thickness=1; fovCircle.Filled=false; fovCircle.Radius=cfg.Aimbot.fov; fovCircle.Position=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2) end elseif fovCircle then pcall(function() fovCircle:Remove() end); fovCircle=nil end end)
	createToggle(cf,"Team Check",cfg.Aimbot,"teamCheck",function() end)
	createToggle(cf,"Prediction",cfg.Aimbot,"prediction",function() end)

	-- PLAYER
	local pf=categoryFrames["Player"]
	createToggle(pf,"Third Person",cfg.Player,"thirdPerson",function(on) pcall(function() local ch=LocalPlayer.Character; if ch and ch:FindFirstChild("Humanoid") then ch.Humanoid.CameraDistanceOffset=on and 12 or 0 end end) end)
	createToggle(pf,"FOV Changer",cfg.Player,"fovChanger",function(on) Camera.FieldOfView=on and 90 or 70 end)
	createToggle(pf,"Godmode (safe)",cfg.Player,"godmode",function(on) applyGodmode(on); notify(on and "Godmode açıldı" or "Godmode kapatıldı",1) end)

	-- SERVER
	local sf=categoryFrames["Server"]
	createButton(sf,"Rejoin",function() TeleportService:Teleport(game.PlaceId,LocalPlayer) end)
	createToggle(sf,"Anti-AFK",cfg.Server,"antiAFK",function(on) if on then enableAntiAFK(); notify("Anti-AFK açıldı",1) end end)
	serverInfoLabel=Instance.new("TextLabel"); serverInfoLabel.Size=UDim2.new(1,-10,0,25); serverInfoLabel.BackgroundTransparency=1; serverInfoLabel.TextColor3=theme.textDim; serverInfoLabel.Font=Enum.Font.Code; serverInfoLabel.TextSize=11; serverInfoLabel.TextXAlignment=Enum.TextXAlignment.Left; serverInfoLabel.Parent=sf
	RunService.Heartbeat:Connect(function() pcall(updateServerInfo) end)

	-- EXTRA
	local ef=categoryFrames["Extra"]
	createButton(ef,"Export Config",function() local json=HttpService:JSONEncode(cfg); if setclipboard then setclipboard(json); notify("Config kopyalandı",1) end end)
	createButton(ef,"Import Config",function() if getclipboard then local ok,data=pcall(function() return HttpService:JSONDecode(getclipboard()) end); if ok and data then for k,v in pairs(data) do if type(v)=="table" and type(cfg[k])=="table" then for sk,sv in pairs(v) do cfg[k][sk]=sv end else cfg[k]=v end end; notify("Config yüklendi",1) end end end)
	createToggle(ef,"Performance Mode",cfg.Performance,"mode",function(on) pcall(function() local s=UserSettings():GetService("UserGameSettings"); s.RenderingQualityLevel=on and Enum.QualityLevel.Level01 or Enum.QualityLevel.Level21 end) end)
	createButton(ef,"Destroy GUI",function() guiDestroyed=true; disableAllFeatures(); cleanConns(); stopAimbot(); removeESP(); for _,hl in ipairs(chamsHL) do pcall(function() hl:Destroy() end) end; gui:Destroy() end)

	-- ESP COLORS
	createDropdown(vf,"Box Color",{"accent","red","green","blue","yellow","purple","white","cyan","pink","orange"},cfg.ESP,"boxColor",function() createESP() end)
	createDropdown(vf,"Name Color",{"white","red","green","blue","yellow","purple","cyan","pink","orange"},cfg.ESP,"nameColor",function() createESP() end)

	-- AIMBOT SETTINGS
	createDropdown(cf,"Bind Key",{"MouseButton2","MouseButton3","E","Q","LeftShift","LeftControl"},cfg.Aimbot,"bindKey",function() end)
	createSlider(pf,"Third Person Dist",cfg.Player,"thirdPersonDist",5,30,function(val) pcall(function() local ch=LocalPlayer.Character; if ch and ch:FindFirstChild("Humanoid") and cfg.Player.thirdPerson then ch.Humanoid.CameraDistanceOffset=val end end) end)
	createSlider(pf,"FOV Value",cfg.Player,"fovValue",50,120,function(val) if cfg.Player.fovChanger then Camera.FieldOfView=val end end)

	-- ADMIN COMMANDS
	local af=categoryFrames["Admin"] or categoryFrames["Extra"]
	-- Komut listesi
	local cmdHelp=Instance.new("TextLabel")
	cmdHelp.Size=UDim2.new(1,-10,0,60); cmdHelp.BackgroundColor3=theme.inputBg; cmdHelp.TextColor3=theme.textDim
	cmdHelp.Text="Komutlar: fly|noclip|esp|aimbot|god|speed <n>|jump <n>|rejoin|bright|spin|3rd|gravity <n>|help"
	cmdHelp.Font=Enum.Font.Code; cmdHelp.TextSize=10; cmdHelp.TextWrapped=true; cmdHelp.TextYAlignment=Enum.TextYAlignment.Top; cmdHelp.Parent=ef
	local cmdBox=Instance.new("TextBox")
	cmdBox.Size=UDim2.new(1,-10,0,30); cmdBox.Position=UDim2.new(0,0,0,65); cmdBox.BackgroundColor3=theme.inputBg; cmdBox.TextColor3=theme.text
	cmdBox.PlaceholderText="komut yaz..."
	cmdBox.Font=Enum.Font.Code; cmdBox.TextSize=12; cmdBox.ClearTextOnFocus=true; cmdBox.Parent=ef
	cmdBox.FocusLost:Connect(function(ep)
		if not ep then return end
		local txt=cmdBox.Text:lower():gsub("^%s+",""):gsub("%s+$","")
		if txt=="help" then
			cmdHelp.Text="fly|noclip|esp|aimbot|god|speed <n>|jump <n>|gravity <n>|rejoin|bright|spin|3rd|chams|tracers|skeleton"
		elseif txt=="fly" then cfg.Fly.enabled=not cfg.Fly.enabled; if cfg.Fly.enabled then startFly() else stopFly() end; notify("Fly: "..tostring(cfg.Fly.enabled),1)
		elseif txt=="noclip" then cfg.Movement.noclip=not cfg.Movement.noclip; if cfg.Movement.noclip then noclipConn=RunService.Stepped:Connect(function() local c=LocalPlayer.Character; if c then for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end end); regConn(noclipConn) else if noclipConn then noclipConn:Disconnect(); noclipConn=nil end end; notify("NoClip: "..tostring(cfg.Movement.noclip),1)
		elseif txt=="esp" then cfg.ESP.enabled=not cfg.ESP.enabled; createESP(); notify("ESP: "..tostring(cfg.ESP.enabled),1)
		elseif txt=="aimbot" then cfg.Aimbot.enabled=not cfg.Aimbot.enabled; if cfg.Aimbot.enabled then startAimbot() else stopAimbot() end; notify("Aimbot: "..tostring(cfg.Aimbot.enabled),1)
		elseif txt=="god" then cfg.Player.godmode=not cfg.Player.godmode; applyGodmode(cfg.Player.godmode); notify("Godmode: "..tostring(cfg.Player.godmode),1)
		elseif txt=="chams" then cfg.ESP.chams=not cfg.ESP.chams; applyChams(); notify("Chams: "..tostring(cfg.ESP.chams),1)
		elseif txt=="tracers" then cfg.ESP.tracers=not cfg.ESP.tracers; createESP(); notify("Tracers: "..tostring(cfg.ESP.tracers),1)
		elseif txt=="skeleton" then cfg.ESP.skeleton=not cfg.ESP.skeleton; createESP(); notify("Skeleton: "..tostring(cfg.ESP.skeleton),1)
		elseif txt:sub(1,6)=="speed " then local v=tonumber(txt:sub(7)); if v then cfg.Movement.walkSpeed=v; local ch=LocalPlayer.Character; if ch and ch:FindFirstChild("Humanoid") then ch.Humanoid.WalkSpeed=v end; notify("Speed: "..v,1) end
		elseif txt:sub(1,5)=="jump " then local v=tonumber(txt:sub(6)); if v then cfg.Movement.jumpPower=v; local ch=LocalPlayer.Character; if ch and ch:FindFirstChild("Humanoid") then ch.Humanoid.JumpPower=v end; notify("Jump: "..v,1) end
		elseif txt:sub(1,8)=="gravity " then local v=tonumber(txt:sub(9)); if v then cfg.Movement.gravity=v; Workspace.Gravity=v; notify("Gravity: "..v,1) end
		elseif txt=="rejoin" then TeleportService:Teleport(game.PlaceId,LocalPlayer)
		elseif txt=="bright" then cfg.Server.fullbright=not cfg.Server.fullbright; enableFullbright(cfg.Server.fullbright); notify("Fullbright: "..tostring(cfg.Server.fullbright),1)
		elseif txt=="spin" then cfg.Movement.spinBot=not cfg.Movement.spinBot; if cfg.Movement.spinBot then spinAngle=0; spinConn=RunService.Heartbeat:Connect(function(dt) spinAngle=spinAngle+dt*360; local ch=LocalPlayer.Character; if ch and ch:FindFirstChild("HumanoidRootPart") then ch.HumanoidRootPart.CFrame=CFrame.new(ch.HumanoidRootPart.Position)*CFrame.Angles(0,math.rad(spinAngle),0) end end); regConn(spinConn) else if spinConn then spinConn:Disconnect(); spinConn=nil end end; notify("Spin: "..tostring(cfg.Movement.spinBot),1)
		elseif txt=="3rd" then cfg.Player.thirdPerson=not cfg.Player.thirdPerson; pcall(function() local ch=LocalPlayer.Character; if ch and ch:FindFirstChild("Humanoid") then ch.Humanoid.CameraDistanceOffset=cfg.Player.thirdPerson and cfg.Player.thirdPersonDist or 0 end end); notify("3rd Person: "..tostring(cfg.Player.thirdPerson),1)
		end
		cmdBox.Text=""
	end)
end

-- Teleport cleanup
LocalPlayer.OnTeleport:Connect(function() guiDestroyed=true; cleanConns(); stopAimbot(); removeESP(); for _,hl in ipairs(chamsHL) do pcall(function() hl:Destroy() end) end; chamsHL={} end)
