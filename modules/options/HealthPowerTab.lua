local ADDON_NAME = ...

-- Health/Power Tab Class

local OptionsTab = WiseHudOptionsBaseTab
local Helpers = WiseHudOptionsHelpers

local HP_DEFAULTS = WiseHudConfig.GetHealthPowerDefaults()

local HealthPowerTab = setmetatable({}, {__index = OptionsTab})
HealthPowerTab.__index = HealthPowerTab

function HealthPowerTab:new(parent, panel)
  local instance = OptionsTab.new(self, parent, panel)
  return instance
end

function HealthPowerTab:Create()
  local e = self.elements
  local healthCfg = Helpers.ensureLayoutTable()
  
  local yOffset = -20
  
  -- Enable/Disable Section
  e.enableSection = Helpers.CreateSectionFrame(self.parent, "WiseHudHealthPowerEnableSection", nil, 500, 80)
  e.enableSection:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 20, yOffset)
  
  -- Health enable/disable checkbox
  e.healthEnabledCheckbox = Helpers.CreateCheckbox(e.enableSection, "WiseHudHealthEnabledCheckbox", "Enable Health", healthCfg.healthEnabled, function(self, checked)
    local cfg = Helpers.ensureLayoutTable()
    cfg.healthEnabled = checked
    if WiseHudHealth_SetEnabled then
      WiseHudHealth_SetEnabled(checked)
    end
  end)
  -- Use standard section padding for inner content
  e.healthEnabledCheckbox:SetPoint("TOPLEFT", e.enableSection, "TOPLEFT", Helpers.SECTION_PADDING_LEFT, -Helpers.SECTION_PADDING_TOP)
  
  -- Power enable/disable checkbox
  e.powerEnabledCheckbox = Helpers.CreateCheckbox(e.enableSection, "WiseHudPowerEnabledCheckbox", "Enable Power", healthCfg.powerEnabled, function(self, checked)
    local cfg = Helpers.ensureLayoutTable()
    cfg.powerEnabled = checked
    if WiseHudPower_SetEnabled then
      WiseHudPower_SetEnabled(checked)
    end
  end)
  e.powerEnabledCheckbox:SetPoint("TOPLEFT", e.healthEnabledCheckbox, "BOTTOMLEFT", 0, -8)
  
  yOffset = yOffset - 100
  
  -- Layout Section
  local layout = Helpers.ensureLayoutTable()
  e.layoutSection = Helpers.CreateSectionFrame(self.parent, "WiseHudHealthPowerLayoutSection", "Position Settings", 500, 280)
  yOffset = Helpers.AnchorSectionWithTitle(self.parent, e.layoutSection, yOffset, {
    contentHeight = 280,
    spacingBelow = 20,
  })
  
  -- Width
  e.widthSlider = Helpers.CreateSlider(e.layoutSection, "WiseHudBarWidthSlider", "Width", 120, 400, 5, layout.width or HP_DEFAULTS.layout.width, nil, function(self, value)
    local cfg = Helpers.ensureLayoutTable()
    cfg.width = value
    if WiseHudHealth_ApplyLayout then WiseHudHealth_ApplyLayout() end
    if WiseHudPower_ApplyLayout then WiseHudPower_ApplyLayout() end
  end)
  e.widthSlider:SetPoint("TOPLEFT", e.layoutSection, "TOPLEFT", Helpers.SECTION_PADDING_LEFT, -Helpers.SECTION_PADDING_TOP)
  
  -- Height
  e.heightSlider = Helpers.CreateSlider(e.layoutSection, "WiseHudBarHeightSlider", "Height", 330, 500, 5, layout.height or HP_DEFAULTS.layout.height, nil, function(self, value)
    local cfg = Helpers.ensureLayoutTable()
    cfg.height = value
    if WiseHudHealth_ApplyLayout then WiseHudHealth_ApplyLayout() end
    if WiseHudPower_ApplyLayout then WiseHudPower_ApplyLayout() end
  end)
  e.heightSlider:SetPoint("TOPLEFT", e.widthSlider, "BOTTOMLEFT", 0, -20)
  
  -- Distance X (expanded range so default is not at the edge)
  e.offsetSlider = Helpers.CreateSlider(e.layoutSection, "WiseHudBarOffsetSlider", "Distance X", 150, 250, 5, layout.offset or HP_DEFAULTS.layout.offsetX, nil, function(self, value)
    local cfg = Helpers.ensureLayoutTable()
    cfg.offset = value
    if WiseHudHealth_ApplyLayout then WiseHudHealth_ApplyLayout() end
    if WiseHudPower_ApplyLayout then WiseHudPower_ApplyLayout() end
  end)
  e.offsetSlider:SetPoint("TOPLEFT", e.heightSlider, "BOTTOMLEFT", 0, -20)
  
  -- Distance Y
  e.offsetYSlider = Helpers.CreateSlider(e.layoutSection, "WiseHudBarOffsetYSlider", "Distance Y", -20, 200, 5, layout.offsetY or HP_DEFAULTS.layout.offsetY, nil, function(self, value)
    local cfg = Helpers.ensureLayoutTable()
    cfg.offsetY = value
    if WiseHudHealth_ApplyLayout then WiseHudHealth_ApplyLayout() end
    if WiseHudPower_ApplyLayout then WiseHudPower_ApplyLayout() end
  end)
  e.offsetYSlider:SetPoint("TOPLEFT", e.offsetSlider, "BOTTOMLEFT", 0, -20)

  -- Alpha settings
  local alphaCfg = Helpers.ensureAlphaTable()
  e.alphaSection = Helpers.CreateSectionFrame(self.parent, "WiseHudHealthPowerAlphaSection", "Alpha Settings", 500, 210)
  yOffset = Helpers.AnchorSectionWithTitle(self.parent, e.alphaSection, yOffset, {
    contentHeight = 210,
    -- Alpha section previously used slightly less spacing below (210 + 10).
    spacingBelow = 10,
  })
  
  -- Combat Alpha
  e.combatAlphaSlider = Helpers.CreateSlider(e.alphaSection, "WiseHudCombatAlphaSlider", "Combat Alpha", 0, 100, 5, alphaCfg.combatAlpha or HP_DEFAULTS.alpha.combat, "%d%%", function(self, value)
    local cfg = Helpers.ensureAlphaTable()
    cfg.combatAlpha = value
    if WiseHudHealth_ApplyAlpha then WiseHudHealth_ApplyAlpha() end
    if WiseHudPower_ApplyAlpha then WiseHudPower_ApplyAlpha() end
  end)
  e.combatAlphaSlider:SetPoint("TOPLEFT", e.alphaSection, "TOPLEFT", Helpers.SECTION_PADDING_LEFT, -Helpers.SECTION_PADDING_TOP)
  
  -- Out of combat (while recently changed)
  e.nonFullAlphaSlider = Helpers.CreateSlider(e.alphaSection, "WiseHudNonFullAlphaSlider", "Out of Combat Alpha", 0, 100, 5, alphaCfg.nonFullAlpha or HP_DEFAULTS.alpha.nonFull, "%d%%", function(self, value)
    local cfg = Helpers.ensureAlphaTable()
    cfg.nonFullAlpha = value
    if WiseHudHealth_ApplyAlpha then WiseHudHealth_ApplyAlpha() end
    if WiseHudPower_ApplyAlpha then WiseHudPower_ApplyAlpha() end
  end)
  e.nonFullAlphaSlider:SetPoint("TOPLEFT", e.combatAlphaSlider, "BOTTOMLEFT", 0, -20)
  
  -- Idle out of combat (no recent changes)
  e.fullIdleAlphaSlider = Helpers.CreateSlider(e.alphaSection, "WiseHudFullIdleAlphaSlider", "Idle Alpha", 0, 100, 5, alphaCfg.fullIdleAlpha or HP_DEFAULTS.alpha.fullIdle, "%d%%", function(self, value)
    local cfg = Helpers.ensureAlphaTable()
    cfg.fullIdleAlpha = value
    if WiseHudHealth_ApplyAlpha then WiseHudHealth_ApplyAlpha() end
    if WiseHudPower_ApplyAlpha then WiseHudPower_ApplyAlpha() end
  end)
  e.fullIdleAlphaSlider:SetPoint("TOPLEFT", e.nonFullAlphaSlider, "BOTTOMLEFT", 0, -20)

  -- Color Section
  e.colorSection = Helpers.CreateSectionFrame(self.parent, "WiseHudHealthPowerColorSection", "Color Settings", 500, 150)
  yOffset = Helpers.AnchorSectionWithTitle(self.parent, e.colorSection, yOffset, {
    contentHeight = 150,
    spacingBelow = 20,
  })
  
  -- Health Bar Color
  local healthColorLabel = e.colorSection:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  healthColorLabel:SetPoint("TOPLEFT", e.colorSection, "TOPLEFT", Helpers.SECTION_PADDING_LEFT, -Helpers.SECTION_PADDING_TOP)
  healthColorLabel:SetText("Health Bar Color:")
  healthColorLabel:SetTextColor(1, 1, 1)
  
  self.UpdateHealthColorSwatch = function()
    if not e.healthColorButton or not e.healthColorButton.texture then return end
    local cfg = Helpers.ensureLayoutTable()
    local defaults = HP_DEFAULTS.colors.health
    local r = (cfg.healthR or defaults.r) / 255
    local g = (cfg.healthG or defaults.g) / 255
    local b = (cfg.healthB or defaults.b) / 255
    e.healthColorButton.texture:SetVertexColor(r, g, b)
    e.healthColorButton.texture:Show()
  end
  
  e.healthColorButton = Helpers.CreateColorPicker(
    e.colorSection,
    "WiseHudHealthColorButton",
    "Health Bar Color",
    function()
      local cfg = Helpers.ensureLayoutTable()
      local defaults = HP_DEFAULTS.colors.health
      return (cfg.healthR or defaults.r) / 255, (cfg.healthG or defaults.g) / 255, (cfg.healthB or defaults.b) / 255, 1
    end,
    function(r, g, b, a)
      local cfg = Helpers.ensureLayoutTable()
      cfg.healthR = math.floor(r * 255 + 0.5)
      cfg.healthG = math.floor(g * 255 + 0.5)
      cfg.healthB = math.floor(b * 255 + 0.5)
      if WiseHudHealth_UpdateColor then WiseHudHealth_UpdateColor() end
    end,
    self.UpdateHealthColorSwatch,
    false
  )
  e.healthColorButton:SetPoint("TOPLEFT", healthColorLabel, "BOTTOMLEFT", 0, -8)
  self.UpdateHealthColorSwatch()
  
  -- Power Bar Color
  local powerColorLabel = e.colorSection:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  powerColorLabel:SetPoint("TOPLEFT", e.healthColorButton, "BOTTOMLEFT", 0, -20)
  powerColorLabel:SetText("Power Bar Color (overrides class default):")
  powerColorLabel:SetTextColor(1, 1, 1)
  
  self.UpdatePowerColorSwatch = function()
    if not e.powerColorButton or not e.powerColorButton.texture then return end
    local cfg = Helpers.ensureLayoutTable()
    local defaults = HP_DEFAULTS.colors.power
    local r = (cfg.powerR or defaults.r) / 255
    local g = (cfg.powerG or defaults.g) / 255
    local b = (cfg.powerB or defaults.b) / 255
    e.powerColorButton.texture:SetVertexColor(r, g, b)
    e.powerColorButton.texture:Show()
  end
  
  e.powerColorButton = Helpers.CreateColorPicker(
    e.colorSection,
    "WiseHudPowerColorButton",
    "Power Bar Color",
    function()
      local cfg = Helpers.ensureLayoutTable()
      local defaults = HP_DEFAULTS.colors.power
      return (cfg.powerR or defaults.r) / 255, (cfg.powerG or defaults.g) / 255, (cfg.powerB or defaults.b) / 255, 1
    end,
    function(r, g, b, a)
      local cfg = Helpers.ensureLayoutTable()
      cfg.powerR = math.floor(r * 255 + 0.5)
      cfg.powerG = math.floor(g * 255 + 0.5)
      cfg.powerB = math.floor(b * 255 + 0.5)
      if WiseHudPower_UpdateColor then WiseHudPower_UpdateColor() end
    end,
    self.UpdatePowerColorSwatch,
    false
  )
  e.powerColorButton:SetPoint("TOPLEFT", powerColorLabel, "BOTTOMLEFT", 0, -8)
  self.UpdatePowerColorSwatch()
  
  -- Calculate yOffset for reset button: color section bottom + padding
  -- Use etwas geringeres Bottom-Padding, analog zum Orb-Tab (ca. 20px)
  -- (already handled by AnchorSectionWithTitle above)
  
  -- Reset Button (positioned at the end of content)
  e.resetButton = Helpers.CreateResetButton(
    self.parent,
    "WiseHudHealthPowerResetButton",
    "WISEHUD_RESET_HEALTHPOWER",
    "Are you sure you want to reset all Health/Power settings to their default values?",
    self,
    "TOPLEFT",
    self.parent,
    "TOPLEFT",
    20,
    yOffset
  )
