if not LPH_OBFUSCATED then
    function LPH_NO_VIRTUALIZE(f)
        return f
    end
    function LPH_JIT(...)
        return ...
    end
    function LPH_JIT_MAX(...)
        return ...
    end
    function LPH_NO_UPVALUES(f)
        return function(...)
            return f(...)
        end
    end
    function LPH_ENCSTR(...)
        return ...
    end
    function LPH_ENCNUM(...)
        return ...
    end
    function LPH_CRASH()
        return print(debug.traceback())
    end
end

repeat task.wait() until game:IsLoaded()

-- =============================================================================
-- SERVICES & CONTROLLERS
-- =============================================================================
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local GunController = require(ReplicatedStorage.Modules.Client.Controllers.GunController)
local BulletController = require(ReplicatedStorage.Modules.Client.Controllers.BulletController)
local CameraController = require(ReplicatedStorage.Modules.Client.Controllers.CameraController)
local IntegrityController = require(ReplicatedStorage.Modules.Client.Controllers.IntegrityController)
local SessionTelemetry = ReplicatedStorage.Remotes.Combat:FindFirstChild("SessionTelemetry")

--W AC Bypass
if SessionTelemetry then SessionTelemetry:Destroy() end
IntegrityController.Start = function() end

local hf = hookfunction
local nc = newcclosure or function(f) return f end
local cf = clonefunction or function(f) return f end

-- =============================================================================
-- INITIALIZATION & CONFIGURATION
-- =============================================================================
local NativeDrawing = Drawing
local Drawing = loadstring(game:HttpGet("https://raw.githubusercontent.com/linemaster2/storage/main/Drawing.lua"))()
local Compkiller = loadstring(game:HttpGet("https://raw.githubusercontent.com/ZwPEZ/Scripts/refs/heads/main/Other/UI.lua"))()
local TrixAPI = loadstring(game:HttpGet("https://raw.githubusercontent.com/ZwPEZ/Scripts/refs/heads/main/Other/API.lua"))()
local ConfigManager = Compkiller:ConfigManager({Directory = "Hitscan/Configs", Config = "TTKTesting"})
local Notifier = Compkiller.newNotify()

Compkiller.Colors.Highlight = Color3.fromHex("5e84ff")
Compkiller.Colors.Toggle = Color3.fromHex("5e84ff")
Compkiller.Colors.BlockColor = Color3.fromHex("090909")
Compkiller.Colors.BGDBColor = Color3.fromHex("050505")
Compkiller.Colors.BlockBackground = Color3.fromHex("050505")
Compkiller.Colors.DropColor = Color3.fromHex("050505")
Compkiller.Colors.MouseEnter = Color3.fromHex("202020")
Compkiller.Colors.StrokeColor = Color3.fromHex("202020")
Compkiller.Colors.HighStrokeColor = Color3.fromHex("202020")
Compkiller.Colors.LineColor = Color3.fromHex("202020")

Compkiller:Loader("rbxassetid://92470148307978" , 1.3).yield();

local cfg = { 
    silentAim = false,
    dynamicFov = true,
    wallCheck = false,
    autoShoot = false,
    drawFov = false,
    fovRadius = 150,
    fovColor = Color3.fromRGB(255, 255, 255),
    drawSnapline = false,
    snaplineColor = Color3.fromRGB(255, 255, 255),
    alwaysAuto = false,
    rapidFire = false,
    rapidFireMultiplier = 2.0,
    instantReload = false,
    noSpread = false,
    spreadControl = 0,
    noRecoil = false,
    recoilControl = 0,
    infiniteAmmo = false,
    chams = false,
    chamFillColor = Color3.fromHex("5e84ff"), 
    chamFillTransparency = 0.82, 
    chamOutlineColor = Color3.fromHex("5e84ff"), 
    chamOutlineTransparency = 0.0,
    handChams = false,
    handColor = Color3.fromHex("5e84ff"),
    handMaterial = Enum.Material.ForceField,
    aimPart = "Head",
    boxEsp = false,
    boxName = false,
    boxNameColor = Color3.fromRGB(255, 255, 255),
    boxNameOutline = true,
    boxNameOutlineColor = Color3.fromRGB(0, 0, 0),
    boxColor = Color3.fromRGB(255, 255, 255),
    boxOutline = true,
    boxOutlineColor = Color3.fromRGB(0, 0, 0),
    boxFilled = false,
    boxFilledColor = Color3.fromRGB(0, 0, 0),
    boxFilledColor = Color3.fromRGB(0, 0, 0),
    boxFilledTransparency = 0.5,
    healthBar = false,
    healthBarColor = Color3.fromRGB(0, 255, 0),
    healthBarOutline = true,
    healthBarOutlineColor = Color3.fromRGB(0, 0, 0),
    healthBarPosition = "left",
    bulletTracers = false,
    tracerColor = Color3.fromHex("5e84ff"),
    tracerDuration = 1.5,
    targetDot = false,
    targetDotColor = Color3.fromRGB(255, 255, 255),
    targetDotRadius = 3,
    targetDotOutline = true,
    targetDotOutlineColor = Color3.fromRGB(0, 0, 0),
    enableWalkSpeed = false,
    momentumWalkSpeed = 16,
    enableFly = false,
    flySpeed = 50,
    enableNoclip = false,
    weaponChams = false,
    weaponColor = Color3.fromHex("5e84ff"),
    weaponMaterial = Enum.Material.ForceField,
    attachmentChams = false,
    attachmentColor = Color3.fromHex("5e84ff"),
    attachmentMaterial = Enum.Material.ForceField,
    localModelChams = false,
    localModelColor = Color3.fromHex("5e84ff"),
    localModelMaterial = Enum.Material.ForceField,
    antiFlash = false,
    noScreenShake = false,
    noSway = false,
    fovOverride = false,
    fovAmount = 90,
    thirdPerson = false,
    thirdPersonX = 0,
    thirdPersonY = 0,
    thirdPersonZ = 10,
    hitboxExpander = false,
}

local weaponBackups = {}
local activeHighlights = {}
local activeBoxes = {} 
local activeTracers = {}
local originalHandChams = {}
local originalAttachmentChams = {}
local originalWeaponChams = {}
local originalLocalModelChams = {}
local originalHitboxes = {}
local lastAutoShot = 0

local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1
fovCircle.Color = cfg.fovColor
fovCircle.Filled = false
fovCircle.Transparency = 1
fovCircle.Visible = false

local snapLine = NativeDrawing.new("Line")
snapLine.Thickness = 1
snapLine.Color = cfg.snaplineColor
snapLine.Transparency = 1
snapLine.Visible = false

local realTimeTargetDot = Drawing.new("Circle")
realTimeTargetDot.Thickness = 1
realTimeTargetDot.Filled = true
realTimeTargetDot.Color = cfg.targetDotColor
realTimeTargetDot.Radius = cfg.targetDotRadius
realTimeTargetDot.Visible = false

local realTimeTargetDotOutline = Drawing.new("Circle")
realTimeTargetDotOutline.Thickness = 1
realTimeTargetDotOutline.Filled = false
realTimeTargetDotOutline.Color = cfg.targetDotOutlineColor
realTimeTargetDotOutline.Radius = cfg.targetDotRadius + 1
realTimeTargetDotOutline.Visible = false

-- =============================================================================
-- WINDOW & UI LAYOUT
-- =============================================================================
local Window = Compkiller.new({
    Name = "   Hitscan.cc",
    Keybind = "Insert",
    Logo = "rbxassetid://92470148307978",
    Scale = Compkiller.Scale.Window,
    TextSize = 14,
})

Window:DrawCategory({ Name = "Combat" })
local AimbotTab   = Window:DrawTab({ Name = "Aimbot", Icon = "target", Type = "Single", EnableScrolling = true })
local WeaponTab   = Window:DrawTab({ Name = "Gun Mods", Icon = "sword", Type = "Single", EnableScrolling = true })

Window:DrawCategory({ Name = "Visuals" })
local VisualsTab   = Window:DrawContainerTab({ Name = "Players", Icon = "eye", EnableScrolling = false })
local WorldTab     = Window:DrawTab({ Name = "World", Icon = "globe", Type = "Single", EnableScrolling = true })

local SilentAimSection = AimbotTab:DrawSection({ Name = "Silent Aim", Position = "left" })

local WeaponSection    = WeaponTab:DrawSection({ Name = "Weapon Modifications", Position = "left" })
local WorldSection     = WorldTab:DrawSection({ Name = "World Visuals", Position = "left" })

local EnemyTab = VisualsTab:DrawTab({Name = "Enemy", Type = "Single", EnableScrolling = true})
local LocalTab = VisualsTab:DrawTab({Name = "Local", Type = "Single", EnableScrolling = true})

local EnemyLeftSection  = EnemyTab:DrawSection({ Name = "Player Settings", Position = "left" })
local LocalSection      = LocalTab:DrawSection({ Name = "Local Chams Settings", Position = "left" })
local LocalCameraSection = LocalTab:DrawSection({ Name = "Local Camera Settings", Position = "right" })

Window:DrawCategory({ Name = "Misc" })
local MovementTab = Window:DrawTab({ Name = "Movement", Icon = "activity", Type = "Single", EnableScrolling = true })
local MovementSection = MovementTab:DrawSection({ Name = "Movement Settings", Position = "left" })

-- =============================================================================
-- HELPER UTILITIES
-- =============================================================================

local function getCleanName(merc)
    if not merc then return "" end
    local nameMatch = string.match(merc.Name, "_(.+)$")
    return nameMatch or merc.Name
end

local function getVisualModel(merc)
    if not merc then return nil end
    
    local visualFolder = merc:FindFirstChild("MercVisual")
    if visualFolder then
        if visualFolder:IsA("Model") then
            return visualFolder
        else
            local innerModel = visualFolder:FindFirstChildOfClass("Model")
            if innerModel then return innerModel end
        end
    end
    
    for _, child in ipairs(merc:GetChildren()) do
        if string.find(child.Name, "MercVisual") then
            if child:IsA("Model") then 
                return child 
            else
                local inner = child:FindFirstChildOfClass("Model")
                if inner then return inner end
            end
        end
    end
    
    return merc:IsA("Model") and merc or nil
end

