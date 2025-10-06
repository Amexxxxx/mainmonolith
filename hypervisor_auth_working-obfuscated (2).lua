--[[
    HyperVisor - Working Authentication
    
    Fixed version that properly handles server responses.
]]

-- Services
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

-- Configuration
local CONFIG = {
    serverUrl = "https://monolith-sand.vercel.app/",
    discordInvite = "SHbhWRkveA",
    keyFile = "Monolith.txt", -- File to save the authentication key
    scriptName = "Monolith"
}

-- HTTP request function with multi-executor support
local function makeRequest(url, method, headers, body)
    method = method or "GET"
    headers = headers or {}
    
    local requestData = {
        Url = url,
        Method = method,
        Headers = headers
    }
    
    if body then
        requestData.Body = body
    end
    
    -- Try different HTTP request methods based on executor
    if syn and syn.request then
        return syn.request(requestData)
    elseif request then
        return request(requestData)
    elseif http_request then
        return http_request(requestData)
    elseif fluxus and fluxus.request then
        return fluxus.request(requestData)
    else
        error("❌ No HTTP request method available. This executor doesn't support HTTP requests.")
    end
end

-- Function to save authentication key
local function saveKey(key)
    if writefile then
            writefile(CONFIG.keyFile, key)
    end
end

-- Function to load saved authentication key
local function loadKey()
    if readfile and isfile and isfile(CONFIG.keyFile) then
            return readfile(CONFIG.keyFile)
        end
        return nil
end

-- Function to delete saved key
local function deleteKey()
    if delfile and isfile and isfile(CONFIG.keyFile) then
            delfile(CONFIG.keyFile)
        end
    end

-- Function to get executor information
local function getExecutorInfo()
    local player = Players.LocalPlayer
    local username = player.Name
    local userId = tostring(player.UserId)
    
    -- Try to get executor name
    local executorName = "Unknown"
    
    if syn then
        executorName = "Synapse"
    elseif KRNL_LOADED then
        executorName = "KRNL"
    elseif getexecutorname then
        executorName = getexecutorname() or "Unknown"
    elseif identifyexecutor then
        executorName = identifyexecutor() or "Unknown"
    end
    
    -- Get current game ID
    local gameId = game.PlaceId
    
    return executorName .. "_" .. username .. "_" .. userId .. "_" .. gameId
end

-- Function to get current game ID
local function getCurrentGameId()
    return tostring(game.PlaceId)
end

-- Function to check if script exists for current game
local function checkGameScript(authKey)
    local gameId = getCurrentGameId()
    local executor = getExecutorInfo():match("^[^_]+")
    
    local url = CONFIG.serverUrl .. "/api/scripts/get-by-game?gameId=" .. gameId .. "&executor=" .. executor .. "&key=" .. authKey
    
    local success, response = pcall(function()
        return makeRequest(url, "GET")
    end)
    
    if not success then
        return false, "Failed to connect to server"
    end
    
    if response.StatusCode == 200 then
        local decodeSuccess, responseData = pcall(function()
            return HttpService:JSONDecode(response.Body)
        end)
        
        if not decodeSuccess then
            return false, "JSON decode error"
        end
        
        if responseData.success == true and responseData.script then
            return true, responseData.script
        else
            return false, responseData.error or "No script available for this game"
        end
    elseif response.StatusCode == 404 then
        return false, "No script available for this game"
    else
        return false, "Server error: " .. tostring(response.StatusCode)
    end
end

-- Function to execute script from URL
local function executeScript(scriptUrl)
    if not scriptUrl then
        return false, "No script URL provided"
    end
        
    local success, response = pcall(function()
        return makeRequest(scriptUrl, "GET")
        end)
        
    if not success then
        return false, "Failed to download script"
    end
    
    if response.StatusCode == 200 then
        local scriptContent = response.Body
        if scriptContent and scriptContent ~= "" then
            local executeSuccess, executeError = pcall(function()
                loadstring(scriptContent)()
        end)
        
            if executeSuccess then
                return true, "Script executed successfully"
            else
                return false, "Script execution failed: " .. tostring(executeError)
            end
        else
            return false, "Script content is empty"
        end
    else
        return false, "Failed to download script: " .. tostring(response.StatusCode)
    end