end

function HealthPowerTab:Refresh()
  if self.UpdateHealthColorSwatch then self.UpdateHealthColorSwatch() end
  if self.UpdatePowerColorSwatch then self.UpdatePowerColorSwatch() end
  
  -- Reload values from config and update sliders
  local healthCfg = Helpers.ensureLayoutTable()
  local alphaCfg = Helpers.ensureAlphaTable()
  local e = self.elements
  
  -- Refresh all sliders with their config values
  Helpers.RefreshSliderFromConfig(e.widthSlider, healthCfg.width, HP_DEFAULTS.layout.width)
  Helpers.RefreshSliderFromConfig(e.heightSlider, healthCfg.height, HP_DEFAULTS.layout.height)
  Helpers.RefreshSliderFromConfig(e.offsetSlider, healthCfg.offset, HP_DEFAULTS.layout.offsetX)
  Helpers.RefreshSliderFromConfig(e.offsetYSlider, healthCfg.offsetY, HP_DEFAULTS.layout.offsetY)
  Helpers.RefreshSliderFromConfig(e.combatAlphaSlider, alphaCfg.combatAlpha, HP_DEFAULTS.alpha.combat)
  Helpers.RefreshSliderFromConfig(e.nonFullAlphaSlider, alphaCfg.nonFullAlpha, HP_DEFAULTS.alpha.nonFull)
  Helpers.RefreshSliderFromConfig(e.fullIdleAlphaSlider, alphaCfg.fullIdleAlpha, HP_DEFAULTS.alpha.fullIdle)
  
  -- Update checkboxes
  if e.healthEnabledCheckbox then
    e.healthEnabledCheckbox:SetChecked(healthCfg.healthEnabled ~= false)
  end
  if e.powerEnabledCheckbox then
    e.powerEnabledCheckbox:SetChecked(healthCfg.powerEnabled ~= false)
  end
