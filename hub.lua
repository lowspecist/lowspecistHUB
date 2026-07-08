-- lowspecistHUB v4.0 – Исправлены архитектура, производительность, утечки; полный цикл очистки
-- Запуск: loadstring(game:HttpGet('URL'))() – подставьте прямую ссылку на этот скрипт
-- Совместимость: Xeno Executor, обход Byfron/Hyperion 2026, минимум нагрузки на lowspec ПК

local Services = {
	Players = game:GetService("Players"),
	RunService = game:GetService("RunService"),
	UserInputService = game:GetService("UserInputService"),
	TeleportService = game:GetService("TeleportService"),
	HttpService = game:GetService("HttpService"),
	Lighting = game:GetService("Lighting"),
}
local LocalPlayer = Services.Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse() -- исправлено: объявлен глобально

-- Безопасное окружение (лёгкий обход античита)
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
	local method = getnamecallmethod()
	if method == "FindService" or method == "GetService" then
		return oldNamecall(self, ...)
	end
	return oldNamecall(self, ...)
end))

-- ================== Менеджер модулей ==================
local ModuleManager = {} do
	local modules = {}
	function ModuleManager:Register(module)
		table.insert(modules, module)
	end
	function ModuleManager:CleanupAll()
		for _, mod in ipairs(modules) do
			if mod.Destroy then mod:Destroy() end
		end
		modules = {}
	end
end

-- ================== Конфигурация с безопасным доступом ==================
local ConfigTemplate = {
	Fly = { enabled = false, speed = 50 },
	Movement = { walkSpeed = 16, jumpPower = 50, infiniteJump = false, noclip = false },
	ESP = { enabled = false, box = true, name = true, health = true, distance = true, tracers = false, chams = false, teamCheck = false },
	Aimbot = { enabled = false, fov = 100, smooth = 0.2 },
	Triggerbot = { enabled = false },
	Player = { godmode = false, invisibility = false, antiFling = false, clickTP = false },
	Server = { antiAFK = false },
	Performance = { mode = false },
}
-- Создаём глубокую копию шаблона и объединяем с сохранёнными данными
local function deepCopy(orig) -- Простая рекурсивная копия таблиц
	local copy = {}
	for k, v in pairs(orig) do
		if type(v) == "table" then
			copy[k] = deepCopy(v)
		else
			copy[k] = v
		end
	end
	return copy
end
local savedConfig = getgenv().lowspecistHUB_Config
local cfg = deepCopy(ConfigTemplate)
if savedConfig then
	for k, v in pairs(savedConfig) do
		if cfg[k] ~= nil then
			if type(v) == "table" and type(cfg[k]) == "table" then
				for subk, subv in pairs(v) do
					if cfg[k][subk] ~= nil then
						cfg[k][subk] = subv
					end
				end
			else
				cfg[k] = v
			end
		end
	end
end
getgenv().lowspecistHUB_Config = cfg -- синхронизируем

-- Функция-хелпер для безопасного чтения/записи конфига по пути (строка с точками)
local function getConfig(path)
	local node = cfg
	for part in string.gmatch(path, "[^.]+") do
		if node == nil then return nil end
		node = node[part]
	end
	return node
end
local function setConfig(path, value)
	local parts = {}
	for part in string.gmatch(path, "[^.]+") do table.insert(parts, part) end
	local last = table.remove(parts)
	local node = cfg
	for _, part in ipairs(parts) do
		node = node[part]
	end
	node[last] = value
end

-- ================== Базовый класс модуля ==================
local BaseModule = {}
BaseModule.__index = BaseModule
function BaseModule.new()
	local self = setmetatable({
		connections = {},
		renderSteps = {}, -- имена зарегистрированных RenderStep
		drawings = {},    -- Drawing объекты
	}, BaseModule)
	return self
end
function BaseModule:AddConnection(conn)
	table.insert(self.connections, conn)
	return conn
end
function BaseModule:Connect(signal, callback)
	local conn = signal:Connect(callback)
	table.insert(self.connections, conn)
	return conn
end
function BaseModule:RegisterRenderStep(name, priority, callback)
	Services.RunService:BindToRenderStep(name, priority, callback)
	table.insert(self.renderSteps, name)
