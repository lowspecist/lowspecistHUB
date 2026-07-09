# Yapılmaması Gereken Hatalar ve Dersler

## 1. Forward Declaration Hataları

### Hata
```lua
-- Close button handler
closeBtn.MouseButton1Click:Connect(function()
    disableAllFeatures() -- NIL VALUE HATASI!
end)

-- ... 200 satır sonra ...
local function disableAllFeatures() ... end
```

### Çözüm
```lua
-- Üstte forward declaration
local disableAllFeatures

-- ... GUI kodu ...

-- Altta atama
disableAllFeatures = function() ... end
```

### Öğrenilen
Lua'da `local function foo()` yeni local oluşturur. `local foo` ile aynı değişken değildir. Forward declaration için `local foo` + `foo = function()` kullanımı gerekir.

---

## 2. Duplicate Variable Declaration

### Hata
```lua
local chamsHL = {} -- Satır 100'de
-- ... 200 satır sonra ...
local chamsHL = {} -- Satır 300'de — GÖLGELEME!
```

### Çözüm
```lua
-- Sadece bir kez tanımla
local chamsHL = {}
```

### Öğrenilen
Lua'da `local` her zaman en yakın scope'a tanımlar. Aynı isimde iki `local` birbirini gölgeler.

---

## 3. Godmode = math.huge

### Hata
```lua
hum.MaxHealth = math.huge
hum.Health = math.huge
-- Anti-cheat: "math.huge tespit edildi" → BAN
```

### Çözüm
```lua
-- 4 katmanlı koruma
hum.BreakJointsOnDeath = false
hum.RequiresNeck = false
hum.HealthChanged:Connect(function(hp)
    if hp < maxHP then hum.Health = maxHP end
end)
hum.StateChanged:Connect(function(_, state)
    if state == Enum.HumanoidStateType.Dead then
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
end)
```

### Öğrenilen
`math.huge` anti-cheat'ler tarafından doğrudan tespit edilir. Ölüm mekaniklerini devre dışı bırakmak daha güvenlidir.

---

## 4. RenderingStep'de task.wait()

### Hata
```lua
RunService:BindToRenderStep("aim", 2, function()
    task.wait(0.1) -- RENDER'I BLOKLAR!
    -- ... aimbot kodu ...
end)
```

### Çözüm
```lua
-- Asla RenderStep'de task.wait kullanma
-- Gecikme gerekiyorsa task.delay kullan
if cfg.Triggerbot.delay > 0 then
    task.delay(cfg.Triggerbot.delay/1000, function()
        pcall(function() mouse1press(); task.wait(0.05); mouse1release() end)
    end)
end
```

### Öğrenilen
`RenderStep` her frame çalışır. İçinde `task.wait()` tüm render'ı bloklar.

---

## 5. Drawing.new Korunmasız Kullanım

### Hata
```lua
local box = Drawing.new("Square") -- Crash yapabilir!
box.Visible = true
```

### Çözüm
```lua
local function safeDrawing(type)
    local ok, d = pcall(function() return Drawing.new(type) end)
    return ok and d or nil
end

local box = safeDrawing("Square")
if box then box.Visible = true end
```

### Öğrenilen
`Drawing.new()` bazı executor'larda desteklenmez. `pcall` ile korunmalı.

---

## 6. Config Import shallow Merge

### Hata
```lua
-- Import: nested table'ları bozar
for k, v in pairs(data) do
    cfg[k] = v -- ESP = { box = true } → tüm ESP ayarları silinir
end
```

### Çözüm
```lua
for k, v in pairs(data) do
    if type(v) == "table" and type(cfg[k]) == "table" then
        for sk, sv in pairs(v) do cfg[k][sk] = sv end
    else cfg[k] = v end
end
```

### Öğrenilen
Deep merge, nested table'ları korur. Shallow merge ise tamamen değiştirir.

---

## 7. ESP memory Leak

### Hata
```lua
RunService:BindToRenderStep("esp", 1, function()
    -- Her frame'de yeni Drawing oluştur, eskilerini temizleme
    local box = Drawing.new("Square") -- HER FRAME'DE YENİ!
    table.insert(espDrawings, box) -- Büyüyen liste!
end)
```