end

-- Server-based key validation function
local function validateKey(key)
    local executorInfo = getExecutorInfo()
    
    local success, isValid, responseData = pcall(function()
        local response = makeRequest(
            CONFIG.serverUrl .. "/api/auth/validate",
            "POST",
            {
                ["Content-Type"] = "application/json"
            },
            HttpService:JSONEncode({
                key = key,
                executor = executorInfo
            })
        )
        
        if response.StatusCode == 200 then
            local data = HttpService:JSONDecode(response.Body)
            
            if data.success then
                return true, data
            else
                return false, data
            end
        else
            local errorData
            pcall(function()
                errorData = HttpService:JSONDecode(response.Body)
            end)
            return false, errorData or { error = "Server error", code = "HTTP_" .. response.StatusCode }
        end
    end)
    
    if success then
        return isValid, responseData
    else
        return false, { error = "Connection failed", details = tostring(isValid) }
    end
end

-- Remove existing GUI
local existing = CoreGui:FindFirstChild("Monolith")
if existing then existing:Destroy() end

-- Create main GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Monolith"
ScreenGui.Parent = CoreGui

-- Main frame - sleek black design
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 400, 0, 450)
MainFrame.Position = UDim2.new(0.5, -200, 0.5, -225)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

-- Minimal rounded corners
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

-- Thin border
local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(40, 40, 40)
UIStroke.Thickness = 1
UIStroke.Parent = MainFrame

-- Header section - minimal black design
local HeaderFrame = Instance.new("Frame")
HeaderFrame.Size = UDim2.new(1, 0, 0, 80)
HeaderFrame.Position = UDim2.new(0, 0, 0, 0)
HeaderFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
HeaderFrame.BorderSizePixel = 0
HeaderFrame.Parent = MainFrame

-- Title - simple and clean
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -100, 0, 40)
Title.Position = UDim2.new(0, 30, 0, 20)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.Text = "Monolith"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 24
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = HeaderFrame

-- Subtle divider line
local Divider = Instance.new("Frame")
Divider.Size = UDim2.new(1, -60, 0, 1)
Divider.Position = UDim2.new(0, 30, 1, -1)
Divider.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Divider.BorderSizePixel = 0
Divider.Parent = HeaderFrame

-- Form container
local FormFrame = Instance.new("Frame")
FormFrame.Size = UDim2.new(1, -60, 1, -120)
FormFrame.Position = UDim2.new(0, 30, 0, 100)
FormFrame.BackgroundTransparency = 1
FormFrame.Parent = MainFrame

-- Key input label
local KeyLabel = Instance.new("TextLabel")
KeyLabel.Size = UDim2.new(1, 0, 0, 18)
KeyLabel.Position = UDim2.new(0, 0, 0, 0)
KeyLabel.BackgroundTransparency = 1
KeyLabel.Font = Enum.Font.Gotham
KeyLabel.Text = "Authentication Key"
KeyLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
KeyLabel.TextSize = 12
KeyLabel.TextXAlignment = Enum.TextXAlignment.Left
KeyLabel.Parent = FormFrame

-- Key input box - minimal black design
local KeyBox = Instance.new("TextBox")
KeyBox.Size = UDim2.new(1, 0, 0, 42)
KeyBox.Position = UDim2.new(0, 0, 0, 26)
KeyBox.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
KeyBox.BorderSizePixel = 0
KeyBox.Font = Enum.Font.Gotham
KeyBox.PlaceholderText = "Enter your key"
KeyBox.PlaceholderColor3 = Color3.fromRGB(80, 80, 80)
KeyBox.Text = ""
KeyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
KeyBox.TextSize = 14
KeyBox.TextWrapped = false
KeyBox.TextScaled = false
KeyBox.ClipsDescendants = true
KeyBox.TextXAlignment = Enum.TextXAlignment.Left
KeyBox.TextYAlignment = Enum.TextYAlignment.Center
KeyBox.MultiLine = false
KeyBox.ClearTextOnFocus = false
KeyBox.Parent = FormFrame