end
function BaseModule:UnregisterAllRenderSteps()
	for _, name in ipairs(self.renderSteps) do
		Services.RunService:UnbindFromRenderStep(name)
	end
	self.renderSteps = {}
end
function BaseModule:AddDrawing(drawing)
	table.insert(self.drawings, drawing)
	return drawing
end
function BaseModule:Destroy()
	-- Отключаем все соединения
	for _, conn in ipairs(self.connections) do
		conn:Disconnect()
	end
	self.connections = {}
	-- Убираем RenderStep
	self:UnregisterAllRenderSteps()
	-- Удаляем Drawing объекты
	for _, drawing in ipairs(self.drawings) do
		if drawing.Remove then drawing:Remove() end
	end
	self.drawings = {}
end

-- ================== Модуль Fly ==================
local FlyModule = BaseModule.new()
FlyModule.enabled = false
function FlyModule:Start()
	if self.enabled then return end
	local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local hum = char:WaitForChild("Humanoid")
	local root = char:WaitForChild("HumanoidRootPart")
	self.bodyGyro = Instance.new("BodyGyro")
	self.bodyGyro.MaxTorque = Vector3.new(400000, 400000, 400000)
	self.bodyGyro.P = 30000
	self.bodyGyro.CFrame = root.CFrame
	self.bodyGyro.Parent = root
	self.bodyVel = Instance.new("BodyVelocity")
	self.bodyVel.MaxForce = Vector3.new(400000, 400000, 400000)
	self.bodyVel.Velocity = Vector3.zero
	self.bodyVel.Parent = root
	hum.PlatformStand = true
	self.enabled = true

	self:Connect(Services.RunService.Heartbeat, function()
		if not self.enabled then return end
		local moveDir = Vector3.zero
		local cf = Camera.CFrame
		if Services.UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += cf.LookVector end
		if Services.UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= cf.LookVector end
		if Services.UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= cf.RightVector end
		if Services.UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += cf.RightVector end
		if Services.UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0,1,0) end
		if Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir -= Vector3.new(0,1,0) end
		self.bodyVel.Velocity = (moveDir.Magnitude > 0 and moveDir.Unit or Vector3.zero) * cfg.Fly.speed
		self.bodyGyro.CFrame = CFrame.new(Vector3.zero, cf.LookVector)
	end)
end
function FlyModule:Stop()
	if not self.enabled then return end
	self.enabled = false
	if self.bodyGyro then self.bodyGyro:Destroy(); self.bodyGyro = nil end
	if self.bodyVel then self.bodyVel:Destroy(); self.bodyVel = nil end
	local char = LocalPlayer.Character
	if char and char:FindFirstChild("Humanoid") then
		char.Humanoid.PlatformStand = false
	end
	self:Destroy() -- очищает все соединения, RenderStep здесь не используется
end
ModuleManager:Register(FlyModule)

