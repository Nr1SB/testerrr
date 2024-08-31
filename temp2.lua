-- All-in-One Aimbot and ESP Script with Pastebin Key System

-- Load Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = game:GetService("Workspace").CurrentCamera
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- Aimbot Settings
local aimbotEnabled = false
local aimbotFOV = 50
local aimbotSmoothness = 0.2
local aimbotPrediction = 0.165
local visibilityCheck = true

-- ESP Settings
local ESPEnabled = false
local maxESPDistance = 1000
local ESPSettings = {
    BoxEnabled = true,
    BoxColor = Color3.fromRGB(255, 255, 255),
    BoxThickness = 1,
    BoxTransparency = 0.7,
    
    NameEnabled = true,
    NameColor = Color3.fromRGB(255, 255, 255),
    NameSize = 14,
    NameFont = Drawing.Fonts.UI,
    NameOutline = true,
    NameOutlineColor = Color3.new(0, 0, 0),
    
    DistanceEnabled = true,
    DistanceColor = Color3.fromRGB(255, 255, 255),
    DistanceSize = 12,
    DistanceFont = Drawing.Fonts.UI,
    DistanceOutline = true,
    DistanceOutlineColor = Color3.new(0, 0, 0),
    
    HealthBarEnabled = true,
    HealthBarColor = Color3.fromRGB(0, 255, 0),
    HealthBarThickness = 1,
    
    HeadDotEnabled = true,
    HeadDotColor = Color3.fromRGB(255, 0, 0),
    HeadDotRadius = 1,
    
    TracerEnabled = true,
    TracerColor = Color3.fromRGB(255, 255, 255),
    TracerThickness = 1,
    TracerTransparency = 0.7,
    TracerFrom = "Bottom" -- "Bottom", "Top", or "Mouse"
}

-- FOV Circle Setup
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Thickness = 1
FOVCircle.NumSides = 60
FOVCircle.Radius = aimbotFOV
FOVCircle.Filled = false
FOVCircle.Transparency = 0.7
FOVCircle.Visible = false

local function updateFOVCircle()
    FOVCircle.Position = UIS:GetMouseLocation()
    FOVCircle.Radius = aimbotFOV
    FOVCircle.Visible = aimbotEnabled
end

local function predictPosition(player)
    local character = player.Character
    if not character then return nil end
    
    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then return nil end
    
    local velocity = rootPart.Velocity
    local position = rootPart.Position
    
    return position + (velocity * aimbotPrediction)
end

local function isVisible(target)
    local character = LocalPlayer.Character
    if not character then return false end
    
    local origin = character.Head.Position
    local direction = (target.Position - origin).Unit
    local ray = Ray.new(origin, direction * 1000)
    
    local hit, _ = workspace:FindPartOnRayWithIgnoreList(ray, {character})
    return hit and hit:IsDescendantOf(target.Parent)
end

local function getClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = aimbotFOV

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local predictedPos = predictPosition(player)
            if not predictedPos then continue end
            
            local headPos, onScreen = Camera:WorldToViewportPoint(predictedPos)
            if not onScreen then continue end
            
            local mousePos = UIS:GetMouseLocation()
            local distance = (Vector2.new(headPos.X, headPos.Y) - mousePos).Magnitude
            
            if distance < shortestDistance then
                if visibilityCheck and not isVisible(player.Character.Head) then continue end
                closestPlayer = player
                shortestDistance = distance
            end
        end
    end

    return closestPlayer
end