-- Ensure text stays bright when typing
KeyBox.Focused:Connect(function()
    KeyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
end)

KeyBox.FocusLost:Connect(function()
    if KeyBox.Text ~= "" then
        KeyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
end)

local KeyBoxCorner = Instance.new("UICorner")
KeyBoxCorner.CornerRadius = UDim.new(0, 6)
KeyBoxCorner.Parent = KeyBox

local KeyBoxStroke = Instance.new("UIStroke")
KeyBoxStroke.Color = Color3.fromRGB(40, 40, 40)
KeyBoxStroke.Thickness = 1
KeyBoxStroke.Parent = KeyBox

-- Key box padding
local KeyBoxPadding = Instance.new("UIPadding")
KeyBoxPadding.PaddingLeft = UDim.new(0, 14)
KeyBoxPadding.PaddingRight = UDim.new(0, 14)
KeyBoxPadding.Parent = KeyBox

-- Auto-fill saved key
local savedKey = loadKey()
if savedKey then
    KeyBox.Text = savedKey
    KeyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    KeyBoxStroke.Color = Color3.fromRGB(40, 40, 40)
end

-- Save key checkbox container
local SaveContainer = Instance.new("Frame")
SaveContainer.Size = UDim2.new(1, 0, 0, 28)
SaveContainer.Position = UDim2.new(0, 0, 0, 80)
SaveContainer.BackgroundTransparency = 1
SaveContainer.Parent = FormFrame

-- Save key checkbox - minimal design
local SaveCheckbox = Instance.new("TextButton")
SaveCheckbox.Size = UDim2.new(0, 18, 0, 18)
SaveCheckbox.Position = UDim2.new(0, 0, 0, 5)
SaveCheckbox.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
SaveCheckbox.BorderSizePixel = 0
SaveCheckbox.Text = ""
SaveCheckbox.Parent = SaveContainer

local SaveCheckboxCorner = Instance.new("UICorner")
SaveCheckboxCorner.CornerRadius = UDim.new(0, 4)
SaveCheckboxCorner.Parent = SaveCheckbox

local SaveCheckboxStroke = Instance.new("UIStroke")
SaveCheckboxStroke.Color = Color3.fromRGB(60, 60, 60)
SaveCheckboxStroke.Thickness = 1
SaveCheckboxStroke.Parent = SaveCheckbox

-- Checkbox check mark
local CheckMark = Instance.new("TextLabel")
CheckMark.Size = UDim2.new(1, 0, 1, 0)
CheckMark.Position = UDim2.new(0, 0, 0, -1)
CheckMark.BackgroundTransparency = 1
CheckMark.Font = Enum.Font.GothamBold
CheckMark.Text = "✓"
CheckMark.TextColor3 = Color3.fromRGB(255, 255, 255)
CheckMark.TextSize = 11
CheckMark.Visible = savedKey and true or false
CheckMark.Parent = SaveCheckbox

-- Save key label
local SaveLabel = Instance.new("TextLabel")
SaveLabel.Size = UDim2.new(1, -28, 1, 0)
SaveLabel.Position = UDim2.new(0, 28, 0, 0)
SaveLabel.BackgroundTransparency = 1
SaveLabel.Font = Enum.Font.Gotham
SaveLabel.Text = "Remember key"
SaveLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
SaveLabel.TextSize = 12
SaveLabel.TextXAlignment = Enum.TextXAlignment.Left
SaveLabel.Parent = SaveContainer

