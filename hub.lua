-- v1pro — hardened version
-- All vulnerabilities fixed

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Config
local cfg = {
	Fly = { enabled = false, speed = 50 },
	Movement = { walkSpeed = 16, jumpPower = 50, noclip = false, gravity = 196.2 },
	ESP = { enabled = false, box = true, name = true, health = true, distance = true },
	Aimbot = { enabled = false, fov = 100, smooth = 0.2 },
	Server = { fullbright = false },
}

-- Connection yönetimi
local connections = {}
local function reg(c) table.insert(connections, c); return c end
local function clean()
	for _, c in ipairs(connections) do
		pcall(function() if typeof(c) == "RBXScriptConnection" then c:Disconnect() end end)
	end
	connections = {}
end

-- Safe GUI parent (gethui > CoreGui)
local function getGuiParent()
	local ok, hui = pcall(gethui)
	return ok and hui or game:GetService("CoreGui")
end

-- Random name generator
local function rndName()
	return string.char(97+math.random(25))..tostring(math.random(100000,999999))
end

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = rndName() -- FIX: randomized name
gui.Parent = getGuiParent() -- FIX: safe parent
gui.ResetOnSpawn = false
gui.Enabled = true

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 300, 0, 350)
main.Position = UDim2.new(0.5, -150, 0.5, -175)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = gui

-- Başlık
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
titleBar.BorderSizePixel = 0
titleBar.Parent = main

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -30, 1, 0)
titleText.BackgroundTransparency = 1
titleText.Text = rndName() -- FIX: randomized title
titleText.TextColor3 = Color3.fromRGB(0, 200, 255)
titleText.Font = Enum.Font.Code
titleText.TextSize = 14
titleText.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -30, 0, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 14
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar
closeBtn.MouseButton1Click:Connect(function() gui:Destroy(); clean() end)

-- Sürükleme
local dragging, dragStart, frameStart = false, nil, nil
titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		frameStart = main.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local d = input.Position - dragStart
		main.Position = UDim2.new(frameStart.X.Scale, frameStart.X.Offset + d.X, frameStart.Y.Scale, frameStart.Y.Offset + d.Y)
	end
end)

-- Scroll area
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, 0, 1, -30)
scroll.Position = UDim2.new(0, 0, 0, 30)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.Parent = main

local layout = Instance.new("UIListLayout")
layout.Parent = scroll
layout.Padding = UDim.new(0, 3)
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
end)

