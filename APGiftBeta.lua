local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    LocalPlayer = Players.PlayerAdded:Wait()
end

-- ==========================================
-- 🖼️ ITEM IMAGE
-- ==========================================
local ITEM_IMAGE_ID = "rbxassetid://139291316302932"
local ROBUX_ICON_ID = "rbxasset://textures/ui/common/robux_small.png"

local success = pcall(function() return CoreGui.Name end)
local targetParent = success and CoreGui or LocalPlayer:WaitForChild("PlayerGui")

if targetParent:FindFirstChild("CustomPurchaseUI_Control") then
    targetParent.CustomPurchaseUI_Control:Destroy()
end
if targetParent:FindFirstChild("CustomPurchaseUI") then
    targetParent.CustomPurchaseUI:Destroy()
end

-- ==========================================
-- SCRIPT STATE & VARIABLES
-- ==========================================
local SETTINGS_FILE = "APVisual/ap_settings.txt"
pcall(function()
    if isfolder and makefolder and not isfolder("APVisual") then
        makefolder("APVisual")
    end
end)

-- Settings: balance | keybind name | startMinimized (1/0) | showOwned (1/0)
local function splitString(str, sep)
    local parts = {}
    for part in str:gmatch("[^" .. sep .. "]+") do
        table.insert(parts, part)
    end
    return parts
end

local function saveSettings(balance, keybind, minimized, showOwned)
    pcall(function()
        if writefile then
            local keyName = tostring(keybind):gsub("Enum.KeyCode.", "")
            writefile(SETTINGS_FILE, tostring(balance) .. "|" .. keyName .. "|" .. (minimized and "1" or "0") .. "|" .. (showOwned and "1" or "0"))
        end
    end)
end

local function loadSettings()
    local balance   = 5641388
    local keybind   = Enum.KeyCode.RightControl
    local minimized = false
    local showOwned = false
    pcall(function()
        if isfile and readfile and isfile(SETTINGS_FILE) then
            local parts = splitString(readfile(SETTINGS_FILE), "|")
            if parts[1] then local n = tonumber(parts[1]); if n then balance = n end end
            if parts[2] then
                local ok, kc = pcall(function() return Enum.KeyCode[parts[2]] end)
                if ok and kc then keybind = kc end
            end
            if parts[3] then minimized = (parts[3] == "1") end
            if parts[4] then showOwned = (parts[4] == "1") end
        end
    end)
    return balance, keybind, minimized, showOwned
end

local scriptEnabled   = true
local currentBalance, toggleKeybind, startMinimized, showOwned = loadSettings()
local hookedButtons   = {}
local isListeningForKey = false

-- Helper function to format numbers with commas
local function FormatNumber(n)
    local i, j, minus, int, fraction = tostring(n):find('([-]?)(%d+)([.]?%d*)')
    int = int:reverse():gsub("(%d%d%d)", "%1,")
    return minus .. int:reverse():gsub("^,", "") .. fraction
end

-- Function to dynamically find the user being gifted
-- Only returns a username if a "GIFTING" label and "@username" label share the same parent frame
-- Uses the exact known GUI path:
-- PlayerGui > [any ScreenGui] > Shop > GiftPlayerSelect > PlayerSelected > PlayerName
local function getGiftTargetUser()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")

    for _, screenGui in pairs(playerGui:GetChildren()) do
        local shopFrame = screenGui:FindFirstChild("Shop")
        if shopFrame then
            local giftSelect = shopFrame:FindFirstChild("GiftPlayerSelect")
            if giftSelect and giftSelect.Visible then
                local playerSelected = giftSelect:FindFirstChild("PlayerSelected")
                if playerSelected and playerSelected.Visible then
                    local playerNameLabel = playerSelected:FindFirstChild("PlayerName")
                    if playerNameLabel then
                        local name = playerNameLabel.Text:match("@[%w_]+")
                        if name then
                            return name
                        end
                    end
                end
            end
        end
    end

    return nil -- not gifting
end

-- ==========================================
-- CONTROL PANEL UI
-- ==========================================
local controlGui = Instance.new("ScreenGui")
controlGui.Name = "CustomPurchaseUI_Control"
controlGui.ResetOnSpawn = false
controlGui.Parent = targetParent

local controlFrame = Instance.new("Frame")
controlFrame.Name = "ControlFrame"
controlFrame.Size = UDim2.new(0, 200, 0, 230) -- taller to fit owned toggle
controlFrame.Position = UDim2.new(0, 20, 0, 20)
controlFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
controlFrame.BorderSizePixel = 0
controlFrame.Active = true
controlFrame.Draggable = true
controlFrame.ClipsDescendants = true
controlFrame.Parent = controlGui

local controlCorner = Instance.new("UICorner")
controlCorner.CornerRadius = UDim.new(0, 8)
controlCorner.Parent = controlFrame

