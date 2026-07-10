-- Minimal Test Script
-- Bu script executor'ın çalışıp çalışmadığını test eder

-- Test 1: Basic services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
print("Test 1: Services OK")

-- Test 2: LocalPlayer
local LocalPlayer = Players.LocalPlayer
print("Test 2: LocalPlayer = " .. LocalPlayer.Name)

-- Test 3: GUI creation
local gui = Instance.new("ScreenGui")
gui.Name = "TestGUI"
gui.Parent = game:GetService("CoreGui")
print("Test 3: GUI created")

local label = Instance.new("TextLabel")
label.Size = UDim2.new(0, 200, 0, 50)
label.Position = UDim2.new(0.5, -100, 0.5, -25)
label.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.Text = "Script Calisiyor!"
label.Font = Enum.Font.SourceSansBold
label.TextSize = 20
label.Parent = gui
print("Test 4: Label created")

-- Test 4: Drawing API
local function testDrawing()
	local ok, d = pcall(function() return Drawing.new("Square") end)
	if ok and d then
		d:Remove()
		return true
	end
	return false
end
print("Test 5: Drawing API = " .. tostring(testDrawing()))

-- Test 5: getgenv
local function testGetgenv()
	local ok, res = pcall(function() return getgenv() end)
	return ok and type(res) == "table"
end
print("Test 6: getgenv = " .. tostring(testGetgenv()))

-- Test 6: hookmetamethod
local function testHook()
	local ok, res = pcall(function() return hookmetamethod end)
	return ok and type(res) == "function"
end
print("Test 7: hookmetamethod = " .. tostring(testHook()))

-- Test 7: Heartbeat
local count = 0
local conn
conn = RunService.Heartbeat:Connect(function()
	count = count + 1
	if count >= 5 then
		conn:Disconnect()
		print("Test 8: Heartbeat OK (5 frames)")
		print("=== TUM TESTLER BASARILI ===")
		-- 5 saniye sonra temizle
		task.wait(5)
		gui:Destroy()
	end
end)

print("Test baslatildi...")