local function isDead(merc)
    if not merc then return true end
    if not merc:IsDescendantOf(workspace) then return true end

    local modelToCheckParts = merc

    if not string.find(merc.Name, "MercVisual") then
        local parent = merc.Parent
        if parent then
            local expected1 = merc.Name .. "_MercVisual"
            local expected2 = merc.Name .. "MercVisual"
            local visualModel = parent:FindFirstChild(expected1) or parent:FindFirstChild(expected2)
            
            if not visualModel then
                local cleanName = getCleanName(merc)
                for _, child in ipairs(parent:GetChildren()) do
                    if string.find(child.Name, "MercVisual") and string.find(child.Name, cleanName, 1, true) then
                        visualModel = child
                        break
                    end
                end
            end

            if visualModel then
                if not visualModel:IsDescendantOf(workspace) then
                    return true
                end
                modelToCheckParts = visualModel
            else
                return true
            end
        end
    end

    local realPlayerName = getCleanName(merc)
    local mainCharacter = workspace:FindFirstChild(realPlayerName)
    if mainCharacter and mainCharacter:IsA("Model") then
        local humanoid = mainCharacter:FindFirstChildOfClass("Humanoid")
        if humanoid then
            return humanoid.Health <= 0
        end
    end

    local internalHumanoid = merc:FindFirstChildOfClass("Humanoid") or (merc:FindFirstChild("MercVisual") and merc.MercVisual:FindFirstChildOfClass("Humanoid"))
    if internalHumanoid then
        return internalHumanoid.Health <= 0
    end

    if not modelToCheckParts:FindFirstChild("Head") and not modelToCheckParts:FindFirstChildOfClass("BasePart") then
        return true
    end

    local visualFallback = getVisualModel(merc)
    if modelToCheckParts == merc and visualFallback and visualFallback ~= merc then
        if not visualFallback:FindFirstChild("Head") and not visualFallback:FindFirstChildOfClass("BasePart") then
            return true
        end
    end

    return false
end

