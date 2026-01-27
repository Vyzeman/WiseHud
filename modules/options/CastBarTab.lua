local ADDON_NAME = ...

-- Cast Bar Tab Class

local OptionsTab = WiseHudOptionsBaseTab
local Helpers = WiseHudOptionsHelpers

local CAST_DEFAULTS = WiseHudConfig.GetCastDefaults()

-- Helper function to get statusbar names from LibSharedMedia
local function GetStatusbarNames()
  local names = {}
  local nameSet = {}
  
  local libStub = _G.LibStub
  if not libStub or type(libStub) ~= "table" or type(libStub.GetLibrary) ~= "function" then
    return names
  end
  
  local currentLSM = libStub:GetLibrary("LibSharedMedia-3.0", true)
  if not currentLSM then
    return names
  end
  
  local mediatype = "statusbar"
  
  if currentLSM.MediaTable then
    local mediaTable = currentLSM.MediaTable
    if type(mediaTable) == "table" then
      local statusbarMedia = mediaTable[mediatype]
      if statusbarMedia and type(statusbarMedia) == "table" then
        for name, data in pairs(statusbarMedia) do
          if type(name) == "string" and name ~= "" and not nameSet[name] then
            names[#names + 1] = name
            nameSet[name] = true
          end
        end
      end
    end
  end
  
  if currentLSM.List and type(currentLSM.List) == "function" then
    local success, list = pcall(function()
      return currentLSM:List(mediatype)
    end)
    if success and type(list) == "table" then
      for _, name in ipairs(list) do
        if type(name) == "string" and name ~= "" and not nameSet[name] then
          names[#names + 1] = name
          nameSet[name] = true
        end
      end
    end
  end
  
  if currentLSM.HashTable and type(currentLSM.HashTable) == "function" then
    local success, tbl = pcall(function() 
      return currentLSM:HashTable(mediatype)
    end)
    if success and type(tbl) == "table" then
      for name in pairs(tbl) do
        if type(name) == "string" and name ~= "" and not nameSet[name] then
          names[#names + 1] = name
          nameSet[name] = true
        end
      end
    end
  end
  
  table.sort(names)
  return names
end

local CastBarTab = setmetatable({}, {__index = OptionsTab})
CastBarTab.__index = CastBarTab

function CastBarTab:new(parent, panel)
  local instance = OptionsTab.new(self, parent, panel)
  return instance
end

function CastBarTab:Create()
  local e = self.elements
  
  WiseHudDB = WiseHudDB or {}
  WiseHudDB.castLayout = WiseHudDB.castLayout or {}
  local castCfg = WiseHudDB.castLayout
  
  local yOffset = -20
  
  -- Enable/Disable Section
  e.enableSection = Helpers.CreateSectionFrame(self.parent, "WiseHudCastEnableSection", nil, 500, 60)
  e.enableSection:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 20, yOffset)
  
  -- Cast enable/disable checkbox
  e.enabledCheckbox = Helpers.CreateCheckbox(e.enableSection, "WiseHudCastEnabledCheckbox", "Enable Cast Bar", castCfg.enabled, function(self, checked)
    WiseHudDB = WiseHudDB or {}
    WiseHudDB.castLayout = WiseHudDB.castLayout or {}
    local cfg = WiseHudDB.castLayout
    cfg.enabled = checked
    if WiseHudCast_SetEnabled then
      WiseHudCast_SetEnabled(checked)
    end
  end)
  e.enabledCheckbox:SetPoint("TOPLEFT", e.enableSection, "TOPLEFT", 12, -12)
  
  yOffset = yOffset - 80
  
  -- Texture Section
  e.textureSection = Helpers.CreateSectionFrame(self.parent, "WiseHudCastTextureSection", "Texture Settings", 500, 80)
  
  -- Position title above section
  if e.textureSection.titleText then
    e.textureSection.titleText:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 20, yOffset)
    yOffset = yOffset - 28 -- Space for title
  end
  
  e.textureSection:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 20, yOffset)
  
  local textureLabel = e.textureSection:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  textureLabel:SetPoint("TOPLEFT", e.textureSection, "TOPLEFT", 12, -12)
  textureLabel:SetText("Texture:")
  textureLabel:SetTextColor(1, 1, 1)
  
  e.textureDropdown = CreateFrame("Frame", "WiseHudCastTextureDropdown", e.textureSection, "UIDropDownMenuTemplate")
  e.textureDropdown:SetPoint("TOPLEFT", textureLabel, "BOTTOMLEFT", -16, -8)
  
  local currentTexture = castCfg.texture or castCfg.fillTexture or castCfg.bgTexture or CAST_DEFAULTS.textureName
  UIDropDownMenu_SetWidth(e.textureDropdown, 220)
  UIDropDownMenu_SetText(e.textureDropdown, currentTexture)
  
  self.RefreshTextureDropdown = function()
    local statusbarNames = GetStatusbarNames()
    WiseHudDB = WiseHudDB or {}
    WiseHudDB.castLayout = WiseHudDB.castLayout or {}
    local cfg = WiseHudDB.castLayout
    local selected = cfg.texture or cfg.fillTexture or cfg.bgTexture or CAST_DEFAULTS.textureName
    
    local found = false
    for _, name in ipairs(statusbarNames) do
      if name == selected then
        found = true
        break
      end
    end
    if found then
      UIDropDownMenu_SetText(e.textureDropdown, selected)
    else
      UIDropDownMenu_SetText(e.textureDropdown, statusbarNames[1] or CAST_DEFAULTS.textureName)
    end
  end
  
  self.InitializeTextureDropdown = function(self, level)
    local statusbarNames = GetStatusbarNames()
    WiseHudDB = WiseHudDB or {}
    WiseHudDB.castLayout = WiseHudDB.castLayout or {}
    local cfg = WiseHudDB.castLayout
    local selected = cfg.texture or cfg.fillTexture or cfg.bgTexture or CAST_DEFAULTS.textureName
    
    if #statusbarNames == 0 then
      local lsm = nil
      local libStub = _G.LibStub
      if libStub and type(libStub) == "table" and type(libStub.GetLibrary) == "function" then
        lsm = libStub:GetLibrary("LibSharedMedia-3.0", true)
      end
      
      if lsm then
        if lsm.MediaTable and lsm.MediaTable.statusbar then
          for name, path in pairs(lsm.MediaTable.statusbar) do
            if type(name) == "string" and name ~= "" then
              statusbarNames[#statusbarNames + 1] = name
            end
          end
          table.sort(statusbarNames)
        end
      end
      
      if #statusbarNames == 0 then
        local info = UIDropDownMenu_CreateInfo()
        local ok, status = Helpers.CheckLSMAvailability()
        if ok then
          info.text = "LSM loaded but no textures found"
        else
          info.text = "LSM Error: " .. status
        end
        info.notCheckable = true
        info.disabled = true
        UIDropDownMenu_AddButton(info, level)
        return
      end
    end
    
    for _, textureName in ipairs(statusbarNames) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = textureName
      info.func = function()
        UIDropDownMenu_SetSelectedValue(e.textureDropdown, textureName)
        UIDropDownMenu_SetText(e.textureDropdown, textureName)
        WiseHudDB = WiseHudDB or {}
        WiseHudDB.castLayout = WiseHudDB.castLayout or {}
        local cfg = WiseHudDB.castLayout
        cfg.texture = textureName
        cfg.fillTexture = textureName
        cfg.bgTexture = textureName
        if WiseHudCast_UpdateTexture then
          WiseHudCast_UpdateTexture()
        end
      end
      info.checked = (textureName == selected)
      UIDropDownMenu_AddButton(info, level)
    end
  end
  
  UIDropDownMenu_Initialize(e.textureDropdown, self.InitializeTextureDropdown)
  
  local textureDropdownButton = _G[e.textureDropdown:GetName() .. "Button"]
  if textureDropdownButton then
    textureDropdownButton:SetScript("OnClick", nil)
    local tabInstance = self
    textureDropdownButton:SetScript("OnClick", function(button)
      UIDropDownMenu_Initialize(e.textureDropdown, tabInstance.InitializeTextureDropdown)
      ToggleDropDownMenu(1, nil, e.textureDropdown, button, 0, 0)
    end)
  end
  
  local libStub = _G.LibStub
  if libStub and type(libStub) == "table" and type(libStub.GetLibrary) == "function" then
    local lsm = libStub:GetLibrary("LibSharedMedia-3.0", true)
    if lsm and lsm.RegisterCallback then
      local tabInstance = self
      lsm:RegisterCallback("LibSharedMedia_Registered", function(event, mediatype, key)
        if mediatype == "statusbar" then
          tabInstance.RefreshTextureDropdown()
        end
      end)
    end
  end
  
  self.RefreshTextureDropdown()
  
  yOffset = yOffset - 100
  
  -- Cast Bar Position Section
  local castLayout = WiseHudDB.castLayout
  e.positionSection = Helpers.CreateSectionFrame(self.parent, "WiseHudCastPositionSection", "Cast Bar Position", 500, 320)
  
  -- Position title above section
  if e.positionSection.titleText then
    e.positionSection.titleText:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 20, yOffset)
    yOffset = yOffset - 28 -- Space for title
  end
  
  e.positionSection:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 20, yOffset)
  
  -- Cast Bar Width
  e.widthSlider = Helpers.CreateSlider(e.positionSection, "WiseHudCastWidthSlider", "Cast Width", 100, 400, 5, castLayout.width or CAST_DEFAULTS.width, nil, function(self, value)
    WiseHudDB = WiseHudDB or {}
    WiseHudDB.castLayout = WiseHudDB.castLayout or {}
    local cfg = WiseHudDB.castLayout
    cfg.width = value
    if WiseHudCast_ApplyLayout then WiseHudCast_ApplyLayout() end
  end)
  e.widthSlider:SetPoint("TOPLEFT", e.positionSection, "TOPLEFT", 12, -12)
  
  -- Cast Bar Height
  e.heightSlider = Helpers.CreateSlider(e.positionSection, "WiseHudCastHeightSlider", "Cast Height", 10, 50, 1, castLayout.height or CAST_DEFAULTS.height, nil, function(self, value)
    WiseHudDB = WiseHudDB or {}
    WiseHudDB.castLayout = WiseHudDB.castLayout or {}
    local cfg = WiseHudDB.castLayout
    cfg.height = value
    if WiseHudCast_ApplyLayout then WiseHudCast_ApplyLayout() end
  end)
  e.heightSlider:SetPoint("TOPLEFT", e.widthSlider, "BOTTOMLEFT", 0, -20)
  
  -- Cast Bar X Offset
  e.xSlider = Helpers.CreateSlider(e.positionSection, "WiseHudCastXSlider", "Cast X", -400, 400, 5, castLayout.offsetX or CAST_DEFAULTS.offsetX, nil, function(self, value)
    WiseHudDB = WiseHudDB or {}
    WiseHudDB.castLayout = WiseHudDB.castLayout or {}
    local cfg = WiseHudDB.castLayout
    cfg.offsetX = value
    if WiseHudCast_ApplyLayout then WiseHudCast_ApplyLayout() end
  end)
  e.xSlider:SetPoint("TOPLEFT", e.heightSlider, "BOTTOMLEFT", 0, -20)
  
  -- Cast Bar Y Offset
  e.ySlider = Helpers.CreateSlider(e.positionSection, "WiseHudCastYSlider", "Cast Y", -400, 400, 5, castLayout.offsetY or CAST_DEFAULTS.offsetY, nil, function(self, value)
    WiseHudDB = WiseHudDB or {}
    WiseHudDB.castLayout = WiseHudDB.castLayout or {}
    local cfg = WiseHudDB.castLayout
    cfg.offsetY = value
    if WiseHudCast_ApplyLayout then WiseHudCast_ApplyLayout() end
  end)
  e.ySlider:SetPoint("TOPLEFT", e.xSlider, "BOTTOMLEFT", 0, -20)
  
  -- Show Text Checkbox (inside position section)
  local initialShowText = castLayout.showText
  if initialShowText == nil then
    initialShowText = CAST_DEFAULTS.showText
  end
  e.showTextCheck = Helpers.CreateCheckbox(e.positionSection, "WiseHudCastShowTextCheck", "Show Spell Name", initialShowText, function(self, checked)
    WiseHudDB = WiseHudDB or {}
    WiseHudDB.castLayout = WiseHudDB.castLayout or {}
    local cfg = WiseHudDB.castLayout
    cfg.showText = checked
    if WiseHudCast_ApplyLayout then WiseHudCast_ApplyLayout() end
  end)
  e.showTextCheck:SetPoint("TOPLEFT", e.ySlider, "BOTTOMLEFT", 0, -20)
  
  -- Calculate yOffset for next section: position section height (320) + title space (28) + padding
  yOffset = yOffset - 320 - 20 -- Section height + extra padding
  
  -- Color Section
  e.colorSection = Helpers.CreateSectionFrame(self.parent, "WiseHudCastColorSection", "Color Settings", 500, 180)
  
  -- Position title above section
  if e.colorSection.titleText then
    e.colorSection.titleText:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 20, yOffset)
    yOffset = yOffset - 28 -- Space for title
  end
  
  e.colorSection:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 20, yOffset)
  
  -- Fill Color Settings
  local fillColorLabel = e.colorSection:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  fillColorLabel:SetPoint("TOPLEFT", e.colorSection, "TOPLEFT", 12, -12)
  fillColorLabel:SetText("Fill Color:")
  fillColorLabel:SetTextColor(1, 1, 1)
  
  self.UpdateFillColorSwatch = function()
    if not e.fillColorButton or not e.fillColorButton.texture then return end
    WiseHudDB = WiseHudDB or {}
    WiseHudDB.castLayout = WiseHudDB.castLayout or {}
    local cfg = WiseHudDB.castLayout
    local defaults = CAST_DEFAULTS.fill
    local r = (cfg.fillR or defaults.r) / 255
    local g = (cfg.fillG or defaults.g) / 255
    local b = (cfg.fillB or defaults.b) / 255
    e.fillColorButton.texture:SetVertexColor(r, g, b)
    e.fillColorButton.texture:Show()
  end
  
  e.fillColorButton = Helpers.CreateColorPicker(
    e.colorSection,
    "WiseHudCastFillColorButton",
    "Fill Color",
    function()
      WiseHudDB = WiseHudDB or {}
      WiseHudDB.castLayout = WiseHudDB.castLayout or {}
      local cfg = WiseHudDB.castLayout
      local defaults = CAST_DEFAULTS.fill
      return (cfg.fillR or defaults.r) / 255, (cfg.fillG or defaults.g) / 255, (cfg.fillB or defaults.b) / 255, 1
    end,
    function(r, g, b, a)
      WiseHudDB = WiseHudDB or {}
      WiseHudDB.castLayout = WiseHudDB.castLayout or {}
      local cfg = WiseHudDB.castLayout
      cfg.fillR = math.floor(r * 255 + 0.5)
      cfg.fillG = math.floor(g * 255 + 0.5)
      cfg.fillB = math.floor(b * 255 + 0.5)
      if WiseHudCast_UpdateColors then WiseHudCast_UpdateColors() end
    end,
    self.UpdateFillColorSwatch,
    false
  )
  e.fillColorButton:SetPoint("TOPLEFT", fillColorLabel, "BOTTOMLEFT", 0, -8)
  self.UpdateFillColorSwatch()
  
  -- Background Color Settings
  local bgColorLabel = e.colorSection:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  bgColorLabel:SetPoint("TOPLEFT", e.fillColorButton, "BOTTOMLEFT", 0, -20)
  bgColorLabel:SetText("Background Color:")
  bgColorLabel:SetTextColor(1, 1, 1)
  
  self.UpdateBgColorSwatch = function()
    if not e.bgColorButton or not e.bgColorButton.texture then return end
    WiseHudDB = WiseHudDB or {}
    WiseHudDB.castLayout = WiseHudDB.castLayout or {}
    local cfg = WiseHudDB.castLayout
    local defaults = CAST_DEFAULTS.bg
    local r = (cfg.bgR or defaults.r) / 255
    local g = (cfg.bgG or defaults.g) / 255
    local b = (cfg.bgB or defaults.b) / 255
    e.bgColorButton.texture:SetVertexColor(r, g, b)
    e.bgColorButton.texture:Show()
  end
  
  e.bgColorButton = Helpers.CreateColorPicker(
    e.colorSection,
    "WiseHudCastBgColorButton",
    "Background Color",
    function()
      WiseHudDB = WiseHudDB or {}
      WiseHudDB.castLayout = WiseHudDB.castLayout or {}
      local cfg = WiseHudDB.castLayout
      local defaults = CAST_DEFAULTS.bg
      return (cfg.bgR or defaults.r) / 255, (cfg.bgG or defaults.g) / 255, (cfg.bgB or defaults.b) / 255, (cfg.bgA or defaults.a) / 100
    end,
    function(r, g, b, a)
      WiseHudDB = WiseHudDB or {}
      WiseHudDB.castLayout = WiseHudDB.castLayout or {}
      local cfg = WiseHudDB.castLayout
      cfg.bgR = math.floor(r * 255 + 0.5)
      cfg.bgG = math.floor(g * 255 + 0.5)
      cfg.bgB = math.floor(b * 255 + 0.5)
      cfg.bgA = math.floor(a * 100 + 0.5)
      if WiseHudCast_UpdateColors then WiseHudCast_UpdateColors() end
    end,
    self.UpdateBgColorSwatch,
    true
  )
  e.bgColorButton:SetPoint("TOPLEFT", bgColorLabel, "BOTTOMLEFT", 0, -8)
  self.UpdateBgColorSwatch()
  
  -- Calculate yOffset for reset button: color section bottom + padding
  yOffset = yOffset - 180 - 40 -- Section height + padding
  
  -- Reset Button (positioned at the end of content)
  e.resetButton = Helpers.CreateResetButton(
    self.parent,
    "WiseHudCastResetButton",
    "WISEHUD_RESET_CASTBAR",
    "Are you sure you want to reset all Cast Bar settings to their default values?",
    self,
    "TOPLEFT",
    self.parent,
    "TOPLEFT",
    20,
    yOffset
  )
