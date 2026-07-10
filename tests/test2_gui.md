-- TEST 2: GUI oluşturma
local gui = Instance.new("ScreenGui")
gui.Name = "test"
gui.Parent = game:GetService("CoreGui")
local lbl = Instance.new("TextLabel")
lbl.Size = UDim2.new(0,200,0,50)
lbl.Position = UDim2.new(0.5,-100,0.5,-25)
lbl.BackgroundColor3 = Color3.fromRGB(0,100,200)
lbl.TextColor3 = Color3.fromRGB(255,255,255)
lbl.Text = "GUI OK"
lbl.Font = Enum.Font.SourceSansBold
lbl.TextSize = 20
lbl.Parent = gui
print("test2 OK")
