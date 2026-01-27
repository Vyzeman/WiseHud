local ADDON_NAME = ...

-- Options panel for WiseHud (HUD layout + Combo Points)
-- Main file that imports and uses the tab classes

-- Import tab classes (loaded via TOC)
local OrbResourceTab = WiseHudOptionsOrbResourceTab
local HealthPowerTab = WiseHudOptionsHealthPowerTab
local CastBarTab = WiseHudOptionsCastBarTab

-- ===== Main Options Panel =====
local function CreateOptionsPanel()
  if type(Settings) ~= "table" or WiseHudOptionsCategory then
    return
  end

  local panel = CreateFrame("Frame")
  panel.name = "WiseHud"

  -- Forward declarations for tab instances so callbacks see them
  local orbTabInstance, healthPowerTabInstance, castTabInstance

  -- Create header with logo/icon - positioned top right
  local logoFrame = CreateFrame("Frame", nil, panel)
  logoFrame:SetSize(80, 80)
  logoFrame:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -16, -16)
  
  -- Logo background (subtle border/background) - optional, can be removed if not needed
  -- local logoBg = logoFrame:CreateTexture(nil, "BACKGROUND")
  -- logoBg:SetAllPoints(logoFrame)
  -- logoBg:SetColorTexture(0.1, 0.1, 0.1, 0.5)
  -- logoBg:SetBlendMode("BLEND")
  
  -- Logo/Icon texture - try to load from textures folder first, fallback to WoW icon
  local logoTexture = logoFrame:CreateTexture(nil, "ARTWORK")
  logoTexture:SetPoint("CENTER", logoFrame, "CENTER", 0, 0)
  logoTexture:SetSize(72, 72)
  
  -- Try to load logo from textures folder (as BLP)
  local logoPaths = {
    "Interface\\AddOns\\WiseHud\\WiseHud_Logo.blp",  -- Root directory
    "Interface\\AddOns\\WiseHud\\textures\\WiseHud_Logo.blp",  -- Textures folder
  }
  
  local logoLoaded = false
  for _, path in ipairs(logoPaths) do
    local success = pcall(function()
      logoTexture:SetTexture(path)
    end)
    if success then
      -- Check if texture was actually loaded by trying to get it
      local currentTexture = logoTexture:GetTexture()
      if currentTexture then
        logoLoaded = true
        -- Ensure proper filtering for crisp display
        logoTexture:SetTexCoord(0, 1, 0, 1)
        break
      end
    end
  end
  
  -- Fallback: Use a nice icon from WoW if logo not found
  if not logoLoaded then
    -- Use a simple, clean icon as placeholder
    logoTexture:SetTexture("Interface\\Icons\\INV_Misc_EngGizmos_19")
    logoTexture:SetVertexColor(0.4, 0.7, 1.0, 1.0) -- Light blue tint
  end
  

  -- Create tab container - positioned below tab buttons
  -- Tab buttons are at Y=-16 with height 32, so container starts at -16-32-2 = -50
  local tabContainer = CreateFrame("Frame", nil, panel)
  tabContainer:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -50)  -- Below tab buttons (32px height + 2px margin)
  tabContainer:SetPoint("BOTTOMRIGHT", -16, 16)

  -- Helper function to create a scrollable tab
  local function CreateScrollableTab(name, parent)
    local scrollFrame = CreateFrame("ScrollFrame", name .. "ScrollFrame", parent)
    scrollFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -20, 0) -- Leave space for scrollbar
    -- Clipping region to prevent content from going into logo area
    scrollFrame:SetClipsChildren(true)
    
    -- Create scroll child (this is where all content goes)
    local scrollChild = CreateFrame("Frame", name .. "ScrollChild", scrollFrame)
    -- Width will be set when parent is sized
    scrollChild:SetHeight(1) -- Will be updated based on content
    
    -- Set width when parent is shown/sized
    scrollChild:SetScript("OnShow", function(self)
      self:SetWidth(scrollFrame:GetWidth())
    end)
    
    scrollFrame:SetScrollChild(scrollChild)
    
    -- Create scroll bar - positioned to avoid logo area (logo is 80px high at top, plus margin)
    local scrollBar = CreateFrame("Slider", name .. "ScrollBar", scrollFrame, "UIPanelScrollBarTemplate")
    scrollBar:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", 0, -90)  -- Start below logo area (80px logo + 10px margin)
    scrollBar:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", 0, 16)
    scrollBar:SetMinMaxValues(0, 0)
    scrollBar:SetValue(0)
    scrollBar:SetValueStep(20)
    scrollBar:SetObeyStepOnDrag(true)
    
    -- Link scroll bar to scroll frame
    scrollFrame.scrollBar = scrollBar
    scrollBar:SetScript("OnValueChanged", function(self, value)
      scrollFrame:SetVerticalScroll(value)
    end)
    
    -- Enable mouse wheel scrolling on both scrollFrame and scrollChild
    scrollFrame:EnableMouseWheel(true)
    scrollChild:EnableMouseWheel(true)
    
    local function HandleMouseWheel(self, delta)
      local currentScroll = scrollFrame:GetVerticalScroll()
      local minScroll, maxScroll = scrollFrame.scrollBar:GetMinMaxValues()
      local scrollStep = 30
      
      if maxScroll > 0 then
        local newScroll = currentScroll - (delta * scrollStep)
        newScroll = math.max(minScroll, math.min(maxScroll, newScroll))
        
        scrollFrame:SetVerticalScroll(newScroll)
        scrollFrame.scrollBar:SetValue(newScroll)
      end
    end
    
    scrollFrame:SetScript("OnMouseWheel", HandleMouseWheel)
    scrollChild:SetScript("OnMouseWheel", HandleMouseWheel)
    
    -- Store reference to UpdateScrollRange function (will be set later)
    scrollFrame.updateScrollRange = nil
    
    -- Update scroll child width when frame is shown
    scrollFrame:SetScript("OnShow", function(self)
      scrollChild:SetWidth(self:GetWidth())
      -- Update scroll range when shown
      if self.updateScrollRange then
        C_Timer.After(0.05, function()
          self.updateScrollRange()
        end)
      end
    end)
    
    scrollFrame.scrollChild = scrollChild
    scrollFrame:Hide()
    
    return scrollFrame, scrollChild
  end

  -- Create three scrollable tab panels
  local orbTab, orbTabChild = CreateScrollableTab("WiseHudOrbTab", tabContainer)
  local healthPowerTab, healthPowerTabChild = CreateScrollableTab("WiseHudHealthPowerTab", tabContainer)
  local castTab, castTabChild = CreateScrollableTab("WiseHudCastTab", tabContainer)

  -- Create tab buttons
  local function CreateTabButton(parent, id, text, x, y)
    local tab = CreateFrame("Button", nil, parent)
    if id == 1 then
      tab:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    else
      tab:SetPoint("LEFT", _G["WiseHudTab" .. (id - 1)], "RIGHT", -5, 0)
    end
    tab:SetID(id)
    tab:SetSize(100, 32)
    
    local bg = tab:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(tab)
    bg:SetTexture("Interface\\OptionsFrame\\UI-OptionsFrame-ActiveTab")
    tab.bg = bg
    
    local textObj = tab:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    textObj:SetPoint("CENTER", tab, "CENTER", 0, -3)
    tab.Text = textObj
    textObj:SetText(text)
    
    local textWidth = textObj:GetStringWidth()
    tab:SetWidth(textWidth + 20)
    
    _G["WiseHudTab" .. id] = tab
    return tab, textObj
  end

  local tab1, tab1Text = CreateTabButton(panel, 1, "Orb Resource", 16, -16)
  local tab2, tab2Text = CreateTabButton(panel, 2, "Health/Power", 0, 0)
  local tab3, tab3Text = CreateTabButton(panel, 3, "Cast Bar", 0, 0)

  -- Tab state variables
  local selectedTab = 1
  
  -- Function to update tab appearance
  local function UpdateTabAppearance()
    if selectedTab == 1 then
      tab1.bg:SetTexture("Interface\\OptionsFrame\\UI-OptionsFrame-ActiveTab")
      tab2.bg:SetTexture("Interface\\OptionsFrame\\UI-OptionsFrame-InactiveTab")
      tab3.bg:SetTexture("Interface\\OptionsFrame\\UI-OptionsFrame-InactiveTab")
      tab1Text:SetTextColor(1, 0.82, 0)
      tab2Text:SetTextColor(0.5, 0.5, 0.5)
      tab3Text:SetTextColor(0.5, 0.5, 0.5)
    elseif selectedTab == 2 then
      tab1.bg:SetTexture("Interface\\OptionsFrame\\UI-OptionsFrame-InactiveTab")
      tab2.bg:SetTexture("Interface\\OptionsFrame\\UI-OptionsFrame-ActiveTab")
      tab3.bg:SetTexture("Interface\\OptionsFrame\\UI-OptionsFrame-InactiveTab")
      tab1Text:SetTextColor(0.5, 0.5, 0.5)
      tab2Text:SetTextColor(1, 0.82, 0)
      tab3Text:SetTextColor(0.5, 0.5, 0.5)
    else
      tab1.bg:SetTexture("Interface\\OptionsFrame\\UI-OptionsFrame-InactiveTab")
      tab2.bg:SetTexture("Interface\\OptionsFrame\\UI-OptionsFrame-InactiveTab")
      tab3.bg:SetTexture("Interface\\OptionsFrame\\UI-OptionsFrame-ActiveTab")
      tab1Text:SetTextColor(0.5, 0.5, 0.5)
      tab2Text:SetTextColor(0.5, 0.5, 0.5)
      tab3Text:SetTextColor(1, 0.82, 0)
    end
  end

  -- Tab switching function
  local function SelectTab(tabID)
    selectedTab = tabID
    UpdateTabAppearance()
    
    if tabID == 1 then
      orbTab:Show()
      healthPowerTab:Hide()
      castTab:Hide()
      -- Refresh the tab to ensure values are loaded
      C_Timer.After(0.05, function()
        if orbTabInstance then orbTabInstance:Refresh() end
      end)
    elseif tabID == 2 then
      orbTab:Hide()
      healthPowerTab:Show()
      castTab:Hide()
      -- Refresh the tab to ensure values are loaded
      C_Timer.After(0.05, function()
        if healthPowerTabInstance then healthPowerTabInstance:Refresh() end
      end)
    else
      orbTab:Hide()
      healthPowerTab:Hide()
      castTab:Show()
      -- Refresh the tab to ensure values are loaded
      C_Timer.After(0.05, function()
        if castTabInstance then castTabInstance:Refresh() end
      end)
    end
  end

  -- Function to update scroll range for a tab
  local function UpdateScrollRange(scrollFrame, scrollChild)
    if not scrollFrame or not scrollChild or not scrollFrame:IsShown() then
      return
    end
    
    -- Ensure scroll child width matches scroll frame width
    scrollChild:SetWidth(scrollFrame:GetWidth())
    
    -- Find the bottom-most element
    local minY = 0
    local maxY = 0
    local hasElements = false
    
    -- Check all children
    local children = {scrollChild:GetChildren()}
    for _, child in ipairs(children) do
      if child then
        -- Check if child is visible (either shown or parent is shown)
        local isVisible = child:IsShown()
        if not isVisible and child.GetParent then
          local parent = child:GetParent()
          if parent then
            isVisible = parent:IsShown()
          end
        end
        
        if isVisible then
          local point, relativeTo, relativePoint, xOfs, yOfs = child:GetPoint()
          if yOfs then
            hasElements = true
            local height = child:GetHeight() or 0
            local top = yOfs
            local bottom = yOfs - height
            if top > maxY then maxY = top end
            if bottom < minY then minY = bottom end
          end
        end
      end
    end
    
    -- Check all regions (textures, font strings, etc.)
    local regions = {scrollChild:GetRegions()}
    for _, region in ipairs(regions) do
      if region and region.GetPoint then
        local isVisible = region:IsShown()
        if isVisible then
          local point, relativeTo, relativePoint, xOfs, yOfs = region:GetPoint()
          if yOfs then
            hasElements = true
            local height = region:GetHeight() or 0
            local top = yOfs
            local bottom = yOfs - height
            if top > maxY then maxY = top end
            if bottom < minY then minY = bottom end
          end
        end
      end
    end
    
    -- If no elements found, use a default height
    if not hasElements or (maxY == 0 and minY == 0) then
      scrollChild:SetHeight(scrollFrame:GetHeight())
      scrollFrame.scrollBar:SetMinMaxValues(0, 0)
      scrollFrame.scrollBar:Hide()
      scrollFrame:SetVerticalScroll(0)
      scrollFrame.scrollBar:SetValue(0)
      return
    end
    
    -- Set scroll child height (add padding at bottom)
    local contentHeight = math.abs(maxY - minY) + 40
    local frameHeight = scrollFrame:GetHeight()
    scrollChild:SetHeight(math.max(frameHeight, contentHeight))
    
    -- Update scroll bar range
    local maxScroll = math.max(0, contentHeight - frameHeight)
    scrollFrame.scrollBar:SetMinMaxValues(0, maxScroll)
    
    -- Show/hide scrollbar based on whether scrolling is needed
    if maxScroll > 0 then
      scrollFrame.scrollBar:Show()
    else
      scrollFrame.scrollBar:Hide()
    end
    
    -- Ensure scroll position is valid
    local currentScroll = scrollFrame:GetVerticalScroll()
    if currentScroll > maxScroll then
      scrollFrame:SetVerticalScroll(maxScroll)
      scrollFrame.scrollBar:SetValue(maxScroll)
    end
  end
  
  -- Update scroll ranges after content is created
  local function UpdateAllScrollRanges()
    UpdateScrollRange(orbTab, orbTabChild)
    UpdateScrollRange(healthPowerTab, healthPowerTabChild)
    UpdateScrollRange(castTab, castTabChild)
  end

  -- Store UpdateScrollRange function for use in tab switching
  local function UpdateScrollRangeForTab(tabID)
    if tabID == 1 then
      C_Timer.After(0.05, function() UpdateScrollRange(orbTab, orbTabChild) end)
      C_Timer.After(0.15, function() UpdateScrollRange(orbTab, orbTabChild) end) -- Second update to ensure accuracy
    elseif tabID == 2 then
      C_Timer.After(0.05, function() UpdateScrollRange(healthPowerTab, healthPowerTabChild) end)
      C_Timer.After(0.15, function() UpdateScrollRange(healthPowerTab, healthPowerTabChild) end)
    else
      C_Timer.After(0.05, function() UpdateScrollRange(castTab, castTabChild) end)
      C_Timer.After(0.15, function() UpdateScrollRange(castTab, castTabChild) end)
    end
  end

  tab1:SetScript("OnClick", function() 
    SelectTab(1)
    UpdateScrollRangeForTab(1)
  end)
  tab2:SetScript("OnClick", function() 
    SelectTab(2)
    UpdateScrollRangeForTab(2)
  end)
  tab3:SetScript("OnClick", function() 
    SelectTab(3)
    UpdateScrollRangeForTab(3)
  end)

  -- Initialize with tab 1
  UpdateTabAppearance()
  SelectTab(1)

  -- Create tab instances (use scrollChild as parent for content)
  orbTabInstance = OrbResourceTab:new(orbTabChild, panel)
  healthPowerTabInstance = HealthPowerTab:new(healthPowerTabChild, panel)
  castTabInstance = CastBarTab:new(castTabChild, panel)
  
  -- Create tab contents
  orbTabInstance:Create()
  healthPowerTabInstance:Create()
  castTabInstance:Create()
  
  -- Store update functions for each scroll frame (after UpdateScrollRange is defined)
  orbTab.updateScrollRange = function() UpdateScrollRange(orbTab, orbTabChild) end
  healthPowerTab.updateScrollRange = function() UpdateScrollRange(healthPowerTab, healthPowerTabChild) end
  castTab.updateScrollRange = function() UpdateScrollRange(castTab, castTabChild) end
  
  -- Update scroll ranges after content is created (multiple attempts to ensure accuracy)
  C_Timer.After(0.1, UpdateAllScrollRanges)
  C_Timer.After(0.2, UpdateAllScrollRanges)
  C_Timer.After(0.3, function()
    UpdateAllScrollRanges()
    -- Also update the currently visible tab
    UpdateScrollRangeForTab(selectedTab)
  end)
  
  -- Also update when panel is shown
  panel:SetScript("OnShow", function()
    -- Refresh all tabs to ensure values are loaded correctly
    C_Timer.After(0.05, function()
      if orbTabInstance then orbTabInstance:Refresh() end
      if healthPowerTabInstance then healthPowerTabInstance:Refresh() end
      if castTabInstance then castTabInstance:Refresh() end
    end)
    C_Timer.After(0.1, function()
      UpdateScrollRangeForTab(selectedTab)
    end)
  end)

  -- Panel refresh function
  panel.refresh = function()
    orbTabInstance:Refresh()
    healthPowerTabInstance:Refresh()
    castTabInstance:Refresh()
  end
  
  panel.okay = function()
    -- Called automatically by OnValueChanged handlers
  end

  panel.default = function()
    orbTabInstance:Reset()
    healthPowerTabInstance:Reset()
    castTabInstance:Reset()
  end

  local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name, panel.name)
  category.ID = panel.name
  Settings.RegisterAddOnCategory(category)

  WiseHudOptionsCategory = category
end

function WiseHudOptions_OnPlayerLogin()
  CreateOptionsPanel()
end
