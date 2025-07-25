-- Prison VC Mohie Tracker
-- By dabbingman137 | Discord: dabbingman137

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Configuration (EDIT THESE VALUES)
local CONFIG = {
    GITHUB = {
        REPO = "https://api.github.com/repos/gocrg/PIRSON-VC-REMAKE-MOHIE-FINDER/contents/mohie.json",
        TOKEN = "YOUR_GITHUB_TOKEN_HERE", -- Replace with your token
        BRANCH = "main"
    },
    TARGET_ID = 1067583, -- Mohie's user ID
    UPDATE_INTERVAL = 60, -- Seconds between checks
    MAX_RETRIES = 3 -- Retry failed requests
}

-- Secure Data Manager
local DataManager = {
    cache = {
        version = "2.0",
        lastUpdated = nil,
        sessions = {},
        stats = {
            totalDetections = 0,
            firstDetection = nil,
            lastDetection = nil
        }
    },
    sha = nil
}

function DataManager:RequestGitHub(method, extraPath, body)
    local url = CONFIG.GITHUB.REPO
    if extraPath then url = url .. extraPath end
    
    for attempt = 1, CONFIG.MAX_RETRIES do
        local success, response = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(url, {
                Method = method,
                Headers = {
                    ["Authorization"] = "token " .. CONFIG.GITHUB.TOKEN,
                    ["Accept"] = "application/vnd.github.v3+json",
                    ["Content-Type"] = "application/json"
                },
                Body = body and HttpService:JSONEncode(body) or nil
            }))
        end)
        
        if success then return response end
        warn(("Attempt %d failed: %s"):format(attempt, response))
        task.wait(2 ^ attempt) -- Exponential backoff
    end
    return nil
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
            version = "2.0",
            sessions = {},
            stats = {
                totalDetections = 0,
                firstDetection = nil,
                lastDetection = nil
            }
        }
    end
    
    return true
end

function DataManager:Save()
    self.cache.lastUpdated = os.date("%Y-%m-%d %H:%M:%S")
    
    local response = self:RequestGitHub("PUT", nil, {
        message = "Prison VC Tracker Update",
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

function DataManager:AddSession(player)
    local newSession = {
        timestamp = os.time(),
        gameId = game.PlaceId,
        serverId = game.JobId,
        player = {
            userId = player.UserId,
            name = player.Name,
            displayName = player.DisplayName,
            accountAgeDays = math.floor((os.time() - player.AccountAge) / 86400)
        }
    }
    
    table.insert(self.cache.sessions, newSession)
    
    -- Update stats
    self.cache.stats.totalDetections = (self.cache.stats.totalDetections or 0) + 1
    self.cache.stats.lastDetection = os.date("%Y-%m-%d %H:%M:%S")
    if not self.cache.stats.firstDetection then
        self.cache.stats.firstDetection = self.cache.stats.lastDetection
    end
    
    self:Save()
end

-- Main Tracker
local function StartTracker()
    -- Initialize data
    if not DataManager:Load() then
        warn("Failed to initialize data manager")
        return
    end

    print([[
    Prison VC Mohie Tracker
    Tracking UserID: ]] .. CONFIG.TARGET_ID .. [[
    
    Made By dabbingman137
    Discord: dabbingman137
    ]])

    while true do
        local targetPlayer = Players:GetPlayerByUserId(CONFIG.TARGET_ID)
        
        if targetPlayer then
            print("\n[!] Target detected in server!")
            print(("Name: %s (@%s)"):format(targetPlayer.DisplayName, targetPlayer.Name))
            print(("Server: %s"):format(game.JobId))
            print(("Time: %s"):format(os.date("%Y-%m-%d %H:%M:%S")))
            
            DataManager:AddSession(targetPlayer)
            
            -- Print recent stats
            local stats = DataManager.cache.stats
            print("\nTracking Statistics:")
            print(("Total detections: %d"):format(stats.totalDetections))
            print(("First seen: %s"):format(stats.firstDetection or "Never"))
            print(("Last seen before: %s"):format(stats.lastDetection or "Never"))
            print("\n" .. string.rep("-", 40))
        end
        
        task.wait(CONFIG.UPDATE_INTERVAL)
    end
end

-- Error handling wrapper
local function SafeStart()
    local success, err = pcall(StartTracker)
    if not success then
        warn("Tracker crashed:", err)
        -- Attempt to save data before exiting
        pcall(DataManager.Save, DataManager)
    end
end

-- Start the tracker
coroutine.wrap(SafeStart)()