end

function HealthPowerTab:Reset()
  local healthCfg = Helpers.ensureLayoutTable()
  healthCfg.width = nil
  healthCfg.height = nil
  healthCfg.offset = nil
  healthCfg.offsetY = nil
  healthCfg.healthEnabled = nil
  healthCfg.powerEnabled = nil
  healthCfg.healthR = nil
  healthCfg.healthG = nil
  healthCfg.healthB = nil
  healthCfg.powerR = nil
  healthCfg.powerG = nil
  healthCfg.powerB = nil
  
  local alphaCfg = Helpers.ensureAlphaTable()
  alphaCfg.combatAlpha = nil
  alphaCfg.nonFullAlpha = nil
  alphaCfg.fullIdleAlpha = nil
  
  local e = self.elements
  if e.widthSlider and e.widthSlider.slider then 
    e.widthSlider.slider:SetValue(HP_DEFAULTS.layout.width)
    if e.widthSlider.UpdateDisplay then e.widthSlider.UpdateDisplay(HP_DEFAULTS.layout.width) end
  end
  if e.heightSlider and e.heightSlider.slider then 
    e.heightSlider.slider:SetValue(HP_DEFAULTS.layout.height)
    if e.heightSlider.UpdateDisplay then e.heightSlider.UpdateDisplay(HP_DEFAULTS.layout.height) end
  end
  if e.offsetSlider and e.offsetSlider.slider then 
    e.offsetSlider.slider:SetValue(HP_DEFAULTS.layout.offsetX)
    if e.offsetSlider.UpdateDisplay then e.offsetSlider.UpdateDisplay(HP_DEFAULTS.layout.offsetX) end
  end
  if e.offsetYSlider and e.offsetYSlider.slider then 
    e.offsetYSlider.slider:SetValue(HP_DEFAULTS.layout.offsetY)
    if e.offsetYSlider.UpdateDisplay then e.offsetYSlider.UpdateDisplay(HP_DEFAULTS.layout.offsetY) end
  end
  if e.healthEnabledCheckbox then e.healthEnabledCheckbox:SetChecked(true) end
  if e.powerEnabledCheckbox then e.powerEnabledCheckbox:SetChecked(true) end
  if e.combatAlphaSlider and e.combatAlphaSlider.slider then 
    e.combatAlphaSlider.slider:SetValue(HP_DEFAULTS.alpha.combat)
    if e.combatAlphaSlider.UpdateDisplay then e.combatAlphaSlider.UpdateDisplay(HP_DEFAULTS.alpha.combat) end
  end
  if e.nonFullAlphaSlider and e.nonFullAlphaSlider.slider then 
    e.nonFullAlphaSlider.slider:SetValue(HP_DEFAULTS.alpha.nonFull)
    if e.nonFullAlphaSlider.UpdateDisplay then e.nonFullAlphaSlider.UpdateDisplay(HP_DEFAULTS.alpha.nonFull) end
  end
  if e.fullIdleAlphaSlider and e.fullIdleAlphaSlider.slider then 
    e.fullIdleAlphaSlider.slider:SetValue(HP_DEFAULTS.alpha.fullIdle)
    if e.fullIdleAlphaSlider.UpdateDisplay then e.fullIdleAlphaSlider.UpdateDisplay(HP_DEFAULTS.alpha.fullIdle) end
  end
  
  if WiseHudHealth_SetEnabled then WiseHudHealth_SetEnabled(true) end
  if WiseHudPower_SetEnabled then WiseHudPower_SetEnabled(true) end
  if WiseHudHealth_ApplyLayout then WiseHudHealth_ApplyLayout() end
  if WiseHudPower_ApplyLayout then WiseHudPower_ApplyLayout() end
  if WiseHudHealth_ApplyAlpha then WiseHudHealth_ApplyAlpha() end
  if WiseHudPower_ApplyAlpha then WiseHudPower_ApplyAlpha() end
  if self.UpdateHealthColorSwatch then self.UpdateHealthColorSwatch() end
  if self.UpdatePowerColorSwatch then self.UpdatePowerColorSwatch() end
end

-- Export class
WiseHudOptionsHealthPowerTab = HealthPowerTab
