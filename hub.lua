-- lowspecistHUB v4pro – улучшенный UI, draggable, закрытие по RShift, кнопка Close
-- Полная совместимость с Xeno Executor

local Services = {
	Players = game:GetService("Players"),
	RunService = game:GetService("RunService"),
	UserInputService = game:GetService("UserInputService"),
	TeleportService = game:GetService("TeleportService"),
	Lighting = game:GetService("Lighting"),
}
local LocalPlayer = Services.Players.LocalPlayer
local Camera = workspace.CurrentCamera

local function safeCall(func, ...)
	local success, result = pcall(func, ...)
	if success then return result end
	return nil
end

-- HttpService may not be available in all executors
local HttpService = safeCall(function() return game:GetService("HttpService") end)
local function randomName()
	return string.char(97+math.random(25))..tostring(math.random(100000,999999))
end

local function getHui()
	return (safeCall(gethui) or game.CoreGui)
end

local defaultConfig = {
	Fly = { enabled = false, speed = 50 },
	Movement = { walkSpeed = 16, jumpPower = 50, infiniteJump = false, noclip = false },
	ESP = { enabled = false, box = true, name = true, health = true, distance = true, tracers = false, chams = false, teamCheck = false },
	Aimbot = { enabled = false, fov = 100, smooth = 0.2 },
	Triggerbot = { enabled = false },
	Player = { godmode = false, invisibility = false, antiFling = false, clickTP = false },
	Server = { antiAFK = false },
	Performance = { mode = false },
}

local cfg = getgenv().lowspecistHUB_Config or {}
for k, v in pairs(defaultConfig) do
	if cfg[k] == nil then cfg[k] = v end
	if type(v) == "table" then
		for subk, subv in pairs(v) do
			if cfg[k][subk] == nil then cfg[k][subk] = subv end
		end
	end
end
getgenv().lowspecistHUB_Config = cfg

local CleanUp = {}
local function RegisterCleanUp(obj)
	table.insert(CleanUp, obj)
end
function DestroyAll()
	for _, obj in ipairs(CleanUp) do
		if type(obj) == "table" and obj.Remove then obj:Remove() end
		if type(obj) == "table" and obj.Destroy then obj:Destroy() end
		if type(obj) == "userdata" and obj.Disconnect then obj:Disconnect() end
	end
	CleanUp = {}
end

-- UI элементы
local function createToggle(parent, text, configTable, key, callback)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, -10, 0, 30)
	frame.BackgroundTransparency = 1
	frame.Parent = parent

	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0, 40, 0, 20)
	button.Position = UDim2.new(0, 0, 0, 5)
	button.BorderSizePixel = 0
	button.Parent = frame

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -50, 0, 30)
	label.Position = UDim2.new(0, 50, 0, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255,255,255)
	label.Text = text
	label.Font = Enum.Font.SourceSans
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = frame

	local function updateButton()
		button.BackgroundColor3 = configTable[key] and Color3.fromRGB(0,170,0) or Color3.fromRGB(170,0,0)
	end
	updateButton()

	button.MouseButton1Click:Connect(function()
		configTable[key] = not configTable[key]
		updateButton()
		if callback then pcall(callback, configTable[key]) end
	end)
	pcall(function() if callback then callback(configTable[key]) end end)
	return frame
end

