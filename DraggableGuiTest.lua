local rs  = game:GetService("RunService")
local uis = game:GetService("UserInputService")
local camera = workspace.CurrentCamera
local g   = Instance.new("ScreenGui", game.Players.LocalPlayer.PlayerGui)
g.ResetOnSpawn = false

-- main frame
local f = Instance.new("Frame", g)
f.Size = UDim2.new(0,340,0,220)
f.AnchorPoint = Vector2.new(0.5, 0.5)
f.Position = UDim2.new(0.5, 0, 0.5, 0)
f.BackgroundColor3 = Color3.fromRGB(4,4,4)
f.BorderSizePixel = 0
f.Active = true
f.ZIndex = 2
Instance.new("UICorner", f).CornerRadius = UDim.new(0,18)

local stroke = Instance.new("UIStroke", f)
stroke.Thickness = 1.8
stroke.Color = Color3.fromRGB(50,50,50)

-- minimized frame
local minFrame = Instance.new("Frame", g)
minFrame.Size = UDim2.new(0,60,0,60)
minFrame.AnchorPoint = Vector2.new(0.5, 0.5)
minFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
minFrame.BackgroundColor3 = Color3.fromRGB(4,4,4)
minFrame.Visible = false
minFrame.ZIndex = 5
Instance.new("UICorner", minFrame).CornerRadius = UDim.new(0,14)

local minStroke = Instance.new("UIStroke", minFrame)
minStroke.Thickness = 1.8

local minLabel = Instance.new("TextLabel", minFrame)
minLabel.Size = UDim2.new(1,0,1,0)
minLabel.BackgroundTransparency = 1
minLabel.Text = "FT"
minLabel.Font = Enum.Font.GothamBold
minLabel.TextSize = 22
minLabel.TextColor3 = Color3.fromRGB(210,210,210)
minLabel.ZIndex = 6

local minBtnOverlay = Instance.new("TextButton", minFrame)
minBtnOverlay.Size = UDim2.new(1,0,1,0)
minBtnOverlay.BackgroundTransparency = 1
minBtnOverlay.Text = ""
minBtnOverlay.ZIndex = 7

-- dynamic scaling logic for both frames
local uiScale = Instance.new("UIScale", f)
local minScale = Instance.new("UIScale", minFrame)

local function updateScale()
    local targetWidth = camera.ViewportSize.X * 0.3 
    local scaleFactor = targetWidth / 340
    uiScale.Scale = scaleFactor
    minScale.Scale = scaleFactor
end
updateScale()
camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)

-- shadow 
local shadow = Instance.new("ImageLabel", f)
shadow.Size = UDim2.new(1,30,1,30)
shadow.Position = UDim2.new(0,-15,0,-12)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://5028857084"
shadow.ImageColor3 = Color3.fromRGB(0,0,0)
shadow.ImageTransparency = 0.4
shadow.ZIndex = 1 

-- inner top glow bar
local topglow = Instance.new("Frame", f)
topglow.ZIndex = 2
topglow.Size = UDim2.new(0.6,0,0,2)
topglow.Position = UDim2.new(0.2,0,0,0)
topglow.BorderSizePixel = 0
topglow.BackgroundColor3 = Color3.fromRGB(255,255,255)
topglow.BackgroundTransparency = 0.6

-- drag bar
local bar = Instance.new("Frame", f)
bar.ZIndex = 2
bar.Size = UDim2.new(1,0,0,40)
bar.BackgroundColor3 = Color3.fromRGB(7,7,7)
bar.BorderSizePixel = 0
Instance.new("UICorner", bar).CornerRadius = UDim.new(0,18)
local fix = Instance.new("Frame", bar)
fix.Size = UDim2.new(1,0,0.5,0)
fix.Position = UDim2.new(0,0,0.5,0)
fix.BackgroundColor3 = Color3.fromRGB(7,7,7)
fix.BorderSizePixel = 0
fix.ZIndex = 2

local title = Instance.new("TextLabel", bar)
title.ZIndex = 3
title.Size = UDim2.new(1,0,1,0)
title.BackgroundTransparency = 1
title.Text = "TRADE TOOL"
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.TextColor3 = Color3.fromRGB(55,55,55)

-- close / minimize button
local closeBtn = Instance.new("TextButton", bar)
closeBtn.ZIndex = 4
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0.5, -15)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.TextColor3 = Color3.fromRGB(150, 150, 150)

closeBtn.MouseEnter:Connect(function() closeBtn.TextColor3 = Color3.fromRGB(255, 80, 80) end)
closeBtn.MouseLeave:Connect(function() closeBtn.TextColor3 = Color3.fromRGB(150, 150, 150) end)

