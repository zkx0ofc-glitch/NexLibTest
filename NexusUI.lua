-- ============================================================================
-- NEXUS UI LIBRARY (Luau / Roblox Edition)
-- Architecture: OOP with Metatables, TweenService Animations & Reactive State
-- ============================================================================

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- ----------------------------------------------------------------------------
-- 1. UTILITIES & CONTAINER RESOLUTION
-- ----------------------------------------------------------------------------
local function GetGuiContainer()
    local success, container = pcall(function()
        if gethui then return gethui() end
        return CoreGui
    end)
    if success and container then return container end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function ToColor3(colorData, default)
    if typeof(colorData) == "Color3" then return colorData end
    if type(colorData) == "table" then
        local r = colorData.r or colorData[1] or 255
        local g = colorData.g or colorData[2] or 255
        local b = colorData.b or colorData[3] or 255
        return Color3.fromRGB(r, g, b)
    end
    return default or Color3.fromRGB(255, 255, 255)
end

local function ToTransparency(colorData, default)
    if type(colorData) == "table" and colorData.a ~= nil then
        return 1 - math.clamp(colorData.a, 0, 1)
    end
    return default or 0
end

local function CreateTween(instance, info, properties)
    local tween = TweenService:Create(instance, info, properties)
    tween:Play()
    return tween
end

-- ----------------------------------------------------------------------------
-- 2. CORE LIBRARY OBJECT
-- ----------------------------------------------------------------------------
local NexusUI = {}
NexusUI.__index = NexusUI

-- Tema Padrão
NexusUI.DefaultTheme = {
    BackgroundPrimary   = { r = 16, g = 18, b = 24, a = 0.98 },
    BackgroundSecondary = { r = 22, g = 25, b = 34, a = 1.0 },
    Accent              = { r = 0, g = 180, b = 255, a = 1.0 },
    Text                = { r = 240, g = 240, b = 245, a = 1.0 },
    TextDim             = { r = 130, g = 135, b = 150, a = 1.0 },
    LockedOverlay       = { r = 10, g = 10, b = 15, a = 0.85 }
}

-- ----------------------------------------------------------------------------
-- 3. DRAGGABLE CONTROLLER (Arrastar a Janela pelo Cabeçalho)
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
            CreateTween(mainFrame, TweenInfo.new(0.08, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            })
        end
    end)
end

-- ----------------------------------------------------------------------------
-- 4. BASE COMPONENT CLASS (Tags Dinâmicas, Bloqueio & Favoritos)
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
    self.TagContainer.Size = UDim2.new(0, 0, 1, 0)
    self.TagContainer.Position = UDim2.new(1, -10, 0, 0)
    self.TagContainer.AnchorPoint = Vector2.new(1, 0)
    self.TagContainer.Parent = self.Instance

    local tagLayout = Instance.new("UIListLayout")
    tagLayout.FillDirection = Enum.FillDirection.Horizontal
    tagLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    tagLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    tagLayout.Padding = UDim.new(0, 6)
    tagLayout.Parent = self.TagContainer

    -- Camada de Bloqueio (Lock Overlay)
    self.LockOverlay = Instance.new("TextButton")
    self.LockOverlay.Name = "LockOverlay"
    self.LockOverlay.Size = UDim2.new(1, 0, 1, 0)
    self.LockOverlay.BackgroundColor3 = ToColor3(NexusUI.DefaultTheme.LockedOverlay)
    self.LockOverlay.BackgroundTransparency = 0.25
    self.LockOverlay.Text = "🔒 " .. self.LockReason
    self.LockOverlay.TextColor3 = Color3.fromRGB(255, 100, 100)
    self.LockOverlay.Font = Enum.Font.GothamBold
    self.LockOverlay.TextSize = 12
    self.LockOverlay.Visible = self.IsLocked
    self.LockOverlay.ZIndex = 15
    self.LockOverlay.AutoButtonColor = false

    local overlayCorner = Instance.new("UICorner")
    overlayCorner.CornerRadius = UDim.new(0, 6)
    overlayCorner.Parent = self.LockOverlay
    self.LockOverlay.Parent = self.Instance

    -- Botão de Favorito (Estrela)
    if self.Config.canFavorite then
        local starBtn = Instance.new("TextButton")
        starBtn.Name = "FavoriteStar"
        starBtn.Size = UDim2.new(0, 24, 0, 24)
        starBtn.Position = UDim2.new(0, 6, 0.5, -12)
        starBtn.BackgroundTransparency = 1
        starBtn.Text = "★"
        starBtn.TextColor3 = Color3.fromRGB(80, 85, 100)
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
    local color = ToColor3(colorData, Color3.fromRGB(0, 180, 255))

    if not tag then
        local badge = Instance.new("TextLabel")
        badge.Name = "Tag_" .. tostring(tagId)
        badge.AutomaticSize = Enum.AutomaticSize.X
        badge.Size = UDim2.new(0, 0, 0, 18)
        badge.BackgroundColor3 = color
        badge.BackgroundTransparency = 0.2
        badge.TextColor3 = Color3.fromRGB(255, 255, 255)
        badge.Font = Enum.Font.GothamBold
        badge.TextSize = 10
        badge.Text = " " .. tostring(text) .. " "
        badge.ZIndex = 8

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = badge
        badge.Parent = self.TagContainer

        self.Tags[tagId] = badge
    else
        tag.Text = " " .. tostring(text) .. " "
        tag.BackgroundColor3 = color
    end