end

function CastBarTab:Refresh()
  if self.RefreshTextureDropdown then
    self.RefreshTextureDropdown()
  end
  if self.InitializeTextureDropdown and self.elements.textureDropdown then
    UIDropDownMenu_Initialize(self.elements.textureDropdown, self.InitializeTextureDropdown)
  end
  if self.UpdateFillColorSwatch then self.UpdateFillColorSwatch() end
  if self.UpdateBgColorSwatch then self.UpdateBgColorSwatch() end
  
  -- Reload values from config and update sliders
  WiseHudDB = WiseHudDB or {}
  WiseHudDB.castLayout = WiseHudDB.castLayout or {}
  local castCfg = WiseHudDB.castLayout
  local e = self.elements
  
  -- Helper function to refresh a slider with a value from config
  local function RefreshSlider(sliderContainer, configValue, defaultValue)
    if not sliderContainer or not sliderContainer.slider then return end
    
    local value = configValue
    if value == nil then
      value = defaultValue
    end
    
    -- Ensure value is a number
    value = tonumber(value)
    if not value then return end
    
    -- Expand range if needed
    if sliderContainer.ExpandSliderRange then
      sliderContainer.ExpandSliderRange(value)
    end
    
    -- Update slider range if it was expanded
    if sliderContainer.currentMin and sliderContainer.currentMax then
      sliderContainer.slider:SetMinMaxValues(sliderContainer.currentMin, sliderContainer.currentMax)
      local sliderName = sliderContainer.slider:GetName()
      if _G[sliderName .. "Low"] then
        _G[sliderName .. "Low"]:SetText(tostring(sliderContainer.currentMin))
      end
      if _G[sliderName .. "High"] then
        _G[sliderName .. "High"]:SetText(tostring(sliderContainer.currentMax))
      end
    end
    
    -- Round value to step
    local step = sliderContainer.step or 1
    local roundedValue
    if step < 1 then
      roundedValue = math.floor(value / step + 0.5) * step
    else
      roundedValue = math.floor(value + 0.5)
    end
    
    -- Ensure value is within range
    local minVal = sliderContainer.currentMin or sliderContainer.initialMin
    local maxVal = sliderContainer.currentMax or sliderContainer.initialMax
    roundedValue = math.max(minVal, math.min(maxVal, roundedValue))
    
    -- Set slider value
    sliderContainer.slider:SetValue(roundedValue)
    
    -- Update display
    if sliderContainer.UpdateDisplay then
      sliderContainer.UpdateDisplay(roundedValue)
    end
  end
  
  -- Refresh all sliders with their config values
  RefreshSlider(e.widthSlider, castCfg.width, CAST_DEFAULTS.width)
  RefreshSlider(e.heightSlider, castCfg.height, CAST_DEFAULTS.height)
  RefreshSlider(e.xSlider, castCfg.offsetX, CAST_DEFAULTS.offsetX)
  RefreshSlider(e.ySlider, castCfg.offsetY, CAST_DEFAULTS.offsetY)
  
  -- Update checkboxes
  if e.enabledCheckbox then
    e.enabledCheckbox:SetChecked(castCfg.enabled ~= false)
  end
  if e.showTextCheck then
    if castCfg.showText == nil then
      e.showTextCheck:SetChecked(CAST_DEFAULTS.showText)
    else
      e.showTextCheck:SetChecked(castCfg.showText)
    end
  end