### Çözüm
```lua
RunService:BindToRenderStep("esp", 1, function()
    -- Önce eskileri temizle
    for _, d in ipairs(espDrawings) do pcall(function() d:Remove() end) end
    espDrawings = {}
    -- Sonra yenileri oluştur
end)
```

### Öğrenilen
ESP her frame'de Drawing oluşturup temizlemezsen bellek sızıntısı oluşur.

---

## 8. Godmode Respawn'da Kurulmuyor

### Hata
```lua
-- İlk kurulum iyi
if LocalPlayer.Character then setup(LocalPlayer.Character) end
-- Ama respawn'da yeniden kurulmuyor!
```

### Çözüm
```lua
local c = LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5) -- Karakter yüklenmesini bekle
    setup(char)
end)
```

### Öğrenilen
`CharacterAdded` her respawn'da tetiklenir. Tüm feature'lar burada yeniden kurulmalı.

---

## 9. Speed Force Respawn'da Başlamıyor

### Hata
```lua
-- Speed Force bir kez bağlanıyor
startSpeedForce()
-- Ama karakter ölünce Humanoid yeniden oluşturuluyor
-- Eski connection geçersiz kalıyor
```

### Çözüm
```lua
-- Heartbeat connection character'a bağlı değil, her zaman çalışır
-- Ama Humanoid referansı her frame'de yeniden alınıyor
speedForceConn = RunService.Heartbeat:Connect(function()
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if hum then hum.WalkSpeed = cfg.Movement.walkSpeed end
end)
```

### Öğrenilen
`Heartbeat` connection'ı character'dan bağımsızdır. Humanoid referansı her frame'de taze alınmalı.

---

## 10. Duplicate createDropdown

### Hata
```lua
local function createDropdown(...) -- Satır 284
    -- fonksiyon gövdesi
end

local function createDropdown(...) -- Satır 324 — TEKRAR!
    -- aynı fonksiyon gövdesi
end
```

### Çözüm
```lua
-- Sadece bir kez tanımla
local function createDropdown(...) ... end
```

### Öğrenilen
Düzenleme sırasında yanlışlıkla duplicate fonksiyon tanımlanabilir. Düzenleme sonrası kontrol gerekir.

---

## 11. Admin Komutları Config'i Senkronize Etmiyor

### Hata
```lua
elseif txt == "fly" then
    if flyEnabled then stopFly() else startFly() end
    -- cfg.Fly.enabled güncellenmiyor!
```

### Çözüm
```lua
elseif txt == "fly" then
    cfg.Fly.enabled = not cfg.Fly.enabled
    if cfg.Fly.enabled then startFly() else stopFly() end
```

### Öğrenilen
Admin komutları her zaman config'i de güncellemeli, aksi halde UI ile çelişir.

---

## 12. Silent Aim Hook Stacked

### Hata
```lua
-- Her frame'de yeni hook ekleniyor
RunService:BindToRenderStep("aim", 2, function()
    if cfg.Aimbot.silentAim and not silentAimHooked then
        oldNamecall = hookmetamethod(game, "__namecall", ...)
        -- silentAimHooked = true yapılmamış!
    end
end)
```

### Çözüm
```lua
if cfg.Aimbot.silentAim and not silentAimHooked then
    -- ... hook kodu ...
    silentAimHooked = true
    silentAimOldNamecall = oldNamecall
end

-- Stop'ta restore et
stopAimbot = function()
    if silentAimHooked and silentAimOldNamecall then
        hookmetamethod(game, "__namecall", silentAimOldNamecall)
    end
end
```

### Öğrenilen
`hookmetamethod` her frame'de çağrılırsa yığın oluşur. Flag ile kontrol edilmeli.

---

## Genel Kurallar

1. **Her düzenlemeden sonra kodu tara** — duplicate, forward declaration, nil reference
2. **pcall her zaman kullan** — Drawing, hookmetamethod, Character access
3. **Config'i her yerde güncelle** — Admin komutları, toggle'lar, reset
4. **Forward declaration** — GUI'den önce tanımlanan fonksiyonlar için
5. **memory leak kontrolü** — Drawing, connection, instance temizliği
6. **Spawn handler** — Her feature respawn'da yeniden kurulmalı
7. **Stealth** — Tanınabilir string, pcall, jitter, random name
8. **Panic key** — Anti-cheat algılarsa tek tuşla her şeyi kapat
