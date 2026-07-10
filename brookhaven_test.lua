-- Brookhaven Gamepass Test Script
-- Kendi Studio kopyaninda test et

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local LocalPlayer = Players.LocalPlayer

-- Brookhaven bilinen gamepass ID'leri (test icin)
local BROOKHAVEN_PASSES = {
	160260459,  -- VIP
	248618016,  -- Emergency
	2319882615, -- F1 Car
	151506188,  -- Military
}

print("=== BROOKHAVEN GAMEPASS TEST ===")
print("Oyuncu: " .. LocalPlayer.Name)
print("UserID: " .. LocalPlayer.UserId)

-- Test 1: Mevcut gamepass'leri kontrol et
print("\n--- Test 1: Mevcut Gamepass'ler ---")
for _, passId in ipairs(BROOKHAVEN_PASSES) do
	local ok, owns = pcall(function() return MarketplaceService:UserOwnsGamePassAsync(LocalPlayer.UserId, passId) end)
	print("Gamepass " .. passId .. ": " .. tostring(owns))
end

-- Test 2: __namecall hook ile spoof
print("\n--- Test 2: Gamepass Spoof ---")
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
local readonly = setreadonly or make_writeable

pcall(function()
	readonly(mt, false)
	mt.__namecall = newcclosure(function(self, ...)
		local args = {...}
		local method = table.remove(args)
		if self == MarketplaceService and method == "UserOwnsGamePassAsync" then
			print("[SPOOF] UserOwnsGamePassAsync called - returning true")
			return true
		end
		return oldNamecall(self, unpack(args))
	end)
	readonly(mt, true)
	print("Hook basarili!")
end)

-- Test 3: Spoof sonrasi kontrol
print("\n--- Test 3: Spoof Sonrasi ---")
for _, passId in ipairs(BROOKHAVEN_PASSES) do
	local ok, owns = pcall(function() return MarketplaceService:UserOwnsGamePassAsync(LocalPlayer.UserId, passId) end)
	print("Gamepass " .. passId .. ": " .. tostring(owns))
end

-- Test 4: Workspace VIP kontrol
print("\n--- Test 4: VIP Kapilari ---")
local doorCount = 0
for _, v in pairs(workspace:GetDescendants()) do
	if v:IsA("BasePart") then
		local n = v.Name:lower()
		if n:find("vip") or n:find("gamepass") or n:find("premium") or n:find("locked") then
			doorCount = doorCount + 1
			print("Kapi bulundu: " .. v.Name .. " (Parent: " .. v.Parent.Name .. ")")
		end
	end
end
print("Toplam kapi: " .. doorCount)

print("\n=== TEST TAMAMLANDI ===")
print("Sonuclari konsoldan kontrol et (F9)")
