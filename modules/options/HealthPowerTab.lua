local ADDON_NAME = ...

-- Health/Power Tab Class

local OptionsTab = WiseHudOptionsBaseTab
local Helpers = WiseHudOptionsHelpers

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
  e.healthEnabledCheckbox:SetPoint("TOPLEFT", e.enableSection, "TOPLEFT", 12, -12)
  
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
  e.layoutSection = Helpers.CreateSectionFrame(self.parent, "WiseHudHealthPowerLayoutSection", "HUD Arc Size and Distance", 500, 280)
  
  -- Position title above section
  if e.layoutSection.titleText then
    e.layoutSection.titleText:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 20, yOffset)
    yOffset = yOffset - 28 -- Space for title
  end
  
  e.layoutSection:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 20, yOffset)
  
  -- Width
  e.widthSlider = Helpers.CreateSlider(e.layoutSection, "WiseHudBarWidthSlider", "Width", 120, 400, 5, layout.width or 260, nil, function(self, value)
    local cfg = Helpers.ensureLayoutTable()
    cfg.width = value
    if WiseHudHealth_ApplyLayout then WiseHudHealth_ApplyLayout() end
    if WiseHudPower_ApplyLayout then WiseHudPower_ApplyLayout() end
  end)
  e.widthSlider:SetPoint("TOPLEFT", e.layoutSection, "TOPLEFT", 12, -12)
  
  -- Height
  e.heightSlider = Helpers.CreateSlider(e.layoutSection, "WiseHudBarHeightSlider", "Height", 330, 500, 5, layout.height or 415, nil, function(self, value)
    local cfg = Helpers.ensureLayoutTable()
    cfg.height = value
    if WiseHudHealth_ApplyLayout then WiseHudHealth_ApplyLayout() end
    if WiseHudPower_ApplyLayout then WiseHudPower_ApplyLayout() end
  end)
  e.heightSlider:SetPoint("TOPLEFT", e.widthSlider, "BOTTOMLEFT", 0, -20)
  
  -- Distance X
  e.offsetSlider = Helpers.CreateSlider(e.layoutSection, "WiseHudBarOffsetSlider", "Distance X", 170, 200, 5, layout.offset or 200, nil, function(self, value)
    local cfg = Helpers.ensureLayoutTable()
    cfg.offset = value
    if WiseHudHealth_ApplyLayout then WiseHudHealth_ApplyLayout() end
    if WiseHudPower_ApplyLayout then WiseHudPower_ApplyLayout() end
  end)
  e.offsetSlider:SetPoint("TOPLEFT", e.heightSlider, "BOTTOMLEFT", 0, -20)
  
  -- Distance Y
  e.offsetYSlider = Helpers.CreateSlider(e.layoutSection, "WiseHudBarOffsetYSlider", "Distance Y", -20, 200, 5, layout.offsetY or 100, nil, function(self, value)
    local cfg = Helpers.ensureLayoutTable()
    cfg.offsetY = value
    if WiseHudHealth_ApplyLayout then WiseHudHealth_ApplyLayout() end
    if WiseHudPower_ApplyLayout then WiseHudPower_ApplyLayout() end
  end)
  e.offsetYSlider:SetPoint("TOPLEFT", e.offsetSlider, "BOTTOMLEFT", 0, -20)
  
  -- Calculate yOffset for next section: layout section height (280) + title space (28) + padding
  yOffset = yOffset - 280 - 20 -- Section height + extra padding
  
  -- Alpha settings
  local alphaCfg = Helpers.ensureAlphaTable()
  e.alphaSection = Helpers.CreateSectionFrame(self.parent, "WiseHudHealthPowerAlphaSection", "Alpha Settings", 500, 200)
  
  -- Position title above section
  if e.alphaSection.titleText then
    e.alphaSection.titleText:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 20, yOffset)
    yOffset = yOffset - 28 -- Space for title
  end
  
  e.alphaSection:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 20, yOffset)
  
  -- Combat Alpha
  e.combatAlphaSlider = Helpers.CreateSlider(e.alphaSection, "WiseHudCombatAlphaSlider", "Combat Alpha", 0, 100, 5, alphaCfg.combatAlpha or 40, "%d%%", function(self, value)
    local cfg = Helpers.ensureAlphaTable()
    cfg.combatAlpha = value
    if WiseHudHealth_ApplyAlpha then WiseHudHealth_ApplyAlpha() end
    if WiseHudPower_ApplyAlpha then WiseHudPower_ApplyAlpha() end
  end)
  e.combatAlphaSlider:SetPoint("TOPLEFT", e.alphaSection, "TOPLEFT", 12, -12)
  
  -- Not full, no combat
  e.nonFullAlphaSlider = Helpers.CreateSlider(e.alphaSection, "WiseHudNonFullAlphaSlider", "Not Full (ooc)", 0, 100, 5, alphaCfg.nonFullAlpha or 20, "%d%%", function(self, value)
    local cfg = Helpers.ensureAlphaTable()
    cfg.nonFullAlpha = value
    if WiseHudHealth_ApplyAlpha then WiseHudHealth_ApplyAlpha() end
    if WiseHudPower_ApplyAlpha then WiseHudPower_ApplyAlpha() end
  end)
  e.nonFullAlphaSlider:SetPoint("TOPLEFT", e.combatAlphaSlider, "BOTTOMLEFT", 0, -20)
  
  -- Full, no combat
  e.fullIdleAlphaSlider = Helpers.CreateSlider(e.alphaSection, "WiseHudFullIdleAlphaSlider", "Full (ooc)", 0, 100, 5, alphaCfg.fullIdleAlpha or 0, "%d%%", function(self, value)
    local cfg = Helpers.ensureAlphaTable()
    cfg.fullIdleAlpha = value
    if WiseHudHealth_ApplyAlpha then WiseHudHealth_ApplyAlpha() end
    if WiseHudPower_ApplyAlpha then WiseHudPower_ApplyAlpha() end
  end)
  e.fullIdleAlphaSlider:SetPoint("TOPLEFT", e.nonFullAlphaSlider, "BOTTOMLEFT", 0, -20)
  
  yOffset = yOffset - 220
  
  -- Color Section
  e.colorSection = Helpers.CreateSectionFrame(self.parent, "WiseHudHealthPowerColorSection", "Color Settings", 500, 160)
  
  -- Position title above section
  if e.colorSection.titleText then
    e.colorSection.titleText:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 20, yOffset)
    yOffset = yOffset - 28 -- Space for title
  end
  
  e.colorSection:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 20, yOffset)
  
  -- Health Bar Color
  local healthColorLabel = e.colorSection:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  healthColorLabel:SetPoint("TOPLEFT", e.colorSection, "TOPLEFT", 12, -12)
  healthColorLabel:SetText("Health Bar Color:")
  healthColorLabel:SetTextColor(1, 1, 1)
  
  self.UpdateHealthColorSwatch = function()
    if not e.healthColorButton or not e.healthColorButton.texture then return end
    local cfg = Helpers.ensureLayoutTable()
    local r = (cfg.healthR or 37) / 255
    local g = (cfg.healthG or 164) / 255
    local b = (cfg.healthB or 30) / 255
    e.healthColorButton.texture:SetVertexColor(r, g, b)
    e.healthColorButton.texture:Show()
  end
  
  e.healthColorButton = Helpers.CreateColorPicker(
    e.colorSection,
    "WiseHudHealthColorButton",
    "Health Bar Color",
    function()
      local cfg = Helpers.ensureLayoutTable()
      return (cfg.healthR or 37) / 255, (cfg.healthG or 164) / 255, (cfg.healthB or 30) / 255, 1
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
    local r = (cfg.powerR or 62) / 255
    local g = (cfg.powerG or 54) / 255
    local b = (cfg.powerB or 152) / 255
    e.powerColorButton.texture:SetVertexColor(r, g, b)
    e.powerColorButton.texture:Show()
  end
  
  e.powerColorButton = Helpers.CreateColorPicker(
    e.colorSection,
    "WiseHudPowerColorButton",
    "Power Bar Color",
    function()
      local cfg = Helpers.ensureLayoutTable()
      return (cfg.powerR or 62) / 255, (cfg.powerG or 54) / 255, (cfg.powerB or 152) / 255, 1
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
  yOffset = yOffset - 160 - 40 -- Section height + padding
  
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
  if e.widthSlider and e.widthSlider.slider then e.widthSlider.slider:SetValue(260) end
  if e.heightSlider and e.heightSlider.slider then e.heightSlider.slider:SetValue(415) end
  if e.offsetSlider and e.offsetSlider.slider then e.offsetSlider.slider:SetValue(200) end
  if e.offsetYSlider and e.offsetYSlider.slider then e.offsetYSlider.slider:SetValue(100) end
  if e.healthEnabledCheckbox then e.healthEnabledCheckbox:SetChecked(true) end
  if e.powerEnabledCheckbox then e.powerEnabledCheckbox:SetChecked(true) end
  if e.combatAlphaSlider and e.combatAlphaSlider.slider then e.combatAlphaSlider.slider:SetValue(40) end
  if e.nonFullAlphaSlider and e.nonFullAlphaSlider.slider then e.nonFullAlphaSlider.slider:SetValue(20) end
  if e.fullIdleAlphaSlider and e.fullIdleAlphaSlider.slider then e.fullIdleAlphaSlider.slider:SetValue(0) end
  
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
