--[[
    SolittaSoftware Admin Commands  v2.0
    Toggle key: RightShift (changeable in Settings)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer
local GUI_NAME = "SolittaAdminPanel"

-- Owners (lowercase usernames)
local Owners = {["99intheforest40"] = true}
local function isOwnerName(n) return Owners[tostring(n):lower()] == true end

-- Remove old GUI
pcall(function()
    local targets = {CoreGui, Player:FindFirstChildOfClass("PlayerGui")}
    if gethui then table.insert(targets, gethui()) end
    for _, p in ipairs(targets) do
        local old = p and p:FindFirstChild(GUI_NAME)
        if old then old:Destroy() end
    end
end)

-- ═══════════════ SETTINGS (saved) ═══════════════
local SAVE_FILE = "SolittaAdmin_Settings.json"
local Settings = {BgImage = "", Glass = 0.35, Dim = 0.55, Accent = 1, Particles = true, Border = true, Key = "RightShift"}
pcall(function()
    if isfile and isfile(SAVE_FILE) then
        local data = HttpService:JSONDecode(readfile(SAVE_FILE))
        for k, v in pairs(data) do if Settings[k] ~= nil then Settings[k] = v end end
    end
end)
local function saveSettings()
    pcall(function() if writefile then writefile(SAVE_FILE, HttpService:JSONEncode(Settings)) end end)
end
local saveQueued = false
local function queueSave()
    if saveQueued then return end
    saveQueued = true
    task.delay(0.6, function() saveQueued = false saveSettings() end)
end

-- ═══════════════ THEME ═══════════════
local AccentPresets = {
    {name = "Violet",  a = Color3.fromRGB(138, 92, 255), b = Color3.fromRGB(70, 160, 255)},
    {name = "Crimson", a = Color3.fromRGB(255, 80, 110), b = Color3.fromRGB(255, 160, 70)},
    {name = "Emerald", a = Color3.fromRGB(60, 220, 140), b = Color3.fromRGB(60, 190, 255)},
    {name = "Sakura",  a = Color3.fromRGB(255, 110, 200), b = Color3.fromRGB(150, 100, 255)},
    {name = "Gold",    a = Color3.fromRGB(255, 205, 70),  b = Color3.fromRGB(255, 110, 60)},
}
local startPreset = AccentPresets[Settings.Accent] or AccentPresets[1]
local Theme = {
    Bg = Color3.fromRGB(10, 10, 16), Panel = Color3.fromRGB(16, 16, 26), Panel2 = Color3.fromRGB(24, 24, 38),
    Stroke = Color3.fromRGB(52, 52, 78), Accent = startPreset.a, Accent2 = startPreset.b,
    Text = Color3.fromRGB(240, 240, 250), SubText = Color3.fromRGB(150, 150, 178),
    Green = Color3.fromRGB(80, 230, 140), Red = Color3.fromRGB(255, 90, 100), Yellow = Color3.fromRGB(255, 205, 90),
}

-- ═══════════════ HELPERS ═══════════════
local function make(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do inst[k] = v end
    for _, c in ipairs(children or {}) do c.Parent = inst end
    return inst
end
local function corner(r) return make("UICorner", {CornerRadius = UDim.new(0, r)}) end
local function stroke(c, t, tr)
    return make("UIStroke", {Color = c or Theme.Stroke, Thickness = t or 1, Transparency = tr or 0.35, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
end
local function esc(s) return (tostring(s):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")) end
local function colored(text, color) return string.format('<font color="#%s">%s</font>', color:ToHex(), text) end
local function tween(o, t, props, style, dir)
    local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end

local conns = {}
local function bind(sig, fn)
    local c = sig:Connect(fn)
    table.insert(conns, c)
    return c
end
local cleanups = {}

-- Glass (transparency) registry
local glassObjs = {}
local function glass(inst, off)
    off = off or 0
    table.insert(glassObjs, {inst, off})
    inst.BackgroundTransparency = math.clamp(Settings.Glass + off, 0, 1)
    return inst
end
local function applyGlass()
    for _, g in ipairs(glassObjs) do
        if g[1].Parent then g[1].BackgroundTransparency = math.clamp(Settings.Glass + g[2], 0, 1) end
    end
end

-- Accent registry
local accentGradients, accentCallbacks = {}, {}
local function accentGrad(parent, rot)
    local g = make("UIGradient", {Color = ColorSequence.new(Theme.Accent, Theme.Accent2), Rotation = rot or 0, Parent = parent})
    table.insert(accentGradients, g)
    return g
end
local function onAccent(fn) fn() table.insert(accentCallbacks, fn) end
local function applyAccent(i)
    local p = AccentPresets[i] or AccentPresets[1]
    Theme.Accent, Theme.Accent2 = p.a, p.b
    for _, g in ipairs(accentGradients) do
        if g.Parent then g.Color = ColorSequence.new(Theme.Accent, Theme.Accent2) end
    end
    for _, fn in ipairs(accentCallbacks) do pcall(fn) end
end

local function hoverable(btn, base, hover, grow)
    local function val(v) if typeof(v) == "function" then return v() end return v end
    local sc = btn:FindFirstChildOfClass("UIScale") or make("UIScale", {Parent = btn})
    grow = grow or 1.03
    btn.MouseEnter:Connect(function()
        tween(btn, 0.18, {BackgroundColor3 = val(hover)})
        tween(sc, 0.22, {Scale = grow}, Enum.EasingStyle.Back)
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, 0.18, {BackgroundColor3 = val(base)})
        tween(sc, 0.18, {Scale = 1})
    end)
    if btn:IsA("GuiButton") then
        btn.MouseButton1Down:Connect(function() tween(sc, 0.08, {Scale = grow * 0.94}) end)
        btn.MouseButton1Up:Connect(function() tween(sc, 0.14, {Scale = grow}, Enum.EasingStyle.Back) end)
    end
end

local ToggleKey = Enum.KeyCode.RightShift
pcall(function() ToggleKey = Enum.KeyCode[Settings.Key] or Enum.KeyCode.RightShift end)
local listeningForKey = false
local HintLabel

-- Forward declarations
local setBackground, playWelcome
local log, info, success, fail
local Commands = {}
local function addCmd(name, usage, desc, fn) Commands[name] = {usage = usage, desc = desc, fn = fn} end

-- ═══════════════ ROOT GUI ═══════════════
local Gui = make("ScreenGui", {
    Name = GUI_NAME, ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true,
})
local parented = pcall(function() Gui.Parent = (gethui and gethui()) or CoreGui end)
if not parented or not Gui.Parent then Gui.Parent = Player:WaitForChild("PlayerGui") end

local function calcScale()
    local cam = workspace.CurrentCamera
    local vs = cam and cam.ViewportSize or Vector2.new(1280, 720)
    return math.clamp(math.min(vs.X / 880, vs.Y / 560), 0.45, 1)
end

local Main = make("Frame", {
    Name = "Main", Size = UDim2.fromOffset(800, 480), Position = UDim2.fromScale(0.5, 0.5),
    AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Theme.Bg, BorderSizePixel = 0, Parent = Gui,
}, {corner(14)})
glass(Main, 0)
local Scale = make("UIScale", {Scale = 0, Parent = Main})

local MainStroke = stroke(Color3.new(1, 1, 1), 1.6, 0.15)
MainStroke.Parent = Main
local BorderGrad = accentGrad(MainStroke, 0)

-- Background image layers
local BgImage = make("ImageLabel", {
    Name = "Background", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Crop,
    ImageTransparency = 1, Visible = false, ZIndex = 0, Parent = Main,
}, {corner(14)})
local Dim = make("Frame", {
    Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1 - Settings.Dim,
    BorderSizePixel = 0, Visible = false, ZIndex = 0, Parent = Main,
}, {corner(14)})

-- Floating particles
local ParticleHolder = make("Frame", {
    Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 0, Parent = Main,
})
for _ = 1, 24 do
    task.spawn(function()
        local size = math.random(2, 5)
        local p = make("Frame", {
            Size = UDim2.fromOffset(size, size), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1,
            BorderSizePixel = 0, ZIndex = 0, Parent = ParticleHolder,
        }, {corner(8)})
        task.wait(math.random() * 5)
        while Gui.Parent do
            if Settings.Particles and Main.Visible then
                local x = math.random()
                local dur = math.random(7, 13)
                p.Position = UDim2.new(x, 0, 1, 10)
                p.BackgroundColor3 = (math.random() < 0.5) and Theme.Accent or Theme.Accent2
                p.BackgroundTransparency = 0.55
                local tw = tween(p, dur, {Position = UDim2.new(math.clamp(x + (math.random() - 0.5) * 0.2, 0, 1), 0, 0, -10), BackgroundTransparency = 1}, Enum.EasingStyle.Linear)
                tw.Completed:Wait()
            else
                p.BackgroundTransparency = 1
                task.wait(0.5)
            end
        end
    end)
end

-- Animated border
bind(RunService.Heartbeat, function(dt)
    if Settings.Border and Main.Visible then BorderGrad.Rotation = (BorderGrad.Rotation + dt * 55) % 360 end
end)

-- ═══════════════ TOP BAR ═══════════════
local TopBar = make("Frame", {Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1, Active = true, Parent = Main})
local TopLine = make("Frame", {
    Size = UDim2.new(1, -28, 0, 1), Position = UDim2.new(0, 14, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1),
    BackgroundTransparency = 0.55, BorderSizePixel = 0, Parent = TopBar,
})
accentGrad(TopLine, 0)

local TitleLbl = make("TextLabel", {
    Size = UDim2.new(0, 360, 1, 0), Position = UDim2.fromOffset(18, 0), BackgroundTransparency = 1,
    Text = "◆  SolittaSoftware Admin Commands", TextXAlignment = Enum.TextXAlignment.Left,
    Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = Color3.new(1, 1, 1), Parent = TopBar,
})
local TitleGrad = make("UIGradient", {Parent = TitleLbl})
onAccent(function()
    TitleGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.Accent), ColorSequenceKeypoint.new(0.5, Theme.Accent2), ColorSequenceKeypoint.new(1, Theme.Accent),
    })
end)
TitleGrad.Offset = Vector2.new(-0.5, 0)
TweenService:Create(TitleGrad, TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Offset = Vector2.new(0.5, 0)}):Play()

local function topButton(txt, xOff, color)
    local b = make("TextButton", {
        Size = UDim2.fromOffset(30, 30), Position = UDim2.new(1, xOff, 0.5, -15), BackgroundColor3 = Theme.Panel2,
        Text = txt, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = color, AutoButtonColor = false, Parent = TopBar,
    }, {corner(9), stroke()})
    glass(b, 0.2)
    hoverable(b, Theme.Panel2, Theme.Stroke, 1.1)
    return b
end
local CloseBtn = topButton("✕", -44, Theme.Red)
local MinBtn = topButton("–", -80, Theme.Yellow)

-- Dragging
do
    local dragging, dragStart, startPos
    TopBar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, i.Position, Main.Position
            i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    bind(UserInputService.InputChanged, function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dragStart
            Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

-- ═══════════════ SIDEBAR / TABS ═══════════════
local Sidebar = make("Frame", {
    Size = UDim2.new(0, 178, 1, -66), Position = UDim2.fromOffset(10, 56), BackgroundColor3 = Theme.Panel, BorderSizePixel = 0, Parent = Main,
}, {corner(12), stroke()})
glass(Sidebar, 0.1)

make("TextLabel", {
    Size = UDim2.new(1, -20, 0, 18), Position = UDim2.fromOffset(14, 10), BackgroundTransparency = 1, Text = "CATEGORIES",
    Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left, Parent = Sidebar,
})

local TAB_H, TAB_GAP, TAB_Y0 = 38, 6, 34
local function tabY(order) return TAB_Y0 + (order - 1) * (TAB_H + TAB_GAP) end
local Pill = make("Frame", {
    Size = UDim2.new(1, -16, 0, TAB_H), Position = UDim2.fromOffset(8, tabY(1)), BackgroundColor3 = Color3.new(1, 1, 1),
    BackgroundTransparency = 0.8, BorderSizePixel = 0, Parent = Sidebar,
}, {corner(9)})
accentGrad(Pill, 0)
local PillBar = make("Frame", {
    Size = UDim2.new(0, 3, 0.56, 0), Position = UDim2.new(0, 4, 0.22, 0), BackgroundColor3 = Color3.new(1, 1, 1),
    BorderSizePixel = 0, Parent = Pill,
}, {corner(2)})
accentGrad(PillBar, 90)

-- Mini profile
do
    local prof = make("Frame", {
        Size = UDim2.new(1, -16, 0, 50), Position = UDim2.new(0, 8, 1, -78), BackgroundColor3 = Theme.Panel2, BorderSizePixel = 0, Parent = Sidebar,
    }, {corner(10), stroke()})
    glass(prof, 0.2)
    local av = make("ImageLabel", {
        Size = UDim2.fromOffset(34, 34), Position = UDim2.fromOffset(8, 8), BackgroundColor3 = Theme.Bg, BorderSizePixel = 0, Parent = prof,
    }, {corner(17)})
    task.spawn(function()
        local ok, img = pcall(function()
            return Players:GetUserThumbnailAsync(Player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        end)
        if ok then av.Image = img end
    end)
    make("TextLabel", {
        Size = UDim2.new(1, -54, 0, 16), Position = UDim2.fromOffset(48, 9), BackgroundTransparency = 1, Text = Player.Name,
        Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, Parent = prof,
    })
    make("TextLabel", {
        Size = UDim2.new(1, -54, 0, 14), Position = UDim2.fromOffset(48, 26), BackgroundTransparency = 1, Text = isOwnerName(Player.Name) and "👑 OWNER" or "● Online",
        Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = isOwnerName(Player.Name) and Theme.Yellow or Theme.Green, TextXAlignment = Enum.TextXAlignment.Left, Parent = prof,
    })
    HintLabel = make("TextLabel", {
        Size = UDim2.new(1, -16, 0, 14), Position = UDim2.new(0, 8, 1, -22), BackgroundTransparency = 1,
        Text = "v2.0  •  [" .. ToggleKey.Name .. "] Toggle", Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = Theme.SubText, Parent = Sidebar,
    })
end

local Content = make("Frame", {
    Size = UDim2.new(1, -208, 1, -66), Position = UDim2.fromOffset(198, 56), BackgroundTransparency = 1, Parent = Main,
})

local Pages, Tabs, currentTab = {}, {}, nil
local function newPage(name)
    local p = make("CanvasGroup", {
        Name = name, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Panel, BorderSizePixel = 0, Visible = false, Parent = Content,
    }, {corner(12), stroke()})
    glass(p, 0.05)
    Pages[name] = p
    return p
end

local function selectTab(name)
    if currentTab == name then return end
    currentTab = name
    for n, page in pairs(Pages) do if n ~= name then page.Visible = false end end
    local page = Pages[name]
    page.Position = UDim2.fromOffset(0, 18)
    page.GroupTransparency = 1
    page.Visible = true
    tween(page, 0.4, {GroupTransparency = 0, Position = UDim2.fromOffset(0, 0)}, Enum.EasingStyle.Quint)
    for n, t in pairs(Tabs) do
        tween(t.Label, 0.25, {TextColor3 = (n == name) and Theme.Text or Theme.SubText})
        tween(t.Btn, 0.2, {BackgroundTransparency = 1})
    end
    tween(Pill, 0.45, {Position = UDim2.fromOffset(8, tabY(Tabs[name].Order))}, Enum.EasingStyle.Quint)
    if name == "Welcome" and playWelcome then playWelcome() end
end

local function newTab(name, icon, order)
    local btn = make("TextButton", {
        Size = UDim2.new(1, -16, 0, TAB_H), Position = UDim2.fromOffset(8, tabY(order)), BackgroundColor3 = Theme.Panel2,
        BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = Sidebar,
    }, {corner(9)})
    local lbl = make("TextLabel", {
        Size = UDim2.new(1, -20, 1, 0), Position = UDim2.fromOffset(18, 0), BackgroundTransparency = 1,
        Text = icon .. "   " .. name, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = Theme.SubText,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = btn,
    })
    Tabs[name] = {Btn = btn, Label = lbl, Order = order}
    btn.MouseButton1Click:Connect(function() selectTab(name) end)
    btn.MouseEnter:Connect(function()
        if currentTab ~= name then
            tween(btn, 0.15, {BackgroundTransparency = 0.6})
            tween(lbl, 0.15, {Position = UDim2.fromOffset(24, 0)})
        end
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, 0.15, {BackgroundTransparency = 1})
        tween(lbl, 0.2, {Position = UDim2.fromOffset(18, 0)})
    end)
end

-- ═══════════════ WELCOME ═══════════════
do
    local Page = newPage("Welcome")
    newTab("Welcome", "⌂", 1)

    local CharCard = make("Frame", {
        Size = UDim2.new(0, 200, 1, -24), Position = UDim2.fromOffset(12, 12), BackgroundColor3 = Theme.Bg, BorderSizePixel = 0, Parent = Page,
    }, {corner(12)})
    glass(CharCard, 0.2)
    local cardStroke = stroke(Theme.Accent, 1.4, 0.2)
    cardStroke.Parent = CharCard
    onAccent(function() cardStroke.Color = Theme.Accent end)

    -- Hover discs (floating platform)
    local discBig = make("Frame", {
        Size = UDim2.new(0.86, 0, 0, 34), Position = UDim2.fromScale(0.5, 0.93), AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.82, BorderSizePixel = 0, Parent = CharCard,
    }, {corner(30)})
    accentGrad(discBig, 0)
    local disc = make("Frame", {
        Size = UDim2.new(0.58, 0, 0, 20), Position = UDim2.fromScale(0.5, 0.93), AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.35, BorderSizePixel = 0, Parent = CharCard,
    }, {corner(30)})
    accentGrad(disc, 0)
    local pulse = TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
    TweenService:Create(disc, pulse, {BackgroundTransparency = 0.7, Size = UDim2.new(0.44, 0, 0, 14)}):Play()
    TweenService:Create(discBig, pulse, {BackgroundTransparency = 0.92, Size = UDim2.new(0.98, 0, 0, 40)}):Play()

    local Viewport = make("ViewportFrame", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Ambient = Color3.fromRGB(190, 190, 215),
        LightColor = Color3.new(1, 1, 1), LightDirection = Vector3.new(-0.4, -0.6, 0.8), Parent = CharCard,
    })
    local VCam = make("Camera", {Parent = Viewport})
    Viewport.CurrentCamera = VCam
    local WorldModel = make("WorldModel", {Parent = Viewport})
    local Thumb = make("ImageLabel", {
        Size = UDim2.fromScale(0.85, 0.85), Position = UDim2.fromScale(0.075, 0.05), BackgroundTransparency = 1, Visible = false, Parent = CharCard,
    })
    task.spawn(function()
        local ok, img = pcall(function()
            return Players:GetUserThumbnailAsync(Player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
        end)
        if ok then Thumb.Image = img end
    end)

    -- Online chip
    local chip = make("Frame", {
        Size = UDim2.fromOffset(76, 22), Position = UDim2.fromOffset(10, 10), BackgroundColor3 = Theme.Panel2, BorderSizePixel = 0, Parent = CharCard,
    }, {corner(11), stroke()})
    glass(chip, 0.2)
    local dot = make("Frame", {
        Size = UDim2.fromOffset(8, 8), Position = UDim2.fromOffset(9, 7), BackgroundColor3 = Theme.Green, BorderSizePixel = 0, Parent = chip,
    }, {corner(4)})
    TweenService:Create(dot, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {BackgroundTransparency = 0.7}):Play()
    make("TextLabel", {
        Size = UDim2.new(1, -24, 1, 0), Position = UDim2.fromOffset(22, 0), BackgroundTransparency = 1, Text = isOwnerName(Player.Name) and "OWNER" or "LIVE",
        Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = chip,
    })

    local vpClone, vpRoot
    local vpAngle, vpTime = 0, 0
    local function buildViewport()
        pcall(function() if vpClone then vpClone:Destroy() end end)
        vpClone, vpRoot = nil, nil
        local char = Player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        local ok = pcall(function()
            char.Archivable = true
            vpClone = char:Clone()
            for _, d in ipairs(vpClone:GetDescendants()) do
                if d:IsA("Script") or d:IsA("LocalScript") then d:Destroy() end
            end
            local h = vpClone:FindFirstChildOfClass("Humanoid")
            if h then h.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
            vpClone.Parent = WorldModel
            vpRoot = vpClone:FindFirstChild("HumanoidRootPart")
            vpRoot.Anchored = true
            vpClone:PivotTo(CFrame.new(0, 0, 0))
            VCam.CFrame = CFrame.new(Vector3.new(0, 0.4, -10.5), Vector3.new(0, 0.1, 0))
            VCam.FieldOfView = 40
        end)
        Thumb.Visible = not (ok and vpClone ~= nil)
    end
    buildViewport()
    bind(Player.CharacterAdded, function() task.wait(1) buildViewport() end)

    bind(RunService.RenderStepped, function(dt)
        if vpClone and vpRoot and Page.Visible and Main.Visible then
            vpAngle += dt * 0.9
            vpTime += dt
            pcall(function()
                vpClone:PivotTo(CFrame.new(0, math.sin(vpTime * 2.2) * 0.28, 0) * CFrame.Angles(0, vpAngle, 0))
            end)
        end
    end)

    -- Right side
    local Right = make("Frame", {
        Size = UDim2.new(1, -236, 1, -24), Position = UDim2.fromOffset(224, 12), BackgroundTransparency = 1, Parent = Page,
    })
    make("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Text = "SOLITTASOFTWARE  •  ADMIN COMMANDS",
        Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left, Parent = Right,
    })
    local WelcomeLbl = make("TextLabel", {
        Size = UDim2.new(1, 0, 0, 44), Position = UDim2.fromOffset(0, 26), BackgroundTransparency = 1, Text = "",
        Font = Enum.Font.GothamBold, TextSize = 36, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = Right,
    })
    local NameLbl = make("TextLabel", {
        Size = UDim2.new(1, 0, 0, 44), Position = UDim2.fromOffset(0, 66), BackgroundTransparency = 1, Text = "",
        Font = Enum.Font.GothamBold, TextSize = 36, TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, Parent = Right,
    })
    accentGrad(NameLbl, 0)
    make("TextLabel", {
        Size = UDim2.new(1, 0, 0, 36), Position = UDim2.fromOffset(0, 116), BackgroundTransparency = 1, TextWrapped = true,
        Text = "Open the Terminal tab and start typing commands. Type 'help' to see everything available.",
        Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top, Parent = Right,
    })

    local welcomeToken = 0
    playWelcome = function()
        welcomeToken += 1
        local tok = welcomeToken
        WelcomeLbl.Text, NameLbl.Text = "", ""
        task.spawn(function()
            local t1, t2 = "Welcome,", Player.Name
            for i = 1, #t1 do
                if tok ~= welcomeToken then return end
                WelcomeLbl.Text = t1:sub(1, i)
                task.wait(0.035)
            end
            for i = 1, #t2 do
                if tok ~= welcomeToken then return end
                NameLbl.Text = t2:sub(1, i) .. "_"
                task.wait(0.045)
            end
            NameLbl.Text = t2
        end)
    end

    local Cards = make("Frame", {
        Size = UDim2.new(1, 0, 0, 176), Position = UDim2.fromOffset(0, 168), BackgroundTransparency = 1, Parent = Right,
    }, {make("UIGridLayout", {CellSize = UDim2.new(0.5, -5, 0, 52), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder})})

    local function infoCard(title, value, order)
        local c = make("Frame", {BackgroundColor3 = Theme.Panel2, BorderSizePixel = 0, LayoutOrder = order, Parent = Cards}, {corner(10)})
        glass(c, 0.15)
        local st = stroke()
        st.Parent = c
        make("TextLabel", {
            Size = UDim2.new(1, -16, 0, 14), Position = UDim2.fromOffset(12, 8), BackgroundTransparency = 1, Text = title,
            Font = Enum.Font.GothamMedium, TextSize = 10, TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left, Parent = c,
        })
        local v = make("TextLabel", {
            Size = UDim2.new(1, -16, 0, 20), Position = UDim2.fromOffset(12, 24), BackgroundTransparency = 1, Text = tostring(value),
            Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd, Parent = c,
        })
        c.MouseEnter:Connect(function() tween(st, 0.2, {Color = Theme.Accent, Transparency = 0}) end)
        c.MouseLeave:Connect(function() tween(st, 0.2, {Color = Theme.Stroke, Transparency = 0.35}) end)
        return v
    end

    local execName = "Unknown"
    pcall(function() if identifyexecutor then execName = (identifyexecutor()) end end)
    infoCard("DISPLAY NAME", Player.DisplayName, 1)
    infoCard("USER ID", Player.UserId, 2)
    infoCard("EXECUTOR", execName, 3)
    local fpsLabel = infoCard("FPS", "...", 4)
    infoCard("ACCOUNT AGE", Player.AccountAge .. " days", 5)
    local plrLabel = infoCard("PLAYERS", #Players:GetPlayers() .. "/" .. Players.MaxPlayers, 6)

    local frames, last = 0, tick()
    bind(RunService.RenderStepped, function()
        frames += 1
        if tick() - last >= 1 then
            fpsLabel.Text = tostring(frames)
            plrLabel.Text = #Players:GetPlayers() .. "/" .. Players.MaxPlayers
            frames, last = 0, tick()
        end
    end)
end

-- ═══════════════ TERMINAL ═══════════════
local Output, Input
do
    local Page = newPage("Terminal")
    newTab("Terminal", ">_", 2)

    local TermTop = make("Frame", {Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, Parent = Page})
    make("Frame", {
        Size = UDim2.new(1, -20, 0, 1), Position = UDim2.new(0, 10, 1, 0), BackgroundColor3 = Theme.Stroke, BackgroundTransparency = 0.5,
        BorderSizePixel = 0, Parent = TermTop,
    })
    for i, c in ipairs({Theme.Red, Theme.Yellow, Theme.Green}) do
        make("Frame", {
            Size = UDim2.fromOffset(10, 10), Position = UDim2.fromOffset(12 + (i - 1) * 16, 11), BackgroundColor3 = c, BorderSizePixel = 0, Parent = TermTop,
        }, {corner(5)})
    end
    make("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = Player.Name .. "@solitta: ~", Font = Enum.Font.Code,
        TextSize = 12, TextColor3 = Theme.SubText, Parent = TermTop,
    })

    Output = make("ScrollingFrame", {
        Size = UDim2.new(1, -16, 1, -86), Position = UDim2.fromOffset(8, 38), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Accent, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = Page,
    }, {
        make("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}),
        make("UIPadding", {PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 6)}),
    })
    onAccent(function() Output.ScrollBarImageColor3 = Theme.Accent end)

    local InputBar = make("Frame", {
        Size = UDim2.new(1, -16, 0, 36), Position = UDim2.new(0, 8, 1, -44), BackgroundColor3 = Theme.Bg, BorderSizePixel = 0, Parent = Page,
    }, {corner(10)})
    glass(InputBar, 0.1)
    local barStroke = stroke(Theme.Accent, 1.2, 0.2)
    barStroke.Parent = InputBar
    onAccent(function() barStroke.Color = Theme.Accent end)

    local PromptLabel = make("TextLabel", {
        Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, Position = UDim2.fromOffset(12, 0), BackgroundTransparency = 1,
        RichText = true, Text = "", Font = Enum.Font.Code, TextSize = 14, Parent = InputBar,
    })
    onAccent(function()
        PromptLabel.Text = (isOwnerName(Player.Name) and colored("[OWNER] ", Theme.Yellow) or "")
            .. colored(esc(Player.Name), Theme.Green) .. " " .. colored("~#", Theme.Accent)
    end)
    Input = make("TextBox", {
        Size = UDim2.new(1, -20, 1, 0), BackgroundTransparency = 1, Text = "", PlaceholderText = "type a command... (help)",
        PlaceholderColor3 = Theme.SubText, Font = Enum.Font.Code, TextSize = 14, TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, Parent = InputBar,
    })
    local function layoutInput()
        local w = PromptLabel.AbsoluteSize.X / math.max(Scale.Scale, 0.01)
        Input.Position = UDim2.fromOffset(w + 20, 0)
        Input.Size = UDim2.new(1, -(w + 30), 1, 0)
    end
    PromptLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutInput)
    task.delay(0.6, layoutInput)

    local lineOrder = 0
    log = function(text, color, raw)
        lineOrder += 1
        local l = make("TextLabel", {
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, RichText = true,
            Text = raw and text or colored(esc(text), color or Theme.Text), TextWrapped = true, Font = Enum.Font.Code, TextSize = 13,
            TextColor3 = Theme.Text, TextTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = lineOrder, Parent = Output,
        })
        tween(l, 0.3, {TextTransparency = 0})
        task.delay(0.06, function() Output.CanvasPosition = Vector2.new(0, 1e6) end)
        return l
    end
    info = function(t) log(t, Theme.Accent2) end
    success = function(t) log("✔ " .. t, Theme.Green) end
    fail = function(t) log("✖ " .. t, Theme.Red) end

    -- ───────── COMMANDS ─────────
    local function getHum() local c = Player.Character return c and c:FindFirstChildOfClass("Humanoid") end
    local function getRoot() local c = Player.Character return c and c:FindFirstChild("HumanoidRootPart") end

    -- Fly
    local flying, flySpeed, flyConn, flyBV, flyBG = false, 60, nil, nil, nil
    local function stopFly()
        flying = false
        if flyConn then flyConn:Disconnect() flyConn = nil end
        if flyBV then flyBV:Destroy() flyBV = nil end
        if flyBG then flyBG:Destroy() flyBG = nil end
        local h = getHum()
        if h then h.PlatformStand = false end
    end
    local function startFly()
        local root, hum = getRoot(), getHum()
        if not root or not hum then return false end
        stopFly()
        flying = true
        flyBV = make("BodyVelocity", {MaxForce = Vector3.new(9e9, 9e9, 9e9), Velocity = Vector3.zero, Parent = root})
        flyBG = make("BodyGyro", {MaxTorque = Vector3.new(9e9, 9e9, 9e9), P = 9e4, CFrame = root.CFrame, Parent = root})
        hum.PlatformStand = true
        flyConn = RunService.RenderStepped:Connect(function()
            if not flyBV or not flyBG then return end
            local cam = workspace.CurrentCamera
            local d = Vector3.zero
            if not UserInputService:GetFocusedTextBox() then
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then d += cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then d -= cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then d += cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then d -= cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.E) or UserInputService:IsKeyDown(Enum.KeyCode.Space) then d += Vector3.yAxis end
                if UserInputService:IsKeyDown(Enum.KeyCode.Q) or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then d -= Vector3.yAxis end
            end
            flyBV.Velocity = d.Magnitude > 0 and d.Unit * flySpeed or Vector3.zero
            flyBG.CFrame = cam.CFrame
        end)
        return true
    end

    -- Noclip
    local noclipConn
    local function setNoclip(on)
        if noclipConn then noclipConn:Disconnect() noclipConn = nil end
        if on then
            noclipConn = RunService.Stepped:Connect(function()
                local c = Player.Character
                if c then for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
            end)
        end
    end

    -- Infinite jump
    local infJump = false
    bind(UserInputService.JumpRequest, function()
        if infJump then local h = getHum() if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end
    end)

    -- Fullbright
    local origLight
    local function setFullbright(on)
        if on then
            if not origLight then
                origLight = {Lighting.Brightness, Lighting.ClockTime, Lighting.FogEnd, Lighting.GlobalShadows, Lighting.Ambient}
            end
            Lighting.Brightness, Lighting.ClockTime, Lighting.FogEnd, Lighting.GlobalShadows = 2, 14, 1e6, false
            Lighting.Ambient = Color3.fromRGB(180, 180, 180)
        elseif origLight then
            Lighting.Brightness, Lighting.ClockTime, Lighting.FogEnd, Lighting.GlobalShadows, Lighting.Ambient = table.unpack(origLight)
            origLight = nil
        end
    end

    table.insert(cleanups, function() stopFly() setNoclip(false) infJump = false setFullbright(false) end)

    local function findPlayer(name)
        name = name:lower()
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name:lower():sub(1, #name) == name or p.DisplayName:lower():sub(1, #name) == name then return p end
        end
    end

    addCmd("help", "help", "Lists all commands", function()
        info("── COMMANDS ──")
        local names = {}
        for n in pairs(Commands) do table.insert(names, n) end
        table.sort(names)
        for _, n in ipairs(names) do
            log(colored(esc(Commands[n].usage), Theme.Yellow) .. colored("  —  " .. esc(Commands[n].desc), Theme.SubText), nil, true)
        end
    end)
    addCmd("clear", "clear", "Clears the terminal", function()
        for _, c in ipairs(Output:GetChildren()) do if c:IsA("TextLabel") then c:Destroy() end end
    end)
    addCmd("fly", "fly [speed]", "Enable flight (WASD, E/Q or Space/Ctrl)", function(a)
        if a[1] and tonumber(a[1]) then flySpeed = tonumber(a[1]) end
        if startFly() then success("Fly enabled (speed: " .. flySpeed .. ")") else fail("Character not found") end
    end)
    addCmd("unfly", "unfly", "Disable flight", function() stopFly() success("Fly disabled") end)
    addCmd("flyspeed", "flyspeed <number>", "Set flight speed", function(a)
        local n = tonumber(a[1]) if not n then return fail("Usage: flyspeed <number>") end
        flySpeed = n success("Fly speed: " .. n)
    end)
    addCmd("speed", "speed <number>", "Set walk speed", function(a)
        local n, h = tonumber(a[1]), getHum()
        if not n then return fail("Usage: speed <number>") end
        if h then h.WalkSpeed = n success("WalkSpeed = " .. n) end
    end)
    addCmd("jump", "jump <number>", "Set jump power", function(a)
        local n, h = tonumber(a[1]), getHum()
        if not n then return fail("Usage: jump <number>") end
        if h then h.UseJumpPower = true h.JumpPower = n success("JumpPower = " .. n) end
    end)
    addCmd("noclip", "noclip", "Walk through walls", function() setNoclip(true) success("Noclip enabled") end)
    addCmd("clip", "clip", "Disable noclip", function() setNoclip(false) success("Noclip disabled") end)
    addCmd("infjump", "infjump", "Infinite jump", function() infJump = true success("InfJump enabled") end)
    addCmd("uninfjump", "uninfjump", "Disable infinite jump", function() infJump = false success("InfJump disabled") end)
    addCmd("fov", "fov <number>", "Set camera field of view", function(a)
        local n = tonumber(a[1]) if not n then return fail("Usage: fov <number>") end
        workspace.CurrentCamera.FieldOfView = n success("FOV = " .. n)
    end)
    addCmd("gravity", "gravity <number>", "Set workspace gravity", function(a)
        local n = tonumber(a[1]) if not n then return fail("Usage: gravity <number>") end
        workspace.Gravity = n success("Gravity = " .. n)
    end)
    addCmd("time", "time <0-24>", "Set the time of day", function(a)
        local n = tonumber(a[1]) if not n then return fail("Usage: time <0-24>") end
        Lighting.ClockTime = n success("ClockTime = " .. n)
    end)
    addCmd("fullbright", "fullbright", "Remove darkness and fog", function() setFullbright(true) success("Fullbright enabled") end)
    addCmd("unfullbright", "unfullbright", "Restore lighting", function() setFullbright(false) success("Lighting restored") end)
    addCmd("goto", "goto <player>", "Teleport to a player", function(a)
        local t = a[1] and findPlayer(a[1])
        if not t then return fail("Player not found") end
        local r, tr = getRoot(), t.Character and t.Character:FindFirstChild("HumanoidRootPart")
        if r and tr then r.CFrame = tr.CFrame * CFrame.new(0, 0, 3) success("Teleported to " .. t.Name) else fail("Character missing") end
    end)
    addCmd("view", "view <player>", "Spectate a player", function(a)
        local t = a[1] and findPlayer(a[1])
        local h = t and t.Character and t.Character:FindFirstChildOfClass("Humanoid")
        if not h then return fail("Player not found") end
        workspace.CurrentCamera.CameraSubject = h success("Viewing " .. t.Name)
    end)
    addCmd("unview", "unview", "Stop spectating", function()
        local h = getHum()
        if h then workspace.CurrentCamera.CameraSubject = h end
        success("Camera restored")
    end)
    addCmd("players", "players", "List all players", function()
        for _, p in ipairs(Players:GetPlayers()) do log("• " .. p.Name .. " (" .. p.DisplayName .. ")", Theme.Text) end
    end)
    addCmd("bg", "bg <id|url|file>", "Set panel background image (empty = remove)", function(a)
        setBackground(table.concat(a, " "))
    end)
    addCmd("glass", "glass <0-0.9>", "Set window transparency", function(a)
        local n = tonumber(a[1]) if not n then return fail("Usage: glass <0-0.9>") end
        Settings.Glass = math.clamp(n, 0, 0.9) applyGlass() queueSave() success("Transparency = " .. Settings.Glass)
    end)
    addCmd("reset", "reset", "Reset your character", function() local h = getHum() if h then h.Health = 0 end success("Character reset") end)
    addCmd("rejoin", "rejoin", "Rejoin the current server", function()
        success("Rejoining...")
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
    end)

    -- ───────── EXTRA COMMANDS ─────────
    -- TPWalk
    local tpwalking = false
    addCmd("tpwalk", "tpwalk [speed]", "Speed boost by teleport walking (harder to detect)", function(a)
        local s = tonumber(a[1]) or 1
        tpwalking = false
        task.wait()
        tpwalking = true
        task.spawn(function()
            while tpwalking do
                local dt = RunService.Heartbeat:Wait()
                local h, c = getHum(), Player.Character
                if h and c and h.MoveDirection.Magnitude > 0 then
                    c:TranslateBy(h.MoveDirection * s * dt * 10)
                end
            end
        end)
        success("TPWalk enabled (" .. s .. ")")
    end)
    addCmd("untpwalk", "untpwalk", "Disable TPWalk", function() tpwalking = false success("TPWalk disabled") end)

    -- Spin
    addCmd("spin", "spin [speed]", "Spin your character", function(a)
        local r = getRoot()
        if not r then return fail("Character not found") end
        local old = r:FindFirstChild("SolittaSpin")
        if old then old:Destroy() end
        make("BodyAngularVelocity", {
            Name = "SolittaSpin", MaxTorque = Vector3.new(0, 9e9, 0),
            AngularVelocity = Vector3.new(0, tonumber(a[1]) or 10, 0), Parent = r,
        })
        success("Spinning")
    end)
    addCmd("unspin", "unspin", "Stop spinning", function()
        local r = getRoot()
        local s = r and r:FindFirstChild("SolittaSpin")
        if s then s:Destroy() end
        success("Spin stopped")
    end)

    -- Freeze
    addCmd("freeze", "freeze", "Freeze your character in place", function()
        local c = Player.Character
        if not c then return fail("Character not found") end
        for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.Anchored = true end end
        success("Frozen")
    end)
    addCmd("unfreeze", "unfreeze", "Unfreeze your character", function()
        local c = Player.Character
        if not c then return fail("Character not found") end
        for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.Anchored = false end end
        success("Unfrozen")
    end)

    -- Airwalk
    local awPart, awConn
    local function stopAirwalk()
        if awConn then awConn:Disconnect() awConn = nil end
        if awPart then awPart:Destroy() awPart = nil end
    end
    addCmd("airwalk", "airwalk", "Walk on air (Space = go up)", function()
        stopAirwalk()
        if not getRoot() then return fail("Character not found") end
        awPart = make("Part", {Size = Vector3.new(7, 2, 7), Transparency = 1, Anchored = true, Parent = workspace})
        awConn = RunService.Heartbeat:Connect(function()
            local r = getRoot()
            if r and awPart then awPart.CFrame = r.CFrame * CFrame.new(0, -4, 0) end
        end)
        success("Airwalk enabled")
    end)
    addCmd("unairwalk", "unairwalk", "Disable airwalk", function() stopAirwalk() success("Airwalk disabled") end)

    -- Click teleport
    addCmd("ctp", "ctp", "Gives a Click Teleport tool", function()
        local tool = make("Tool", {Name = "ClickTP", RequiresHandle = false, Parent = Player.Backpack})
        tool.Activated:Connect(function()
            local r, m = getRoot(), Player:GetMouse()
            if r and m.Hit then r.CFrame = CFrame.new(m.Hit.Position + Vector3.new(0, 3, 0)) end
        end)
        success("ClickTP tool added to your backpack")
    end)

    -- ESP
    local espObjs, espConns = {}, {}
    local function stopESP()
        for _, c in ipairs(espConns) do pcall(function() c:Disconnect() end) end
        for _, o in ipairs(espObjs) do pcall(function() o:Destroy() end) end
        espConns, espObjs = {}, {}
    end
    local function addESP(p)
        if p == Player then return end
        local function apply(char)
            local head = char:WaitForChild("Head", 5)
            if not head then return end
            local hl = make("Highlight", {FillTransparency = 0.7, FillColor = Theme.Accent2, OutlineColor = Theme.Accent, Parent = char})
            local bb = make("BillboardGui", {
                Size = UDim2.fromOffset(110, 30), StudsOffset = Vector3.new(0, 2.5, 0), AlwaysOnTop = true, Adornee = head, Parent = head,
            })
            make("TextLabel", {
                Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = p.DisplayName, Font = Enum.Font.GothamBold,
                TextScaled = true, TextColor3 = Color3.new(1, 1, 1), TextStrokeTransparency = 0, Parent = bb,
            })
            table.insert(espObjs, hl)
            table.insert(espObjs, bb)
        end
        if p.Character then task.spawn(apply, p.Character) end
        table.insert(espConns, p.CharacterAdded:Connect(apply))
    end
    addCmd("esp", "esp", "See players through walls", function()
        stopESP()
        for _, p in ipairs(Players:GetPlayers()) do addESP(p) end
        table.insert(espConns, Players.PlayerAdded:Connect(addESP))
        success("ESP enabled")
    end)
    addCmd("unesp", "unesp", "Disable ESP", function() stopESP() success("ESP disabled") end)

    -- Anti fling
    local antiFling = false
    addCmd("antifling", "antifling", "Stops other players from flinging you", function()
        antiFling = false
        task.wait()
        antiFling = true
        task.spawn(function()
            while antiFling do
                RunService.Stepped:Wait()
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= Player and p.Character then
                        for _, part in ipairs(p.Character:GetChildren()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                                part.AssemblyLinearVelocity = Vector3.zero
                                part.AssemblyAngularVelocity = Vector3.zero
                            end
                        end
                    end
                end
            end
        end)
        success("AntiFling enabled")
    end)
    addCmd("unantifling", "unantifling", "Disable AntiFling", function() antiFling = false success("AntiFling disabled") end)

    -- Anti kick / teleport (client-side hooks)
    addCmd("antikick", "antikick", "Blocks client-side kick attempts", function()
        if not (hookmetamethod and newcclosure and getnamecallmethod) then return fail("Executor does not support hookmetamethod") end
        local old
        old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            if self == Player and getnamecallmethod():lower() == "kick" then return end
            return old(self, ...)
        end))
        success("AntiKick loaded")
    end)
    addCmd("antiteleport", "antiteleport", "Blocks client-side teleport attempts", function()
        if not (hookmetamethod and newcclosure and getnamecallmethod) then return fail("Executor does not support hookmetamethod") end
        local old
        old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            if self == TeleportService then
                local m = getnamecallmethod():lower()
                if m == "teleport" or m == "teleporttoplaceinstance" or m == "teleportasync" then return end
            end
            return old(self, ...)
        end))
        success("AntiTeleport loaded")
    end)

    -- FPS booster
    addCmd("fpsboost", "fpsboost", "Lower graphics for more FPS (can't be undone)", function()
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("BasePart") then
                d.Material = Enum.Material.Plastic
                d.Reflectance = 0
            elseif d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Fire") or d:IsA("Smoke") or d:IsA("Sparkles") then
                d.Enabled = false
            end
        end
        for _, e in ipairs(Lighting:GetChildren()) do if e:IsA("PostEffect") then e.Enabled = false end end
        Lighting.GlobalShadows = false
        success("FPS boost applied")
    end)

    -- Fire interactions
    addCmd("fcd", "fcd", "Fire every ClickDetector in the game", function()
        if not fireclickdetector then return fail("Executor does not support fireclickdetector") end
        local n = 0
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("ClickDetector") then n += 1 pcall(fireclickdetector, d) end
        end
        success("Fired " .. n .. " click detectors")
    end)
    addCmd("fpp", "fpp", "Fire every ProximityPrompt in the game", function()
        if not fireproximityprompt then return fail("Executor does not support fireproximityprompt") end
        local n = 0
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("ProximityPrompt") then n += 1 pcall(fireproximityprompt, d) end
        end
        success("Fired " .. n .. " proximity prompts")
    end)
    addCmd("fti", "fti", "Fire every touch interest in the game", function()
        if not firetouchinterest then return fail("Executor does not support firetouchinterest") end
        local r, n = getRoot(), 0
        if not r then return fail("Character not found") end
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("TouchTransmitter") and d.Parent:IsA("BasePart") then
                n += 1
                pcall(function() firetouchinterest(r, d.Parent, 0) firetouchinterest(r, d.Parent, 1) end)
            end
        end
        success("Fired " .. n .. " touch interests")
    end)

    -- Tools
    addCmd("droptools", "droptools", "Drop every tool in your backpack", function()
        local c = Player.Character
        if not c then return fail("Character not found") end
        for _, t in ipairs(Player.Backpack:GetChildren()) do if t:IsA("Tool") then t.Parent = c end end
        task.wait()
        for _, t in ipairs(c:GetChildren()) do if t:IsA("Tool") then t.Parent = workspace end end
        success("Tools dropped")
    end)
    addCmd("grabtools", "grabtools", "Pick up every dropped tool", function()
        local h = getHum()
        if not h then return fail("Character not found") end
        for _, t in ipairs(workspace:GetChildren()) do if t:IsA("Tool") then h:EquipTool(t) end end
        success("Grabbed dropped tools")
    end)
    addCmd("aat", "aat", "Equip and activate all your tools", function()
        local c = Player.Character
        if not c then return fail("Character not found") end
        for _, t in ipairs(Player.Backpack:GetChildren()) do
            if t:IsA("Tool") then t.Parent = c t:Activate() end
        end
        success("Activated all tools")
    end)

    -- God (local)
    addCmd("god", "god", "Disable touch on nearby parts (kill bricks)", function()
        local r = getRoot()
        if not r then return fail("Character not found") end
        for _, p in ipairs(workspace:GetPartBoundsInRadius(r.Position, 10)) do p.CanTouch = false end
        success("God enabled (nearby parts)")
    end)
    addCmd("ungod", "ungod", "Re-enable touch on nearby parts", function()
        local r = getRoot()
        if not r then return fail("Character not found") end
        for _, p in ipairs(workspace:GetPartBoundsInRadius(r.Position, 10)) do p.CanTouch = true end
        success("God disabled")
    end)

    -- Teleport helpers
    addCmd("tt", "tt <player> [seconds]", "Teleport to a player, then back after a delay", function(a)
        local t = a[1] and findPlayer(a[1])
        local r, tr = getRoot(), t and t.Character and t.Character:FindFirstChild("HumanoidRootPart")
        if not (r and tr) then return fail("Player not found") end
        local back = r.CFrame
        r.CFrame = tr.CFrame
        task.wait(tonumber(a[2]) or 1)
        r.CFrame = back
        success("Returned")
    end)
    addCmd("respawn", "respawn", "Respawn at your current position", function()
        local r = getRoot()
        if not r then return fail("Character not found") end
        local cf = r.CFrame
        getHum().Health = 0
        Player.CharacterAdded:Wait()
        local nr = Player.Character:WaitForChild("HumanoidRootPart")
        task.wait(0.1)
        nr.CFrame = cf
        success("Respawned")
    end)
    addCmd("rejoinre", "rejoinre", "Rejoin and return to the same position", function()
        local q = (syn and syn.queue_on_teleport) or queue_on_teleport
        local r = getRoot()
        if not (q and r) then return fail("Executor does not support queue_on_teleport") end
        local comps = table.concat({r.CFrame:GetComponents()}, ",")
        q("repeat task.wait() until game:IsLoaded() local p=game:GetService('Players').LocalPlayer local c=p.Character or p.CharacterAdded:Wait() c:WaitForChild('HumanoidRootPart').CFrame=CFrame.new(" .. comps .. ")")
        success("Rejoining...")
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
    end)
    addCmd("fixcam", "fixcam", "Fix a broken camera", function()
        local cam = workspace.CurrentCamera
        cam.CameraType = Enum.CameraType.Custom
        local h = getHum()
        if h then cam.CameraSubject = h end
        Player.CameraMode = Enum.CameraMode.Classic
        Player.CameraMinZoomDistance = 0.5
        Player.CameraMaxZoomDistance = 300
        success("Camera fixed")
    end)
    addCmd("chat", "chat <message>", "Send a chat message", function(a)
        local msg = table.concat(a, " ")
        if msg == "" then return fail("Usage: chat <message>") end
        local ok = pcall(function()
            local TCS = game:GetService("TextChatService")
            if TCS.ChatVersion == Enum.ChatVersion.TextChatService then
                TCS.TextChannels.RBXGeneral:SendAsync(msg)
            else
                game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg, "All")
            end
        end)
        if not ok then fail("Could not send message") end
    end)

    table.insert(cleanups, function()
        tpwalking = false
        antiFling = false
        stopAirwalk()
        stopESP()
    end)

    -- ═══════════ MEGA COMMAND PACK ═══════════
    do
        local Stats = game:GetService("Stats")
        local StarterGui = game:GetService("StarterGui")
        local MarketplaceService = game:GetService("MarketplaceService")
        local SoundService = game:GetService("SoundService")
        local VirtualUser = game:GetService("VirtualUser")
        local startClock = os.clock()

        local function needPlayer(a)
            local t = a[1] and findPlayer(a[1])
            if not t then fail("Player not found") end
            return t
        end
        local function onoff(a)
            local v = (a[1] or "on"):lower()
            return not (v == "off" or v == "false" or v == "0")
        end
        local function copy(text)
            if setclipboard then setclipboard(tostring(text)) return true end
            return false
        end
        local function charOf(p) return p and p.Character end

        -- ───── CHARACTER ─────
        addCmd("sit", "sit", "Make your character sit", function()
            local h = getHum()
            if h then h.Sit = true success("Sitting") end
        end)
        addCmd("heal", "heal", "Restore your health", function()
            local h = getHum()
            if h then h.Health = h.MaxHealth success("Healed") end
        end)
        addCmd("hipheight", "hipheight <n>", "Set hip height", function(a)
            local h, n = getHum(), tonumber(a[1])
            if not (h and n) then return fail("Usage: hipheight <number>") end
            h.HipHeight = n success("HipHeight = " .. n)
        end)
        addCmd("scale", "scale <n>", "Scale your R15 character", function(a)
            local h, n = getHum(), tonumber(a[1])
            if not (h and n) then return fail("Usage: scale <number>") end
            local c = 0
            for _, name in ipairs({"BodyHeightScale", "BodyWidthScale", "BodyDepthScale", "HeadScale"}) do
                local v = h:FindFirstChild(name)
                if v then v.Value = n c += 1 end
            end
            if c == 0 then fail("R15 scale values not found") else success("Scale = " .. n) end
        end)
        local invisStore = {}
        addCmd("invisible", "invisible", "Make your character invisible (only for you)", function()
            local c = Player.Character
            if not c then return fail("Character not found") end
            for _, p in ipairs(c:GetDescendants()) do
                if (p:IsA("BasePart") or p:IsA("Decal")) and p.Name ~= "HumanoidRootPart" then
                    if invisStore[p] == nil then invisStore[p] = p.Transparency end
                    p.Transparency = 1
                end
            end
            success("Invisible (client-side)")
        end)
        addCmd("visible", "visible", "Make your character visible again", function()
            for p, v in pairs(invisStore) do if p.Parent then p.Transparency = v end end
            invisStore = {}
            success("Visible")
        end)
        addCmd("norotate", "norotate", "Stop your character from auto-rotating", function()
            local h = getHum() if h then h.AutoRotate = false success("AutoRotate off") end
        end)
        addCmd("rotate", "rotate", "Restore auto-rotation", function()
            local h = getHum() if h then h.AutoRotate = true success("AutoRotate on") end
        end)
        addCmd("platformstand", "platformstand", "Enable PlatformStand", function()
            local h = getHum() if h then h.PlatformStand = true success("PlatformStand on") end
        end)
        addCmd("unplatformstand", "unplatformstand", "Disable PlatformStand", function()
            local h = getHum() if h then h.PlatformStand = false success("PlatformStand off") end
        end)
        addCmd("noanim", "noanim", "Disable the default animations", function()
            local c = Player.Character
            local an = c and c:FindFirstChild("Animate")
            if an then an.Disabled = true success("Animations disabled") else fail("Animate script not found") end
        end)
        addCmd("anims", "anims", "Enable the default animations", function()
            local c = Player.Character
            local an = c and c:FindFirstChild("Animate")
            if an then an.Disabled = false success("Animations enabled") else fail("Animate script not found") end
        end)

        local animTrack
        addCmd("anim", "anim <id>", "Play an animation by ID", function(a)
            local h, id = getHum(), tonumber(a[1])
            if not (h and id) then return fail("Usage: anim <animation id>") end
            if animTrack then animTrack:Stop() end
            local an = make("Animation", {AnimationId = "rbxassetid://" .. id})
            local ok, tr = pcall(function() return h:LoadAnimation(an) end)
            if not ok then return fail("Could not load animation") end
            animTrack = tr
            tr:Play()
            success("Playing animation " .. id)
        end)
        addCmd("stopanim", "stopanim", "Stop all playing animations", function()
            local h = getHum()
            if animTrack then animTrack:Stop() animTrack = nil end
            if h then for _, t in ipairs(h:GetPlayingAnimationTracks()) do t:Stop() end end
            success("Animations stopped")
        end)

        -- Locked speed / jump
        local lockedWS, lockedJP
        bind(RunService.Heartbeat, function()
            local h = getHum()
            if not h then return end
            if lockedWS then h.WalkSpeed = lockedWS end
            if lockedJP then h.UseJumpPower = true h.JumpPower = lockedJP end
        end)
        addCmd("loopspeed", "loopspeed <n>", "Keep your WalkSpeed locked", function(a)
            local n = tonumber(a[1])
            if not n then return fail("Usage: loopspeed <number>") end
            lockedWS = n success("Locked WalkSpeed = " .. n)
        end)
        addCmd("unloopspeed", "unloopspeed", "Unlock WalkSpeed", function() lockedWS = nil success("WalkSpeed unlocked") end)
        addCmd("loopjump", "loopjump <n>", "Keep your JumpPower locked", function(a)
            local n = tonumber(a[1])
            if not n then return fail("Usage: loopjump <number>") end
            lockedJP = n success("Locked JumpPower = " .. n)
        end)
        addCmd("unloopjump", "unloopjump", "Unlock JumpPower", function() lockedJP = nil success("JumpPower unlocked") end)

        local autoJump = false
        addCmd("autojump", "autojump", "Keep jumping automatically", function()
            autoJump = false
            task.wait()
            autoJump = true
            task.spawn(function()
                while autoJump do
                    local h = getHum()
                    if h then h.Jump = true end
                    task.wait(0.1)
                end
            end)
            success("AutoJump enabled")
        end)
        addCmd("unautojump", "unautojump", "Disable AutoJump", function() autoJump = false success("AutoJump disabled") end)

        -- ───── MOVEMENT / TELEPORT ─────
        local following = false
        addCmd("follow", "follow <player>", "Walk after a player", function(a)
            local t = needPlayer(a)
            if not t then return end
            following = false
            task.wait()
            following = true
            task.spawn(function()
                while following do
                    local h = getHum()
                    local tr = t.Character and t.Character:FindFirstChild("HumanoidRootPart")
                    if h and tr then h:MoveTo(tr.Position) end
                    task.wait(0.2)
                end
            end)
            success("Following " .. t.Name)
        end)
        addCmd("unfollow", "unfollow", "Stop following", function() following = false success("Stopped following") end)
        addCmd("lookat", "lookat <player>", "Face a player", function(a)
            local t = needPlayer(a)
            if not t then return end
            local r, tr = getRoot(), t.Character and t.Character:FindFirstChild("HumanoidRootPart")
            if r and tr then
                r.CFrame = CFrame.lookAt(r.Position, Vector3.new(tr.Position.X, r.Position.Y, tr.Position.Z))
                success("Facing " .. t.Name)
            end
        end)
        addCmd("tpto", "tpto <x> <y> <z>", "Teleport to coordinates", function(a)
            local x, y, z, r = tonumber(a[1]), tonumber(a[2]), tonumber(a[3]), getRoot()
            if not (x and y and z) then return fail("Usage: tpto <x> <y> <z>") end
            if r then r.CFrame = CFrame.new(x, y, z) success("Teleported") end
        end)
        addCmd("pos", "pos", "Show (and copy) your position", function()
            local r = getRoot()
            if not r then return fail("Character not found") end
            local p = r.Position
            local s = string.format("%.1f, %.1f, %.1f", p.X, p.Y, p.Z)
            info("Position: " .. s)
            if copy(s) then log("Copied to clipboard", Theme.SubText) end
        end)
        addCmd("distance", "distance <player>", "Distance to a player", function(a)
            local t = needPlayer(a)
            if not t then return end
            local r, tr = getRoot(), t.Character and t.Character:FindFirstChild("HumanoidRootPart")
            if r and tr then success(string.format("%s is %.0f studs away", t.Name, (r.Position - tr.Position).Magnitude)) end
        end)
        local wps = {}
        addCmd("setwp", "setwp <name>", "Save your current position", function(a)
            local r = getRoot()
            if not (r and a[1]) then return fail("Usage: setwp <name>") end
            wps[a[1]:lower()] = r.CFrame
            success("Waypoint '" .. a[1] .. "' saved")
        end)
        addCmd("gowp", "gowp <name>", "Teleport to a saved waypoint", function(a)
            local cf, r = a[1] and wps[a[1]:lower()], getRoot()
            if not cf then return fail("Waypoint not found") end
            if r then r.CFrame = cf success("Teleported to '" .. a[1] .. "'") end
        end)
        addCmd("delwp", "delwp <name>", "Delete a waypoint", function(a)
            if not (a[1] and wps[a[1]:lower()]) then return fail("Waypoint not found") end
            wps[a[1]:lower()] = nil success("Waypoint deleted")
        end)
        addCmd("wps", "wps", "List saved waypoints", function()
            local any = false
            for n, cf in pairs(wps) do
                any = true
                log(string.format("• %s  (%.0f, %.0f, %.0f)", n, cf.X, cf.Y, cf.Z), Theme.Text)
            end
            if not any then info("No waypoints saved") end
        end)

        -- ───── CAMERA ─────
        addCmd("firstperson", "firstperson", "Lock first-person view", function()
            Player.CameraMode = Enum.CameraMode.LockFirstPerson success("First person")
        end)
        addCmd("thirdperson", "thirdperson", "Return to normal camera", function()
            Player.CameraMode = Enum.CameraMode.Classic success("Third person")
        end)
        addCmd("zoom", "zoom <max>", "Set max camera zoom distance", function(a)
            local n = tonumber(a[1])
            if not n then return fail("Usage: zoom <number>") end
            Player.CameraMaxZoomDistance = n success("Max zoom = " .. n)
        end)
        addCmd("hidegui", "hidegui", "Hide the game's GUIs", function()
            for _, g in ipairs(Player.PlayerGui:GetChildren()) do
                if g:IsA("ScreenGui") and g.Name ~= GUI_NAME and g.Enabled then
                    g.Enabled = false
                    g:SetAttribute("SolittaHidden", true)
                end
            end
            success("Game GUIs hidden")
        end)
        addCmd("showgui", "showgui", "Show the hidden GUIs", function()
            for _, g in ipairs(Player.PlayerGui:GetChildren()) do
                if g:IsA("ScreenGui") and g:GetAttribute("SolittaHidden") then
                    g.Enabled = true
                    g:SetAttribute("SolittaHidden", nil)
                end
            end
            success("Game GUIs restored")
        end)

        -- ───── WORLD / LIGHTING ─────
        local xr = {}
        addCmd("xray", "xray", "See through walls (client-side)", function()
            local n = 0
            for _, p in ipairs(workspace:GetDescendants()) do
                if p:IsA("BasePart") and not (Player.Character and p:IsDescendantOf(Player.Character)) then
                    if xr[p] == nil then xr[p] = p.LocalTransparencyModifier end
                    p.LocalTransparencyModifier = 0.7
                    n += 1
                end
            end
            success("X-ray on (" .. n .. " parts)")
        end)
        addCmd("unxray", "unxray", "Disable x-ray", function()
            for p, v in pairs(xr) do if p.Parent then p.LocalTransparencyModifier = v end end
            xr = {}
            success("X-ray off")
        end)
        addCmd("nofog", "nofog", "Remove fog", function() Lighting.FogEnd = 1e9 Lighting.FogStart = 1e9 success("Fog removed") end)
        addCmd("brightness", "brightness <n>", "Set lighting brightness", function(a)
            local n = tonumber(a[1])
            if not n then return fail("Usage: brightness <number>") end
            Lighting.Brightness = n success("Brightness = " .. n)
        end)
        addCmd("noshadows", "noshadows", "Disable global shadows", function() Lighting.GlobalShadows = false success("Shadows off") end)
        addCmd("shadows", "shadows", "Enable global shadows", function() Lighting.GlobalShadows = true success("Shadows on") end)
        addCmd("day", "day", "Set time to day", function() Lighting.ClockTime = 14 success("It's day") end)
        addCmd("night", "night", "Set time to night", function() Lighting.ClockTime = 0 success("It's night") end)
        addCmd("unlock", "unlock", "Unlock every part in the game", function()
            local n = 0
            for _, p in ipairs(workspace:GetDescendants()) do
                if p:IsA("BasePart") and p.Locked then p.Locked = false n += 1 end
            end
            success("Unlocked " .. n .. " parts")
        end)
        addCmd("delete", "delete <name>", "Delete parts with that name (client-side)", function(a)
            local nm = (a[1] or ""):lower()
            if nm == "" then return fail("Usage: delete <name>") end
            local n = 0
            for _, d in ipairs(workspace:GetDescendants()) do
                if d.Name:lower() == nm and not Players:GetPlayerFromCharacter(d) and not d:IsDescendantOf(Player.Character or workspace) then
                    pcall(function() d:Destroy() end) n += 1
                end
            end
            success("Deleted " .. n .. " objects")
        end)
        addCmd("delclass", "delclass <ClassName>", "Delete every object of a class (e.g. Decal)", function(a)
            if not a[1] then return fail("Usage: delclass <ClassName>") end
            local n = 0
            for _, d in ipairs(workspace:GetDescendants()) do
                local okIs, isIt = pcall(function() return d:IsA(a[1]) end)
                if okIs and isIt and not d:IsDescendantOf(Player.Character or workspace) then
                    pcall(function() d:Destroy() end) n += 1
                end
            end
            success("Deleted " .. n .. " objects")
        end)
        addCmd("partcount", "partcount", "Count the objects in the workspace", function()
            local parts, all = 0, 0
            for _, d in ipairs(workspace:GetDescendants()) do
                all += 1
                if d:IsA("BasePart") then parts += 1 end
            end
            success(parts .. " parts / " .. all .. " objects")
        end)

        -- ───── HIGHLIGHT HELPERS ─────
        local function highlightKind(kind, on)
            local n = 0
            for _, d in ipairs(workspace:GetDescendants()) do
                if d:IsA(kind) and d.Parent then
                    local tgt = d.Parent
                    if tgt:IsA("Attachment") then tgt = tgt.Parent end
                    if tgt then
                        local ex = tgt:FindFirstChild("SolittaHL")
                        if on and not ex then
                            make("Highlight", {Name = "SolittaHL", FillColor = Theme.Accent2, OutlineColor = Theme.Accent, FillTransparency = 0.6, Parent = tgt})
                            n += 1
                        elseif not on and ex then
                            ex:Destroy() n += 1
                        end
                    end
                end
            end
            return n
        end
        addCmd("cdesp", "cdesp", "Highlight all ClickDetectors", function() success("Highlighted " .. highlightKind("ClickDetector", true)) end)
        addCmd("uncdesp", "uncdesp", "Remove ClickDetector highlights", function() success("Removed " .. highlightKind("ClickDetector", false)) end)
        addCmd("ppesp", "ppesp", "Highlight all ProximityPrompts", function() success("Highlighted " .. highlightKind("ProximityPrompt", true)) end)
        addCmd("unppesp", "unppesp", "Remove ProximityPrompt highlights", function() success("Removed " .. highlightKind("ProximityPrompt", false)) end)
        addCmd("tiesp", "tiesp", "Highlight all touch interests", function() success("Highlighted " .. highlightKind("TouchTransmitter", true)) end)
        addCmd("untiesp", "untiesp", "Remove touch interest highlights", function() success("Removed " .. highlightKind("TouchTransmitter", false)) end)
        addCmd("partesp", "partesp <name>", "Highlight parts/models with a name", function(a)
            local nm = (a[1] or ""):lower()
            if nm == "" then return fail("Usage: partesp <name>") end
            local n = 0
            for _, d in ipairs(workspace:GetDescendants()) do
                if d.Name:lower() == nm and (d:IsA("BasePart") or d:IsA("Model")) and not d:FindFirstChild("SolittaHL") then
                    make("Highlight", {Name = "SolittaHL", FillColor = Theme.Accent2, OutlineColor = Theme.Accent, FillTransparency = 0.6, Parent = d})
                    n += 1
                end
            end
            success("Highlighted " .. n .. " objects")
        end)
        addCmd("unpartesp", "unpartesp", "Remove all highlights added by Solitta", function()
            local n = 0
            for _, d in ipairs(workspace:GetDescendants()) do
                if d.Name == "SolittaHL" then d:Destroy() n += 1 end
            end
            success("Removed " .. n .. " highlights")
        end)

        -- ───── TOOLS ─────
        addCmd("tools", "tools", "List the tools in your backpack", function()
            local n = 0
            for _, t in ipairs(Player.Backpack:GetChildren()) do
                if t:IsA("Tool") then n += 1 log("• " .. t.Name, Theme.Text) end
            end
            if n == 0 then info("No tools in backpack") end
        end)
        addCmd("equiptools", "equiptools", "Equip every tool", function()
            local h = getHum()
            if not h then return fail("Character not found") end
            for _, t in ipairs(Player.Backpack:GetChildren()) do if t:IsA("Tool") then h:EquipTool(t) end end
            success("Tools equipped")
        end)
        addCmd("unequiptools", "unequiptools", "Unequip your tools", function()
            local h = getHum() if h then h:UnequipTools() success("Tools unequipped") end
        end)
        addCmd("deletetools", "deletetools", "Delete your tools (client-side)", function()
            local n = 0
            for _, t in ipairs(Player.Backpack:GetChildren()) do if t:IsA("Tool") then t:Destroy() n += 1 end end
            success("Deleted " .. n .. " tools")
        end)
        addCmd("clonetools", "clonetools", "Clone your tools (client-side)", function()
            local n = 0
            for _, t in ipairs(Player.Backpack:GetChildren()) do
                if t:IsA("Tool") then t:Clone().Parent = Player.Backpack n += 1 end
            end
            success("Cloned " .. n .. " tools")
        end)

        -- ───── INFO ─────
        addCmd("ping", "ping", "Show your ping", function()
            local ok, v = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
            if ok then success(string.format("Ping: %.0f ms", v)) else fail("Could not read ping") end
        end)
        addCmd("memory", "memory", "Show client memory usage", function()
            success(string.format("Memory: %.0f MB", Stats:GetTotalMemoryUsageMb()))
        end)
        addCmd("serverinfo", "serverinfo", "Show info about this server", function()
            local name = "Unknown"
            pcall(function() name = MarketplaceService:GetProductInfo(game.PlaceId).Name end)
            info("── SERVER ──")
            log("Game      : " .. name, Theme.Text)
            log("Place ID  : " .. game.PlaceId, Theme.Text)
            log("Job ID    : " .. game.JobId, Theme.Text)
            log("Players   : " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers, Theme.Text)
            log(string.format("Uptime    : %.0f min", workspace.DistributedGameTime / 60), Theme.Text)
        end)
        addCmd("uptime", "uptime", "How long this panel has been running", function()
            success(string.format("Panel uptime: %.1f min", (os.clock() - startClock) / 60))
        end)
        addCmd("executor", "executor", "Show your executor name", function()
            local n = "Unknown"
            pcall(function() if identifyexecutor then n = (identifyexecutor()) end end)
            success("Executor: " .. n)
        end)
        addCmd("copyjobid", "copyjobid", "Copy the server Job ID", function()
            if copy(game.JobId) then success("Job ID copied") else fail("Executor does not support setclipboard") end
        end)
        addCmd("copyplaceid", "copyplaceid", "Copy the Place ID", function()
            if copy(game.PlaceId) then success("Place ID copied") else fail("Executor does not support setclipboard") end
        end)
        addCmd("userid", "userid <player>", "Show (and copy) a player's user ID", function(a)
            local t = needPlayer(a)
            if not t then return end
            success(t.Name .. " = " .. t.UserId)
            copy(t.UserId)
        end)
        addCmd("whois", "whois <player>", "Show info about a player", function(a)
            local t = needPlayer(a)
            if not t then return end
            info("── " .. t.Name .. " ──")
            log("Display name : " .. t.DisplayName, Theme.Text)
            log("User ID      : " .. t.UserId, Theme.Text)
            log("Account age  : " .. t.AccountAge .. " days", Theme.Text)
            log("Team         : " .. tostring(t.Team), Theme.Text)
            local r, tr = getRoot(), t.Character and t.Character:FindFirstChild("HumanoidRootPart")
            if r and tr then log(string.format("Distance     : %.0f studs", (r.Position - tr.Position).Magnitude), Theme.Text) end
        end)
        addCmd("friends", "friends", "List your friends in this server", function()
            local n = 0
            for _, p in ipairs(Players:GetPlayers()) do
                local ok, isF = pcall(function() return p ~= Player and p:IsFriendsWith(Player.UserId) end)
                if ok and isF then n += 1 log("• " .. p.Name .. " (" .. p.DisplayName .. ")", Theme.Text) end
            end
            if n == 0 then info("No friends in this server") end
        end)
        addCmd("teams", "teams", "List the game's teams", function()
            local list = game:GetService("Teams"):GetTeams()
            if #list == 0 then return info("This game has no teams") end
            for _, t in ipairs(list) do log("• " .. t.Name .. " (" .. #t:GetPlayers() .. ")", Theme.Text) end
        end)

        -- ───── UTILITY ─────
        addCmd("echo", "echo <text>", "Print text to the terminal", function(a) log(table.concat(a, " "), Theme.Text) end)
        addCmd("calc", "calc <expression>", "Evaluate a math expression", function(a)
            local expr = table.concat(a, " ")
            if expr == "" or expr:find("[^%d%+%-%*/%%%^%(%)%.%s]") then
                return fail("Only numbers and + - * / % ^ ( ) are allowed")
            end
            local f = loadstring("return " .. expr)
            if not f then return fail("Invalid expression") end
            local ok, res = pcall(f)
            if ok then success(expr .. " = " .. tostring(res)) else fail("Could not evaluate") end
        end)
        addCmd("exec", "exec <lua>", "Run a line of Lua code", function(a)
            local code = table.concat(a, " ")
            if code == "" then return fail("Usage: exec <lua code>") end
            local f, err = loadstring(code)
            if not f then return fail(tostring(err)) end
            local ok, e = pcall(f)
            if ok then success("Executed") else fail(tostring(e)) end
        end)
        addCmd("notify", "notify <text>", "Show a Roblox notification", function(a)
            pcall(function()
                StarterGui:SetCore("SendNotification", {Title = "SolittaSoftware", Text = table.concat(a, " "), Duration = 5})
            end)
        end)
        addCmd("theme", "theme <1-5>", "Accent: 1 Violet, 2 Crimson, 3 Emerald, 4 Sakura, 5 Gold", function(a)
            local i = tonumber(a[1])
            if not (i and AccentPresets[i]) then return fail("Usage: theme <1-5>") end
            Settings.Accent = i applyAccent(i) queueSave()
            success("Theme: " .. AccentPresets[i].name)
        end)
        addCmd("particles", "particles <on|off>", "Toggle background particles", function(a)
            Settings.Particles = onoff(a) queueSave()
            success("Particles " .. (Settings.Particles and "on" or "off"))
        end)
        addCmd("border", "border <on|off>", "Toggle the animated border", function(a)
            Settings.Border = onoff(a) queueSave()
            success("Border animation " .. (Settings.Border and "on" or "off"))
        end)
        addCmd("fpscap", "fpscap <n>", "Set the FPS cap", function(a)
            local n = tonumber(a[1])
            if not n then return fail("Usage: fpscap <number>") end
            if setfpscap then setfpscap(n) success("FPS cap = " .. n) else fail("Executor does not support setfpscap") end
        end)
        addCmd("quality", "quality <1-21>", "Set the graphics quality level", function(a)
            local n = tonumber(a[1])
            if not n then return fail("Usage: quality <1-21>") end
            local ok = pcall(function() settings().Rendering.QualityLevel = math.clamp(math.floor(n), 1, 21) end)
            if ok then success("Quality = " .. n) else fail("Could not set quality") end
        end)
        addCmd("volume", "volume <0-10>", "Set master volume", function(a)
            local n = tonumber(a[1])
            if not n then return fail("Usage: volume <0-10>") end
            local ok = pcall(function() UserSettings():GetService("UserGameSettings").MasterVolume = math.clamp(n, 0, 10) / 10 end)
            if ok then success("Volume = " .. n) else fail("Could not set volume") end
        end)

        local snd
        addCmd("play", "play <id>", "Play an audio ID (client-side)", function(a)
            local id = tonumber(a[1])
            if not id then return fail("Usage: play <audio id>") end
            if snd then snd:Destroy() end
            snd = make("Sound", {SoundId = "rbxassetid://" .. id, Volume = 1, Parent = SoundService})
            snd:Play()
            success("Playing " .. id)
        end)
        addCmd("stopsounds", "stopsounds", "Stop the audio started with play", function()
            if snd then snd:Destroy() snd = nil end
            success("Audio stopped")
        end)

        local afkConn
        addCmd("antiafk", "antiafk", "Prevent the AFK kick", function()
            if afkConn then return info("AntiAFK is already enabled") end
            afkConn = Player.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
            success("AntiAFK enabled")
        end)
        local clicking = false
        addCmd("autoclick", "autoclick [cps]", "Auto click (needs mouse1click)", function(a)
            if not mouse1click then return fail("Executor does not support mouse1click") end
            local cps = math.clamp(tonumber(a[1]) or 10, 1, 50)
            clicking = false
            task.wait()
            clicking = true
            task.spawn(function()
                while clicking do
                    mouse1click()
                    task.wait(1 / cps)
                end
            end)
            success("AutoClick enabled (" .. cps .. " CPS)")
        end)
        addCmd("unautoclick", "unautoclick", "Disable AutoClick", function() clicking = false success("AutoClick disabled") end)

        addCmd("serverhop", "serverhop", "Join a different public server", function()
            success("Searching for a server...")
            task.spawn(function()
                local ok, res = pcall(function()
                    return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
                end)
                if not ok or not res or not res.data then return fail("Could not fetch the server list") end
                local list = {}
                for _, s in ipairs(res.data) do
                    if s.id ~= game.JobId and s.playing < s.maxPlayers then table.insert(list, s.id) end
                end
                if #list == 0 then return fail("No other servers found") end
                TeleportService:TeleportToPlaceInstance(game.PlaceId, list[math.random(#list)], Player)
            end)
        end)

        table.insert(cleanups, function()
            following, clicking, autoJump = false, false, false
            lockedWS, lockedJP = nil, nil
            if afkConn then afkConn:Disconnect() afkConn = nil end
            if snd then snd:Destroy() snd = nil end
        end)
    end

    -- Command runner
    local history, hIndex = {}, 0
    local function runCommand(raw)
        raw = raw:gsub("^%s+", ""):gsub("%s+$", "")
        if raw == "" then return end
        log(colored(esc(Player.Name), Theme.Green) .. " " .. colored("~#", Theme.Accent) .. " " .. colored(esc(raw), Theme.Text), nil, true)
        table.insert(history, raw)
        hIndex = #history + 1
        local parts = {}
        for w in raw:gmatch("%S+") do table.insert(parts, w) end
        local name = table.remove(parts, 1):lower()
        local cmd = Commands[name]
        if not cmd then return fail("Command not found: " .. name .. "  (type help)") end
        local ok, err = pcall(cmd.fn, parts)
        if not ok then fail("Error: " .. tostring(err)) end
    end

    Input.FocusLost:Connect(function(enter)
        if enter then
            local t = Input.Text
            Input.Text = ""
            runCommand(t)
            Input:CaptureFocus()
        end
    end)
    bind(UserInputService.InputBegan, function(i)
        if not Input:IsFocused() then return end
        if i.KeyCode == Enum.KeyCode.Up and #history > 0 then
            hIndex = math.max(1, hIndex - 1)
            Input.Text = history[hIndex]
        elseif i.KeyCode == Enum.KeyCode.Down and #history > 0 then
            hIndex = math.min(#history + 1, hIndex + 1)
            Input.Text = history[hIndex] or ""
        end
    end)

    info("SolittaSoftware Admin Commands loaded.")
    log("Type help to list every command. Use ↑ / ↓ for command history.", Theme.SubText)
    log("")
end

-- ═══════════════ COMMANDS LIST ═══════════════
do
    local Page = newPage("Commands")
    newTab("Commands", "☰", 3)

    make("TextLabel", {
        Size = UDim2.new(1, -24, 0, 26), Position = UDim2.fromOffset(14, 10), BackgroundTransparency = 1, Text = "Command List",
        Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = Page,
    })
    make("TextLabel", {
        Size = UDim2.new(1, -24, 0, 14), Position = UDim2.fromOffset(14, 36), BackgroundTransparency = 1, Text = "Click a command to send it to the terminal.",
        Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left, Parent = Page,
    })
    local Scroll = make("ScrollingFrame", {
        Size = UDim2.new(1, -24, 1, -66), Position = UDim2.fromOffset(12, 58), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Accent, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Parent = Page,
    }, {make("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder})})
    onAccent(function() Scroll.ScrollBarImageColor3 = Theme.Accent end)

    local names = {}
    for n in pairs(Commands) do table.insert(names, n) end
    table.sort(names)
    for i, n in ipairs(names) do
        local row = make("TextButton", {
            Size = UDim2.new(1, -8, 0, 40), BackgroundColor3 = Theme.Panel2, Text = "", AutoButtonColor = false, LayoutOrder = i, Parent = Scroll,
        }, {corner(9), stroke()})
        glass(row, 0.15)
        make("TextLabel", {
            Size = UDim2.new(0.42, 0, 1, 0), Position = UDim2.fromOffset(14, 0), BackgroundTransparency = 1, Text = Commands[n].usage,
            Font = Enum.Font.Code, TextSize = 13, TextColor3 = Theme.Yellow, TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
        })
        make("TextLabel", {
            Size = UDim2.new(0.58, -28, 1, 0), Position = UDim2.new(0.42, 14, 0, 0), BackgroundTransparency = 1, Text = Commands[n].desc,
            Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd, Parent = row,
        })
        hoverable(row, Theme.Panel2, Theme.Stroke, 1)
        row.MouseButton1Click:Connect(function()
            selectTab("Terminal")
            Input.Text = n .. " "
            Input:CaptureFocus()
        end)
    end
end

-- ═══════════════ SETTINGS ═══════════════
do
    local Page = newPage("Settings")
    newTab("Settings", "⚙", 4)

    make("TextLabel", {
        Size = UDim2.new(1, -24, 0, 26), Position = UDim2.fromOffset(14, 10), BackgroundTransparency = 1, Text = "Settings",
        Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = Page,
    })
    make("TextLabel", {
        Size = UDim2.new(1, -24, 0, 14), Position = UDim2.fromOffset(14, 36), BackgroundTransparency = 1,
        Text = "Customize your panel. Changes are saved automatically.", Font = Enum.Font.Gotham, TextSize = 11,
        TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left, Parent = Page,
    })
    local Scroll = make("ScrollingFrame", {
        Size = UDim2.new(1, -24, 1, -66), Position = UDim2.fromOffset(12, 58), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Accent, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Parent = Page,
    }, {make("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder})})
    onAccent(function() Scroll.ScrollBarImageColor3 = Theme.Accent end)

    local order = 0
    local function card(height)
        order += 1
        local f = make("Frame", {
            Size = UDim2.new(1, -8, 0, height), BackgroundColor3 = Theme.Panel2, BorderSizePixel = 0, LayoutOrder = order, Parent = Scroll,
        }, {corner(10), stroke()})
        glass(f, 0.15)
        return f
    end
    local function label(parent, text, x, y, w, h, size, color, font)
        return make("TextLabel", {
            Size = UDim2.new(w, w <= 1 and 0 or 0, 0, h), Position = UDim2.fromOffset(x, y), BackgroundTransparency = 1, Text = text,
            Font = font or Enum.Font.Gotham, TextSize = size or 12, TextColor3 = color or Theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Parent = parent,
        })
    end
    local function makeButton(parent, text, pos, size, primary)
        local b = make("TextButton", {
            Size = size, Position = pos, BackgroundColor3 = primary and Theme.Accent or Theme.Panel2, Text = text,
            Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = Theme.Text, AutoButtonColor = false, Parent = parent,
        }, {corner(8), stroke()})
        if primary then
            onAccent(function() b.BackgroundColor3 = Theme.Accent end)
            hoverable(b, function() return Theme.Accent end, function() return Theme.Accent:Lerp(Color3.new(1, 1, 1), 0.25) end, 1.04)
        else
            hoverable(b, Theme.Panel2, Theme.Stroke, 1.04)
        end
        return b
    end

    -- Background image
    local bgCard = card(142)
    label(bgCard, "Background Image", 14, 10, 1, 16, 13, Theme.Text, Enum.Font.GothamBold)
    local descLbl = label(bgCard, "Paste an image ID, rbxassetid://..., a direct image URL, or a file name from your executor's workspace folder.", 14, 28, 1, 30, 11, Theme.SubText)
    descLbl.Size = UDim2.new(1, -28, 0, 30)
    local box = make("TextBox", {
        Size = UDim2.new(1, -28, 0, 32), Position = UDim2.fromOffset(14, 64), BackgroundColor3 = Theme.Bg, BackgroundTransparency = 0.3,
        Text = Settings.BgImage, PlaceholderText = "rbxassetid://123456789  or  https://i.imgur.com/xxxx.png", PlaceholderColor3 = Theme.SubText,
        Font = Enum.Font.Code, TextSize = 12, TextColor3 = Theme.Text, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
        Parent = bgCard,
    }, {corner(8), stroke(), make("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)})})
    local applyBtn = makeButton(bgCard, "Apply", UDim2.fromOffset(14, 104), UDim2.fromOffset(100, 28), true)
    local resetBtn = makeButton(bgCard, "Remove", UDim2.fromOffset(122, 104), UDim2.fromOffset(90, 28), false)
    local status = make("TextLabel", {
        Size = UDim2.new(1, -240, 0, 28), Position = UDim2.fromOffset(224, 104), BackgroundTransparency = 1, Text = "",
        Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, Parent = bgCard,
    })
    local function setStatus(t, c) status.Text = t status.TextColor3 = c or Theme.SubText end

    local function resolveImage(src)
        src = src:gsub("^%s+", ""):gsub("%s+$", "")
        if src == "" then return nil, "Empty" end
        if tonumber(src) then return "rbxassetid://" .. src end
        if src:match("^rbxassetid://") or src:match("^rbxasset://") or src:match("^rbxthumb://") then return src end
        local getAsset = getcustomasset or getsynasset
        if src:match("^https?://") then
            if not (writefile and getAsset) then return nil, "Executor lacks writefile/getcustomasset" end
            local okH, data = pcall(function() return game:HttpGet(src) end)
            if not okH or not data or #data == 0 then return nil, "Download failed" end
            local fname = "solitta_bg_" .. os.time() .. math.random(100, 999) .. ".png"
            writefile(fname, data)
            local okA, asset = pcall(getAsset, fname)
            if okA and asset then return asset end
            return nil, "getcustomasset failed"
        end
        if isfile and getAsset and isfile(src) then
            local okA, asset = pcall(getAsset, src)
            if okA and asset then return asset end
        end
        return nil, "Unrecognized source"
    end

    setBackground = function(src, silent)
        src = (src or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if src == "" then
            BgImage.Image = ""
            BgImage.Visible = false
            Dim.Visible = false
            Settings.BgImage = ""
            box.Text = ""
            queueSave()
            if not silent then setStatus("Background removed", Theme.SubText) end
            return
        end
        setStatus("Loading...", Theme.Yellow)
        task.spawn(function()
            local asset, err = resolveImage(src)
            if not asset then
                setStatus("✖ " .. tostring(err), Theme.Red)
                if info and not silent then fail("Background: " .. tostring(err)) end
                return
            end
            BgImage.Image = asset
            BgImage.ImageTransparency = 1
            BgImage.Visible = true
            Dim.Visible = true
            tween(BgImage, 0.6, {ImageTransparency = 0})
            Settings.BgImage = src
            queueSave()
            setStatus("✔ Background applied", Theme.Green)
        end)
    end

    applyBtn.MouseButton1Click:Connect(function() setBackground(box.Text) end)
    resetBtn.MouseButton1Click:Connect(function() setBackground("") end)
    box.FocusLost:Connect(function(enter) if enter then setBackground(box.Text) end end)

    -- Slider
    local function makeSlider(title, min, max, value, decimals, onChange)
        local f = card(60)
        label(f, title, 14, 10, 0.6, 16, 13, Theme.Text, Enum.Font.GothamBold)
        local valLbl = make("TextLabel", {
            Size = UDim2.fromOffset(60, 16), Position = UDim2.new(1, -74, 0, 10), BackgroundTransparency = 1, Text = "",
            Font = Enum.Font.Code, TextSize = 12, TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Right, Parent = f,
        })
        local track = make("Frame", {
            Size = UDim2.new(1, -28, 0, 6), Position = UDim2.fromOffset(14, 40), BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0, Parent = f,
        }, {corner(3)})
        local fill = make("Frame", {
            Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = track,
        }, {corner(3)})
        accentGrad(fill, 0)
        local knob = make("Frame", {
            Size = UDim2.fromOffset(14, 14), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5),
            BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = track,
        }, {corner(7)})
        local hit = make("TextButton", {
            Size = UDim2.new(1, 0, 0, 26), Position = UDim2.new(0, 0, 0.5, -13), BackgroundTransparency = 1, Text = "", Parent = track,
        })
        local function render(v)
            local a = (v - min) / (max - min)
            fill.Size = UDim2.fromScale(a, 1)
            knob.Position = UDim2.fromScale(a, 0.5)
            valLbl.Text = string.format("%." .. decimals .. "f", v)
        end
        render(value)
        local dragging = false
        local function setFromX(x)
            local a = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
            local v = min + (max - min) * a
            local m = 10 ^ decimals
            v = math.floor(v * m + 0.5) / m
            render(v)
            onChange(v)
        end
        hit.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                tween(knob, 0.12, {Size = UDim2.fromOffset(18, 18)}, Enum.EasingStyle.Back)
                setFromX(i.Position.X)
            end
        end)
        bind(UserInputService.InputChanged, function(i)
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                setFromX(i.Position.X)
            end
        end)
        bind(UserInputService.InputEnded, function(i)
            if dragging and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
                dragging = false
                tween(knob, 0.15, {Size = UDim2.fromOffset(14, 14)})
            end
        end)
    end

    makeSlider("Window Transparency", 0, 0.9, Settings.Glass, 2, function(v)
        Settings.Glass = v applyGlass() queueSave()
    end)
    makeSlider("Image Darkness", 0, 0.9, Settings.Dim, 2, function(v)
        Settings.Dim = v Dim.BackgroundTransparency = 1 - v queueSave()
    end)

    -- Accent colors
    local accCard = card(84)
    label(accCard, "Accent Color", 14, 10, 1, 16, 13, Theme.Text, Enum.Font.GothamBold)
    local swatches = {}
    local function refreshSwatches()
        for i, s in ipairs(swatches) do
            tween(s.stroke, 0.2, {Transparency = (i == Settings.Accent) and 0 or 1})
        end
    end
    for i, p in ipairs(AccentPresets) do
        local b = make("TextButton", {
            Size = UDim2.fromOffset(34, 34), Position = UDim2.fromOffset(14 + (i - 1) * 44, 38), BackgroundColor3 = Color3.new(1, 1, 1),
            Text = "", AutoButtonColor = false, Parent = accCard,
        }, {corner(17)})
        make("UIGradient", {Color = ColorSequence.new(p.a, p.b), Rotation = 45, Parent = b})
        local st = make("UIStroke", {Color = Color3.new(1, 1, 1), Thickness = 2, Transparency = 1, Parent = b})
        swatches[i] = {btn = b, stroke = st}
        hoverable(b, Color3.new(1, 1, 1), Color3.new(1, 1, 1), 1.12)
        b.MouseButton1Click:Connect(function()
            Settings.Accent = i
            applyAccent(i)
            refreshSwatches()
            queueSave()
        end)
    end
    refreshSwatches()

    -- Toggle
    local function makeToggle(title, desc, value, cb)
        local f = card(54)
        label(f, title, 14, 9, 0.7, 16, 13, Theme.Text, Enum.Font.GothamBold)
        label(f, desc, 14, 28, 0.7, 14, 11, Theme.SubText)
        local sw = make("TextButton", {
            Size = UDim2.fromOffset(44, 24), Position = UDim2.new(1, -58, 0.5, -12), BackgroundColor3 = Theme.Stroke, Text = "",
            AutoButtonColor = false, Parent = f,
        }, {corner(12)})
        local dot = make("Frame", {
            Size = UDim2.fromOffset(18, 18), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = sw,
        }, {corner(9)})
        local state = value
        local function render(animate)
            local t = animate and 0.22 or 0
            tween(sw, t, {BackgroundColor3 = state and Theme.Accent or Theme.Stroke})
            tween(dot, t, {Position = state and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3)}, Enum.EasingStyle.Back)
        end
        render(false)
        onAccent(function() render(false) end)
        sw.MouseButton1Click:Connect(function()
            state = not state
            render(true)
            cb(state)
        end)
    end
    makeToggle("Floating Particles", "Animated particles drifting in the background.", Settings.Particles, function(v)
        Settings.Particles = v queueSave()
    end)
    makeToggle("Animated Border", "Rotating accent gradient around the window.", Settings.Border, function(v)
        Settings.Border = v queueSave()
    end)

    -- Keybind
    local keyCard = card(54)
    label(keyCard, "Toggle Key", 14, 9, 0.6, 16, 13, Theme.Text, Enum.Font.GothamBold)
    label(keyCard, "Press the button, then press any key.", 14, 28, 0.6, 14, 11, Theme.SubText)
    local keyBtn = makeButton(keyCard, ToggleKey.Name, UDim2.new(1, -134, 0.5, -14), UDim2.fromOffset(120, 28), false)
    keyBtn.MouseButton1Click:Connect(function()
        listeningForKey = true
        keyBtn.Text = "Press a key..."
    end)
    bind(UserInputService.InputBegan, function(i)
        if listeningForKey and i.UserInputType == Enum.UserInputType.Keyboard then
            listeningForKey = false
            if i.KeyCode ~= Enum.KeyCode.Escape then
                ToggleKey = i.KeyCode
                Settings.Key = i.KeyCode.Name
                queueSave()
                HintLabel.Text = "v2.0  •  [" .. ToggleKey.Name .. "] Toggle"
            end
            keyBtn.Text = ToggleKey.Name
        end
    end)
end

-- ═══════════════ SHOW / HIDE / CLOSE ═══════════════
-- ═══════════════ OWNER TAGS (visible to script users) ═══════════════
do
    local function tagChar(char)
        local head = char:WaitForChild("Head", 5)
        if not head or head:FindFirstChild("SolittaOwnerTag") then return end
        local bb = make("BillboardGui", {
            Name = "SolittaOwnerTag", Size = UDim2.fromOffset(130, 26), StudsOffset = Vector3.new(0, 3.4, 0),
            AlwaysOnTop = true, Adornee = head, Parent = head,
        })
        make("TextLabel", {
            Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Bg, BackgroundTransparency = 0.3, Text = "👑 OWNER",
            Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Theme.Yellow, Parent = bb,
        }, {corner(8), stroke(Theme.Yellow, 1.2, 0.1)})
    end
    local function watch(p)
        if not isOwnerName(p.Name) then return end
        if p.Character then task.spawn(tagChar, p.Character) end
        bind(p.CharacterAdded, tagChar)
    end
    for _, p in ipairs(Players:GetPlayers()) do watch(p) end
    bind(Players.PlayerAdded, watch)
    table.insert(cleanups, function()
        for _, p in ipairs(Players:GetPlayers()) do
            local h = p.Character and p.Character:FindFirstChild("Head")
            local t = h and h:FindFirstChild("SolittaOwnerTag")
            if t then t:Destroy() end
        end
    end)
end

local shown = false
local function setVisible(v)
    shown = v
    if v then
        Main.Visible = true
        tween(Scale, 0.5, {Scale = calcScale()}, Enum.EasingStyle.Back)
    else
        local t = tween(Scale, 0.22, {Scale = 0}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        t.Completed:Connect(function() if not shown then Main.Visible = false end end)
    end
end

-- Floating toggle button (handy on mobile)
local Fab = make("TextButton", {
    Size = UDim2.fromOffset(42, 42), Position = UDim2.new(0, 14, 0.5, -21), BackgroundColor3 = Theme.Panel, Text = "S",
    Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = Theme.Text, AutoButtonColor = false, Parent = Gui,
}, {corner(21)})
local fabStroke = stroke(Color3.new(1, 1, 1), 1.5, 0.1)
fabStroke.Parent = Fab
accentGrad(fabStroke, 45)
hoverable(Fab, Theme.Panel, Theme.Panel2, 1.12)
Fab.MouseButton1Click:Connect(function() setVisible(not shown) end)

MinBtn.MouseButton1Click:Connect(function() setVisible(false) end)
CloseBtn.MouseButton1Click:Connect(function()
    for _, fn in ipairs(cleanups) do pcall(fn) end
    shown = false
    local t = tween(Scale, 0.25, {Scale = 0}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    t.Completed:Wait()
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    Gui:Destroy()
end)

bind(UserInputService.InputBegan, function(i, gp)
    if gp or listeningForKey then return end
    if i.KeyCode == ToggleKey then setVisible(not shown) end
end)

-- ═══════════════ START ═══════════════
applyAccent(Settings.Accent)
applyGlass()
if Settings.BgImage ~= "" then setBackground(Settings.BgImage, true) end
selectTab("Welcome")
setVisible(true)
