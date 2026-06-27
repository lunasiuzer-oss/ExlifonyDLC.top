-- Полная очистка предыдущих интерфейсов
local function cleanup(name)
    local cg = game:GetService("CoreGui"):FindFirstChild(name)
    if cg then cg:Destroy() end
    local pg = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild(name)
    if pg then pg:Destroy() end
end
cleanup("DeltaMegaMenu")

-- Сервисы
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Workspace = game:GetService("Workspace")

-- Таблица состояний
local Flags = {
    Aimbot = false, KillAura = false,
    BoxEsp = false, Tracers = false, ChinaHat = false, TargetEsp = false,
    Fly = false, Noclip = false, SpeedHack = false, InfJump = false,
    HudActive = false, FullBright = false
}

local Colors = {
    BoxEsp = Color3.fromRGB(255, 0, 100),
    Tracers = Color3.fromRGB(255, 255, 0),
    ChinaHat = Color3.fromRGB(0, 150, 255),
    TargetEsp = Color3.fromRGB(255, 80, 0)
}

-- Настройки функций
local Values = { 
    FlySpeed = 50, 
    WalkSpeed = 90,
    AimFOV = 120,
    AimSmooth = 4,
    AuraRange = 18,
    AuraDelay = 0.05
}

local MenuOpen = true
local ChinaHatPart = nil
local flyConnection, aimConnection, auraConnection, jumpConnection
local lastAuraTime = 0
local activeLabels = {} -- Для обновления списка активности

-- Круг FOV для Аимбота
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.Visible = false
FOVCircle.Color = Color3.fromRGB(0, 150, 255)
FOVCircle.Filled = false

-- Папка для визуала
if Workspace:FindFirstChild("DeltaVisuals") then Workspace.DeltaVisuals:Destroy() end
local VisualsFolder = Instance.new("Folder", Workspace)
VisualsFolder.Name = "DeltaVisuals"

-- Контейнер интерфейса
local TargetGui = LocalPlayer:WaitForChild("PlayerGui")
local ScreenGui = Instance.new("ScreenGui", TargetGui)
ScreenGui.Name = "DeltaMegaMenu"
ScreenGui.ResetOnSpawn = false

-- ГЛАВНЫЙ ФРЕЙМ (СТРОГО ПО ЦЕНТРУ ЭКРАНА)
local MainGridFrame = Instance.new("Frame", ScreenGui)
MainGridFrame.Size = UDim2.new(0, 720, 0, 360)
MainGridFrame.Position = UDim2.new(0.5, -360, 0.5, -180)
MainGridFrame.BackgroundTransparency = 1
MainGridFrame.Visible = MenuOpen

local GridListLayout = Instance.new("UIListLayout", MainGridFrame)
GridListLayout.FillDirection = Enum.FillDirection.Horizontal
GridListLayout.SortOrder = Enum.SortOrder.LayoutOrder
GridListLayout.Padding = UDim.new(0, 6)

-- [[ ВЕРХНИЙ ПРАВЫЙ ХАБ (FPS + ExlifonyDLC) ]] --
local InfoHudFrame = Instance.new("Frame", ScreenGui)
InfoHudFrame.Size = UDim2.new(0, 140, 0, 45)
InfoHudFrame.Position = UDim2.new(1, -150, 0, 10)
InfoHudFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 16)
InfoHudFrame.BackgroundTransparency = 0.2
BorderSizePixel = 0
Instance.new("UICorner", InfoHudFrame).CornerRadius = UDim.new(0, 5)

local InfoTitle = Instance.new("TextLabel", InfoHudFrame)
InfoTitle.Size = UDim2.new(1, -10, 0, 22)
InfoTitle.Position = UDim2.new(0, 10, 0, 2)
InfoTitle.BackgroundTransparency = 1
InfoTitle.Text = "ExlifonyDLC"
InfoTitle.TextColor3 = Color3.fromRGB(0, 150, 255)
InfoTitle.Font = Enum.Font.SourceSansBold; InfoTitle.TextSize = 15
InfoTitle.TextXAlignment = Enum.TextXAlignment.Left