local controlTitle = Instance.new("TextLabel")
controlTitle.Size = UDim2.new(1, -30, 0, 25)
controlTitle.Position = UDim2.new(0, 10, 0, 0)
controlTitle.BackgroundTransparency = 1
controlTitle.Text = "UI Controller"
controlTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
controlTitle.Font = Enum.Font.GothamBold
controlTitle.TextSize = 14
controlTitle.TextXAlignment = Enum.TextXAlignment.Left
controlTitle.Parent = controlFrame

local hideBtn = Instance.new("TextButton")
hideBtn.Size = UDim2.new(0, 25, 0, 25)
hideBtn.Position = UDim2.new(1, -25, 0, 0)
hideBtn.BackgroundTransparency = 1
hideBtn.Text = "X"
hideBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
hideBtn.Font = Enum.Font.GothamBold
hideBtn.TextSize = 16
hideBtn.Parent = controlFrame

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(1, -20, 0, 30)
toggleBtn.Position = UDim2.new(0, 10, 0, 30)
toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 110, 255)
toggleBtn.Text = "Script: ON"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 14
toggleBtn.Parent = controlFrame

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 6)
toggleCorner.Parent = toggleBtn

local balanceInput = Instance.new("TextBox")
balanceInput.Size = UDim2.new(1, -20, 0, 30)
balanceInput.Position = UDim2.new(0, 10, 0, 70)
balanceInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
balanceInput.Text = tostring(currentBalance)
balanceInput.PlaceholderText = "Set Fake Balance"
balanceInput.TextColor3 = Color3.fromRGB(255, 255, 255)
balanceInput.Font = Enum.Font.Gotham
balanceInput.TextSize = 14
balanceInput.ClearTextOnFocus = false
balanceInput.Parent = controlFrame

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 6)
inputCorner.Parent = balanceInput

-- Settings button at the bottom of the panel
local settingsBtn = Instance.new("TextButton")
settingsBtn.Size = UDim2.new(1, -20, 0, 30)
settingsBtn.Position = UDim2.new(0, 10, 0, 110)
settingsBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
settingsBtn.Text = "⚙  Settings"
settingsBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
settingsBtn.Font = Enum.Font.Gotham
settingsBtn.TextSize = 13
settingsBtn.Parent = controlFrame

local settingsCorner = Instance.new("UICorner")
settingsCorner.CornerRadius = UDim.new(0, 6)
settingsCorner.Parent = settingsBtn

local minimizeToggleBtn = Instance.new("TextButton")
minimizeToggleBtn.Size = UDim2.new(1, -20, 0, 30)
minimizeToggleBtn.Position = UDim2.new(0, 10, 0, 150)
minimizeToggleBtn.BackgroundColor3 = startMinimized and Color3.fromRGB(0, 110, 255) or Color3.fromRGB(55, 55, 55)
minimizeToggleBtn.Text = "Start Minimized: " .. (startMinimized and "YES" or "NO")
minimizeToggleBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
minimizeToggleBtn.Font = Enum.Font.Gotham
minimizeToggleBtn.TextSize = 12
minimizeToggleBtn.Parent = controlFrame

local minimizeToggleCorner = Instance.new("UICorner")
minimizeToggleCorner.CornerRadius = UDim.new(0, 6)
minimizeToggleCorner.Parent = minimizeToggleBtn

local ownedToggleBtn = Instance.new("TextButton")
ownedToggleBtn.Size = UDim2.new(1, -20, 0, 30)
ownedToggleBtn.Position = UDim2.new(0, 10, 0, 190)
ownedToggleBtn.BackgroundColor3 = showOwned and Color3.fromRGB(0, 110, 255) or Color3.fromRGB(55, 55, 55)
ownedToggleBtn.Text = "Show as OWNED: " .. (showOwned and "YES" or "NO")
ownedToggleBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
ownedToggleBtn.Font = Enum.Font.Gotham
ownedToggleBtn.TextSize = 12
ownedToggleBtn.Parent = controlFrame

local ownedToggleCorner = Instance.new("UICorner")
ownedToggleCorner.CornerRadius = UDim.new(0, 6)
ownedToggleCorner.Parent = ownedToggleBtn

-- ==========================================
-- SETTINGS UI
-- ==========================================
local settingsGui = Instance.new("ScreenGui")
settingsGui.Name = "CustomPurchaseUI_Settings"
settingsGui.ResetOnSpawn = false
settingsGui.Parent = targetParent

local settingsFrame = Instance.new("Frame")
settingsFrame.Name = "SettingsFrame"
settingsFrame.Size = UDim2.new(0, 220, 0, 130)
settingsFrame.Position = UDim2.new(0, 230, 0, 20) -- Opens to the right of the control panel
settingsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
settingsFrame.BorderSizePixel = 0
settingsFrame.Active = true
settingsFrame.Draggable = true
settingsFrame.ClipsDescendants = true
settingsFrame.Visible = false
settingsFrame.Parent = settingsGui

local settingsFrameCorner = Instance.new("UICorner")
settingsFrameCorner.CornerRadius = UDim.new(0, 8)
settingsFrameCorner.Parent = settingsFrame