local function createSlider(parent, text, configTable, key, min, max, callback)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, -10, 0, 50)
	frame.BackgroundTransparency = 1
	frame.Parent = parent

	local value = configTable[key] or min
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 20)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255,255,255)
	label.Text = text .. ": " .. value
	label.Font = Enum.Font.SourceSans
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = frame

	local sliderFrame = Instance.new("Frame")
	sliderFrame.Size = UDim2.new(1, 0, 0, 10)
	sliderFrame.Position = UDim2.new(0, 0, 0, 20)
	sliderFrame.BackgroundColor3 = Color3.fromRGB(50,50,50)
	sliderFrame.BorderSizePixel = 0
	sliderFrame.Parent = frame

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new((value - min)/(max - min), 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(0,100,255)
	fill.BorderSizePixel = 0
	fill.Parent = sliderFrame

	local knob = Instance.new("TextButton")
	knob.Size = UDim2.new(0, 12, 0, 12)
	knob.Position = UDim2.new((value - min)/(max - min), -6, 0.5, -6)
	knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
	knob.Text = ""
	knob.BorderSizePixel = 0
	knob.Parent = sliderFrame

	local dragging = false
	local function updateSlider(input)
		local pos = math.clamp((input.Position.X - sliderFrame.AbsolutePosition.X) / sliderFrame.AbsoluteSize.X, 0, 1)
		local val = math.floor(min + (max - min) * pos)
		knob.Position = UDim2.new(pos, -6, 0.5, -6)
		fill.Size = UDim2.new(pos, 0, 1, 0)
		label.Text = text .. ": " .. val
		configTable[key] = val
		if callback then callback(val) end
	end

	knob.MouseButton1Down:Connect(function() dragging = true end)
	Services.UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
	Services.UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			updateSlider({Position = Vector2.new(input.Position.X, input.Position.Y)})
		end
	end)
	pcall(function() if callback then callback(value) end end)
	return frame
end

local function createButton(parent, text, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -10, 0, 30)
	btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
	btn.TextColor3 = Color3.fromRGB(255,255,255)
	btn.Text = text
	btn.Font = Enum.Font.SourceSans
	btn.TextSize = 14
	btn.BorderSizePixel = 0
	btn.Parent = parent
	btn.MouseButton1Click:Connect(callback)
	return btn
end

-- Создание GUI
local gui = Instance.new("ScreenGui")
gui.Name = "lowspecistHUB"
gui.Parent = getHui()
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Enabled = true

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 600, 0, 400)
mainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)
mainFrame.BorderSizePixel = 0
mainFrame.BackgroundTransparency = 0.1
mainFrame.ClipsDescendants = true
mainFrame.Parent = gui

-- Заголовок с кнопкой закрытия и перетаскиванием
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
title.Text = "lowspecistHUB v4pro"
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
closeBtn.MouseButton1Click:Connect(function()
	gui.Enabled = false
end)

-- Перетаскивание окна
local draggingWindow = false
local dragStart, frameStart
titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingWindow = true
		dragStart = input.Position
		frameStart = mainFrame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				draggingWindow = false
			end
		end)
	end
end)
Services.UserInputService.InputChanged:Connect(function(input)
	if draggingWindow and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(frameStart.X.Scale, frameStart.X.Offset + delta.X, frameStart.Y.Scale, frameStart.Y.Offset + delta.Y)
	end
end)

-- Правая панель категорий
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

-- Контентная область
local contentContainer = Instance.new("ScrollingFrame")
contentContainer.Size = UDim2.new(1, -130, 1, -30)
contentContainer.Position = UDim2.new(0, 130, 0, 30)
contentContainer.BackgroundColor3 = Color3.fromRGB(25,25,25)
contentContainer.BorderSizePixel = 0
contentContainer.ScrollBarThickness = 4
contentContainer.CanvasSize = UDim2.new(0,0,0,0)
contentContainer.ClipsDescendants = true
contentContainer.Parent = mainFrame

-- contentCanvas sized manually per visible tab

-- Категории и фреймы
local categories = {"Movement", "Visual", "Combat", "Player", "Server", "Admin", "Extra"}
local categoryButtons = {}
local categoryFrames = {}

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
	btn.MouseButton1Click:Connect(function()
		switchCategory(cat)
	end)

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, -10, 1, 0)
	frame.Position = UDim2.new(0, 5, 0, 0)
	frame.BackgroundTransparency = 1
	frame.Visible = false
	frame.Parent = contentContainer
	local frameLayout = Instance.new("UIListLayout")
	frameLayout.Parent = frame
	frameLayout.SortOrder = Enum.SortOrder.LayoutOrder
	frameLayout.Padding = UDim.new(0,3)
	categoryFrames[cat] = frame