local FpsLabel = Instance.new("TextLabel", InfoHudFrame)
FpsLabel.Size = UDim2.new(1, -10, 0, 18)
FpsLabel.Position = UDim2.new(0, 10, 0, 22)
FpsLabel.BackgroundTransparency = 1
FpsLabel.Text = "FPS: --"
FpsLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
FpsLabel.Font = Enum.Font.SourceSans; FpsLabel.TextSize = 12
FpsLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Счётчик FPS
local fpsCount = 0
local lastFpsTime = tick()
RunService.RenderStepped:Connect(function()
    fpsCount = fpsCount + 1
    if tick() - lastFpsTime >= 1 then
        FpsLabel.Text = "FPS: " .. tostring(fpsCount)
        fpsCount = 0
        lastFpsTime = tick()
    end
end)

-- [[ КНОПКА ОТКРЫТИЯ/ЗАКРЫТИЯ СВЕРХУ ПО ЦЕНТРУ ]] --
local TopToggle = Instance.new("TextButton", ScreenGui)
TopToggle.Size = UDim2.new(0, 120, 0, 25)
TopToggle.Position = UDim2.new(0.5, -60, 0, 5)
TopToggle.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
TopToggle.BackgroundTransparency = 0.4
TopToggle.Text = "CLICK TO TOGGLE"
TopToggle.TextColor3 = Color3.fromRGB(150, 150, 150)
TopToggle.Font = Enum.Font.SourceSansBold; TopToggle.TextSize = 10
Instance.new("UICorner", TopToggle).CornerRadius = UDim.new(0, 4)

TopToggle.MouseButton1Click:Connect(function()
    MenuOpen = not MenuOpen
    MainGridFrame.Visible = MenuOpen
end)