local function getRandomName(length)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local randomString = ""
    for i = 1, length or 12 do
        local randIndex = math.random(1, #chars)
        randomString = randomString .. string.sub(chars, randIndex, randIndex)
    end
    return randomString
end

-- =============================================================================
-- ORIGINAL VISUALS LOGIC CHAMS
-- =============================================================================
local function clearHighlights()
    for obj, highlight in pairs(activeHighlights) do
        if highlight then
            pcall(function() highlight:Destroy() end)
        end
    end
    table.clear(activeHighlights)
end



local function updateChams()
    if not cfg.chams then 
        clearHighlights()
        return 
    end

    local mercPlayers = workspace:FindFirstChild("MercPlayers")
    if not mercPlayers then return end

    local currentIterationObjects = {}

    for _, merc in ipairs(mercPlayers:GetChildren()) do
        if merc.Name == LocalPlayer.Name then continue end
        if isDead(merc) then continue end
        
        local targetModel = getVisualModel(merc)
        if targetModel then
            currentIterationObjects[targetModel] = true
            
            local highlight = activeHighlights[targetModel]
            if not highlight or highlight.Parent ~= targetModel then
                if highlight then pcall(function() highlight:Destroy() end) end
                
                highlight = Instance.new("Highlight")
                highlight.Name = getRandomName(math.random(10, 16))
                highlight.FillColor = cfg.chamFillColor
                highlight.FillTransparency = cfg.chamFillTransparency
                highlight.OutlineColor = cfg.chamOutlineColor
                highlight.OutlineTransparency = cfg.chamOutlineTransparency
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.Parent = targetModel
                
                activeHighlights[targetModel] = highlight
            else
                highlight.FillColor = cfg.chamFillColor
                highlight.FillTransparency = cfg.chamFillTransparency
                highlight.OutlineColor = cfg.chamOutlineColor
                highlight.OutlineTransparency = cfg.chamOutlineTransparency
            end
        end
    end

    for obj, highlight in pairs(activeHighlights) do
        if not currentIterationObjects[obj] then
            if highlight then pcall(function() highlight:Destroy() end) end
            activeHighlights[obj] = nil
        end
    end
end

-- =============================================================================
-- BOX ESP SYSTEM
-- =============================================================================
local function clearBoxes()
    for _, esp in pairs(activeBoxes) do
        pcall(function() esp.box_outline:Remove() end)
        pcall(function() esp.box_filled:Remove() end)
        pcall(function() esp.box_inline:Remove() end)
        pcall(function() esp.box_name:Remove() end)
        pcall(function() esp.health_bar_bg:Remove() end)
        pcall(function() esp.health_bar:Remove() end)
    end
    table.clear(activeBoxes)
end

local function createEspBox()
    local esp = {
        box_outline = Drawing.new("Square"),
        box_filled = Drawing.new("Square"),
        box_inline = Drawing.new("Square"),
        box_name = Drawing.new("Text"),
        health_bar_bg = Drawing.new("Square"),
        health_bar = Drawing.new("Square")
    }

    esp.box_filled.ZIndex = 0
    esp.box_outline.ZIndex = 1
    esp.health_bar_bg.ZIndex = 1
    
    esp.box_inline.ZIndex = 2
    esp.health_bar.ZIndex = 2
    esp.box_name.ZIndex = 3

    return esp
end

local function updateBoxes()
    if not cfg.boxEsp and not cfg.boxName and not cfg.healthBar then
        clearBoxes()
        return
    end

    local viewportSize = Camera.ViewportSize
    local currentModels = {}

    local mercPlayers = workspace:FindFirstChild("MercPlayers")
    if not mercPlayers then return end

    for _, merc in ipairs(mercPlayers:GetChildren()) do
        if merc.Name == LocalPlayer.Name then continue end
        if string.find(merc.Name, "MercVisual") then continue end
        if isDead(merc) then continue end

        local targetModel = getVisualModel(merc)
        if not targetModel then continue end

        local minX, minY = math.huge, math.huge
        local maxX, maxY = -math.huge, -math.huge
        local anyOnScreen = false

        local weaponModel = targetModel:FindFirstChild("Weapon")

        for _, part in ipairs(targetModel:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and part.Name ~= "Head" then
                if not weaponModel or not part:IsDescendantOf(weaponModel) then
                    local cframe = part.CFrame
                    local size = part.Size / 2
                    local corners = {
                        cframe * CFrame.new(-size.X, -size.Y, -size.Z),
                        cframe * CFrame.new( size.X, -size.Y, -size.Z),
                        cframe * CFrame.new(-size.X,  size.Y, -size.Z),
                        cframe * CFrame.new( size.X,  size.Y, -size.Z),
                        cframe * CFrame.new(-size.X, -size.Y,  size.Z),
                        cframe * CFrame.new( size.X, -size.Y,  size.Z),
                        cframe * CFrame.new(-size.X,  size.Y,  size.Z),
                        cframe * CFrame.new( size.X,  size.Y,  size.Z)
                    }
                    for _, corner in ipairs(corners) do
                        local screenPos, onScreen = Camera:WorldToViewportPoint(corner.Position)
                        if onScreen then
                            anyOnScreen = true
                            local x, y = screenPos.X, screenPos.Y
                            if x < minX then minX = x end
                            if x > maxX then maxX = x end
                            if y < minY then minY = y end
                            if y > maxY then maxY = y end
                        end
                    end
                end
            end
        end

        if not anyOnScreen then continue end

        currentModels[targetModel] = true

        minX = math.max(0, minX)
        minY = math.max(0, minY)
        maxX = math.min(viewportSize.X, maxX)
        maxY = math.min(viewportSize.Y, maxY)

        local esp = activeBoxes[targetModel]
        if not esp then
            esp = createEspBox()
            activeBoxes[targetModel] = esp
        end

        local boxWidth = maxX - minX
        local boxHeight = maxY - minY

        local outline_offset = -2
        local box_outline_size = Vector2.new(boxWidth + outline_offset, boxHeight + outline_offset)
        local box_outline_position = Vector2.new(minX - (outline_offset / 2), minY - (outline_offset / 2))

        esp.box_outline.Thickness = 3
        esp.box_outline.Filled = false
        esp.box_outline.Size = box_outline_size
        esp.box_outline.Position = box_outline_position
        esp.box_outline.Color = cfg.boxOutlineColor
        esp.box_outline.Visible = cfg.boxEsp and cfg.boxOutline

        esp.box_filled.Thickness = 1
        esp.box_filled.Filled = true
        esp.box_filled.Size = Vector2.new(boxWidth, boxHeight)
        esp.box_filled.Position = Vector2.new(minX, minY)
        esp.box_filled.Color = cfg.boxFilledColor
        esp.box_filled.Transparency = 1 - cfg.boxFilledTransparency
        esp.box_filled.Visible = cfg.boxEsp and cfg.boxFilled

        esp.box_inline.Thickness = 1
        esp.box_inline.Filled = false
        esp.box_inline.Size = Vector2.new(boxWidth, boxHeight)
        esp.box_inline.Position = Vector2.new(minX, minY)
        esp.box_inline.Color = cfg.boxColor
        esp.box_inline.Visible = cfg.boxEsp

        esp.box_name.Text = getCleanName(merc)
        esp.box_name.Size = 13
        esp.box_name.Color = cfg.boxNameColor
        esp.box_name.Center = true
        esp.box_name.Outline = cfg.boxNameOutline
        pcall(function() esp.box_name.OutlineColor = cfg.boxNameOutlineColor end)
        esp.box_name.Position = Vector2.new(minX + (boxWidth / 2), minY - 18)
        esp.box_name.Visible = cfg.boxName

        if cfg.healthBar then
            local health = 100
            local maxHealth = 100
            
            local playerName = getCleanName(merc)
            local realPlayerModel = workspace:FindFirstChild(playerName)
            
            if realPlayerModel then
                local hum = realPlayerModel:FindFirstChildOfClass("Humanoid")
                if hum then
                    health = hum.Health
                    maxHealth = hum.MaxHealth
                end
            end
            local healthPercent = math.clamp(health / maxHealth, 0, 1)

            local bar_thickness = 1
            local outline_thickness = 3
            local margin = 4

            -- The box outline (Thickness 3, positioned at minX+1) effectively extends 1 pixel outward
            local box_outer_minY = minY - 1
            local box_outer_minX = minX - 1
            local box_outer_maxX = maxX + 1
            local box_outer_maxY = maxY + 1
            local box_outer_height = boxHeight + 2
            local box_outer_width = boxWidth + 2

            local bg_offset = cfg.healthBarOutline and 1 or 0
            local actual_thickness = cfg.healthBarOutline and outline_thickness or bar_thickness

            if cfg.healthBarPosition == "left" then
                hb_bg_size = Vector2.new(actual_thickness, box_outer_height)
                hb_bg_pos = Vector2.new(box_outer_minX - margin - actual_thickness, box_outer_minY)
                
                local inner_height = box_outer_height - (bg_offset * 2)
                hb_size = Vector2.new(bar_thickness, inner_height * healthPercent)
                hb_pos = Vector2.new(hb_bg_pos.X + bg_offset, box_outer_minY + bg_offset + (inner_height - hb_size.Y))
            elseif cfg.healthBarPosition == "right" then
                hb_bg_size = Vector2.new(actual_thickness, box_outer_height)
                hb_bg_pos = Vector2.new(box_outer_maxX + margin, box_outer_minY)
                
                local inner_height = box_outer_height - (bg_offset * 2)
                hb_size = Vector2.new(bar_thickness, inner_height * healthPercent)
                hb_pos = Vector2.new(hb_bg_pos.X + bg_offset, box_outer_minY + bg_offset + (inner_height - hb_size.Y))
            elseif cfg.healthBarPosition == "top" then
                hb_bg_size = Vector2.new(box_outer_width, actual_thickness)
                hb_bg_pos = Vector2.new(box_outer_minX, box_outer_minY - margin - actual_thickness)
                
                local inner_width = box_outer_width - (bg_offset * 2)
                hb_size = Vector2.new(inner_width * healthPercent, bar_thickness)
                hb_pos = Vector2.new(box_outer_minX + bg_offset, hb_bg_pos.Y + bg_offset)
            elseif cfg.healthBarPosition == "bottom" then
                hb_bg_size = Vector2.new(box_outer_width, actual_thickness)
                hb_bg_pos = Vector2.new(box_outer_minX, box_outer_maxY + margin)
                
                local inner_width = box_outer_width - (bg_offset * 2)
                hb_size = Vector2.new(inner_width * healthPercent, bar_thickness)
                hb_pos = Vector2.new(box_outer_minX + bg_offset, hb_bg_pos.Y + bg_offset)
            end

            esp.health_bar_bg.Filled = true
            esp.health_bar_bg.Size = hb_bg_size
            esp.health_bar_bg.Position = hb_bg_pos
            esp.health_bar_bg.Color = cfg.healthBarOutlineColor
            esp.health_bar_bg.Visible = cfg.healthBarOutline

            esp.health_bar.Filled = true
            esp.health_bar.Size = hb_size
            esp.health_bar.Position = hb_pos
            esp.health_bar.Color = cfg.healthBarColor
            esp.health_bar.Visible = true
        else
            esp.health_bar_bg.Visible = false
            esp.health_bar.Visible = false
        end
    end

    for model, esp in pairs(activeBoxes) do
        if not currentModels[model] then
            pcall(function() esp.box_outline:Remove() end)
            pcall(function() esp.box_filled:Remove() end)
            pcall(function() esp.box_inline:Remove() end)
            pcall(function() esp.box_name:Remove() end)
            pcall(function() esp.health_bar_bg:Remove() end)
            pcall(function() esp.health_bar:Remove() end)
            activeBoxes[model] = nil
        end
    end
end

-- =============================================================================
-- BULLET TRACER SYSTEM
-- =============================================================================
local weaponOffsets = {
    ["M18"] = 0.7,
    ["Rattler"] = 2.4, 
    ["KH9"] = 1.8,
    ["AUGA3"] = 3.4,
    ["UMP45"] = 2.3,
    ["BenelliM4"] = 3.6,
}

local function getLocalWeaponMuzzle()
    if Camera then
        local barrelAttacker = Camera:FindFirstChild("BarrelAttacher", true)
        if barrelAttacker and barrelAttacker.ClassName == "Part" then
            local finalPos = barrelAttacker.Position
            local parentModel = barrelAttacker:FindFirstAncestorOfClass("Model")
            
            if parentModel and weaponOffsets[parentModel.Name] then
                local offsetDistance = weaponOffsets[parentModel.Name]
                finalPos = finalPos + (barrelAttacker.CFrame.LookVector * offsetDistance)
            end
            return finalPos
        end

        local gunAttackerPart = Camera:FindFirstChild("GunAttacher", true)
        if gunAttackerPart and gunAttackerPart.ClassName == "Part" then
            local finalPos = gunAttackerPart.Position
            local parentModel = gunAttackerPart:FindFirstAncestorOfClass("Model")
            
            if parentModel and weaponOffsets[parentModel.Name] then
                local offsetDistance = weaponOffsets[parentModel.Name]
                finalPos = finalPos + (gunAttackerPart.CFrame.LookVector * offsetDistance)
            end
            return finalPos
        end
    end
    
    return Camera.CFrame.Position
end

local pendingTracers = {}

local function createBulletTracer(startPos, endPos)
    if not cfg.bulletTracers then return nil end
    table.insert(pendingTracers, {startPos = startPos, endPos = endPos})
end

local function updateBulletTracers()
    local currentTime = os.clock()

    if #pendingTracers > 0 then
        for i = 1, #pendingTracers do
            local data = pendingTracers[i]
            local tracerLine = Drawing.new("Line")
            tracerLine.Thickness = 2
            tracerLine.Color = cfg.tracerColor
            tracerLine.Transparency = 1
            tracerLine.Visible = false

            local tracerData = {
                line = tracerLine,
                startPos = data.startPos,
                endPos = data.endPos,
                startTime = currentTime
            }
            table.insert(activeTracers, tracerData)
        end
        table.clear(pendingTracers)
    end

    for i = #activeTracers, 1, -1 do
        local tracer = activeTracers[i]
        local age = currentTime - tracer.startTime
        
        if age >= cfg.tracerDuration then
            pcall(function() tracer.line:Remove() end)
            table.remove(activeTracers, i)
        else
            local camSpaceStart = Camera.CFrame:PointToObjectSpace(tracer.startPos)
            local camSpaceEnd = Camera.CFrame:PointToObjectSpace(tracer.endPos)
            
            local p1_Z = -camSpaceStart.Z
            local p2_Z = -camSpaceEnd.Z
            
            local minZ = 0.1 
            local visible = true
            
            if p1_Z < minZ and p2_Z < minZ then
                visible = false
            elseif p1_Z < minZ or p2_Z < minZ then
                local t = (minZ - p1_Z) / (p2_Z - p1_Z)
                local clippedCamSpace = camSpaceStart:Lerp(camSpaceEnd, t)
                
                if p1_Z < minZ then
                    camSpaceStart = clippedCamSpace
                else
                    camSpaceEnd = clippedCamSpace
                end
            end
            
            if visible then
                local worldStart = Camera.CFrame:PointToWorldSpace(camSpaceStart)
                local worldEnd = Camera.CFrame:PointToWorldSpace(camSpaceEnd)
                
                local startScreen = Camera:WorldToViewportPoint(worldStart)
                local endScreen = Camera:WorldToViewportPoint(worldEnd)
                
                tracer.line.From = Vector2.new(startScreen.X, startScreen.Y)
                tracer.line.To = Vector2.new(endScreen.X, endScreen.Y)
                tracer.line.Transparency = 1 - (age / cfg.tracerDuration)
                tracer.line.Color = cfg.tracerColor
                tracer.line.Visible = true
            else
                tracer.line.Visible = false
            end
        end
    end
end

local function updateRealTimeTargetDot()
    local isRightClickHeld = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)

    local hideDot = isRightClickHeld
    if cfg.thirdPerson then
        hideDot = false
    end

    if not cfg.targetDot or hideDot then
        realTimeTargetDot.Visible = false
        realTimeTargetDotOutline.Visible = false
        return
    end

    local muzzlePos = getLocalWeaponMuzzle()
    local direction = Camera.CFrame.LookVector 

    if Camera then
        local barrelAttacker = Camera:FindFirstChild("BarrelAttacher", true) 
            or Camera:FindFirstChild("GunAttacher", true)
            
        if barrelAttacker and barrelAttacker.ClassName == "Part" then
            direction = barrelAttacker.CFrame.LookVector
        end
    end

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}

    local result = workspace:Raycast(muzzlePos, direction * 1000, raycastParams)
    local targetWorldPos = result and result.Position or (muzzlePos + direction * 1000)
    local screenPos, onScreen = Camera:WorldToViewportPoint(targetWorldPos)

    if onScreen then
        local screenVector = Vector2.new(screenPos.X, screenPos.Y)
        
        realTimeTargetDot.Position = screenVector
        realTimeTargetDot.Color = cfg.targetDotColor
        realTimeTargetDot.Radius = cfg.targetDotRadius
        realTimeTargetDot.Visible = true

        if cfg.targetDotOutline then
            realTimeTargetDotOutline.Position = screenVector
            realTimeTargetDotOutline.Color = cfg.targetDotOutlineColor
            realTimeTargetDotOutline.Radius = cfg.targetDotRadius + 1
            realTimeTargetDotOutline.Visible = true
        else
            realTimeTargetDotOutline.Visible = false
        end
    else
        realTimeTargetDot.Visible = false
        realTimeTargetDotOutline.Visible = false
    end
end

-- =============================================================================
-- ENHANCED MULTI-POINT VISIBILITY SYSTEM
-- =============================================================================
local function getTargetPositionForPart(targetModel, partName)
    if partName == "Head" then
        return targetModel:FindFirstChild("Head")
    elseif partName == "HumanoidRootPart" then
        return targetModel:FindFirstChild("HumanoidRootPart")
            or targetModel:FindFirstChild("UpperTorso")
            or targetModel:FindFirstChild("Head")
    elseif partName == "Body" then
        return targetModel:FindFirstChild("UpperTorso") 
            or targetModel:FindFirstChild("HumanoidRootPart")
            or targetModel:FindFirstChildOfClass("BasePart")
    end
    return nil
end