end

local selectedCategory = nil
local function switchCategory(name)
	if selectedCategory == name then return end
	selectedCategory = name
	for _, entry in ipairs(categoryButtons) do
		entry.button.BackgroundColor3 = (entry.category == name) and Color3.fromRGB(0,100,200) or Color3.fromRGB(30,30,30)
	end
	for cat, frame in pairs(categoryFrames) do
		frame.Visible = (cat == name)
	end
	-- update canvas size to match visible content
	task.defer(function()
		local visibleFrame = categoryFrames[name]
		if visibleFrame then
			local layout = visibleFrame:FindFirstChildOfClass("UIListLayout")
			if layout then
				contentContainer.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 10)
			end
		end
	end)
end
switchCategory("Movement")

-- Kategori test
pcall(function()
	for cat, frame in pairs(categoryFrames) do
		if cat ~= "Movement" then
			frame.Visible = false
		end
	end
end)

-- Закрытие по RightShift или X
Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.RightShift or input.KeyCode == Enum.KeyCode.X then
		gui.Enabled = not gui.Enabled
	end
end)

-- Модули функционала
local activeConnections = {}
local noclipConn = nil
local function registerConn(conn)
	table.insert(activeConnections, conn)
	return conn
end
local function cleanFeatureConns()
	for _, c in ipairs(activeConnections) do
		if type(c) == "userdata" and c.Disconnect then pcall(function() c:Disconnect() end) end
	end
	activeConnections = {}
end
-- Fly
local flyEnabled = false
local flyBodyGyro, flyBodyVel, flyHeartbeat
local function startFly()
	if flyEnabled then return end
	local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local hum = char:WaitForChild("Humanoid")
	local root = char:WaitForChild("HumanoidRootPart")
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
	flyHeartbeat = Services.RunService.Heartbeat:Connect(function()
		if not flyEnabled then return end
		local moveDir = Vector3.zero
		local cf = Camera.CFrame
		if Services.UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += cf.LookVector end
		if Services.UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= cf.LookVector end
		if Services.UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= cf.RightVector end
		if Services.UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += cf.RightVector end
		if Services.UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0,1,0) end
		if Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir -= Vector3.new(0,1,0) end
		flyBodyVel.Velocity = (moveDir.Magnitude > 0 and moveDir.Unit or Vector3.zero) * cfg.Fly.speed
		flyBodyGyro.CFrame = CFrame.new(Vector3.zero, cf.LookVector)
	end)
	RegisterCleanUp(flyHeartbeat)
end
local function stopFly()
	if not flyEnabled then return end
	flyEnabled = false
	if flyHeartbeat then flyHeartbeat:Disconnect() end
	if flyBodyGyro then flyBodyGyro:Destroy() end
	if flyBodyVel then flyBodyVel:Destroy() end
	local char = LocalPlayer.Character
	if char and char:FindFirstChild("Humanoid") then char.Humanoid.PlatformStand = false end
end

-- ESP
local espDrawings = {}
local espRenderStepName = randomName()
local function removeESP()
	if Services.RunService:IsRunning() then
		pcall(function() Services.RunService:UnbindFromRenderStep(espRenderStepName) end)
	end
	for _, d in ipairs(espDrawings) do
		if d.Remove then d:Remove() end
	end
	espDrawings = {}
