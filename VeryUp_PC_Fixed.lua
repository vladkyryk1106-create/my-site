-- VeryUp PC Fixed Edition
-- Працює на ПК | ESP виправлено | Додано кнопку закриття

local Player = game.Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ========== НАЛАШТУВАННЯ ==========
local settings = {
    esp = true, silentAim = true, magicBullet = true,
    fly = false, flySpeed = 40, keys = {w=false,s=false,a=false,d=false,up=false,down=false},
    bodyVel = nil, noRecoil = true, noSpread = true, jumpShoot = true
}

-- ========== 1. ESP (ВИПРАВЛЕНО ДЛЯ ПК) ==========
local espObjects = {}
RunService.RenderStepped:Connect(function()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            if not espObjects[plr] then
                local highlight = Instance.new("Highlight")
                highlight.FillColor = Color3.fromRGB(255, 0, 0)
                highlight.OutlineColor = Color3.new(0, 0, 0)
                highlight.FillTransparency = 0.5
                highlight.Parent = plr.Character
                espObjects[plr] = highlight
            end
            espObjects[plr].Enabled = settings.esp
        elseif espObjects[plr] then
            pcall(espObjects[plr].Destroy, espObjects[plr])
            espObjects[plr] = nil
        end
    end
end)

-- ========== 2. SILENT AIM ==========
local function getNearestInFOV()
    local nearest, minDist = nil, 200
    local mousePos = UserInputService:GetMouseLocation()
    local center = Camera.ViewportSize / 2
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local screenPos, onScreen = Camera:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
            if onScreen then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                if dist < minDist then
                    minDist = dist
                    nearest = plr.Character.HumanoidRootPart
                end
            end
        end
    end
    return nearest
end

if settings.silentAim then
    RunService.RenderStepped:Connect(function()
        local target = getNearestInFOV()
        if target then
            local lookAt = CFrame.new(Camera.CFrame.Position, target.Position)
            Camera.CFrame = Camera.CFrame:Lerp(lookAt, 0.85)
        end
    end)
end

-- ========== 3. MAGIC BULLET ==========
local oldRaycast = workspace.Raycast
local lastShot = 0
workspace.Raycast = function(_, origin, direction, ...)
    if not settings.magicBullet then
        return oldRaycast(workspace, origin, direction, ...)
    end
    local target = nil
    local minDist = 500
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local d = (plr.Character.HumanoidRootPart.Position - Camera.CFrame.Position).Magnitude
            if d < minDist then
                minDist = d
                target = plr
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

-- ========== 4. NO RECOIL / SPREAD / JUMP SHOOT ==========
if settings.noRecoil then
    task.spawn(function()
        while true do
            pcall(function()
                local recoil = ReplicatedStorage:FindFirstChild("Gun") and ReplicatedStorage.Gun:FindFirstChild("Scripts") and ReplicatedStorage.Gun.Scripts:FindFirstChild("RecoilHandler")
                if recoil then
                    local module = require(recoil)
                    module.nextStep = function() end
                    module.setRecoilMultiplier = function() end
                end
            end)
            task.wait(1)
        end
    end)
end

if settings.noSpread then
    task.spawn(function()
        while true do
            pcall(function()
                local utils = ReplicatedStorage:FindFirstChild("Utils")
                if utils then
                    local module = require(utils)
                    if module.applySpreadToDirection then
                        module.applySpreadToDirection = function(dir) return dir end
                    end
                end
            end)
            task.wait(1)
        end
    end)
end

if settings.jumpShoot then
    task.spawn(function()
        while true do
            pcall(function()
                for _, module in ipairs(ReplicatedStorage:GetDescendants()) do
                    if module:IsA("ModuleScript") and (module.Name:find("Client") or module.Name:find("Gun")) then
                        local req = require(module)
                        if req and req.canFire then
                            req.canFire = function() return true end
                        end
                    end
                end
            end)
            task.wait(2)
        end
    end)
end

