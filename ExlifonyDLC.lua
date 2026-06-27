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
    Aimbot = false, KillAura = false, Fling = false,
    BoxEsp = false, Skeleton = false, Tracers = false, ChinaHat = false, TargetEsp = false,
    Fly = false, Noclip = false, SpeedHack = false, InfJump = false,
    HudActive = false, FullBright = false
}

local Colors = {
    BoxEsp = Color3.fromRGB(255, 0, 100),
    Skeleton = Color3.fromRGB(0, 255, 150),
    Tracers = Color3.fromRGB(255, 255, 0),
    ChinaHat = Color3.fromRGB(0, 150, 255),
    TargetEsp = Color3.fromRGB(255, 80, 0)
}

-- Настройки функций
local Values = { 
    FlySpeed = 50, 
    WalkSpeed = 90,
    AimFOV = 120,
    AimSmooth = 4, -- Чем меньше, тем резче наводка (1 — моментально)
    AuraRange = 18,
    AuraDelay = 0.05
}

local MenuOpen = true
local ChinaHatPart = nil
local flyConnection, flingConnection, aimConnection, auraConnection, jumpConnection
local flingBav, flingBp
local lastAuraTime = 0

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

-- [[ ОКОШКО TARGET INFO / PLAYER INFO ]] --
local TargetInfoFrame = Instance.new("Frame", ScreenGui)
TargetInfoFrame.Size = UDim2.new(0, 160, 0, 45)
TargetInfoFrame.Position = UDim2.new(0.5, -80, 0.8, 0)
TargetInfoFrame.BackgroundColor3 = Color3.fromRGB(20, 15, 15)
TargetInfoFrame.BackgroundTransparency = 0.2
TargetInfoFrame.BorderSizePixel = 0
TargetInfoFrame.Visible = false
Instance.new("UICorner", TargetInfoFrame).CornerRadius = UDim.new(0, 6)

local TargetAvatar = Instance.new("ImageLabel", TargetInfoFrame)
TargetAvatar.Size = UDim2.new(0, 35, 0, 35)
TargetAvatar.Position = UDim2.new(0, 5, 0.5, -17)
TargetAvatar.BackgroundColor3 = Color3.fromRGB(30, 25, 25)
TargetAvatar.BorderSizePixel = 0
Instance.new("UICorner", TargetAvatar).CornerRadius = UDim.new(0, 4)

local TargetName = Instance.new("TextLabel", TargetInfoFrame)
TargetName.Size = UDim2.new(0, 110, 0, 16)
TargetName.Position = UDim2.new(0, 45, 0, 4)
TargetName.BackgroundTransparency = 1
TargetName.Text = "Player"
TargetName.TextColor3 = Color3.fromRGB(240, 240, 240)
TargetName.Font = Enum.Font.SourceSansBold; TargetName.TextSize = 13
TargetName.TextXAlignment = Enum.TextXAlignment.Left

local HealthBarBg = Instance.new("Frame", TargetInfoFrame)
HealthBarBg.Size = UDim2.new(0, 110, 0, 6)
HealthBarBg.Position = UDim2.new(0, 45, 0, 22)
HealthBarBg.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
HealthBarBg.BorderSizePixel = 0
Instance.new("UICorner", HealthBarBg).CornerRadius = UDim.new(1, 0)

local HealthBarFill = Instance.new("Frame", HealthBarBg)
HealthBarFill.Size = UDim2.new(1, 0, 1, 0)
HealthBarFill.BackgroundColor3 = Color3.fromRGB(255, 80, 50)
HealthBarFill.BorderSizePixel = 0
Instance.new("UICorner", HealthBarFill).CornerRadius = UDim.new(1, 0)

local HealthText = Instance.new("TextLabel", TargetInfoFrame)
HealthText.Size = UDim2.new(0, 40, 0, 10)
HealthText.Position = UDim2.new(0, 45, 0, 30)
HealthText.BackgroundTransparency = 1
HealthText.Text = "20.0"
HealthText.TextColor3 = Color3.fromRGB(200, 200, 200)
HealthText.Font = Enum.Font.SourceSans; HealthText.TextSize = 10
HealthText.TextXAlignment = Enum.TextXAlignment.Left

-- [[ УЛУЧШЕННЫЙ ПОИСК ДЛЯ АИМБОТА И КИЛЛАУРЫ ]] --
local function getClosestPlayerToCenter()
    local closest, shortestDist = nil, Values.AimFOV
    local centerScreen = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            local pos, onScreen = Camera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
            if onScreen then
                local dist = (Vector2.new(pos.X, pos.Y) - centerScreen).Magnitude
                if dist < shortestDist then
                    shortestDist = dist
                    closest = p.Character
                end
            end
        end
    end
    return closest
end

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
                        fill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
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
        end)
        
        btn.MouseButton2Click:Connect(function()
            configFrame.Visible = not configFrame.Visible
        end)
    end
    return addModule
end

-- Сетка окон (6 колонок в ряд)
local combatGroup   = createCategory("Combat")
local movementGroup = createCategory("Movement")
local playerGroup   = createCategory("Player")
local renderGroup   = createCategory("Render")
local miscGroup     = createCategory("Misc")
local themeGroup    = createCategory("Theme")

-- [[ ОБНОВЛЕННЫЕ ФУНКЦИИ COMBAT (AIM И КИЛЛАУРА) ]] --