local function createESPObject(player)
    local esp = {}
    esp.Player = player
    esp.Box = Drawing.new("Square")
    esp.Name = Drawing.new("Text")
    esp.Distance = Drawing.new("Text")
    esp.HealthBar = Drawing.new("Line")
    esp.HealthBarBackground = Drawing.new("Line")
    esp.HeadDot = Drawing.new("Circle")
    esp.Tracer = Drawing.new("Line")

    esp.Box.Thickness = ESPSettings.BoxThickness
    esp.Box.Color = ESPSettings.BoxColor
    esp.Box.Filled = false
    esp.Box.Transparency = ESPSettings.BoxTransparency

    esp.Name.Color = ESPSettings.NameColor
    esp.Name.Size = ESPSettings.NameSize
    esp.Name.Center = true
    esp.Name.Outline = ESPSettings.NameOutline
    esp.Name.OutlineColor = ESPSettings.NameOutlineColor
    esp.Name.Font = ESPSettings.NameFont

    esp.Distance.Color = ESPSettings.DistanceColor
    esp.Distance.Size = ESPSettings.DistanceSize
    esp.Distance.Center = true
    esp.Distance.Outline = ESPSettings.DistanceOutline
    esp.Distance.OutlineColor = ESPSettings.DistanceOutlineColor
    esp.Distance.Font = ESPSettings.DistanceFont

    esp.HealthBar.Thickness = ESPSettings.HealthBarThickness
    esp.HealthBar.Color = ESPSettings.HealthBarColor
    esp.HealthBarBackground.Thickness = ESPSettings.HealthBarThickness
    esp.HealthBarBackground.Color = Color3.new(0.1, 0.1, 0.1)
    esp.HealthBarBackground.Transparency = 0.5

    esp.HeadDot.Radius = ESPSettings.HeadDotRadius
    esp.HeadDot.Color = ESPSettings.HeadDotColor
    esp.HeadDot.Filled = true

    esp.Tracer.Thickness = ESPSettings.TracerThickness
    esp.Tracer.Color = ESPSettings.TracerColor
    esp.Tracer.Transparency = ESPSettings.TracerTransparency

    return esp
end

local espObjects = {}

local function updateESP()
    for _, esp in pairs(espObjects) do
        if esp.Player.Character and esp.Player.Character:FindFirstChild("HumanoidRootPart") and esp.Player.Character:FindFirstChild("Humanoid") then
            local rootPart = esp.Player.Character.HumanoidRootPart
            local humanoid = esp.Player.Character.Humanoid
            local head = esp.Player.Character:FindFirstChild("Head")

            local rootPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
            local distance = (LocalPlayer.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude

            if onScreen and distance <= maxESPDistance then
                local headPos = Camera:WorldToViewportPoint(head.Position)
                local legPos = Camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3, 0))

                -- Box ESP
                if ESPSettings.BoxEnabled then
                    esp.Box.Size = Vector2.new(2000 / rootPos.Z, headPos.Y - legPos.Y)
                    esp.Box.Position = Vector2.new(rootPos.X - esp.Box.Size.X / 2, rootPos.Y - esp.Box.Size.Y / 2)
                    esp.Box.Visible = ESPEnabled
                else
                    esp.Box.Visible = false
                end

                -- Name ESP
                if ESPSettings.NameEnabled then
                    esp.Name.Text = esp.Player.Name
                    esp.Name.Position = Vector2.new(rootPos.X, (rootPos.Y - esp.Box.Size.Y / 2) - 20)
                    esp.Name.Visible = ESPEnabled
                else
                    esp.Name.Visible = false
                end

                -- Distance ESP
                if ESPSettings.DistanceEnabled then
                    esp.Distance.Text = math.floor(distance) .. " studs"
                    esp.Distance.Position = Vector2.new(rootPos.X, (rootPos.Y + esp.Box.Size.Y / 2) + 5)
                    esp.Distance.Visible = ESPEnabled
                else
                    esp.Distance.Visible = false
                end

                -- Health Bar ESP
                if ESPSettings.HealthBarEnabled then
                    local healthPercent = humanoid.Health / humanoid.MaxHealth
                    esp.HealthBarBackground.From = Vector2.new((rootPos.X - esp.Box.Size.X / 2) - 5, rootPos.Y + esp.Box.Size.Y / 2)
                    esp.HealthBarBackground.To = Vector2.new(esp.HealthBarBackground.From.X, rootPos.Y - esp.Box.Size.Y / 2)
                    esp.HealthBar.From = esp.HealthBarBackground.From
                    esp.HealthBar.To = Vector2.new(esp.HealthBarBackground.From.X, esp.HealthBar.From.Y - (esp.Box.Size.Y * healthPercent))
                    esp.HealthBar.Color = Color3.fromHSV(healthPercent / 3, 1, 1)
                    esp.HealthBar.Visible = ESPEnabled
                    esp.HealthBarBackground.Visible = ESPEnabled
                else
                    esp.HealthBar.Visible = false
                    esp.HealthBarBackground.Visible = false
                end

                -- Head Dot ESP
                if ESPSettings.HeadDotEnabled then
                    esp.HeadDot.Position = Vector2.new(headPos.X, headPos.Y)
                    esp.HeadDot.Visible = ESPEnabled
                else
                    esp.HeadDot.Visible = false
                end

                -- Tracer ESP
                if ESPSettings.TracerEnabled then
                    esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    if ESPSettings.TracerFrom == "Top" then
                        esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, 0)
                    elseif ESPSettings.TracerFrom == "Mouse" then
                        esp.Tracer.From = UIS:GetMouseLocation()
                    end
                    esp.Tracer.To = Vector2.new(rootPos.X, rootPos.Y)
                    esp.Tracer.Visible = ESPEnabled
                else
                    esp.Tracer.Visible = false
                end

            else
                esp.Box.Visible = false
                esp.Name.Visible = false
                esp.Distance.Visible = false
                esp.HealthBar.Visible = false
                esp.HealthBarBackground.Visible = false
                esp.HeadDot.Visible = false
                esp.Tracer.Visible = false
            end
        else
            esp.Box.Visible = false
            esp.Name.Visible = false
            esp.Distance.Visible = false
            esp.HealthBar.Visible = false
            esp.HealthBarBackground.Visible = false
            esp.HeadDot.Visible = false
            esp.Tracer.Visible = false
        end
    end
