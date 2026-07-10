-- v1pro full features hardened
-- All vulnerabilities fixed, all features restored

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Config
local cfg = {
	Fly = { enabled = false, speed = 50 },
	Movement = { walkSpeed = 16, jumpPower = 50, noclip = false, gravity = 196.2, spinBot = false, speedForce = false },
	ESP = { enabled = false, box = true, boxStyle = "Corner", name = true, health = true, distance = true, tracers = false, snaplines = false, skeleton = false, headDot = false, chams = false, teamCheck = false, crosshair = false, throttle = false, boxThickness = 2 },
	Aimbot = { enabled = false, fov = 100, smooth = 0.2, showFOV = false, teamCheck = false, prediction = false, bindKey = "MouseButton2", aimPart = "Head" },
	Player = { thirdPerson = false, thirdPersonDist = 12, fovChanger = false, fovValue = 70, godmode = false },
	Server = { antiAFK = false, fullbright = false },
	Performance = { mode = false },
}

local connections = {}
local function reg(c) table.insert(connections, c); return c end
local function clean()
	for _, c in ipairs(connections) do
		pcall(function() if typeof(c) == "RBXScriptConnection" then c:Disconnect() end end)
	end
	connections = {}
end

local guiParent = game:GetService("CoreGui")

local function rndName()
	return string.char(97+math.random(25))..tostring(math.random(100000,999999))
end

local soundEnabled = true
local function playSound(id, vol, pitch)
	if not soundEnabled then return end
	pcall(function()
		local s = Instance.new("Sound")
		s.SoundId = id or "rbxassetid://130791370"
		s.Volume = vol or 0.3
		s.PlaybackSpeed = pitch or 1
		s.Parent = game:GetService("SoundService")
		s:Play()
		game:GetService("Debris"):AddItem(s, 2)
	end)
end
local function playToggle(on) playSound(on and "rbxassetid://130791370" or "rbxassetid://130791394", 0.2, on and 1.2 or 0.8) end
local function playClick() playSound("rbxassetid://130791370", 0.15, 1.5) end

local notifGui = Instance.new("ScreenGui")
notifGui.Name = rndName()
notifGui.Parent = guiParent
notifGui.ResetOnSpawn = false
notifGui.DisplayOrder = 998

local function notify(text, dur)
	task.spawn(function()
		pcall(function()
			local n = Instance.new("TextLabel")
			n.Size = UDim2.new(0, 0, 0, 28)
			n.Position = UDim2.new(0.5, 0, 0.85, 0)
			n.AnchorPoint = Vector2.new(0.5, 0.5)
			n.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
			n.TextColor3 = Color3.fromRGB(0, 200, 255)
			n.Text = text
			n.Font = Enum.Font.SourceSans
			n.TextSize = 13
			n.BorderSizePixel = 0
			n.Parent = notifGui
			n.Size = UDim2.new(0, n.TextBounds.X + 20, 0, 28)
			TweenService:Create(n, TweenInfo.new(0.2), {BackgroundTransparency = 0.1}):Play()
			task.wait(dur or 2)
			TweenService:Create(n, TweenInfo.new(0.3), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
			task.wait(0.3)
			n:Destroy()
		end)
	end)
end

local colorMap = {
	accent = Color3.fromRGB(0, 180, 255),
	red = Color3.fromRGB(255, 0, 0), green = Color3.fromRGB(0, 255, 0),
	blue = Color3.fromRGB(0, 100, 255), yellow = Color3.fromRGB(255, 255, 0),
	purple = Color3.fromRGB(180, 0, 255), white = Color3.fromRGB(255, 255, 255),
	cyan = Color3.fromRGB(0, 255, 255), pink = Color3.fromRGB(255, 100, 200),
	orange = Color3.fromRGB(255, 165, 0),
}
local function getColor(key) return colorMap[cfg.ESP[key]] or colorMap.accent end

local themes = {
	dark = {bg=Color3.fromRGB(20,20,25), side=Color3.fromRGB(15,15,20), title=Color3.fromRGB(10,10,15), accent=Color3.fromRGB(0,180,255)},
	blue = {bg=Color3.fromRGB(15,20,35), side=Color3.fromRGB(10,15,25), title=Color3.fromRGB(8,12,20), accent=Color3.fromRGB(0,150,255)},
	green = {bg=Color3.fromRGB(15,25,18), side=Color3.fromRGB(10,18,12), title=Color3.fromRGB(8,14,10), accent=Color3.fromRGB(0,255,100)},
	purple = {bg=Color3.fromRGB(25,15,35), side=Color3.fromRGB(18,10,25), title=Color3.fromRGB(14,8,20), accent=Color3.fromRGB(180,0,255)},
	red = {bg=Color3.fromRGB(30,15,15), side=Color3.fromRGB(22,10,10), title=Color3.fromRGB(18,8,8), accent=Color3.fromRGB(255,60,60)},
}

local gui = Instance.new("ScreenGui")
gui.Name = rndName()
gui.Parent = guiParent
gui.ResetOnSpawn = false
gui.Enabled = true

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 550, 0, 400)
main.Position = UDim2.new(0.5, -275, 0.5, -200)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = gui