-- Settings title bar
local settingsTitle = Instance.new("TextLabel")
settingsTitle.Size = UDim2.new(1, -40, 0, 30)
settingsTitle.Position = UDim2.new(0, 10, 0, 0)
settingsTitle.BackgroundTransparency = 1
settingsTitle.Text = "⚙  Settings"
settingsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
settingsTitle.Font = Enum.Font.GothamBold
settingsTitle.TextSize = 13
settingsTitle.TextXAlignment = Enum.TextXAlignment.Left
settingsTitle.Parent = settingsFrame

local settingsCloseBtn = Instance.new("TextButton")
settingsCloseBtn.Size = UDim2.new(0, 25, 0, 25)
settingsCloseBtn.Position = UDim2.new(1, -28, 0, 3)
settingsCloseBtn.BackgroundTransparency = 1
settingsCloseBtn.Text = "X"
settingsCloseBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
settingsCloseBtn.Font = Enum.Font.GothamBold
settingsCloseBtn.TextSize = 14
settingsCloseBtn.Parent = settingsFrame

-- Divider line
local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, -20, 0, 1)
divider.Position = UDim2.new(0, 10, 0, 30)
divider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
divider.BorderSizePixel = 0
divider.Parent = settingsFrame

-- Keybind label
local keybindLabel = Instance.new("TextLabel")
keybindLabel.Size = UDim2.new(1, -20, 0, 20)
keybindLabel.Position = UDim2.new(0, 10, 0, 40)
keybindLabel.BackgroundTransparency = 1
keybindLabel.Text = "Show/Hide Panel Keybind:"
keybindLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
keybindLabel.Font = Enum.Font.Gotham
keybindLabel.TextSize = 12
keybindLabel.TextXAlignment = Enum.TextXAlignment.Left
keybindLabel.Parent = settingsFrame

-- Keybind button (shows current key, click to rebind)
local keybindBtn = Instance.new("TextButton")
keybindBtn.Size = UDim2.new(1, -20, 0, 32)
keybindBtn.Position = UDim2.new(0, 10, 0, 65)
keybindBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
keybindBtn.Text = tostring(toggleKeybind):gsub("Enum.KeyCode.", "")
keybindBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
keybindBtn.Font = Enum.Font.GothamBold
keybindBtn.TextSize = 13
keybindBtn.Parent = settingsFrame

local keybindBtnCorner = Instance.new("UICorner")
keybindBtnCorner.CornerRadius = UDim.new(0, 6)
keybindBtnCorner.Parent = keybindBtn

local keybindStroke = Instance.new("UIStroke")
keybindStroke.Color = Color3.fromRGB(70, 70, 70)
keybindStroke.Thickness = 1
keybindStroke.Parent = keybindBtn

-- Hint text below keybind button
local keybindHint = Instance.new("TextLabel")
keybindHint.Size = UDim2.new(1, -20, 0, 20)
keybindHint.Position = UDim2.new(0, 10, 0, 103)
keybindHint.BackgroundTransparency = 1
keybindHint.Text = "Click the button above to rebind"
keybindHint.TextColor3 = Color3.fromRGB(120, 120, 120)
keybindHint.Font = Enum.Font.Gotham
keybindHint.TextSize = 11
keybindHint.TextXAlignment = Enum.TextXAlignment.Left
keybindHint.Parent = settingsFrame

-- ==========================================
-- SETTINGS LOGIC
-- ==========================================
settingsBtn.MouseButton1Click:Connect(function()
    settingsFrame.Visible = not settingsFrame.Visible
end)

settingsCloseBtn.MouseButton1Click:Connect(function()
    settingsFrame.Visible = false
    -- Cancel any pending rebind when closed
    if isListeningForKey then
        isListeningForKey = false
        keybindBtn.Text = tostring(toggleKeybind):gsub("Enum.KeyCode.", "")
        keybindBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        keybindStroke.Color = Color3.fromRGB(70, 70, 70)
        keybindHint.Text = "Click the button above to rebind"
    end
end)

keybindBtn.MouseButton1Click:Connect(function()
    if isListeningForKey then
        -- Cancel if clicked again while listening
        isListeningForKey = false
        keybindBtn.Text = tostring(toggleKeybind):gsub("Enum.KeyCode.", "")
        keybindBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        keybindStroke.Color = Color3.fromRGB(70, 70, 70)
        keybindHint.Text = "Click the button above to rebind"
    else
        -- Enter listening mode
        isListeningForKey = true
        keybindBtn.Text = "Press any key..."
        keybindBtn.BackgroundColor3 = Color3.fromRGB(0, 80, 180)
        keybindStroke.Color = Color3.fromRGB(0, 130, 255)
        keybindHint.Text = "Listening... click button to cancel"
    end
end)