end

-- Fetch key from Pastebin
local pastebinKeyURL = "https://pastebin.com/raw/SAdD4BU6"
local function fetchKeyFromPastebin()
    local success, key = pcall(function()
        return game:HttpGet(pastebinKeyURL)
    end)
    if success then
        return key
    else
        return nil
    end
end
local validKey = fetchKeyFromPastebin()

-- UI Setup
local Window = Rayfield:CreateWindow({
    Name = "AdrianoWare.cc",
    LoadingTitle = "Loading AdrianoWare.cc",
    LoadingSubtitle = "Script Made By YTAdriano",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = nil,
        FileName = "AdrianoWareConfig"
    },
    KeySystem = true,
    KeySettings = {
        Title = "AdrianoWare Key System",
        Subtitle = "Please enter the key to proceed",
        Note = "Contact the developer to get the key",
        FileName = "AdrianoWareKey",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = {validKey} -- Use the fetched key here
    }
})

-- Tabs
local AimbotTab = Window:CreateTab("Aimbot")
local ESPTab = Window:CreateTab("ESP")

-- Aimbot Controls
AimbotTab:CreateToggle({
    Name = "Enable Aimbot",
    CurrentValue = false,
    Flag = "AimbotToggle",
    Callback = function(value)
        aimbotEnabled = value
        updateFOVCircle()
    end,
})

AimbotTab:CreateSlider({
    Name = "Aimbot FOV",
    Range = {10, 500},
    Increment = 1,
    Suffix = "px",
    CurrentValue = aimbotFOV,
    Flag = "AimbotFOV",
    Callback = function(value)
        aimbotFOV = value
        updateFOVCircle()
    end,
})

AimbotTab:CreateSlider({
    Name = "Aimbot Smoothness",
    Range = {0.01, 1},
    Increment = 0.01,
    Suffix = "x",
    CurrentValue = aimbotSmoothness,
    Flag = "AimbotSmoothness",
    Callback = function(value)
        aimbotSmoothness = value
    end,
})

AimbotTab:CreateSlider({
    Name = "Prediction Time",
    Range = {0, 1},
    Increment = 0.001,
    Suffix = "s",
    CurrentValue = aimbotPrediction,
    Flag = "AimbotPrediction",
    Callback = function(value)
        aimbotPrediction = value
    end,
})

AimbotTab:CreateToggle({
    Name = "Visibility Check",
    CurrentValue = visibilityCheck,
    Flag = "VisibilityCheckToggle",
    Callback = function(value)
        visibilityCheck = value
    end,
})

-- ESP Controls
ESPTab:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = false,
    Flag = "ESPToggle",
    Callback = function(value)
        ESPEnabled = value
        if value then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    espObjects[player] = createESPObject(player)
                end
            end
        else
            for _, esp in pairs(espObjects) do
                esp.Box:Remove()
                esp.Name:Remove()
                esp.Distance:Remove()
                esp.HealthBar:Remove()
                esp.HealthBarBackground:Remove()
                esp.HeadDot:Remove()
                esp.Tracer:Remove()
            end
            espObjects = {}
        end
    end,
})

ESPTab:CreateToggle({
    Name = "Box ESP",
    CurrentValue = ESPSettings.BoxEnabled,
    Flag = "BoxESPToggle",
    Callback = function(value)
        ESPSettings.BoxEnabled = value
    end,
})