local wm = Instance.new("TextLabel")
wm.Size = UDim2.new(0, 140, 0, 18)
wm.Position = UDim2.new(0, 10, 0, 10)
wm.BackgroundTransparency = 1
wm.Text = "LowspecistHUB v1pro"
wm.TextColor3 = Color3.fromRGB(0, 180, 255)
wm.Font = Enum.Font.Code
wm.TextSize = 13
wm.TextXAlignment = Enum.TextXAlignment.Left
wm.TextStrokeTransparency = 0.5
wm.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
wm.Parent = gui

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 28)
titleBar.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
titleBar.BorderSizePixel = 0
titleBar.Parent = main

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -30, 1, 0)
titleText.BackgroundTransparency = 1
titleText.Text = rndName()
titleText.TextColor3 = Color3.fromRGB(0, 200, 255)
titleText.Font = Enum.Font.Code
titleText.TextSize = 14
titleText.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -28, 0, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 14
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar
closeBtn.MouseButton1Click:Connect(function() gui:Destroy(); clean() end)

local dragging, dragStart, frameStart = false, nil, nil
titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true; dragStart = input.Position; frameStart = main.Position
		input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local d = input.Position - dragStart
		main.Position = UDim2.new(frameStart.X.Scale, frameStart.X.Offset+d.X, frameStart.Y.Scale, frameStart.Y.Offset+d.Y)
	end
end)

local sidePanel = Instance.new("ScrollingFrame")
sidePanel.Size = UDim2.new(0, 120, 1, -28)
sidePanel.Position = UDim2.new(0, 0, 0, 28)
sidePanel.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
sidePanel.BorderSizePixel = 0
sidePanel.ScrollBarThickness = 3
sidePanel.CanvasSize = UDim2.new(0, 0, 0, 0)
sidePanel.Parent = main

local sideLayout = Instance.new("UIListLayout")
sideLayout.Parent = sidePanel
sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
sideLayout.Padding = UDim.new(0, 2)
sideLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	sidePanel.CanvasSize = UDim2.new(0, 0, 0, sideLayout.AbsoluteContentSize.Y + 10)
end)

local content = Instance.new("ScrollingFrame")
content.Size = UDim2.new(1, -120, 1, -28)
content.Position = UDim2.new(0, 120, 0, 28)
content.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
content.BorderSizePixel = 0
content.ScrollBarThickness = 3
content.CanvasSize = UDim2.new(0, 0, 0, 0)
content.ClipsDescendants = true
content.Parent = main

local categories = {"Movement","Visual","Combat","Player","Server","Extra"}
local catBtns, catFrames, selectedCat = {}, {}, nil

local function switchCat(name)
	if selectedCat == name then return end
	selectedCat = name
	for _, e in ipairs(catBtns) do
		e.btn.BackgroundColor3 = (e.name == name) and Color3.fromRGB(0,90,160) or Color3.fromRGB(15,15,20)
		e.btn.TextColor3 = (e.name == name) and Color3.fromRGB(255,255,255) or Color3.fromRGB(120,120,140)
	end
	for cat, frame in pairs(catFrames) do frame.Visible = (cat == name) end
	pcall(function()
		local vf = catFrames[name]
		if vf then
			local lay = vf:FindFirstChildOfClass("UIListLayout")
			if lay then content.CanvasSize = UDim2.new(0, 0, 0, lay.AbsoluteContentSize.Y + 20) end
		end
	end)
end

for i, cat in ipairs(categories) do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -4, 0, 28)
	btn.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	btn.TextColor3 = Color3.fromRGB(120, 120, 140)
	btn.Text = cat
	btn.Font = Enum.Font.SourceSans
	btn.TextSize = 13
	btn.BorderSizePixel = 0
	btn.LayoutOrder = i
	btn.Parent = sidePanel
	table.insert(catBtns, {btn = btn, name = cat})
	btn.MouseButton1Click:Connect(function() switchCat(cat) end)

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundTransparency = 1
	frame.Visible = false
	frame.Parent = content
	local fl = Instance.new("UIListLayout")
	fl.Parent = frame
	fl.SortOrder = Enum.SortOrder.LayoutOrder
	fl.Padding = UDim.new(0, 3)
	catFrames[cat] = frame
end
switchCat("Movement")

local function createToggle(parent, text, callback)
	local f = Instance.new("Frame"); f.Size = UDim2.new(1, -8, 0, 26); f.BackgroundTransparency = 1; f.Parent = parent
	local b = Instance.new("TextButton"); b.Size = UDim2.new(0, 40, 0, 18); b.Position = UDim2.new(0, 0, 0, 4); b.BackgroundColor3 = Color3.fromRGB(150, 40, 40); b.BorderSizePixel = 0; b.Parent = f
	local l = Instance.new("TextLabel"); l.Size = UDim2.new(1, -50, 0, 26); l.Position = UDim2.new(0, 50, 0, 0); l.BackgroundTransparency = 1; l.TextColor3 = Color3.fromRGB(255,255,255); l.Text = text; l.Font = Enum.Font.SourceSans; l.TextSize = 13; l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = f
	local enabled = false
	b.MouseButton1Click:Connect(function() enabled = not enabled; b.BackgroundColor3 = enabled and Color3.fromRGB(40,150,40) or Color3.fromRGB(150,40,40); playToggle(enabled); pcall(callback, enabled) end)
	return f
end