-- Listen for new key press when in rebind mode
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    -- Handle keybind toggle (show/hide panel)
    if not isListeningForKey and input.KeyCode == toggleKeybind then
        controlFrame.Visible = not controlFrame.Visible
        return
    end

    -- Handle rebind input (ignore mouse, gamepad, etc.)
    if isListeningForKey and input.UserInputType == Enum.UserInputType.Keyboard then
        -- Ignore modifier-only keys
        local ignored = {
            [Enum.KeyCode.LeftShift] = true, [Enum.KeyCode.RightShift] = true,
            [Enum.KeyCode.LeftControl] = true, [Enum.KeyCode.LeftAlt] = true,
            [Enum.KeyCode.RightAlt] = true, [Enum.KeyCode.CapsLock] = true,
            [Enum.KeyCode.Escape] = true,
        }
        if ignored[input.KeyCode] then return end

        toggleKeybind = input.KeyCode
        isListeningForKey = false

        local keyName = tostring(input.KeyCode):gsub("Enum.KeyCode.", "")
        keybindBtn.Text = keyName
        keybindBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        keybindStroke.Color = Color3.fromRGB(70, 70, 70)
        keybindHint.Text = "Keybind saved!"
        saveSettings(currentBalance, toggleKeybind, startMinimized, showOwned)

        -- Reset hint text after 2 seconds
        task.delay(2, function()
            if keybindHint and keybindHint.Parent then
                keybindHint.Text = "Click the button above to rebind"
            end
        end)
    end
end)

-- Apply saved minimized preference on startup
controlFrame.Visible = not startMinimized

-- ==========================================
-- CONTROL PANEL LOGIC
-- ==========================================
hideBtn.MouseButton1Click:Connect(function()
    controlFrame.Visible = false
end)

minimizeToggleBtn.MouseButton1Click:Connect(function()
    startMinimized = not startMinimized
    minimizeToggleBtn.Text = "Start Minimized: " .. (startMinimized and "YES" or "NO")
    minimizeToggleBtn.BackgroundColor3 = startMinimized and Color3.fromRGB(0, 110, 255) or Color3.fromRGB(55, 55, 55)
    saveSettings(currentBalance, toggleKeybind, startMinimized, showOwned)
end)

ownedToggleBtn.MouseButton1Click:Connect(function()
    showOwned = not showOwned
    ownedToggleBtn.Text = "Show as OWNED: " .. (showOwned and "YES" or "NO")
    ownedToggleBtn.BackgroundColor3 = showOwned and Color3.fromRGB(0, 110, 255) or Color3.fromRGB(55, 55, 55)
    saveSettings(currentBalance, toggleKeybind, startMinimized, showOwned)
end)

-- ==========================================
-- "SHOW AS OWNED" LOOP
-- Finds PlayerGui > Shop > Shop > Content > List > GamepassList > [frame] > RedStroke > Buy > Price
-- and sets it to "OWNED" unless the player is currently gifting
-- ==========================================
local nativePriceText = nil -- stores the original price text so we can restore it

local function findPriceLabel()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    for _, screenGui in pairs(playerGui:GetChildren()) do
        local shopFrame = screenGui:FindFirstChild("Shop")
        if shopFrame then
            local content = shopFrame:FindFirstChild("Content")
            if content then
                local list = content:FindFirstChild("List")
                if list then
                    local gamepassList = list:FindFirstChild("GamepassList")
                    if gamepassList then
                        for _, item in pairs(gamepassList:GetChildren()) do
                            -- Path: GamepassList > [item] > Buy > Price
                            local buyFrame = item:FindFirstChild("Buy")
                            if buyFrame then
                                local priceLabel = buyFrame:FindFirstChild("Price")
                                if priceLabel and priceLabel:IsA("TextLabel") then
                                    return priceLabel
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end

task.spawn(function()
    while true do
        task.wait(0.25)
        pcall(function()
            local priceLabel = findPriceLabel()
            if not priceLabel then return end

            local isGifting = (getGiftTargetUser() ~= nil)

            if showOwned and not isGifting then
                -- Save native text before overwriting (only once)
                if priceLabel.Text ~= "OWNED" then
                    nativePriceText = priceLabel.Text
                end
                priceLabel.Text = "OWNED"
            else
                -- Restore native text if we have it saved
                if nativePriceText and priceLabel.Text == "OWNED" then
                    priceLabel.Text = nativePriceText
                end
            end
        end)
    end
end)

-- Legacy chat command still works too
LocalPlayer.Chatted:Connect(function(message)
    if string.lower(message) == "/ap" then
        controlFrame.Visible = true
    end
end)

toggleBtn.MouseButton1Click:Connect(function()
    scriptEnabled = not scriptEnabled
    if scriptEnabled then
        toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 110, 255)
        toggleBtn.Text = "Script: ON"
    else
        toggleBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        toggleBtn.Text = "Script: OFF"
    end
    for _, overlay in pairs(hookedButtons) do
        if overlay and overlay.Parent then
            overlay.Visible = scriptEnabled
        end
    end
end)