ESPTab:CreateToggle({
    Name = "Name ESP",
    CurrentValue = ESPSettings.NameEnabled,
    Flag = "NameESPToggle",
    Callback = function(value)
        ESPSettings.NameEnabled = value
    end,
})

ESPTab:CreateToggle({
    Name = "Distance ESP",
    CurrentValue = ESPSettings.DistanceEnabled,
    Flag = "DistanceESPToggle",
    Callback = function(value)
        ESPSettings.DistanceEnabled = value
    end,
})

ESPTab:CreateToggle({
    Name = "Health Bar",
    CurrentValue = ESPSettings.HealthBarEnabled,
    Flag = "HealthBarToggle",
    Callback = function(value)
        ESPSettings.HealthBarEnabled = value
    end,
})

ESPTab:CreateToggle({
    Name = "Head Dot",
    CurrentValue = ESPSettings.HeadDotEnabled,
    Flag = "HeadDotToggle",
    Callback = function(value)
        ESPSettings.HeadDotEnabled = value
    end,
})

ESPTab:CreateToggle({
    Name = "Tracers",
    CurrentValue = ESPSettings.TracerEnabled,
    Flag = "TracerToggle",
    Callback = function(value)
        ESPSettings.TracerEnabled = value
    end,
})

ESPTab:CreateDropdown({
    Name = "Tracer Origin",
    Options = {"Bottom", "Top", "Mouse"},
    CurrentOption = ESPSettings.TracerFrom,
    Flag = "TracerFromDropdown",
    Callback = function(option)
        ESPSettings.TracerFrom = option
    end,
})

ESPTab:CreateSlider({
    Name = "Max ESP Distance",
    Range = {100, 5000},
    Increment = 100,
    Suffix = " studs",
    CurrentValue = maxESPDistance,
    Flag = "MaxESPDistance",
    Callback = function(value)
        maxESPDistance = value
    end,
})

ESPTab:CreateColorPicker({
    Name = "Box Color",
    Color = ESPSettings.BoxColor,
    Flag = "BoxColorPicker",
    Callback = function(color)
        ESPSettings.BoxColor = color
    end,
})

ESPTab:CreateColorPicker({
    Name = "Name Color",
    Color = ESPSettings.NameColor,
    Flag = "NameColorPicker",
    Callback = function(color)
        ESPSettings.NameColor = color
    end,
})

ESPTab:CreateColorPicker({
    Name = "Health Bar Color",
    Color = ESPSettings.HealthBarColor,
    Flag = "HealthBarColorPicker",
    Callback = function(color)
        ESPSettings.HealthBarColor = color
    end,
})

ESPTab:CreateColorPicker({
    Name = "Head Dot Color",
    Color = ESPSettings.HeadDotColor,
    Flag = "HeadDotColorPicker",
    Callback = function(color)
        ESPSettings.HeadDotColor = color
    end,
})

ESPTab:CreateColorPicker({
    Name = "Tracer Color",
    Color = ESPSettings.TracerColor,
    Flag = "TracerColorPicker",
    Callback = function(color)
        ESPSettings.TracerColor = color
    end,
})

ESPTab:CreateSlider({
    Name = "ESP Transparency",
    Range = {0, 1},
    Increment = 0.1,
    Suffix = "",
    CurrentValue = 1 - ESPSettings.BoxTransparency,
    Flag = "ESPTransparencySlider",
    Callback = function(value)
        ESPSettings.BoxTransparency = 1 - value
    end,
})

-- Update ESP
RunService.RenderStepped:Connect(updateESP)
UIS.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 and aimbotEnabled then
        local target = getClosestPlayer()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            local predictedPos = predictPosition(target)
            local mouseMove = (Camera:WorldToViewportPoint(predictedPos) - Camera:WorldToViewportPoint(LocalPlayer.Character.Head.Position)) * aimbotSmoothness
            mousemoverel(mouseMove.X, mouseMove.Y)
        end
    end
end)

-- Cleanup on script exit
local function onExit()
    for _, esp in pairs(espObjects) do
        esp.Box:Remove()
        esp.Name:Remove()
        esp.Distance:Remove()
        esp.HealthBar:Remove()
        esp.HealthBarBackground:Remove()
        esp.HeadDot:Remove()
        esp.Tracer:Remove()
    end
    FOVCircle:Remove()
end

game:BindToClose(onExit)