local function createSlider(parent, text, min, max, default, callback)
	local f = Instance.new("Frame"); f.Size = UDim2.new(1, -8, 0, 42); f.BackgroundTransparency = 1; f.Parent = parent
	local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1, 0, 0, 16); lbl.BackgroundTransparency = 1; lbl.TextColor3 = Color3.fromRGB(255,255,255); lbl.Text = text..": "..default; lbl.Font = Enum.Font.SourceSans; lbl.TextSize = 13; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = f
	local bar = Instance.new("Frame"); bar.Size = UDim2.new(1, 0, 0, 6); bar.Position = UDim2.new(0, 0, 0, 20); bar.BackgroundColor3 = Color3.fromRGB(50,50,60); bar.BorderSizePixel = 0; bar.Parent = f
	local fill = Instance.new("Frame"); fill.Size = UDim2.new((default-min)/(max-min), 0, 1, 0); fill.BackgroundColor3 = Color3.fromRGB(0,150,255); fill.BorderSizePixel = 0; fill.Parent = bar
	local knob = Instance.new("TextButton"); knob.Size = UDim2.new(0,12,0,12); knob.Position = UDim2.new((default-min)/(max-min),-6,0.5,-6); knob.BackgroundColor3 = Color3.fromRGB(255,255,255); knob.Text=""; knob.BorderSizePixel=0; knob.Parent=bar
	local dragging = false
	knob.MouseButton1Down:Connect(function() dragging = true end)
	local c1 = UserInputService.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
	local c2 = UserInputService.InputChanged:Connect(function(inp)
		if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
			local p = math.clamp((inp.Position.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
			local v = math.floor(min + (max-min)*p); knob.Position = UDim2.new(p,-6,0.5,-6); fill.Size = UDim2.new(p,0,1,0); lbl.Text = text..": "..v; pcall(callback, v)
		end
	end)
	pcall(function() f.Destroying:Connect(function() c1:Disconnect(); c2:Disconnect() end) end)
	return f
end

local function createButton(parent, text, callback)
	local b = Instance.new("TextButton"); b.Size = UDim2.new(1, -8, 0, 26); b.BackgroundColor3 = Color3.fromRGB(40,40,50); b.TextColor3 = Color3.fromRGB(255,255,255); b.Text = text; b.Font = Enum.Font.SourceSans; b.TextSize = 13; b.BorderSizePixel = 0; b.Parent = parent
	b.MouseButton1Click:Connect(function() playClick(); pcall(callback) end)
	return b
end

local function createDropdown(parent, text, options, configTable, key, callback)
	local f = Instance.new("Frame"); f.Size = UDim2.new(1, -8, 0, 26); f.BackgroundTransparency = 1; f.Parent = parent
	local l = Instance.new("TextLabel"); l.Size = UDim2.new(0.45, 0, 1, 0); l.BackgroundTransparency = 1; l.TextColor3 = Color3.fromRGB(255,255,255); l.Text = text; l.Font = Enum.Font.SourceSans; l.TextSize = 13; l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = f
	local btn = Instance.new("TextButton"); btn.Size = UDim2.new(0.55, -5, 0, 22); btn.Position = UDim2.new(0.45, 0, 0, 2); btn.BackgroundColor3 = Color3.fromRGB(40,40,50); btn.TextColor3 = Color3.fromRGB(255,255,255); btn.Text = configTable[key] or options[1]; btn.Font = Enum.Font.SourceSans; btn.TextSize = 12; btn.BorderSizePixel = 0; btn.Parent = f
	local idx = 0
	btn.MouseButton1Click:Connect(function() idx = idx % #options + 1; configTable[key] = options[idx]; btn.Text = options[idx]; playClick(); if callback then pcall(callback, options[idx]) end end)
	return f
end

local noclipConn, ijConn, flyEnabled, flyGyro, flyVel, flyConn
local espDrawings = {}, espName = rndName()
local aimbotActive, aimbotName = false, rndName()
local fovCircle, chamsHL = nil, {}
local spinConn, spinAngle = nil, 0
local originalLighting = nil
local godmodeConns, godmodeCharAdded = {}, nil
local speedForceConn = nil
local espFrameCount = 0
local crosshairDrawings = {}
local serverInfoLabel = nil

local function startFly()
	if flyEnabled then return end
	local char = LocalPlayer.Character; if not char then return end
	local hum = char:FindFirstChild("Humanoid"); local root = char:FindFirstChild("HumanoidRootPart")
	if not hum or not root then return end
	flyGyro = Instance.new("BodyGyro"); flyGyro.MaxTorque = Vector3.new(400000,400000,400000); flyGyro.P = 30000; flyGyro.Parent = root
	flyVel = Instance.new("BodyVelocity"); flyVel.MaxForce = Vector3.new(400000,400000,400000); flyVel.Parent = root
	hum.PlatformStand = true; flyEnabled = true
	flyConn = RunService.Heartbeat:Connect(function()
		if not flyEnabled then return end
		local dir = Vector3.zero; local cf = Camera.CFrame
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cf.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cf.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cf.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cf.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0,1,0) end
		flyVel.Velocity = (dir.Magnitude > 0 and dir.Unit or Vector3.zero) * cfg.Fly.speed
		flyGyro.CFrame = CFrame.new(Vector3.zero, cf.LookVector)
	end)
	reg(flyConn)
end
local function stopFly()
	flyEnabled = false
	if flyConn then flyConn:Disconnect() end
	if flyGyro then pcall(function() flyGyro:Destroy() end) end
	if flyVel then pcall(function() flyVel:Destroy() end) end
	local ch = LocalPlayer.Character
	if ch and ch:FindFirstChild("Humanoid") then ch.Humanoid.PlatformStand = false end
end

local function safeDrawing(type) local ok,d = pcall(function() return Drawing.new(type) end); return ok and d or nil end
local function jitter() return (math.random()-0.5)*0.4 end
removeESP = function()
	pcall(function() RunService:UnbindFromRenderStep(espName) end)
	for _,d in ipairs(espDrawings) do pcall(function() d:Remove() end) end; espDrawings = {}
end
local function createESP()
	removeESP(); if not cfg.ESP.enabled then return end
	espFrameCount = 0
	RunService:BindToRenderStep(espName, 1, function()
		pcall(function()
			espFrameCount = espFrameCount+1
			if cfg.ESP.throttle and espFrameCount%2 ~= 0 then return end
			for _,d in ipairs(espDrawings) do d:Remove() end; espDrawings = {}
			local myTeam = LocalPlayer.Team; local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= LocalPlayer then
					if cfg.ESP.teamCheck and p.Team == myTeam then continue end
					local ch = p.Character
					if ch and ch:FindFirstChild("Head") and ch:FindFirstChild("HumanoidRootPart") and ch:FindFirstChild("Humanoid") then
						if ch.Humanoid.Health <= 0 then continue end
						local hp, onScr = Camera:WorldToViewportPoint(ch.Head.Position); if not onScr then continue end
						local fp = Camera:WorldToViewportPoint((ch.HumanoidRootPart.CFrame*CFrame.new(0,-3,0)).Position)
						local boxH = math.abs(fp.Y-hp.Y); if boxH <= 0 then continue end
						local jx, jy = jitter(), jitter()
						if cfg.ESP.box then
							if cfg.ESP.boxStyle == "3D" then
								local hrpCF = ch.HumanoidRootPart.CFrame; local topY=1.5; local botY=-3; local hw=1.5
								local c3d = {hrpCF*CFrame.new(-hw,topY,-hw),hrpCF*CFrame.new(hw,topY,-hw),hrpCF*CFrame.new(hw,topY,hw),hrpCF*CFrame.new(-hw,topY,hw),hrpCF*CFrame.new(-hw,botY,-hw),hrpCF*CFrame.new(hw,botY,-hw),hrpCF*CFrame.new(hw,botY,hw),hrpCF*CFrame.new(-hw,botY,hw)}
								local c2d = {}; for _,c in ipairs(c3d) do local p2,onS=Camera:WorldToViewportPoint(c.Position); table.insert(c2d,{pos=Vector2.new(p2.X,p2.Y),vis=onS}) end
								local edges = {{1,2},{2,3},{3,4},{4,1},{5,6},{6,7},{7,8},{8,5},{1,5},{2,6},{3,7},{4,8}}
								for _,e in ipairs(edges) do
									local a,b = c2d[e[1]],c2d[e[2]]
									if a.vis and b.vis then local ln = safeDrawing("Line"); if ln then ln.Visible=true; ln.Color=getColor("boxColor"); ln.Thickness=cfg.ESP.boxThickness; ln.From=a.pos; ln.To=b.pos; table.insert(espDrawings,ln) end end
								end
							elseif cfg.ESP.boxStyle == "Corner" then
								local sw=boxH/2; local cs=math.max(sw*0.2,4)
								local corners={{Vector2.new(hp.X-sw/2,hp.Y),Vector2.new(hp.X-sw/2+cs,hp.Y),Vector2.new(hp.X-sw/2,hp.Y+cs)},{Vector2.new(hp.X+sw/2,hp.Y),Vector2.new(hp.X+sw/2-cs,hp.Y),Vector2.new(hp.X+sw/2,hp.Y+cs)},{Vector2.new(hp.X-sw/2,hp.Y+boxH),Vector2.new(hp.X-sw/2+cs,hp.Y+boxH),Vector2.new(hp.X-sw/2,hp.Y+boxH-cs)},{Vector2.new(hp.X+sw/2,hp.Y+boxH),Vector2.new(hp.X+sw/2-cs,hp.Y+boxH),Vector2.new(hp.X+sw/2,hp.Y+boxH-cs)}}
								for _,c in ipairs(corners) do
									local ln=safeDrawing("Line"); if ln then ln.Visible=true; ln.Color=getColor("boxColor"); ln.Thickness=cfg.ESP.boxThickness; ln.From=c[1]; ln.To=c[2]; table.insert(espDrawings,ln) end
									local ln2=safeDrawing("Line"); if ln2 then ln2.Visible=true; ln2.Color=getColor("boxColor"); ln2.Thickness=cfg.ESP.boxThickness; ln2.From=c[1]; ln2.To=c[3]; table.insert(espDrawings,ln2) end
								end
							else local bx=safeDrawing("Square"); if bx then bx.Visible=true; bx.Color=getColor("boxColor"); bx.Thickness=cfg.ESP.boxThickness; bx.Filled=false; bx.Position=Vector2.new(hp.X-boxH/4+jx,hp.Y+jy); bx.Size=Vector2.new(boxH/2,boxH); table.insert(espDrawings,bx) end end
						end
						if cfg.ESP.name then local nm=safeDrawing("Text"); if nm then nm.Visible=true; nm.Color=Color3.fromRGB(255,255,255); nm.Center=true; nm.Outline=true; nm.Size=14; nm.Position=Vector2.new(hp.X+jx,hp.Y-10+jy); nm.Text=p.Name; table.insert(espDrawings,nm) end end
						if cfg.ESP.health then local hm=ch.Humanoid; if hm.MaxHealth>0 then local hpPct=hm.Health/hm.MaxHealth; local hb=safeDrawing("Square"); if hb then hb.Visible=true; hb.Filled=true; hb.Position=Vector2.new(hp.X-boxH/2-6+jx,hp.Y+boxH*(1-hpPct)+jy); hb.Size=Vector2.new(3,boxH*hpPct); hb.Color=Color3.fromRGB(255*(1-hpPct),255*hpPct,0); table.insert(espDrawings,hb) end end end
						if cfg.ESP.distance then local dd=safeDrawing("Text"); if dd then dd.Visible=true; dd.Color=Color3.fromRGB(200,200,200); dd.Center=true; dd.Size=12; local dist=myRoot and math.floor((myRoot.Position-ch.HumanoidRootPart.Position).Magnitude) or 0; dd.Position=Vector2.new(hp.X+jx,hp.Y+boxH+4+jy); dd.Text=dist.."m"; table.insert(espDrawings,dd) end end
						if cfg.ESP.tracers then local tr=safeDrawing("Line"); if tr then tr.Visible=true; tr.Color=getColor("boxColor"); tr.Thickness=1; local sm=myRoot and Camera:WorldToViewportPoint(myRoot.Position); local st=Camera:WorldToViewportPoint(ch.HumanoidRootPart.Position); if sm and sm.Z>0 and st.Z>0 then tr.From=Vector2.new(sm.X,sm.Y); tr.To=Vector2.new(st.X,st.Y) end; table.insert(espDrawings,tr) end end
						if cfg.ESP.snaplines then local sl=safeDrawing("Line"); if sl then sl.Visible=true; sl.Color=getColor("boxColor"); sl.Thickness=1; sl.Transparency=0.5; local bot=Camera:WorldToViewportPoint(ch.HumanoidRootPart.Position); sl.From=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y); sl.To=Vector2.new(bot.X+jx,bot.Y+jy); table.insert(espDrawings,sl) end end
						if cfg.ESP.headDot then local hd=safeDrawing("Circle"); if hd then hd.Visible=true; hd.Color=Color3.fromRGB(255,255,255); hd.Filled=true; hd.Radius=3; hd.Position=Vector2.new(hp.X+jx,hp.Y+jy); table.insert(espDrawings,hd) end end
						if cfg.ESP.skeleton then
							local function skLine(a,b) local pa,va=Camera:WorldToViewportPoint(a); local pb,vb=Camera:WorldToViewportPoint(b); if va and vb then local ln=safeDrawing("Line"); if ln then ln.Visible=true; ln.Color=Color3.fromRGB(180,180,180); ln.Thickness=1; ln.From=Vector2.new(pa.X+jx,pa.Y+jy); ln.To=Vector2.new(pb.X+jx,pb.Y+jy); table.insert(espDrawings,ln) end end end
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

local function updateCrosshair()
	for _,d in ipairs(crosshairDrawings) do pcall(function() d:Remove() end) end; crosshairDrawings = {}
	if not cfg.ESP.crosshair then return end
	local cx=Camera.ViewportSize.X/2; local cy=Camera.ViewportSize.Y/2; local s=10; local gap=4
	local lines={{Vector2.new(cx-gap,cy),Vector2.new(cx-gap-s,cy)},{Vector2.new(cx+gap,cy),Vector2.new(cx+gap+s,cy)},{Vector2.new(cx,cy-gap),Vector2.new(cx,cy-gap-s)},{Vector2.new(cx,cy+gap),Vector2.new(cx,cy+gap+s)}}
	for _,l in ipairs(lines) do local ln=safeDrawing("Line"); if ln then ln.Visible=true; ln.Color=Color3.fromRGB(255,255,255); ln.Thickness=1; ln.From=l[1]; ln.To=l[2]; table.insert(crosshairDrawings,ln) end end
end

local function applyChams()
	for _,hl in ipairs(chamsHL) do pcall(function() hl:Destroy() end) end; chamsHL = {}
	if not cfg.ESP.chams then return end
	for _,p in ipairs(Players:GetPlayers()) do
		if p~=LocalPlayer and p.Character then
			local hl=Instance.new("Highlight"); hl.Name=rndName(); hl.FillColor=Color3.fromRGB(255,0,0); hl.OutlineColor=Color3.fromRGB(255,0,0); hl.FillTransparency=0.5; hl.OutlineTransparency=0; hl.Parent=p.Character
			table.insert(chamsHL,hl)
		end
	end
end
Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(function() task.wait(1); pcall(function() if cfg.ESP.chams then applyChams() end end) end) end)
Players.PlayerRemoving:Connect(function() if cfg.ESP.chams then task.defer(function() pcall(applyChams) end) end end)

local aimbotHolding = false
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	pcall(function()
		if input.UserInputType.Name == cfg.Aimbot.bindKey or input.KeyCode.Name == cfg.Aimbot.bindKey then aimbotHolding = true end
	end)
end)
UserInputService.InputEnded:Connect(function(input)
	pcall(function()
		if input.UserInputType.Name == cfg.Aimbot.bindKey or input.KeyCode.Name == cfg.Aimbot.bindKey then aimbotHolding = false end
	end)
end)

local function startAimbot()
	if aimbotActive then return end; aimbotActive = true
	if cfg.Aimbot.showFOV then fovCircle=safeDrawing("Circle"); if fovCircle then fovCircle.Visible=true; fovCircle.Color=Color3.fromRGB(0,180,255); fovCircle.Thickness=1; fovCircle.Filled=false; fovCircle.Radius=cfg.Aimbot.fov; fovCircle.Position=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2) end end
	RunService:BindToRenderStep(aimbotName, 2, function()
		pcall(function()
			if fovCircle then fovCircle.Radius=cfg.Aimbot.fov; fovCircle.Position=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2) end
			if cfg.ESP.crosshair then updateCrosshair() end
			if not cfg.Aimbot.enabled or not aimbotHolding then return end
			local myRoot=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			if not myRoot then return end
			local myTeam=LocalPlayer.Team; local best, bestDist=nil, cfg.Aimbot.fov
			local sc=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
			for _,p in ipairs(Players:GetPlayers()) do
				if p~=LocalPlayer then
					if cfg.Aimbot.teamCheck and p.Team==myTeam then continue end
					local ch=p.Character
					if ch and ch:FindFirstChild("Head") and ch:FindFirstChild("Humanoid") and ch.Humanoid.Health>0 then
						local targetPos=ch:FindFirstChild(cfg.Aimbot.aimPart) and ch[cfg.Aimbot.aimPart].Position or ch.Head.Position
						if cfg.Aimbot.prediction then local hrp=ch:FindFirstChild("HumanoidRootPart"); if hrp then targetPos=targetPos+hrp.Velocity*0.1 end end
						local sp,onS=Camera:WorldToViewportPoint(targetPos)
						if onS then local d=(Vector2.new(sp.X,sp.Y)-sc).Magnitude; if d<bestDist then bestDist=d; best={player=p,pos=targetPos} end end
					end
				end
			end
			if best then Camera.CFrame=Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position,best.pos),cfg.Aimbot.smooth) end
		end)
	end)
