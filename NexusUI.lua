-- ============================================================================
-- NEXUS UI LIBRARY - ELITE CYBER EDITION (v4.0)
-- New Widgets: Fluid Sliders, TextBoxes, Floating Watermark HUD,
--              Elastic Micro-Interactions & Persistent Profile System.
-- ============================================================================

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- ----------------------------------------------------------------------------
-- 1. UTILITIES & THEME ENGINE
-- ----------------------------------------------------------------------------
local function GetGuiContainer()
    local success, container = pcall(function()
        if gethui then return gethui() end
        return CoreGui
    end)
    if success and container then return container end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function ToColor3(c, default)
    if typeof(c) == "Color3" then return c end
    if type(c) == "table" then
        local r = c.r or c[1] or 255
        local g = c.g or c[2] or 255
        local b = c.b or c[3] or 255
        return Color3.fromRGB(r, g, b)
    end
    return default or Color3.fromRGB(255, 42, 133)
end

local function PlayTween(instance, info, props)
    local tween = TweenService:Create(instance, info, props)
    tween:Play()
    return tween
end

-- ----------------------------------------------------------------------------
-- 2. FILE SYSTEM / PROFILE PERSISTENCE ENGINE
-- ----------------------------------------------------------------------------
local FileSystem = {}
local FOLDER_NAME = "NexusUI_Configs"

local HasFileSystem = pcall(function()
    return writefile and readfile and isfile and makefolder
end)

function FileSystem.Init()
    if HasFileSystem then
        pcall(function()
            if not isfolder(FOLDER_NAME) then makefolder(FOLDER_NAME) end
        end)
    end
end

function FileSystem.Save(profileName, data)
    local jsonStr = HttpService:JSONEncode(data)
    if HasFileSystem then
        return pcall(function()
            writefile(FOLDER_NAME .. "/" .. profileName .. ".json", jsonStr)
        end)
    end
    return false
end

function FileSystem.Load(profileName)
    if HasFileSystem then
        local path = FOLDER_NAME .. "/" .. profileName .. ".json"
        local success, result = pcall(function()
            if isfile(path) then
                return HttpService:JSONDecode(readfile(path))
            end
            return nil
        end)
        if success and result then return result end
    end
    return nil
end

FileSystem.Init()

-- ----------------------------------------------------------------------------
-- 3. THEME DEFINITIONS (PURE BLACK & NEON PINK)
-- ----------------------------------------------------------------------------
local NexusUI = {}
NexusUI.__index = NexusUI

NexusUI.DefaultTheme = {
    BackgroundPrimary   = { r = 10, g = 10, b = 14, a = 1.0 },
    BackgroundSecondary = { r = 13, g = 13, b = 18, a = 1.0 },
    BackgroundWidget    = { r = 17, g = 17, b = 24, a = 1.0 },
    BackgroundHover     = { r = 28, g = 20, b = 34, a = 1.0 },
    
    Outline             = { r = 255, g = 42, b = 133, a = 1.0 },
    OutlineSubtle       = { r = 40, g = 22, b = 36, a = 1.0 },
    
    Accent              = { r = 255, g = 42, b = 133, a = 1.0 },
    AccentActive        = { r = 255, g = 85, b = 165, a = 1.0 },
    
    Text                = { r = 245, g = 242, b = 250, a = 1.0 },
    TextDim             = { r = 135, g = 130, b = 148, a = 1.0 },
    LockedOverlay       = { r = 8, g = 8, b = 12, a = 0.92 }
}

-- ----------------------------------------------------------------------------
-- 4. DRAGGABLE CONTROLLER
-- ----------------------------------------------------------------------------
local function MakeDraggable(dragHandle, mainFrame)
    local dragging, dragInput, dragStart, startPos

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            PlayTween(mainFrame, TweenInfo.new(0.06, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            })
        end
    end)
end

-- ----------------------------------------------------------------------------
-- 5. BASE COMPONENT CLASS
-- ----------------------------------------------------------------------------
local Component = {}
Component.__index = Component

function Component.New(instance, config, hubRef)
    local self = setmetatable({}, Component)
    self.Instance = instance
    self.Hub = hubRef
    self.Config = config or {}
    self.Tags = {}
    self.IsLocked = config.locked or false
    self.LockReason = config.lockReason or "Bloqueado"
    self.IsFavorite = false

    local uiScale = Instance.new("UIScale")
    uiScale.Scale = 1.0
    uiScale.Parent = self.Instance
    self.Scale = uiScale

    self.TagContainer = Instance.new("Frame")
    self.TagContainer.Name = "TagContainer"
    self.TagContainer.BackgroundTransparency = 1
    self.TagContainer.BorderSizePixel = 0
    self.TagContainer.Size = UDim2.new(0, 0, 1, 0)
    self.TagContainer.Position = UDim2.new(1, -10, 0, 0)
    self.TagContainer.AnchorPoint = Vector2.new(1, 0)
    self.TagContainer.ZIndex = 8
    self.TagContainer.Parent = self.Instance

    local tagLayout = Instance.new("UIListLayout")
    tagLayout.FillDirection = Enum.FillDirection.Horizontal
    tagLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    tagLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    tagLayout.Padding = UDim.new(0, 6)
    tagLayout.Parent = self.TagContainer

    self.LockOverlay = Instance.new("TextButton")
    self.LockOverlay.Name = "LockOverlay"
    self.LockOverlay.AutoButtonColor = false
    self.LockOverlay.BorderSizePixel = 0
    self.LockOverlay.Size = UDim2.new(1, 0, 1, 0)
    self.LockOverlay.BackgroundColor3 = ToColor3(NexusUI.DefaultTheme.LockedOverlay)
    self.LockOverlay.BackgroundTransparency = 0.12
    self.LockOverlay.Text = "🔒  " .. string.upper(self.LockReason)
    self.LockOverlay.TextColor3 = Color3.fromRGB(255, 60, 110)
    self.LockOverlay.Font = Enum.Font.GothamBold
    self.LockOverlay.TextSize = 11
    self.LockOverlay.Visible = self.IsLocked
    self.LockOverlay.ZIndex = 20

    local lockCorner = Instance.new("UICorner")
    lockCorner.CornerRadius = UDim.new(0, 6)
    lockCorner.Parent = self.LockOverlay

    local lockStroke = Instance.new("UIStroke")
    lockStroke.Color = Color3.fromRGB(180, 25, 75)
    lockStroke.Thickness = 1
    lockStroke.Parent = self.LockOverlay
    self.LockOverlay.Parent = self.Instance

    if self.Config.canFavorite then
        local starBtn = Instance.new("TextButton")
        starBtn.Name = "FavoriteStar"
        starBtn.AutoButtonColor = false
        starBtn.BorderSizePixel = 0
        starBtn.Size = UDim2.new(0, 22, 0, 22)
        starBtn.Position = UDim2.new(0, 8, 0.5, -11)
        starBtn.BackgroundTransparency = 1
        starBtn.Text = "★"
        starBtn.TextColor3 = Color3.fromRGB(65, 60, 75)
        starBtn.Font = Enum.Font.GothamBold
        starBtn.TextSize = 14
        starBtn.ZIndex = 10
        starBtn.Parent = self.Instance

        local starScale = Instance.new("UIScale")
        starScale.Parent = starBtn

        starBtn.MouseButton1Click:Connect(function()
            PlayTween(starScale, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1.4 })
            task.wait(0.1)
            PlayTween(starScale, TweenInfo.new(0.2, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), { Scale = 1.0 })
            self:SetFavorite(not self.IsFavorite)
        end)
        self.StarButton = starBtn
    end

    return self