end
local function createESP()
	removeESP()
	if not cfg.ESP.enabled then return end
	Services.RunService:BindToRenderStep(espRenderStepName, 1, function()
		pcall(function()
			local myTeam = LocalPlayer.Team
			local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			for _, player in ipairs(Services.Players:GetPlayers()) do
				if player == LocalPlayer then continue end
				if cfg.ESP.teamCheck and player.Team == myTeam then continue end
				local char = player.Character
				if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Head") then continue end
				local head = char.Head
				local root = char.HumanoidRootPart
				local headPos, onScreen = Camera:WorldToViewportPoint(head.Position)
				if not onScreen then continue end
				local footPos = Camera:WorldToViewportPoint((root.CFrame * CFrame.new(0, -3, 0)).Position)
				local height = math.abs(footPos.Y - headPos.Y)
				if cfg.ESP.box then
					local box = Drawing.new("Square")
					box.Visible = true; box.Color = Color3.fromRGB(255,0,0); box.Thickness = 2; box.Filled = false
					local sizeX = height / 2
					box.Position = Vector2.new(headPos.X - sizeX/2, headPos.Y)
					box.Size = Vector2.new(sizeX, height)
					table.insert(espDrawings, box)
				end
				if cfg.ESP.name then
					local nm = Drawing.new("Text")
					nm.Visible = true; nm.Color = Color3.fromRGB(255,255,255); nm.Center = true; nm.Outline = true; nm.Size = 16
					nm.Position = Vector2.new(headPos.X, headPos.Y - 10)
					nm.Text = player.Name
					table.insert(espDrawings, nm)
				end
				if cfg.ESP.health then
					local humanoid = char:FindFirstChild("Humanoid")
					if humanoid and humanoid.MaxHealth > 0 then
						local healthBar = Drawing.new("Square")
						healthBar.Filled = true
						local healthPercent = humanoid.Health / humanoid.MaxHealth
						healthBar.Position = Vector2.new(headPos.X - 5 - height/4 - 2, headPos.Y + height*(1-healthPercent))
						healthBar.Size = Vector2.new(4, height * healthPercent)
						healthBar.Color = Color3.fromRGB(255*(1-healthPercent), 255*healthPercent, 0)
						table.insert(espDrawings, healthBar)
					end
				end
				if cfg.ESP.distance then
					local distDraw = Drawing.new("Text")
					distDraw.Visible = true; distDraw.Color = Color3.fromRGB(200,200,200); distDraw.Center = true; distDraw.Size = 14
					local dist = myRoot and math.floor((myRoot.Position - root.Position).Magnitude) or 0
					distDraw.Position = Vector2.new(headPos.X, headPos.Y + 10)
					distDraw.Text = dist .. "m"
					table.insert(espDrawings, distDraw)
				end
				if cfg.ESP.tracers then
					local tracer = Drawing.new("Line")
					tracer.Visible = true; tracer.Color = Color3.fromRGB(255,0,0); tracer.Thickness = 1
					local screenMy = myRoot and Camera:WorldToViewportPoint(myRoot.Position)
					local screenTarget = Camera:WorldToViewportPoint(root.Position)
					if screenMy and screenMy.Z > 0 and screenTarget.Z > 0 then
						tracer.From = Vector2.new(screenMy.X, screenMy.Y)
						tracer.To = Vector2.new(screenTarget.X, screenTarget.Y)
					end
					table.insert(espDrawings, tracer)
				end
			end
		end)
	end)
end

-- Chams
local chamsHighlights = {}
local function applyChams()
	for _, hl in ipairs(chamsHighlights) do hl:Destroy() end
	chamsHighlights = {}
	if not cfg.ESP.chams then return end
	for _, player in ipairs(Services.Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local char = player.Character
			if char then
				local hl = Instance.new("Highlight")
				hl.Name = randomName()
				hl.FillColor = Color3.fromRGB(255,0,0)
				hl.OutlineColor = Color3.fromRGB(255,0,0)
				hl.FillTransparency = 0.5
				hl.OutlineTransparency = 0
				hl.Parent = char
				table.insert(chamsHighlights, hl)
			end
		end
	end
end

-- Aimbot
local aimbotActive = false
local aimbotRenderStep = randomName()
local function startAimbot()
	if aimbotActive then return end
	aimbotActive = true
	Services.RunService:BindToRenderStep(aimbotRenderStep, 2, function()
		pcall(function()
			if not cfg.Aimbot.enabled and not cfg.Triggerbot.enabled then return end
			local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			if not myRoot then return end
			local closestDist = cfg.Aimbot.fov
			local target = nil
			local screenCenter = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
			for _, player in ipairs(Services.Players:GetPlayers()) do
				if player == LocalPlayer then continue end
				local char = player.Character
				if char and char:FindFirstChild("Head") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
					local screenPos, onScreen = Camera:WorldToViewportPoint(char.Head.Position)
					if onScreen then
						local distFromCenter = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
						if distFromCenter < closestDist then
							closestDist = distFromCenter
							target = player
						end
					end
				end
			end
			if cfg.Aimbot.enabled and target then
				local tChar = target.Character
				if tChar and tChar:FindFirstChild("Head") then
					local head = tChar.Head
					Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, head.Position), cfg.Aimbot.smooth)
				end
			end
		end)
	end)