closeBtn.MouseButton1Click:Connect(function()
    minFrame.Position = f.Position 
    f.Visible = false
    minFrame.Visible = true
end)

-- REUSABLE SMOOTH DRAG LOGIC (Now with click-cancellation!)
local function makeDraggable(dragHandle, targetFrame, onClick)
    local dragging, dragInput, dragStart, startPos, hasDragged
    
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            hasDragged = false
            dragStart = input.Position
            startPos = targetFrame.Position

            local con
            con = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    -- If we didn't drag, and an onClick function exists, trigger it!
                    if not hasDragged and onClick then
                        onClick()
                    end
                    con:Disconnect()
                end
            end)
        end
    end)

    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    uis.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            -- If mouse moves more than 3 pixels, it's a drag, not a click
            if delta.Magnitude > 3 then 
                hasDragged = true
            end
            targetFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Apply dragging to main frame (no click action needed)
makeDraggable(bar, f)

-- Apply dragging to minimized frame (with maximize callback)
makeDraggable(minBtnOverlay, minFrame, function()
    f.Position = minFrame.Position 
    minFrame.Visible = false
    f.Visible = true
end)

-- button factory
local function btn(txt, y)
    local wrap = Instance.new("Frame", f)
    wrap.ZIndex = 2
    wrap.Size = UDim2.new(0.82,0,0,52)
    wrap.Position = UDim2.new(0.09,0,0,y)
    wrap.BackgroundColor3 = Color3.fromRGB(8,8,8)
    wrap.BorderSizePixel = 0
    Instance.new("UICorner", wrap).CornerRadius = UDim.new(0,13)
    local ws = Instance.new("UIStroke", wrap)
    ws.Thickness = 1.2

    -- inner shimmer
    local shine = Instance.new("ImageLabel", wrap)
    shine.ZIndex = 3
    shine.Size = UDim2.new(1,0,0.5,0)
    shine.Position = UDim2.new(0,0,0,0)
    shine.BackgroundTransparency = 1
    shine.Image = "rbxassetid://5028857084"
    shine.ImageColor3 = Color3.fromRGB(255,255,255)
    shine.ImageTransparency = 0.94

    local b = Instance.new("TextButton", wrap)
    b.ZIndex = 4
    b.Size = UDim2.new(1,0,1,0)
    b.BackgroundTransparency = 1
    b.Text = txt
    b.TextColor3 = Color3.fromRGB(210,210,210)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 15
    b.BorderSizePixel = 0

    -- hover state tracking
    local isHovering = false
    b.MouseEnter:Connect(function() isHovering = true end)
    b.MouseLeave:Connect(function() isHovering = false end)

    return b, ws, wrap, function() return isHovering end
end

-- Create buttons and get their components
local b1, s1, wrap1, hover1 = btn("Freeze Trade", 50)
local b2, s2, wrap2, hover2 = btn("Force Accept", 114)

-- Toggle states
local b1_toggled = false
local b2_toggled = false

b1.MouseButton1Click:Connect(function() 
    b1_toggled = not b1_toggled
end)

b2.MouseButton1Click:Connect(function() 
    b2_toggled = not b2_toggled
end)

-- animate
local t = 0
rs.Heartbeat:Connect(function(dt)
    t = t + dt
    local s  = math.sin(t*1.6)*0.5+0.5
    local s2v = math.sin(t*1.6+2)*0.5+0.5
    
    local pulseColor = Color3.fromRGB(math.floor(s*55),math.floor(s*55),math.floor(s*55))
    stroke.Color = pulseColor
    minStroke.Color = pulseColor 
    
    topglow.BackgroundColor3 = Color3.fromRGB(math.floor(180+s*75),math.floor(180+s*75),255)
    topglow.BackgroundTransparency = 0.4+s*0.4
    
    -- Calculate glowing colors dynamically
    local c1 = Color3.fromRGB(math.floor(50+s*80),math.floor(100+s*80),255)
    local c2 = Color3.fromRGB(0,math.floor(160+s2v*60),math.floor(70+s2v*50))
    
    s1.Color = c1
    s2.Color = c2
    
    -- Update Button 1 Background
    if b1_toggled then
        wrap1.BackgroundColor3 = c1
    else
        wrap1.BackgroundColor3 = hover1() and Color3.fromRGB(14,14,14) or Color3.fromRGB(8,8,8)
    end
    
    -- Update Button 2 Background
    if b2_toggled then
        wrap2.BackgroundColor3 = c2
    else
        wrap2.BackgroundColor3 = hover2() and Color3.fromRGB(14,14,14) or Color3.fromRGB(8,8,8)
    end
end)