-- [[ КОНСТРУКТОР СТИЛЬНЫХ КОЛОНОК ]] --
local function createCategory(name)
    local column = Instance.new("Frame", MainGridFrame)
    column.Size = UDim2.new(0, 115, 1, 0)
    column.BackgroundColor3 = Color3.fromRGB(14, 14, 16)
    column.BackgroundTransparency = 0.15
    column.BorderSizePixel = 0
    Instance.new("UICorner", column).CornerRadius = UDim.new(0, 4)
    
    local header = Instance.new("TextLabel", column)
    header.Size = UDim2.new(1, 0, 0, 32)
    header.BackgroundTransparency = 1
    header.Text = name
    header.TextColor3 = Color3.fromRGB(240, 240, 240)
    header.Font = Enum.Font.SourceSans; header.TextSize = 13
    
    local line = Instance.new("Frame", column)
    line.Size = UDim2.new(0, 95, 0, 1)
    line.Position = UDim2.new(0.5, -47, 0, 32)
    line.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    line.BorderSizePixel = 0
    
    local list = Instance.new("ScrollingFrame", column)
    list.Size = UDim2.new(1, 0, 1, -35)
    list.Position = UDim2.new(0, 0, 0, 35)
    list.BackgroundTransparency = 1
    list.BorderSizePixel = 0
    list.ScrollBarThickness = 0
    
    local layout = Instance.new("UIListLayout", list)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    
    local function addModule(text, flagName, settings, callback)
        local btn = Instance.new("TextButton", list)
        btn.Size = UDim2.new(1, 0, 0, 26)
        btn.BackgroundTransparency = 1
        btn.Text = "  " .. text
        btn.TextColor3 = Color3.fromRGB(140, 140, 145)
        btn.Font = Enum.Font.SourceSans; btn.TextSize = 12
        btn.TextXAlignment = Enum.TextXAlignment.Left
        
        local arrow = Instance.new("TextLabel", btn)
        arrow.Size = UDim2.new(0, 15, 1, 0)
        arrow.Position = UDim2.new(1, -15, 0, 0)
        arrow.BackgroundTransparency = 1
        arrow.Text = ">"
        arrow.TextColor3 = Color3.fromRGB(80, 80, 85)
        arrow.Font = Enum.Font.SourceSans; arrow.TextSize = 10
        arrow.TextXAlignment = Enum.TextXAlignment.Center
        arrow.Visible = (settings ~= nil)

        local configFrame = Instance.new("Frame", list)
        configFrame.Size = UDim2.new(1, 0, 0, 0)
        configFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
        configFrame.BorderSizePixel = 0
        configFrame.ClipsDescendants = true
        configFrame.Visible = false
        
        if settings then
            local count = 0
            for valName, valConf in pairs(settings) do
                count = count + 1
                local subBtn = Instance.new("TextButton", configFrame)
                subBtn.Size = UDim2.new(1, 0, 0, 22)
                subBtn.Position = UDim2.new(0, 0, 0, (count-1)*22)
                subBtn.BackgroundTransparency = 1
                subBtn.Font = Enum.Font.SourceSans; subBtn.TextSize = 11
                subBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
                
                local bar = Instance.new("Frame", subBtn)
                bar.Size = UDim2.new(0, 90, 0, 4)
                bar.Position = UDim2.new(0.5, -45, 1, -5)
                bar.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
                bar.BorderSizePixel = 0
                Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
                
                local fill = Instance.new("Frame", bar)
                fill.Size = UDim2.new(0.5, 0, 1, 0)
                fill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
                fill.BorderSizePixel = 0
                Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
                
                local function updateLabel()
                    if valConf.Type == "Slider" then
                        subBtn.Text = valConf.Title .. ": " .. tostring(Values[valName])
                        local percent = (Values[valName] - valConf.Min) / (valConf.Max - valConf.Min)
                        fill.Size = UDim2.new(math.clamp(percent, 0, 1), 0, 1, 0)
                    elseif valConf.Type == "Color" then
                        subBtn.Text = valConf.Title
                        fill.Size = UDim2.new(1, 0, 1, 0)
                        fill.BackgroundColor3 = Colors[valName]
                    end
                end
                
                subBtn.MouseButton1Click:Connect(function()
                    if valConf.Type == "Slider" then
                        local cur = Values[valName] + valConf.Step
                        if cur > valConf.Max then cur = valConf.Min end
                        Values[valName] = cur
                    elseif valConf.Type == "Color" then
                        Colors[valName] = Color3.fromHSV(math.random(), 1, 1)
                    end
                    updateLabel()
                end)
                updateLabel()
            end
            configFrame.Size = UDim2.new(1, 0, 0, count * 22)
        end

        local function updateStyle()
            btn.TextColor3 = Flags[flagName] and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(140, 140, 145)
            arrow.TextColor3 = Flags[flagName] and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(80, 80, 85)
        end
        
        btn.MouseButton1Click:Connect(function()
            Flags[flagName] = not Flags[flagName]
            updateStyle()
            callback(Flags[flagName])
            _G.UpdateBindActivity() -- Обновляем вкладку активных функций
        end)
        
        btn.MouseButton2Click:Connect(function()
            configFrame.Visible = not configFrame.Visible
        end)
    end
    return addModule, list
end

-- Сетка окон (6 колонок в ряд)
local combatGroup   = createCategory("Combat")
local movementGroup = createCategory("Movement")
local playerGroup   = createCategory("Player")
local renderGroup   = createCategory("Render")
local miscGroup     = createCategory("Misc")
local _, activityList = createCategory("Activity") -- Та самая вкладка "bind activity"