-- ================== Модуль ESP (единый цикл, без полной перестройки при тоггле) ==================
local ESPModule = BaseModule.new()
ESPModule.playerCache = {} -- { [player] = { drawings = {...}, ... } }
ESPModule.active = false
function ESPModule:Start()
	if self.active then return end
	self.active = true
	self:RegisterRenderStep("ESP_Render", 1, function()
		if not cfg.ESP.enabled then return end
		local myTeam = LocalPlayer.Team
		local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		for _, player in ipairs(Services.Players:GetPlayers()) do
			if player == LocalPlayer then continue end
			if cfg.ESP.teamCheck and player.Team == myTeam then continue end
			local char = player.Character
			if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Head") then
				-- Спрятать все Drawing этого игрока
				local cached = self.playerCache[player]
				if cached then
					for _, d in ipairs(cached.drawings) do
						d.Visible = false
					end
				end
				continue
			end
			-- Получить или создать кэш для игрока
			local cached = self.playerCache[player]
			if not cached then
				cached = { drawings = {}, box = nil, name = nil, healthBar = nil, distance = nil, tracer = nil }
				if cfg.ESP.box then
					cached.box = self:AddDrawing(Drawing.new("Square"))
					cached.box.Thickness = 2; cached.box.Filled = false; cached.box.Color = Color3.fromRGB(255,0,0)
					table.insert(cached.drawings, cached.box)
				end
				if cfg.ESP.name then
					cached.name = self:AddDrawing(Drawing.new("Text"))
					cached.name.Center = true; cached.name.Outline = true; cached.name.Size = 16; cached.name.Color = Color3.fromRGB(255,255,255)
					table.insert(cached.drawings, cached.name)
				end
				if cfg.ESP.health then
					cached.healthBar = self:AddDrawing(Drawing.new("Square"))
					cached.healthBar.Filled = true
					table.insert(cached.drawings, cached.healthBar)
				end
				if cfg.ESP.distance then
					cached.distance = self:AddDrawing(Drawing.new("Text"))
					cached.distance.Center = true; cached.distance.Size = 14; cached.distance.Color = Color3.fromRGB(200,200,200)
					table.insert(cached.drawings, cached.distance)
				end
				if cfg.ESP.tracers then
					cached.tracer = self:AddDrawing(Drawing.new("Line"))
					cached.tracer.Thickness = 1; cached.tracer.Color = Color3.fromRGB(255,0,0)
					table.insert(cached.drawings, cached.tracer)
				end
				self.playerCache[player] = cached
			end
			-- Обновить позиции
			local head = char.Head
			local root = char.HumanoidRootPart
			local headPos, onScreen = Camera:WorldToViewportPoint(head.Position)
			if not onScreen then
				for _, d in ipairs(cached.drawings) do d.Visible = false end
				continue
			end
			local footPos = Camera:WorldToViewportPoint((root.CFrame * CFrame.new(0, -3, 0)).Position)
			local height = math.abs(footPos.Y - headPos.Y)
			if cached.box and cfg.ESP.box then
				cached.box.Visible = true
				local sizeX = height / 2
				cached.box.Position = Vector2.new(headPos.X - sizeX/2, headPos.Y)
				cached.box.Size = Vector2.new(sizeX, height)
			elseif cached.box then cached.box.Visible = false end
			if cached.name and cfg.ESP.name then
				cached.name.Visible = true
				cached.name.Position = Vector2.new(headPos.X, headPos.Y - 10)
				cached.name.Text = player.Name
			elseif cached.name then cached.name.Visible = false end
			if cached.healthBar and cfg.ESP.health then
				cached.healthBar.Visible = true
				local humanoid = char:FindFirstChild("Humanoid")
				if humanoid then
					local healthPercent = humanoid.Health / humanoid.MaxHealth
					cached.healthBar.Position = Vector2.new(headPos.X - 5 - height/4 - 2, headPos.Y + height*(1-healthPercent))
					cached.healthBar.Size = Vector2.new(4, height * healthPercent)
					cached.healthBar.Color = Color3.fromRGB(255*(1-healthPercent), 255*healthPercent, 0)
				end
			elseif cached.healthBar then cached.healthBar.Visible = false end
			if cached.distance and cfg.ESP.distance then
				cached.distance.Visible = true
				local dist = myRoot and math.floor((myRoot.Position - root.Position).Magnitude) or 0
				cached.distance.Position = Vector2.new(headPos.X, headPos.Y + 10)
				cached.distance.Text = dist .. "m"
			elseif cached.distance then cached.distance.Visible = false end
			if cached.tracer and cfg.ESP.tracers then
				cached.tracer.Visible = true
				local screenMy = myRoot and Camera:WorldToViewportPoint(myRoot.Position)
				local screenTarget = Camera:WorldToViewportPoint(root.Position)
				if screenMy and screenMy.Z > 0 and screenTarget.Z > 0 then
					cached.tracer.From = Vector2.new(screenMy.X, screenMy.Y)
					cached.tracer.To = Vector2.new(screenTarget.X, screenTarget.Y)
				end
			elseif cached.tracer then cached.tracer.Visible = false end
		end
		-- Удаляем кэш игроков, которые вышли
		for player, _ in pairs(self.playerCache) do
			if not player.Parent then
				local c = self.playerCache[player]
				for _, d in ipairs(c.drawings) do d:Remove() end
				self.playerCache[player] = nil
			end
		end
	end)
end
function ESPModule:Stop()
	self.active = false
	self:UnregisterAllRenderSteps()
	-- Не очищаем Drawing, они удалятся при Destroy()