end
stopAimbot = function()
	aimbotActive = false; pcall(function() RunService:UnbindFromRenderStep(aimbotName) end)
	if fovCircle then pcall(function() fovCircle:Remove() end); fovCircle=nil end
	for _,d in ipairs(crosshairDrawings) do pcall(function() d:Remove() end) end; crosshairDrawings = {}
end

local function enableFullbright(on)
	pcall(function()
		if on then
			if not originalLighting then originalLighting={Brightness=Lighting.Brightness,ClockTime=Lighting.ClockTime,FogEnd=Lighting.FogEnd,GlobalShadows=Lighting.GlobalShadows,Ambient=Lighting.Ambient} end
			Lighting.Brightness=2; Lighting.ClockTime=14; Lighting.FogEnd=100000; Lighting.GlobalShadows=false; Lighting.Ambient=Color3.fromRGB(178,178,178)
		else
			if originalLighting then Lighting.Brightness=originalLighting.Brightness; Lighting.ClockTime=originalLighting.ClockTime; Lighting.FogEnd=originalLighting.FogEnd; Lighting.GlobalShadows=originalLighting.GlobalShadows; Lighting.Ambient=originalLighting.Ambient; originalLighting=nil end
		end
	end)
end

local function applyGodmode(on)
	for _,c in ipairs(godmodeConns) do pcall(function() c:Disconnect() end) end; godmodeConns = {}
	if godmodeCharAdded then godmodeCharAdded:Disconnect(); godmodeCharAdded=nil end
	if on then
		local function setup(char)
			pcall(function()
				local hum=char:WaitForChild("Humanoid",5); if not hum then return end
				hum.BreakJointsOnDeath=false; pcall(function() hum.RequiresNeck=false end)
				local maxHP=hum.MaxHealth
				local c1=hum.HealthChanged:Connect(function(hp) if hp<maxHP then task.defer(function() pcall(function() if hum and hum.Parent then hum.Health=maxHP end end) end) end)
				table.insert(godmodeConns,c1)
				local c2=hum.StateChanged:Connect(function(_,st) if st==Enum.HumanoidStateType.Dead then pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end) end end)
				table.insert(godmodeConns,c2)
			end)
		end
		if LocalPlayer.Character then setup(LocalPlayer.Character) end
		godmodeCharAdded=LocalPlayer.CharacterAdded:Connect(function(char) task.wait(0.5); setup(char) end)
		table.insert(godmodeConns,godmodeCharAdded)
	end