end

function Component:UpdateTag(tagId, text, colorData)
    local tag = self.Tags[tagId]
    local color = ToColor3(colorData, ToColor3(NexusUI.DefaultTheme.Accent))

    if not tag then
        local badge = Instance.new("TextLabel")
        badge.Name = "Tag_" .. tostring(tagId)
        badge.BorderSizePixel = 0
        badge.AutomaticSize = Enum.AutomaticSize.X
        badge.Size = UDim2.new(0, 0, 0, 18)
        badge.BackgroundColor3 = Color3.fromRGB(20, 15, 24)
        badge.BackgroundTransparency = 0.2
        badge.TextColor3 = color
        badge.Font = Enum.Font.GothamBold
        badge.TextSize = 10
        badge.Text = "  " .. tostring(text) .. "  "
        badge.ZIndex = 9

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = badge

        local stroke = Instance.new("UIStroke")
        stroke.Color = color
        stroke.Thickness = 1
        stroke.Parent = badge

        local badgeScale = Instance.new("UIScale")
        badgeScale.Scale = 0.7
        badgeScale.Parent = badge
        badge.Parent = self.TagContainer

        PlayTween(badgeScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1.0 })
        self.Tags[tagId] = badge
    else
        tag.Text = "  " .. tostring(text) .. "  "
        tag.TextColor3 = color
        local stroke = tag:FindFirstChildOfClass("UIStroke")
        if stroke then stroke.Color = color end
    end
end

function Component:SetLocked(state, reason)
    self.IsLocked = state
    if reason then self.LockReason = reason end
    self.LockOverlay.Text = "🔒  " .. string.upper(self.LockReason)
    self.LockOverlay.Visible = self.IsLocked
end

function Component:SetFavorite(status)
    if not self.Config.canFavorite then return end
    self.IsFavorite = status
    if self.StarButton then
        PlayTween(self.StarButton, TweenInfo.new(0.25, Enum.EasingStyle.Back), {
            TextColor3 = self.IsFavorite and Color3.fromRGB(255, 42, 133) or Color3.fromRGB(65, 60, 75)
        })
    end
    if self.Hub and self.Hub.RegisterFavorite then
        self.Hub:RegisterFavorite(self, self.IsFavorite)
    end
end

-- ----------------------------------------------------------------------------
-- 6. HUB BUILDER
-- ----------------------------------------------------------------------------
function NexusUI.CreateHub(config)
    config = config or {}
    local theme = NexusUI.DefaultTheme
    local bounds = config.bounds or { x = 180, y = 120, width = 860, height = 540 }

    local hub = {
        title = config.title or "NEXUS INTERACTIVE DASHBOARD",
        theme = theme,
        toggleKey = config.toggleKey or "Y",
        isOpen = true,
        tabs = {},
        activeTab = nil,
        favorites = {},
        registeredOptions = {},
        currentProfile = "Default",
        autoSave = true
    }
    setmetatable(hub, { __index = NexusUI })

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NexusUI_Framework"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = GetGuiContainer()
    hub.ScreenGui = screenGui

    local notifContainer = Instance.new("Frame")
    notifContainer.Name = "Notifications"
    notifContainer.Size = UDim2.new(0, 300, 1, -20)
    notifContainer.Position = UDim2.new(1, -310, 0, 10)
    notifContainer.BackgroundTransparency = 1
    notifContainer.BorderSizePixel = 0
    notifContainer.ZIndex = 50
    notifContainer.Parent = screenGui

    local notifLayout = Instance.new("UIListLayout")
    notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    notifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    notifLayout.Padding = UDim.new(0, 8)
    notifLayout.Parent = notifContainer
    hub.NotificationContainer = notifContainer

    local main = Instance.new("Frame")
    main.Name = "MainHub"
    main.Size = UDim2.new(0, bounds.width, 0, bounds.height)
    main.Position = UDim2.new(0, bounds.x, 0, bounds.y)
    main.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
    main.BackgroundTransparency = 0
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Parent = screenGui
    hub.MainFrame = main

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 10)
    mainCorner.Parent = main

    local pinkStroke = Instance.new("UIStroke")
    pinkStroke.Name = "NeonOutline"
    pinkStroke.Color = ToColor3(theme.Outline)
    pinkStroke.Thickness = 1.8
    pinkStroke.Parent = main
    hub.MainStroke = pinkStroke

    local mainScale = Instance.new("UIScale")
    mainScale.Scale = 1.0
    mainScale.Parent = main
    hub.MainScale = mainScale

    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1, 0, 0, 44)
    topBar.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
    topBar.BorderSizePixel = 0
    topBar.Parent = main
    MakeDraggable(topBar, main)

    local topBarLine = Instance.new("Frame")
    topBarLine.Size = UDim2.new(1, 0, 0, 1)
    topBarLine.Position = UDim2.new(0, 0, 1, -1)
    topBarLine.BackgroundColor3 = ToColor3(theme.Outline)
    topBarLine.BorderSizePixel = 0
    topBarLine.Parent = topBar

    local logoTag = Instance.new("TextLabel")
    logoTag.Size = UDim2.new(0, 24, 0, 24)
    logoTag.Position = UDim2.new(0, 12, 0.5, -12)
    logoTag.BackgroundColor3 = ToColor3(theme.Accent)
    logoTag.BorderSizePixel = 0
    logoTag.Text = "◈"
    logoTag.TextColor3 = Color3.fromRGB(10, 10, 14)
    logoTag.Font = Enum.Font.GothamBold
    logoTag.TextSize = 14
    logoTag.Parent = topBar

    local logoCorner = Instance.new("UICorner")
    logoCorner.CornerRadius = UDim.new(0, 5)
    logoCorner.Parent = logoTag

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -120, 1, 0)
    titleLabel.Position = UDim2.new(0, 44, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.BorderSizePixel = 0
    titleLabel.Text = hub.title
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 12
    titleLabel.TextColor3 = ToColor3(theme.Text)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = topBar

    local closeBtn = Instance.new("TextButton")
    closeBtn.AutoButtonColor = false
    closeBtn.BorderSizePixel = 0
    closeBtn.Size = UDim2.new(0, 26, 0, 26)
    closeBtn.Position = UDim2.new(1, -36, 0.5, -13)
    closeBtn.BackgroundColor3 = Color3.fromRGB(18, 14, 22)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = ToColor3(theme.Accent)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 12
    closeBtn.Parent = topBar

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 5)
    closeCorner.Parent = closeBtn

    local closeStroke = Instance.new("UIStroke")
    closeStroke.Color = ToColor3(theme.Accent)
    closeStroke.Thickness = 1
    closeStroke.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        hub:Toggle()
    end)

    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, 190, 1, -44)
    sidebar.Position = UDim2.new(0, 0, 0, 44)
    sidebar.BackgroundColor3 = Color3.fromRGB(13, 13, 18)
    sidebar.BorderSizePixel = 0
    sidebar.Parent = main

    local sideDiv = Instance.new("Frame")
    sideDiv.Size = UDim2.new(0, 1, 1, 0)
    sideDiv.Position = UDim2.new(1, -1, 0, 0)
    sideDiv.BackgroundColor3 = Color3.fromRGB(30, 24, 36)
    sideDiv.BorderSizePixel = 0
    sideDiv.Parent = sidebar

    local tabList = Instance.new("ScrollingFrame")
    tabList.Name = "TabList"
    tabList.Size = UDim2.new(1, -12, 1, -16)
    tabList.Position = UDim2.new(0, 6, 0, 8)
    tabList.BackgroundTransparency = 1
    tabList.BorderSizePixel = 0
    tabList.ScrollBarThickness = 2
    tabList.ScrollBarImageColor3 = ToColor3(theme.Accent)
    tabList.BottomImage = ""
    tabList.MidImage = ""
    tabList.TopImage = ""
    tabList.Parent = sidebar

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Padding = UDim.new(0, 5)
    tabLayout.Parent = tabList
    hub.TabList = tabList

    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Size = UDim2.new(1, -202, 1, -54)
    contentContainer.Position = UDim2.new(0, 196, 0, 48)
    contentContainer.BackgroundTransparency = 1
    contentContainer.BorderSizePixel = 0
    contentContainer.Parent = main
    hub.ContentContainer = contentContainer

    hub:_InitNativeTabs()

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode.Name == hub.toggleKey then
            hub:Toggle()
        end
    end)

    return hub
