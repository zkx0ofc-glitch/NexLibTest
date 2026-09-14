-- ============================================================================
-- NEXUS UI LIBRARY - 100% PURE BLACK & NEON PINK (NO WHITE ARTIFACTS)
-- Architecture: Object-Oriented (Metatables) & Roblox Luau UI Framework
-- ============================================================================

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- ----------------------------------------------------------------------------
-- 1. UTILITIES & THEME CONFIGURATION (PRETO ABSOLUTO & ROSA NEON)
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

local NexusUI = {}
NexusUI.__index = NexusUI

-- PALETA DE CORES: 100% PRETO, GRAFITE & ROSA NEON (SEM BRANCO)
NexusUI.DefaultTheme = {
    BackgroundPrimary   = { r = 10, g = 10, b = 14, a = 1.0 },   -- Preto Absoluto Sólido
    BackgroundSecondary = { r = 14, g = 14, b = 20, a = 1.0 },   -- Grafite Escuro
    BackgroundWidget    = { r = 18, g = 18, b = 25, a = 1.0 },   -- Fundo dos Itens
    BackgroundHover     = { r = 26, g = 20, b = 32, a = 1.0 },   -- Hover Rosa Sutil
    
    Outline             = { r = 255, g = 42, b = 133, a = 1.0 }, -- Rosa Neon (#FF2A85)
    OutlineSubtle       = { r = 45, g = 25, b = 40, a = 1.0 },   -- Borda Secundária
    
    Accent              = { r = 255, g = 42, b = 133, a = 1.0 }, -- Rosa Neon Ativo
    AccentHover         = { r = 255, g = 75, b = 155, a = 1.0 },
    
    Text                = { r = 245, g = 240, b = 248, a = 1.0 }, -- Cinza Rosado Claro (Sem Branco Puro)
    TextDim             = { r = 140, g = 135, b = 150, a = 1.0 }, -- Muted Text
    LockedOverlay       = { r = 8, g = 8, b = 12, a = 0.90 }     -- Overlay Escuro
}

-- ----------------------------------------------------------------------------
-- 2. DRAGGABLE CONTROLLER (Arrastar a Janela pelo Topo)
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
            PlayTween(mainFrame, TweenInfo.new(0.05, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            })
        end
    end)
end

-- ----------------------------------------------------------------------------
-- 3. BASE COMPONENT (Tags, Lock Overlay & Favoritos)
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

    -- Container de Tags Dinâmicas
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

    -- Camada de Bloqueio (Lock Overlay Rosa Escuro)
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
    lockStroke.Color = Color3.fromRGB(160, 25, 65)
    lockStroke.Thickness = 1
    lockStroke.Parent = self.LockOverlay
    self.LockOverlay.Parent = self.Instance

    -- Botão de Favorito (Sem piscar branco)
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

        starBtn.MouseButton1Click:Connect(function()
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

        badge.Parent = self.TagContainer
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
        PlayTween(self.StarButton, TweenInfo.new(0.2), {
            TextColor3 = self.IsFavorite and Color3.fromRGB(255, 42, 133) or Color3.fromRGB(65, 60, 75)
        })
    end
    if self.Hub and self.Hub.RegisterFavorite then
        self.Hub:RegisterFavorite(self, self.IsFavorite)
    end
end

-- ----------------------------------------------------------------------------
-- 4. HUB PRINCIPAL (100% PRETO + CONTORNO ROSA NEON)
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
        favorites = {}
    }
    setmetatable(hub, { __index = NexusUI })

    -- 1. ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NexusUI_Framework"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = GetGuiContainer()
    hub.ScreenGui = screenGui

    -- 2. Janela Principal (Preto 100% Sólido)
    local main = Instance.new("Frame")
    main.Name = "MainHub"
    main.Size = UDim2.new(0, bounds.width, 0, bounds.height)
    main.Position = UDim2.new(0, bounds.x, 0, bounds.y)
    main.BackgroundColor3 = Color3.fromRGB(10, 10, 14) -- 100% PRETO
    main.BackgroundTransparency = 0                     -- ANTI-VAZAMENTO
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Parent = screenGui
    hub.MainFrame = main

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 10)
    mainCorner.Parent = main

    -- CONTORNO ROSA NEON
    local pinkStroke = Instance.new("UIStroke")
    pinkStroke.Name = "NeonOutline"
    pinkStroke.Color = ToColor3(theme.Outline)
    pinkStroke.Thickness = 1.8
    pinkStroke.Parent = main

    -- 3. TopBar (Cabeçalho)
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

    closeBtn.MouseButton1Click:Connect(function() hub:Toggle() end)

    -- 4. Sidebar (Menu Lateral)
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

    -- 5. Content Container
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

function NexusUI:Toggle()
    self.isOpen = not self.isOpen
    self.MainFrame.Visible = self.isOpen
end

function NexusUI:Update(dt) end

