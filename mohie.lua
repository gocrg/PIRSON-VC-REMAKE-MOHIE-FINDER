-- PRISON VC MOHIE TRACKER
-- By dabbingman137 | Discord: dabbingman137

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

-- CONFIGURATION (EDIT THESE)
local CONFIG = {
    GITHUB = {
        REPO = "https://api.github.com/repos/gocrg/PIRSON-VC-REMAKE-MOHIE-FINDER/contents/mohie.json",
        TOKEN = "YOUR_GITHUB_TOKEN_HERE", -- Keep this secret!
        BRANCH = "main"
    },
    TARGET_ID = 1067583, -- Mohie's user ID
    UPDATE_INTERVAL = 60, -- Seconds between checks
    NOTIFICATION = {
        DURATION = 15, -- Seconds to show notifications
        PROXIMITY_ALERT_DISTANCE = 50 -- Studs
    },
    COLORS = {
        PRIMARY = Color3.fromRGB(255, 105, 180), -- Pink
        SECONDARY = Color3.fromRGB(175, 75, 255) -- Purple
    }
}

-- NOTIFICATION SYSTEM
local Notification = {
    Active = false,
    Gui = nil,
    Tween = nil,
    ProximityAlertActive = false
}

function Notification:Create()
    if self.Gui then self.Gui:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MohieTrackerNotification"
    screenGui.Parent = CoreGui
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.ResetOnSpawn = false

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 400, 0, 220)
    mainFrame.Position = UDim2.new(1, 10, 0.7, 0)
    mainFrame.AnchorPoint = Vector2.new(1, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    mainFrame.BackgroundTransparency = 0.25
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui

    -- Gradient background
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, CONFIG.COLORS.PRIMARY),
        ColorSequenceKeypoint.new(1, CONFIG.COLORS.SECONDARY)
    })
    gradient.Transparency = NumberSequence.new(0.7)
    gradient.Rotation = 90
    gradient.Parent = mainFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 14)
    corner.Parent = mainFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.new(1, 1, 1)
    stroke.Transparency = 0.8
    stroke.Thickness = 1
    stroke.Parent = mainFrame

    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 30)
    titleBar.BackgroundTransparency = 1
    titleBar.Parent = mainFrame

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(0.8, 0, 1, 0)
    title.Position = UDim2.new(0.05, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "MOHIE DETECTED ⚡"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar

    local timeLabel = Instance.new("TextLabel")
    timeLabel.Name = "TimeLabel"
    timeLabel.Size = UDim2.new(0.25, 0, 1, 0)
    timeLabel.Position = UDim2.new(0.7, 0, 0, 0)
    timeLabel.BackgroundTransparency = 1
    timeLabel.Text = os.date("%H:%M")
    timeLabel.TextColor3 = Color3.new(1, 1, 1)
    timeLabel.Font = Enum.Font.Gotham
    timeLabel.TextSize = 14
    timeLabel.TextXAlignment = Enum.TextXAlignment.Right
    timeLabel.Parent = titleBar

    -- Content area
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "ScrollFrame"
    scrollFrame.Size = UDim2.new(0.95, 0, 0, 150)
    scrollFrame.Position = UDim2.new(0.025, 0, 0.15, 0)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.ScrollBarThickness = 4
    scrollFrame.ScrollBarImageColor3 = Color3.new(1, 1, 1)
    scrollFrame.ScrollBarImageTransparency = 0.7
    scrollFrame.Parent = mainFrame

    local content = Instance.new("TextLabel")
    content.Name = "Content"
    content.Size = UDim2.new(1, 0, 0, 0)
    content.AutomaticSize = Enum.AutomaticSize.Y
    content.BackgroundTransparency = 1
    content.Text = "Loading details..."
    content.TextColor3 = Color3.new(1, 1, 1)
    content.Font = Enum.Font.Gotham
    content.TextSize = 14
    content.TextWrapped = true
    content.TextXAlignment = Enum.TextXAlignment.Left
    content.TextYAlignment = Enum.TextYAlignment.Top
    content.Parent = scrollFrame

    -- Proximity alert
    local proximityAlert = Instance.new("Frame")
    proximityAlert.Name = "ProximityAlert"
    proximityAlert.Size = UDim2.new(0, 0, 0, 4)
    proximityAlert.Position = UDim2.new(0, 0, 1, -4)
    proximityAlert.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    proximityAlert.BorderSizePixel = 0
    proximityAlert.Visible = false
    proximityAlert.Parent = mainFrame

    -- Controls
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0.3, 0, 0, 30)
    closeBtn.Position = UDim2.new(0.35, 0, 1, -35)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.BackgroundTransparency = 0.85
    closeBtn.TextColor3 = Color3.new(0, 0, 0)
    closeBtn.Text = "DISMISS"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.Parent = mainFrame

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = closeBtn

    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = Color3.new(0, 0, 0)
    btnStroke.Thickness = 1
    btnStroke.Parent = closeBtn

    -- Animation setup
    closeBtn.MouseButton1Click:Connect(function()
        self:Hide()
    end)

    self.Gui = screenGui
    return self