-- ========== 5. FLY ==========
local function updateFly()
    if not settings.fly or not settings.bodyVel or not Player.Character then return end
    local hrp = Player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local vel = Vector3.new()
    local s = settings.flySpeed
    if settings.keys.w then vel = vel + hrp.CFrame.LookVector * s end
    if settings.keys.s then vel = vel - hrp.CFrame.LookVector * s end
    if settings.keys.d then vel = vel + hrp.CFrame.RightVector * s end
    if settings.keys.a then vel = vel - hrp.CFrame.RightVector * s end
    if settings.keys.up then vel = vel + Vector3.new(0, s, 0) end
    if settings.keys.down then vel = vel - Vector3.new(0, s, 0) end
    settings.bodyVel.Velocity = vel
end

UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    local k = i.KeyCode
    if k == Enum.KeyCode.F then
        if not settings.fly then
            local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                settings.fly = true
                settings.bodyVel = Instance.new("BodyVelocity")
                settings.bodyVel.MaxForce = Vector3.new(1e6, 1e6, 1e6)
                settings.bodyVel.Parent = hrp
                local hum = Player.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    hum.PlatformStand = true
                end
                CoreGui:SetCore("SendNotification", {Title="Fly", Text="ON", Duration=1})
            end
        else
            settings.fly = false
            if settings.bodyVel then settings.bodyVel:Destroy() end
            settings.bodyVel = nil
            local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
                hum.PlatformStand = false
            end
            CoreGui:SetCore("SendNotification", {Title="Fly", Text="OFF", Duration=1})
        end
    end
    if settings.fly then
        if k == Enum.KeyCode.W then settings.keys.w = true updateFly()
        elseif k == Enum.KeyCode.S then settings.keys.s = true updateFly()
        elseif k == Enum.KeyCode.A then settings.keys.a = true updateFly()
        elseif k == Enum.KeyCode.D then settings.keys.d = true updateFly()
        elseif k == Enum.KeyCode.Space then settings.keys.up = true updateFly()
        elseif k == Enum.KeyCode.LeftControl then settings.keys.down = true updateFly()
        end
    end
end)

UserInputService.InputEnded:Connect(function(i, gp)
    if gp then return end
    local k = i.KeyCode
    if settings.fly then
        if k == Enum.KeyCode.W then settings.keys.w = false updateFly()
        elseif k == Enum.KeyCode.S then settings.keys.s = false updateFly()
        elseif k == Enum.KeyCode.A then settings.keys.a = false updateFly()
        elseif k == Enum.KeyCode.D then settings.keys.d = false updateFly()
        elseif k == Enum.KeyCode.Space then settings.keys.up = false updateFly()
        elseif k == Enum.KeyCode.LeftControl then settings.keys.down = false updateFly()
        end
    end
end)

-- ========== 6. ГРАФІЧНЕ МЕНЮ (З КНОПКОЮ ЗАКРИТТЯ) ==========
local menuOpen = false
local mainGui = nil

UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.RightShift then
        if not menuOpen then
            mainGui = Instance.new("ScreenGui")
            mainGui.Name = "VeryUp_PC"
            mainGui.ResetOnSpawn = false
            mainGui.Parent = CoreGui

            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(0, 300, 0, 400)
            frame.Position = UDim2.new(0.5, -150, 0.5, -200)
            frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
            frame.BackgroundTransparency = 0.05
            frame.BorderSizePixel = 0
            frame.Parent = mainGui

            local title = Instance.new("TextLabel")
            title.Size = UDim2.new(1, 0, 0, 45)
            title.Text = "VERY UP - PC EDITION"
            title.TextColor3 = Color3.fromRGB(255, 70, 70)
            title.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
            title.Font = Enum.Font.GothamBold
            title.TextSize = 16
            title.Parent = frame

            -- КНОПКА ЗАКРИТТЯ (X) – ТЕ, ЧОГО ТИ ХОТІВ
            local closeBtn = Instance.new("TextButton")
            closeBtn.Size = UDim2.new(0, 40, 0, 35)
            closeBtn.Position = UDim2.new(1, -45, 0, 5)
            closeBtn.Text = "✕"
            closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            closeBtn.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
            closeBtn.Font = Enum.Font.GothamBold
            closeBtn.TextSize = 18
            closeBtn.Parent = frame
            closeBtn.MouseButton1Click:Connect(function()
                if mainGui then mainGui:Destroy() end
                menuOpen = false
            end)

            local espBtn = Instance.new("TextButton")
            espBtn.Size = UDim2.new(0.9, 0, 0, 40)
            espBtn.Position = UDim2.new(0.05, 0, 0, 60)
            espBtn.Text = "ESP: " .. (settings.esp and "ON" or "OFF")
            espBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
            espBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            espBtn.Font = Enum.Font.GothamBold
            espBtn.TextSize = 16
            espBtn.Parent = frame
            espBtn.MouseButton1Click:Connect(function()
                settings.esp = not settings.esp
                espBtn.Text = "ESP: " .. (settings.esp and "ON" or "OFF")
            end)

            local mbBtn = Instance.new("TextButton")
            mbBtn.Size = UDim2.new(0.9, 0, 0, 40)
            mbBtn.Position = UDim2.new(0.05, 0, 0, 110)
            mbBtn.Text = "MAGIC BULLET: " .. (settings.magicBullet and "ON" or "OFF")
            mbBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
            mbBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            mbBtn.Font = Enum.Font.GothamBold
            mbBtn.TextSize = 16
            mbBtn.Parent = frame
            mbBtn.MouseButton1Click:Connect(function()
                settings.magicBullet = not settings.magicBullet
                mbBtn.Text = "MAGIC BULLET: " .. (settings.magicBullet and "ON" or "OFF")
            end)

            local speedLbl = Instance.new("TextLabel")
            speedLbl.Size = UDim2.new(0.9, 0, 0, 25)
            speedLbl.Position = UDim2.new(0.05, 0, 0, 160)
            speedLbl.Text = "FLY SPEED: " .. settings.flySpeed
            speedLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
            speedLbl.BackgroundTransparency = 1
            speedLbl.Font = Enum.Font.Gotham
            speedLbl.TextSize = 12
            speedLbl.Parent = frame

            local speedBtn = Instance.new("TextButton")
            speedBtn.Size = UDim2.new(0.9, 0, 0, 30)
            speedBtn.Position = UDim2.new(0.05, 0, 0, 190)
            speedBtn.Text = "+ / -"
            speedBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
            speedBtn.TextColor3 = Color3.fromRGB(255, 200, 100)
            speedBtn.Font = Enum.Font.Gotham
            speedBtn.TextSize = 14
            speedBtn.Parent = frame
            speedBtn.MouseButton1Click:Connect(function()
                settings.flySpeed = (settings.flySpeed % 90) + 10
                speedLbl.Text = "FLY SPEED: " .. settings.flySpeed
            end)

            menuOpen = true
        else
            if mainGui then mainGui:Destroy() end
            menuOpen = false
        end
    end
end)

-- ========== 7. 3RD PERSON ==========
RunService.RenderStepped:Connect(function()
    Player.CameraMode = Enum.CameraMode.Classic
    if Player.CameraMaxZoomDistance < 10 then
        Player.CameraMaxZoomDistance = 50
    end
end)

-- ========== 8. АНТИ-КІК ==========
local oldKick = Player.Kick
Player.Kick = function(_, msg)
    warn("Anti-Kick: " .. tostring(msg))
    return nil
end

-- ========== 9. ПОВІДОМЛЕННЯ ==========
CoreGui:SetCore("SendNotification", {
    Title = "Very Up PC Edition",
    Text = "Fix loaded! Right Shift = Menu | F = Fly",
    Duration = 5
})

print("VeryUp PC Fix – Активовано!")