-- Checkbox functionality
local saveKeyEnabled = savedKey and true or false
SaveCheckbox.MouseButton1Click:Connect(function()
    saveKeyEnabled = not saveKeyEnabled
    CheckMark.Visible = saveKeyEnabled
    SaveCheckbox.BackgroundColor3 = saveKeyEnabled and Color3.fromRGB(70, 70, 70) or Color3.fromRGB(25, 25, 25)
    SaveCheckboxStroke.Color = saveKeyEnabled and Color3.fromRGB(100, 100, 100) or Color3.fromRGB(60, 60, 60)
end)

-- Delete saved key button (only show if key exists)
local DeleteKeyButton = nil
if savedKey then
    DeleteKeyButton = Instance.new("TextButton")
    DeleteKeyButton.Size = UDim2.new(0, 60, 0, 24)
    DeleteKeyButton.Position = UDim2.new(1, -62, 0, 2)
    DeleteKeyButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    DeleteKeyButton.BorderSizePixel = 0
    DeleteKeyButton.Font = Enum.Font.Gotham
    DeleteKeyButton.Text = "Clear"
    DeleteKeyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    DeleteKeyButton.TextSize = 11
    DeleteKeyButton.Parent = SaveContainer
    
    local DeleteCorner = Instance.new("UICorner")
    DeleteCorner.CornerRadius = UDim.new(0, 4)
    DeleteCorner.Parent = DeleteKeyButton
    
    -- Delete key functionality
    DeleteKeyButton.MouseButton1Click:Connect(function()
        deleteKey()
        KeyBox.Text = ""
        KeyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        KeyBoxStroke.Color = Color3.fromRGB(40, 40, 40)
        CheckMark.Visible = false
        saveKeyEnabled = false
        SaveCheckbox.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        SaveCheckboxStroke.Color = Color3.fromRGB(60, 60, 60)
        DeleteKeyButton:Destroy()
    end)
end

-- Status label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 18)
StatusLabel.Position = UDim2.new(0, 0, 0, 120)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Text = ""
StatusLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
StatusLabel.TextSize = 11
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = FormFrame

-- Login button - minimal black design
local LoginButton = Instance.new("TextButton")
LoginButton.Size = UDim2.new(1, 0, 0, 40)
LoginButton.Position = UDim2.new(0, 0, 0, 150)
LoginButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
LoginButton.BorderSizePixel = 0
LoginButton.Font = Enum.Font.GothamBold
LoginButton.Text = "Authenticate"
LoginButton.TextColor3 = Color3.fromRGB(255, 255, 255)
LoginButton.TextSize = 14
LoginButton.AutoButtonColor = false
LoginButton.Parent = FormFrame

local LoginCorner = Instance.new("UICorner")
LoginCorner.CornerRadius = UDim.new(0, 6)
LoginCorner.Parent = LoginButton

-- Discord button
local DiscordButton = Instance.new("TextButton")
DiscordButton.Size = UDim2.new(1, 0, 0, 36)
DiscordButton.Position = UDim2.new(0, 0, 0, 202)
DiscordButton.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
DiscordButton.BorderSizePixel = 0
DiscordButton.Font = Enum.Font.GothamBold
DiscordButton.Text = "Get Key"
DiscordButton.TextColor3 = Color3.fromRGB(255, 255, 255)
DiscordButton.TextSize = 13
DiscordButton.AutoButtonColor = false
DiscordButton.Parent = FormFrame

local DiscordCorner = Instance.new("UICorner")
DiscordCorner.CornerRadius = UDim.new(0, 6)
DiscordCorner.Parent = DiscordButton

-- Discord button click
DiscordButton.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard("https://discord.gg/" .. CONFIG.discordInvite)
        StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
        StatusLabel.Text = "📋 Discord invite copied to clipboard!"
    else
        StatusLabel.TextColor3 = Color3.fromRGB(88, 101, 242)
        StatusLabel.Text = "💬 Join Discord: discord.gg/" .. CONFIG.discordInvite
    end
end)