end

function Notification:Show(playerData, distance)
    if not self.Gui then self:Create() end
    
    local mainFrame = self.Gui.MainFrame
    local scrollFrame = mainFrame.ScrollFrame
    local content = scrollFrame.Content
    local proximityAlert = mainFrame.ProximityAlert
    
    -- Update content
    content.Text = string.format(
        "%s (@%s)\n\n"..
        "UserID: %d\n"..
        "Account Age: %d days\n"..
        "Current Game: Prison VC\n"..
        "Server: %s\n"..
        "Distance: %s studs\n\n"..
        "%s",
        playerData.DisplayName,
        playerData.Name,
        playerData.UserId,
        math.floor((os.time() - playerData.AccountAge)/86400),
        game.JobId,
        distance and tostring(math.floor(distance)) or "N/A",
        os.date("%Y-%m-%d %H:%M:%S")
    )
    
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, content.TextBounds.Y + 10)
    mainFrame.TimeLabel.Text = os.date("%H:%M")
    
    -- Update proximity alert
    if distance and distance <= CONFIG.NOTIFICATION.PROXIMITY_ALERT_DISTANCE then
        self.ProximityAlertActive = true
        proximityAlert.Visible = true
        
        local alertTween = TweenService:Create(
            proximityAlert,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true),
            {Size = UDim2.new(1, 0, 0, 4)}
        )
        alertTween:Play()
    else
        self.ProximityAlertActive = false
        proximityAlert.Visible = false
    end
    
    -- Slide-in animation
    if self.Tween then self.Tween:Cancel() end
    mainFrame.Position = UDim2.new(1, 10, 0.7, 0)
    self.Gui.Enabled = true
    
    self.Tween = TweenService:Create(
        mainFrame,
        TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(1, -20, 0.7, 0)}
    )
    self.Tween:Play()
    
    self.Active = true
    
    -- Auto-hide after duration
    task.delay(CONFIG.NOTIFICATION.DURATION, function()
        if self.Active then
            self:Hide()
        end
    end)
end

function Notification:Hide()
    if not self.Gui or not self.Active then return end
    
    if self.Tween then self.Tween:Cancel() end
    self.Tween = TweenService:Create(
        self.Gui.MainFrame,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad),
        {Position = UDim2.new(1, 10, 0.7, 0)}
    )
    self.Tween:Play()
    
    self.Tween.Completed:Connect(function()
        self.Gui.Enabled = false
        self.Active = false
        self.ProximityAlertActive = false
    end)
end

-- DATA MANAGER (GitHub Integration)
local DataManager = {
    cache = {
        version = "2.1",
        trackedPlayers = {},
        sessions = {},
        stats = {
            totalDetections = 0,
            firstDetection = nil,
            lastDetection = nil,
            closestEncounter = nil
        }
    },
    sha = nil
}

function DataManager:RequestGitHub(method, body)
    local success, response = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(
            CONFIG.GITHUB.REPO,
            {
                Method = method,
                Headers = {
                    ["Authorization"] = "token " .. CONFIG.GITHUB.TOKEN,
                    ["Accept"] = "application/vnd.github.v3+json",
                    ["Content-Type"] = "application/json"
                },
                Body = body and HttpService:JSONEncode(body) or nil
            }
        ))
    end)
    return success and response or nil
end

function DataManager:Load()
    local response = self:RequestGitHub("GET")
    if not response then return false end
    
    if response.content then
        self.cache = HttpService:JSONDecode(HttpService:Base64Decode(response.content))
        self.sha = response.sha
    end
    
    -- Initialize if empty
    if not self.cache.version then
        self.cache = {
            version = "2.1",
            trackedPlayers = {},
            sessions = {},
            stats = {
                totalDetections = 0,
                firstDetection = nil,
                lastDetection = nil,
                closestEncounter = nil
            }
        }
    end
    
    return true
end

function DataManager:Save()
    self.cache.lastUpdated = os.date("%Y-%m-%d %H:%M:%S")
    
    local response = self:RequestGitHub("PUT", {
        message = "Prison VC Tracker Update - " .. os.date(),
        content = HttpService:Base64Encode(HttpService:JSONEncode(self.cache)),
        branch = CONFIG.GITHUB.BRANCH,
        sha = self.sha
    })
    
    if response then
        self.sha = response.sha
        return true
    end
    return false