end
local function stopAimbot()
	aimbotActive = false
	pcall(function() Services.RunService:UnbindFromRenderStep(aimbotRenderStep) end)
end

-- Player effects
local function applyGodmode(enabled)
	if enabled then
		local function makeInvincible(char)
			local hum = char:WaitForChild("Humanoid")
			hum.MaxHealth = math.huge
			hum.Health = math.huge
			local conn = hum.HealthChanged:Connect(function() hum.Health = math.huge end)
			RegisterCleanUp(conn)
		end
		if LocalPlayer.Character then makeInvincible(LocalPlayer.Character) end
		local conn = LocalPlayer.CharacterAdded:Connect(makeInvincible)
		RegisterCleanUp(conn)
	else
		if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
			LocalPlayer.Character.Humanoid.MaxHealth = 100
			LocalPlayer.Character.Humanoid.Health = 100
		end
	end
end
local function applyInvisibility(enabled)
	local transparency = enabled and 0.9 or 0
	local function setTransparency(char)
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") and part.Transparency < 1 then
				part.Transparency = transparency
			end
		end
	end
	if LocalPlayer.Character then setTransparency(LocalPlayer.Character) end
	local conn = LocalPlayer.CharacterAdded:Connect(setTransparency)
	RegisterCleanUp(conn)
end
local function applyAntiFling(enabled)
	if enabled then
		local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
		local root = char:WaitForChild("HumanoidRootPart")
		local lastSafe = root.Velocity
		local conn = Services.RunService.Heartbeat:Connect(function()
			if not root or not root.Parent then return end
			pcall(function()
				if root.Velocity.Magnitude > 200 then
					root.Velocity = lastSafe
				else
					lastSafe = root.Velocity
				end
			end)
		end)
		registerConn(conn)
	end
end
local function applyClickTP(enabled)
	if enabled then
		local conn = Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then return end
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				local mousePos = Services.UserInputService:GetMouseLocation()
				local ray = Camera:ScreenPointToRay(mousePos.X, mousePos.Y)
				local params = RaycastParams.new()
				params.FilterType = Enum.RaycastFilterType.Exclude
				local ignoreList = {}
				if LocalPlayer.Character then
					for _, child in ipairs(LocalPlayer.Character:GetChildren()) do
						if child:IsA("BasePart") then table.insert(ignoreList, child) end
					end
				end
				params.FilterDescendantsInstances = ignoreList
				local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
				if result and result.Position then
					local char = LocalPlayer.Character
					if char and char:FindFirstChild("HumanoidRootPart") then
						char.HumanoidRootPart.CFrame = CFrame.new(result.Position + Vector3.new(0,3,0))
					end
				end
			end
		end)
		RegisterCleanUp(conn)
	end
end

-- Server functions
local function rejoin()
	Services.TeleportService:Teleport(game.PlaceId, LocalPlayer)