-- AIMBOT: Жестко и плавно держит камеру на цели при зажатом ПКМ
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
            -- Условие: цель найдена и игрок зажал правую кнопку мыши (или зажал палец на экране)
            if targetChar and targetChar:FindFirstChild("HumanoidRootPart") and (UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) or UserInputService:IsMouseButtonPressed(Enum.UserInputType.Touch)) then
                local targetHrp = targetChar.HumanoidRootPart
                -- Плавный расчет направления взгляда камеры прямо на HRP противника
                local targetLook = CFrame.new(Camera.CFrame.Position, targetHrp.Position)
                Camera.CFrame = Camera.CFrame:Lerp(targetLook, 1 / Values.AimSmooth)
            end
        end)
    else if aimConnection then aimConnection:Disconnect() end end
end)

-- KILL AURA: Автоматически берет оружие и бьет врагов вокруг
combatGroup("KillAura", "KillAura", {
    AuraRange = {Title = "Range", Type = "Slider", Min = 10, Max = 30, Step = 4},
    AuraDelay = {Title = "Delay", Type = "Slider", Min = 0.05, Max = 0.45, Step = 0.05}
}, function(state)
    if state then
        auraConnection = RunService.Heartbeat:Connect(function()
            if tick() - lastAuraTime < Values.AuraDelay then return end
            
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            
            -- Поиск валидного оружия в инвентаре или в руках
            local tool = char:FindFirstChildOfClass("Tool") or LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
            if not tool then return end
            
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                    local targetHrp = p.Character.HumanoidRootPart
                    local distance = (hrp.Position - targetHrp.Position).Magnitude
                    
                    if distance <= Values.AuraRange then
                        -- Автоматически экипируем оружие, если оно было в рюкзаке
                        if tool.Parent == LocalPlayer.Backpack then
                            tool.Parent = char
                        end
                        -- Наносим удар активацией инструмента
                        tool:Activate()
                        lastAuraTime = tick()
                        break
                    end
                end
            end
        end)
    else if auraConnection then auraConnection:Disconnect() end end
end)

-- [[ ОСТАЛЬНЫЕ ФУНКЦИИ ]] --
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

themeGroup("UI Blur", "HudActive", nil, function() end)

-- [[ ПОДГОТОВКА СЛЕЖЕНИЯ 3D КРУГА НАД ЦЕЛЬЮ ]] --
local TargetRing3D = Instance.new("CylinderHandleAdornment", ScreenGui)
TargetRing3D.Radius = 3.2
TargetRing3D.Height = 0.15
TargetRing3D.AlwaysOnTop = true
TargetRing3D.Transparency = 0.3
TargetRing3D.ZIndex = 10

-- Закрытие/открытие на клавиатуре (Right Shift)
UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.RightShift then
        MenuOpen = not MenuOpen; MainGridFrame.Visible = MenuOpen
    end
end)

-- [[ ОСНОВНОЙ СИНХРОННЫЙ ЦИКЛ ОБНОВЛЕНИЯ ]] --
RunService.RenderStepped:Connect(function()
    if ChinaHatPart and Flags.ChinaHat then ChinaHatPart.Color3 = Colors.ChinaHat end
    
    local closestChar, shortestDistance = nil, math.huge
    local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            local pFolder = VisualsFolder:FindFirstChild(player.Name) or Instance.new("Folder", VisualsFolder)
            pFolder.Name = player.Name
            
            local head, hrp = char:FindFirstChild("Head"), char:FindFirstChild("HumanoidRootPart")
            if head and hrp then
                -- ESP
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
                
                -- Расчет для Target ESP
                if myHrp and Flags.TargetEsp and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                    local distance = (myHrp.Position - hrp.Position).Magnitude
                    if distance < shortestDistance then shortestDistance = distance; closestChar = char end
                end
            end
        end
    end
    
    -- Отрисовка Target ESP и Player Info
    if Flags.TargetEsp and closestChar and closestChar:FindFirstChild("HumanoidRootPart") and closestChar:FindFirstChild("Humanoid") then
        local targetHrp = closestChar.HumanoidRootPart
        local targetHum = closestChar.Humanoid
        local targetPlayer = Players:GetPlayerFromCharacter(closestChar)
        
        -- Позиция кольца (Анимация синуса по вертикали)
        TargetRing3D.Adornee = targetHrp
        TargetRing3D.Color3 = Colors.TargetEsp
        local bounceOffset = math.sin(tick() * 5) * 1.3
        TargetRing3D.CFrame = CFrame.new(0, bounceOffset, 0) * CFrame.Angles(math.rad(90), 0, 0)
        
        -- Выгрузка в Target Info
        TargetName.Text = targetPlayer and targetPlayer.Name or closestChar.Name
        HealthText.Text = string.format("%.1f", targetHum.Health)
        local healthPercent = math.clamp(targetHum.Health / targetHum.MaxHealth, 0, 1)
        HealthBarFill.Size = UDim2.new(healthPercent, 0, 1, 0)
        
        if targetPlayer then
            TargetAvatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. targetPlayer.UserId .. "&width=420&height=420&format=png"
        end
        TargetInfoFrame.Visible = true
    else
        TargetRing3D.Adornee = nil
        TargetInfoFrame.Visible = false
    end
end)

-- Физика Noclip
RunService.Stepped:Connect(function()
    if Flags.Noclip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do 
            if part:IsA("BasePart") then part.CanCollide = false end 
        end
    end
end) добавь новых функций, почини skeletonExli
