local ADDON_NAME = ...

-- Orb Resource Tab Class

local OptionsTab = WiseHudOptionsBaseTab
local Helpers = WiseHudOptionsHelpers

local ORB_DEFAULTS = WiseHudConfig.GetOrbsDefaults()

local OrbResourceTab = setmetatable({}, {__index = OptionsTab})
OrbResourceTab.__index = OrbResourceTab

function OrbResourceTab:new(parent, panel)
  local instance = OptionsTab.new(self, parent, panel)
  return instance
end

function OrbResourceTab:Create()
  local comboCfg = Helpers.ensureComboTable()
  local tab = self
  -- If no preset is stored yet, default to the "Void Orb" preset
  -- (key = "void_orb" in the central config presets).
  -- Older profiles may still have "default" stored; those are treated
  -- as "void_orb" further below when resolving the active key.
  comboCfg.modelPreset = comboCfg.modelPreset or "void_orb"
  local e = self.elements
  
  local yOffset = -20
  
  -- Enable/Disable Section
  e.enableSection = Helpers.CreateSectionFrame(self.parent, "WiseHudOrbsEnableSection", nil, 500, 80)
  e.enableSection:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 20, yOffset)
  
  -- Enable/Disable checkbox
  e.enabledCheckbox = Helpers.CreateCheckbox(e.enableSection, "WiseHudOrbsEnabledCheckbox", "Enable Orbs", comboCfg.enabled, function(self, checked)
    local cfg = Helpers.ensureComboTable()
    cfg.enabled = checked
    if WiseHudOrbs_SetEnabled then
      WiseHudOrbs_SetEnabled(checked)
    end
  end)
  e.enabledCheckbox:SetPoint("TOPLEFT", e.enableSection, "TOPLEFT", 12, -12)

  yOffset = yOffset - 100
  
  -- Orb Position Section (now directly below enable section)
  e.positionSection = Helpers.CreateSectionFrame(self.parent, "WiseHudOrbsPositionSection", "Orb Position", 500, 200)
  
  -- Position title above section
  if e.positionSection.titleText then
    e.positionSection.titleText:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 20, yOffset)
    yOffset = yOffset - 28 -- Space for title
  end
  
  e.positionSection:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 20, yOffset)
  
  -- Combo Points X Position
  e.xSlider = Helpers.CreateSlider(e.positionSection, "WiseHudOrbsXSlider", "X Position", -400, 400, 5, comboCfg.x or ORB_DEFAULTS.x, nil, function(self, value)
    local cfg = Helpers.ensureComboTable()
    cfg.x = value
    if WiseHudOrbs_ApplyLayout then WiseHudOrbs_ApplyLayout() end
  end)
  e.xSlider:SetPoint("TOPLEFT", e.positionSection, "TOPLEFT", 12, -12)
  
  -- Combo Points Y Position
  e.ySlider = Helpers.CreateSlider(e.positionSection, "WiseHudOrbsYSlider", "Y Position", -200, 80, 5, comboCfg.y or ORB_DEFAULTS.y, nil, function(self, value)
    local cfg = Helpers.ensureComboTable()
    cfg.y = value
    if WiseHudOrbs_ApplyLayout then WiseHudOrbs_ApplyLayout() end
  end)
  e.ySlider:SetPoint("TOPLEFT", e.xSlider, "BOTTOMLEFT", 0, -20)
  
  -- Combo Points Radius
  e.radiusSlider = Helpers.CreateSlider(e.positionSection, "WiseHudOrbsRadiusSlider", "Radius", 20, 80, 5, comboCfg.radius or ORB_DEFAULTS.radius, nil, function(self, value)
    local cfg = Helpers.ensureComboTable()
    cfg.radius = value
    if WiseHudOrbs_ApplyLayout then WiseHudOrbs_ApplyLayout() end
  end)
  e.radiusSlider:SetPoint("TOPLEFT", e.ySlider, "BOTTOMLEFT", 0, -20)
  
  -- Calculate yOffset for next section: position section height (200) + title space (28) + padding
  yOffset = yOffset - 200 - 20 -- Section height + extra padding
  
  -- Model Settings Section (with presets + optional custom settings) – now below position settings
  e.modelSection = Helpers.CreateSectionFrame(self.parent, "WiseHudOrbsModelSection", "Model Settings", 500, 140)
  
  -- Position title above section
  if e.modelSection.titleText then
    e.modelSection.titleText:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 20, yOffset)
    yOffset = yOffset - 28 -- Space for title
  end
  
  e.modelSection:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 20, yOffset)
  
  local function GetDefaultModelId()
    if WiseHudOrbs_GetDefaultModelId then
      return WiseHudOrbs_GetDefaultModelId()
    end
    return ORB_DEFAULTS.modelId
  end
  
  -- Preset dropdown label
  local modelLabel = e.modelSection:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  modelLabel:SetPoint("TOPLEFT", e.modelSection, "TOPLEFT", 12, -12)
  modelLabel:SetText("Model Preset:")
  modelLabel:SetTextColor(1, 1, 1)

  -- Helper to get presets from central config
  local orbPresets = {}
  if WiseHudConfig and WiseHudConfig.GetOrbPresets then
    local cfgPresets = WiseHudConfig.GetOrbPresets() or {}
    for i, p in ipairs(cfgPresets) do
      orbPresets[i] = p
    end
  end

  local PRESET_CUSTOM_KEY = "custom"

  local function GetCurrentPresetKey()
    local cfg = Helpers.ensureComboTable()
    local key = cfg.modelPreset
    -- Treat missing/empty or legacy "default" as "void_orb",
    -- so the Void Orb preset is shown as the initial selection.
    if not key or key == "" or key == "default" then
      return "void_orb"
    end
    return key
  end

  -- Preset dropdown
  local presetDropdown = CreateFrame("Frame", "WiseHudOrbsPresetDropdown", e.modelSection, "UIDropDownMenuTemplate")
  presetDropdown:SetPoint("TOPLEFT", modelLabel, "BOTTOMLEFT", -16, -4)
  presetDropdown:SetWidth(180)
  e.presetDropdown = presetDropdown

  -- Forward declaration for UI updater
  local function UpdatePresetUI(selectedKey) end

  -- Utility to update dropdown selection + label
  self.SetModelPresetSelection = function(_, presetKey)
    presetKey = presetKey or GetCurrentPresetKey()
    local displayName = "Custom"
    if presetKey ~= PRESET_CUSTOM_KEY then
      for _, preset in ipairs(orbPresets) do
        if preset.key == presetKey then
          displayName = preset.name or preset.key
          break
        end
      end
    end

    if UIDropDownMenu_SetSelectedValue then
      UIDropDownMenu_SetSelectedValue(presetDropdown, presetKey)
    end
    if UIDropDownMenu_SetText then
      UIDropDownMenu_SetText(presetDropdown, displayName)
    end

    UpdatePresetUI(presetKey)
  end

  -- Initialize dropdown entries
  if UIDropDownMenu_Initialize then
    UIDropDownMenu_Initialize(presetDropdown, function(dropdown, level)
      level = level or 1
      if level ~= 1 then return end

      local currentKey = GetCurrentPresetKey()

      -- Add presets from config
      for _, preset in ipairs(orbPresets) do
        local info = UIDropDownMenu_CreateInfo and UIDropDownMenu_CreateInfo() or {}
        info.text = preset.name or preset.key
        info.value = preset.key
        info.checked = (preset.key == currentKey)
        info.func = function()
          local cfg = Helpers.ensureComboTable()
          cfg.modelPreset = preset.key
          -- When switching away from custom, clear custom overrides so preset cameras apply
          cfg.modelId = nil
          cfg.cameraX = nil
          cfg.cameraY = nil
          cfg.cameraZ = nil

          if tab.SetModelPresetSelection then
            tab:SetModelPresetSelection(preset.key)
          end

          -- Apply new model + layout
          if WiseHudOrbs_ApplyModelPathToExistingOrbs then
            WiseHudOrbs_ApplyModelPathToExistingOrbs()
          end
          if WiseHudOrbs_OnPowerUpdate then
            WiseHudOrbs_OnPowerUpdate("player")
          end
        end
        UIDropDownMenu_AddButton(info, level)
      end

      -- Custom entry
      local info = UIDropDownMenu_CreateInfo and UIDropDownMenu_CreateInfo() or {}
      info.text = "Custom"
      info.value = PRESET_CUSTOM_KEY
      info.checked = (currentKey == PRESET_CUSTOM_KEY)
      info.func = function()
        local cfg = Helpers.ensureComboTable()
        cfg.modelPreset = PRESET_CUSTOM_KEY
        if tab.SetModelPresetSelection then
          tab:SetModelPresetSelection(PRESET_CUSTOM_KEY)
        end
      end
      UIDropDownMenu_AddButton(info, level)
    end)
  end

  -- Custom model ID label (only visible for "Custom" preset)
  local customModelLabel = e.modelSection:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  customModelLabel:SetPoint("TOPLEFT", e.modelSection, "TOPLEFT", 12, -64)
  customModelLabel:SetText("Custom FileDataID / Model Path:")
  customModelLabel:SetTextColor(1, 1, 1)
  e.customModelLabel = customModelLabel

  e.modelIdEditBox = CreateFrame("EditBox", "WiseHudOrbsModelIdEditBox", e.modelSection, "InputBoxTemplate")
  e.modelIdEditBox:SetPoint("TOPLEFT", customModelLabel, "BOTTOMLEFT", 0, -8)
  e.modelIdEditBox:SetSize(150, 20)
  e.modelIdEditBox:SetAutoFocus(false)
  
  local function GetCurrentModelIdForDisplay()
    local cfg = Helpers.ensureComboTable()
    if cfg.modelId then
      return tostring(cfg.modelId)
    end
    return tostring(GetDefaultModelId())
  end
  
  self.SetModelIdText = function()
    if not e.modelIdEditBox then return end
    local text = GetCurrentModelIdForDisplay()
    e.modelIdEditBox:SetText(text)
    e.modelIdEditBox:SetCursorPosition(0)
  end
  
  self.SetModelIdText()
  
  local function UpdateModelFromInput()
    local text = e.modelIdEditBox:GetText() or ""
    text = strtrim(text)
    local cfg = Helpers.ensureComboTable()

    -- Any manual change to model ID implicitly switches to custom preset
    cfg.modelPreset = PRESET_CUSTOM_KEY
    if self.SetModelPresetSelection then
      self:SetModelPresetSelection(PRESET_CUSTOM_KEY)
    end
    
    if text == "" then
      cfg.modelId = nil
    else
      local asNumber = tonumber(text)
      if asNumber then
        cfg.modelId = asNumber
      else
        cfg.modelId = text
      end
    end
    
    if WiseHudOrbs_ApplyModelPathToExistingOrbs then
      WiseHudOrbs_ApplyModelPathToExistingOrbs()
    end
    self.SetModelIdText()
  end
  
  e.modelIdEditBox:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
    UpdateModelFromInput()
  end)
  
  local tabInstance = self
  e.modelIdEditBox:SetScript("OnEscapePressed", function(editBox)
    editBox:ClearFocus()
    tabInstance.SetModelIdText()
  end)
  
  e.modelIdEditBox:SetScript("OnEditFocusLost", function(self)
    UpdateModelFromInput()
  end)
  
  -- Apply Model Button (only relevant for custom preset)
  local testModelButton = CreateFrame("Button", "WiseHudOrbsTestModelButton", e.modelSection, "UIPanelButtonTemplate")
  testModelButton:SetSize(120, 28)
  testModelButton:SetPoint("LEFT", e.modelIdEditBox, "RIGHT", 12, 0)
  testModelButton:SetText("Apply Model")
  e.testModelButton = testModelButton
  
  testModelButton:SetScript("OnClick", function(self)
    UpdateModelFromInput()
    local modelId = e.modelIdEditBox:GetText() or ""
    modelId = strtrim(modelId)
    
    if modelId == "" then
      print("|cFF00FF00WiseHud:|r Model ID is empty. Using default model.")
      return
    end
    
    local success, attempted = false, false
    if WiseHudOrbs_ApplyModelPathToExistingOrbs then
      success, attempted = WiseHudOrbs_ApplyModelPathToExistingOrbs()
    end
    
    -- If no orbs exist, test the model with a temporary orb
    if not attempted then
      local cfg = Helpers.ensureComboTable()
      local modelToTest = cfg.modelId
      if modelToTest and WiseHudOrbs_TestModelPath then
        success = WiseHudOrbs_TestModelPath(modelToTest)
        attempted = true
      end
    end
    
    -- Update orbs to ensure they're created and updated
    if WiseHudOrbs_OnPowerUpdate then
      WiseHudOrbs_OnPowerUpdate("player")
    end
    
    -- Give feedback to user
    if attempted then
      if success then
        print("|cFF00FF00WiseHud:|r Model ID " .. modelId .. " applied successfully.")
        if WiseHudOrbs_UpdateCameraPosition then
          WiseHudOrbs_UpdateCameraPosition()
        end
      else
        print("|cFFFF0000WiseHud:|r Model ID " .. modelId .. " not found. Please check the ID and try again.")
      end
    else
      -- Model ID is saved but couldn't test it
      print("|cFFFFFF00WiseHud:|r Model ID " .. modelId .. " saved. It will be applied when orbs are created.")
    end
  end)
  
  -- UI updater for preset-dependent elements
  UpdatePresetUI = function(selectedKey)
    local isCustom = (selectedKey == PRESET_CUSTOM_KEY)

    if e.customModelLabel then
      e.customModelLabel:SetShown(isCustom)
    end
    if e.modelIdEditBox then
      e.modelIdEditBox:SetShown(isCustom)
      if isCustom then
        e.modelIdEditBox:Enable()
      else
        e.modelIdEditBox:Disable()
      end
    end
    if e.testModelButton then
      e.testModelButton:SetShown(isCustom)
    end
    if e.cameraSection then
      e.cameraSection:SetShown(isCustom)
      if e.cameraSection.titleText then
        e.cameraSection.titleText:SetShown(isCustom)
      end
    end
    -- Move reset button closer to the last visible section
    if e.resetButton then
      e.resetButton:ClearAllPoints()
      if isCustom and e.cameraSection then
        -- Anchor below camera section when custom preset is active
        e.resetButton:SetPoint("TOPLEFT", e.cameraSection, "BOTTOMLEFT", 0, -20)
      else
        -- Anchor directly below model section for non-custom presets
        e.resetButton:SetPoint("TOPLEFT", e.modelSection, "BOTTOMLEFT", 0, -20)
      end
    end
  end

  -- Initialize preset dropdown selection + dependent UI
  if self.SetModelPresetSelection then
    self:SetModelPresetSelection(GetCurrentPresetKey())
  end

  -- Calculate yOffset for next section: model section height (140) + title space (28) + padding
  yOffset = yOffset - 140 - 20 -- Section height + extra padding
  
  -- Camera Position Section (below presets)
  e.cameraSection = Helpers.CreateSectionFrame(self.parent, "WiseHudOrbsCameraSection", "Camera Position", 500, 200)
  
  -- Position title above section
  if e.cameraSection.titleText then
    e.cameraSection.titleText:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 20, yOffset)
    yOffset = yOffset - 28 -- Space for title
  end
  
  e.cameraSection:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 20, yOffset)
  
  -- Camera X Position
  e.cameraXSlider = Helpers.CreateSlider(e.cameraSection, "WiseHudOrbsCameraXSlider", "Camera X", -3.0, 0.0, 0.1, comboCfg.cameraX or ORB_DEFAULTS.cameraX, "%.1f", function(self, value)
    local cfg = Helpers.ensureComboTable()
    cfg.cameraX = value
    if WiseHudOrbs_UpdateCameraOnly then
      WiseHudOrbs_UpdateCameraOnly()
    elseif WiseHudOrbs_UpdateCameraPosition then
      WiseHudOrbs_UpdateCameraPosition()
    end
  end)
  e.cameraXSlider:SetPoint("TOPLEFT", e.cameraSection, "TOPLEFT", 12, -12)
  
  -- Camera Y Position
  e.cameraYSlider = Helpers.CreateSlider(e.cameraSection, "WiseHudOrbsCameraYSlider", "Camera Y", -2.0, 2.0, 0.1, comboCfg.cameraY or ORB_DEFAULTS.cameraY, "%.1f", function(self, value)
    local cfg = Helpers.ensureComboTable()
    cfg.cameraY = value
    if WiseHudOrbs_UpdateCameraOnly then
      WiseHudOrbs_UpdateCameraOnly()
    elseif WiseHudOrbs_UpdateCameraPosition then
      WiseHudOrbs_UpdateCameraPosition()
    end
  end)
  e.cameraYSlider:SetPoint("TOPLEFT", e.cameraXSlider, "BOTTOMLEFT", 0, -20)
  
  -- Camera Z Position
  e.cameraZSlider = Helpers.CreateSlider(e.cameraSection, "WiseHudOrbsCameraZSlider", "Camera Z", -2.0, 2.0, 0.1, comboCfg.cameraZ or ORB_DEFAULTS.cameraZ, "%.1f", function(self, value)
    local cfg = Helpers.ensureComboTable()
    cfg.cameraZ = value
    if WiseHudOrbs_UpdateCameraOnly then
      WiseHudOrbs_UpdateCameraOnly()
    elseif WiseHudOrbs_UpdateCameraPosition then
      WiseHudOrbs_UpdateCameraPosition()
    end
  end)
  e.cameraZSlider:SetPoint("TOPLEFT", e.cameraYSlider, "BOTTOMLEFT", 0, -20)
  
  self.GetDefaultModelId = GetDefaultModelId

  -- Calculate yOffset for reset button: camera section bottom + padding
  yOffset = yOffset - 200 - 40 -- Section height + padding
  
  -- Reset Button (positioned at the end of content)
  e.resetButton = Helpers.CreateResetButton(
    self.parent,
    "WiseHudOrbsResetButton",
    "WISEHUD_RESET_ORBS",
    "Are you sure you want to reset all Orb Resource settings to their default values?",
    self,
    "TOPLEFT",
    self.parent,
    "TOPLEFT",
    20,
    yOffset
  )

  -- Ensure camera section visibility & reset button position match current preset
  if UpdatePresetUI then
    UpdatePresetUI(GetCurrentPresetKey())
  end