local function castCheckRay(origin, dest, params, targetModel)
    local currentOrigin = origin
    local direction = dest - origin
    local distanceRemaining = direction.Magnitude
    local currentDirection = direction.Unit
    local currentFilter = params.FilterDescendantsInstances
    
    for i = 1, 5 do
        local result = workspace:Raycast(currentOrigin, currentDirection * distanceRemaining, params)
        
        if not result then 
            return true 
        end
        
        local hitInstance = result.Instance
        local hitName = hitInstance.Name
        
        if hitInstance:IsDescendantOf(targetModel) then 
            return true 
        end
        
        local isWindow = (hitName == "Window_Breakable" or hitName == "_GlassWedges")
        local isShard = (hitName == "Wedge" and (hitInstance:FindFirstAncestor("_GlassWedges") or hitInstance:FindFirstAncestor("Window_Breakable")))
        
        local isTransparentPass = (hitInstance.CanCollide == false and hitInstance.Transparency >= 0.9)

        if isWindow or isShard or isTransparentPass then
            local hitPosition = result.Position
            currentOrigin = hitPosition + (currentDirection * 0.05)
            distanceRemaining = (dest - currentOrigin).Magnitude
            
            if distanceRemaining <= 0.05 then
                return true
            end
        else
            return false
        end
    end
    
    return false
end

local function isPlayerVisible(targetPart, targetModel)
    local origin = Camera.CFrame.Position
    local baseDest = targetPart.Position
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    
    if castCheckRay(origin, baseDest, raycastParams, targetModel) then
        return true
    end
    
    local partSize = targetPart.Size
    local offsetX = math.max(0.1, partSize.X * 0.35)
    local offsetY = math.max(0.1, partSize.Y * 0.35)
    local offsetZ = math.max(0.1, partSize.Z * 0.35)
    
    local scatterPoints = {
        baseDest + Vector3.new(0, offsetY, 0),   -- Top Inset
        baseDest + Vector3.new(0, -offsetY, 0),  -- Bottom Inset
        baseDest + Vector3.new(offsetX, 0, 0),   -- Right Inset
        baseDest + Vector3.new(-offsetX, 0, 0),  -- Left Inset
        baseDest + Vector3.new(0, 0, offsetZ),   -- Front Inset
        baseDest + Vector3.new(0, 0, -offsetZ)   -- Back Inset
    }
    
    for idx = 1, #scatterPoints do
        if castCheckRay(origin, scatterPoints[idx], raycastParams, targetModel) then
            return true
        end
    end
    
    return false
end

local function getWeaponScreenPosition()
    if not Camera then return UserInputService:GetMouseLocation() end
    
    local activeAsset = Camera:FindFirstChild("BarrelAttacher", true) 
        or Camera:FindFirstChild("GunAttacher", true)
        
    if not activeAsset or activeAsset.ClassName ~= "Part" then 
        return UserInputService:GetMouseLocation() 
    end
    
    local muzzlePos = getLocalWeaponMuzzle()
    local direction = activeAsset.CFrame.LookVector 

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    
    local ignoreList = {LocalPlayer.Character, Camera}
    
    -- If the hitbox is active and pulled to the camera, the raycast will hit it instantly and break the FOV.
    -- We must ignore the current target's head so the raycast passes through to find the real world position.
    if cfg.hitboxExpander then
        local mercPlayers = workspace:FindFirstChild("MercPlayers")
        if mercPlayers then
            for _, merc in ipairs(mercPlayers:GetChildren()) do
                local head = merc:FindFirstChild("Head")
                if head then
                    table.insert(ignoreList, head)
                end
            end
        end
    end
    
    raycastParams.FilterDescendantsInstances = ignoreList

    local result = workspace:Raycast(muzzlePos, direction * 1000, raycastParams)
    local targetWorldPos = result and result.Position or (muzzlePos + direction * 1000)

    local screenPos, onScreen = Camera:WorldToViewportPoint(targetWorldPos)
    if onScreen and screenPos then
        return Vector2.new(screenPos.X, screenPos.Y)
    end
    
    return UserInputService:GetMouseLocation()
end

local function getClosestTargetToCrosshair(forceCheck)
    local closestData = nil
    local shortestFovDist = math.huge
    local mousePos = UserInputService:GetMouseLocation()
    local weaponPos = getWeaponScreenPosition()
    local trackingOrigin = cfg.dynamicFov and weaponPos or mousePos

    local mercPlayers = workspace:FindFirstChild("MercPlayers")
    if not mercPlayers then return nil end
    
    for _, merc in ipairs(mercPlayers:GetChildren()) do
        if merc.Name == LocalPlayer.Name then continue end
        if string.find(merc.Name, "MercVisual") then continue end
        if isDead(merc) then continue end
        
        local targetModel = merc
        if targetModel then
            local targetPart = getTargetPositionForPart(targetModel, cfg.aimPart)
            local trackingPart = getTargetPositionForPart(targetModel, "HumanoidRootPart") or targetPart
            if targetPart and trackingPart then
                if forceCheck or cfg.wallCheck then
                    if not isPlayerVisible(targetPart, targetModel) then
                        continue
                    end
                end

                local screenPos, onScreen = Camera:WorldToViewportPoint(trackingPart.Position)
                
                if onScreen then
                    local fovDist = (Vector2.new(screenPos.X, screenPos.Y) - trackingOrigin).Magnitude
                    if fovDist <= cfg.fovRadius and fovDist < shortestFovDist then
                        shortestFovDist = fovDist
                        closestData = {
                            position = targetPart.Position,
                            part = targetPart,
                            model = targetModel,
                            trackingPosition = trackingPart.Position
                        }
                    end
                end
            end
        end
    end
    return closestData
end

-- =============================================================================
-- BALLISTICS INTERCEPTION
-- =============================================================================
local originalDischarge = BulletController.Discharge
BulletController.Discharge = function(self, weaponId, origin, direction, trailOrigin, ...)
    local targetData = getClosestTargetToCrosshair(false)
    local targetedPosition = (cfg.silentAim and targetData) and targetData.position or nil
    
    local tracerOrigin = getLocalWeaponMuzzle()
    local tracerDestination = origin + (direction * 500)
    
    if cfg.silentAim and targetedPosition then
        local dirToTarget = (targetedPosition - origin).Unit
        local teleportDistance = 10
        local newOrigin = targetedPosition - dirToTarget * teleportDistance
        local newDirection = (targetedPosition - newOrigin).Unit
        
        origin = newOrigin
        direction = newDirection
        tracerDestination = targetedPosition
    elseif cfg.noSpread then
        tracerDestination = origin + (direction * 1000)
        
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
        
        local res = workspace:Raycast(origin, direction * 1000, raycastParams)
        if res then
            tracerDestination = res.Position
        end
    else
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
        
        local res = workspace:Raycast(origin, direction * 1000, raycastParams)
        if res then
            tracerDestination = res.Position
        end
    end
    
    if cfg.bulletTracers then
        createBulletTracer(tracerOrigin, tracerDestination)
    end
    
    return originalDischarge(self, weaponId, origin, direction, trailOrigin, ...)
end


-- =============================================================================
-- WEAPON TAB MODIFICATIONS
-- =============================================================================
local function handleWeaponModifications(weapon)
    if type(weapon) ~= "table" then return end
    
    if not weaponBackups[weapon] then
        weaponBackups[weapon] = {
            AmmoType = weapon.AmmoType,
            MagAmmo = weapon.MagAmmo,
            Magazines = weapon._magazines and {unpack(weapon._magazines)} or nil,
            FireMode = weapon.FireMode,
            FireRate = weapon.FireRate,
            ConfigFireRate = weapon.Config and weapon.Config.fire_rate or nil
        }
    end

    if cfg.alwaysAuto then
        weapon.FireMode = "auto"
        weapon.CanFire = true
    end

    if cfg.rapidFire then
        local baseRate = weaponBackups[weapon].FireRate or 0.1
        local newRate = baseRate / cfg.rapidFireMultiplier
        
        weapon.FireRate = newRate
        if weapon.Config then
            weapon.Config.fire_rate = newRate
        end
    else
        if weaponBackups[weapon] then
            weapon.FireRate = weaponBackups[weapon].FireRate
            if weapon.Config and weaponBackups[weapon].ConfigFireRate then
                weapon.Config.fire_rate = weaponBackups[weapon].ConfigFireRate
            end
        end
    end

    if cfg.instantReload and weapon.IsReloading then
        pcall(function()
            if weapon._reloadTask then
                task.cancel(weapon._reloadTask)
                weapon._reloadTask = nil
            end
            weapon:FinishReload()
        end)
    end

    if cfg.infiniteAmmo then
        local max = weapon.MaxMagSize or (weapon.Config and weapon.Config.mag_size) or 30
        weapon.AmmoType = "none"
        weapon.MagAmmo = max + 1
        if weapon._magazines then
            for i = 1, #weapon._magazines do
                weapon._magazines[i] = max
            end
        end
    end
end

local function restoreAmmo(weapon)
    if type(weapon) ~= "table" or not weaponBackups[weapon] then return end
    local backup = weaponBackups[weapon]
    
    weapon.AmmoType = backup.AmmoType
    weapon.MagAmmo = backup.MagAmmo
    if weapon._magazines and backup.Magazines then
        for i = 1, #weapon._magazines do
            weapon._magazines[i] = backup.Magazines[i] or weapon._magazines[i]
        end
    end
end

local function restoreFireMode(weapon)
    if type(weapon) ~= "table" or not weaponBackups[weapon] then return end
    local backup = weaponBackups[weapon]
    weapon.FireMode = backup.FireMode
end