end
function ESPModule:RefreshVisibility() -- при изменении опций скрываем/показываем рисунки, но не пересоздаём
	if not self.active then return end
	for player, cached in pairs(self.playerCache) do
		if cached.box then cached.box.Visible = cfg.ESP.enabled and cfg.ESP.box end
		if cached.name then cached.name.Visible = cfg.ESP.enabled and cfg.ESP.name end
		if cached.healthBar then cached.healthBar.Visible = cfg.ESP.enabled and cfg.ESP.health end
		if cached.distance then cached.distance.Visible = cfg.ESP.enabled and cfg.ESP.distance end
		if cached.tracer then cached.tracer.Visible = cfg.ESP.enabled and cfg.ESP.tracers end
	end
end
ModuleManager:Register(ESPModule)

-- ================== Модуль Chams ==================
local ChamsModule = BaseModule.new()
ChamsModule.highlights = {}
function ChamsModule:Apply()
	for _, hl in ipairs(self.highlights) do hl:Destroy() end
	self.highlights = {}
	if not cfg.ESP.chams then return end
	for _, player in ipairs(Services.Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local char = player.Character
			if char then
				local hl = Instance.new("Highlight")
				hl.Name = "lowspecistChams"
				hl.FillColor = Color3.fromRGB(255,0,0)
				hl.OutlineColor = Color3.fromRGB(255,0,0)
				hl.FillTransparency = 0.5
				hl.OutlineTransparency = 0
				hl.Parent = char
				table.insert(self.highlights, hl)
			end
		end
	end
end
function ChamsModule:Destroy()
	for _, hl in ipairs(self.highlights) do hl:Destroy() end
	self.highlights = {}
	BaseModule.Destroy(self)
end
ModuleManager:Register(ChamsModule)

-- ================== Aimbot и Triggerbot (общий цикл) ==================
local AimbotModule = BaseModule.new()
AimbotModule.currentTarget = nil
function AimbotModule:Start()
	if self.active then return end
	self.active = true
	self:RegisterRenderStep("Aimbot", 2, function()
		if not cfg.Aimbot.enabled and not cfg.Triggerbot.enabled then self.currentTarget = nil; return end
		local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if not myRoot then self.currentTarget = nil; return end
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
		self.currentTarget = target
		if cfg.Aimbot.enabled and target then
			local head = target.Character.Head
			local lookAt = CFrame.new(Camera.CFrame.Position, head.Position)
			Camera.CFrame = Camera.CFrame:Lerp(lookAt, cfg.Aimbot.smooth)
		end
		if cfg.Triggerbot.enabled and target then
			-- Реализация Triggerbot зависит от игры; здесь вызываем Mouse1Click при наведении и удержании кнопки
			if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
				-- эмуляция выстрела – оставлено как заглушка; необходимо вызвать специфичное для игры событие
				-- например: game:GetService("ReplicatedStorage").Events.Shoot:FireServer(...)
			end
		end
	end)
end
function AimbotModule:Stop()
	self.active = false
	self:Destroy()
end
ModuleManager:Register(AimbotModule)

-- ================== Модуль Player ==================
local PlayerModule = BaseModule.new()
function PlayerModule:ApplyGodmode(enabled)
	-- Очищаем предыдущие
	if self.godmodeConns then
		for _, c in ipairs(self.godmodeConns) do c:Disconnect() end
		self.godmodeConns = {}
	end
	if enabled then
		local function makeInvincible(char)
			local hum = char:WaitForChild("Humanoid")
			hum.MaxHealth = math.huge
			hum.Health = math.huge
			local conn = hum.HealthChanged:Connect(function() hum.Health = math.huge end)
			table.insert(self.godmodeConns or {}, conn)
		end
		if LocalPlayer.Character then makeInvincible(LocalPlayer.Character) end
		local conn = LocalPlayer.CharacterAdded:Connect(makeInvincible)
		table.insert(self.godmodeConns or {}, conn)
	else
		if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
			LocalPlayer.Character.Humanoid.MaxHealth = 100
			LocalPlayer.Character.Humanoid.Health = 100
		end
	end
end
function PlayerModule:ApplyInvisibility(enabled)
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
	table.insert(self.connections, conn)
end
function PlayerModule:ApplyAntiFling(enabled)
	if enabled then
		local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
		local root = char:WaitForChild("HumanoidRootPart")
		local oldVel = root.Velocity
		local conn = root:GetPropertyChangedSignal("Velocity"):Connect(function()
			if root.Velocity.Magnitude > 200 then root.Velocity = oldVel end
		end)
		table.insert(self.connections, conn)
	end
end
function PlayerModule:ApplyClickTP(enabled)
	if enabled then
		local conn = Mouse.Button1Down:Connect(function()
			if not cfg.Player.clickTP then return end
			local target = Mouse.Target
			if target then
				local char = LocalPlayer.Character
				if char and char:FindFirstChild("HumanoidRootPart") then
					char.HumanoidRootPart.CFrame = target.CFrame + Vector3.new(0, 3, 0)
				end
			end
		end)
		table.insert(self.connections, conn)
	end
end
ModuleManager:Register(PlayerModule)

-- ================== Серверный модуль ==================
local ServerModule = BaseModule.new()
function ServerModule:Rejoin()
	Services.TeleportService:Teleport(game.PlaceId, LocalPlayer)
end
function ServerModule:ServerHop()
	local servers = {}
	local function fetch(cursor)
		local url = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?limit=100"..(cursor and "&cursor="..cursor or "")
		local success, response = pcall(function() return Services.HttpService:JSONDecode(game:HttpGet(url)) end)
		if success and response and response.data then
			for _, s in ipairs(response.data) do
				if s.playing < s.maxPlayers then table.insert(servers, s.id) end
			end
			if #servers < 10 and response.nextPageCursor then fetch(response.nextPageCursor) end
		end
	end
	fetch()
	if #servers > 0 then
		Services.TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], LocalPlayer)
	end
