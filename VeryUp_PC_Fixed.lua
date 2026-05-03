-- Simple ESP + Magic Bullet + Fly (by Vlad)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Settings
local espEnabled = true
local magicBullet = true
local flyEnabled = false
local flySpeed = 50
local bodyVel = nil
local flyKeys = {w=false,s=false,a=false,d=false,up=false,down=false}

-- ESP (Highlights through walls)
local espHighlights = {}
RunService.RenderStepped:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if not espHighlights[player] then
                local highlight = Instance.new("Highlight")
                highlight.FillColor = Color3.fromRGB(255, 0, 0)
                highlight.OutlineColor = Color3.fromRGB(0, 0, 0)
                highlight.FillTransparency = 0.5
                highlight.Parent = player.Character
                espHighlights[player] = highlight
            end
            espHighlights[player].Enabled = espEnabled
        elseif espHighlights[player] then
            espHighlights[player]:Destroy()
            espHighlights[player] = nil
        end
    end
end)

-- Magic Bullet
local oldRaycast = workspace.Raycast
local lastShot = 0
workspace.Raycast = function(_, origin, direction, ...)
    if not magicBullet then
        return oldRaycast(workspace, origin, direction, ...)
    end
    local target = nil
    local minDist = 500
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local d = (player.Character.HumanoidRootPart.Position - Camera.CFrame.Position).Magnitude
            if d < minDist then
                minDist = d
                target = player
            end
        end
    end
    if target and tick() - lastShot > 0.15 then
        lastShot = tick()
        local targetPos = target.Character.HumanoidRootPart.Position
        local newDir = (targetPos - origin).Unit * direction.Magnitude
        return oldRaycast(workspace, origin, newDir, ...)
    end
    return oldRaycast(workspace, origin, direction, ...)
end

-- Fly
local function updateFly()
    if not flyEnabled or not bodyVel or not LocalPlayer.Character then return end
    local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local vel = Vector3.new()
    local speed = flySpeed
    if flyKeys.w then vel = vel + root.CFrame.LookVector * speed end
    if flyKeys.s then vel = vel - root.CFrame.LookVector * speed end
    if flyKeys.d then vel = vel + root.CFrame.RightVector * speed end
    if flyKeys.a then vel = vel - root.CFrame.RightVector * speed end
    if flyKeys.up then vel = vel + Vector3.new(0, speed, 0) end
    if flyKeys.down then vel = vel - Vector3.new(0, speed, 0) end
    bodyVel.Velocity = vel
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    local key = input.KeyCode
    if key == Enum.KeyCode.F then
        if not flyEnabled then
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then
                flyEnabled = true
                bodyVel = Instance.new("BodyVelocity")
                bodyVel.MaxForce = Vector3.new(1e6, 1e6, 1e6)
                bodyVel.Parent = root
                local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    humanoid.PlatformStand = true
                end
                CoreGui:SetCore("SendNotification", {Title="Fly", Text="ON", Duration=1})
            end
        else
            flyEnabled = false
            if bodyVel then bodyVel:Destroy() end
            bodyVel = nil
            local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
                humanoid.PlatformStand = false
            end
            CoreGui:SetCore("SendNotification", {Title="Fly", Text="OFF", Duration=1})
        end
    end
    if flyEnabled then
        if key == Enum.KeyCode.W then flyKeys.w = true updateFly()
        elseif key == Enum.KeyCode.S then flyKeys.s = true updateFly()
        elseif key == Enum.KeyCode.A then flyKeys.a = true updateFly()
        elseif key == Enum.KeyCode.D then flyKeys.d = true updateFly()
        elseif key == Enum.KeyCode.Space then flyKeys.up = true updateFly()
        elseif key == Enum.KeyCode.LeftControl then flyKeys.down = true updateFly()
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    local key = input.KeyCode
    if flyEnabled then
        if key == Enum.KeyCode.W then flyKeys.w = false updateFly()
        elseif key == Enum.KeyCode.S then flyKeys.s = false updateFly()
        elseif key == Enum.KeyCode.A then flyKeys.a = false updateFly()
        elseif key == Enum.KeyCode.D then flyKeys.d = false updateFly()
        elseif key == Enum.KeyCode.Space then flyKeys.up = false updateFly()
        elseif key == Enum.KeyCode.LeftControl then flyKeys.down = false updateFly()
        end
    end