end

function DataManager:AddSession(player, distance)
    local newSession = {
        timestamp = os.time(),
        gameId = game.PlaceId,
        serverId = game.JobId,
        player = {
            userId = player.UserId,
            name = player.Name,
            displayName = player.DisplayName,
            accountAgeDays = math.floor((os.time() - player.AccountAge)/86400)
        },
        location = {
            position = distance and tostring(distance) or nil,
            isProximity = distance and distance <= CONFIG.NOTIFICATION.PROXIMITY_ALERT_DISTANCE
        }
    }
    
    table.insert(self.cache.sessions, newSession)
    
    -- Update stats
    self.cache.stats.totalDetections += 1
    self.cache.stats.lastDetection = os.date("%Y-%m-%d %H:%M:%S")
    
    if not self.cache.stats.firstDetection then
        self.cache.stats.firstDetection = self.cache.stats.lastDetection
    end
    
    if distance and (not self.cache.stats.closestEncounter or distance < tonumber(self.cache.stats.closestEncounter.distance)) then
        self.cache.stats.closestEncounter = {
            distance = tostring(distance),
            timestamp = self.cache.stats.lastDetection,
            serverId = game.JobId
        }
    end
    
    self:Save()
end

-- PROXIMITY SYSTEM
local function GetPlayerDistance(targetUserId)
    local localPlayer = Players.LocalPlayer
    local targetPlayer = Players:GetPlayerByUserId(targetUserId)
    
    if not localPlayer.Character or not targetPlayer or not targetPlayer.Character then
        return nil
    end
    
    local humanoidRootPart1 = localPlayer.Character:FindFirstChild("HumanoidRootPart")
    local humanoidRootPart2 = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if humanoidRootPart1 and humanoidRootPart2 then
        return (humanoidRootPart1.Position - humanoidRootPart2.Position).Magnitude
    end
    
    return nil
end

-- MAIN TRACKER
local function StartTracker()
    -- Initialize systems
    Notification:Create()
    if not DataManager:Load() then
        warn("Failed to load data from GitHub")
        DataManager.cache = {
            version = "",
            trackedPlayers = {},
            sessions = {},
            stats = {
                totalDetections = 0,
                firstDetection = nil,
                lastDetection = nil,
                closestEncounter = nil
            }
        }
    end

    print([[
    ====================================
    PRISON VC MOHIE TRACKER
    Target UserID: ]] .. CONFIG.TARGET_ID .. [[
    Made By dabbingman137
    Discord: dabbingman137
    ====================================
    ]])

    while task.wait(CONFIG.UPDATE_INTERVAL) do
        local targetPlayer = Players:GetPlayerByUserId(CONFIG.TARGET_ID)
        
        if targetPlayer then
            -- Calculate distance if in same server
            local distance = GetPlayerDistance(CONFIG.TARGET_ID)
            
            -- Add to history
            DataManager:AddSession(targetPlayer, distance)
            
            -- Show notification
            Notification:Show({
                UserId = targetPlayer.UserId,
                Name = targetPlayer.Name,
                DisplayName = targetPlayer.DisplayName,
                AccountAge = targetPlayer.AccountAge
            }, distance)
            
            -- Console output
            print("\n" .. string.rep("=", 50))
            print("MOHIE DETECTED IN PRISON VC! 🔥")
            print("Player:", targetPlayer.DisplayName .. " (@" .. targetPlayer.Name .. ")")
            print("UserID:", targetPlayer.UserId)
            if distance then
                print("Distance:", math.floor(distance) .. " studs" .. 
                      (distance <= CONFIG.NOTIFICATION.PROXIMITY_ALERT_DISTANCE and " (CLOSE!)" or ""))
            end
            print("Server ID:", game.JobId)
            print("Time:", os.date("%Y-%m-%d %H:%M:%S"))
            print("\n Tracking Stats:")
            print("Total Detections:", DataManager.cache.stats.totalDetections)
            print("First Detection:", DataManager.cache.stats.firstDetection or "Never")
            if DataManager.cache.stats.closestEncounter then
                print("Closest Encounter:", 
                    DataManager.cache.stats.closestEncounter.distance .. " studs on " .. 
                    DataManager.cache.stats.closestEncounter.timestamp)
            end
            print("\nMade By dabbingman137")
            print("Discord: dabbingman137")
            print(string.rep("=", 50) .. "\n")
        end
    end
end

-- Error handling
local function SafeStart()
    local success, err = pcall(StartTracker)
    if not success then
        warn("Tracker error:", err)
        -- Attempt final save
        pcall(DataManager.Save, DataManager)
    end
end

-- Start the tracker
coroutine.wrap(SafeStart)()