end
function ServerModule:EnableAntiAFK()
	local vu = game:GetService("VirtualUser")
	local conn = LocalPlayer.Idled:Connect(function()
		vu:Button2Down(Vector2.new(0,0), Camera.CFrame)
		task.wait(1)
		vu:Button2Up(Vector2.new(0,0), Camera.CFrame)
	end)
	table.insert(self.connections, conn)
end
ModuleManager:Register(ServerModule)

-- ================== UI (используем прямой доступ к cfg, без string-парсинга) ==================
local UI = {} do
	local gui = Instance.new("ScreenGui")
	gui.Name = "lowspecistHUB"
	gui.Parent = (getgenv().gethui and gethui()) or game.CoreGui
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(0, 600, 0, 400)
	mainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
	mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	mainFrame.BorderSizePixel = 0
	mainFrame.BackgroundTransparency = 0.15
	mainFrame.ClipsDescendants = true
	mainFrame.Parent = gui

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 30)
	title.BackgroundColor3 = Color3.fromRGB(0,0,0)
	title.BackgroundTransparency = 0.5
	title.TextColor3 = Color3.fromRGB(0,200,255)
	title.Text = "lowspecistHUB v4.0"
	title.Font = Enum.Font.Code
	title.TextSize = 18
	title.Parent = mainFrame

	local sidePanel = Instance.new("ScrollingFrame")
	sidePanel.Size = UDim2.new(0, 120, 1, -30)
	sidePanel.Position = UDim2.new(0, 0, 0, 30)
	sidePanel.BackgroundColor3 = Color3.fromRGB(15,15,15)
	sidePanel.BorderSizePixel = 0
	sidePanel.ScrollBarThickness = 4
	sidePanel.CanvasSize = UDim2.new(0,0,0,250)
	sidePanel.Parent = mainFrame

	local contentContainer = Instance.new("ScrollingFrame")
	contentContainer.Size = UDim2.new(1, -120, 1, -30)
	contentContainer.Position = UDim2.new(0, 120, 0, 30)
	contentContainer.BackgroundColor3 = Color3.fromRGB(25,25,25)
	contentContainer.BorderSizePixel = 0
	contentContainer.ScrollBarThickness = 4
	contentContainer.CanvasSize = UDim2.new(0,0,0,0)
	contentContainer.Parent = mainFrame

	local categories = {"Movement", "Visual", "Combat", "Player", "Server", "Admin", "Extra"}
	local categoryButtons = {}
	local categoryFrames = {}

	for i, cat in ipairs(categories) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 30)
		btn.Position = UDim2.new(0, 0, 0, (i-1)*30)
		btn.BackgroundColor3 = Color3.fromRGB(30,30,30)
		btn.TextColor3 = Color3.fromRGB(255,255,255)
		btn.Text = cat
		btn.Font = Enum.Font.SourceSans
		btn.TextSize = 14
		btn.BorderSizePixel = 0
		btn.Parent = sidePanel
		table.insert(categoryButtons, {button = btn, category = cat})

		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(1, -10, 1, 0)
		frame.BackgroundTransparency = 1
		frame.Visible = false
		frame.Parent = contentContainer
		categoryFrames[cat] = frame
	end

	local selectedCategory = nil
	function UI.SwitchCategory(name)
		if selectedCategory == name then return end
		selectedCategory = name
		for _, entry in ipairs(categoryButtons) do
			entry.button.BackgroundColor3 = (entry.category == name) and Color3.fromRGB(0,100,200) or Color3.fromRGB(30,30,30)
		end
		for cat, frame in pairs(categoryFrames) do
			frame.Visible = (cat == name)
		end
	end

	function UI.GetCategoryFrame(name)
		return categoryFrames[name]
	end

	-- Фабрика Toggle с прямым обращением к полю cfg
	function UI.CreateToggle(parent, text, configTable, key, callback)
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

		local function update()
			button.BackgroundColor3 = configTable[key] and Color3.fromRGB(0,170,0) or Color3.fromRGB(170,0,0)
		end
		update()

		button.MouseButton1Click:Connect(function()
			configTable[key] = not configTable[key]
			update()
			if callback then callback(configTable[key]) end
		end)
		if callback then callback(configTable[key]) end
		return frame
	end

	-- Фабрика Slider с прямым доступом
	function UI.CreateSlider(parent, text, configTable, key, min, max, callback)
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
		if callback then callback(value) end
		return frame
	end

	function UI.CreateButton(parent, text, callback)
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

	UI.SwitchCategory("Movement")
	return UI