balanceInput.FocusLost:Connect(function()
    local num = tonumber(balanceInput.Text)
    if num then
        currentBalance = num
        saveSettings(currentBalance, toggleKeybind, startMinimized, showOwned)
    else
        balanceInput.Text = tostring(currentBalance)
    end
end)

-- ==========================================
-- FUNCTION TO CREATE AND SHOW YOUR CUSTOM UI
-- ==========================================

-- Shared style constants matching Roblox native purchase dialog
local BG        = Color3.fromRGB(22, 22, 26)
local BG_ROW    = Color3.fromRGB(30, 30, 35)
local BLUE      = Color3.fromRGB(58, 120, 255)
local BLUE_DARK = Color3.fromRGB(30, 60, 160)
local W, H      = 460, 300   -- buy/low-balance dialog size
local SW, SH    = 460, 240   -- success dialog size

local function makeFrame(parent, w, h, zindex)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, 0, 0, 0)
    f.Position = UDim2.new(0.5, 0, 0.5, 0)
    f.AnchorPoint = Vector2.new(0.5, 0.5)
    f.BackgroundColor3 = BG
    f.ClipsDescendants = true
    f.ZIndex = zindex or 2
    f.Parent = parent
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 16); c.Parent = f
    return f
end

local function makeLabel(parent, text, size, pos, textsize, font, color, align, zindex)
    local l = Instance.new("TextLabel")
    l.Size = size; l.Position = pos
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color or Color3.fromRGB(255,255,255)
    l.TextSize = textsize or 14
    l.Font = font or Enum.Font.Gotham
    l.TextXAlignment = align or Enum.TextXAlignment.Left
    l.ZIndex = zindex or 2
    l.Parent = parent
    return l
end

local function makeCloseBtn(parent, zindex)
    local z = zindex or 2

    -- Circular background for hover/click feedback
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(0, 28, 0, 28)
    bg.Position = UDim2.new(1, -38, 0, 14)
    bg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    bg.BackgroundTransparency = 1
    bg.ZIndex = z
    bg.Parent = parent
    local bgC = Instance.new("UICorner"); bgC.CornerRadius = UDim.new(0, 6); bgC.Parent = bg

    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 1, 0)
    b.Position = UDim2.new(0, 0, 0, 0)
    b.BackgroundTransparency = 1
    b.Text = "X"
    b.TextColor3 = Color3.fromRGB(180, 180, 180)
    b.TextSize = 16
    b.Font = Enum.Font.GothamBold
    b.ZIndex = z + 1
    b.Parent = bg

    -- Hover: show faint white circle
    b.MouseEnter:Connect(function()
        bg.BackgroundTransparency = 0.8
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
    b.MouseLeave:Connect(function()
        bg.BackgroundTransparency = 1
        b.TextColor3 = Color3.fromRGB(180, 180, 180)
    end)
    -- Click: darken circle
    b.MouseButton1Down:Connect(function()
        bg.BackgroundTransparency = 0.6
    end)
    b.MouseButton1Up:Connect(function()
        bg.BackgroundTransparency = 0.8
    end)

    return b
end

local function makeBalanceRow(parent, balance, zindex)
    local container = Instance.new("Frame")
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(0, 180, 0, 20)
    container.Position = UDim2.new(1, -46, 0, 20)
    container.AnchorPoint = Vector2.new(1, 0)
    container.ZIndex = zindex or 2
    container.Parent = parent

    local ll = Instance.new("UIListLayout")
    ll.FillDirection = Enum.FillDirection.Horizontal
    ll.HorizontalAlignment = Enum.HorizontalAlignment.Right
    ll.VerticalAlignment = Enum.VerticalAlignment.Center
    ll.Padding = UDim.new(0, 5)
    ll.Parent = container

    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 16, 0, 16)
    icon.BackgroundTransparency = 1
    icon.Image = ROBUX_ICON_ID
    icon.ImageColor3 = Color3.fromRGB(200,200,200)
    icon.LayoutOrder = 1; icon.ZIndex = zindex or 2; icon.Parent = container

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(0, 0, 1, 0)
    txt.AutomaticSize = Enum.AutomaticSize.X
    txt.BackgroundTransparency = 1
    txt.Text = FormatNumber(balance)
    txt.TextColor3 = Color3.fromRGB(200,200,200)
    txt.TextSize = 14; txt.Font = Enum.Font.Gotham
    txt.LayoutOrder = 2; txt.ZIndex = zindex or 2; txt.Parent = container
end