-- =============================================================================
-- CENTRALIZED ENGINE HOOK ARCHITECTURE (RECOIL, SPREAD, & AMMO)
-- =============================================================================
if hf then
    if type(GunController) == "table" and GunController.ApplyRecoil then
        local origApplyRecoil = cf(GunController.ApplyRecoil)
        hf(GunController.ApplyRecoil, nc(function(self, ...)
            if cfg.noSpread then 
                if cfg.spreadControl == 0 then return end
                local args = {...}
                local modifier = cfg.spreadControl / 100
                for i, arg in ipairs(args) do
                    if type(arg) == "number" then args[i] = arg * modifier end
                end
                return origApplyRecoil(self, unpack(args))
            end
            return origApplyRecoil(self, ...)
        end))
    end

    if type(CameraController) == "table" then
        local cameraMethods = {"Recoil", "_EquipKick"}
        for _, method in ipairs(cameraMethods) do
            if CameraController[method] then
                local origMethod = cf(CameraController[method])
                hf(CameraController[method], nc(function(self, ...)
                    if cfg.noRecoil then 
                        if cfg.recoilControl == 0 then return end
                        local args = {...}
                        local modifier = cfg.recoilControl / 100
                        for i, arg in ipairs(args) do
                            if type(arg) == "number" then args[i] = arg * modifier
                            elseif type(arg) == "Vector3" then args[i] = arg * modifier
                            elseif type(arg) == "Vector2" then args[i] = arg * modifier
                            end
                        end
                        return origMethod(self, unpack(args))
                    end
                    return origMethod(self, ...)
                end))
            end
        end

        local shakeMethods = {"BoomKick", "ShakeImpulse"}
        for _, method in ipairs(shakeMethods) do
            if CameraController[method] then
                local origMethod = cf(CameraController[method])
                hf(CameraController[method], nc(function(self, ...)
                    if cfg.noScreenShake then return end
                    return origMethod(self, ...)
                end))
            end
        end

        if CameraController.SetFlashSensitivity then
            local origFlash = cf(CameraController.SetFlashSensitivity)
            hf(CameraController.SetFlashSensitivity, nc(function(self, ...)
                if cfg.antiFlash then return end
                return origFlash(self, ...)
            end))
        end

        if CameraController.SetFovOffset then
            local origFov = cf(CameraController.SetFovOffset)
            hf(CameraController.SetFovOffset, nc(function(self, offset, ...)
                if cfg.fovOverride then
                    local baseFov = 70
                    return origFov(self, cfg.fovAmount - baseFov, ...)
                end
                return origFov(self, offset, ...)
            end))
        end

    end

    local ok, FS = pcall(require, ReplicatedStorage.Modules.Shared.FirearmState)
    if ok then
        ifFS_Fire = FS.Fire and cf(FS.Fire)
        if FS.Fire then
            hf(FS.Fire, nc(function(self, ...)
                if type(self) == "table" then
                    handleWeaponModifications(self)
                end
                return ifFS_Fire(self, ...)
            end))
        end

        if type(FS.GetReserve) == "function" then
            local origReserve = cf(FS.GetReserve)
            hf(FS.GetReserve, nc(function(self, ...)
                local reserve = origReserve(self, ...)
                if cfg.infiniteAmmo and type(self) == "table" and reserve <= 0 then
                    return 9999
                end
                return reserve
            end))
        end
    end
    
    local okAP, AP = pcall(require, ReplicatedStorage.Modules.Shared.AmmoPool)
    if okAP and type(AP.ConsumeAmmo) == "function" then
        local origConsume = cf(AP.ConsumeAmmo)
        hf(AP.ConsumeAmmo, nc(function(pool, ammoType, amount, ...)
            if cfg.infiniteAmmo then return amount or 1 end
            return origConsume(pool, ammoType, amount, ...)
        end))
    end
end

local function applyHandChams()
    local Camera = workspace:FindFirstChild("Camera")
    if not Camera then return end
    for _, model in ipairs(Camera:GetChildren()) do
        if model:IsA("Model") and model.Name ~= "Headphones" then
            for _, part in ipairs(model:GetDescendants()) do
                if part:IsA("MeshPart") then
                    if string.sub(part.Name, 1, 2) == "SK" then
                        
                        if not originalHandChams[part] then
                            originalHandChams[part] = {
                                Material = part.Material,
                                Color = part.Color,
                                BrickColor = part.BrickColor,
                                TextureID = part.TextureID,
                                SurfaceAppearance = part:FindFirstChildOfClass("SurfaceAppearance")
                            }
                        end

                        local surface = part:FindFirstChildOfClass("SurfaceAppearance")
                        if surface then
                            surface:Destroy()
                        end

                        part.Material = cfg.handMaterial
                        part.Color = cfg.handColor
                        part.BrickColor = BrickColor.new(cfg.handColor)
                    end
                end
            end
        end
    end
end

local function removeHandChams()
    for part, data in pairs(originalHandChams) do
        if part and part.Parent then
            part.Material = data.Material
            part.Color = data.Color
            part.BrickColor = data.BrickColor
            part.TextureID = data.TextureID

            if data.SurfaceAppearance then
                local old = part:FindFirstChildOfClass("SurfaceAppearance")
                if old then
                    old:Destroy()
                end

                data.SurfaceAppearance:Clone().Parent = part
            end
        end
    end

    originalHandChams = {}
end

local function applyWeaponChams()
    local Camera = workspace:FindFirstChild("Camera")
    if not Camera then return end

    for _, model in ipairs(Camera:GetChildren()) do
        if model:IsA("Model") and model.Name ~= "Headphones" then

            for _, part in ipairs(model:GetDescendants()) do
                if part:IsA("MeshPart") then

                    local name = part.Name:lower()

                    if name:find("gun")
                        or name:find("casing")
                        or name:find("mag")  then

                        if not originalWeaponChams[part] then
                            local surface = part:FindFirstChildOfClass("SurfaceAppearance")

                            originalWeaponChams[part] = {
                                Material = part.Material,
                                Color = part.Color,
                                BrickColor = part.BrickColor,
                                TextureID = part.TextureID,
                                SurfaceAppearance = surface and surface:Clone()
                            }
                        end

                        local surface = part:FindFirstChildOfClass("SurfaceAppearance")
                        if surface then
                            surface:Destroy()
                        end

                        part.Material = cfg.weaponMaterial
                        part.Color = cfg.weaponColor
                        part.BrickColor = BrickColor.new(cfg.weaponColor)
                    end
                end
            end
        end
    end
end

local function removeWeaponChams()
    for part, data in pairs(originalWeaponChams) do
        if part and part.Parent then
            part.Material = data.Material
            part.Color = data.Color
            part.BrickColor = data.BrickColor
            part.TextureID = data.TextureID

            if data.SurfaceAppearance then
                local old = part:FindFirstChildOfClass("SurfaceAppearance")
                if old then
                    old:Destroy()
                end

                data.SurfaceAppearance:Clone().Parent = part
            end
        end
    end

    originalWeaponChams = {}
end

local function applyAttachmentChams()
    local Camera = workspace:FindFirstChild("Camera")
    if not Camera then return end

    for _, model in ipairs(Camera:GetChildren()) do
        if model:IsA("Model") and model.Name ~= "Headphones" then
            local AllAttachments = model:FindFirstChild("AllAttachments")
            if AllAttachments and AllAttachments:IsA("Folder") then
                for _, obj in ipairs(AllAttachments:GetDescendants()) do
                    
                    if obj:IsA("MeshPart") then
                        
                        if not originalAttachmentChams[obj] then
                            local surface = obj:FindFirstChildOfClass("SurfaceAppearance")

                            originalAttachmentChams[obj] = {
                                Material = obj.Material,
                                Color = obj.Color,
                                BrickColor = obj.BrickColor,
                                TextureID = obj.TextureID,
                                SurfaceAppearance = surface and surface:Clone()
                            }
                        end

                        local surface = obj:FindFirstChildOfClass("SurfaceAppearance")
                        if surface then
                            surface:Destroy()
                        end

                        obj.Material = cfg.attachmentMaterial
                        obj.Color = cfg.attachmentColor
                        obj.BrickColor = BrickColor.new(cfg.attachmentColor)
                    end
                end
            end
        end
    end
end

local function removeAttachmentChams()
    for part, data in pairs(originalAttachmentChams) do
        if part and part.Parent then

            part.Material = data.Material
            part.Color = data.Color
            part.BrickColor = data.BrickColor
            part.TextureID = data.TextureID

            if data.SurfaceAppearance then
                local old = part:FindFirstChildOfClass("SurfaceAppearance")
                if old then
                    old:Destroy()
                end

                data.SurfaceAppearance:Clone().Parent = part
            end
        end
    end

    originalAttachmentChams = {}
end

local function applyLocalModelChams()
    local mercPOV = workspace:FindFirstChild("MercPOV")
    if not mercPOV then return end
    
    local firstModel = nil
    if LocalPlayer and LocalPlayer.Name then
        firstModel = mercPOV:FindFirstChild("MercPOV_" .. LocalPlayer.Name)
    end
    
    if not firstModel then return end

    for _, part in ipairs(firstModel:GetDescendants()) do
        if part:IsA("BasePart") then
            if not originalLocalModelChams[part] then
                originalLocalModelChams[part] = {
                    Material = part.Material,
                    Color = part.Color,
                    BrickColor = part.BrickColor,
                    TextureID = part:IsA("MeshPart") and part.TextureID or "",
                    SurfaceAppearance = part:FindFirstChildOfClass("SurfaceAppearance")
                }
            end

            local surface = part:FindFirstChildOfClass("SurfaceAppearance")
            if surface then
                surface:Destroy()
            end

            part.Material = cfg.localModelMaterial
            part.Color = cfg.localModelColor
        end
    end
end

local function removeLocalModelChams()
    for part, data in pairs(originalLocalModelChams) do
        if part and part.Parent then
            part.Material = data.Material
            part.Color = data.Color
            part.BrickColor = data.BrickColor
            if part:IsA("MeshPart") then
                part.TextureID = data.TextureID
            end

            if data.SurfaceAppearance then
                local old = part:FindFirstChildOfClass("SurfaceAppearance")
                if not old then
                    data.SurfaceAppearance:Clone().Parent = part
                end
            end
        end
    end
end