end

function Component:RemoveTag(tagId)
    if self.Tags[tagId] then
        self.Tags[tagId]:Destroy()
        self.Tags[tagId] = nil
    end
end

function Component:SetLocked(state, reason)
    self.IsLocked = state
    if reason then self.LockReason = reason end
    self.LockOverlay.Text = "🔒 " .. self.LockReason
    self.LockOverlay.Visible = self.IsLocked
end

function Component:SetFavorite(status)
    if not self.Config.canFavorite then return end
    self.IsFavorite = status
    if self.StarButton then
        self.StarButton.TextColor3 = self.IsFavorite and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(80, 85, 100)
    end
    if self.Hub and self.Hub.RegisterFavorite then
        self.Hub:RegisterFavorite(self, self.IsFavorite)
    end
end

-- ----------------------------------------------------------------------------
-- 5. HUB BUILDER & METATABLE
-- ----------------------------------------------------------------------------
function NexusUI.CreateHub(config)
    config = config or {}
    local theme = config.theme or NexusUI.DefaultTheme
    local toggleKeyName = config.toggleKey or "Y"
    local bounds = config.bounds or { x = 200, y = 150, width = 850, height = 550 }

    local hub = {
        title = config.title or "NEXUS INTERACTIVE DASHBOARD",
        theme = theme,
        toggleKey = toggleKeyName,
        isOpen = true,
        tabs = {},
        activeTab = nil,
        favorites = {}
    }
    setmetatable(hub, { __index = NexusUI })

    -- 1. ScreenGui Container
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NexusUI_Framework"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = GetGuiContainer()
    hub.ScreenGui = screenGui

    -- 2. Janela Principal (Main Frame)
    local main = Instance.new("Frame")
    main.Name = "MainHub"
    main.Size = UDim2.new(0, bounds.width, 0, bounds.height)
    main.Position = UDim2.new(0, bounds.x, 0, bounds.y)
    main.BackgroundColor3 = ToColor3(theme.BackgroundPrimary)
    main.BackgroundTransparency = ToTransparency(theme.BackgroundPrimary)
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Parent = screenGui
    hub.MainFrame = main

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 10)
    mainCorner.Parent = main

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Color3.fromRGB(45, 50, 65)
    mainStroke.Thickness = 1.2
    mainStroke.Parent = main

    -- Gradiente de Fundo
    if theme.BackgroundGradient and theme.BackgroundGradient.Enabled then
        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new(ToColor3(theme.BackgroundGradient.StartColor), ToColor3(theme.BackgroundGradient.EndColor))
        gradient.Rotation = 45
        gradient.Parent = main
    end

    -- 3. TopBar (Cabeçalho com Draggable)
    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1, 0, 0, 48)
    topBar.BackgroundTransparency = 1
    topBar.Parent = main
    MakeDraggable(topBar, main)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -60, 1, 0)
    titleLabel.Position = UDim2.new(0, 20, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = hub.title
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 14
    titleLabel.TextColor3 = ToColor3(theme.Text)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = topBar

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 32, 0, 32)
    closeBtn.Position = UDim2.new(1, -40, 0.5, -16)
    closeBtn.BackgroundColor3 = Color3.fromRGB(230, 60, 60)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 12
    closeBtn.Parent = topBar

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn
    closeBtn.MouseButton1Click:Connect(function() hub:Toggle() end)

    -- 4. Sidebar (Navegação Lateral de Abas)
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, 190, 1, -48)
    sidebar.Position = UDim2.new(0, 0, 0, 48)
    sidebar.BackgroundColor3 = ToColor3(theme.BackgroundSecondary)
    sidebar.BorderSizePixel = 0
    sidebar.Parent = main

    local tabList = Instance.new("ScrollingFrame")
    tabList.Name = "TabList"
    tabList.Size = UDim2.new(1, -16, 1, -20)
    tabList.Position = UDim2.new(0, 8, 0, 10)
    tabList.BackgroundTransparency = 1
    tabList.ScrollBarThickness = 2
    tabList.Parent = sidebar

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Padding = UDim.new(0, 6)
    tabLayout.Parent = tabList
    hub.TabList = tabList

    -- 5. Content Area (Páginas das Abas)
    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Size = UDim2.new(1, -200, 1, -58)
    contentContainer.Position = UDim2.new(0, 195, 0, 52)
    contentContainer.BackgroundTransparency = 1
    contentContainer.Parent = main
    hub.ContentContainer = contentContainer

    -- Inicializa Abas Nativas (Favoritos & Configurações)
    hub:_InitNativeTabs()

    -- Listener de Atalho Global (Toggle Key)
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode.Name == hub.toggleKey then
            hub:Toggle()
        end
    end)

    return hub
