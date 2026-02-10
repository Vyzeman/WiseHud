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
  -- Match the enable container height/layout with the Cast Bar tab (height = 60)
  e.enableSection = Helpers.CreateSectionFrame(self.parent, "WiseHudOrbsEnableSection", nil, 500, 50)
  e.enableSection:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 20, yOffset)
  
  -- Enable/Disable checkbox
  e.enabledCheckbox = Helpers.CreateCheckbox(e.enableSection, "WiseHudOrbsEnabledCheckbox", "Enable Orbs", comboCfg.enabled, function(self, checked)
    local cfg = Helpers.ensureComboTable()
    cfg.enabled = checked
    if WiseHudOrbs_SetEnabled then
      WiseHudOrbs_SetEnabled(checked)
    end
  end)
  -- Use standard section padding for inner content
  e.enabledCheckbox:SetPoint("TOPLEFT", e.enableSection, "TOPLEFT", Helpers.SECTION_PADDING_LEFT, -Helpers.SECTION_PADDING_TOP)
  
  -- Spacing below enable section (section height 50 + etwas weniger Padding)
  yOffset = yOffset - 70
  
  -- Orb Position Section (now directly below enable section)
  -- Height slightly oversized so all controls (Layout, X/Y, Radius, Size) sauber
  -- innerhalb des Containers bleiben, ohne gequetscht zu wirken.
  e.positionSection = Helpers.CreateSectionFrame(self.parent, "WiseHudOrbsPositionSection", "Position Settings", 500, 350)
  yOffset = Helpers.AnchorSectionWithTitle(self.parent, e.positionSection, yOffset, {
    contentHeight = 340,
    spacingBelow = 20,
  })
  
  -- Layout type dropdown (circular / horizontal / vertical) – placed at top of section
  local function GetCurrentLayoutType()
    local cfg = Helpers.ensureComboTable()
    return cfg.layoutType or ORB_DEFAULTS.layoutType or "circle"
  end

  local layoutLabel = e.positionSection:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  layoutLabel:SetPoint("TOPLEFT", e.positionSection, "TOPLEFT", Helpers.SECTION_PADDING_LEFT, -Helpers.SECTION_PADDING_TOP)
  layoutLabel:SetText("Layout")
  layoutLabel:SetTextColor(1, 1, 1)

  local layoutDropdown = CreateFrame("Frame", "WiseHudOrbsLayoutDropdown", e.positionSection, "UIDropDownMenuTemplate")
  layoutDropdown:SetPoint("TOPLEFT", layoutLabel, "BOTTOMLEFT", -16, -4)
  layoutDropdown:SetWidth(160)
  e.layoutDropdown = layoutDropdown

  -- Combo Points X Position
  e.xSlider = Helpers.CreateSlider(e.positionSection, "WiseHudOrbsXSlider", "X Position", -400, 400, 5, comboCfg.x or ORB_DEFAULTS.x, nil, function(self, value)
    local cfg = Helpers.ensureComboTable()
    cfg.x = value
    if WiseHudOrbs_ApplyLayout then WiseHudOrbs_ApplyLayout() end
  end)
  e.xSlider:SetPoint("TOPLEFT", layoutDropdown, "BOTTOMLEFT", 16, -16)
  
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

  -- Orb Size
  e.sizeSlider = Helpers.CreateSlider(e.positionSection, "WiseHudOrbsSizeSlider", "Orb Size", 30, 100, 2, comboCfg.orbSize or ORB_DEFAULTS.orbSize, nil, function(self, value)
    local cfg = Helpers.ensureComboTable()
    cfg.orbSize = value
    if WiseHudOrbs_ApplyLayout then WiseHudOrbs_ApplyLayout() end
  end)
  e.sizeSlider:SetPoint("TOPLEFT", e.radiusSlider, "BOTTOMLEFT", 0, -20)

  self.SetLayoutSelection = function(_, layoutKey)
    layoutKey = layoutKey or GetCurrentLayoutType()
    local displayName = "Circular"
    if layoutKey == "horizontal" then
      displayName = "Horizontal"
    elseif layoutKey == "vertical" then
      displayName = "Vertical"
    end

    if UIDropDownMenu_SetSelectedValue then
      UIDropDownMenu_SetSelectedValue(layoutDropdown, layoutKey)
    end
    if UIDropDownMenu_SetText then
      UIDropDownMenu_SetText(layoutDropdown, displayName)
    end
  end

  if UIDropDownMenu_Initialize then
    UIDropDownMenu_Initialize(layoutDropdown, function(dropdown, level)
      level = level or 1
      if level ~= 1 then return end

      local currentLayout = GetCurrentLayoutType()
      local function AddLayoutOption(text, key)
        local info = UIDropDownMenu_CreateInfo and UIDropDownMenu_CreateInfo() or {}
        info.text = text
        info.value = key
        info.checked = (key == currentLayout)
        info.func = function()
          local cfg = Helpers.ensureComboTable()
          cfg.layoutType = key
          if tab.SetLayoutSelection then
            tab:SetLayoutSelection(key)
          end
          if WiseHudOrbs_ApplyLayout then
            WiseHudOrbs_ApplyLayout()
          end
        end
        UIDropDownMenu_AddButton(info, level)
      end

      AddLayoutOption("Circular", "circle")
      AddLayoutOption("Horizontal", "horizontal")
      AddLayoutOption("Vertical", "vertical")
    end)
  end
  
  -- Calculate yOffset for next section: position section height (280) + title space (28) + padding
  -- (already handled by AnchorSectionWithTitle above)

  -- Alpha settings for Orbs (independent of Health/Power),
  -- placed directly below the position controls.
  local alphaCfg = Helpers.ensureComboTable()
  -- Slightly increase height so all three alpha sliders have a bit more vertical space
  e.alphaSection = Helpers.CreateSectionFrame(self.parent, "WiseHudOrbsAlphaSection", "Alpha Settings", 500, 210)
  yOffset = Helpers.AnchorSectionWithTitle(self.parent, e.alphaSection, yOffset, {
    contentHeight = 210,
    spacingBelow = 20,
  })

  local defaultsAlpha = ORB_DEFAULTS.alpha or {}

  -- Combat Alpha (used while in combat)
  e.combatAlphaSlider = Helpers.CreateSlider(
    e.alphaSection,
    "WiseHudOrbsCombatAlphaSlider",
    "Combat Alpha",
    0,
    100,
    5,
    alphaCfg.orbCombatAlpha or defaultsAlpha.combat or 40,
    "%d%%",
    function(self, value)
      local cfg = Helpers.ensureComboTable()
      cfg.orbCombatAlpha = value
      if WiseHudOrbs_ApplyAlpha then
        WiseHudOrbs_ApplyAlpha()
      end
    end
  )
  e.combatAlphaSlider:SetPoint("TOPLEFT", e.alphaSection, "TOPLEFT", Helpers.SECTION_PADDING_LEFT, -Helpers.SECTION_PADDING_TOP)

  -- Out of combat (while recently changed)
  e.nonFullAlphaSlider = Helpers.CreateSlider(
    e.alphaSection,
    "WiseHudOrbsNonFullAlphaSlider",
    "Out of Combat Alpha",
    0,
    100,
    5,
    alphaCfg.orbNonFullAlpha or defaultsAlpha.nonFull or 20,
    "%d%%",
    function(self, value)
      local cfg = Helpers.ensureComboTable()
      cfg.orbNonFullAlpha = value
      if WiseHudOrbs_ApplyAlpha then
        WiseHudOrbs_ApplyAlpha()
      end
    end
  )
  e.nonFullAlphaSlider:SetPoint("TOPLEFT", e.combatAlphaSlider, "BOTTOMLEFT", 0, -20)

  -- Idle out of combat (no recent changes)
  e.fullIdleAlphaSlider = Helpers.CreateSlider(
    e.alphaSection,
    "WiseHudOrbsFullIdleAlphaSlider",
    "Idle Alpha",
    0,
    100,
    5,
    alphaCfg.orbFullIdleAlpha or defaultsAlpha.fullIdle or 0,
    "%d%%",
    function(self, value)
      local cfg = Helpers.ensureComboTable()
      cfg.orbFullIdleAlpha = value
      if WiseHudOrbs_ApplyAlpha then
        WiseHudOrbs_ApplyAlpha()
      end
    end
  )
  e.fullIdleAlphaSlider:SetPoint("TOPLEFT", e.nonFullAlphaSlider, "BOTTOMLEFT", 0, -20)

  -- Calculate yOffset for next section: alpha section height (210) + title space (28) + padding
  -- (already handled by AnchorSectionWithTitle above)
  
  -- Model Settings Section (with presets + optional custom settings) – now below position and alpha settings
  e.modelSection = Helpers.CreateSectionFrame(self.parent, "WiseHudOrbsModelSection", "Model Settings", 500, 120)
  yOffset = Helpers.AnchorSectionWithTitle(self.parent, e.modelSection, yOffset, {
    contentHeight = 120,
    spacingBelow = 20,
  })
  
  local function GetDefaultModelId()
    if WiseHudOrbs_GetDefaultModelId then
      return WiseHudOrbs_GetDefaultModelId()
    end
    return ORB_DEFAULTS.modelId
  end
  
  -- Preset dropdown label (in Model Settings section)
  local modelLabel = e.modelSection:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  modelLabel:SetPoint("TOPLEFT", e.modelSection, "TOPLEFT", Helpers.SECTION_PADDING_LEFT, -Helpers.SECTION_PADDING_TOP)
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
  -- Keep same vertical offset but use standard left padding
  customModelLabel:SetPoint("TOPLEFT", e.modelSection, "TOPLEFT", Helpers.SECTION_PADDING_LEFT, -64)
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
  -- Link-style button: text only, no visible frame
  testModelButton:SetSize(100, 20)
  testModelButton:SetPoint("LEFT", e.modelIdEditBox, "RIGHT", 12, 0)
  testModelButton:SetText("Apply Model")

  -- Hide panel art by making textures fully transparent
  do
    local flat = "Interface\\Buttons\\WHITE8x8"
    local n = testModelButton:GetNormalTexture()
    if n then
      n:SetTexture(flat)
      n:SetVertexColor(0, 0, 0, 0)
    end
    local p = testModelButton:GetPushedTexture()
    if p then
      p:SetTexture(flat)
      p:SetVertexColor(0, 0, 0, 0)
    end
    local h = testModelButton:GetHighlightTexture()
    if h then
      h:SetTexture(flat)
      h:SetVertexColor(0, 0, 0, 0)
    end
  end

  -- Small neutral text with hover color similar to section titles
  testModelButton:SetNormalFontObject("GameFontNormalSmall")
  testModelButton:SetHighlightFontObject("GameFontHighlightSmall")
  testModelButton:SetDisabledFontObject("GameFontDisableSmall")
  do
    local fs = testModelButton:GetFontString()
    local normalR, normalG, normalB = 0.8, 0.8, 0.8
    local hoverR, hoverG, hoverB = 1.0, 0.82, 0.0
    if fs then
      fs:ClearAllPoints()
      fs:SetPoint("CENTER", testModelButton, "CENTER", 0, 0)
      fs:SetTextColor(normalR, normalG, normalB, 1)
    end
    testModelButton:HookScript("OnEnter", function(self)
      local fontString = self:GetFontString()
      if fontString and self:IsEnabled() then
        fontString:SetTextColor(hoverR, hoverG, hoverB, 1)
      end
    end)
    testModelButton:HookScript("OnLeave", function(self)
      local fontString = self:GetFontString()
      if fontString and self:IsEnabled() then
        fontString:SetTextColor(normalR, normalG, normalB, 1)
      end
    end)
  end
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
  
  -- Calculate yOffset for next section: model section height (120) + title space (28) + padding
  -- (already handled by AnchorSectionWithTitle above)
  
  -- Camera Position Section (below presets)
  e.cameraSection = Helpers.CreateSectionFrame(self.parent, "WiseHudOrbsCameraSection", "Camera Position", 500, 210)
  yOffset = Helpers.AnchorSectionWithTitle(self.parent, e.cameraSection, yOffset, {
    contentHeight = 210,
    spacingBelow = 20,
  })
  
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
  e.cameraXSlider:SetPoint("TOPLEFT", e.cameraSection, "TOPLEFT", Helpers.SECTION_PADDING_LEFT, -Helpers.SECTION_PADDING_TOP)
  
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
  
  -- Calculate yOffset for reset button: camera section bottom + padding.
  -- Move the reset button 10px nach oben, damit er im sichtbaren Bereich bleibt.
  -- (already handled by AnchorSectionWithTitle above)
  
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
  
  -- Refresh all sliders with their config values
  Helpers.RefreshSliderFromConfig(e.xSlider, comboCfg.x, ORB_DEFAULTS.x)
  Helpers.RefreshSliderFromConfig(e.ySlider, comboCfg.y, ORB_DEFAULTS.y)
  Helpers.RefreshSliderFromConfig(e.radiusSlider, comboCfg.radius, ORB_DEFAULTS.radius)
  if e.sizeSlider then
    Helpers.RefreshSliderFromConfig(e.sizeSlider, comboCfg.orbSize, ORB_DEFAULTS.orbSize)
  end
  Helpers.RefreshSliderFromConfig(e.cameraXSlider, comboCfg.cameraX, ORB_DEFAULTS.cameraX)
  Helpers.RefreshSliderFromConfig(e.cameraYSlider, comboCfg.cameraY, ORB_DEFAULTS.cameraY)
  Helpers.RefreshSliderFromConfig(e.cameraZSlider, comboCfg.cameraZ, ORB_DEFAULTS.cameraZ)

  local defaultsAlpha = ORB_DEFAULTS.alpha or {}
  if e.combatAlphaSlider then
    Helpers.RefreshSliderFromConfig(e.combatAlphaSlider, comboCfg.orbCombatAlpha, defaultsAlpha.combat or 40)
  end
  if e.nonFullAlphaSlider then
    Helpers.RefreshSliderFromConfig(e.nonFullAlphaSlider, comboCfg.orbNonFullAlpha, defaultsAlpha.nonFull or 20)
  end
  if e.fullIdleAlphaSlider then
    Helpers.RefreshSliderFromConfig(e.fullIdleAlphaSlider, comboCfg.orbFullIdleAlpha, defaultsAlpha.fullIdle or 0)
  end

  -- Update layout dropdown
  if self.SetLayoutSelection and e.layoutDropdown then
    local layoutKey = comboCfg.layoutType or ORB_DEFAULTS.layoutType or "circle"
    self:SetLayoutSelection(layoutKey)
  end
  
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
  comboCfg.orbSize = nil
  comboCfg.cameraX = nil
  comboCfg.cameraY = nil
  comboCfg.cameraZ = nil
  comboCfg.enabled = nil
  comboCfg.testMode = nil
  comboCfg.modelId = nil
  comboCfg.modelPreset = nil
  comboCfg.layoutType = nil
  comboCfg.orbCombatAlpha = nil
  comboCfg.orbNonFullAlpha = nil
  comboCfg.orbFullIdleAlpha = nil
  
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
  if e.sizeSlider and e.sizeSlider.slider then
    e.sizeSlider.slider:SetValue(ORB_DEFAULTS.orbSize)
    if e.sizeSlider.UpdateDisplay then e.sizeSlider.UpdateDisplay(ORB_DEFAULTS.orbSize) end
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
  local defaultsAlpha = ORB_DEFAULTS.alpha or {}
  if e.combatAlphaSlider and e.combatAlphaSlider.slider then
    local v = defaultsAlpha.combat or 40
    e.combatAlphaSlider.slider:SetValue(v)
    if e.combatAlphaSlider.UpdateDisplay then e.combatAlphaSlider.UpdateDisplay(v) end
  end
  if e.nonFullAlphaSlider and e.nonFullAlphaSlider.slider then
    local v = defaultsAlpha.nonFull or 20
    e.nonFullAlphaSlider.slider:SetValue(v)
    if e.nonFullAlphaSlider.UpdateDisplay then e.nonFullAlphaSlider.UpdateDisplay(v) end
  end
  if e.fullIdleAlphaSlider and e.fullIdleAlphaSlider.slider then
    local v = defaultsAlpha.fullIdle or 0
    e.fullIdleAlphaSlider.slider:SetValue(v)
    if e.fullIdleAlphaSlider.UpdateDisplay then e.fullIdleAlphaSlider.UpdateDisplay(v) end
  end
  if e.enabledCheckbox then e.enabledCheckbox:SetChecked(true) end
  if e.modelIdEditBox and self.GetDefaultModelId then
    e.modelIdEditBox:SetText(tostring(self.GetDefaultModelId()))
  end
  if self.SetLayoutSelection then
    self:SetLayoutSelection(ORB_DEFAULTS.layoutType or "circle")
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