-- ----------------------------------------------------------------------------
-- 5. CRIAÇÃO DE ABAS & SUB-ABAS
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
            t.button.BackgroundColor3 = Color3.fromRGB(13, 13, 18)
            t.button.TextColor3 = ToColor3(hub.theme.TextDim)
            t.indicator.Size = UDim2.new(0, 3, 0, 0)
        end
        tabPage.Visible = true
        activeIndicator.Visible = true
        PlayTween(activeIndicator, TweenInfo.new(0.2), { Size = UDim2.new(0, 3, 0.65, 0) })
        tabBtn.BackgroundColor3 = Color3.fromRGB(24, 16, 26)
        tabBtn.TextColor3 = ToColor3(hub.theme.Accent)
        hub.activeTab = tabObj
    end

    tabBtn.MouseButton1Click:Connect(ActivateThisTab)
    table.insert(hub.tabs, tabObj)

    if #hub.tabs == 1 then
        ActivateThisTab()
    end

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
                s.button.TextColor3 = ToColor3(hub.theme.TextDim)
                s.button.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
                s.stroke.Color = Color3.fromRGB(36, 26, 40)
            end
            subPage.Visible = true
            subBtn.TextColor3 = ToColor3(hub.theme.Accent)
            subBtn.BackgroundColor3 = Color3.fromRGB(32, 16, 28)
            sStroke.Color = ToColor3(hub.theme.Accent)
            tabObj.activeSubTab = subObj
        end

        subBtn.MouseButton1Click:Connect(ActivateSub)
        table.insert(tabObj.subTabs, subObj)

        if #tabObj.subTabs == 1 then
            ActivateSub()
        end

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
-- 6. CONSTRUTOR DE SEÇÕES & WIDGETS
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
                btn.BackgroundColor3 = Color3.fromRGB(26, 20, 32)
                stroke.Color = ToColor3(hub.theme.Accent)
            end
        end)
        btn.MouseLeave:Connect(function()
            if not comp.IsLocked then
                btn.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
                stroke.Color = Color3.fromRGB(34, 25, 38)
            end
        end)
        btn.MouseButton1Click:Connect(function()
            if comp.IsLocked then return end
            btn.BackgroundColor3 = ToColor3(hub.theme.Accent)
            task.wait(0.08)
            btn.BackgroundColor3 = Color3.fromRGB(26, 20, 32)
            if btnCfg.callback then btnCfg.callback(comp) end
        end)
        return comp
    end

    -- [TOGGLE]
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

        -- Trilho
        local switch = Instance.new("Frame")
        switch.BorderSizePixel = 0
        switch.Size = UDim2.new(0, 40, 0, 20)
        switch.Position = UDim2.new(1, -50, 0.5, -10)
        switch.BackgroundColor3 = tCfg.default and ToColor3(hub.theme.Accent) or Color3.fromRGB(28, 20, 32)
        switch.Parent = tBtn

        local swCorner = Instance.new("UICorner")
        swCorner.CornerRadius = UDim.new(1, 0)
        swCorner.Parent = switch

        local swStroke = Instance.new("UIStroke")
        swStroke.Color = tCfg.default and ToColor3(hub.theme.Accent) or Color3.fromRGB(48, 30, 52)
        swStroke.Thickness = 1
        swStroke.Parent = switch

        -- Círculo Deslizante (Rosa Pastel Suave quando ligado, Grafite quando desligado)
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

        tBtn.MouseButton1Click:Connect(function()
            if comp.IsLocked then return end
            state = not state
            PlayTween(switch, TweenInfo.new(0.2), {
                BackgroundColor3 = state and ToColor3(hub.theme.Accent) or Color3.fromRGB(28, 20, 32)
            })
            PlayTween(swStroke, TweenInfo.new(0.2), {
                Color = state and ToColor3(hub.theme.Accent) or Color3.fromRGB(48, 30, 52)
            })
            PlayTween(dot, TweenInfo.new(0.2), {
                Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
                BackgroundColor3 = state and Color3.fromRGB(255, 235, 245) or Color3.fromRGB(150, 130, 160)
            })
            if tCfg.callback then tCfg.callback(state) end
        end)
        return comp
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
        headerBtn.Text = "    " .. ddCfg.name .. "  ▾"
        headerBtn.TextColor3 = ToColor3(hub.theme.Text)
        headerBtn.Font = Enum.Font.GothamSemibold
        headerBtn.TextSize = 12
        headerBtn.TextXAlignment = Enum.TextXAlignment.Left
        headerBtn.Parent = dFrame

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

        headerBtn.MouseButton1Click:Connect(function()
            if comp.IsLocked then return end
            isOpen = not isOpen
            optList.Visible = isOpen
            headerBtn.Text = "    " .. ddCfg.name .. (isOpen and "  ▴" or "  ▾")
            dStroke.Color = isOpen and ToColor3(hub.theme.Accent) or Color3.fromRGB(34, 25, 38)
        end)

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
                    isOpen = false
                    optList.Visible = false
                    headerBtn.Text = "    " .. ddCfg.name .. "  [" .. opt .. "]  ▾"
                    dStroke.Color = Color3.fromRGB(34, 25, 38)
                    if ddCfg.callback then ddCfg.callback(selected) end
                end
            end)
        end
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

        -- Caixa da Tecla
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

        kBtn.MouseButton1Click:Connect(function()
            if comp.IsLocked then return end
            listening = true
            keyBox.Text = "..."
            kStroke.Color = Color3.fromRGB(255, 100, 180)

            local conn
            conn = UserInputService.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.Keyboard then
                    conn:Disconnect()
                    listening = false
                    keyBox.Text = inp.KeyCode.Name
                    kStroke.Color = ToColor3(hub.theme.Accent)
                    if kbCfg.callback then kbCfg.callback(inp.KeyCode.Name) end
                end
            end)
        end)
        return comp
    end

    return secApi
end

-- ----------------------------------------------------------------------------
-- 7. ABAS NATIVAS (Favoritos & Configurações)
-- ----------------------------------------------------------------------------
function NexusUI:RegisterFavorite(comp, status)
    if status then
        self.favorites[comp] = true
    else
        self.favorites[comp] = nil
    end
end

function NexusUI:_InitNativeTabs()
    local favTab = self:CreateTab("Favoritos")
    favTab:CreateSection("Acesso Rápido")

    local settingsTab = self:CreateTab("Configurações")
    local cfgSec = settingsTab:CreateSection("Geral")

    cfgSec:AddKeybind({
        name = "Atalho do Menu",
        default = self.toggleKey,
        callback = function(newKey)
            self.toggleKey = newKey
        end
    })
end

return NexusUI