end
local function serverHop()
	if not HttpService then return end
	local servers = {}
	local function fetch(cursor)
		local url = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?limit=100"..(cursor and "&cursor="..cursor or "")
		local success, response = pcall(function() return HttpService:JSONDecode(game:HttpGet(url)) end)
		if success and response and response.data then
			for _, s in ipairs(response.data) do
				if s.playing < s.maxPlayers then table.insert(servers, s.id) end
			end
			if #servers < 10 and response.nextPageCursor then fetch(response.nextPageCursor) end
		end
	end
	fetch()
	if #servers > 0 then
		Services.TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1,#servers)], LocalPlayer)
	end
end
local function enableAntiAFK()
	local vu = game:GetService("VirtualUser")
	local conn = LocalPlayer.Idled:Connect(function()
		vu:CaptureController()
		vu:ClickButton2(Vector2.new())
	end)
	registerConn(conn)
end

-- Karakter ölüm/respawn handler
local function onCharacterDeath()
	-- Fly temizle
	if flyEnabled then
		if flyHeartbeat then flyHeartbeat:Disconnect() flyHeartbeat = nil end
		if flyBodyGyro then pcall(function() flyBodyGyro:Destroy() end) flyBodyGyro = nil end
		if flyBodyVel then pcall(function() flyBodyVel:Destroy() end) flyBodyVel = nil end
		flyEnabled = false
	end
	-- Anti-fling connection temizle
	cleanFeatureConns()
end

local function onCharacterSpawn(char)
	-- Fly aktifse yeniden başlat
	if cfg.Fly.enabled then
		task.defer(function()
			local root = char:WaitForChild("HumanoidRootPart", 3)
			if root then startFly() end
		end)
	end
	-- Noclip aktifse yeniden başlat
	if cfg.Movement.noclip then
		task.defer(function()
			noclipConn = Services.RunService.Stepped:Connect(function()
				local c = LocalPlayer.Character
				if c then
					for _, part in ipairs(c:GetDescendants()) do
						if part:IsA("BasePart") then part.CanCollide = false end
					end
				end
			end)
			registerConn(noclipConn)
		end)
	end
	-- Godmode aktifse yeniden uygula
	if cfg.Player.godmode then
		task.defer(function()
			local hum = char:WaitForChild("Humanoid", 3)
			if hum then
				hum.MaxHealth = math.huge
				hum.Health = math.huge
			end
		end)
	end
end

LocalPlayer.CharacterAdded:Connect(function(char)
	onCharacterDeath()
	local hum = char:WaitForChild("Humanoid", 10)
	if hum then
		hum.Died:Connect(function()
			onCharacterDeath()
		end)
	end
	onCharacterSpawn(char)
end)