end

local function startSpeedForce()
	if speedForceConn then return end
	speedForceConn=RunService.Heartbeat:Connect(function()
		pcall(function()
			local ch=LocalPlayer.Character
			if ch and ch:FindFirstChild("Humanoid") then
				local hum=ch.Humanoid
				if hum.WalkSpeed~=cfg.Movement.walkSpeed then hum.WalkSpeed=cfg.Movement.walkSpeed end
				if hum.JumpPower~=cfg.Movement.jumpPower then hum.JumpPower=cfg.Movement.jumpPower end
			end
		end)
	end)
	reg(speedForceConn)
end
local function stopSpeedForce() if speedForceConn then speedForceConn:Disconnect(); speedForceConn=nil end end

local function enableAntiAFK()
	pcall(function()
		local vu=game:GetService("VirtualUser")
		local c=LocalPlayer.Idled:Connect(function() pcall(function() vu:CaptureController(); vu:ClickButton2(Vector2.new()) end) end)
		reg(c)
	end)
end

local function updateServerInfo()
	pcall(function()
		if not serverInfoLabel or not serverInfoLabel.Parent then return end
		local ping=LocalPlayer:GetNetworkPing(); local count=#Players:GetPlayers()
		serverInfoLabel.Text=string.format("Ping: %dms | Players: %d | Server: %s",math.floor(ping*1000),count,game.JobId:sub(1,8))
	end)