-- Toggle
local yPos = 0
local function createToggle(text, callback)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, -10, 0, 28)
	f.Position = UDim2.new(0, 5, 0, yPos)
	f.BackgroundTransparency = 1
	f.Parent = scroll

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 40, 0, 20)
	btn.Position = UDim2.new(0, 0, 0, 4)
	btn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
	btn.BorderSizePixel = 0
	btn.Parent = f

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -50, 0, 28)
	lbl.Position = UDim2.new(0, 50, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	lbl.Text = text
	lbl.Font = Enum.Font.SourceSans
	lbl.TextSize = 14
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = f

	local enabled = false
	btn.MouseButton1Click:Connect(function()
		enabled = not enabled
		btn.BackgroundColor3 = enabled and Color3.fromRGB(40, 150, 40) or Color3.fromRGB(150, 40, 40)
		pcall(callback, enabled)
	end)
	yPos = yPos + 32
end

-- Slider
local sliderConns = {}
local function createSlider(text, min, max, default, callback)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, -10, 0, 45)
	f.Position = UDim2.new(0, 5, 0, yPos)
	f.BackgroundTransparency = 1
	f.Parent = scroll

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 18)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	lbl.Text = text .. ": " .. default
	lbl.Font = Enum.Font.SourceSans
	lbl.TextSize = 14
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = f

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, 0, 0, 6)
	bar.Position = UDim2.new(0, 0, 0, 22)
	bar.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	bar.BorderSizePixel = 0
	bar.Parent = f

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
	fill.BorderSizePixel = 0
	fill.Parent = bar

	local knob = Instance.new("TextButton")
	knob.Size = UDim2.new(0, 12, 0, 12)
	knob.Position = UDim2.new((default - min) / (max - min), -6, 0.5, -6)
	knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knob.Text = ""
	knob.BorderSizePixel = 0
	knob.Parent = bar

	local dragging = false
	knob.MouseButton1Down:Connect(function() dragging = true end)
	-- FIX: store slider connections for cleanup
	local c1 = UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
	local c2 = UserInputService.InputChanged:Connect(function(inp)
		if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
			local p = math.clamp((inp.Position.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
			local v = math.floor(min + (max - min) * p)
			knob.Position = UDim2.new(p, -6, 0.5, -6)
			fill.Size = UDim2.new(p, 0, 1, 0)
			lbl.Text = text .. ": " .. v
			pcall(callback, v)
		end
	end)
	table.insert(sliderConns, c1)
	table.insert(sliderConns, c2)
	-- FIX: cleanup on destroy
	pcall(function()
		f.Destroying:Connect(function()
			c1:Disconnect()
			c2:Disconnect()
		end)
	end)
	yPos = yPos + 48
end

-- Buton
local function createButton(text, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -10, 0, 28)
	btn.Position = UDim2.new(0, 5, 0, yPos)
	btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Text = text
	btn.Font = Enum.Font.SourceSans
	btn.TextSize = 14
	btn.BorderSizePixel = 0
	btn.Parent = scroll
	btn.MouseButton1Click:Connect(function() pcall(callback) end)
	yPos = yPos + 32
end

-- ===== FEATURES =====

-- FLY
local flyEnabled = false
local flyGyro, flyVel, flyConn
createToggle("Fly", function(on)
	if on then
		local char = LocalPlayer.Character
		if not char then return end
		local hum = char:FindFirstChild("Humanoid")
		local root = char:FindFirstChild("HumanoidRootPart")
		if not hum or not root then return end
		flyGyro = Instance.new("BodyGyro")
		flyGyro.MaxTorque = Vector3.new(400000, 400000, 400000)
		flyGyro.P = 30000
		flyGyro.Parent = root
		flyVel = Instance.new("BodyVelocity")
		flyVel.MaxForce = Vector3.new(400000, 400000, 400000)
		flyVel.Parent = root
		hum.PlatformStand = true
		flyEnabled = true
		flyConn = RunService.Heartbeat:Connect(function()
			if not flyEnabled then return end
			local dir = Vector3.zero
			local cf = Camera.CFrame
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cf.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cf.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cf.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cf.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0, 1, 0) end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0, 1, 0) end
			flyVel.Velocity = (dir.Magnitude > 0 and dir.Unit or Vector3.zero) * cfg.Fly.speed
			flyGyro.CFrame = CFrame.new(Vector3.zero, cf.LookVector)
		end)
		reg(flyConn)
	else
		flyEnabled = false
		if flyConn then flyConn:Disconnect() end
		if flyGyro then flyGyro:Destroy() end
		if flyVel then flyVel:Destroy() end
		local ch = LocalPlayer.Character
		if ch and ch:FindFirstChild("Humanoid") then ch.Humanoid.PlatformStand = false end
	end
end)
createSlider("Fly Speed", 10, 200, 50, function(v) cfg.Fly.speed = v end)

-- WALKSPEED
createSlider("WalkSpeed", 1, 1000, 16, function(v)
	cfg.Movement.walkSpeed = v
	pcall(function()
		local ch = LocalPlayer.Character
		if ch and ch:FindFirstChild("Humanoid") then ch.Humanoid.WalkSpeed = v end
	end)
end)

-- JUMPPOWER
createSlider("JumpPower", 0, 2000, 50, function(v)
	cfg.Movement.jumpPower = v
	pcall(function()
		local ch = LocalPlayer.Character
		if ch and ch:FindFirstChild("Humanoid") then ch.Humanoid.JumpPower = v end
	end)
end)