-- Заполнение категорий
do
	local movFrame = categoryFrames["Movement"]
	createToggle(movFrame, "Fly", cfg.Fly, "enabled", function(on) if on then startFly() else stopFly() end end)
	createSlider(movFrame, "Fly Speed", cfg.Fly, "speed", 10, 200)
	createSlider(movFrame, "WalkSpeed", cfg.Movement, "walkSpeed", 1, 200, function(val)
		if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
			LocalPlayer.Character.Humanoid.WalkSpeed = val
		end
	end)
	createSlider(movFrame, "JumpPower", cfg.Movement, "jumpPower", 0, 500, function(val)
		if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
			LocalPlayer.Character.Humanoid.JumpPower = val
		end
	end)
	local infiniteJumpConn = nil
	createToggle(movFrame, "Infinite Jump", cfg.Movement, "infiniteJump", function(on)
		if infiniteJumpConn then infiniteJumpConn:Disconnect() end
		infiniteJumpConn = nil
		if on then
			infiniteJumpConn = Services.UserInputService.JumpRequest:Connect(function()
				local char = LocalPlayer.Character
				if char and char:FindFirstChild("Humanoid") then char.Humanoid.Jump = true end
			end)
			registerConn(infiniteJumpConn)
		end
	end)
	noclipConn = nil
	createToggle(movFrame, "NoClip", cfg.Movement, "noclip", function(on)
		if noclipConn then noclipConn:Disconnect() end
		noclipConn = nil
		if on then
			noclipConn = Services.RunService.Stepped:Connect(function()
				local char = LocalPlayer.Character
				if char then
					for _, part in ipairs(char:GetDescendants()) do
						if part:IsA("BasePart") then part.CanCollide = false end
					end
				end
			end)
			registerConn(noclipConn)
		end
	end)

	local visFrame = categoryFrames["Visual"]
	createToggle(visFrame, "ESP Master", cfg.ESP, "enabled", function(on) createESP() end)
	createToggle(visFrame, "Box", cfg.ESP, "box", function() createESP() end)
	createToggle(visFrame, "Name", cfg.ESP, "name", function() createESP() end)
	createToggle(visFrame, "Health", cfg.ESP, "health", function() createESP() end)
	createToggle(visFrame, "Distance", cfg.ESP, "distance", function() createESP() end)
	createToggle(visFrame, "Tracers", cfg.ESP, "tracers", function() createESP() end)
	createToggle(visFrame, "Chams", cfg.ESP, "chams", function() applyChams() end)
	createToggle(visFrame, "Team Check", cfg.ESP, "teamCheck", function() createESP(); applyChams() end)

	local combatFrame = categoryFrames["Combat"]
	createToggle(combatFrame, "Aimbot", cfg.Aimbot, "enabled", function(on) if on then startAimbot() else stopAimbot() end end)
	createSlider(combatFrame, "FOV", cfg.Aimbot, "fov", 10, 360)
	createSlider(combatFrame, "Smooth", cfg.Aimbot, "smooth", 0.01, 1)
	createToggle(combatFrame, "Triggerbot", cfg.Triggerbot, "enabled", function(on) startAimbot() end)

	local playerFrame = categoryFrames["Player"]
	createToggle(playerFrame, "Godmode", cfg.Player, "godmode", applyGodmode)
	createToggle(playerFrame, "Invisibility", cfg.Player, "invisibility", applyInvisibility)
	createToggle(playerFrame, "Anti-Fling", cfg.Player, "antiFling", applyAntiFling)
	createToggle(playerFrame, "Click TP", cfg.Player, "clickTP", applyClickTP)

	local servFrame = categoryFrames["Server"]
	createButton(servFrame, "Rejoin", rejoin)
	createButton(servFrame, "Server Hop", serverHop)
	createToggle(servFrame, "Anti-AFK", cfg.Server, "antiAFK", function(on) if on then enableAntiAFK() end end)

	local adminFrame = categoryFrames["Admin"]
	local cmdBox = Instance.new("TextBox")
	cmdBox.Size = UDim2.new(1, -10, 0, 30)
	cmdBox.Position = UDim2.new(0, 5, 0, 5)
	cmdBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
	cmdBox.TextColor3 = Color3.fromRGB(255,255,255)
	cmdBox.PlaceholderText = "cmd (rejoin, print ...)"
	cmdBox.Font = Enum.Font.Code
	cmdBox.TextSize = 14
	cmdBox.Parent = adminFrame
	cmdBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			local cmd = cmdBox.Text
			if cmd == "rejoin" then rejoin()
			end
			cmdBox.Text = ""
		end
	end)

	local extraFrame = categoryFrames["Extra"]
	createButton(extraFrame, "Save Settings", function() end)
	createButton(extraFrame, "Load Settings", function() end)
	createToggle(extraFrame, "Performance Mode", cfg.Performance, "mode", function(on)
		pcall(function()
			local settings = UserSettings():GetService("UserGameSettings")
			settings.RenderingQualityLevel = on and Enum.QualityLevel.Level01 or Enum.QualityLevel.Level21
		end)
	end)
end

LocalPlayer.OnTeleport:Connect(function()
	cleanFeatureConns()
	stopFly()
	stopAimbot()
	removeESP()
	for _, hl in ipairs(chamsHighlights) do hl:Destroy() end
	chamsHighlights = {}
end)

-- loaded silently