local function makeItemRow(parent, yPos, zindex, itemName)
    -- Icon (no background)
    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 64, 0, 64)
    icon.Position = UDim2.new(0, 24, 0, yPos)
    icon.BackgroundTransparency = 1
    icon.Image = ITEM_IMAGE_ID
    icon.ScaleType = Enum.ScaleType.Fit
    icon.ZIndex = zindex or 2; icon.Parent = parent

    -- Name
    makeLabel(parent, itemName or "[GIFT] Admin Commands",
        UDim2.new(1, -110, 0, 22), UDim2.new(0, 104, 0, yPos + 8),
        16, Enum.Font.GothamBold, Color3.fromRGB(255,255,255),
        Enum.TextXAlignment.Left, zindex)

    -- Price row
    local pIcon = Instance.new("ImageLabel")
    pIcon.Size = UDim2.new(0, 15, 0, 15)
    pIcon.Position = UDim2.new(0, 104, 0, yPos + 36)
    pIcon.BackgroundTransparency = 1
    pIcon.Image = ROBUX_ICON_ID
    pIcon.ZIndex = zindex or 2; pIcon.Parent = parent

    makeLabel(parent, "7,499",
        UDim2.new(0, 80, 0, 18), UDim2.new(0, 124, 0, yPos + 33),
        14, Enum.Font.Gotham, Color3.fromRGB(180,180,180),
        Enum.TextXAlignment.Left, zindex)
end

local function makeBuyButton(parent, yPos, zindex)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -48, 0, 50)
    btn.Position = UDim2.new(0, 24, 0, yPos)
    btn.BackgroundColor3 = BLUE_DARK
    btn.Text = ""; btn.ZIndex = zindex or 2; btn.Parent = parent
    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0,12); bc.Parent = btn

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = BLUE
    fill.BorderSizePixel = 0; fill.ZIndex = (zindex or 2)
    fill.Parent = btn
    local fc = Instance.new("UICorner"); fc.CornerRadius = UDim.new(0,12); fc.Parent = fill

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "Buy"
    label.TextColor3 = Color3.fromRGB(160,160,160)
    label.TextSize = 18; label.Font = Enum.Font.GothamBold
    label.ZIndex = (zindex or 2) + 1; label.Parent = btn

    return btn, fill, label
end