-- NOCLIP
local noclipConn = nil
createToggle("NoClip", function(on)
	if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
	if on then
		noclipConn = RunService.Stepped:Connect(function()
			pcall(function()
				local c = LocalPlayer.Character
				if c then for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
			end)
		end)
		reg(noclipConn)
	end
end)

-- INFINITE JUMP
local ijConn = nil
createToggle("Infinite Jump", function(on)
	if ijConn then ijConn:Disconnect(); ijConn = nil end
	if on then
		ijConn = UserInputService.JumpRequest:Connect(function()
			pcall(function()
				local c = LocalPlayer.Character
				if c and c:FindFirstChild("Humanoid") then c.Humanoid.Jump = true end
			end)
		end)
		reg(ijConn)
	end
end)

-- ESP
local espDrawings = {}
local espName = rndName() -- FIX: randomized name
local function removeESP()
	pcall(function() RunService:UnbindFromRenderStep(espName) end)
	for _, d in ipairs(espDrawings) do pcall(function() d:Remove() end) end
	espDrawings = {}
end
local function createESP()
	removeESP()
	if not cfg.ESP.enabled then return end
	RunService:BindToRenderStep(espName, 1, function()
		pcall(function()
			for _, d in ipairs(espDrawings) do d:Remove() end
			espDrawings = {}
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= LocalPlayer then
					local ch = p.Character
					if ch and ch:FindFirstChild("Head") and ch:FindFirstChild("HumanoidRootPart") and ch:FindFirstChild("Humanoid") then
						if ch.Humanoid.Health <= 0 then continue end
						local hp, onScr = Camera:WorldToViewportPoint(ch.Head.Position)
						if onScr then
							local fp = Camera:WorldToViewportPoint((ch.HumanoidRootPart.CFrame * CFrame.new(0, -3, 0)).Position)
							local h = math.abs(fp.Y - hp.Y)
							if h > 0 then
								-- FIX: jitter for stealth
								local jx = (math.random() - 0.5) * 0.4
								local jy = (math.random() - 0.5) * 0.4
								if cfg.ESP.box then
									local ok, bx = pcall(function() return Drawing.new("Square") end)
									if ok and bx then
										bx.Visible = true; bx.Color = Color3.fromRGB(0, 200, 255); bx.Thickness = 1; bx.Filled = false
										bx.Position = Vector2.new(hp.X - h/4 + jx, hp.Y + jy); bx.Size = Vector2.new(h/2, h)
										table.insert(espDrawings, bx)
									end
								end
								if cfg.ESP.name then
									local ok, nm = pcall(function() return Drawing.new("Text") end)
									if ok and nm then
										nm.Visible = true; nm.Color = Color3.fromRGB(255, 255, 255); nm.Center = true; nm.Outline = true; nm.Size = 14
										nm.Position = Vector2.new(hp.X + jx, hp.Y - 10 + jy); nm.Text = p.Name
										table.insert(espDrawings, nm)
									end
								end
								if cfg.ESP.health then
									local hm = ch.Humanoid
									if hm.MaxHealth > 0 then
										local hpPct = hm.Health / hm.MaxHealth
										local ok, hb = pcall(function() return Drawing.new("Square") end)
										if ok and hb then
											hb.Visible = true; hb.Filled = true
											hb.Position = Vector2.new(hp.X - h/2 - 6 + jx, hp.Y + h * (1 - hpPct) + jy)
											hb.Size = Vector2.new(3, h * hpPct)
											hb.Color = Color3.fromRGB(255 * (1 - hpPct), 255 * hpPct, 0)
											table.insert(espDrawings, hb)
										end
									end
								end
								if cfg.ESP.distance then
									local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
									local ok, dd = pcall(function() return Drawing.new("Text") end)
									if ok and dd then
										dd.Visible = true; dd.Color = Color3.fromRGB(200, 200, 200); dd.Center = true; dd.Size = 12
										local dist = myRoot and math.floor((myRoot.Position - ch.HumanoidRootPart.Position).Magnitude) or 0
										dd.Position = Vector2.new(hp.X + jx, hp.Y + h + 4 + jy); dd.Text = dist .. "m"
										table.insert(espDrawings, dd)
									end
								end
							end
						end
					end
				end
			end
		end)
	end)
