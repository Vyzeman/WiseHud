local ADDON_NAME = ...

-- Orb Resource Tab Class

local OptionsTab = WiseHudOptionsBaseTab
local Helpers = WiseHudOptionsHelpers

local OrbResourceTab = setmetatable({}, {__index = OptionsTab})
OrbResourceTab.__index = OrbResourceTab

function OrbResourceTab:new(parent, panel)
  local instance = OptionsTab.new(self, parent, panel)
  return instance
end

function OrbResourceTab:Create()
  local comboCfg = Helpers.ensureComboTable()
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
  
  -- Test Mode checkbox
  e.testModeCheckbox = Helpers.CreateCheckbox(e.enableSection, "WiseHudOrbsTestModeCheckbox", "Test Mode (Show Max CP)", comboCfg.testMode == true, function(self, checked)
    local cfg = Helpers.ensureComboTable()
    cfg.testMode = checked
    if WiseHudOrbs_OnPowerUpdate then
      WiseHudOrbs_OnPowerUpdate("player")
    end
  end)
  e.testModeCheckbox:SetPoint("TOPLEFT", e.enabledCheckbox, "BOTTOMLEFT", 0, -8)
  
  yOffset = yOffset - 100
  
  -- Model ID Settings Section (moved to top, above Position Section)
  e.modelSection = Helpers.CreateSectionFrame(self.parent, "WiseHudOrbsModelSection", "Model Settings", 500, 100)
  
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
    return 1372960
  end
  
  local modelLabel = e.modelSection:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  modelLabel:SetPoint("TOPLEFT", e.modelSection, "TOPLEFT", 12, -12)
  modelLabel:SetText("Model ID:")
  modelLabel:SetTextColor(1, 1, 1)
  
  e.modelIdEditBox = CreateFrame("EditBox", "WiseHudOrbsModelIdEditBox", e.modelSection, "InputBoxTemplate")
  e.modelIdEditBox:SetPoint("TOPLEFT", modelLabel, "BOTTOMLEFT", 0, -8)
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
  
  -- Apply Model Button
  local testModelButton = CreateFrame("Button", "WiseHudOrbsTestModelButton", e.modelSection, "UIPanelButtonTemplate")
  testModelButton:SetSize(120, 28)
  testModelButton:SetPoint("LEFT", e.modelIdEditBox, "RIGHT", 12, 0)
  testModelButton:SetText("Apply Model")
  
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
        -- Update camera position for ALL orbs after successful model apply
        -- This ensures camera is set even for hidden orbs
        -- Set camera position multiple times with delays to ensure it sticks
        if WiseHudOrbs_UpdateCameraPosition then
          -- First update after model has time to start loading
          C_Timer.After(0.2, function()
            if WiseHudOrbs_UpdateCameraPosition then
              WiseHudOrbs_UpdateCameraPosition()
            end
          end)
          -- Second update after model should be loaded
          C_Timer.After(0.4, function()
            if WiseHudOrbs_UpdateCameraPosition then
              WiseHudOrbs_UpdateCameraPosition()
            end
          end)
          -- Third update to ensure it sticks
          C_Timer.After(0.6, function()
            if WiseHudOrbs_UpdateCameraPosition then
              WiseHudOrbs_UpdateCameraPosition()
            end
          end)
        end
      else
        print("|cFFFF0000WiseHud:|r Model ID " .. modelId .. " not found. Please check the ID and try again.")
      end
    else
      -- Model ID is saved but couldn't test it
      print("|cFFFFFF00WiseHud:|r Model ID " .. modelId .. " saved. It will be applied when orbs are created.")
    end
  end)
  
  -- Calculate yOffset for next section: model section height (100) + title space (28) + padding
  yOffset = yOffset - 100 - 20 -- Section height + extra padding
  
  -- Combo Points Position Section (moved below Model Settings)
  e.positionSection = Helpers.CreateSectionFrame(self.parent, "WiseHudOrbsPositionSection", "Combo Points Position", 500, 200)
  
  -- Position title above section
  if e.positionSection.titleText then
    e.positionSection.titleText:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 20, yOffset)
    yOffset = yOffset - 28 -- Space for title
  end
  
  e.positionSection:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 20, yOffset)
  
  -- Combo Points X Position
  e.xSlider = Helpers.CreateSlider(e.positionSection, "WiseHudOrbsXSlider", "X Position", -400, 400, 5, comboCfg.x or 0, nil, function(self, value)
    local cfg = Helpers.ensureComboTable()
    cfg.x = value
    if WiseHudOrbs_ApplyLayout then WiseHudOrbs_ApplyLayout() end
  end)
  e.xSlider:SetPoint("TOPLEFT", e.positionSection, "TOPLEFT", 12, -12)
  
  -- Combo Points Y Position
  e.ySlider = Helpers.CreateSlider(e.positionSection, "WiseHudOrbsYSlider", "Y Position", -200, 80, 5, comboCfg.y or -50, nil, function(self, value)
    local cfg = Helpers.ensureComboTable()
    cfg.y = value
    if WiseHudOrbs_ApplyLayout then WiseHudOrbs_ApplyLayout() end
  end)
  e.ySlider:SetPoint("TOPLEFT", e.xSlider, "BOTTOMLEFT", 0, -20)
  
  -- Combo Points Radius
  e.radiusSlider = Helpers.CreateSlider(e.positionSection, "WiseHudOrbsRadiusSlider", "Radius", 20, 80, 5, comboCfg.radius or 35, nil, function(self, value)
    local cfg = Helpers.ensureComboTable()
    cfg.radius = value
    if WiseHudOrbs_ApplyLayout then WiseHudOrbs_ApplyLayout() end
  end)
  e.radiusSlider:SetPoint("TOPLEFT", e.ySlider, "BOTTOMLEFT", 0, -20)
  
  -- Calculate yOffset for next section: position section height (200) + title space (28) + padding
  yOffset = yOffset - 200 - 20 -- Section height + extra padding
  
  -- Camera Position Section (moved below Position Section)
  e.cameraSection = Helpers.CreateSectionFrame(self.parent, "WiseHudOrbsCameraSection", "Camera Position", 500, 200)
  
  -- Position title above section
  if e.cameraSection.titleText then
    e.cameraSection.titleText:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 20, yOffset)
    yOffset = yOffset - 28 -- Space for title
  end
  
  e.cameraSection:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 20, yOffset)
  
  -- Camera X Position
  e.cameraXSlider = Helpers.CreateSlider(e.cameraSection, "WiseHudOrbsCameraXSlider", "Camera X", -3.0, 0.0, 0.1, comboCfg.cameraX or -3.0, "%.1f", function(self, value)
    local cfg = Helpers.ensureComboTable()
    cfg.cameraX = value
    if WiseHudOrbs_UpdateCameraPosition then
      WiseHudOrbs_UpdateCameraPosition()
    end
  end)
  e.cameraXSlider:SetPoint("TOPLEFT", e.cameraSection, "TOPLEFT", 12, -12)
  
  -- Camera Y Position
  e.cameraYSlider = Helpers.CreateSlider(e.cameraSection, "WiseHudOrbsCameraYSlider", "Camera Y", -2.0, 2.0, 0.1, comboCfg.cameraY or 0.0, "%.1f", function(self, value)
    local cfg = Helpers.ensureComboTable()
    cfg.cameraY = value
    if WiseHudOrbs_UpdateCameraPosition then
      WiseHudOrbs_UpdateCameraPosition()
    end
  end)
  e.cameraYSlider:SetPoint("TOPLEFT", e.cameraXSlider, "BOTTOMLEFT", 0, -20)
  
  -- Camera Z Position
  e.cameraZSlider = Helpers.CreateSlider(e.cameraSection, "WiseHudOrbsCameraZSlider", "Camera Z", -2.0, 2.0, 0.1, comboCfg.cameraZ or -1.7, "%.1f", function(self, value)
    local cfg = Helpers.ensureComboTable()
    cfg.cameraZ = value
    if WiseHudOrbs_UpdateCameraPosition then
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
end

function OrbResourceTab:Refresh()
  if self.SetModelIdText then
    self.SetModelIdText()
  end
  
  -- Reload values from config and update sliders
  local comboCfg = Helpers.ensureComboTable()
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
  RefreshSlider(e.xSlider, comboCfg.x, 0)
  RefreshSlider(e.ySlider, comboCfg.y, -50)
  RefreshSlider(e.radiusSlider, comboCfg.radius, 35)
  RefreshSlider(e.cameraXSlider, comboCfg.cameraX, -3.0)
  RefreshSlider(e.cameraYSlider, comboCfg.cameraY, 0.0)
  RefreshSlider(e.cameraZSlider, comboCfg.cameraZ, -1.7)
  
  -- Update checkboxes
  if e.enabledCheckbox then
    e.enabledCheckbox:SetChecked(comboCfg.enabled ~= false)
  end
  if e.testModeCheckbox then
    e.testModeCheckbox:SetChecked(comboCfg.testMode == true)
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
  
  local e = self.elements
  if e.xSlider and e.xSlider.slider then 
    e.xSlider.slider:SetValue(0)
    if e.xSlider.UpdateDisplay then e.xSlider.UpdateDisplay(0) end
  end
  if e.ySlider and e.ySlider.slider then 
    e.ySlider.slider:SetValue(-50)
    if e.ySlider.UpdateDisplay then e.ySlider.UpdateDisplay(-50) end
  end
  if e.radiusSlider and e.radiusSlider.slider then 
    e.radiusSlider.slider:SetValue(35)
    if e.radiusSlider.UpdateDisplay then e.radiusSlider.UpdateDisplay(35) end
  end
  if e.cameraXSlider and e.cameraXSlider.slider then 
    e.cameraXSlider.slider:SetValue(-3.0)
    if e.cameraXSlider.UpdateDisplay then e.cameraXSlider.UpdateDisplay(-3.0) end
  end
  if e.cameraYSlider and e.cameraYSlider.slider then 
    e.cameraYSlider.slider:SetValue(0.0)
    if e.cameraYSlider.UpdateDisplay then e.cameraYSlider.UpdateDisplay(0.0) end
  end
  if e.cameraZSlider and e.cameraZSlider.slider then 
    e.cameraZSlider.slider:SetValue(-1.7)
    if e.cameraZSlider.UpdateDisplay then e.cameraZSlider.UpdateDisplay(-1.7) end
  end
  if e.enabledCheckbox then e.enabledCheckbox:SetChecked(true) end
  if e.testModeCheckbox then e.testModeCheckbox:SetChecked(false) end
  if e.modelIdEditBox and self.GetDefaultModelId then
    e.modelIdEditBox:SetText(tostring(self.GetDefaultModelId()))
  end
  
  if WiseHudOrbs_SetEnabled then WiseHudOrbs_SetEnabled(true) end
  if WiseHudOrbs_ApplyLayout then WiseHudOrbs_ApplyLayout() end
end

-- Export class
WiseHudOptionsOrbResourceTab = OrbResourceTab