end

function CastBarTab:Reset()
  WiseHudDB = WiseHudDB or {}
  WiseHudDB.castLayout = WiseHudDB.castLayout or {}
  local castCfg = WiseHudDB.castLayout
  -- Reset layout values back to central defaults
  castCfg.width = CAST_DEFAULTS.width
  castCfg.height = CAST_DEFAULTS.height
  castCfg.offsetX = CAST_DEFAULTS.offsetX
  castCfg.offsetY = CAST_DEFAULTS.offsetY
  -- Enabled / show text use their default-true semantics
  castCfg.enabled = true
  castCfg.showText = CAST_DEFAULTS.showText

  -- Reset texture selection back to the central default
  castCfg.texture = CAST_DEFAULTS.textureName
  castCfg.fillTexture = CAST_DEFAULTS.textureName
  castCfg.bgTexture = CAST_DEFAULTS.textureName

  -- Reset fill and background colors explicitly to their defaults
  castCfg.fillR = CAST_DEFAULTS.fill.r
  castCfg.fillG = CAST_DEFAULTS.fill.g
  castCfg.fillB = CAST_DEFAULTS.fill.b
  castCfg.bgR = CAST_DEFAULTS.bg.r
  castCfg.bgG = CAST_DEFAULTS.bg.g
  castCfg.bgB = CAST_DEFAULTS.bg.b
  castCfg.bgA = CAST_DEFAULTS.bg.a
  
  local e = self.elements
  if e.widthSlider and e.widthSlider.slider then 
    e.widthSlider.slider:SetValue(CAST_DEFAULTS.width)
    if e.widthSlider.UpdateDisplay then e.widthSlider.UpdateDisplay(CAST_DEFAULTS.width) end
  end
  if e.heightSlider and e.heightSlider.slider then 
    e.heightSlider.slider:SetValue(CAST_DEFAULTS.height)
    if e.heightSlider.UpdateDisplay then e.heightSlider.UpdateDisplay(CAST_DEFAULTS.height) end
  end
  if e.xSlider and e.xSlider.slider then 
    e.xSlider.slider:SetValue(CAST_DEFAULTS.offsetX)
    if e.xSlider.UpdateDisplay then e.xSlider.UpdateDisplay(CAST_DEFAULTS.offsetX) end
  end
  if e.ySlider and e.ySlider.slider then 
    e.ySlider.slider:SetValue(CAST_DEFAULTS.offsetY)
    if e.ySlider.UpdateDisplay then e.ySlider.UpdateDisplay(CAST_DEFAULTS.offsetY) end
  end
  if e.enabledCheckbox then e.enabledCheckbox:SetChecked(true) end
  if e.showTextCheck then e.showTextCheck:SetChecked(true) end
  if e.textureDropdown then
    UIDropDownMenu_SetText(e.textureDropdown, CAST_DEFAULTS.textureName)
    UIDropDownMenu_SetSelectedValue(e.textureDropdown, CAST_DEFAULTS.textureName)
  end
  
  if self.UpdateFillColorSwatch then self.UpdateFillColorSwatch() end
  if self.UpdateBgColorSwatch then self.UpdateBgColorSwatch() end
  if WiseHudCast_SetEnabled then WiseHudCast_SetEnabled(true) end
  if WiseHudCast_UpdateTexture then WiseHudCast_UpdateTexture() end
  if WiseHudCast_UpdateColors then WiseHudCast_UpdateColors() end
  if WiseHudCast_ApplyLayout then WiseHudCast_ApplyLayout() end
end

-- Export class
WiseHudOptionsCastBarTab = CastBarTab
