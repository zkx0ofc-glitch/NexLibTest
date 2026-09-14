-- ============================================================================
-- NEXUS UI LIBRARY - Core Architecture
-- Paradigm: Object-Oriented Programming (Metatables) & Event-Driven
-- ============================================================================

local NexusUI = {}
NexusUI.__index = NexusUI

-- ----------------------------------------------------------------------------
-- 1. UTILITIES & FOUNDATION (OOP, Signals, Color & Math)
-- ----------------------------------------------------------------------------
local function CreateClass(base)
    local c = {}
    c.__index = c
    if base then
        setmetatable(c, { __index = base })
    end
    function c:New(...)
        local obj = setmetatable({}, c)
        if obj.Init then
            obj:Init(...)
        end
        return obj
    end
    return c
end

-- Sistema de Eventos / Signals (Observer Pattern)
local Signal = CreateClass()
function Signal:Init()
    self.listeners = {}
end

function Signal:Connect(fn)
    table.insert(self.listeners, fn)
    return {
        Disconnect = function()
            for i, l in ipairs(self.listeners) do
                if l == fn then
                    table.remove(self.listeners, i)
                    break
                end
            end
        end
    }
end

function Signal:Fire(...)
    for _, fn in ipairs(self.listeners) do
        fn(...)
    end
end

-- Utilitário de Cores e Interpolação Linear (Tweening/Easing)
local Color = {}
function Color.RGBA(r, g, b, a)
    return { r = r or 255, g = g or 255, b = b or 255, a = a or 1.0 }
end

local function Lerp(a, b, t)
    return a + (b - a) * t
end

-- ----------------------------------------------------------------------------
-- 2. THEME & VISUAL DEFINITIONS
-- ----------------------------------------------------------------------------
NexusUI.DefaultTheme = {
    BackgroundPrimary   = Color.RGBA(18, 18, 22, 0.95),
    BackgroundSecondary = Color.RGBA(25, 25, 32, 0.90),
    Accent              = Color.RGBA(98, 71, 235, 1.0),
    AccentHover         = Color.RGBA(115, 88, 255, 1.0),
    Text                = Color.RGBA(240, 240, 245, 1.0),
    TextDim             = Color.RGBA(140, 140, 155, 1.0),
    Success             = Color.RGBA(46, 204, 113, 1.0),
    Warning             = Color.RGBA(241, 196, 15, 1.0),
    Danger              = Color.RGBA(231, 76, 60, 1.0),
    LockedOverlay       = Color.RGBA(10, 10, 12, 0.75),
    BlurEnabled         = true,
    BackgroundGradient  = {
        Enabled = true,
        StartColor = Color.RGBA(30, 20, 50, 0.95),
        EndColor   = Color.RGBA(15, 15, 20, 0.95)
    }
}

-- ----------------------------------------------------------------------------
-- 3. BASE COMPONENT (Herança para todos os Widgets)
-- ----------------------------------------------------------------------------
local BaseComponent = CreateClass()

function BaseComponent:Init(config)
    config = config or {}
    self.id = config.id or tostring(math.random(100000, 999999))
    self.name = config.name or "Component"
    self.bounds = config.bounds or { x = 0, y = 0, width = 100, height = 30 }
    self.visible = config.visible ~= nil and config.visible or true
    self.parent = nil
    self.children = {}
    
    -- Estados Interativos
    self.isHovered = false
    self.isPressed = false
    self.canFavorite = config.canFavorite or false
    self.isFavorite = false
    
    -- Sistema de Tags Dinâmicas (Textos reativos, Badges, Status)
    self.dynamicTags = {} -- Ex: { tagId = { text = "ONLINE", color = Color.RGBA(...) } }
    
    -- Sistema de Bloqueio Condicional (Lock/Permissions)
    self.locked = config.locked or false
    self.lockReason = config.lockReason or "Sem Permissão"
    
    -- Eventos Natuais
    self.OnStateChanged = Signal:New()
end

function BaseComponent:AddChild(child)
    child.parent = self
    table.insert(self.children, child)
end

function BaseComponent:SetLocked(locked, reason)
    self.locked = locked
    if reason then self.lockReason = reason end
    self.OnStateChanged:Fire("lock", self.locked, self.lockReason)
end

function BaseComponent:SetFavorite(status)
    if not self.canFavorite then return end
    self.isFavorite = status
    self.OnStateChanged:Fire("favorite", self.isFavorite)
    
    -- Notifica o Hub raiz para atualizar a lista de favoritos
    local root = self:GetRootHub()
    if root and root.OnFavoriteToggled then
        root:OnFavoriteToggled(self, self.isFavorite)
    end
end

function BaseComponent:UpdateTag(tagId, text, color)
    self.dynamicTags[tagId] = {
        text = text,
        color = color or NexusUI.DefaultTheme.Accent
    }
    self.OnStateChanged:Fire("tag_updated", tagId, text)
end

function BaseComponent:RemoveTag(tagId)
    self.dynamicTags[tagId] = nil
    self.OnStateChanged:Fire("tag_removed", tagId)
end

function BaseComponent:GetRootHub()
    local curr = self
    while curr.parent do
        curr = curr.parent
    end
    return curr