-- [[ ДИНАМИЧЕСКИЙ СПИСОК АКТИВНЫХ ФУНКЦИЙ ]] --
_G.UpdateBindActivity = function()
    -- Очищаем старые записи
    for _, child in pairs(activityList:GetChildren()) do
        if child:IsA("TextLabel") then child:Destroy() end
    end
    -- Записываем активные
    for name, enabled in pairs(Flags) do
        if enabled and name ~= "HudActive" then
            local actLabel = Instance.new("TextLabel", activityList)
            actLabel.Size = UDim2.new(1, 0, 0, 24)
            actLabel.BackgroundTransparency = 1
            actLabel.Text = "  " .. name
            actLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            actLabel.Font = Enum.Font.SourceSansSemibold; actLabel.TextSize = 12
            actLabel.TextXAlignment = Enum.TextXAlignment.Left
        end
    end
end

-- [[ ПОИСК ЦЕЛИ ]] --
local function getClosestPlayerToCenter()
    local closest, shortestDist = nil, Values.AimFOV
    local centerScreen = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            local pos, onScreen = Camera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
            if onScreen then
                local dist = (Vector2.new(pos.X, pos.Y) - centerScreen).Magnitude
                if dist < shortestDist then shortestDist = dist; closest = p.Character end
            end
        end
    end
    return closest
end

-- [[ НАПОЛНЕНИЕ ФУНКЦИОНАЛА ]] --
combatGroup("Aimbot", "Aimbot", {
    AimFOV = {Title = "FOV", Type = "Slider", Min = 50, Max = 300, Step = 50},
    AimSmooth = {Title = "Smooth", Type = "Slider", Min = 1, Max = 9, Step = 2}
}, function(state)
    FOVCircle.Visible = state
    if state then
        aimConnection = RunService.RenderStepped:Connect(function()
            FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            FOVCircle.Radius = Values.AimFOV
            local targetChar = getClosestPlayerToCenter()
            if targetChar and targetChar:FindFirstChild("HumanoidRootPart") and (UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) or UserInputService:IsMouseButtonPressed(Enum.UserInputType.Touch)) then
                local targetLook = CFrame.new(Camera.CFrame.Position, targetChar.HumanoidRootPart.Position)
                Camera.CFrame = Camera.CFrame:Lerp(targetLook, 1 / Values.AimSmooth)
            end
        end)
    else if aimConnection then aimConnection:Disconnect() end end
end)

combatGroup("KillAura", "KillAura", {
    AuraRange = {Title = "Range", Type = "Slider", Min = 10, Max = 30, Step = 4},
    AuraDelay = {Title = "Delay", Type = "Slider", Min = 0.05, Max = 0.45, Step = 0.05}
}, function(state)
    if state then
        auraConnection = RunService.Heartbeat:Connect(function()
            if tick() - lastAuraTime < Values.AuraDelay then return end
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local tool = char and (char:FindFirstChildOfClass("Tool") or LocalPlayer.Backpack:FindFirstChildOfClass("Tool"))
            if hrp and tool then
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                        if (hrp.Position - p.Character.HumanoidRootPart.Position).Magnitude <= Values.AuraRange then
                            if tool.Parent == LocalPlayer.Backpack then tool.Parent = char end
                            tool:Activate(); lastAuraTime = tick(); break
                        end
                    end
                end
            end
        end)
    else if auraConnection then auraConnection:Disconnect() end end
end)

movementGroup("Fly", "Fly", {FlySpeed = {Title = "Speed", Type = "Slider", Min = 25, Max = 125, Step = 25}}, function(state)
    if state then
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")
        local hum = char:WaitForChild("Humanoid")
        local bv = Instance.new("BodyVelocity", hrp)
        bv.MaxForce = Vector3.new(1, 1, 1) * math.huge
        flyConnection = RunService.RenderStepped:Connect(function()
            if not Flags.Fly or not hrp.Parent then bv:Destroy(); flyConnection:Disconnect(); return end
            hum.PlatformStand = true
            local md = hum.MoveDirection
            bv.Velocity = md.Magnitude > 0 and Camera.CFrame:VectorToWorldSpace(Camera.CFrame:ToObjectSpace(hrp.CFrame * CFrame.new(md)).Position).Unit * Values.FlySpeed or Vector3.new(0,0,0)
        end)
    else
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.PlatformStand = false end
    end
end)