end

function OrbResourceTab:Refresh()
  if self.SetModelIdText then
    self.SetModelIdText()
  end
  
  -- Reload values from config and update sliders
  local comboCfg = Helpers.ensureComboTable()
  local e = self.elements

  -- Update preset dropdown + dependent UI
  if self.SetModelPresetSelection then
    -- Map legacy "default" and empty values to "void_orb" for display
    local function GetCurrentPresetKey()
      local cfg = Helpers.ensureComboTable()
      local key = cfg.modelPreset
      if not key or key == "" or key == "default" then
        return "void_orb"
      end
      return key
    end
    self:SetModelPresetSelection(GetCurrentPresetKey())
  end
  
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
  RefreshSlider(e.xSlider, comboCfg.x, ORB_DEFAULTS.x)
  RefreshSlider(e.ySlider, comboCfg.y, ORB_DEFAULTS.y)
  RefreshSlider(e.radiusSlider, comboCfg.radius, ORB_DEFAULTS.radius)
  RefreshSlider(e.cameraXSlider, comboCfg.cameraX, ORB_DEFAULTS.cameraX)
  RefreshSlider(e.cameraYSlider, comboCfg.cameraY, ORB_DEFAULTS.cameraY)
  RefreshSlider(e.cameraZSlider, comboCfg.cameraZ, ORB_DEFAULTS.cameraZ)
  
  -- Update checkboxes
  if e.enabledCheckbox then
    e.enabledCheckbox:SetChecked(comboCfg.enabled ~= false)
  end