end

-- ----------------------------------------------------------------------------
-- 4. WIDGETS INTERATIVOS
-- ----------------------------------------------------------------------------

-- [BUTTON WIDGET]
local Button = CreateClass(BaseComponent)
function Button:Init(config)
    BaseComponent.Init(self, config)
    self.callback = config.callback or function() end
    self.iconAsset = config.iconAsset or nil
end

function Button:Click()
    if self.locked then return end
    self.callback(self)
    self.OnStateChanged:Fire("clicked")
end

-- [TOGGLE WIDGET]
local Toggle = CreateClass(BaseComponent)
function Toggle:Init(config)
    BaseComponent.Init(self, config)
    self.state = config.default or false
    self.callback = config.callback or function(state) end
    self.animPosition = self.state and 1.0 or 0.0 -- Usado para transição suave
end

function Toggle:SetState(newState)
    if self.locked then return end
    self.state = newState
    self.callback(self.state)
    self.OnStateChanged:Fire("toggled", self.state)
end

function Toggle:Toggle()
    self:SetState(not self.state)
end

-- [SELECTOR / DROPDOWN WIDGET]
local Dropdown = CreateClass(BaseComponent)
function Dropdown:Init(config)
    BaseComponent.Init(self, config)
    self.options = config.options or {}
    self.multiSelect = config.multiSelect or false
    self.selected = self.multiSelect and {} or config.default or self.options[1]
    self.isOpen = false
    self.callback = config.callback or function(selected) end
end

function Dropdown:Select(option)
    if self.locked then return end
    
    if self.multiSelect then
        self.selected[option] = not self.selected[option]
        self.callback(self.selected)
    else
        self.selected = option
        self.isOpen = false
        self.callback(self.selected)
    end
    self.OnStateChanged:Fire("selected", self.selected)
end

function Dropdown:ToggleDropdown()
    if self.locked then return end
    self.isOpen = not self.isOpen
end

-- [KEYBIND WIDGET]
local Keybind = CreateClass(BaseComponent)
function Keybind:Init(config)
    BaseComponent.Init(self, config)
    self.currentKey = config.default or "None"
    self.isListening = false
    self.callback = config.callback or function(newKey) end
end

function Keybind:StartListening()
    if self.locked then return end
    self.isListening = true
    self.OnStateChanged:Fire("listening", true)
end

function Keybind:AssignKey(key)
    self.currentKey = key
    self.isListening = false
    self.callback(self.currentKey)
    self.OnStateChanged:Fire("key_assigned", self.currentKey)
end

-- [GAME ASSET / IMAGE COMPONENT]
local AssetImage = CreateClass(BaseComponent)
function AssetImage:Init(config)
    BaseComponent.Init(self, config)
    self.assetPath = config.assetPath or ""
    self.aspectRatio = config.aspectRatio or "fit"
    self.roundedCorners = config.roundedCorners or 6
end

-- ----------------------------------------------------------------------------
-- 5. CONTAINER STRUCTURE (Sections, Tabs, Sub-Tabs)
-- ----------------------------------------------------------------------------
local Section = CreateClass(BaseComponent)
function Section:Init(config)
    BaseComponent.Init(self, config)
    self.bannerAsset = config.bannerAsset or nil -- Imagem de capa/Game Asset
end

function Section:AddButton(config)
    local btn = Button:New(config)
    self:AddChild(btn)
    return btn
end

function Section:AddToggle(config)
    local toggle = Toggle:New(config)
    self:AddChild(toggle)
    return toggle
end

function Section:AddDropdown(config)
    local dropdown = Dropdown:New(config)
    self:AddChild(dropdown)
    return dropdown
end

function Section:AddKeybind(config)
    local keybind = Keybind:New(config)
    self:AddChild(keybind)
    return keybind
end

function Section:AddImage(config)
    local img = AssetImage:New(config)
    self:AddChild(img)
    return img
end

-- [SUB-TAB]
local SubTab = CreateClass(BaseComponent)
function SubTab:Init(config)
    BaseComponent.Init(self, config)
    self.sections = {}
end

function SubTab:CreateSection(title, bannerAsset)
    local sec = Section:New({ name = title, bannerAsset = bannerAsset })
    self:AddChild(sec)
    table.insert(self.sections, sec)
    return sec
end

-- [TAB]
local Tab = CreateClass(BaseComponent)
function Tab:Init(config)
    BaseComponent.Init(self, config)
    self.iconAsset = config.iconAsset or nil
    self.subTabs = {}
    self.activeSubTab = nil
end

function Tab:CreateSubTab(name)
    local sub = SubTab:New({ name = name })
    self:AddChild(sub)
    table.insert(self.subTabs, sub)
    if not self.activeSubTab then
        self.activeSubTab = sub
    end
    return sub
end

-- Caso queira criar uma seção direta sem sub-abas
function Tab:CreateSection(title, bannerAsset)
    if #self.subTabs == 0 then
        self:CreateSubTab("Geral")
    end
    return self.subTabs[1]:CreateSection(title, bannerAsset)
end