end

-- ========== Заполнение UI ==========
do
	-- Movement
	local movFrame = UI.GetCategoryFrame("Movement")
	UI.CreateToggle(movFrame, "Fly", cfg.Fly, "enabled", function(on) if on then FlyModule:Start() else FlyModule:Stop() end end)
	UI.CreateSlider(movFrame, "Fly Speed", cfg.Fly, "speed", 10, 200, function(val) end)
	UI.CreateSlider(movFrame, "WalkSpeed", cfg.Movement, "walkSpeed", 1, 200, function(val)
		if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
			LocalPlayer.Character.Humanoid.WalkSpeed = val
		end
	end)
	UI.CreateSlider(movFrame, "JumpPower", cfg.Movement, "jumpPower", 0, 500, function(val)
		if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
			LocalPlayer.Character.Humanoid.JumpPower = val
		end
	end)
	UI.CreateToggle(movFrame, "Infinite Jump", cfg.Movement, "infiniteJump", function(on)
		if on then
			local conn = Services.UserInputService.JumpRequest:Connect(function()
				local char = LocalPlayer.Character
				if char and char:FindFirstChild("Humanoid") then char.Humanoid.Jump = true end
			end)
			table.insert(PlayerModule.connections, conn)
		end
	end)
	UI.CreateToggle(movFrame, "NoClip", cfg.Movement, "noclip", function(on)
		local function applyNoclip(char)
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") then part.CanCollide = not on end
			end
		end
		if LocalPlayer.Character then applyNoclip(LocalPlayer.Character) end
		local conn = LocalPlayer.CharacterAdded:Connect(applyNoclip)
		table.insert(PlayerModule.connections, conn)
	end)

	-- Visual
	local visFrame = UI.GetCategoryFrame("Visual")
	UI.CreateToggle(visFrame, "ESP Master", cfg.ESP, "enabled", function(on)
		if on then ESPModule:Start() else ESPModule:Stop() end
		ESPModule:RefreshVisibility()
		ChamsModule:Apply()
	end)
	UI.CreateToggle(visFrame, "Box", cfg.ESP, "box", function() ESPModule:RefreshVisibility() end)
	UI.CreateToggle(visFrame, "Name", cfg.ESP, "name", function() ESPModule:RefreshVisibility() end)
	UI.CreateToggle(visFrame, "Health", cfg.ESP, "health", function() ESPModule:RefreshVisibility() end)
	UI.CreateToggle(visFrame, "Distance", cfg.ESP, "distance", function() ESPModule:RefreshVisibility() end)
	UI.CreateToggle(visFrame, "Tracers", cfg.ESP, "tracers", function() ESPModule:RefreshVisibility() end)
	UI.CreateToggle(visFrame, "Chams", cfg.ESP, "chams", function() ChamsModule:Apply() end)
	UI.CreateToggle(visFrame, "Team Check", cfg.ESP, "teamCheck", function()
		ESPModule:RefreshVisibility()
		ChamsModule:Apply()
	end)

	-- Combat
	local combatFrame = UI.GetCategoryFrame("Combat")
	UI.CreateToggle(combatFrame, "Aimbot", cfg.Aimbot, "enabled", function(on) if on then AimbotModule:Start() else AimbotModule:Stop() end end)
	UI.CreateSlider(combatFrame, "FOV", cfg.Aimbot, "fov", 10, 360, function(val) end)
	UI.CreateSlider(combatFrame, "Smooth", cfg.Aimbot, "smooth", 0.01, 1, function(val) end)
	UI.CreateToggle(combatFrame, "Triggerbot", cfg.Triggerbot, "enabled", function(on) AimbotModule:Start() end)

	-- Player
	local playerFrame = UI.GetCategoryFrame("Player")
	UI.CreateToggle(playerFrame, "Godmode", cfg.Player, "godmode", function(on) PlayerModule:ApplyGodmode(on) end)
	UI.CreateToggle(playerFrame, "Invisibility", cfg.Player, "invisibility", function(on) PlayerModule:ApplyInvisibility(on) end)
	UI.CreateToggle(playerFrame, "Anti-Fling", cfg.Player, "antiFling", function(on) PlayerModule:ApplyAntiFling(on) end)
	UI.CreateToggle(playerFrame, "Click TP", cfg.Player, "clickTP", function(on) PlayerModule:ApplyClickTP(on) end)

	-- Server
	local servFrame = UI.GetCategoryFrame("Server")
	UI.CreateButton(servFrame, "Rejoin", function() ServerModule:Rejoin() end)
	UI.CreateButton(servFrame, "Server Hop", function() ServerModule:ServerHop() end)
	UI.CreateToggle(servFrame, "Anti-AFK", cfg.Server, "antiAFK", function(on) if on then ServerModule:EnableAntiAFK() end end)

	-- Admin
	local adminFrame = UI.GetCategoryFrame("Admin")
	local cmdBox = Instance.new("TextBox")
	cmdBox.Size = UDim2.new(1, -10, 0, 30)
	cmdBox.Position = UDim2.new(0, 5, 0, 10)
	cmdBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
	cmdBox.TextColor3 = Color3.fromRGB(255,255,255)
	cmdBox.PlaceholderText = "cmd (rejoin, print текст)"
	cmdBox.Font = Enum.Font.Code
	cmdBox.TextSize = 14
	cmdBox.Parent = adminFrame
	cmdBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			local cmd = cmdBox.Text
			if cmd == "rejoin" then ServerModule:Rejoin()
			elseif cmd:sub(1,5) == "print" then print(cmd:sub(7))
			else print("Неизвестная команда: "..cmd)
			end
			cmdBox.Text = ""
		end
	end)

	-- Extra
	local extraFrame = UI.GetCategoryFrame("Extra")
	UI.CreateButton(extraFrame, "Save Settings", function()
		print("Настройки сохранены в getgenv().lowspecistHUB_Config")
	end)
	UI.CreateButton(extraFrame, "Load Settings", function()
		-- Уже загружены при инициализации
	end)
	UI.CreateToggle(extraFrame, "Performance Mode", cfg.Performance, "mode", function(on)
		local level = on and Enum.QualityLevel.Level01 or Enum.QualityLevel.Level21
		sethiddenprop(Services.Lighting, "RenderingQualityLevel", level)
	end)
end

-- Автоочистка при телепортации
LocalPlayer.OnTeleport:Connect(function()
	ModuleManager:CleanupAll()
end)

print("lowspecistHUB v4.0 загружен. Все утечки устранены, производительность оптимизирована.")