local function updateHitboxes(currentTargetModel)
    local mercPlayers = workspace:FindFirstChild("MercPlayers")
    if not mercPlayers then return end

    for _, merc in ipairs(mercPlayers:GetChildren()) do
        if merc.Name == LocalPlayer.Name or string.find(merc.Name, "MercVisual") or isDead(merc) then continue end
        
        local head = getTargetPositionForPart(merc, "Head")
        if head and head:IsA("BasePart") then
            if not originalHitboxes[head] then
                originalHitboxes[head] = {
                    Size = head.Size,
                    Transparency = head.Transparency,
                    CanCollide = head.CanCollide
                }
            end

            if cfg.hitboxExpander and merc == currentTargetModel then
                if not originalHitboxes[head].NeckWeld then
                    local neck = head.Parent:FindFirstChild("Neck", true) or merc:FindFirstChild("Neck", true)
                    if neck and neck:IsA("Motor6D") then
                        originalHitboxes[head].NeckWeld = {
                            Name = neck.Name,
                            Parent = neck.Parent,
                            Part0 = neck.Part0,
                            Part1 = neck.Part1,
                            C0 = neck.C0,
                            C1 = neck.C1
                        }
                        neck:Destroy()
                    end
                end
                
                local hum = merc:FindFirstChild("Humanoid")
                if hum then hum.RequiresNeck = false end

                head.Size = Vector3.new(1, 1, 1)
                head.Transparency = 1 
                head.CanCollide = false
                head.Massless = true
                head.Anchored = true
                
                local muzzlePos = getLocalWeaponMuzzle()
                local direction = Camera.CFrame.LookVector
                
                local barrelAttacker = Camera:FindFirstChild("BarrelAttacher", true) 
                    or Camera:FindFirstChild("GunAttacher", true)
                    
                if barrelAttacker and barrelAttacker.ClassName == "Part" then
                    direction = barrelAttacker.CFrame.LookVector
                end
                
                head.CFrame = CFrame.lookAt(muzzlePos + (direction * 2), muzzlePos)
            else
                head.Size = originalHitboxes[head].Size
                head.Transparency = originalHitboxes[head].Transparency
                head.CanCollide = originalHitboxes[head].CanCollide
                head.Massless = false
                head.Anchored = false

                if originalHitboxes[head].NeckWeld then
                    local weldData = originalHitboxes[head].NeckWeld
                    if weldData.Parent and not weldData.Parent:FindFirstChild(weldData.Name) then
                        local newNeck = Instance.new("Motor6D")
                        newNeck.Name = weldData.Name
                        newNeck.Part0 = weldData.Part0
                        newNeck.Part1 = weldData.Part1
                        newNeck.C0 = weldData.C0
                        newNeck.C1 = weldData.C1
                        newNeck.Parent = weldData.Parent
                    end
                    originalHitboxes[head].NeckWeld = nil
                end
            end
        end
    end
end

-- =============================================================================
-- HEARTEAT RUNTIME UPDATE PIPELINE
-- =============================================================================
RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function()
    Camera = workspace.CurrentCamera
    
    if GunController and GunController.Weapon then
        handleWeaponModifications(GunController.Weapon)
    end
    
    if cfg.noSway and type(CameraController) == "table" then
        CameraController.WeaponWalkIntensity = 0
        CameraController.WeaponSwayPhase = 0
    end
    
    updateChams()
    updateBoxes()
    updateBulletTracers()
    updateRealTimeTargetDot()
    
    if cfg.handChams then
        applyHandChams()
    else
        removeHandChams()
    end

    if cfg.weaponChams then
        applyWeaponChams()
    else
        removeWeaponChams()
    end

    if cfg.attachmentChams then
        applyAttachmentChams()
    else
        removeAttachmentChams()
    end
    
    if cfg.localModelChams then
        applyLocalModelChams()
    else
        removeLocalModelChams()
    end
    
    local mousePos = UserInputService:GetMouseLocation()
    local weaponPos = getWeaponScreenPosition()

    if cfg.drawFov then
        fovCircle.Visible = true
        fovCircle.Radius = cfg.fovRadius
        fovCircle.Color = cfg.fovColor
        if cfg.dynamicFov then
            fovCircle.Position = weaponPos
        else
            fovCircle.Position = mousePos
        end
    else
        fovCircle.Visible = false
    end

    local targetDataNormal = getClosestTargetToCrosshair(false)
    local currentTarget = targetDataNormal and targetDataNormal.position or nil
    local currentTargetModel = targetDataNormal and targetDataNormal.model or nil
    local trackingTarget = targetDataNormal and targetDataNormal.trackingPosition or currentTarget

    updateHitboxes(currentTargetModel)
    
    if (cfg.enableWalkSpeed or cfg.enableFly) and LocalPlayer and LocalPlayer.Name then
        local myCharacter = workspace:FindFirstChild(LocalPlayer.Name) or LocalPlayer.Character
        if myCharacter then
            local myHumanoid = myCharacter:FindFirstChild("Humanoid")
            local rootPart = myCharacter:FindFirstChild("HumanoidRootPart")
            if myHumanoid and rootPart then
                
                if cfg.enableWalkSpeed then
                    local lookVec = Vector3.new(Camera.CFrame.LookVector.X, 0, Camera.CFrame.LookVector.Z)
                    if lookVec.Magnitude > 0 then lookVec = lookVec.Unit end
                    
                    local rightVec = Vector3.new(Camera.CFrame.RightVector.X, 0, Camera.CFrame.RightVector.Z)
                    if rightVec.Magnitude > 0 then rightVec = rightVec.Unit end

                    local moveDir = Vector3.new(0, 0, 0)
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + lookVec end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - lookVec end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + rightVec end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - rightVec end

                    if moveDir.Magnitude > 0 then
                        moveDir = moveDir.Unit
                        local extraSpeed = math.max(0, cfg.momentumWalkSpeed - 16)
                        if extraSpeed > 0 then
                            local moveDelta = moveDir * (extraSpeed / 60)
                            rootPart.CFrame = rootPart.CFrame + Vector3.new(moveDelta.X, 0, moveDelta.Z)
                        end
                    end
                end

                if cfg.enableFly then
                    local flyY = 0
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                        flyY = cfg.flySpeed / 60
                    elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                        flyY = -cfg.flySpeed / 60
                    end

                    local lookVec = Vector3.new(Camera.CFrame.LookVector.X, 0, Camera.CFrame.LookVector.Z).Unit
                    local rightVec = Vector3.new(Camera.CFrame.RightVector.X, 0, Camera.CFrame.RightVector.Z).Unit
                    
                    local moveDir = Vector3.new(0, 0, 0)
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + lookVec end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - lookVec end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + rightVec end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - rightVec end

                    if moveDir.Magnitude > 0 then
                        moveDir = moveDir.Unit
                    end

                    local moveDelta = moveDir * (cfg.flySpeed / 60)
                    rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    rootPart.CFrame = rootPart.CFrame + Vector3.new(moveDelta.X, flyY, moveDelta.Z)

                end

                if cfg.enableNoclip then
                    for _, part in ipairs(myCharacter:GetDescendants()) do
                        if part:IsA("BasePart") and part.CanCollide then
                            part.CanCollide = false
                        end
                    end
                end
            end
        end
    end

    if cfg.autoShoot and GunController and GunController.Weapon then
        local targetDataStrict = getClosestTargetToCrosshair(true)
        if targetDataStrict then
            local currentWeapon = GunController.Weapon
            local currentTime = os.clock()
            local clickDelay = currentWeapon.FireRate or 0.1
            
            if currentTime - lastAutoShot >= clickDelay then
                lastAutoShot = currentTime
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                task.delay(0.05, function()
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                end)
            end
        end
    else
        if cfg.autoShoot then
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        end
    end

    if cfg.drawSnapline and trackingTarget then
        local screenPos, onScreen = Camera:WorldToViewportPoint(trackingTarget)
        if onScreen then
            if cfg.dynamicFov then
                snapLine.From = weaponPos
            else
                snapLine.From = mousePos
            end

            snapLine.To = Vector2.new(screenPos.X, screenPos.Y)
            snapLine.Color = cfg.snaplineColor
            snapLine.Visible = true
        else
            snapLine.Visible = false
        end
    else
        snapLine.Visible = false
    end
end))

-- =============================================================================
-- UI TOGGLE CALLBACKS
-- =============================================================================

SilentAimSection:AddToggle({
    Name = "Enable Silent Aim",
    Flag = "UI_Enable_Silent_Aim",
    Default = false,
    Callback = function(state)
        cfg.silentAim = state
    end,
})

local HitboxToggle = SilentAimSection:AddToggle({
    Name = "Magic Bullet",
    Flag = "UI_Magic_Bullet",
    Default = false,
    Risky = true,
    Callback = function(state)
        cfg.hitboxExpander = state
    end,
})

HitboxToggle.Link:AddHelper({
    Text = "    Killing enemies too quickly may result in a server kick."
})

SilentAimSection:AddToggle({
    Name = "Visibility Check",
    Flag = "UI_Visibility_Check", 
    Default = false,
    Callback = function(state)
        cfg.wallCheck = state
    end,
})

SilentAimSection:AddToggle({
    Name = "Auto Shoot",
    Flag = "UI_Auto_Shoot", 
    Default = false,
    Callback = function(state)
        cfg.autoShoot = state
    end,
})

local FovToggle = SilentAimSection:AddToggle({
    Name = "Draw Field Of View",
    Flag = "UI_Draw_Field_Of_View",
    Default = false,
    Callback = function(state)
        cfg.drawFov = state
    end,
})

local fovOption = FovToggle.Link:AddOption()
FovToggle.Link:AddColorPicker({
    Name = "FOV Color",
    Flag = "UI_FOV_Color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(color)
        cfg.fovColor = color
    end,
})

fovOption:AddToggle({
    Name = "Dynamic",
    Flag = "UI_Dynamic",
    Default = true,
    Callback = function(state)
        cfg.dynamicFov = state
    end,
})

local SnaplineToggle = SilentAimSection:AddToggle({
    Name = "Draw Snapline",
    Flag = "UI_Draw_Snapline",
    Default = false,
    Callback = function(state)
        cfg.drawSnapline = state
    end,
})

SnaplineToggle.Link:AddColorPicker({
    Name = "Snapline Color",
    Flag = "UI_Snapline_Color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(color)
        cfg.snaplineColor = color
    end,
})

SilentAimSection:AddSlider({
    Name = "Field Of View",
    Flag = "UI_Field_Of_View",
    Min = 10,
    Max = 800,
    Default = 150,
    Round = 0,
    Callback = function(val)
        cfg.fovRadius = val
    end,
})

