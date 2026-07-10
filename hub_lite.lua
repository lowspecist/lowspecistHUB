-- v1pro lite — minimal version
-- Crash sorunu için basitleştirilmiş versiyon

-- Servisler
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Güvenli getHui
local function getHui()
	return pcall(gethui) and gethui() or game:GetService("CoreGui")
end

-- Rastgele isim
local function rndName()
	return string.char(97+math.random(25))..tostring(math.random(100000,999999))
end

-- Config
local cfg = {
	Fly = { enabled = false, speed = 50 },
	Movement = { walkSpeed = 16, jumpPower = 50, noclip = false, gravity = 196.2 },
	ESP = { enabled = false, box = true, name = true, health = true, distance = true },
	Aimbot = { enabled = false, fov = 100, smooth = 0.2 },
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

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = rndName()
gui.Parent = getHui()
gui.ResetOnSpawn = false
gui.Enabled = true

-- Ana frame
local main = Instance.new("Frame")
main.Size = UDim2.new(0, 300, 0, 250)
main.Position = UDim2.new(0.5, -150, 0.5, -125)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
main.BorderSizePixel = 0
main.Parent = gui

-- Başlık
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
title.Text = "v1pro lite"
title.TextColor3 = Color3.fromRGB(0, 200, 255)
title.Font = Enum.Font.Code
title.TextSize = 14
title.Parent = main

-- Kapatma butonu
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -30, 0, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 14
closeBtn.BorderSizePixel = 0
closeBtn.Parent = title
closeBtn.MouseButton1Click:Connect(function() gui:Destroy(); clean() end)

-- Toggle butonları
local yPos = 40
local function createToggle(text, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -20, 0, 28)
	btn.Position = UDim2.new(0, 10, 0, yPos)
	btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Text = text .. ": OFF"
	btn.Font = Enum.Font.SourceSans
	btn.TextSize = 14
	btn.BorderSizePixel = 0
	btn.Parent = main

	local enabled = false
	btn.MouseButton1Click:Connect(function()
		enabled = not enabled
		btn.Text = text .. ": " .. (enabled and "ON" or "OFF")
		btn.BackgroundColor3 = enabled and Color3.fromRGB(0, 150, 50) or Color3.fromRGB(40, 40, 50)
		pcall(callback, enabled)
	end)
	yPos = yPos + 35
end

-- Slider
local function createSlider(text, min, max, default, callback)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -20, 0, 20)
	lbl.Position = UDim2.new(0, 10, 0, yPos)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	lbl.Text = text .. ": " .. default
	lbl.Font = Enum.Font.SourceSans
	lbl.TextSize = 14
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = main

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, -20, 0, 8)
	bar.Position = UDim2.new(0, 10, 0, yPos + 22)
	bar.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	bar.BorderSizePixel = 0
	bar.Parent = main

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
	UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
	UserInputService.InputChanged:Connect(function(inp)
		if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
			local p = math.clamp((inp.Position.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
			local v = math.floor(min + (max - min) * p)
			knob.Position = UDim2.new(p, -6, 0.5, -6)
			fill.Size = UDim2.new(p, 0, 1, 0)
			lbl.Text = text .. ": " .. v
			pcall(callback, v)
		end
	end)
	yPos = yPos + 45
end

-- FLY
local flyEnabled = false
local flyBodyGyro, flyBodyVel, flyHeartbeat
createToggle("Fly", function(on)
	if on then
		local char = LocalPlayer.Character
		if not char then return end
		local hum = char:FindFirstChild("Humanoid")
		local root = char:FindFirstChild("HumanoidRootPart")
		if not hum or not root then return end
		flyBodyGyro = Instance.new("BodyGyro")
		flyBodyGyro.MaxTorque = Vector3.new(400000, 400000, 400000)
		flyBodyGyro.P = 30000
		flyBodyGyro.Parent = root
		flyBodyVel = Instance.new("BodyVelocity")
		flyBodyVel.MaxForce = Vector3.new(400000, 400000, 400000)
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
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0, 1, 0) end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0, 1, 0) end
			flyBodyVel.Velocity = (dir.Magnitude > 0 and dir.Unit or Vector3.zero) * cfg.Fly.speed
			flyBodyGyro.CFrame = CFrame.new(Vector3.zero, cf.LookVector)
		end)
		reg(flyHeartbeat)
	else
		flyEnabled = false
		if flyHeartbeat then flyHeartbeat:Disconnect() end
		if flyBodyGyro then flyBodyGyro:Destroy() end
		if flyBodyVel then flyBodyVel:Destroy() end
		local ch = LocalPlayer.Character
		if ch and ch:FindFirstChild("Humanoid") then ch.Humanoid.PlatformStand = false end
	end
end)

createSlider("Fly Speed", 10, 200, 50, function(v) cfg.Fly.speed = v end)

-- WALKSPEED
createSlider("WalkSpeed", 1, 1000, 16, function(v)
	cfg.Movement.walkSpeed = v
	local ch = LocalPlayer.Character
	if ch and ch:FindFirstChild("Humanoid") then ch.Humanoid.WalkSpeed = v end
end)

-- JUMPPOWER
createSlider("JumpPower", 0, 2000, 50, function(v)
	cfg.Movement.jumpPower = v
	local ch = LocalPlayer.Character
	if ch and ch:FindFirstChild("Humanoid") then ch.Humanoid.JumpPower = v end
end)

-- NOCLIP
local noclipConn = nil
createToggle("NoClip", function(on)
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
		reg(noclipConn)
	end
end)

-- ESP (basit)
local espDrawings = {}
local espName = rndName()
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
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= LocalPlayer then
					local ch = p.Character
					if ch and ch:FindFirstChild("Head") and ch:FindFirstChild("HumanoidRootPart") and ch:FindFirstChild("Humanoid") then
						if ch.Humanoid.Health <= 0 then continue end
						local hp, onScr = Camera:WorldToViewportPoint(ch.Head.Position)
						if onScr then
							if cfg.ESP.box then
								local fp = Camera:WorldToViewportPoint((ch.HumanoidRootPart.CFrame * CFrame.new(0, -3, 0)).Position)
								local h = math.abs(fp.Y - hp.Y)
								if h > 0 then
									local bx = Drawing.new("Square")
									bx.Visible = true; bx.Color = Color3.fromRGB(0, 200, 255); bx.Thickness = 1; bx.Filled = false
									bx.Position = Vector2.new(hp.X - h/4, hp.Y); bx.Size = Vector2.new(h/2, h)
									table.insert(espDrawings, bx)
								end
							end
							if cfg.ESP.name then
								local nm = Drawing.new("Text")
								nm.Visible = true; nm.Color = Color3.fromRGB(255, 255, 255); nm.Center = true; nm.Outline = true; nm.Size = 14
								nm.Position = Vector2.new(hp.X, hp.Y - 10); nm.Text = p.Name
								table.insert(espDrawings, nm)
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
createToggle("Godmode", function(on)
	for _, c in ipairs(godmodeConns) do pcall(function() c:Disconnect() end) end
	godmodeConns = {}
	if on then
		local function setup(char)
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
		end
		if LocalPlayer.Character then setup(LocalPlayer.Character) end
		local c = LocalPlayer.CharacterAdded:Connect(function(char) task.wait(0.5); setup(char) end)
		table.insert(godmodeConns, c)
	end
end)

-- FULLBRIGHT
local originalLighting = nil
createToggle("Fullbright", function(on)
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

-- Hotkey (RightCtrl)
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.RightControl then gui.Enabled = not gui.Enabled end
end)

print("v1pro lite loaded")