end)

-- Simple GUI
local gui = nil
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        if not gui then
            gui = Instance.new("ScreenGui")
            gui.Name = "SimpleCheat"
            gui.Parent = CoreGui
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(0, 250, 0, 200)
            frame.Position = UDim2.new(0.5, -125, 0.5, -100)
            frame.BackgroundColor3 = Color3.fromRGB(30,30,40)
            frame.BackgroundTransparency = 0.1
            frame.BorderSizePixel = 0
            frame.Parent = gui
            local title = Instance.new("TextLabel")
            title.Size = UDim2.new(1,0,0,40)
            title.Text = "SIMPLE CHEAT"
            title.TextColor3 = Color3.fromRGB(255,100,100)
            title.BackgroundColor3 = Color3.fromRGB(40,40,55)
            title.Font = Enum.Font.GothamBold
            title.TextSize = 18
            title.Parent = frame
            local espButton = Instance.new("TextButton")
            espButton.Size = UDim2.new(0.9,0,0,40)
            espButton.Position = UDim2.new(0.05,0,0,50)
            espButton.Text = "ESP: ON"
            espButton.BackgroundColor3 = Color3.fromRGB(60,60,80)
            espButton.TextColor3 = Color3.fromRGB(255,255,255)
            espButton.Font = Enum.Font.GothamBold
            espButton.TextSize = 16
            espButton.Parent = frame
            espButton.MouseButton1Click:Connect(function()
                espEnabled = not espEnabled
                espButton.Text = "ESP: " .. (espEnabled and "ON" or "OFF")
            end)
            local mbButton = Instance.new("TextButton")
            mbButton.Size = UDim2.new(0.9,0,0,40)
            mbButton.Position = UDim2.new(0.05,0,0,100)
            mbButton.Text = "MAGIC: ON"
            mbButton.BackgroundColor3 = Color3.fromRGB(60,60,80)
            mbButton.TextColor3 = Color3.fromRGB(255,255,255)
            mbButton.Font = Enum.Font.GothamBold
            mbButton.TextSize = 16
            mbButton.Parent = frame
            mbButton.MouseButton1Click:Connect(function()
                magicBullet = not magicBullet
                mbButton.Text = "MAGIC: " .. (magicBullet and "ON" or "OFF")
            end)
            local close = Instance.new("TextButton")
            close.Size = UDim2.new(0.4,0,0,30)
            close.Position = UDim2.new(0.3,0,1,-40)
            close.Text = "CLOSE"
            close.BackgroundColor3 = Color3.fromRGB(80,30,30)
            close.TextColor3 = Color3.fromRGB(255,255,255)
            close.Font = Enum.Font.GothamBold
            close.TextSize = 14
            close.Parent = frame
            close.MouseButton1Click:Connect(function()
                gui:Destroy()
                gui = nil
            end)
        else
            gui:Destroy()
            gui = nil
        end
    end
end)

-- Fixed 3rd Person
RunService.RenderStepped:Connect(function()
    LocalPlayer.CameraMode = Enum.CameraMode.Classic
    if LocalPlayer.CameraMaxZoomDistance < 10 then
        LocalPlayer.CameraMaxZoomDistance = 50
    end
end)

-- Anti-Kick
local oldKick = LocalPlayer.Kick
LocalPlayer.Kick = function(_, msg) warn("Kick blocked") return nil end

CoreGui:SetCore("SendNotification", {Title="Simple Cheat", Text="Loaded! Right Shift = Menu | F = Fly", Duration=5})
print("Simple Cheat Activated")