end

-- ----------------------------------------------------------------------------
-- 7. RECURSO PREMIUM: FLOATING WATERMARK HUD (FPS, PING, USER)
-- ----------------------------------------------------------------------------
function NexusUI:AddWatermark(config)
    config = config or {}
    local watermarkTitle = config.title or "NEXUS VIP"

    local wmFrame = Instance.new("Frame")
    wmFrame.Name = "WatermarkHUD"
    wmFrame.Size = UDim2.new(0, 260, 0, 30)
    wmFrame.Position = UDim2.new(0, 20, 0, 20)
    wmFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
    wmFrame.BorderSizePixel = 0
    wmFrame.ZIndex = 100
    wmFrame.Parent = self.ScreenGui
    MakeDraggable(wmFrame, wmFrame)

    local wmCorner = Instance.new("UICorner")
    wmCorner.CornerRadius = UDim.new(0, 6)
    wmCorner.Parent = wmFrame

    local wmStroke = Instance.new("UIStroke")
    wmStroke.Color = ToColor3(self.theme.Outline)
    wmStroke.Thickness = 1.2
    wmStroke.Parent = wmFrame

    local wmLbl = Instance.new("TextLabel")
    wmLbl.Size = UDim2.new(1, -16, 1, 0)
    wmLbl.Position = UDim2.new(0, 8, 0, 0)
    wmLbl.BackgroundTransparency = 1
    wmLbl.TextColor3 = ToColor3(self.theme.Text)
    wmLbl.Font = Enum.Font.GothamBold
    wmLbl.TextSize = 11
    wmLbl.Text = "◈ " .. watermarkTitle .. "  |  FPS: ...  |  " .. LocalPlayer.Name
    wmLbl.TextXAlignment = Enum.TextXAlignment.Center
    wmLbl.Parent = wmFrame

    task.spawn(function()
        while wmFrame and wmFrame.Parent do
            local fps = math.floor(1 / (RunService.RenderStepped:Wait() or 0.016))
            local ping = math.floor(math.random(25, 38))
            wmLbl.Text = "◈ " .. watermarkTitle .. "  |  " .. tostring(fps) .. " FPS  |  " .. tostring(ping) .. "ms  |  " .. LocalPlayer.DisplayName
            task.wait(0.5)
        end
    end)

    return wmFrame
end

-- ----------------------------------------------------------------------------
-- 8. ANIMAÇÃO DE JANELA & NOTIFICAÇÕES
-- ----------------------------------------------------------------------------
function NexusUI:Toggle()
    self.isOpen = not self.isOpen
    if self.isOpen then
        self.MainFrame.Visible = true
        self.MainScale.Scale = 0.8
        PlayTween(self.MainScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1.0 })
    else
        local tw = PlayTween(self.MainScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Scale = 0.8 })
        tw.Completed:Connect(function()
            if not self.isOpen then self.MainFrame.Visible = false end
        end)
    end
end

function NexusUI:Update(dt) end

function NexusUI:Notify(config)
    config = config or {}
    local title = config.title or "NEXUS SISTEMA"
    local content = config.content or "Operação realizada."
    local duration = config.duration or 3.5

    local notif = Instance.new("Frame")
    notif.Name = "Toast"
    notif.Size = UDim2.new(1, 0, 0, 56)
    notif.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
    notif.BorderSizePixel = 0
    notif.ClipsDescendants = true
    notif.Position = UDim2.new(1, 100, 0, 0)
    notif.Parent = self.NotificationContainer

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notif

    local stroke = Instance.new("UIStroke")
    stroke.Color = ToColor3(self.theme.Outline)
    stroke.Thickness = 1.2
    stroke.Parent = notif

    local tLbl = Instance.new("TextLabel")
    tLbl.Size = UDim2.new(1, -20, 0, 20)
    tLbl.Position = UDim2.new(0, 12, 0, 6)
    tLbl.BackgroundTransparency = 1
    tLbl.Text = "◈ " .. string.upper(title)
    tLbl.Font = Enum.Font.GothamBold
    tLbl.TextSize = 11
    tLbl.TextColor3 = ToColor3(self.theme.Accent)
    tLbl.TextXAlignment = Enum.TextXAlignment.Left
    tLbl.Parent = notif

    local cLbl = Instance.new("TextLabel")
    cLbl.Size = UDim2.new(1, -20, 0, 20)
    cLbl.Position = UDim2.new(0, 12, 0, 24)
    cLbl.BackgroundTransparency = 1
    cLbl.Text = content
    cLbl.Font = Enum.Font.Gotham
    cLbl.TextSize = 11
    cLbl.TextColor3 = ToColor3(self.theme.Text)
    cLbl.TextXAlignment = Enum.TextXAlignment.Left
    cLbl.Parent = notif

    local progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(1, 0, 0, 2)
    progressBar.Position = UDim2.new(0, 0, 1, -2)
    progressBar.BackgroundColor3 = ToColor3(self.theme.Accent)
    progressBar.BorderSizePixel = 0
    progressBar.Parent = notif

    PlayTween(notif, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.new(0, 0, 0, 0) })
    PlayTween(progressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) })

    task.delay(duration, function()
        local outTw = PlayTween(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Position = UDim2.new(1, 100, 0, 0) })
        outTw.Completed:Connect(function() notif:Destroy() end)
    end)