end

function OrbResourceTab:Reset()
  local comboCfg = Helpers.ensureComboTable()
  comboCfg.x = nil
  comboCfg.y = nil
  comboCfg.radius = nil
  comboCfg.cameraX = nil
  comboCfg.cameraY = nil
  comboCfg.cameraZ = nil
  comboCfg.enabled = nil
  comboCfg.testMode = nil
  comboCfg.modelId = nil
  comboCfg.modelPreset = nil
  
  local e = self.elements
  if e.xSlider and e.xSlider.slider then 
    e.xSlider.slider:SetValue(ORB_DEFAULTS.x)
    if e.xSlider.UpdateDisplay then e.xSlider.UpdateDisplay(ORB_DEFAULTS.x) end
  end
  if e.ySlider and e.ySlider.slider then 
    e.ySlider.slider:SetValue(ORB_DEFAULTS.y)
    if e.ySlider.UpdateDisplay then e.ySlider.UpdateDisplay(ORB_DEFAULTS.y) end
  end
  if e.radiusSlider and e.radiusSlider.slider then 
    e.radiusSlider.slider:SetValue(ORB_DEFAULTS.radius)
    if e.radiusSlider.UpdateDisplay then e.radiusSlider.UpdateDisplay(ORB_DEFAULTS.radius) end
  end
  if e.cameraXSlider and e.cameraXSlider.slider then 
    e.cameraXSlider.slider:SetValue(ORB_DEFAULTS.cameraX)
    if e.cameraXSlider.UpdateDisplay then e.cameraXSlider.UpdateDisplay(ORB_DEFAULTS.cameraX) end
  end
  if e.cameraYSlider and e.cameraYSlider.slider then 
    e.cameraYSlider.slider:SetValue(ORB_DEFAULTS.cameraY)
    if e.cameraYSlider.UpdateDisplay then e.cameraYSlider.UpdateDisplay(ORB_DEFAULTS.cameraY) end
  end
  if e.cameraZSlider and e.cameraZSlider.slider then 
    e.cameraZSlider.slider:SetValue(ORB_DEFAULTS.cameraZ)
    if e.cameraZSlider.UpdateDisplay then e.cameraZSlider.UpdateDisplay(ORB_DEFAULTS.cameraZ) end
  end
  if e.enabledCheckbox then e.enabledCheckbox:SetChecked(true) end
  if e.modelIdEditBox and self.GetDefaultModelId then
    e.modelIdEditBox:SetText(tostring(self.GetDefaultModelId()))
  end
  if self.SetModelPresetSelection then
    -- When resetting, also show the Void Orb preset as the default selection
    self:SetModelPresetSelection("void_orb")
  end
  
  if WiseHudOrbs_SetEnabled then WiseHudOrbs_SetEnabled(true) end
  if WiseHudOrbs_ApplyLayout then WiseHudOrbs_ApplyLayout() end
end

-- Export class
WiseHudOptionsOrbResourceTab = OrbResourceTab