end

-- ----------------------------------------------------------------------------
-- 6. HUB METHODS (Tabs, Sub-Tabs & Sections)
-- ----------------------------------------------------------------------------
function NexusUI:Toggle()
    self.isOpen = not self.isOpen
    local targetAlpha = self.isOpen and 0 or 1
    local targetPos = self.isOpen and self.MainFrame.Position or self.MainFrame.Position + UDim2.new(0, 0, 0, 20)

    CreateTween(self.MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = self.isOpen and ToTransparency(self.theme.BackgroundPrimary) or 1
    })
    self.MainFrame.Visible = self.isOpen
end

function NexusUI:Update(dt)
    -- Método de compatibilidade para ticks de execução
end

function NexusUI:CreateTab(name, iconAsset)
    local hub = self

    -- Botão da Aba na Sidebar
    local tabBtn = Instance.new("TextButton")
    tabBtn.Name = "TabBtn_" .. name
    tabBtn.Size = UDim2.new(1, 0, 0, 38)
    tabBtn.BackgroundColor3 = Color3.fromRGB(28, 32, 44)
    tabBtn.BackgroundTransparency = 1
    tabBtn.Text = "     " .. name
    tabBtn.TextColor3 = ToColor3(hub.theme.TextDim)
    tabBtn.Font = Enum.Font.GothamSemibold
    tabBtn.TextSize = 13
    tabBtn.TextXAlignment = Enum.TextXAlignment.Left
    tabBtn.Parent = hub.TabList

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = tabBtn

    -- Página de Conteúdo da Aba
    local tabPage = Instance.new("Frame")
    tabPage.Name = "Page_" .. name
    tabPage.Size = UDim2.new(1, 0, 1, 0)
    tabPage.BackgroundTransparency = 1
    tabPage.Visible = false
    tabPage.Parent = hub.ContentContainer

    -- Barra de Sub-Abas (Navegação Superior interna)
    local subTabHeader = Instance.new("Frame")
    subTabHeader.Name = "SubTabHeader"
    subTabHeader.Size = UDim2.new(1, 0, 0, 32)
    subTabHeader.BackgroundTransparency = 1
    subTabHeader.Parent = tabPage

    local subTabLayout = Instance.new("UIListLayout")
    subTabLayout.FillDirection = Enum.FillDirection.Horizontal
    subTabLayout.Padding = UDim.new(0, 8)
    subTabLayout.Parent = subTabHeader

    -- Container para conteúdo das Sub-Abas
    local subTabContainer = Instance.new("Frame")
    subTabContainer.Name = "SubTabContainer"
    subTabContainer.Size = UDim2.new(1, 0, 1, -40)
    subTabContainer.Position = UDim2.new(0, 0, 0, 40)
    subTabContainer.BackgroundTransparency = 1
    subTabContainer.Parent = tabPage

    local tabObj = {
        name = name,
        button = tabBtn,
        page = tabPage,
        subTabHeader = subTabHeader,
        subTabContainer = subTabContainer,
        subTabs = {},
        activeSubTab = nil
    }

    tabBtn.MouseButton1Click:Connect(function()
        for _, t in pairs(hub.tabs) do
            t.page.Visible = false
            CreateTween(t.button, TweenInfo.new(0.2), { BackgroundTransparency = 1, TextColor3 = ToColor3(hub.theme.TextDim) })
        end
        tabPage.Visible = true
        CreateTween(tabBtn, TweenInfo.new(0.2), { BackgroundTransparency = 0, BackgroundColor3 = ToColor3(hub.theme.Accent), TextColor3 = Color3.fromRGB(255, 255, 255) })
        hub.activeTab = tabObj
    end)

    table.insert(hub.tabs, tabObj)

    -- Define a primeira aba como ativa automaticamente
    if #hub.tabs == 1 then
        tabPage.Visible = true
        tabBtn.BackgroundTransparency = 0
        tabBtn.BackgroundColor3 = ToColor3(hub.theme.Accent)
        tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        hub.activeTab = tabObj
    end

    -- Criação de Sub-Abas
    function tabObj:CreateSubTab(subName)
        local subBtn = Instance.new("TextButton")
        subBtn.Name = "SubBtn_" .. subName
        subBtn.Size = UDim2.new(0, 110, 1, 0)
        subBtn.BackgroundColor3 = Color3.fromRGB(25, 30, 42)
        subBtn.Text = subName
        subBtn.TextColor3 = ToColor3(hub.theme.TextDim)
        subBtn.Font = Enum.Font.GothamSemibold
        subBtn.TextSize = 12
        subBtn.Parent = subTabHeader

        local sCorner = Instance.new("UICorner")
        sCorner.CornerRadius = UDim.new(0, 6)
        sCorner.Parent = subBtn

        local subPage = Instance.new("ScrollingFrame")
        subPage.Name = "SubPage_" .. subName
        subPage.Size = UDim2.new(1, 0, 1, 0)
        subPage.BackgroundTransparency = 1
        subPage.ScrollBarThickness = 3
        subPage.Visible = false
        subPage.Parent = subTabContainer

        local subLayout = Instance.new("UIListLayout")
        subLayout.Padding = UDim.new(0, 12)
        subLayout.Parent = subPage

        local subObj = { name = subName, page = subPage, button = subBtn }

        subBtn.MouseButton1Click:Connect(function()
            for _, s in pairs(tabObj.subTabs) do
                s.page.Visible = false
                s.button.TextColor3 = ToColor3(hub.theme.TextDim)
            end
            subPage.Visible = true
            subBtn.TextColor3 = ToColor3(hub.theme.Accent)
            tabObj.activeSubTab = subObj
        end)

        table.insert(tabObj.subTabs, subObj)

        if #tabObj.subTabs == 1 then
            subPage.Visible = true
            subBtn.TextColor3 = ToColor3(hub.theme.Accent)
            tabObj.activeSubTab = subObj
        end

        function subObj:CreateSection(secTitle, bannerAsset)
            return hub:_BuildSection(subPage, secTitle, bannerAsset)
        end

        return subObj
    end

    function tabObj:CreateSection(secTitle, bannerAsset)
        if #self.subTabs == 0 then
            self:CreateSubTab("Geral")
        end
        return self.subTabs[1]:CreateSection(secTitle, bannerAsset)
    end

    return tabObj