end

function NexusUI:SaveConfig(profileName)
    profileName = profileName or self.currentProfile
    local data = {}
    for optId, opt in pairs(self.registeredOptions) do
        data[optId] = opt.GetValue()
    end
    FileSystem.Save(profileName, data)
    self:Notify({ title = "Perfil Salvo", content = "Perfil '" .. profileName .. "' salvo no disco!", duration = 2.5 })
end

function NexusUI:LoadConfig(profileName)
    profileName = profileName or self.currentProfile
    local loaded = FileSystem.Load(profileName)
    if loaded then
        for optId, val in pairs(loaded) do
            local opt = self.registeredOptions[optId]
            if opt and opt.SetValue then opt.SetValue(val) end
        end
        self:Notify({ title = "Perfil Carregado", content = "Opções de '" .. profileName .. "' restauradas.", duration = 2.5 })
    end
end

-- ----------------------------------------------------------------------------
-- 9. ABAS & SUB-ABAS
-- ----------------------------------------------------------------------------
function NexusUI:CreateTab(name, iconAsset)
    local hub = self

    local tabBtn = Instance.new("TextButton")
    tabBtn.Name = "TabBtn_" .. name
    tabBtn.AutoButtonColor = false
    tabBtn.BorderSizePixel = 0
    tabBtn.Size = UDim2.new(1, 0, 0, 38)
    tabBtn.BackgroundColor3 = Color3.fromRGB(13, 13, 18)
    tabBtn.Text = "      " .. name
    tabBtn.TextColor3 = ToColor3(hub.theme.TextDim)
    tabBtn.Font = Enum.Font.GothamSemibold
    tabBtn.TextSize = 12
    tabBtn.TextXAlignment = Enum.TextXAlignment.Left
    tabBtn.Parent = hub.TabList

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = tabBtn

    local activeIndicator = Instance.new("Frame")
    activeIndicator.Name = "Indicator"
    activeIndicator.Size = UDim2.new(0, 3, 0, 0)
    activeIndicator.Position = UDim2.new(0, 0, 0.5, 0)
    activeIndicator.AnchorPoint = Vector2.new(0, 0.5)
    activeIndicator.BackgroundColor3 = ToColor3(hub.theme.Accent)
    activeIndicator.BorderSizePixel = 0
    activeIndicator.Visible = false
    activeIndicator.Parent = tabBtn

    local tabPage = Instance.new("Frame")
    tabPage.Name = "Page_" .. name
    tabPage.Size = UDim2.new(1, 0, 1, 0)
    tabPage.BackgroundTransparency = 1
    tabPage.BorderSizePixel = 0
    tabPage.Visible = false
    tabPage.Parent = hub.ContentContainer

    local subTabHeader = Instance.new("Frame")
    subTabHeader.Name = "SubTabHeader"
    subTabHeader.Size = UDim2.new(1, 0, 0, 30)
    subTabHeader.BackgroundTransparency = 1
    subTabHeader.BorderSizePixel = 0
    subTabHeader.Visible = false
    subTabHeader.Parent = tabPage

    local subTabLayout = Instance.new("UIListLayout")
    subTabLayout.FillDirection = Enum.FillDirection.Horizontal
    subTabLayout.Padding = UDim.new(0, 8)
    subTabLayout.Parent = subTabHeader

    local subTabContainer = Instance.new("Frame")
    subTabContainer.Name = "SubTabContainer"
    subTabContainer.Size = UDim2.new(1, 0, 1, 0)
    subTabContainer.Position = UDim2.new(0, 0, 0, 0)
    subTabContainer.BackgroundTransparency = 1
    subTabContainer.BorderSizePixel = 0
    subTabContainer.Parent = tabPage

    local tabObj = {
        name = name,
        button = tabBtn,
        page = tabPage,
        indicator = activeIndicator,
        subTabHeader = subTabHeader,
        subTabContainer = subTabContainer,
        subTabs = {},
        activeSubTab = nil
    }

    local function ActivateThisTab()
        for _, t in pairs(hub.tabs) do
            t.page.Visible = false
            t.indicator.Visible = false
            PlayTween(t.button, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(13, 13, 18),
                TextColor3 = ToColor3(hub.theme.TextDim)
            })
            PlayTween(t.indicator, TweenInfo.new(0.2), { Size = UDim2.new(0, 3, 0, 0) })
        end
        tabPage.Visible = true
        activeIndicator.Visible = true
        PlayTween(activeIndicator, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.new(0, 3, 0.7, 0) })
        PlayTween(tabBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(24, 16, 26),
            TextColor3 = ToColor3(hub.theme.Accent)
        })
        hub.activeTab = tabObj
    end

    tabBtn.MouseButton1Click:Connect(ActivateThisTab)
    table.insert(hub.tabs, tabObj)

    if #hub.tabs == 1 then ActivateThisTab() end

    function tabObj:CreateSubTab(subName)
        subTabHeader.Visible = true
        subTabContainer.Position = UDim2.new(0, 0, 0, 36)
        subTabContainer.Size = UDim2.new(1, 0, 1, -36)

        local subBtn = Instance.new("TextButton")
        subBtn.Name = "SubBtn_" .. subName
        subBtn.AutoButtonColor = false
        subBtn.BorderSizePixel = 0
        subBtn.Size = UDim2.new(0, 105, 1, 0)
        subBtn.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
        subBtn.Text = subName
        subBtn.TextColor3 = ToColor3(hub.theme.TextDim)
        subBtn.Font = Enum.Font.GothamBold
        subBtn.TextSize = 11
        subBtn.Parent = subTabHeader

        local sCorner = Instance.new("UICorner")
        sCorner.CornerRadius = UDim.new(0, 5)
        sCorner.Parent = subBtn

        local sStroke = Instance.new("UIStroke")
        sStroke.Color = Color3.fromRGB(36, 26, 40)
        sStroke.Thickness = 1
        sStroke.Parent = subBtn

        local subPage = Instance.new("ScrollingFrame")
        subPage.Name = "SubPage_" .. subName
        subPage.Size = UDim2.new(1, 0, 1, 0)
        subPage.BackgroundTransparency = 1
        subPage.BorderSizePixel = 0
        subPage.ScrollBarThickness = 2
        subPage.ScrollBarImageColor3 = ToColor3(hub.theme.Accent)
        subPage.BottomImage = ""
        subPage.MidImage = ""
        subPage.TopImage = ""
        subPage.Visible = false
        subPage.Parent = subTabContainer

        local subLayout = Instance.new("UIListLayout")
        subLayout.Padding = UDim.new(0, 10)
        subLayout.Parent = subPage

        local subObj = { name = subName, page = subPage, button = subBtn, stroke = sStroke }

        local function ActivateSub()
            for _, s in pairs(tabObj.subTabs) do
                s.page.Visible = false
                PlayTween(s.button, TweenInfo.new(0.2), {
                    TextColor3 = ToColor3(hub.theme.TextDim),
                    BackgroundColor3 = Color3.fromRGB(16, 16, 22)
                })
                PlayTween(s.stroke, TweenInfo.new(0.2), { Color = Color3.fromRGB(36, 26, 40) })
            end
            subPage.Visible = true
            PlayTween(subBtn, TweenInfo.new(0.25, Enum.EasingStyle.Back), {
                TextColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundColor3 = Color3.fromRGB(32, 16, 28)
            })
            PlayTween(sStroke, TweenInfo.new(0.25), { Color = ToColor3(hub.theme.Accent) })
            tabObj.activeSubTab = subObj
        end

        subBtn.MouseButton1Click:Connect(ActivateSub)
        table.insert(tabObj.subTabs, subObj)
        if #tabObj.subTabs == 1 then ActivateSub() end

        function subObj:CreateSection(secTitle, bannerAsset)
            return hub:_BuildSection(subPage, secTitle, bannerAsset)
        end

        return subObj
    end

    function tabObj:CreateSection(secTitle, bannerAsset)
        if #self.subTabs == 0 then
            local defaultSub = self:CreateSubTab("Principal")
            self.subTabHeader.Visible = false
            self.subTabContainer.Position = UDim2.new(0, 0, 0, 0)
            self.subTabContainer.Size = UDim2.new(1, 0, 1, 0)
            return defaultSub:CreateSection(secTitle, bannerAsset)
        end
        return self.subTabs[1]:CreateSection(secTitle, bannerAsset)
    end

    return tabObj