-- ----------------------------------------------------------------------------
-- 6. HUB CORE (Menu Principal & Sistemas Globais)
-- ----------------------------------------------------------------------------
local Hub = CreateClass(BaseComponent)

function Hub:Init(config)
    BaseComponent.Init(self, config)
    self.title = config.title or "Dashboard Hub"
    self.theme = config.theme or NexusUI.DefaultTheme
    self.toggleKey = config.toggleKey or "Y"
    self.isOpen = true
    self.transitionAlpha = 1.0 -- Controle de animação de entrada/saída (0 a 1)
    
    self.tabs = {}
    self.activeTab = nil
    self.favoriteItems = {} -- Registro de elementos favoritados
    
    -- Inicializa Abas de Sistema Nativas
    self:_InitNativeTabs()
end

function Hub:CreateTab(name, iconAsset)
    local tab = Tab:New({ name = name, iconAsset = iconAsset })
    self:AddChild(tab)
    table.insert(self.tabs, tab)
    if not self.activeTab then
        self.activeTab = tab
    end
    return tab
end

function Hub:SetActiveTab(tab)
    self.activeTab = tab
    self.OnStateChanged:Fire("tab_switched", tab.name)
end

function Hub:Toggle()
    self.isOpen = not self.isOpen
    self.OnStateChanged:Fire("visibility_toggled", self.isOpen)
end

-- Gerenciador do Sistema de Favoritos
function Hub:OnFavoriteToggled(component, isFav)
    if isFav then
        self.favoriteItems[component.id] = component
    else
        self.favoriteItems[component.id] = nil
    end
    self:_RefreshFavoritesView()
end

function Hub:_RefreshFavoritesView()
    if not self.favoritesSubTab then return end
    self.favoritesSubTab.sections = {}
    self.favoritesSubTab.children = {}
    
    local quickSec = self.favoritesSubTab:CreateSection("Acesso Rápido")
    for _, comp in pairs(self.favoriteItems) do
        quickSec:AddChild(comp)
    end
end

-- Abas do Sistema: Favoritos e Configurações (Settings)
function Hub:_InitNativeTabs()
    -- 1. Aba de Favoritos
    self.favoritesTab = Tab:New({ name = "Favoritos", iconAsset = "assets/icons/star.png" })
    self.favoritesSubTab = self.favoritesTab:CreateSubTab("Salvos")
    self:AddChild(self.favoritesTab)
    table.insert(self.tabs, self.favoritesTab)
    
    -- 2. Aba de Configurações do Sistema
    self.settingsTab = Tab:New({ name = "Configurações", iconAsset = "assets/icons/gear.png" })
    local uiSettings = self.settingsTab:CreateSubTab("Interface")
    local generalSec = uiSettings:CreateSection("Comportamento do Hub")
    
    -- Atalho de Abertura Global
    generalSec:AddKeybind({
        name = "Tecla de Atalho do Menu",
        default = self.toggleKey,
        callback = function(newKey)
            self.toggleKey = newKey
        end
    })
    
    -- Efeito de Blur
    generalSec:AddToggle({
        name = "Ativar Background Blur",
        default = self.theme.BlurEnabled,
        callback = function(state)
            self.theme.BlurEnabled = state
        end
    })
    
    -- Efeito de Gradiente
    generalSec:AddToggle({
        name = "Ativar Gradiente no Fundo",
        default = self.theme.BackgroundGradient.Enabled,
        callback = function(state)
            self.theme.BackgroundGradient.Enabled = state
        end
    })
    
    self:AddChild(self.settingsTab)
    table.insert(self.tabs, self.settingsTab)
end

-- Atualização de Estados e Transições por Frame (Tick)
function Hub:Update(dt)
    -- Transição suave (Fade) ao abrir e fechar
    local targetAlpha = self.isOpen and 1.0 or 0.0
    self.transitionAlpha = Lerp(self.transitionAlpha, targetAlpha, dt * 10)
end

-- Trata Teclado Global
function Hub:HandleKeyPress(key)
    if key == self.toggleKey then
        self:Toggle()
        return true
    end
    return false
end

-- ----------------------------------------------------------------------------
-- 7. ABSTRACT RENDERER INTERFACE (Driver desacoplado de motor)
-- ----------------------------------------------------------------------------
local Renderer = CreateClass()
function Renderer:RenderHub(hub)
    if hub.transitionAlpha <= 0.01 then return end -- Invisível

    -- 1. Renderizar Fundo (Gradiente, Blur e Painel Principal)
    local theme = hub.theme
    local currentAlpha = hub.transitionAlpha
    
    -- [Exemplo de chamada ao motor de renderização]
    -- Render:DrawBlur(hub.bounds, theme.BlurEnabled and currentAlpha or 0)
    -- Render:DrawGradient(hub.bounds, theme.BackgroundGradient.StartColor, theme.BackgroundGradient.EndColor, currentAlpha)
    
    -- 2. Renderizar Abas e Sub-Abas Ativas
    -- 3. Renderizar Itens Interativos, Tags Dinâmicas e Bloqueios
end

NexusUI.CreateHub = function(config)
    return Hub:New(config)
end

return NexusUI