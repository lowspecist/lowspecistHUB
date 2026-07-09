# Roblox Exploit Script Bilgi Bankası

## Roblox Mimari Temelleri

### Script Türleri
- **Script (Server Script):** Sadece Server'da çalışır. Oyunun gerçek mantığını yönetir.
- **LocalScript:** Sadece Client'ta çalışır. Oyuncunun deneyimini yönetir.
- **ModuleScript:** Kod kütüphanesi. çağıran tarafa göre çalışır.

### Client-Server İlişkisi
- Server ve Client aynı belleği paylaşmaz
- İletişim sadece RemoteEvent/RemoteFunction ile yapılır
- Client güvenilmez kabul edilir
- Server oyunun tek otoritesidir

### Executor Çalışma Mantığı
- Executor, Roblox Client ile aynı süreçte çalışır
- Sadece Client tarafındaki verilere erişebilir
- Server belleğine erişemez
- Client'ın yapabildiği her şeyi yapabilir
- Yeni bir iletişim kanalı oluşturmaz, mevcut olanları kullanır

## Anti-Cheat Tespit Yöntemleri

### Tespit Edilebilir (Yüksek Risk)
- `MaxHealth = math.huge` → Godmode flag
- `hookmetamethod` → Namecall hook tespiti
- `Drawing.new()` → Drawing API tespiti (bazı anti-cheat'ler)
- Sabit string isimler → Script fingerprinting
- Anormal WalkSpeed/JumpPower → Speed hack flag
- BodyVelocity/BodyGyro → Fly flag
- CanCollide=false sürekli → NoClip flag

### Tespit Edilmesi Zor (Düşük Risk)
- Camera CFrame değişikliği → Aimbot (server umursamaz)
- Drawing API ile ESP → Sadece görsel
- Lighting değişikliği → Fullbright
- Humanoid.CameraDistanceOffset → Third Person
- Camera.FieldOfView → FOV Changer
- VirtualUser → Anti-AFK

## Stealth Teknikleri

### String Gizleme
```lua
-- Kötü: Tanınabilir isimler
gui.Name = "ExploitHub"
-- İyi: Rastgele isimler
gui.Name = string.char(97+math.random(25))..tostring(math.random(100000,999999))
```

### Error Bastırma
```lua
-- Kötü: Hata mesajları log'da görünür
local result = someFunc()
-- İyi: pcall ile sessizce yönet
local ok, result = pcall(someFunc)
```

### Drawing Koruma
```lua
-- Kötü: Drawing.new crash yapabilir
local d = Drawing.new("Square")
-- İyi: safeDrawing ile koruma
local function safeDrawing(type)
    local ok, d = pcall(function() return Drawing.new(type) end)
    return ok and d or nil
end
```

### Jitter (Gözdağı)
```lua
-- ESP pozisyonlarına rastgele offset ekle
local function jitter() return (math.random()-0.5)*0.4 end
box.Position = Vector2.new(pos.X + jitter(), pos.Y + jitter())
```

### Forward Declaration
```lua
-- Kötü: nil value hatası
closeBtn.MouseButton1Click:Connect(function()
    disableAllFeatures() -- Henüz tanımlanmamış!
end)
-- İyi: İleriye dönük tanımlama
local disableAllFeatures
-- ... (GUI kodu) ...
disableAllFeatures = function() ... end
```

## Godmode Yaklaşımları

### Yanlış Yaklaşım (Tespit Edilir)
```lua
hum.MaxHealth = math.huge
hum.Health = math.huge
-- Anti-cheat: math.huge arar
```

### Doğru Yaklaşım (4 Katmanlı)
1. `BreakJointsOnDeath = false` → Eklem kırılmasını engelle
2. `RequiresNeck = false` → Boyun kırılma kontrolünü kapat
3. `HealthChanged` → Sağlık düşerse anında restore
4. `StateChanged` → Dead state → GettingUp değiştir

## Speed Force Sistemi

### Neden Gerekli?
Oyunlar WalkSpeed/JumpPower'ı zaman zaman sıfırlayabilir. Speed Force her frame'de değeri zorla uygular.

```lua
RunService.Heartbeat:Connect(function()
    local hum = char:FindFirstChild("Humanoid")
    if hum.WalkSpeed ~= cfg.Movement.walkSpeed then
        hum.WalkSpeed = cfg.Movement.walkSpeed
    end
end)
```

## ESP Optimizasyonu

### Frame Throttle
Her frame'de çizim yapmak yerine 2-3 frame'de bir güncelle:
```lua
espFrameCount = espFrameCount + 1
if cfg.ESP.throttle and espFrameCount % 2 ~= 0 then return end
```

### Auto-Refresh
Oyuncu katılınca/bırakınca Chams güncellenmeli:
```lua
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(1)
        if cfg.ESP.chams then applyChams() end
    end)
end)
```

## Aimbot İyileştirmeleri

### Prediction (Öngörü)
Hedefin hızına göre pozisyonu tahmin et:
```lua
local targetPos = head.Position
if cfg.Aimbot.prediction then
    local hrp = ch:FindFirstChild("HumanoidRootPart")
    if hrp then targetPos = targetPos + hrp.Velocity * 0.1 end
end
```

### Team Check
Takım arkadaşını nişan alma:
```lua
if cfg.Aimbot.teamCheck and p.Team == myTeam then continue end
```

## Config Yönetimi

### Auto-Merge
Eski config ile yeni config'i birleştir:
```lua
for k, v in pairs(defaultConfig) do
    if cfg[k] == nil then cfg[k] = v end
    if type(v) == "table" then
        for sk, sv in pairs(v) do
            if cfg[k][sk] == nil then cfg[k][sk] = sv end
        end
    end
end
```

### Deep Merge (Import)
Import ederken nested table'ları koru:
```lua
for k, v in pairs(data) do
    if type(v) == "table" and type(cfg[k]) == "table" then
        for sk, sv in pairs(v) do cfg[k][sk] = sv end
    else cfg[k] = v end
end
```

## Panic Key
Tek tuşla tüm özellikleri kapat — anti-cheat algılarsa:
```lua
if input.KeyCode == Enum.KeyCode.P then
    disableAllFeatures()
    notify("PANIC: Tüm özellikler kapatıldı", 1.5)
end
```

## Notification Sistemi
Toast bildirimleri ile kullanıcıya bilgi ver:
```lua
local function notify(text, duration)
    -- TweenService ile animasyonlu bildirim
end
```