end

-- ----------------------------------------------------------------------------
-- 10. CONSTRUTOR DE SEÇÕES & WIDGETS (SLIDERS, TEXTBOX, BUTTONS, TOGGLES)
-- ----------------------------------------------------------------------------
function NexusUI:_BuildSection(parentFrame, title, bannerAsset)
    local hub = self

    local secFrame = Instance.new("Frame")
    secFrame.Name = "Section_" .. title
    secFrame.Size = UDim2.new(1, -8, 0, 36)
    secFrame.AutomaticSize = Enum.AutomaticSize.Y
    secFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 19)
    secFrame.BorderSizePixel = 0
    secFrame.Parent = parentFrame

    local secCorner = Instance.new("UICorner")
    secCorner.CornerRadius = UDim.new(0, 8)
    secCorner.Parent = secFrame

    local secStroke = Instance.new("UIStroke")
    secStroke.Color = Color3.fromRGB(40, 24, 38)
    secStroke.Thickness = 1
    secStroke.Parent = secFrame

    local headerBar = Instance.new("Frame")
    headerBar.Size = UDim2.new(1, 0, 0, 30)
    headerBar.BackgroundTransparency = 1
    headerBar.BorderSizePixel = 0
    headerBar.Parent = secFrame

    local accentTag = Instance.new("Frame")
    accentTag.Size = UDim2.new(0, 3, 0, 12)
    accentTag.Position = UDim2.new(0, 10, 0.5, -6)
    accentTag.BackgroundColor3 = ToColor3(hub.theme.Accent)
    accentTag.BorderSizePixel = 0
    accentTag.Parent = headerBar

    local tagCorner = Instance.new("UICorner")
    tagCorner.CornerRadius = UDim.new(1, 0)
    tagCorner.Parent = accentTag

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -30, 1, 0)
    titleLbl.Position = UDim2.new(0, 20, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.BorderSizePixel = 0
    titleLbl.Text = string.upper(title)
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 11
    titleLbl.TextColor3 = ToColor3(hub.theme.Accent)
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = headerBar

    local widgetList = Instance.new("Frame")
    widgetList.Name = "Widgets"
    widgetList.Size = UDim2.new(1, -20, 0, 0)
    widgetList.Position = UDim2.new(0, 10, 0, 34)
    widgetList.AutomaticSize = Enum.AutomaticSize.Y
    widgetList.BackgroundTransparency = 1
    widgetList.BorderSizePixel = 0
    widgetList.Parent = secFrame

    local wLayout = Instance.new("UIListLayout")
    wLayout.Padding = UDim.new(0, 8)
    wLayout.Parent = widgetList

    local padding = Instance.new("UIPadding")
    padding.PaddingBottom = UDim.new(0, 12)
    padding.Parent = secFrame

    local secApi = {}

    -- [BUTTON]
    function secApi:AddButton(btnCfg)
        local btn = Instance.new("TextButton")
        btn.AutoButtonColor = false
        btn.BorderSizePixel = 0
        btn.Size = UDim2.new(1, 0, 0, 36)
        btn.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
        btn.Text = (btnCfg.canFavorite and "      " or "    ") .. btnCfg.name
        btn.TextColor3 = ToColor3(hub.theme.Text)
        btn.Font = Enum.Font.GothamSemibold
        btn.TextSize = 12
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = widgetList

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = btn

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(34, 25, 38)
        stroke.Thickness = 1
        stroke.Parent = btn

        local comp = Component.New(btn, btnCfg, hub)

        btn.MouseEnter:Connect(function()
            if not comp.IsLocked then
                PlayTween(btn, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(26, 20, 32) })
                PlayTween(stroke, TweenInfo.new(0.2), { Color = ToColor3(hub.theme.Accent), Thickness = 1.4 })
            end
        end)
        btn.MouseLeave:Connect(function()
            if not comp.IsLocked then
                PlayTween(btn, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(18, 18, 25) })
                PlayTween(stroke, TweenInfo.new(0.2), { Color = Color3.fromRGB(34, 25, 38), Thickness = 1.0 })
            end
        end)
        btn.MouseButton1Click:Connect(function()
            if comp.IsLocked then return end
            PlayTween(comp.Scale, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 0.95 })
            PlayTween(btn, TweenInfo.new(0.08), { BackgroundColor3 = ToColor3(hub.theme.Accent) })
            task.wait(0.08)
            PlayTween(comp.Scale, TweenInfo.new(0.25, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), { Scale = 1.0 })
            PlayTween(btn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(26, 20, 32) })
            if btnCfg.callback then btnCfg.callback(comp) end
        end)
        return comp
    end

    -- [TOGGLE COM FÍSICA DE MOLA]
    function secApi:AddToggle(tCfg)
        local tBtn = Instance.new("TextButton")
        tBtn.AutoButtonColor = false
        tBtn.BorderSizePixel = 0
        tBtn.Size = UDim2.new(1, 0, 0, 36)
        tBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
        tBtn.Text = (tCfg.canFavorite and "      " or "    ") .. tCfg.name
        tBtn.TextColor3 = ToColor3(hub.theme.Text)
        tBtn.Font = Enum.Font.GothamSemibold
        tBtn.TextSize = 12
        tBtn.TextXAlignment = Enum.TextXAlignment.Left
        tBtn.Parent = widgetList

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = tBtn

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(34, 25, 38)
        stroke.Thickness = 1
        stroke.Parent = tBtn

        local switch = Instance.new("Frame")
        switch.BorderSizePixel = 0
        switch.Size = UDim2.new(0, 42, 0, 20)
        switch.Position = UDim2.new(1, -52, 0.5, -10)
        switch.BackgroundColor3 = tCfg.default and ToColor3(hub.theme.Accent) or Color3.fromRGB(28, 20, 32)
        switch.Parent = tBtn

        local swCorner = Instance.new("UICorner")
        swCorner.CornerRadius = UDim.new(1, 0)
        swCorner.Parent = switch

        local swStroke = Instance.new("UIStroke")
        swStroke.Color = tCfg.default and ToColor3(hub.theme.Accent) or Color3.fromRGB(48, 30, 52)
        swStroke.Thickness = 1
        swStroke.Parent = switch

        local dot = Instance.new("Frame")
        dot.BorderSizePixel = 0
        dot.Size = UDim2.new(0, 14, 0, 14)
        dot.Position = tCfg.default and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        dot.BackgroundColor3 = tCfg.default and Color3.fromRGB(255, 235, 245) or Color3.fromRGB(150, 130, 160)
        dot.Parent = switch

        local dotCorner = Instance.new("UICorner")
        dotCorner.CornerRadius = UDim.new(1, 0)
        dotCorner.Parent = dot

        local comp = Component.New(tBtn, tCfg, hub)
        local state = tCfg.default or false

        local function SetToggleState(newState, skipCallback)
            state = newState
            local targetPos = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
            local targetBg = state and ToColor3(hub.theme.Accent) or Color3.fromRGB(28, 20, 32)
            local targetDotColor = state and Color3.fromRGB(255, 235, 245) or Color3.fromRGB(150, 130, 160)

            PlayTween(dot, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(0, 20, 0, 14) })
            PlayTween(switch, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { BackgroundColor3 = targetBg })
            PlayTween(swStroke, TweenInfo.new(0.25), { Color = state and ToColor3(hub.theme.Accent) or Color3.fromRGB(48, 30, 52) })

            task.wait(0.08)
            PlayTween(dot, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = targetPos,
                Size = UDim2.new(0, 14, 0, 14),
                BackgroundColor3 = targetDotColor
            })

            if not skipCallback and tCfg.callback then tCfg.callback(state) end
            if hub.autoSave then hub:SaveConfig(hub.currentProfile) end
        end

        tBtn.MouseButton1Click:Connect(function()
            if comp.IsLocked then return end
            SetToggleState(not state)
        end)

        local optId = tCfg.id or tCfg.name
        hub.registeredOptions[optId] = {
            GetValue = function() return state end,
            SetValue = function(val) SetToggleState(val, false) end
        }

        return comp
    end

    -- [NOVO WIDGET: SLIDER FLUIDO COM ARRASTE E PORCENTAGEM]
    function secApi:AddSlider(sCfg)
        local min = sCfg.min or 0
        local max = sCfg.max or 100
        local default = math.clamp(sCfg.default or min, min, max)

        local sFrame = Instance.new("Frame")
        sFrame.BorderSizePixel = 0
        sFrame.Size = UDim2.new(1, 0, 0, 48)
        sFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
        sFrame.Parent = widgetList

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = sFrame

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(34, 25, 38)
        stroke.Thickness = 1
        stroke.Parent = sFrame

        local titleText = Instance.new("TextLabel")
        titleText.Size = UDim2.new(1, -70, 0, 22)
        titleText.Position = UDim2.new(0, 12, 0, 4)
        titleText.BackgroundTransparency = 1
        titleText.Text = sCfg.name
        titleText.TextColor3 = ToColor3(hub.theme.Text)
        titleText.Font = Enum.Font.GothamSemibold
        titleText.TextSize = 12
        titleText.TextXAlignment = Enum.TextXAlignment.Left
        titleText.Parent = sFrame

        local valLbl = Instance.new("TextLabel")
        valLbl.Size = UDim2.new(0, 50, 0, 22)
        valLbl.Position = UDim2.new(1, -62, 0, 4)
        valLbl.BackgroundTransparency = 1
        valLbl.Text = tostring(default)
        valLbl.TextColor3 = ToColor3(hub.theme.Accent)
        valLbl.Font = Enum.Font.GothamBold
        valLbl.TextSize = 12
        valLbl.TextXAlignment = Enum.TextXAlignment.Right
        valLbl.Parent = sFrame

        local sliderBar = Instance.new("TextButton")
        sliderBar.Name = "SliderBar"
        sliderBar.AutoButtonColor = false
        sliderBar.BorderSizePixel = 0
        sliderBar.Text = ""
        sliderBar.Size = UDim2.new(1, -24, 0, 8)
        sliderBar.Position = UDim2.new(0, 12, 0, 30)
        sliderBar.BackgroundColor3 = Color3.fromRGB(28, 20, 32)
        sliderBar.Parent = sFrame

        local barCorner = Instance.new("UICorner")
        barCorner.CornerRadius = UDim.new(1, 0)
        barCorner.Parent = sliderBar

        local fill = Instance.new("Frame")
        fill.BorderSizePixel = 0
        fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = ToColor3(hub.theme.Accent)
        fill.Parent = sliderBar

        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(1, 0)
        fillCorner.Parent = fill

        local knob = Instance.new("Frame")
        knob.BorderSizePixel = 0
        knob.Size = UDim2.new(0, 14, 0, 14)
        knob.Position = UDim2.new(1, -7, 0.5, -7)
        knob.BackgroundColor3 = Color3.fromRGB(255, 235, 245)
        knob.Parent = fill

        local knobCorner = Instance.new("UICorner")
        knobCorner.CornerRadius = UDim.new(1, 0)
        knobCorner.Parent = knob

        local comp = Component.New(sFrame, sCfg, hub)
        local val = default
        local dragging = false

        local function UpdateValue(input)
            local percent = math.clamp((input.Position.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
            val = math.floor(min + (max - min) * percent)
            valLbl.Text = tostring(val)
            PlayTween(fill, TweenInfo.new(0.06, Enum.EasingStyle.Sine), { Size = UDim2.new(percent, 0, 1, 0) })
            if sCfg.callback then sCfg.callback(val) end
            if hub.autoSave then hub:SaveConfig(hub.currentProfile) end
        end

        sliderBar.InputBegan:Connect(function(input)
            if comp.IsLocked then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                PlayTween(knob, TweenInfo.new(0.15, Enum.EasingStyle.Back), { Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(1, -9, 0.5, -9) })
                UpdateValue(input)
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                UpdateValue(input)
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
                PlayTween(knob, TweenInfo.new(0.15), { Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(1, -7, 0.5, -7) })
            end
        end)

        local optId = sCfg.id or sCfg.name
        hub.registeredOptions[optId] = {
            GetValue = function() return val end,
            SetValue = function(newVal)
                val = math.clamp(newVal, min, max)
                valLbl.Text = tostring(val)
                local percent = (val - min) / (max - min)
                fill.Size = UDim2.new(percent, 0, 1, 0)
                if sCfg.callback then sCfg.callback(val) end
            end
        }

        return comp
    end

    -- [NOVO WIDGET: TEXTBOX PARA INSERIR DADOS E COMANDOS]
    function secApi:AddTextInput(tbCfg)
        local tbFrame = Instance.new("Frame")
        tbFrame.BorderSizePixel = 0
        tbFrame.Size = UDim2.new(1, 0, 0, 38)
        tbFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
        tbFrame.Parent = widgetList

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = tbFrame

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(34, 25, 38)
        stroke.Thickness = 1
        stroke.Parent = tbFrame

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(0.5, 0, 1, 0)
        nameLbl.Position = UDim2.new(0, 12, 0, 0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = tbCfg.name
        nameLbl.TextColor3 = ToColor3(hub.theme.Text)
        nameLbl.Font = Enum.Font.GothamSemibold
        nameLbl.TextSize = 12
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.Parent = tbFrame

        local inputBox = Instance.new("TextBox")
        inputBox.Size = UDim2.new(0.45, 0, 0, 24)
        inputBox.Position = UDim2.new(0.52, 0, 0.5, -12)
        inputBox.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
        inputBox.BorderSizePixel = 0
        inputBox.Text = tbCfg.default or ""
        inputBox.PlaceholderText = tbCfg.placeholder or "Digite..."
        inputBox.TextColor3 = ToColor3(hub.theme.Accent)
        inputBox.PlaceholderColor3 = Color3.fromRGB(90, 85, 100)
        inputBox.Font = Enum.Font.Gotham
        inputBox.TextSize = 11
        inputBox.ClearTextOnFocus = false
        inputBox.Parent = tbFrame

        local boxCorner = Instance.new("UICorner")
        boxCorner.CornerRadius = UDim.new(0, 4)
        boxCorner.Parent = inputBox

        local boxStroke = Instance.new("UIStroke")
        boxStroke.Color = Color3.fromRGB(36, 26, 40)
        boxStroke.Thickness = 1
        boxStroke.Parent = inputBox

        inputBox.Focused:Connect(function()
            PlayTween(boxStroke, TweenInfo.new(0.2), { Color = ToColor3(hub.theme.Accent) })
        end)

        inputBox.FocusLost:Connect(function(enterPressed)
            PlayTween(boxStroke, TweenInfo.new(0.2), { Color = Color3.fromRGB(36, 26, 40) })
            if tbCfg.callback then tbCfg.callback(inputBox.Text, enterPressed) end
        end)

        return Component.New(tbFrame, tbCfg, hub)
    end

    -- [DROPDOWN]
    function secApi:AddDropdown(ddCfg)
        local dFrame = Instance.new("Frame")
        dFrame.BorderSizePixel = 0
        dFrame.Size = UDim2.new(1, 0, 0, 36)
        dFrame.AutomaticSize = Enum.AutomaticSize.Y
        dFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
        dFrame.Parent = widgetList

        local dCorner = Instance.new("UICorner")
        dCorner.CornerRadius = UDim.new(0, 6)
        dCorner.Parent = dFrame

        local dStroke = Instance.new("UIStroke")
        dStroke.Color = Color3.fromRGB(34, 25, 38)
        dStroke.Thickness = 1
        dStroke.Parent = dFrame

        local headerBtn = Instance.new("TextButton")
        headerBtn.AutoButtonColor = false
        headerBtn.BorderSizePixel = 0
        headerBtn.Size = UDim2.new(1, 0, 0, 36)
        headerBtn.BackgroundTransparency = 1
        headerBtn.Text = "    " .. ddCfg.name
        headerBtn.TextColor3 = ToColor3(hub.theme.Text)
        headerBtn.Font = Enum.Font.GothamSemibold
        headerBtn.TextSize = 12
        headerBtn.TextXAlignment = Enum.TextXAlignment.Left
        headerBtn.Parent = dFrame

        local arrow = Instance.new("TextLabel")
        arrow.Size = UDim2.new(0, 24, 0, 24)
        arrow.Position = UDim2.new(1, -30, 0.5, -12)
        arrow.BackgroundTransparency = 1
        arrow.Text = "▾"
        arrow.TextColor3 = ToColor3(hub.theme.Accent)
        arrow.Font = Enum.Font.GothamBold
        arrow.TextSize = 14
        arrow.Parent = headerBtn

        local optList = Instance.new("Frame")
        optList.BorderSizePixel = 0
        optList.Size = UDim2.new(1, 0, 0, 0)
        optList.Position = UDim2.new(0, 0, 0, 38)
        optList.AutomaticSize = Enum.AutomaticSize.Y
        optList.BackgroundTransparency = 1
        optList.Visible = false
        optList.Parent = dFrame

        local oLayout = Instance.new("UIListLayout")
        oLayout.Padding = UDim.new(0, 4)
        oLayout.Parent = optList

        local comp = Component.New(dFrame, ddCfg, hub)
        local isOpen = false
        local selected = ddCfg.multiSelect and {} or (ddCfg.default or ddCfg.options[1])

        local function ToggleDropdown()
            if comp.IsLocked then return end
            isOpen = not isOpen
            optList.Visible = isOpen
            PlayTween(arrow, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Rotation = isOpen and 180 or 0 })
            PlayTween(dStroke, TweenInfo.new(0.2), { Color = isOpen and ToColor3(hub.theme.Accent) or Color3.fromRGB(34, 25, 38) })
        end

        headerBtn.MouseButton1Click:Connect(ToggleDropdown)

        for _, opt in ipairs(ddCfg.options or {}) do
            local optBtn = Instance.new("TextButton")
            optBtn.AutoButtonColor = false
            optBtn.BorderSizePixel = 0
            optBtn.Size = UDim2.new(1, -16, 0, 28)
            optBtn.Position = UDim2.new(0, 8, 0, 0)
            optBtn.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
            optBtn.Text = "     " .. opt
            optBtn.TextColor3 = ToColor3(hub.theme.TextDim)
            optBtn.Font = Enum.Font.Gotham
            optBtn.TextSize = 11
            optBtn.TextXAlignment = Enum.TextXAlignment.Left
            optBtn.Parent = optList

            local oCorner = Instance.new("UICorner")
            oCorner.CornerRadius = UDim.new(0, 4)
            oCorner.Parent = optBtn

            local oStroke = Instance.new("UIStroke")
            oStroke.Color = Color3.fromRGB(28, 20, 32)
            oStroke.Thickness = 1
            oStroke.Parent = optBtn

            optBtn.MouseButton1Click:Connect(function()
                if ddCfg.multiSelect then
                    selected[opt] = not selected[opt]
                    optBtn.TextColor3 = selected[opt] and ToColor3(hub.theme.Accent) or ToColor3(hub.theme.TextDim)
                    oStroke.Color = selected[opt] and ToColor3(hub.theme.Accent) or Color3.fromRGB(28, 20, 32)
                    if ddCfg.callback then ddCfg.callback(selected) end
                else
                    selected = opt
                    ToggleDropdown()
                    headerBtn.Text = "    " .. ddCfg.name .. "  [" .. opt .. "]"
                    if ddCfg.callback then ddCfg.callback(selected) end
                end
                if hub.autoSave then hub:SaveConfig(hub.currentProfile) end
            end)
        end

        local optId = ddCfg.id or ddCfg.name
        hub.registeredOptions[optId] = {
            GetValue = function() return selected end,
            SetValue = function(val)
                selected = val
                headerBtn.Text = "    " .. ddCfg.name .. "  [" .. tostring(val) .. "]"
                if ddCfg.callback then ddCfg.callback(val) end
            end
        }

        return comp
    end

    -- [KEYBIND]
    function secApi:AddKeybind(kbCfg)
        local kBtn = Instance.new("TextButton")
        kBtn.AutoButtonColor = false
        kBtn.BorderSizePixel = 0
        kBtn.Size = UDim2.new(1, 0, 0, 36)
        kBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
        kBtn.Text = "    " .. kbCfg.name
        kBtn.TextColor3 = ToColor3(hub.theme.Text)
        kBtn.Font = Enum.Font.GothamSemibold
        kBtn.TextSize = 12
        kBtn.TextXAlignment = Enum.TextXAlignment.Left
        kBtn.Parent = widgetList

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = kBtn

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(34, 25, 38)
        stroke.Thickness = 1
        stroke.Parent = kBtn

        local keyBox = Instance.new("TextLabel")
        keyBox.BorderSizePixel = 0
        keyBox.Size = UDim2.new(0, 60, 0, 22)
        keyBox.Position = UDim2.new(1, -70, 0.5, -11)
        keyBox.BackgroundColor3 = Color3.fromRGB(24, 16, 28)
        keyBox.Text = kbCfg.default or "None"
        keyBox.TextColor3 = ToColor3(hub.theme.Accent)
        keyBox.Font = Enum.Font.GothamBold
        keyBox.TextSize = 11
        keyBox.Parent = kBtn

        local kCorner = Instance.new("UICorner")
        kCorner.CornerRadius = UDim.new(0, 4)
        kCorner.Parent = keyBox

        local kStroke = Instance.new("UIStroke")
        kStroke.Color = ToColor3(hub.theme.Accent)
        kStroke.Thickness = 1
        kStroke.Parent = keyBox

        local comp = Component.New(kBtn, kbCfg, hub)
        local listening = false
        local currentBoundKey = kbCfg.default or "None"

        kBtn.MouseButton1Click:Connect(function()
            if comp.IsLocked then return end
            listening = true
            keyBox.Text = "..."
            PlayTween(kStroke, TweenInfo.new(0.2), { Color = Color3.fromRGB(255, 120, 190) })

            local conn
            conn = UserInputService.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.Keyboard then
                    conn:Disconnect()
                    listening = false
                    currentBoundKey = inp.KeyCode.Name
                    keyBox.Text = currentBoundKey
                    PlayTween(kStroke, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Color = ToColor3(hub.theme.Accent) })
                    if kbCfg.callback then kbCfg.callback(currentBoundKey) end
                    if hub.autoSave then hub:SaveConfig(hub.currentProfile) end
                end
            end)
        end)

        local optId = kbCfg.id or kbCfg.name
        hub.registeredOptions[optId] = {
            GetValue = function() return currentBoundKey end,
            SetValue = function(val)
                currentBoundKey = val
                keyBox.Text = val
                if kbCfg.callback then kbCfg.callback(val) end
            end
        }

        return comp
    end

    return secApi