movementGroup("Noclip", "Noclip", nil, function() end)
movementGroup("SpeedHack", "SpeedHack", {WalkSpeed = {Title = "Speed", Type = "Slider", Min = 50, Max = 150, Step = 25}}, function(state)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = state and Values.WalkSpeed or 16
    end
end)

playerGroup("Infinite Jump", "InfJump", nil, function(state)
    if state then
        jumpConnection = UserInputService.JumpRequest:Connect(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
            end
        end)
    else if jumpConnection then jumpConnection:Disconnect() end end
end)

renderGroup("Box ESP", "BoxEsp", {BoxEsp = {Title = "Color picker", Type = "Color"}}, function() end)
renderGroup("Tracers", "Tracers", {Tracers = {Title = "Color picker", Type = "Color"}}, function() end)
renderGroup("Target ESP", "TargetEsp", {TargetEsp = {Title = "Color", Type = "Color"}}, function() end)

renderGroup("China Hat", "ChinaHat", {ChinaHat = {Title = "Color picker", Type = "Color"}}, function(state)
    if state and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") then
        ChinaHatPart = Instance.new("ConeHandleAdornment", ScreenGui)
        ChinaHatPart.Height, ChinaHatPart.Radius = 0.5, 1.1
        ChinaHatPart.Adornee = LocalPlayer.Character.Head
        ChinaHatPart.CFrame = CFrame.new(0, 0.6, 0) * CFrame.Angles(math.rad(-90), 0, 0)
    else if ChinaHatPart then ChinaHatPart:Destroy(); ChinaHatPart = nil end end
end)

miscGroup("FullBright", "FullBright", nil, function(state)
    game:GetService("Lighting").Ambient = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(127, 127, 127)
end)

-- [[ КЛЮЧ RE-RENDER ДЛЯ СЛЕЖЕНИЯ ВИЗУАЛА ]] --
local TargetRing3D = Instance.new("CylinderHandleAdornment", ScreenGui)
TargetRing3D.Radius = 3.2; TargetRing3D.Height = 0.15; TargetRing3D.AlwaysOnTop = true; TargetRing3D.Transparency = 0.3

UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.RightShift then
        MenuOpen = not MenuOpen; MainGridFrame.Visible = MenuOpen
    end
end)

RunService.RenderStepped:Connect(function()
    if ChinaHatPart and Flags.ChinaHat then ChinaHatPart.Color3 = Colors.ChinaHat end
    local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            local pFolder = VisualsFolder:FindFirstChild(player.Name) or Instance.new("Folder", VisualsFolder)
            pFolder.Name = player.Name
            local head, hrp = char:FindFirstChild("Head"), char:FindFirstChild("HumanoidRootPart")
            if head and hrp then
                local box = pFolder:FindFirstChild("EspBox")
                if Flags.BoxEsp then
                    if not box then box = Instance.new("SelectionBox", pFolder); box.Name = "EspBox"; box.LineThickness = 0.05 end
                    box.Color3 = Colors.BoxEsp; box.Adornee = char
                else if box then box:Destroy() end end
                
                local tracer = pFolder:FindFirstChild("TracerLine")
                if Flags.Tracers and myHrp then
                    if not tracer then tracer = Instance.new("BoxHandleAdornment", pFolder); tracer.Name = "TracerLine"; tracer.AlwaysOnTop = true; tracer.Transparency = 0.2 end
                    tracer.Color3 = Colors.Tracers; tracer.Adornee = myHrp
                    local d = (myHrp.Position - head.Position).Magnitude
                    tracer.Size = Vector3.new(0.04, 0.04, d)
                    tracer.CFrame = CFrame.new(Vector3.new(), myHrp.CFrame:PointToObjectSpace(head.Position)) * CFrame.new(0, 0, -d/2)
                else if tracer then tracer:Destroy() end end
            end
        end
    end
end)

RunService.Stepped:Connect(function()
    if Flags.Noclip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end
    end
end)