SilentAimSection:AddDropdown({
    Name = "Aim Target",
    Flag = "UI_Aim_Target",
    Values = {"Head", "Body"},
    Default = "Head",
    Callback = function(value)
        cfg.aimPart = value
    end,
})


-- =============================================================================
-- GUN MODS SECTION
-- =============================================================================
WeaponSection:AddToggle({
    Name = "Always Automatic",
    Flag = "UI_Always_Automatic",
    Default = false,
    Callback = function(state)
        cfg.alwaysAuto = state
        if state then
            handleWeaponModifications(GunController.Weapon)
        else
            restoreFireMode(GunController.Weapon)
        end
    end,
})

local RapidFireToggle = WeaponSection:AddToggle({
    Name = "Rapid Fire",
    Flag = "UI_Rapid_Fire",
    Default = false,
    Callback = function(state)
        cfg.rapidFire = state
        if GunController and GunController.Weapon then
            handleWeaponModifications(GunController.Weapon)
        end
    end,
})

local rapidFireOption = RapidFireToggle.Link:AddOption()
rapidFireOption:AddSlider({
    Name = "Fire Rate Multiplier",
    Flag = "UI_Fire_Rate_Multiplier",
    Min = 1,
    Max = 10,
    Default = 2,
    Round = 1,
    Callback = function(val)
        cfg.rapidFireMultiplier = val
        if GunController and GunController.Weapon then
            handleWeaponModifications(GunController.Weapon)
        end
    end
})

WeaponSection:AddToggle({
    Name = "Instant Reload",
    Flag = "UI_Instant_Reload",
    Default = false,
    Callback = function(state)
        cfg.instantReload = state
    end,
})

local SpreadToggle = WeaponSection:AddToggle({
    Name = "No Spread",
    Flag = "UI_No_Spread",
    Default = false,
    Callback = function(state)
        cfg.noSpread = state
    end,
})

local spreadOption = SpreadToggle.Link:AddOption()
spreadOption:AddSlider({
    Name = "Spread Power (%)",
    Flag = "UI_Spread_Power_%",
    Min = 0,
    Max = 100,
    Default = 0,
    Round = 0,
    Callback = function(val)
        cfg.spreadControl = val
    end,
})

local RecoilToggle = WeaponSection:AddToggle({
    Name = "No Recoil",
    Flag = "UI_No_Recoil",
    Default = false,
    Callback = function(state)
        cfg.noRecoil = state
    end,
})

local recoilOption = RecoilToggle.Link:AddOption()
recoilOption:AddSlider({
    Name = "Recoil Power (%)",
    Flag = "UI_Recoil_Power_%",
    Min = 0,
    Max = 100,
    Default = 0,
    Round = 0,
    Callback = function(val)
        cfg.recoilControl = val
    end,
})

WeaponSection:AddToggle({
    Name = "Infinite Ammo",
    Flag = "UI_Infinite_Ammo",
    Default = false,
    Callback = function(state)
        cfg.infiniteAmmo = state
        if state then
            handleWeaponModifications(GunController.Weapon)
        else
            restoreAmmo(GunController.Weapon)
        end
    end,
})

-- =============================================================================
-- ENEMY CONTAINER ELEMENTS (BOX & CHAMS)
-- =============================================================================
local NameToggle = EnemyLeftSection:AddToggle({
    Name = "Enable Name",
    Flag = "UI_Enable_Name",
    Default = false,
    Callback = function(state)
        cfg.boxName = state
    end,
})

local nameOption = NameToggle.Link:AddOption()
nameOption:AddColorPicker({
    Name = "Name Color",
    Flag = "UI_Name_Color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(color)
        cfg.boxNameColor = color
    end,
})

local NameOutlineToggle = nameOption:AddToggle({
    Name = "Name Outline",
    Flag = "UI_Name_Outline",
    Default = true,
    Callback = function(state)
        cfg.boxNameOutline = state
    end,
})

NameOutlineToggle.Link:AddColorPicker({
    Name = "Outline Color",
    Flag = "UI_Outline_Color",
    Default = Color3.fromRGB(0, 0, 0),
    Callback = function(color)
        cfg.boxNameOutlineColor = color
    end,
})

local HealthBarToggle = EnemyLeftSection:AddToggle({
    Name = "Enable Health Bar",
    Flag = "UI_Enable_Health_Bar",
    Default = false,
    Callback = function(state)
        cfg.healthBar = state
    end,
})

local healthOption = HealthBarToggle.Link:AddOption()
healthOption:AddColorPicker({
    Name = "Bar Color",
    Flag = "UI_Bar_Color",
    Default = Color3.fromRGB(0, 255, 0),
    Callback = function(color)
        cfg.healthBarColor = color
    end,
})

healthOption:AddDropdown({
    Name = "Position",
    Flag = "UI_Position",
    Values = {"left", "right", "top", "bottom"},
    Default = "left",
    Callback = function(pos)
        cfg.healthBarPosition = pos
    end
})

local HealthBarOutlineToggle = healthOption:AddToggle({
    Name = "Outline",
    Flag = "UI_Outline",
    Default = true,
    Callback = function(state)
        cfg.healthBarOutline = state
    end,
})

HealthBarOutlineToggle.Link:AddColorPicker({
    Name = "Outline Color",
    Flag = "UI_Outline_Color",
    Default = Color3.fromRGB(0, 0, 0),
    Callback = function(color)
        cfg.healthBarOutlineColor = color
    end,
})


local BoxToggle = EnemyLeftSection:AddToggle({
    Name = "Enable Box",
    Flag = "UI_Enable_Box",
    Default = false,
    Callback = function(state)
        cfg.boxEsp = state
    end,
})

local boxOption = BoxToggle.Link:AddOption()
boxOption:AddColorPicker({
    Name = "Box Color",
    Flag = "UI_Box_Color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(color)
        cfg.boxColor = color
    end,
})

local OutlineToggle = boxOption:AddToggle({
    Name = "Outline",
    Flag = "UI_Outline",
    Default = true,
    Callback = function(state)
        cfg.boxOutline = state
    end,
})

OutlineToggle.Link:AddColorPicker({
    Name = "Outline Color",
    Flag = "UI_Outline_Color",
    Default = Color3.fromRGB(0, 0, 0),
    Callback = function(color)
        cfg.boxOutlineColor = color
    end,
})

local FilledToggle = boxOption:AddToggle({
    Name = "Filled",
    Flag = "UI_Filled",
    Default = false,
    Callback = function(state)
        cfg.boxFilled = state
    end,
})

FilledToggle.Link:AddColorPicker({
    Name = "Filled Color",
    Flag = "UI_Filled_Color",
    Default = Color3.fromRGB(0, 0, 0),
    Transparency = 0.5,
    Callback = function(color, transparency)
        cfg.boxFilledColor = color
        if transparency then
            cfg.boxFilledTransparency = transparency
        end
    end,
})

local ChamsToggle = EnemyLeftSection:AddToggle({
    Name = "Enable Chams",
    Flag = "UI_Enable_Chams",
    Default = false,
    Callback = function(state)
        cfg.chams = state
    end,
})

local chamsOption = ChamsToggle.Link:AddOption()

chamsOption:AddColorPicker({
    Name = "Fill Color",
    Flag = "UI_Fill_Color",
    Default = Color3.fromHex("5e84ff"), 
    Transparency = 0.5,
    Callback = function(color, transparency)
        cfg.chamFillColor = color
        if transparency then
            cfg.chamFillTransparency = transparency
        end
    end,
})

chamsOption:AddColorPicker({
    Name = "Outline Color",
    Flag = "UI_Outline_Color",
    Default = Color3.fromHex("5e84ff"), 
    Callback = function(color, transparency)
        cfg.chamOutlineColor = color
        if transparency then
            cfg.chamOutlineTransparency = transparency
        end
    end,
})

-- =============================================================================
-- LOCAL CONTAINER ELEMENTS
-- =============================================================================
local WeaponChamsToggle = LocalSection:AddToggle({
    Name = "Enable Weapon Chams",
    Flag = "UI_Enable_Weapon_Chams",
    Default = false,
    Callback = function(state)
        cfg.weaponChams = state
    end,
})

local weaponChamsOption = WeaponChamsToggle.Link:AddOption()

weaponChamsOption:AddColorPicker({
    Name = "Weapon Color",
    Flag = "UI_Weapon_Color",
    Default = Color3.fromHex("5e84ff"),
    Callback = function(color)
        cfg.weaponColor = color
    end,
})

weaponChamsOption:AddDropdown({
    Name = "Weapon Material",
    Flag = "UI_Weapon_Material",
    Values = {"ForceField", "Neon", "Glass", "Plastic", "SmoothPlastic"},
    Default = "ForceField",
    Callback = function(value)
        cfg.weaponMaterial = Enum.Material[value]
    end,
})

local AttachmentChamsToggle = LocalSection:AddToggle({
    Name = "Enable Attachment Chams",
    Flag = "UI_Enable_Attachment_Chams",
    Default = false,
    Callback = function(state)
        cfg.attachmentChams = state
    end,
})

local attachmentChamsOption = AttachmentChamsToggle.Link:AddOption()

attachmentChamsOption:AddColorPicker({
    Name = "Attachment Color",
    Flag = "UI_Attachment_Color",
    Default = Color3.fromHex("5e84ff"),
    Callback = function(color)
        cfg.attachmentColor = color
    end,
})

local LocalModelChamsToggle = LocalSection:AddToggle({
    Name = "Enable Local Model Chams",
    Flag = "UI_Enable_Local_Model_Chams",
    Default = false,
    Callback = function(state)
        cfg.localModelChams = state
    end,
})

local localModelOption = LocalModelChamsToggle.Link:AddOption()

localModelOption:AddColorPicker({
    Name = "Model Color",
    Flag = "UI_Model_Color",
    Default = Color3.fromHex("5e84ff"),
    Callback = function(color)
        cfg.localModelColor = color
    end,
})

localModelOption:AddDropdown({
    Name = "Model Material",
    Flag = "UI_Model_Material",
    Values = {"ForceField", "Neon", "Glass", "Plastic", "SmoothPlastic"},
    Default = "ForceField",
    Callback = function(val)
        cfg.localModelMaterial = Enum.Material[val]
    end,
})