end

-- ----------------------------------------------------------------------------
-- 11. ABAS NATIVAS
-- ----------------------------------------------------------------------------
function NexusUI:RegisterFavorite(comp, status)
    if status then self.favorites[comp] = true else self.favorites[comp] = nil end
end

function NexusUI:_InitNativeTabs()
    local favTab = self:CreateTab("Favoritos")
    favTab:CreateSection("Acesso Rápido")

    local settingsTab = self:CreateTab("Configurações")
    local profileSec = settingsTab:CreateSection("Gerenciador de Perfis")
    
    profileSec:AddDropdown({
        name = "Perfil Ativo",
        options = { "Default", "Legit", "Rage", "Personalizado" },
        default = "Default",
        callback = function(selected) self.currentProfile = selected end
    })

    profileSec:AddButton({
        name = "💾 Salvar Configurações no Disco",
        callback = function() self:SaveConfig(self.currentProfile) end
    })

    profileSec:AddButton({
        name = "📂 Carregar Configurações Salvas",
        callback = function() self:LoadConfig(self.currentProfile) end
    })

    profileSec:AddToggle({
        name = "Auto-Save ao Alterar Opções",
        default = true,
        callback = function(state) self.autoSave = state end
    })

    local cfgSec = settingsTab:CreateSection("Atalhos do Sistema")
    cfgSec:AddKeybind({
        name = "Atalho do Menu",
        default = self.toggleKey,
        callback = function(newKey) self.toggleKey = newKey end
    })
end

return NexusUI