end

local function disableAllFeatures()
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
	pcall(function() local ch=LocalPlayer.Character; if ch and ch:FindFirstChild("Humanoid") then ch.Humanoid.WalkSpeed=16; ch.Humanoid.JumpPower=50; cfg.Movement.walkSpeed=16; cfg.Movement.jumpPower=50 end end)
end

do
	local mf=catFrames["Movement"]
	createToggle(mf,"Fly",function(on) if on then startFly() else stopFly() end end)
	createSlider(mf,"Fly Speed",10,200,cfg.Fly.speed,function(v) cfg.Fly.speed=v end)
	createSlider(mf,"WalkSpeed",1,1000,cfg.Movement.walkSpeed,function(v) cfg.Movement.walkSpeed=v; pcall(function() local ch=LocalPlayer.Character; if ch and ch:FindFirstChild("Humanoid") then ch.Humanoid.WalkSpeed=v end end) end)
	createSlider(mf,"JumpPower",0,2000,cfg.Movement.jumpPower,function(v) cfg.Movement.jumpPower=v; pcall(function() local ch=LocalPlayer.Character; if ch and ch:FindFirstChild("Humanoid") then ch.Humanoid.JumpPower=v end end) end)
	createSlider(mf,"Gravity",0,500,cfg.Movement.gravity,function(v) cfg.Movement.gravity=v; Workspace.Gravity=v end)
	createToggle(mf,"NoClip",function(on) if noclipConn then noclipConn:Disconnect(); noclipConn=nil end; if on then noclipConn=RunService.Stepped:Connect(function() pcall(function() local c=LocalPlayer.Character; if c then for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end end) end); reg(noclipConn) end end)
	createToggle(mf,"Infinite Jump",function(on) if ijConn then ijConn:Disconnect(); ijConn=nil end; if on then ijConn=UserInputService.JumpRequest:Connect(function() pcall(function() local c=LocalPlayer.Character; if c and c:FindFirstChild("Humanoid") then c.Humanoid.Jump=true end end) end); reg(ijConn) end end)
	createToggle(mf,"Spin Bot",function(on) if spinConn then spinConn:Disconnect(); spinConn=nil end; if on then spinAngle=0; spinConn=RunService.Heartbeat:Connect(function(dt) spinAngle=spinAngle+dt*360; pcall(function() local ch=LocalPlayer.Character; if ch and ch:FindFirstChild("HumanoidRootPart") then ch.HumanoidRootPart.CFrame=CFrame.new(ch.HumanoidRootPart.Position)*CFrame.Angles(0,math.rad(spinAngle),0) end end) end); reg(spinConn) end end)
	createButton(mf,"Speed Force",function() if speedForceConn then stopSpeedForce(); cfg.Movement.speedForce=false; notify("Speed Force OFF",1) else startSpeedForce(); cfg.Movement.speedForce=true; notify("Speed Force ON",1) end end)

	local vf=catFrames["Visual"]
	createToggle(vf,"ESP",function(on) cfg.ESP.enabled=on; createESP() end)
	createToggle(vf,"Box",function(on) cfg.ESP.box=on; createESP() end)
	createDropdown(vf,"Box Style",{"Corner","Full","3D"},cfg.ESP,"boxStyle",function() createESP() end)
	createToggle(vf,"Name",function(on) cfg.ESP.name=on; createESP() end)
	createToggle(vf,"Health",function(on) cfg.ESP.health=on; createESP() end)
	createToggle(vf,"Distance",function(on) cfg.ESP.distance=on; createESP() end)
	createToggle(vf,"Tracers",function(on) cfg.ESP.tracers=on; createESP() end)
	createToggle(vf,"Snaplines",function(on) cfg.ESP.snaplines=on; createESP() end)
	createToggle(vf,"Head Dot",function(on) cfg.ESP.headDot=on; createESP() end)
	createToggle(vf,"Skeleton",function(on) cfg.ESP.skeleton=on; createESP() end)
	createToggle(vf,"Chams",function(on) cfg.ESP.chams=on; applyChams() end)
	createToggle(vf,"Team Check",function(on) cfg.ESP.teamCheck=on; createESP() end)
	createToggle(vf,"Crosshair",function(on) cfg.ESP.crosshair=on end)
	createToggle(vf,"Frame Throttle",function(on) cfg.ESP.throttle=on end)
	createSlider(vf,"Box Thickness",1,5,cfg.ESP.boxThickness,function(v) cfg.ESP.boxThickness=v; createESP() end)
	createDropdown(vf,"Box Color",{"accent","red","green","blue","yellow","purple","white","cyan","pink","orange"},cfg.ESP,"boxColor",function() createESP() end)
	createToggle(vf,"Fullbright",function(on) enableFullbright(on); notify(on and "Fullbright ON" or "Fullbright OFF",1) end)

	local cf=catFrames["Combat"]
	createToggle(cf,"Aimbot",function(on) cfg.Aimbot.enabled=on; if on then startAimbot() else stopAimbot() end; notify(on and "Aimbot ON" or "Aimbot OFF",1) end)
	createSlider(cf,"FOV",10,360,cfg.Aimbot.fov,function(v) cfg.Aimbot.fov=v; if fovCircle then fovCircle.Radius=v end end)
	createSlider(cf,"Smooth",0.01,1,cfg.Aimbot.smooth,function(v) cfg.Aimbot.smooth=v end)
	createToggle(cf,"Show FOV",function(on) cfg.Aimbot.showFOV=on; if on and aimbotActive then fovCircle=safeDrawing("Circle"); if fovCircle then fovCircle.Visible=true; fovCircle.Color=Color3.fromRGB(0,180,255); fovCircle.Thickness=1; fovCircle.Filled=false; fovCircle.Radius=cfg.Aimbot.fov; fovCircle.Position=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2) end elseif fovCircle then pcall(function() fovCircle:Remove() end); fovCircle=nil end end)
	createToggle(cf,"Team Check",function(on) cfg.Aimbot.teamCheck=on end)
	createToggle(cf,"Prediction",function(on) cfg.Aimbot.prediction=on end)
	createDropdown(cf,"Bind Key",{"MouseButton2","MouseButton3","E","Q","LeftShift","LeftControl"},cfg.Aimbot,"bindKey",function() end)
	createDropdown(cf,"Aim Part",{"Head","Torso","HumanoidRootPart"},cfg.Aimbot,"aimPart",function() end)

	local pf=catFrames["Player"]
	createToggle(pf,"Third Person",function(on) cfg.Player.thirdPerson=on; pcall(function() local ch=LocalPlayer.Character; if ch and ch:FindFirstChild("Humanoid") then ch.Humanoid.CameraDistanceOffset=on and cfg.Player.thirdPersonDist or 0 end end) end)
	createSlider(pf,"3rd Distance",5,30,cfg.Player.thirdPersonDist,function(v) cfg.Player.thirdPersonDist=v; if cfg.Player.thirdPerson then pcall(function() local ch=LocalPlayer.Character; if ch and ch:FindFirstChild("Humanoid") then ch.Humanoid.CameraDistanceOffset=v end end) end end)
	createToggle(pf,"FOV Changer",function(on) cfg.Player.fovChanger=on; Camera.FieldOfView=on and cfg.Player.fovValue or 70 end)
	createSlider(pf,"FOV Value",50,120,cfg.Player.fovValue,function(v) cfg.Player.fovValue=v; if cfg.Player.fovChanger then Camera.FieldOfView=v end end)
	createToggle(pf,"Godmode",function(on) cfg.Player.godmode=on; applyGodmode(on); notify(on and "Godmode ON" or "Godmode OFF",1) end)

	local sf=catFrames["Server"]
	createButton(sf,"Rejoin",function() pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId,LocalPlayer) end) end)
	createToggle(sf,"Anti-AFK",function(on) cfg.Server.antiAFK=on; if on then enableAntiAFK(); notify("Anti-AFK ON",1) end end)
	serverInfoLabel=Instance.new("TextLabel"); serverInfoLabel.Size=UDim2.new(1,-8,0,22); serverInfoLabel.BackgroundTransparency=1; serverInfoLabel.TextColor3=Color3.fromRGB(120,120,140); serverInfoLabel.Font=Enum.Font.Code; serverInfoLabel.TextSize=11; serverInfoLabel.TextXAlignment=Enum.TextXAlignment.Left; serverInfoLabel.Parent=sf
	RunService.Heartbeat:Connect(function() pcall(updateServerInfo) end)

	local ef=catFrames["Extra"]
	createDropdown(ef,"Theme",{"dark","blue","green","purple","red"},{currentTheme="dark"},"currentTheme",function(name) local t=themes[name]; if t then pcall(function() main.BackgroundColor3=t.bg; sidePanel.BackgroundColor3=t.side; titleBar.BackgroundColor3=t.title; titleText.TextColor3=t.accent; wm.TextColor3=t.accent end); notify("Theme: "..name,1) end end)
	createButton(ef,"Export Config",function() local json=HttpService:JSONEncode(cfg); if setclipboard then setclipboard(json); end; notify("Config saved",1) end)
	createButton(ef,"Import Config",function() if getclipboard then local ok,data=pcall(function() return HttpService:JSONDecode(getclipboard()) end); if ok and data then for k,v in pairs(data) do if type(v)=="table" and type(cfg[k])=="table" then for sk,sv in pairs(v) do cfg[k][sk]=sv end else cfg[k]=v end end; notify("Config loaded",1) end end end)
	createToggle(ef,"Performance Mode",function(on) pcall(function() local s=UserSettings():GetService("UserGameSettings"); s.RenderingQualityLevel=on and Enum.QualityLevel.Level01 or Enum.QualityLevel.Level21 end) end)
	createButton(ef,"Toggle Sounds",function() soundEnabled=not soundEnabled; notify(soundEnabled and "Sounds ON" or "Sounds OFF",1) end)
	createButton(ef,"Destroy",function() gui:Destroy(); clean(); removeESP(); for _,hl in ipairs(chamsHL) do pcall(function() hl:Destroy() end) end end)
end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.RightControl then gui.Enabled = not gui.Enabled end
end)

pcall(function()
	LocalPlayer.OnTeleport:Connect(function()
		clean(); removeESP(); stopAimbot()
		for _,c in ipairs(godmodeConns) do pcall(function() c:Disconnect() end) end; godmodeConns={}
		if godmodeCharAdded then godmodeCharAdded:Disconnect(); godmodeCharAdded=nil end
		for _,hl in ipairs(chamsHL) do pcall(function() hl:Destroy() end) end; chamsHL={}
	end)
end)

print(rndName())
