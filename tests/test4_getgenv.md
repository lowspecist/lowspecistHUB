-- TEST 4: getgenv
local ok, res = pcall(function() return getgenv() end)
if ok and type(res) == "table" then
	print("test4: getgenv OK")
else
	print("test4: getgenv FAILED")
end