end

-- Construtor de Seções & Componentes Interativos
function NexusUI:_BuildSection(parentFrame, title, bannerAsset)
    local hub = self
    local sectionFrame = Instance.new("Frame")
    sectionFrame.Name = "Section_" .. title
    sectionFrame.Size = UDim2.new(1, -8, 0, 36)
    sectionFrame.AutomaticSize = Enum.AutomaticSize.Y
    sectionFrame.BackgroundColor3 = Color3.fromRGB(22, 26, 36)
    sectionFrame.BorderSizePixel = 0
    sectionFrame.Parent = parentFrame

    local secCorner = Instance.new("UICorner")
    secCorner.CornerRadius = UDim.new(0, 8)
    secCorner.Parent = sectionFrame

    local secStroke = Instance.new("UIStroke")
    secStroke.Color = Color3.fromRGB(35, 40, 55)
    secStroke.Thickness = 1
    secStroke.Parent = sectionFrame

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -20, 0, 32)
    titleLbl.Position = UDim2.new(0, 14, 0, 4)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = string.upper(title)
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 12
    titleLbl.TextColor3 = ToColor3(hub.theme.Accent)
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = sectionFrame

    local widgetList = Instance.new("Frame")
    widgetList.Name = "Widgets"
    widgetList.Size = UDim2.new(1, -20, 0, 0)
    widgetList.Position = UDim2.new(0, 10, 0, 40)
    widgetList.AutomaticSize = Enum.AutomaticSize.Y
    widgetList.BackgroundTransparency = 1
    widgetList.Parent = sectionFrame

    local wLayout = Instance.new("UIListLayout")
    wLayout.Padding = UDim.new(0, 8)
    wLayout.Parent = widgetList

    local padding = Instance.new("UIPadding")
    padding.PaddingBottom = UDim.new(0, 12)
    padding.Parent = sectionFrame

    local sectionApi = {}

    -- [BUTTON]
    function sectionApi:AddButton(btnCfg)
        local btnFrame = Instance.new("TextButton")
        btnFrame.Size = UDim2.new(1, 0, 0, 36)
        btnFrame.BackgroundColor3 = Color3.fromRGB(28, 33, 46)
        btnFrame.Text = (btnCfg.canFavorite and "      " or "   ") .. btnCfg.name
        btnFrame.TextColor3 = ToColor3(hub.theme.Text)
        btnFrame.Font = Enum.Font.GothamSemibold
        btnFrame.TextSize = 12
        btnFrame.TextXAlignment = Enum.TextXAlignment.Left
        btnFrame.Parent = widgetList

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = btnFrame

        local comp = Component.New(btnFrame, btnCfg, hub)
        btnFrame.MouseButton1Click:Connect(function()
            if comp.IsLocked then return end
            CreateTween(btnFrame, TweenInfo.new(0.1), { BackgroundColor3 = ToColor3(hub.theme.Accent) })
            task.wait(0.1)
            CreateTween(btnFrame, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(28, 33, 46) })
            if btnCfg.callback then btnCfg.callback(comp) end
        end)
        return comp
    end

    -- [TOGGLE]
    function sectionApi:AddToggle(toggleCfg)
        local tFrame = Instance.new("TextButton")
        tFrame.Size = UDim2.new(1, 0, 0, 36)
        tFrame.BackgroundColor3 = Color3.fromRGB(28, 33, 46)
        tFrame.Text = (toggleCfg.canFavorite and "      " or "   ") .. toggleCfg.name
        tFrame.TextColor3 = ToColor3(hub.theme.Text)
        tFrame.Font = Enum.Font.GothamSemibold
        tFrame.TextSize = 12
        tFrame.TextXAlignment = Enum.TextXAlignment.Left
        tFrame.Parent = widgetList

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = tFrame

        -- Switch visual
        local switch = Instance.new("Frame")
        switch.Size = UDim2.new(0, 38, 0, 20)
        switch.Position = UDim2.new(1, -48, 0.5, -10)
        switch.BackgroundColor3 = toggleCfg.default and ToColor3(hub.theme.Accent) or Color3.fromRGB(40, 45, 60)
        switch.Parent = tFrame

        local swCorner = Instance.new("UICorner")
        swCorner.CornerRadius = UDim.new(1, 0)
        swCorner.Parent = switch

        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 14, 0, 14)
        dot.Position = toggleCfg.default and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        dot.Parent = switch

        local dotCorner = Instance.new("UICorner")
        dotCorner.CornerRadius = UDim.new(1, 0)
        dotCorner.Parent = dot

        local comp = Component.New(tFrame, toggleCfg, hub)
        local state = toggleCfg.default or false

        tFrame.MouseButton1Click:Connect(function()
            if comp.IsLocked then return end
            state = not state
            CreateTween(switch, TweenInfo.new(0.2), { BackgroundColor3 = state and ToColor3(hub.theme.Accent) or Color3.fromRGB(40, 45, 60) })
            CreateTween(dot, TweenInfo.new(0.2), { Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7) })
            if toggleCfg.callback then toggleCfg.callback(state) end
        end)
        return comp
    end

    -- [DROPDOWN]
    function sectionApi:AddDropdown(ddCfg)
        local dFrame = Instance.new("Frame")
        dFrame.Size = UDim2.new(1, 0, 0, 36)
        dFrame.AutomaticSize = Enum.AutomaticSize.Y
        dFrame.BackgroundColor3 = Color3.fromRGB(28, 33, 46)
        dFrame.Parent = widgetList

        local dCorner = Instance.new("UICorner")
        dCorner.CornerRadius = UDim.new(0, 6)
        dCorner.Parent = dFrame

        local headerBtn = Instance.new("TextButton")
        headerBtn.Size = UDim2.new(1, 0, 0, 36)
        headerBtn.BackgroundTransparency = 1
        headerBtn.Text = "   " .. ddCfg.name .. "  ▼"
        headerBtn.TextColor3 = ToColor3(hub.theme.Text)
        headerBtn.Font = Enum.Font.GothamSemibold
        headerBtn.TextSize = 12
        headerBtn.TextXAlignment = Enum.TextXAlignment.Left
        headerBtn.Parent = dFrame

        local optList = Instance.new("Frame")
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
            headerBtn.Text = "   " .. ddCfg.name .. (isOpen and "  ▲" or "  ▼")
        end)

        for _, opt in ipairs(ddCfg.options or {}) do
            local optBtn = Instance.new("TextButton")
            optBtn.Size = UDim2.new(1, -16, 0, 28)
            optBtn.Position = UDim2.new(0, 8, 0, 0)
            optBtn.BackgroundColor3 = Color3.fromRGB(35, 42, 58)
            optBtn.Text = "   " .. opt
            optBtn.TextColor3 = ToColor3(hub.theme.TextDim)
            optBtn.Font = Enum.Font.Gotham
            optBtn.TextSize = 11
            optBtn.TextXAlignment = Enum.TextXAlignment.Left
            optBtn.Parent = optList

            local oCorner = Instance.new("UICorner")
            oCorner.CornerRadius = UDim.new(0, 4)
            oCorner.Parent = optBtn

            optBtn.MouseButton1Click:Connect(function()
                if ddCfg.multiSelect then
                    selected[opt] = not selected[opt]
                    optBtn.TextColor3 = selected[opt] and ToColor3(hub.theme.Accent) or ToColor3(hub.theme.TextDim)
                    if ddCfg.callback then ddCfg.callback(selected) end
                else
                    selected = opt
                    isOpen = false
                    optList.Visible = false
                    headerBtn.Text = "   " .. ddCfg.name .. "  [" .. opt .. "]  ▼"
                    if ddCfg.callback then ddCfg.callback(selected) end
                end
            end)
        end
        return comp
    end

    -- [KEYBIND]
    function sectionApi:AddKeybind(kbCfg)
        local kFrame = Instance.new("TextButton")
        kFrame.Size = UDim2.new(1, 0, 0, 36)
        kFrame.BackgroundColor3 = Color3.fromRGB(28, 33, 46)
        kFrame.Text = "   " .. kbCfg.name
        kFrame.TextColor3 = ToColor3(hub.theme.Text)
        kFrame.Font = Enum.Font.GothamSemibold
        kFrame.TextSize = 12
        kFrame.TextXAlignment = Enum.TextXAlignment.Left
        kFrame.Parent = widgetList

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = kFrame

        local keyBox = Instance.new("TextLabel")
        keyBox.Size = UDim2.new(0, 60, 0, 22)
        keyBox.Position = UDim2.new(1, -70, 0.5, -11)
        keyBox.BackgroundColor3 = Color3.fromRGB(40, 45, 62)
        keyBox.Text = kbCfg.default or "None"
        keyBox.TextColor3 = ToColor3(hub.theme.Accent)
        keyBox.Font = Enum.Font.GothamBold
        keyBox.TextSize = 11
        keyBox.Parent = kFrame

        local kCorner = Instance.new("UICorner")
        kCorner.CornerRadius = UDim.new(0, 4)
        kCorner.Parent = keyBox

        local comp = Component.New(kFrame, kbCfg, hub)
        local listening = false

        kFrame.MouseButton1Click:Connect(function()
            if comp.IsLocked then return end
            listening = true
            keyBox.Text = "..."
            local conn
            conn = UserInputService.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.Keyboard then
                    conn:Disconnect()
                    listening = false
                    keyBox.Text = inp.KeyCode.Name
                    if kbCfg.callback then kbCfg.callback(inp.KeyCode.Name) end
                end
            end)
        end)
        return comp
    end

    return sectionApi
end

-- Gerenciador de Favoritos & Configurações Nativas
function NexusUI:RegisterFavorite(comp, status)
    if status then
        self.favorites[comp] = true
    else
        self.favorites[comp] = nil
    end
end

function NexusUI:_InitNativeTabs()
    local favTab = self:CreateTab("Favoritos")
    local favSec = favTab:CreateSection("Acesso Rápido")

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

-- ============================================================================
-- FINAL RETORNO DO MÓDULO (Para suporte a loadstring)
-- ============================================================================
return NexusUI
