-- TEST 3: Drawing API
local ok, d = pcall(function() return Drawing.new("Square") end)
if ok and d then
	d:Remove()
	print("test3: Drawing OK")
else
	print("test3: Drawing FAILED")
end