-- Close button - minimal design
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 28, 0, 28)
CloseButton.Position = UDim2.new(1, -38, 0, 26)
CloseButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
CloseButton.BorderSizePixel = 0
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Text = "×"
CloseButton.TextColor3 = Color3.fromRGB(140, 140, 140)
CloseButton.TextSize = 20
CloseButton.AutoButtonColor = false
CloseButton.Parent = HeaderFrame

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 4)
CloseCorner.Parent = CloseButton

-- Close button hover effect
CloseButton.MouseEnter:Connect(function()
    CloseButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
end)

CloseButton.MouseLeave:Connect(function()
    CloseButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    CloseButton.TextColor3 = Color3.fromRGB(140, 140, 140)
end)

-- Make frame draggable (only on header)
local dragging = false
local dragStart = nil
local startPos = nil

HeaderFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- Authentication function
local function authenticate()
    local authKey = KeyBox.Text
    
    -- Validation
    if authKey == "" then
        StatusLabel.TextColor3 = Color3.fromRGB(220, 80, 80)
        StatusLabel.Text = "Please enter a key"
        return false
    end
    
    -- Update button and status
    LoginButton.Text = "Validating..."
    LoginButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    StatusLabel.TextColor3 = Color3.fromRGB(100, 150, 255)
    StatusLabel.Text = "Connecting to server..."
    
    -- Disable button during authentication
    LoginButton.Active = false
    
    -- Use spawn to prevent blocking
    task.spawn(function()
        local isValid, responseData = validateKey(authKey)
        
        -- Re-enable button
        LoginButton.Active = true
        
        if isValid == true then
            LoginButton.Text = "Authenticated"
            LoginButton.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
            
            StatusLabel.TextColor3 = Color3.fromRGB(60, 220, 100)
            StatusLabel.Text = "Access granted"
            
            -- Store auth data globally
            getgenv().HyperVisorAuth = {
                authenticated = true,
                key = authKey,
                timestamp = tick(),
                keyInfo = (responseData and responseData.keyInfo) or {}
            }
            
            -- Save key if checkbox is checked
            if saveKeyEnabled then
                saveKey(authKey)
            else
                -- If save is disabled and key exists, delete it
                if savedKey then
                    deleteKey()
                end
            end
            
            -- Wait a moment then check for game script
            task.wait(1)
            
            -- Update status to show checking for script
            StatusLabel.Text = "Checking for game script..."
            LoginButton.Text = "Loading..."
            
            -- Check if script exists for current game
            local hasScript, scriptData = checkGameScript(authKey)
            
            if hasScript then
                -- Script found, execute it
                StatusLabel.Text = "Loading game script..."
                LoginButton.Text = "Executing..."
                
                task.wait(1)
                
                -- Close GUI before executing script
                ScreenGui:Destroy()
                
                -- Execute the game script
                executeScript(scriptData.githubUrl)
                
                return true
            else
                -- No script found, kick player
                StatusLabel.TextColor3 = Color3.fromRGB(220, 80, 80)
                StatusLabel.Text = "No script for this game"
                LoginButton.Text = "No Script Available"
                LoginButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
                
                -- Show kick message
                task.wait(2)
                
                -- Kick the player
                Players.LocalPlayer:Kick("❌ No script available for this game!\n\n🎮 Game ID: " .. getCurrentGameId() .. "\n\n💡 Contact administrators to add a script for this game.")
                
                return false
            end
        else
            -- Handle authentication failure
            local errorMessage = "Invalid authentication key"
            if responseData and responseData.error then
                errorMessage = responseData.error
            end
            
            StatusLabel.TextColor3 = Color3.fromRGB(220, 80, 80)
            StatusLabel.Text = errorMessage
            
            -- Reset button
            LoginButton.Text = "Authenticate"
            LoginButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            
            return false
        end
    end)
end

-- Button events
LoginButton.MouseButton1Click:Connect(function()
    authenticate()
end)

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Enter key support
KeyBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        authenticate()
    end
end)