local function triggerCustomStartUI(targetUser)
    -- Determine gifting context
    local isGifting = (targetUser ~= nil)
    local itemName    = isGifting and "[GIFT] Admin Commands" or "Admin Commands"
    local successDesc = isGifting
        and "You have successfully bought [GIFT] Admin Commands."
        or  "You have successfully bought Admin Commands."
    local notifText   = isGifting
        and ("You gifted Admin Commands to " .. tostring(targetUser) .. "!")
        or  "Successfully bought Admin Commands!"

    if targetParent:FindFirstChild("CustomPurchaseUI") then
        targetParent.CustomPurchaseUI:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CustomPurchaseUI"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.DisplayOrder = 999 -- Renders above all Roblox core UI
    screenGui.Parent = targetParent

    local overlay = Instance.new("TextButton")
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.Text = ""
    overlay.AutoButtonColor = false
    overlay.ZIndex = 1
    overlay.Parent = screenGui

    -- ==========================================
    -- LOW BALANCE BRANCH
    -- ==========================================
    if currentBalance < 7499 then
        local lowFrame = makeFrame(screenGui, W, H, 2)

        makeLabel(lowFrame, "Buy Robux and item",
            UDim2.new(0, 260, 0, 26), UDim2.new(0, 24, 0, 18),
            18, Enum.Font.GothamBold, Color3.fromRGB(255,255,255),
            Enum.TextXAlignment.Left, 2)

        local lowClose = makeCloseBtn(lowFrame, 2)
        makeBalanceRow(lowFrame, currentBalance, 2)
        makeItemRow(lowFrame, 58, 2, itemName)


        -- Package row
        local pkgBox = Instance.new("Frame")
        pkgBox.Size = UDim2.new(1, -48, 0, 52)
        pkgBox.Position = UDim2.new(0, 24, 0, 150)
        pkgBox.BackgroundColor3 = BG_ROW
        pkgBox.ZIndex = 2; pkgBox.Parent = lowFrame
        local pkgC = Instance.new("UICorner"); pkgC.CornerRadius = UDim.new(0,10); pkgC.Parent = pkgBox
        local pkgS = Instance.new("UIStroke"); pkgS.Color = Color3.fromRGB(90,90,100); pkgS.Thickness = 1.5; pkgS.Parent = pkgBox

        local pkgIcon = Instance.new("ImageLabel")
        pkgIcon.Size = UDim2.new(0, 18, 0, 18)
        pkgIcon.Position = UDim2.new(0, 14, 0.5, -9)
        pkgIcon.BackgroundTransparency = 1; pkgIcon.Image = ROBUX_ICON_ID
        pkgIcon.ZIndex = 3; pkgIcon.Parent = pkgBox

        makeLabel(pkgBox, "10,000",
            UDim2.new(0, 120, 1, 0), UDim2.new(0, 38, 0, 0),
            15, Enum.Font.GothamBold, Color3.fromRGB(255,255,255),
            Enum.TextXAlignment.Left, 3)

        makeLabel(pkgBox, "$139.99",
            UDim2.new(0, 90, 1, 0), UDim2.new(1, -98, 0, 0),
            15, Enum.Font.Gotham, Color3.fromRGB(200,200,200),
            Enum.TextXAlignment.Right, 3)

        local lowBtn, lowFill, lowText = makeBuyButton(lowFrame, 216, 2)

        -- Fine print
        makeLabel(lowFrame, "Your payment method will be charged. Roblox Terms of Use apply.",
            UDim2.new(1, -48, 0, 28), UDim2.new(0, 24, 0, 272),
            11, Enum.Font.Gotham, Color3.fromRGB(120,120,130),
            Enum.TextXAlignment.Center, 2).TextWrapped = true

        -- Pop in
        local popInfo = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        TweenService:Create(lowFrame, popInfo, {Size = UDim2.new(0, W, 0, H)}):Play()

        -- Loading bar + click
        local lowClickable = false
        local lowFillTween = TweenService:Create(lowFill, TweenInfo.new(2, Enum.EasingStyle.Linear), {Size = UDim2.new(1, 0, 1, 0)})
        lowFillTween.Completed:Connect(function()
            lowClickable = true
            lowText.TextColor3 = Color3.fromRGB(255, 255, 255)
        end)
        task.wait(0.5)
        lowFillTween:Play()

        lowBtn.MouseButton1Click:Connect(function()
            if not lowClickable then return end
            lowClickable = false
            lowFill.Visible = false
            lowText.TextColor3 = Color3.fromRGB(255, 255, 255)
            task.wait(0.75)
            screenGui:Destroy()
        end)

        lowClose.MouseButton1Click:Connect(function() screenGui:Destroy() end)
        overlay.MouseButton1Click:Connect(function() screenGui:Destroy() end)
        return
    end

    -- ==========================================
    -- NORMAL BALANCE BRANCH
    -- ==========================================
    local mainFrame = makeFrame(screenGui, W, H, 2)

    makeLabel(mainFrame, "Buy item",
        UDim2.new(0, 200, 0, 26), UDim2.new(0, 24, 0, 18),
        18, Enum.Font.GothamBold, Color3.fromRGB(255,255,255),
        Enum.TextXAlignment.Left, 2)

    local mainCloseButton = makeCloseBtn(mainFrame, 2)
    makeBalanceRow(mainFrame, currentBalance, 2)
    makeItemRow(mainFrame, 58, 2, itemName)


    -- Buy button
    local startButton, loadingFill, startText = makeBuyButton(mainFrame, 150, 2)

    -- ==========================================
    -- SUCCESS / OK UI
    -- ==========================================
    local successFrame = makeFrame(screenGui, SW, SH, 2)
    successFrame.Visible = false

    makeLabel(successFrame, "Purchase completed",
        UDim2.new(1, -60, 0, 26), UDim2.new(0, 24, 0, 18),
        18, Enum.Font.GothamBold, Color3.fromRGB(255,255,255),
        Enum.TextXAlignment.Left, 2)

    local successCloseButton = makeCloseBtn(successFrame, 2)


    -- Check circle
    local checkCircle = Instance.new("Frame")
    checkCircle.Size = UDim2.new(0, 54, 0, 54)
    checkCircle.Position = UDim2.new(0.5, -27, 0, 68)
    checkCircle.BackgroundTransparency = 1
    checkCircle.ZIndex = 2; checkCircle.Parent = successFrame
    local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0.5,0); cc.Parent = checkCircle
    local cs = Instance.new("UIStroke"); cs.Color = Color3.fromRGB(255,255,255); cs.Thickness = 2; cs.Parent = checkCircle

    local checkMark = Instance.new("TextLabel")
    checkMark.Size = UDim2.new(1,0,1,0)
    checkMark.BackgroundTransparency = 1
    checkMark.Text = "✓"
    checkMark.TextColor3 = Color3.fromRGB(255,255,255)
    checkMark.TextSize = 32; checkMark.Font = Enum.Font.GothamBold
    checkMark.ZIndex = 3; checkMark.Parent = checkCircle

    makeLabel(successFrame, successDesc,
        UDim2.new(1, -48, 0, 34), UDim2.new(0, 24, 0, 132),
        14, Enum.Font.Gotham, Color3.fromRGB(180,180,190),
        Enum.TextXAlignment.Center, 2).TextWrapped = true

    -- OK button (same style as Buy)
    local okButton = Instance.new("TextButton")
    okButton.Size = UDim2.new(1, -48, 0, 50)
    okButton.Position = UDim2.new(0, 24, 0, 176)
    okButton.BackgroundColor3 = BLUE
    okButton.Text = "OK"
    okButton.TextColor3 = Color3.fromRGB(255,255,255)
    okButton.TextSize = 18; okButton.Font = Enum.Font.GothamBold
    okButton.ZIndex = 2; okButton.Parent = successFrame
    local okC = Instance.new("UICorner"); okC.CornerRadius = UDim.new(0,12); okC.Parent = okButton

    -- Bottom notification
    local bottomNotification = Instance.new("TextLabel")
    bottomNotification.Size = UDim2.new(0, 0, 0, 0)
    bottomNotification.Position = UDim2.new(0.5, 0, 0.85, 0)
    bottomNotification.AnchorPoint = Vector2.new(0.5, 0.5)
    bottomNotification.BackgroundTransparency = 1
    bottomNotification.Text = notifText
    bottomNotification.TextColor3 = Color3.fromRGB(85, 255, 0)
    bottomNotification.TextSize = 16
    bottomNotification.Font = Enum.Font.GothamBold
    bottomNotification.Visible = false
    bottomNotification.ZIndex = 0
    bottomNotification.Parent = screenGui

    local textStroke = Instance.new("UIStroke")
    textStroke.Color = Color3.fromRGB(0, 0, 0)
    textStroke.Thickness = 1
    textStroke.Parent = bottomNotification

    -- ==========================================
    -- ANIMATIONS & LOGIC
    -- ==========================================
    local isClickable = false
    local popTweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    local isSuccessClosed = false
    local isNotificationFaded = false

    local function checkCleanup()
        if isSuccessClosed and isNotificationFaded then
            screenGui:Destroy()
        end
    end

    TweenService:Create(mainFrame, popTweenInfo, {Size = UDim2.new(0, W, 0, 215)}):Play()

    local loadTween = TweenService:Create(loadingFill, TweenInfo.new(2, Enum.EasingStyle.Linear), {Size = UDim2.new(1, 0, 1, 0)})
    loadTween.Completed:Connect(function()
        isClickable = true
        startText.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
    task.wait(0.5)
    loadTween:Play()

    startButton.MouseButton1Click:Connect(function()
        if not isClickable then return end
        isClickable = false

        loadingFill.Visible = false
        startText.TextColor3 = Color3.fromRGB(255, 255, 255)
        task.wait(0.75)

        currentBalance = currentBalance - 7499
        balanceInput.Text = tostring(currentBalance)
        saveSettings(currentBalance, toggleKeybind, startMinimized, showOwned)

        mainFrame.Visible = false
        successFrame.Visible = true
        bottomNotification.Visible = true

        TweenService:Create(successFrame, popTweenInfo, {Size = UDim2.new(0, SW, 0, SH)}):Play()
        TweenService:Create(bottomNotification, popTweenInfo, {Size = UDim2.new(1, 0, 0, 50)}):Play()

        print("Executing Admin Commands...")

        task.spawn(function()
            task.wait(3)
            local fadeOutInfo = TweenInfo.new(1, Enum.EasingStyle.Linear)
            local fadeText = TweenService:Create(bottomNotification, fadeOutInfo, {TextTransparency = 1})
            local fadeStroke = TweenService:Create(textStroke, fadeOutInfo, {Transparency = 1})
            fadeText:Play(); fadeStroke:Play()
            fadeText.Completed:Wait()
            isNotificationFaded = true
            checkCleanup()
        end)
    end)

    mainCloseButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)

    local function closeSuccessFrame()
        successFrame.Visible = false
        overlay.Visible = false
        isSuccessClosed = true
        checkCleanup()
    end

    successCloseButton.MouseButton1Click:Connect(closeSuccessFrame)
    okButton.MouseButton1Click:Connect(closeSuccessFrame)