end
createToggle("ESP", function(on) cfg.ESP.enabled = on; createESP() end)

-- GODMODE (safe)
local godmodeConns = {}
local godmodeCharAdded = nil -- FIX: track CharacterAdded connection
createToggle("Godmode", function(on)
	-- cleanup
	for _, c in ipairs(godmodeConns) do pcall(function() c:Disconnect() end) end
	godmodeConns = {}
	if godmodeCharAdded then godmodeCharAdded:Disconnect(); godmodeCharAdded = nil end
	if on then
		local function setup(char)
			pcall(function()
				local hum = char:WaitForChild("Humanoid", 5)
				if not hum then return end
				hum.BreakJointsOnDeath = false
				pcall(function() hum.RequiresNeck = false end)
				local maxHP = hum.MaxHealth
				local c1 = hum.HealthChanged:Connect(function(hp)
					if hp < maxHP then task.defer(function() pcall(function() if hum and hum.Parent then hum.Health = maxHP end end) end) end
				end)
				table.insert(godmodeConns, c1)
				local c2 = hum.StateChanged:Connect(function(_, state)
					if state == Enum.HumanoidStateType.Dead then pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end) end
				end)
				table.insert(godmodeConns, c2)
			end)
		end
		if LocalPlayer.Character then setup(LocalPlayer.Character) end
		godmodeCharAdded = LocalPlayer.CharacterAdded:Connect(function(char) task.wait(0.5); setup(char) end)
		table.insert(godmodeConns, godmodeCharAdded)
	end
end)

-- FULLBRIGHT
local originalLighting = nil
createToggle("Fullbright", function(on)
	pcall(function()
		if on then
			if not originalLighting then
				originalLighting = {Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime, FogEnd = Lighting.FogEnd, GlobalShadows = Lighting.GlobalShadows, Ambient = Lighting.Ambient}
			end
			Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.FogEnd = 100000; Lighting.GlobalShadows = false; Lighting.Ambient = Color3.fromRGB(178, 178, 178)
		else
			if originalLighting then
				Lighting.Brightness = originalLighting.Brightness; Lighting.ClockTime = originalLighting.ClockTime; Lighting.FogEnd = originalLighting.FogEnd; Lighting.GlobalShadows = originalLighting.GlobalShadows; Lighting.Ambient = originalLighting.Ambient; originalLighting = nil
			end
		end
	end)
end)

-- ANTI-AFK
createToggle("Anti-AFK", function(on)
	if on then
		pcall(function()
			local vu = game:GetService("VirtualUser")
			local c = LocalPlayer.Idled:Connect(function()
				pcall(function()
					vu:CaptureController()
					vu:ClickButton2(Vector2.new())
				end)
			end)
			reg(c)
		end)
	end
end)

-- SERVER INFO
createButton("Server Info", function()
	pcall(function()
		local ping = LocalPlayer:GetNetworkPing()
		local count = #Players:GetPlayers()
		print("Ping: " .. math.floor(ping * 1000) .. "ms | Players: " .. count .. " | Server: " .. game.JobId:sub(1, 8))
	end)
end)

-- REJOIN
createButton("Rejoin", function()
	pcall(function()
		game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
	end)
end)

-- Hotkey
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.RightControl then gui.Enabled = not gui.Enabled end
end)

-- Cleanup on teleport
pcall(function()
	LocalPlayer.OnTeleport:Connect(function()
		clean()
		removeESP()
		for _, c in ipairs(godmodeConns) do pcall(function() c:Disconnect() end) end
		godmodeConns = {}
		if godmodeCharAdded then godmodeCharAdded:Disconnect(); godmodeCharAdded = nil end
	end)
end)

print(rndName())