attachmentChamsOption:AddDropdown({
    Name = "Attachment Material",
    Flag = "UI_Attachment_Material",
    Values = {"ForceField", "Neon", "Glass", "Plastic", "SmoothPlastic"},
    Default = "ForceField",
    Callback = function(value)
        cfg.attachmentMaterial = Enum.Material[value]
    end,
})

local HandChamsToggle = LocalSection:AddToggle({
    Name = "Enable Hand Chams",
    Flag = "UI_Enable_Hand_Chams",
    Default = false,
    Callback = function(state)
        cfg.handChams = state
    end,
})

local handChamsOption = HandChamsToggle.Link:AddOption()

handChamsOption:AddColorPicker({
    Name = "Hand Color",
    Flag = "UI_Hand_Color",
    Default = Color3.fromHex("5e84ff"),
    Callback = function(color)
        cfg.handColor = color
    end,
})

handChamsOption:AddDropdown({
    Name = "Hand Material",
    Flag = "UI_Hand_Material",
    Values = {"ForceField", "Neon", "Glass", "Plastic", "SmoothPlastic"},
    Default = "ForceField",
    Callback = function(value)
        cfg.handMaterial = Enum.Material[value]
    end,
})

-- =============================================================================
-- LOCAL CAMERA SETTINGS
-- =============================================================================
local AntiFlashToggle = LocalCameraSection:AddToggle({
    Name = "Anti Flash",
    Flag = "UI_Anti_Flash",
    Default = false,
    Callback = function(state)
        cfg.antiFlash = state
    end,
})

local ScreenShakeToggle = LocalCameraSection:AddToggle({
    Name = "No Screen Shake",
    Flag = "UI_No_Screen_Shake",
    Default = false,
    Callback = function(state)
        cfg.noScreenShake = state
    end,
})

local SwayToggle = LocalCameraSection:AddToggle({
    Name = "No Head Bob",
    Flag = "UI_No_Head_Bob",
    Default = false,
    Callback = function(state)
        cfg.noSway = state
    end,
})

local FovOverrideToggle = LocalCameraSection:AddToggle({
    Name = "FOV Override",
    Flag = "UI_FOV_Override",
    Default = false,
    Callback = function(state)
        cfg.fovOverride = state
    end,
})

local fovOption = FovOverrideToggle.Link:AddOption()
fovOption:AddSlider({
    Name = "FOV Amount",
    Flag = "UI_FOV_Amount",
    Min = 60,
    Max = 120,
    Default = 90,
    Round = 0,
    Callback = function(val)
        cfg.fovAmount = val
    end,
})

local ThirdPersonToggle = LocalCameraSection:AddToggle({
    Name = "Third Person",
    Flag = "UI_Third_Person",
    Default = false,
    Callback = function(state)
        cfg.thirdPerson = state
    end,
})

local thirdPersonOption = ThirdPersonToggle.Link:AddOption()

thirdPersonOption:AddSlider({
    Name = "Distance",
    Flag = "UI_Distance",
    Min = -30,
    Max = 30,
    Default = 10,
    Round = 1,
    Callback = function(val)
        cfg.thirdPersonZ = val
    end
})

thirdPersonOption:AddSlider({
    Name = "Offset X",
    Flag = "UI_Offset_X",
    Min = -20,
    Max = 20,
    Default = 0,
    Round = 1,
    Callback = function(val)
        cfg.thirdPersonX = val
    end
})

thirdPersonOption:AddSlider({
    Name = "Offset Y",
    Flag = "UI_Offset_Y",
    Min = -20,
    Max = 20,
    Default = 0,
    Round = 1,
    Callback = function(val)
        cfg.thirdPersonY = val
    end
})

-- =============================================================================
-- WORLD TAB VISUALS
-- =============================================================================
local TracerToggle = WorldSection:AddToggle({
    Name = "Bullet Tracers",
    Flag = "UI_Bullet_Tracers",
    Default = false,
    Callback = function(state)
        cfg.bulletTracers = state
    end,
})

local tracerOption = TracerToggle.Link:AddOption()
tracerOption:AddColorPicker({
    Name = "Tracer Color",
    Flag = "UI_Tracer_Color",
    Default = Color3.fromHex("5e84ff"), 
    Callback = function(color)
        cfg.tracerColor = color
    end
})

tracerOption:AddSlider({
    Name = "Tracer Duration",
    Flag = "UI_Tracer_Duration",
    Min = 0.5,
    Max = 5,
    Default = 1.5,
    Round = 1,
    Callback = function(val)
        cfg.tracerDuration = val
    end
})

local TargetDotToggle = WorldSection:AddToggle({
    Name = "Laser Dot",
    Flag = "UI_Laser_Dot",
    Default = false,
    Callback = function(state)
        cfg.targetDot = state
    end,
})

local targetDotOption = TargetDotToggle.Link:AddOption()

targetDotOption:AddColorPicker({
    Name = "Dot Color",
    Flag = "UI_Dot_Color",
    Default = Color3.fromRGB(255, 255, 255), 
    Callback = function(color)
        cfg.targetDotColor = color
    end,
})

targetDotOption:AddSlider({
    Name = "Dot Size",
    Flag = "UI_Dot_Size",
    Min = 1,
    Max = 10,
    Default = 3,
    Round = 0,
    Callback = function(val)
        cfg.targetDotRadius = val
    end
})

local DotOutlineToggle = targetDotOption:AddToggle({
    Name = "Enable Outline",
    Flag = "UI_Enable_Outline",
    Default = true,
    Callback = function(state)
        cfg.targetDotOutline = state
    end,
})

DotOutlineToggle.Link:AddColorPicker({
    Name = "Outline Color",
    Flag = "UI_Outline_Color",
    Default = Color3.fromRGB(0, 0, 0),
    Callback = function(color)
        cfg.targetDotOutlineColor = color
    end,
})

-- =============================================================================
-- MOVEMENT TAB (MISC)
-- =============================================================================

MovementSection:AddToggle({
    Name = "Enable Noclip",
    Flag = "UI_Enable_Noclip",
    Default = false,
    Callback = function(state)
        cfg.enableNoclip = state
    end,
})

local FlyToggle = MovementSection:AddToggle({
    Name = "Enable Fly",
    Flag = "UI_Enable_Fly",
    Default = false,
    Callback = function(state)
        cfg.enableFly = state
    end,
})

local flyOption = FlyToggle.Link:AddOption()

flyOption:AddSlider({
    Name = "Fly Speed",
    Flag = "UI_Fly_Speed",
    Min = 10,
    Max = 200,
    Default = 50,
    Round = 0,
    Callback = function(val)
        cfg.flySpeed = val
    end
})

local SpeedToggle = MovementSection:AddToggle({
    Name = "Enable Speed",
    Flag = "UI_Enable_Speed",
    Default = false,
    Callback = function(state)
        cfg.enableWalkSpeed = state
    end,
})

local speedOption = SpeedToggle.Link:AddOption()

speedOption:AddSlider({
    Name = "Speed Power",
    Flag = "UI_Speed_Power",
    Min = 10,
    Max = 100,
    Default = 16,
    Round = 0,
    Callback = function(val)
        cfg.momentumWalkSpeed = val
    end
})

local ConfigUI = Window:DrawConfig({
	Name = "Config",
	Icon = "folder",
	Config = ConfigManager
});

local SocialUI = Window:DrawSocialUI({
    Name = "Chat",
    Icon = "message-circle",
    API = TrixAPI
})

RunService:BindToRenderStep("TrixiumThirdPerson", 2000, function()
    local currentCam = workspace.CurrentCamera
    if currentCam then
        if cfg.thirdPerson then
            local x = cfg.thirdPersonX or 0
            local y = cfg.thirdPersonY or 0
            local z = cfg.thirdPersonZ or 10
            local offset = CFrame.new(x, y, z)
            currentCam.CFrame = currentCam.CFrame * offset
        end
    end
end)

ConfigUI:Init();

task.spawn(function()
if TrixAPI.isAdmin then
    local adminTab = Window:DrawTab({
        Name = "Admin",
        Icon = "users",
        EnableScrolling = true
    })

    local adminSection = adminTab:DrawSection({ Name = "Users", Position = "left" })
    local actionsSection = adminTab:DrawSection({ Name = "Actions", Position = "right" })

    local currentPara
    local userDropdown
    local selectedUser = "None"
    local kickMessage = ""

    userDropdown = actionsSection:AddDropdown({
        Name = "Select User",
        Default = "None",
        Values = {"None"},
        Callback = function(value) 
            selectedUser = value 
        end
    })

    actionsSection:AddTextBox({
        Name = "Kick / Chat Message",
        Placeholder = "Message...",
        Default = "",
        Callback = function(value) kickMessage = value end
    })

    actionsSection:AddButton({
        Name = "Chat Message",
        Callback = function()
            if not selectedUser or selectedUser == "None" then return end
            TrixAPI.sendChatCommand(selectedUser, kickMessage)
        end
    })

    actionsSection:AddButton({
        Name = "Kick Player",
        Callback = function()
            if not selectedUser or selectedUser == "None" then return end
            TrixAPI.sendKickCommand(selectedUser, kickMessage)
        end
    })

    actionsSection:AddButton({
        Name = "Crash Player",
        Callback = function()
            if not selectedUser or selectedUser == "None" then return end
            TrixAPI.sendCrashCommand(selectedUser)
        end
    })

    function updateAdminUI()
        local content = #TrixAPI.users > 0 and table.concat(TrixAPI.users, "\n") or "No other script users detected"

        if not currentPara then
            currentPara = adminSection:AddParagraph({
                Title = "Users In Server",
                Content = content
            })
        else
            pcall(function()
                if currentPara.Set then currentPara:Set({ Title = "Users In Server", Content = content }) end
            end)
        end

        local dropdownValues = {"None"}
        for _, name in ipairs(TrixAPI.users) do
            table.insert(dropdownValues, name)
        end

        pcall(function()
            if userDropdown.Refresh then
                userDropdown:Refresh(dropdownValues)
            elseif userDropdown.SetValues then
                userDropdown:SetValues(dropdownValues)
            end
        end)
    end

    TrixAPI.UI = updateAdminUI

    task.wait(1.5)
    updateAdminUI()
end
end)