end

-- ==========================================
-- BUTTON HOOK SCANNER
-- ==========================================
local function attemptToHookButton(guiElement)
    if guiElement:IsA("GuiButton") then
        if guiElement:FindFirstChild("PurchaseBlockOverlay") then return end

        local foundText = false

        if guiElement:IsA("TextButton") and (string.find(guiElement.Text, "7,499") or string.find(guiElement.Text, "7499")) then
            foundText = true
        end

        for _, child in pairs(guiElement:GetDescendants()) do
            if child:IsA("TextLabel") and (string.find(child.Text, "7,499") or string.find(child.Text, "7499")) then
                foundText = true
            end
        end

        if foundText then
            local blockOverlay = Instance.new("TextButton")
            blockOverlay.Name = "PurchaseBlockOverlay"
            blockOverlay.Size = UDim2.new(1, 0, 1, 0)
            blockOverlay.BackgroundTransparency = 1
            blockOverlay.Text = ""
            blockOverlay.ZIndex = guiElement.ZIndex + 10
            blockOverlay.Visible = scriptEnabled
            blockOverlay.Parent = guiElement

            blockOverlay.MouseButton1Click:Connect(function()
                if scriptEnabled then
                    local targetUser = getGiftTargetUser()
                    triggerCustomStartUI(targetUser)
                end
            end)

            table.insert(hookedButtons, blockOverlay)
            print("Successfully hooked and blocked the Admin Commands purchase button!")
        end
    end
end

for _, element in pairs(LocalPlayer:WaitForChild("PlayerGui"):GetDescendants()) do
    attemptToHookButton(element)
end

LocalPlayer.PlayerGui.DescendantAdded:Connect(attemptToHookButton)
