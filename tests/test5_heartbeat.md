-- TEST 5: Heartbeat + Drawing
local RunService = game:GetService("RunService")
local count = 0
local conn
conn = RunService.Heartbeat:Connect(function()
	count = count + 1
	if count >= 3 then
		conn:Disconnect()
		print("test5: Heartbeat OK")
	end
end)
