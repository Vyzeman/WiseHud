local ADDON_NAME = ...

-- Options panel for WiseHud (HUD layout + Combo Points)

-- Debug: Check LibStub availability immediately
do
  local libStub = _G.LibStub
  if not libStub then
    print("WiseHud: LibStub not found in global namespace at Options.lua load time")
  elseif type(libStub) ~= "table" then
    print("WiseHud: LibStub exists but is not a table (type: " .. type(libStub) .. ")")
  elseif type(libStub.GetLibrary) ~= "function" then
    print("WiseHud: LibStub exists but GetLibrary is not a function")
  else
    print("WiseHud: LibStub loaded successfully")
  end
end

-- Debug: Check if LibStub and LibSharedMedia are available
local function CheckLSMAvailability()
  -- Check if LibStub exists in global namespace
  local libStub = _G.LibStub
  if not libStub then
    return false, "LibStub not in global namespace"
  end
  
  if type(libStub) ~= "table" then
    return false, "LibStub is not a table (type: " .. type(libStub) .. ")"
  end
  
  if type(libStub.GetLibrary) ~= "function" then
    return false, "LibStub.GetLibrary is not a function"
  end
  
  local lsm = libStub:GetLibrary("LibSharedMedia-3.0", true)
  if not lsm then
    return false, "LibSharedMedia-3.0 not found via LibStub"
  end
  
  if not lsm.MediaTable then
    return false, "LibSharedMedia found but MediaTable missing"
  end
  
  if not lsm.MediaTable.statusbar then
    return false, "LibSharedMedia found but statusbar table missing"
  end
  
  return true, "OK"
end

local function ensureLayoutTable()
  WiseHudDB = WiseHudDB or {}
  WiseHudDB.barLayout = WiseHudDB.barLayout or {}
  return WiseHudDB.barLayout
end

local function ensureAlphaTable()
  WiseHudDB = WiseHudDB or {}
  WiseHudDB.alphaSettings = WiseHudDB.alphaSettings or {}
  return WiseHudDB.alphaSettings
end

local function ensureComboTable()
  WiseHudDB = WiseHudDB or {}
  WiseHudDB.comboSettings = WiseHudDB.comboSettings or {}
  return WiseHudDB.comboSettings
end

local function CreateOptionsPanel()
  if type(Settings) ~= "table" or WiseHudOptionsCategory then
    return
  end

  local panel = CreateFrame("Frame")
  panel.name = "WiseHud"

  -- Create tab container
  local tabContainer = CreateFrame("Frame", nil, panel)
  tabContainer:SetPoint("TOPLEFT", 16, -50)
  tabContainer:SetPoint("BOTTOMRIGHT", -16, 16)

  -- Create three tab panels
  local orbTab = CreateFrame("Frame", nil, tabContainer)
  orbTab:SetAllPoints(tabContainer)
  orbTab:Hide()

  local healthPowerTab = CreateFrame("Frame", nil, tabContainer)
  healthPowerTab:SetAllPoints(tabContainer)
  healthPowerTab:Hide()

  local castTab = CreateFrame("Frame", nil, tabContainer)
  castTab:SetAllPoints(tabContainer)
  castTab:Hide()

  -- Create tab buttons (without template for control over OnShow)
  local tab1 = CreateFrame("Button", nil, panel)
  tab1:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -16)
  tab1:SetID(1)
  tab1:SetSize(100, 32)
  
  -- Background texture for tab
  local tab1Bg = tab1:CreateTexture(nil, "BACKGROUND")
  tab1Bg:SetAllPoints(tab1)
  tab1Bg:SetTexture("Interface\\OptionsFrame\\UI-OptionsFrame-ActiveTab")
  tab1.bg = tab1Bg
  
  -- Text element for tab 1
  local tab1Text = tab1:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  tab1Text:SetPoint("CENTER", tab1, "CENTER", 0, -3)
  tab1.Text = tab1Text
  tab1Text:SetText("Orb Resource")
  
  -- Set size based on text
  local textWidth = tab1Text:GetStringWidth()
  tab1:SetWidth(textWidth + 20)

  local tab2 = CreateFrame("Button", nil, panel)
  tab2:SetPoint("LEFT", tab1, "RIGHT", -5, 0)
  tab2:SetID(2)
  tab2:SetSize(100, 32)
  
  -- Background texture for tab
  local tab2Bg = tab2:CreateTexture(nil, "BACKGROUND")
  tab2Bg:SetAllPoints(tab2)
  tab2Bg:SetTexture("Interface\\OptionsFrame\\UI-OptionsFrame-ActiveTab")
  tab2.bg = tab2Bg
  
  -- Text element for tab 2
  local tab2Text = tab2:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  tab2Text:SetPoint("CENTER", tab2, "CENTER", 0, -3)
  tab2.Text = tab2Text
  tab2Text:SetText("Health/Power")
  
  -- Set size based on text
  local textWidth2 = tab2Text:GetStringWidth()
  tab2:SetWidth(textWidth2 + 20)

  local tab3 = CreateFrame("Button", nil, panel)
  tab3:SetPoint("LEFT", tab2, "RIGHT", -5, 0)
  tab3:SetID(3)
  tab3:SetSize(100, 32)
  
  -- Background texture for tab
  local tab3Bg = tab3:CreateTexture(nil, "BACKGROUND")
  tab3Bg:SetAllPoints(tab3)
  tab3Bg:SetTexture("Interface\\OptionsFrame\\UI-OptionsFrame-ActiveTab")
  tab3.bg = tab3Bg
  
  -- Text element for tab 3
  local tab3Text = tab3:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  tab3Text:SetPoint("CENTER", tab3, "CENTER", 0, -3)
  tab3.Text = tab3Text
  tab3Text:SetText("Cast Bar")
  
  -- Set size based on text
  local textWidth3 = tab3Text:GetStringWidth()
  tab3:SetWidth(textWidth3 + 20)
  
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
    elseif tabID == 2 then
      orbTab:Hide()
      healthPowerTab:Show()
      castTab:Hide()
    else
      orbTab:Hide()
      healthPowerTab:Hide()
      castTab:Show()
    end
  end

  tab1:SetScript("OnClick", function() SelectTab(1) end)
  tab2:SetScript("OnClick", function() SelectTab(2) end)
  tab3:SetScript("OnClick", function() SelectTab(3) end)

  -- Initialize with tab 1
  UpdateTabAppearance()
  SelectTab(1)

  -- ===== TAB 1: Orb Resource =====
  local comboCfg = ensureComboTable()
  
  -- Enable/Disable checkbox
  local comboEnabledCheckbox = CreateFrame("CheckButton", "WiseHudOrbsEnabledCheckbox", orbTab, "InterfaceOptionsCheckButtonTemplate")
  comboEnabledCheckbox:SetPoint("TOPLEFT", 0, -20)
  _G[comboEnabledCheckbox:GetName() .. "Text"]:SetText("Enable Orbs")
  comboEnabledCheckbox:SetChecked(comboCfg.enabled ~= false)
  
  comboEnabledCheckbox:SetScript("OnClick", function(self)
    local cfg = ensureComboTable()
    cfg.enabled = self:GetChecked()
    if WiseHudOrbs_SetEnabled then
      WiseHudOrbs_SetEnabled(cfg.enabled)
    end
  end)
  
  -- Test Mode checkbox
  local testModeCheckbox = CreateFrame("CheckButton", "WiseHudOrbsTestModeCheckbox", orbTab, "InterfaceOptionsCheckButtonTemplate")
  testModeCheckbox:SetPoint("TOPLEFT", comboEnabledCheckbox, "BOTTOMLEFT", 0, -20)
  _G[testModeCheckbox:GetName() .. "Text"]:SetText("Test Mode (Show Max CP)")
  testModeCheckbox:SetChecked(comboCfg.testMode == true)
  
  testModeCheckbox:SetScript("OnClick", function(self)
    local cfg = ensureComboTable()
    cfg.testMode = self:GetChecked()
    -- Update orbs immediately when test mode is toggled
    if WiseHudOrbs_OnPowerUpdate then
      WiseHudOrbs_OnPowerUpdate("player")
    end
  end)
  
  local comboLabel = orbTab:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  comboLabel:SetPoint("TOPLEFT", testModeCheckbox, "BOTTOMLEFT", 0, -20)
  comboLabel:SetText("Combo Points Position:")

  -- Combo Points X Position
  local comboXSlider = CreateFrame("Slider", "WiseHudOrbsXSlider", orbTab, "OptionsSliderTemplate")
  comboXSlider:SetPoint("TOPLEFT", comboLabel, "BOTTOMLEFT", 0, -20)
  comboXSlider:SetMinMaxValues(-400, 400)
  comboXSlider:SetValueStep(5)
  comboXSlider:SetObeyStepOnDrag(true)
  comboXSlider:SetValue(comboCfg.x or 0)
  _G[comboXSlider:GetName() .. "Low"]:SetText("-400")
  _G[comboXSlider:GetName() .. "High"]:SetText("400")
  _G[comboXSlider:GetName() .. "Text"]:SetText("X Position: " .. (comboCfg.x or 0))

  comboXSlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value + 0.5)
    local cfg = ensureComboTable()
    cfg.x = value
    _G[self:GetName() .. "Text"]:SetText("X Position: " .. value)
    if WiseHudOrbs_ApplyLayout then WiseHudOrbs_ApplyLayout() end
  end)

  -- Combo Points Y Position
  local comboYSlider = CreateFrame("Slider", "WiseHudOrbsYSlider", orbTab, "OptionsSliderTemplate")
  comboYSlider:SetPoint("TOPLEFT", comboXSlider, "BOTTOMLEFT", 0, -24)
  comboYSlider:SetMinMaxValues(-200, 80)
  comboYSlider:SetValueStep(5)
  comboYSlider:SetObeyStepOnDrag(true)
  comboYSlider:SetValue(comboCfg.y or -60)
  _G[comboYSlider:GetName() .. "Low"]:SetText("-200")
  _G[comboYSlider:GetName() .. "High"]:SetText("80")
  _G[comboYSlider:GetName() .. "Text"]:SetText("Y Position: " .. (comboCfg.y or -60))

  comboYSlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value + 0.5)
    local cfg = ensureComboTable()
    cfg.y = value
    _G[self:GetName() .. "Text"]:SetText("Y Position: " .. value)
    if WiseHudOrbs_ApplyLayout then WiseHudOrbs_ApplyLayout() end
  end)

  -- Combo Points Radius
  local comboRadiusSlider = CreateFrame("Slider", "WiseHudOrbsRadiusSlider", orbTab, "OptionsSliderTemplate")
  comboRadiusSlider:SetPoint("TOPLEFT", comboYSlider, "BOTTOMLEFT", 0, -24)
  comboRadiusSlider:SetMinMaxValues(20, 80)
  comboRadiusSlider:SetValueStep(5)
  comboRadiusSlider:SetObeyStepOnDrag(true)
  comboRadiusSlider:SetValue(comboCfg.radius or 50)
  _G[comboRadiusSlider:GetName() .. "Low"]:SetText("20")
  _G[comboRadiusSlider:GetName() .. "High"]:SetText("80")
  _G[comboRadiusSlider:GetName() .. "Text"]:SetText("Radius: " .. (comboCfg.radius or 50))

  comboRadiusSlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value + 0.5)
    local cfg = ensureComboTable()
    cfg.radius = value
    _G[self:GetName() .. "Text"]:SetText("Radius: " .. value)
    if WiseHudOrbs_ApplyLayout then WiseHudOrbs_ApplyLayout() end
  end)

  -- Camera Position
  local cameraLabel = orbTab:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  cameraLabel:SetPoint("TOPLEFT", comboRadiusSlider, "BOTTOMLEFT", 0, -24)
  cameraLabel:SetText("Camera Position:")

  -- Camera X Position (Zoom)
  local cameraXSlider = CreateFrame("Slider", "WiseHudOrbsCameraXSlider", orbTab, "OptionsSliderTemplate")
  cameraXSlider:SetPoint("TOPLEFT", cameraLabel, "BOTTOMLEFT", 0, -20)
  cameraXSlider:SetMinMaxValues(-3.0, 0.0)
  cameraXSlider:SetValueStep(0.1)
  cameraXSlider:SetObeyStepOnDrag(true)
  cameraXSlider:SetValue(comboCfg.cameraX or -1.2)
  _G[cameraXSlider:GetName() .. "Low"]:SetText("-3.0")
  _G[cameraXSlider:GetName() .. "High"]:SetText("0.0")
  _G[cameraXSlider:GetName() .. "Text"]:SetText("Camera X: " .. string.format("%.1f", comboCfg.cameraX or -1.2))

  cameraXSlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value * 10 + 0.5) / 10  -- Round to 1 decimal place
    local cfg = ensureComboTable()
    cfg.cameraX = value
    _G[self:GetName() .. "Text"]:SetText("Camera X: " .. string.format("%.1f", value))
    -- Update camera position for all orbs
    if WiseHudOrbs_UpdateCameraPosition then
      WiseHudOrbs_UpdateCameraPosition()
    end
  end)

  -- Camera Y Position
  local cameraYSlider = CreateFrame("Slider", "WiseHudOrbsCameraYSlider", orbTab, "OptionsSliderTemplate")
  cameraYSlider:SetPoint("TOPLEFT", cameraXSlider, "BOTTOMLEFT", 0, -24)
  cameraYSlider:SetMinMaxValues(-2.0, 2.0)
  cameraYSlider:SetValueStep(0.1)
  cameraYSlider:SetObeyStepOnDrag(true)
  cameraYSlider:SetValue(comboCfg.cameraY or 0.0)
  _G[cameraYSlider:GetName() .. "Low"]:SetText("-2.0")
  _G[cameraYSlider:GetName() .. "High"]:SetText("2.0")
  _G[cameraYSlider:GetName() .. "Text"]:SetText("Camera Y: " .. string.format("%.1f", comboCfg.cameraY or 0.0))

  cameraYSlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value * 10 + 0.5) / 10  -- Round to 1 decimal place
    local cfg = ensureComboTable()
    cfg.cameraY = value
    _G[self:GetName() .. "Text"]:SetText("Camera Y: " .. string.format("%.1f", value))
    -- Update camera position for all orbs
    if WiseHudOrbs_UpdateCameraPosition then
      WiseHudOrbs_UpdateCameraPosition()
    end
  end)

  -- Camera Z Position
  local cameraZSlider = CreateFrame("Slider", "WiseHudOrbsCameraZSlider", orbTab, "OptionsSliderTemplate")
  cameraZSlider:SetPoint("TOPLEFT", cameraYSlider, "BOTTOMLEFT", 0, -24)
  cameraZSlider:SetMinMaxValues(-2.0, 2.0)
  cameraZSlider:SetValueStep(0.1)
  cameraZSlider:SetObeyStepOnDrag(true)
  cameraZSlider:SetValue(comboCfg.cameraZ or 0.0)
  _G[cameraZSlider:GetName() .. "Low"]:SetText("-2.0")
  _G[cameraZSlider:GetName() .. "High"]:SetText("2.0")
  _G[cameraZSlider:GetName() .. "Text"]:SetText("Camera Z: " .. string.format("%.1f", comboCfg.cameraZ or 0.0))

  cameraZSlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value * 10 + 0.5) / 10  -- Round to 1 decimal place
    local cfg = ensureComboTable()
    cfg.cameraZ = value
    _G[self:GetName() .. "Text"]:SetText("Camera Z: " .. string.format("%.1f", value))
    -- Update camera position for all orbs
    if WiseHudOrbs_UpdateCameraPosition then
      WiseHudOrbs_UpdateCameraPosition()
    end
  end)

  -- Model ID Settings
  local modelLabel = orbTab:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  modelLabel:SetPoint("TOPLEFT", cameraZSlider, "BOTTOMLEFT", 0, -24)
  modelLabel:SetText("Model ID:")

  -- Helper function to get default model ID
  local function GetDefaultModelId()
    if WiseHudOrbs_GetDefaultModelId then
      return WiseHudOrbs_GetDefaultModelId()
    end
    return 1372960 -- Fallback if function not available
  end
  
  -- Model ID Input Field (use standard InputBoxTemplate)
  local modelIdEditBox = CreateFrame("EditBox", "WiseHudOrbsModelIdEditBox", orbTab, "InputBoxTemplate")
  modelIdEditBox:SetPoint("TOPLEFT", modelLabel, "BOTTOMLEFT", 0, -5)
  modelIdEditBox:SetSize(150, 20)
  modelIdEditBox:SetAutoFocus(false)
  
  -- Helper function to get current model ID for display
  local function GetCurrentModelIdForDisplay()
    local cfg = ensureComboTable()
    if cfg.modelId then
      return tostring(cfg.modelId)
    end
    -- Default model ID from Combo.lua
    return tostring(GetDefaultModelId())
  end
  
  -- Display the saved model ID, or default if not set
  local function SetModelIdText()
    if not modelIdEditBox then return end
    local text = GetCurrentModelIdForDisplay()
    modelIdEditBox:SetText(text)
    -- Ensure cursor (and thus visible text) is am Anfang
    modelIdEditBox:SetCursorPosition(0)
  end
  
  -- Set text once after creation
  SetModelIdText()
  
  -- Helper function to update model
  local function UpdateModelFromInput()
    local text = modelIdEditBox:GetText() or ""
    text = strtrim(text)
    local cfg = ensureComboTable()
    
    if text == "" then
      -- Empty: reset to default
      cfg.modelId = nil
    else
      local asNumber = tonumber(text)
      if asNumber then
        cfg.modelId = asNumber
      else
        -- Allow string path
        cfg.modelId = text
      end
    end
    
    -- Apply model to existing orbs
    if WiseHudOrbs_ApplyModelPathToExistingOrbs then
      WiseHudOrbs_ApplyModelPathToExistingOrbs()
    end
    
    -- Normalize display text
    SetModelIdText()
  end
  
  modelIdEditBox:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
    UpdateModelFromInput()
  end)
  
  modelIdEditBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
    SetModelIdText()
  end)
  
  modelIdEditBox:SetScript("OnEditFocusLost", function(self)
    UpdateModelFromInput()
  end)

  -- Test/Check Button
  local testModelButton = CreateFrame("Button", "WiseHudOrbsTestModelButton", orbTab, "UIPanelButtonTemplate")
  testModelButton:SetSize(100, 25)
  testModelButton:SetPoint("LEFT", modelIdEditBox, "RIGHT", 10, 0)
  testModelButton:SetText("Test Model")
  
  testModelButton:SetScript("OnClick", function(self)
    UpdateModelFromInput()
    -- Force update of orbs to show the new model
    if WiseHudOrbs_ApplyModelPathToExistingOrbs then
      WiseHudOrbs_ApplyModelPathToExistingOrbs()
    end
    -- Also trigger a power update to refresh display
    if WiseHudOrbs_OnPowerUpdate then
      WiseHudOrbs_OnPowerUpdate("player")
    end
  end)

  -- ===== TAB 2: Health/Power =====
  -- Health enable/disable checkbox
  local healthEnabledCheckbox = CreateFrame("CheckButton", "WiseHudHealthEnabledCheckbox", healthPowerTab, "InterfaceOptionsCheckButtonTemplate")
  healthEnabledCheckbox:SetPoint("TOPLEFT", 0, -20)
  _G[healthEnabledCheckbox:GetName() .. "Text"]:SetText("Enable Health")
  local healthCfg = ensureLayoutTable()
  healthEnabledCheckbox:SetChecked(healthCfg.healthEnabled ~= false)
  
  healthEnabledCheckbox:SetScript("OnClick", function(self)
    local cfg = ensureLayoutTable()
    cfg.healthEnabled = self:GetChecked()
    if WiseHudHealth_SetEnabled then
      WiseHudHealth_SetEnabled(cfg.healthEnabled)
    end
  end)
  
  -- Power enable/disable checkbox
  local powerEnabledCheckbox = CreateFrame("CheckButton", "WiseHudPowerEnabledCheckbox", healthPowerTab, "InterfaceOptionsCheckButtonTemplate")
  powerEnabledCheckbox:SetPoint("TOPLEFT", healthEnabledCheckbox, "BOTTOMLEFT", 0, -10)
  _G[powerEnabledCheckbox:GetName() .. "Text"]:SetText("Enable Power")
  powerEnabledCheckbox:SetChecked(healthCfg.powerEnabled ~= false)
  
  powerEnabledCheckbox:SetScript("OnClick", function(self)
    local cfg = ensureLayoutTable()
    cfg.powerEnabled = self:GetChecked()
    if WiseHudPower_SetEnabled then
      WiseHudPower_SetEnabled(cfg.powerEnabled)
    end
  end)
  
  local layoutLabel = healthPowerTab:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  layoutLabel:SetPoint("TOPLEFT", powerEnabledCheckbox, "BOTTOMLEFT", 0, -20)
  layoutLabel:SetText("HUD Arc Size and Distance:")

  local layout = ensureLayoutTable()

  -- Width
  local widthSlider = CreateFrame("Slider", "WiseHudBarWidthSlider", healthPowerTab, "OptionsSliderTemplate")
  widthSlider:SetPoint("TOPLEFT", layoutLabel, "BOTTOMLEFT", 0, -20)
  widthSlider:SetMinMaxValues(120, 400)
  widthSlider:SetValueStep(5)
  widthSlider:SetObeyStepOnDrag(true)
  widthSlider:SetValue(layout.width or 260)
  _G[widthSlider:GetName() .. "Low"]:SetText("120")
  _G[widthSlider:GetName() .. "High"]:SetText("400")
  _G[widthSlider:GetName() .. "Text"]:SetText("Width: " .. (layout.width or 260))

  widthSlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value + 0.5)
    local cfg = ensureLayoutTable()
    cfg.width = value
    _G[self:GetName() .. "Text"]:SetText("Width: " .. value)
    if WiseHudHealth_ApplyLayout then WiseHudHealth_ApplyLayout() end
    if WiseHudPower_ApplyLayout then WiseHudPower_ApplyLayout() end
  end)

  -- Height
  local heightSlider = CreateFrame("Slider", "WiseHudBarHeightSlider", healthPowerTab, "OptionsSliderTemplate")
  heightSlider:SetPoint("TOPLEFT", widthSlider, "BOTTOMLEFT", 0, -24)
  heightSlider:SetMinMaxValues(330, 500)
  heightSlider:SetValueStep(5)
  heightSlider:SetObeyStepOnDrag(true)
  heightSlider:SetValue(layout.height or 415)
  _G[heightSlider:GetName() .. "Low"]:SetText("330")
  _G[heightSlider:GetName() .. "High"]:SetText("500")
  _G[heightSlider:GetName() .. "Text"]:SetText("Height: " .. (layout.height or 415))

  heightSlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value + 0.5)
    local cfg = ensureLayoutTable()
    cfg.height = value
    _G[self:GetName() .. "Text"]:SetText("Height: " .. value)
    if WiseHudHealth_ApplyLayout then WiseHudHealth_ApplyLayout() end
    if WiseHudPower_ApplyLayout then WiseHudPower_ApplyLayout() end
  end)

  -- Distance from center (X)
  local offsetSlider = CreateFrame("Slider", "WiseHudBarOffsetSlider", healthPowerTab, "OptionsSliderTemplate")
  offsetSlider:SetPoint("TOPLEFT", heightSlider, "BOTTOMLEFT", 0, -24)
  offsetSlider:SetMinMaxValues(170, 200)
  offsetSlider:SetValueStep(5)
  offsetSlider:SetObeyStepOnDrag(true)
  offsetSlider:SetValue(layout.offset or 185)
  _G[offsetSlider:GetName() .. "Low"]:SetText("170")
  _G[offsetSlider:GetName() .. "High"]:SetText("200")
  _G[offsetSlider:GetName() .. "Text"]:SetText("Distance X: " .. (layout.offset or 185))

  offsetSlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value + 0.5)
    local cfg = ensureLayoutTable()
    cfg.offset = value
    _G[self:GetName() .. "Text"]:SetText("Distance X: " .. value)
    if WiseHudHealth_ApplyLayout then WiseHudHealth_ApplyLayout() end
    if WiseHudPower_ApplyLayout then WiseHudPower_ApplyLayout() end
  end)

  -- Vertical offset (Y)
  local offsetYSlider = CreateFrame("Slider", "WiseHudBarOffsetYSlider", healthPowerTab, "OptionsSliderTemplate")
  offsetYSlider:SetPoint("TOPLEFT", offsetSlider, "BOTTOMLEFT", 0, -24)
  offsetYSlider:SetMinMaxValues(-20, 200)
  offsetYSlider:SetValueStep(5)
  offsetYSlider:SetObeyStepOnDrag(true)
  offsetYSlider:SetValue(layout.offsetY or 90)
  _G[offsetYSlider:GetName() .. "Low"]:SetText("-20")
  _G[offsetYSlider:GetName() .. "High"]:SetText("200")
  _G[offsetYSlider:GetName() .. "Text"]:SetText("Distance Y: " .. (layout.offsetY or 90))

  offsetYSlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value + 0.5)
    local cfg = ensureLayoutTable()
    cfg.offsetY = value
    _G[self:GetName() .. "Text"]:SetText("Distance Y: " .. value)
    if WiseHudHealth_ApplyLayout then WiseHudHealth_ApplyLayout() end
    if WiseHudPower_ApplyLayout then WiseHudPower_ApplyLayout() end
  end)

  -- Alpha settings (in percent)
  local alphaCfg = ensureAlphaTable()

  local alphaLabel = healthPowerTab:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  alphaLabel:SetPoint("TOPLEFT", offsetYSlider, "BOTTOMLEFT", 0, -30)
  alphaLabel:SetText("Alpha Settings:")

  -- Combat Alpha
  local combatAlphaSlider = CreateFrame("Slider", "WiseHudCombatAlphaSlider", healthPowerTab, "OptionsSliderTemplate")
  combatAlphaSlider:SetPoint("TOPLEFT", alphaLabel, "BOTTOMLEFT", 0, -20)
  combatAlphaSlider:SetMinMaxValues(0, 100)
  combatAlphaSlider:SetValueStep(5)
  combatAlphaSlider:SetObeyStepOnDrag(true)
  combatAlphaSlider:SetValue(alphaCfg.combatAlpha or 70)
  _G[combatAlphaSlider:GetName() .. "Low"]:SetText("0")
  _G[combatAlphaSlider:GetName() .. "High"]:SetText("100")
  _G[combatAlphaSlider:GetName() .. "Text"]:SetText("Combat Alpha: " .. (alphaCfg.combatAlpha or 70) .. "%")

  combatAlphaSlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value + 0.5)
    local cfg = ensureAlphaTable()
    cfg.combatAlpha = value
    _G[self:GetName() .. "Text"]:SetText("Combat Alpha: " .. value .. "%")
    if WiseHudHealth_ApplyAlpha then WiseHudHealth_ApplyAlpha() end
    if WiseHudPower_ApplyAlpha then WiseHudPower_ApplyAlpha() end
  end)

  -- Not full, no combat
  local nonFullAlphaSlider = CreateFrame("Slider", "WiseHudNonFullAlphaSlider", healthPowerTab, "OptionsSliderTemplate")
  nonFullAlphaSlider:SetPoint("TOPLEFT", combatAlphaSlider, "BOTTOMLEFT", 0, -24)
  nonFullAlphaSlider:SetMinMaxValues(0, 100)
  nonFullAlphaSlider:SetValueStep(5)
  nonFullAlphaSlider:SetObeyStepOnDrag(true)
  nonFullAlphaSlider:SetValue(alphaCfg.nonFullAlpha or 40)
  _G[nonFullAlphaSlider:GetName() .. "Low"]:SetText("0")
  _G[nonFullAlphaSlider:GetName() .. "High"]:SetText("100")
  _G[nonFullAlphaSlider:GetName() .. "Text"]:SetText("Not Full (ooc): " .. (alphaCfg.nonFullAlpha or 40) .. "%")

  nonFullAlphaSlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value + 0.5)
    local cfg = ensureAlphaTable()
    cfg.nonFullAlpha = value
    _G[self:GetName() .. "Text"]:SetText("Not Full (ooc): " .. value .. "%")
    if WiseHudHealth_ApplyAlpha then WiseHudHealth_ApplyAlpha() end
    if WiseHudPower_ApplyAlpha then WiseHudPower_ApplyAlpha() end
  end)

  -- Full, no combat
  local fullIdleAlphaSlider = CreateFrame("Slider", "WiseHudFullIdleAlphaSlider", healthPowerTab, "OptionsSliderTemplate")
  fullIdleAlphaSlider:SetPoint("TOPLEFT", nonFullAlphaSlider, "BOTTOMLEFT", 0, -24)
  fullIdleAlphaSlider:SetMinMaxValues(0, 100)
  fullIdleAlphaSlider:SetValueStep(5)
  fullIdleAlphaSlider:SetObeyStepOnDrag(true)
  fullIdleAlphaSlider:SetValue(alphaCfg.fullIdleAlpha or 0)
  _G[fullIdleAlphaSlider:GetName() .. "Low"]:SetText("0")
  _G[fullIdleAlphaSlider:GetName() .. "High"]:SetText("100")
  _G[fullIdleAlphaSlider:GetName() .. "Text"]:SetText("Full (ooc): " .. (alphaCfg.fullIdleAlpha or 0) .. "%")

  fullIdleAlphaSlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value + 0.5)
    local cfg = ensureAlphaTable()
    cfg.fullIdleAlpha = value
    _G[self:GetName() .. "Text"]:SetText("Full (ooc): " .. value .. "%")
    if WiseHudHealth_ApplyAlpha then WiseHudHealth_ApplyAlpha() end
    if WiseHudPower_ApplyAlpha then WiseHudPower_ApplyAlpha() end
  end)

  -- Health Bar Color
  local healthColorLabel = healthPowerTab:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  healthColorLabel:SetPoint("TOPLEFT", fullIdleAlphaSlider, "BOTTOMLEFT", 0, -24)
  healthColorLabel:SetText("Health Bar Color:")

  local healthColorButton = CreateFrame("Button", "WiseHudHealthColorButton", healthPowerTab, "UIPanelButtonTemplate")
  healthColorButton:SetSize(120, 30)
  healthColorButton:SetPoint("TOPLEFT", healthColorLabel, "BOTTOMLEFT", 0, -10)
  healthColorButton:SetText("Pick Color")
  
  local healthColorSwatch = healthColorButton:CreateTexture(nil, "OVERLAY")
  healthColorSwatch:SetSize(20, 20)
  healthColorSwatch:SetPoint("LEFT", healthColorButton, "LEFT", 5, 0)
  healthColorSwatch:SetTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
  
  local healthColorTexture = healthColorButton:CreateTexture(nil, "ARTWORK")
  healthColorTexture:SetSize(16, 16)
  healthColorTexture:SetPoint("CENTER", healthColorSwatch, "CENTER", 0, 0)
  healthColorTexture:SetTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
  healthColorTexture:Show()
  
  local function UpdateHealthColorSwatch()
    if not healthColorTexture then return end
    WiseHudDB = WiseHudDB or {}
    WiseHudDB.barLayout = WiseHudDB.barLayout or {}
    local cfg = WiseHudDB.barLayout
    local r = (cfg.healthR or 37) / 255
    local g = (cfg.healthG or 164) / 255
    local b = (cfg.healthB or 30) / 255
    healthColorTexture:SetVertexColor(r, g, b)
    healthColorTexture:Show()
  end
  UpdateHealthColorSwatch()
  
  healthColorButton:SetScript("OnClick", function()
    WiseHudDB = WiseHudDB or {}
    WiseHudDB.barLayout = WiseHudDB.barLayout or {}
    local cfg = WiseHudDB.barLayout
    local r = (cfg.healthR or 37) / 255
    local g = (cfg.healthG or 164) / 255
    local b = (cfg.healthB or 30) / 255
    
    local origR, origG, origB = r, g, b
    
    local function UpdateHealthColor()
      local newR, newG, newB
      if ColorPickerFrame.GetColorRGB then
        local ok, rgb = pcall(ColorPickerFrame.GetColorRGB, ColorPickerFrame)
        if ok then
          newR, newG, newB = rgb.r, rgb.g, rgb.b
        else
          newR = ColorPickerFrame.r or r
          newG = ColorPickerFrame.g or g
          newB = ColorPickerFrame.b or b
        end
      else
        newR = ColorPickerFrame.r or r
        newG = ColorPickerFrame.g or g
        newB = ColorPickerFrame.b or b
      end
      
      WiseHudDB = WiseHudDB or {}
      WiseHudDB.barLayout = WiseHudDB.barLayout or {}
      local cfg = WiseHudDB.barLayout
      cfg.healthR = math.floor(newR * 255 + 0.5)
      cfg.healthG = math.floor(newG * 255 + 0.5)
      cfg.healthB = math.floor(newB * 255 + 0.5)
      UpdateHealthColorSwatch()
      if WiseHudHealth_UpdateColor then WiseHudHealth_UpdateColor() end
    end
    
    local function CancelHealthColor()
      WiseHudDB = WiseHudDB or {}
      WiseHudDB.barLayout = WiseHudDB.barLayout or {}
      local cfg = WiseHudDB.barLayout
      cfg.healthR = math.floor(origR * 255 + 0.5)
      cfg.healthG = math.floor(origG * 255 + 0.5)
      cfg.healthB = math.floor(origB * 255 + 0.5)
      UpdateHealthColorSwatch()
      if WiseHudHealth_UpdateColor then WiseHudHealth_UpdateColor() end
    end
    
    if ColorPickerFrame.SetupColorPickerAndShow then
      ColorPickerFrame:SetupColorPickerAndShow({
        r = r,
        g = g,
        b = b,
        swatchFunc = UpdateHealthColor,
        cancelFunc = CancelHealthColor,
      })
    else
      ColorPickerFrame.func = UpdateHealthColor
      ColorPickerFrame.cancelFunc = CancelHealthColor
      ColorPickerFrame:SetColorRGB(r, g, b)
      ColorPickerFrame:Show()
    end
  end)

  -- Power Bar Color
  local powerColorLabel = healthPowerTab:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  powerColorLabel:SetPoint("TOPLEFT", healthColorButton, "BOTTOMLEFT", 0, -20)
  powerColorLabel:SetText("Power Bar Color (overrides class default):")

  local powerColorButton = CreateFrame("Button", "WiseHudPowerColorButton", healthPowerTab, "UIPanelButtonTemplate")
  powerColorButton:SetSize(120, 30)
  powerColorButton:SetPoint("TOPLEFT", powerColorLabel, "BOTTOMLEFT", 0, -10)
  powerColorButton:SetText("Pick Color")
  
  local powerColorSwatch = powerColorButton:CreateTexture(nil, "OVERLAY")
  powerColorSwatch:SetSize(20, 20)
  powerColorSwatch:SetPoint("LEFT", powerColorButton, "LEFT", 5, 0)
  powerColorSwatch:SetTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
  
  local powerColorTexture = powerColorButton:CreateTexture(nil, "ARTWORK")
  powerColorTexture:SetSize(16, 16)
  powerColorTexture:SetPoint("CENTER", powerColorSwatch, "CENTER", 0, 0)
  powerColorTexture:SetTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
  powerColorTexture:Show()
  
  local function UpdatePowerColorSwatch()
    if not powerColorTexture then return end
    WiseHudDB = WiseHudDB or {}
    WiseHudDB.barLayout = WiseHudDB.barLayout or {}
    local cfg = WiseHudDB.barLayout
    -- Default to mana color if not set
    local r = (cfg.powerR or 62) / 255
    local g = (cfg.powerG or 54) / 255
    local b = (cfg.powerB or 152) / 255
    powerColorTexture:SetVertexColor(r, g, b)
    powerColorTexture:Show()
  end
  UpdatePowerColorSwatch()
  
  powerColorButton:SetScript("OnClick", function()
    WiseHudDB = WiseHudDB or {}
    WiseHudDB.barLayout = WiseHudDB.barLayout or {}
    local cfg = WiseHudDB.barLayout
    local r = (cfg.powerR or 62) / 255
    local g = (cfg.powerG or 54) / 255
    local b = (cfg.powerB or 152) / 255
    
    local origR, origG, origB = r, g, b
    
    local function UpdatePowerColor()
      local newR, newG, newB
      if ColorPickerFrame.GetColorRGB then
        local ok, rgb = pcall(ColorPickerFrame.GetColorRGB, ColorPickerFrame)
        if ok then
          newR, newG, newB = rgb.r, rgb.g, rgb.b
        else
          newR = ColorPickerFrame.r or r
          newG = ColorPickerFrame.g or g
          newB = ColorPickerFrame.b or b
        end
      else
        newR = ColorPickerFrame.r or r
        newG = ColorPickerFrame.g or g
        newB = ColorPickerFrame.b or b
      end
      
      WiseHudDB = WiseHudDB or {}
      WiseHudDB.barLayout = WiseHudDB.barLayout or {}
      local cfg = WiseHudDB.barLayout
      cfg.powerR = math.floor(newR * 255 + 0.5)
      cfg.powerG = math.floor(newG * 255 + 0.5)
      cfg.powerB = math.floor(newB * 255 + 0.5)
      UpdatePowerColorSwatch()
      if WiseHudPower_UpdateColor then WiseHudPower_UpdateColor() end
    end
    
    local function CancelPowerColor()
      WiseHudDB = WiseHudDB or {}
      WiseHudDB.barLayout = WiseHudDB.barLayout or {}
      local cfg = WiseHudDB.barLayout
      cfg.powerR = math.floor(origR * 255 + 0.5)
      cfg.powerG = math.floor(origG * 255 + 0.5)
      cfg.powerB = math.floor(origB * 255 + 0.5)
      UpdatePowerColorSwatch()
      if WiseHudPower_UpdateColor then WiseHudPower_UpdateColor() end
    end
    
    if ColorPickerFrame.SetupColorPickerAndShow then
      ColorPickerFrame:SetupColorPickerAndShow({
        r = r,
        g = g,
        b = b,
        swatchFunc = UpdatePowerColor,
        cancelFunc = CancelPowerColor,
      })
    else
      ColorPickerFrame.func = UpdatePowerColor
      ColorPickerFrame.cancelFunc = CancelPowerColor
      ColorPickerFrame:SetColorRGB(r, g, b)
      ColorPickerFrame:Show()
    end
  end)

  -- ===== TAB 3: Cast Bar =====
  -- Cast enable/disable checkbox
  local castEnabledCheckbox = CreateFrame("CheckButton", "WiseHudCastEnabledCheckbox", castTab, "InterfaceOptionsCheckButtonTemplate")
  castEnabledCheckbox:SetPoint("TOPLEFT", 0, -20)
  _G[castEnabledCheckbox:GetName() .. "Text"]:SetText("Enable Cast Bar")
  WiseHudDB = WiseHudDB or {}
  WiseHudDB.castLayout = WiseHudDB.castLayout or {}
  local castCfg = WiseHudDB.castLayout
  castEnabledCheckbox:SetChecked(castCfg.enabled ~= false)
  
  castEnabledCheckbox:SetScript("OnClick", function(self)
    WiseHudDB = WiseHudDB or {}
    WiseHudDB.castLayout = WiseHudDB.castLayout or {}
    local cfg = WiseHudDB.castLayout
    cfg.enabled = self:GetChecked()
    if WiseHudCast_SetEnabled then
      WiseHudCast_SetEnabled(cfg.enabled)
    end
  end)

  -- Texture dropdowns (dynamic via LibSharedMedia-3.0 when available)
  local function GetStatusbarNames()
    local names = {}
    local nameSet = {} -- Use a set for faster duplicate checking
    
    -- Check if LibStub exists in global namespace
    local libStub = _G.LibStub
    if not libStub or type(libStub) ~= "table" or type(libStub.GetLibrary) ~= "function" then
      return names
    end
    
    -- Always try to get fresh LSM instance (in case it loads later)
    local currentLSM = libStub:GetLibrary("LibSharedMedia-3.0", true)
    
    if not currentLSM then
      return names
    end
    
    local mediatype = "statusbar"
    
    -- Method 1: Try direct access to MediaTable first (most reliable)
    -- LSM stores media in currentLSM.MediaTable[mediatype][name] = path
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
    
    -- Method 2: Try List() - this is the recommended way
    -- List() returns an array of texture names (sorted)
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
    
    -- Method 3: Try HashTable() - directly accesses MediaTable
    -- HashTable() returns mediaTable[mediatype] directly
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
    
    -- Sort the list alphabetically
    table.sort(names)
    return names
  end

  -- Texture (used for both fill and background)
  local textureLabel = castTab:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  textureLabel:SetPoint("TOPLEFT", castEnabledCheckbox, "BOTTOMLEFT", 0, -20)
  textureLabel:SetText("Texture:")

  local textureDropdown = CreateFrame("Frame", "WiseHudCastTextureDropdown", castTab, "UIDropDownMenuTemplate")
  textureDropdown:SetPoint("TOPLEFT", textureLabel, "BOTTOMLEFT", -16, -5)

  -- Default to Blizzard texture if nothing is set
  local currentTexture = castCfg.texture or castCfg.fillTexture or castCfg.bgTexture or "Blizzard"
  UIDropDownMenu_SetWidth(textureDropdown, 220)
  UIDropDownMenu_SetText(textureDropdown, currentTexture)

  local function RefreshTextureDropdown()
    -- Get fresh list of textures each time (in case LSM loads later)
    local statusbarNames = GetStatusbarNames()
    
    WiseHudDB = WiseHudDB or {}
    WiseHudDB.castLayout = WiseHudDB.castLayout or {}
    local cfg = WiseHudDB.castLayout
    local selected = cfg.texture or cfg.fillTexture or cfg.bgTexture or "Blizzard"
    
    -- Update dropdown text if selected texture is in the list
    local found = false
    for _, name in ipairs(statusbarNames) do
      if name == selected then
        found = true
        break
      end
    end
    if found then
      UIDropDownMenu_SetText(textureDropdown, selected)
    else
      -- Default to first available texture or "Blizzard" if list is empty
      UIDropDownMenu_SetText(textureDropdown, statusbarNames[1] or "Blizzard")
    end
  end

  -- Initialize dropdown menu
  local function InitializeTextureDropdown(self, level)
    -- Get fresh list of textures each time (in case LSM loads later)
    local statusbarNames = GetStatusbarNames()
    
    WiseHudDB = WiseHudDB or {}
    WiseHudDB.castLayout = WiseHudDB.castLayout or {}
    local cfg = WiseHudDB.castLayout
    local selected = cfg.texture or cfg.fillTexture or cfg.bgTexture or "Blizzard"

    -- If no textures found, try to get LSM directly and debug
    if #statusbarNames == 0 then
      -- Try one more time with direct access
      local lsm = nil
      local libStub = _G.LibStub
      if libStub and type(libStub) == "table" and type(libStub.GetLibrary) == "function" then
        lsm = libStub:GetLibrary("LibSharedMedia-3.0", true)
      end
      
      if lsm then
        -- Try direct access to MediaTable
        if lsm.MediaTable and lsm.MediaTable.statusbar then
          for name, path in pairs(lsm.MediaTable.statusbar) do
            if type(name) == "string" and name ~= "" then
              statusbarNames[#statusbarNames + 1] = name
            end
          end
          table.sort(statusbarNames)
        end
      end
      
      -- If still no textures, show error message with more info
      if #statusbarNames == 0 then
        local info = UIDropDownMenu_CreateInfo()
        local ok, status = CheckLSMAvailability()
        
        if ok then
          -- LSM is available but no textures found - this shouldn't happen
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
        UIDropDownMenu_SetSelectedValue(textureDropdown, textureName)
        UIDropDownMenu_SetText(textureDropdown, textureName)
        WiseHudDB = WiseHudDB or {}
        WiseHudDB.castLayout = WiseHudDB.castLayout or {}
        local cfg = WiseHudDB.castLayout
        -- Set texture for both fill and background
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

  -- Initialize dropdown menu
  UIDropDownMenu_Initialize(textureDropdown, InitializeTextureDropdown)
  
  -- Make sure the dropdown button works
  local textureDropdownButton = _G[textureDropdown:GetName() .. "Button"]
  if textureDropdownButton then
    -- Remove any existing OnClick handler
    textureDropdownButton:SetScript("OnClick", nil)
    -- Add our own handler
    textureDropdownButton:SetScript("OnClick", function(self)
      -- Re-initialize to get fresh texture list
      UIDropDownMenu_Initialize(textureDropdown, InitializeTextureDropdown)
      ToggleDropDownMenu(1, nil, textureDropdown, self, 0, 0)
    end)
  end
  
  -- Try to register for LSM callbacks if available
  local libStub = _G.LibStub
  if libStub and type(libStub) == "table" and type(libStub.GetLibrary) == "function" then
    local lsm = libStub:GetLibrary("LibSharedMedia-3.0", true)
    if lsm and lsm.RegisterCallback then
      lsm:RegisterCallback("LibSharedMedia_Registered", function(event, mediatype, key)
        if mediatype == "statusbar" then
          -- Refresh dropdown when new textures are registered
          RefreshTextureDropdown()
        end
      end)
    end
  end
  
  -- Initial refresh to set the correct texture name
  RefreshTextureDropdown()

  -- Cast Bar Settings
  local castLabel = castTab:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  castLabel:SetPoint("TOPLEFT", textureDropdown, "BOTTOMLEFT", 16, -15)
  castLabel:SetText("Cast Bar Position:")

  WiseHudDB = WiseHudDB or {}
  WiseHudDB.castLayout = WiseHudDB.castLayout or {}
  local castLayout = WiseHudDB.castLayout

  -- Cast Bar Width
  local castWidthSlider = CreateFrame("Slider", "WiseHudCastWidthSlider", castTab, "OptionsSliderTemplate")
  castWidthSlider:SetPoint("TOPLEFT", castLabel, "BOTTOMLEFT", 0, -20)
  castWidthSlider:SetMinMaxValues(100, 400)
  castWidthSlider:SetValueStep(5)
  castWidthSlider:SetObeyStepOnDrag(true)
  castWidthSlider:SetValue(castLayout.width or 200)
  _G[castWidthSlider:GetName() .. "Low"]:SetText("100")
  _G[castWidthSlider:GetName() .. "High"]:SetText("400")
  _G[castWidthSlider:GetName() .. "Text"]:SetText("Cast Width: " .. (castLayout.width or 200))

  castWidthSlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value + 0.5)
    WiseHudDB = WiseHudDB or {}
    WiseHudDB.castLayout = WiseHudDB.castLayout or {}
    local cfg = WiseHudDB.castLayout
    cfg.width = value
    _G[self:GetName() .. "Text"]:SetText("Cast Width: " .. value)
    if WiseHudCast_ApplyLayout then WiseHudCast_ApplyLayout() end
  end)

  -- Cast Bar Height
  local castHeightSlider = CreateFrame("Slider", "WiseHudCastHeightSlider", castTab, "OptionsSliderTemplate")
  castHeightSlider:SetPoint("TOPLEFT", castWidthSlider, "BOTTOMLEFT", 0, -24)
  castHeightSlider:SetMinMaxValues(10, 50)
  castHeightSlider:SetValueStep(1)
  castHeightSlider:SetObeyStepOnDrag(true)
  castHeightSlider:SetValue(castLayout.height or 20)
  _G[castHeightSlider:GetName() .. "Low"]:SetText("10")
  _G[castHeightSlider:GetName() .. "High"]:SetText("50")
  _G[castHeightSlider:GetName() .. "Text"]:SetText("Cast Height: " .. (castLayout.height or 20))

  castHeightSlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value + 0.5)
    WiseHudDB = WiseHudDB or {}
    WiseHudDB.castLayout = WiseHudDB.castLayout or {}
    local cfg = WiseHudDB.castLayout
    cfg.height = value
    _G[self:GetName() .. "Text"]:SetText("Cast Height: " .. value)
    if WiseHudCast_ApplyLayout then WiseHudCast_ApplyLayout() end
  end)

  -- Cast Bar X Offset
  local castXSlider = CreateFrame("Slider", "WiseHudCastXSlider", castTab, "OptionsSliderTemplate")
  castXSlider:SetPoint("TOPLEFT", castHeightSlider, "BOTTOMLEFT", 0, -24)
  castXSlider:SetMinMaxValues(-400, 400)
  castXSlider:SetValueStep(5)
  castXSlider:SetObeyStepOnDrag(true)
  castXSlider:SetValue(castLayout.offsetX or 0)
  _G[castXSlider:GetName() .. "Low"]:SetText("-400")
  _G[castXSlider:GetName() .. "High"]:SetText("400")
  _G[castXSlider:GetName() .. "Text"]:SetText("Cast X: " .. (castLayout.offsetX or 0))

  castXSlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value + 0.5)
    WiseHudDB = WiseHudDB or {}
    WiseHudDB.castLayout = WiseHudDB.castLayout or {}
    local cfg = WiseHudDB.castLayout
    cfg.offsetX = value
    _G[self:GetName() .. "Text"]:SetText("Cast X: " .. value)
    if WiseHudCast_ApplyLayout then WiseHudCast_ApplyLayout() end
  end)

  -- Cast Bar Y Offset
  local castYSlider = CreateFrame("Slider", "WiseHudCastYSlider", castTab, "OptionsSliderTemplate")
  castYSlider:SetPoint("TOPLEFT", castXSlider, "BOTTOMLEFT", 0, -24)
  castYSlider:SetMinMaxValues(-400, 400)
  castYSlider:SetValueStep(5)
  castYSlider:SetObeyStepOnDrag(true)
  castYSlider:SetValue(castLayout.offsetY or -200)
  _G[castYSlider:GetName() .. "Low"]:SetText("-400")
  _G[castYSlider:GetName() .. "High"]:SetText("400")
  _G[castYSlider:GetName() .. "Text"]:SetText("Cast Y: " .. (castLayout.offsetY or -200))

  castYSlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value + 0.5)
    WiseHudDB = WiseHudDB or {}
    WiseHudDB.castLayout = WiseHudDB.castLayout or {}
    local cfg = WiseHudDB.castLayout
    cfg.offsetY = value
    _G[self:GetName() .. "Text"]:SetText("Cast Y: " .. value)
    if WiseHudCast_ApplyLayout then WiseHudCast_ApplyLayout() end
  end)

  -- Show Text Checkbox
  local showTextCheck = CreateFrame("CheckButton", "WiseHudCastShowTextCheck", castTab, "InterfaceOptionsCheckButtonTemplate")
  showTextCheck:SetPoint("TOPLEFT", castYSlider, "BOTTOMLEFT", 0, -30)
  _G[showTextCheck:GetName() .. "Text"]:SetText("Show Spell Name")
  showTextCheck:SetChecked(castLayout.showText ~= false) -- Default to true
  
  showTextCheck:SetScript("OnClick", function(self)
    WiseHudDB = WiseHudDB or {}
    WiseHudDB.castLayout = WiseHudDB.castLayout or {}
    local cfg = WiseHudDB.castLayout
    cfg.showText = self:GetChecked()
    if WiseHudCast_ApplyLayout then WiseHudCast_ApplyLayout() end
  end)

  -- Fill Color Settings
  local fillColorLabel = castTab:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  fillColorLabel:SetPoint("TOPLEFT", showTextCheck, "BOTTOMLEFT", 0, -20)
  fillColorLabel:SetText("Fill Color:")

  -- Fill Color Button
  local fillColorButton = CreateFrame("Button", "WiseHudCastFillColorButton", castTab, "UIPanelButtonTemplate")
  fillColorButton:SetSize(120, 30)
  fillColorButton:SetPoint("TOPLEFT", fillColorLabel, "BOTTOMLEFT", 0, -10)
  fillColorButton:SetText("Pick Color")
  
  local fillColorSwatch = fillColorButton:CreateTexture(nil, "OVERLAY")
  fillColorSwatch:SetSize(20, 20)
  fillColorSwatch:SetPoint("LEFT", fillColorButton, "LEFT", 5, 0)
  fillColorSwatch:SetTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
  
  local fillColorTexture = fillColorButton:CreateTexture(nil, "ARTWORK")
  fillColorTexture:SetSize(16, 16)
  fillColorTexture:SetPoint("CENTER", fillColorSwatch, "CENTER", 0, 0)
  fillColorTexture:SetTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
  fillColorTexture:Show()
  
  local function UpdateFillColorSwatch()
    if not fillColorTexture then return end
    WiseHudDB = WiseHudDB or {}
    WiseHudDB.castLayout = WiseHudDB.castLayout or {}
    local cfg = WiseHudDB.castLayout
    local r = (cfg.fillR or 242) / 255
    local g = (cfg.fillG or 242) / 255
    local b = (cfg.fillB or 10) / 255
    fillColorTexture:SetVertexColor(r, g, b)
    fillColorTexture:Show()
  end
  UpdateFillColorSwatch()
  
  fillColorButton:SetScript("OnClick", function()
    local r = (castLayout.fillR or 242) / 255
    local g = (castLayout.fillG or 242) / 255
    local b = (castLayout.fillB or 10) / 255
    
    -- Store original values for cancel (capture in closure)
    local origR, origG, origB = r, g, b
    
    -- Helper function to update color
    local function UpdateFillColor()
      -- Read color values - try method first, then fallback to fields
      local newR, newG, newB
      if ColorPickerFrame.GetColorRGB then
        local ok, rVal, gVal, bVal = pcall(ColorPickerFrame.GetColorRGB, ColorPickerFrame)
        if ok then
          newR, newG, newB = rVal, gVal, bVal
        else
          newR = ColorPickerFrame.r or r
          newG = ColorPickerFrame.g or g
          newB = ColorPickerFrame.b or b
        end
      else
        -- Fallback: read from internal fields
        newR = ColorPickerFrame.r or r
        newG = ColorPickerFrame.g or g
        newB = ColorPickerFrame.b or b
      end
      
      WiseHudDB = WiseHudDB or {}
      WiseHudDB.castLayout = WiseHudDB.castLayout or {}
      local cfg = WiseHudDB.castLayout
      cfg.fillR = math.floor(newR * 255 + 0.5)
      cfg.fillG = math.floor(newG * 255 + 0.5)
      cfg.fillB = math.floor(newB * 255 + 0.5)
      UpdateFillColorSwatch()
      if WiseHudCast_UpdateColors then WiseHudCast_UpdateColors() end
    end
    
    -- Cancel function to restore original values
    local function CancelFillColor()
      WiseHudDB = WiseHudDB or {}
      WiseHudDB.castLayout = WiseHudDB.castLayout or {}
      local cfg = WiseHudDB.castLayout
      cfg.fillR = math.floor(origR * 255 + 0.5)
      cfg.fillG = math.floor(origG * 255 + 0.5)
      cfg.fillB = math.floor(origB * 255 + 0.5)
      UpdateFillColorSwatch()
      if WiseHudCast_UpdateColors then WiseHudCast_UpdateColors() end
    end
    
    -- Set color using internal fields
    ColorPickerFrame.r = r
    ColorPickerFrame.g = g
    ColorPickerFrame.b = b
    ColorPickerFrame.hasOpacity = false
    
    -- Try to set color using available method
    if ColorPickerFrame.SetColorRGB then
      pcall(ColorPickerFrame.SetColorRGB, ColorPickerFrame, r, g, b)
    end
    
    -- Use swatchFunc for real-time updates if available (newer API)
    if ColorPickerFrame.SetupColorPickerAndShow then
      ColorPickerFrame:SetupColorPickerAndShow({
        swatchFunc = UpdateFillColor,
        hasOpacity = false,
        r = r,
        g = g,
        b = b,
        cancelFunc = CancelFillColor,
      })
    else
      -- Fallback to older API
      ColorPickerFrame.func = UpdateFillColor
      ColorPickerFrame.cancelFunc = CancelFillColor
      ColorPickerFrame:Show()
    end
  end)

  -- Background Color Settings
  local bgColorLabel = castTab:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  bgColorLabel:SetPoint("TOPLEFT", fillColorButton, "BOTTOMLEFT", 0, -20)
  bgColorLabel:SetText("Background Color:")

  -- Background Color Button
  local bgColorButton = CreateFrame("Button", "WiseHudCastBgColorButton", castTab, "UIPanelButtonTemplate")
  bgColorButton:SetSize(120, 30)
  bgColorButton:SetPoint("TOPLEFT", bgColorLabel, "BOTTOMLEFT", 0, -10)
  bgColorButton:SetText("Pick Color")
  
  local bgColorSwatch = bgColorButton:CreateTexture(nil, "OVERLAY")
  bgColorSwatch:SetSize(20, 20)
  bgColorSwatch:SetPoint("LEFT", bgColorButton, "LEFT", 5, 0)
  bgColorSwatch:SetTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
  
  local bgColorTexture = bgColorButton:CreateTexture(nil, "ARTWORK")
  bgColorTexture:SetSize(16, 16)
  bgColorTexture:SetPoint("CENTER", bgColorSwatch, "CENTER", 0, 0)
  bgColorTexture:SetTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
  bgColorTexture:Show()
  
  local function UpdateBgColorSwatch()
    if not bgColorTexture then return end
    WiseHudDB = WiseHudDB or {}
    WiseHudDB.castLayout = WiseHudDB.castLayout or {}
    local cfg = WiseHudDB.castLayout
    local r = (cfg.bgR or 77) / 255
    local g = (cfg.bgG or 77) / 255
    local b = (cfg.bgB or 77) / 255
    bgColorTexture:SetVertexColor(r, g, b)
    bgColorTexture:Show()
  end
  UpdateBgColorSwatch()
  
  bgColorButton:SetScript("OnClick", function()
    local r = (castLayout.bgR or 77) / 255
    local g = (castLayout.bgG or 77) / 255
    local b = (castLayout.bgB or 77) / 255
    local a = (castLayout.bgA or 80) / 100
    
    -- Store original values for cancel (capture in closure)
    local origR, origG, origB, origA = r, g, b, a
    
    -- Helper function to update color
    local function UpdateBgColor()
      -- Read color values - try method first, then fallback to fields
      local newR, newG, newB
      if ColorPickerFrame.GetColorRGB then
        local ok, rVal, gVal, bVal = pcall(ColorPickerFrame.GetColorRGB, ColorPickerFrame)
        if ok then
          newR, newG, newB = rVal, gVal, bVal
        else
          newR = ColorPickerFrame.r or r
          newG = ColorPickerFrame.g or g
          newB = ColorPickerFrame.b or b
        end
      else
        -- Fallback: read from internal fields
        newR = ColorPickerFrame.r or r
        newG = ColorPickerFrame.g or g
        newB = ColorPickerFrame.b or b
      end
      
      -- Read opacity/alpha value
      -- Note: OpacitySliderFrame:GetValue() returns alpha (0-1) directly
      -- where 0 = fully transparent, 1 = fully opaque
      -- GetColorAlpha() also returns alpha (0-1) directly
      -- ColorPickerFrame.opacity stores (1 - alpha)
      local newA
      -- Priority: OpacitySliderFrame (most reliable) > GetColorAlpha > GetOpacity > fallback
      if OpacitySliderFrame and OpacitySliderFrame.GetValue then
        -- OpacitySliderFrame:GetValue() returns alpha directly (like IceHUD line 98, 105)
        newA = OpacitySliderFrame:GetValue()
      elseif ColorPickerFrame.GetColorAlpha then
        -- GetColorAlpha() returns alpha directly (like IceHUD line 73, 80)
        local ok, alphaVal = pcall(ColorPickerFrame.GetColorAlpha, ColorPickerFrame)
        if ok then
          newA = alphaVal
        else
          -- Fallback: read from opacity field (opacity = 1 - alpha)
          newA = 1 - (ColorPickerFrame.opacity or (1 - a))
        end
      elseif ColorPickerFrame.GetOpacity then
        local ok, opacityVal = pcall(ColorPickerFrame.GetOpacity, ColorPickerFrame)
        if ok then
          -- GetOpacity returns opacity (1 - alpha), so convert to alpha
          newA = 1 - opacityVal
        else
          newA = 1 - (ColorPickerFrame.opacity or (1 - a))
        end
      else
        -- Fallback: read from internal field (opacity is stored as 1 - alpha)
        newA = 1 - (ColorPickerFrame.opacity or (1 - a))
      end
      -- Ensure alpha is in valid range (0-1), allowing 0 for fully transparent
      newA = math.max(0, math.min(1, newA))
      
      WiseHudDB = WiseHudDB or {}
      WiseHudDB.castLayout = WiseHudDB.castLayout or {}
      local cfg = WiseHudDB.castLayout
      cfg.bgR = math.floor(newR * 255 + 0.5)
      cfg.bgG = math.floor(newG * 255 + 0.5)
      cfg.bgB = math.floor(newB * 255 + 0.5)
      cfg.bgA = math.floor(newA * 100 + 0.5)
      UpdateBgColorSwatch()
      if WiseHudCast_UpdateColors then WiseHudCast_UpdateColors() end
    end
    
    -- Cancel function to restore original values
    local function CancelBgColor()
      WiseHudDB = WiseHudDB or {}
      WiseHudDB.castLayout = WiseHudDB.castLayout or {}
      local cfg = WiseHudDB.castLayout
      cfg.bgR = math.floor(origR * 255 + 0.5)
      cfg.bgG = math.floor(origG * 255 + 0.5)
      cfg.bgB = math.floor(origB * 255 + 0.5)
      cfg.bgA = math.floor(origA * 100 + 0.5)
      UpdateBgColorSwatch()
      if WiseHudCast_UpdateColors then WiseHudCast_UpdateColors() end
    end
    
    -- Set color using internal fields
    ColorPickerFrame.r = r
    ColorPickerFrame.g = g
    ColorPickerFrame.b = b
    ColorPickerFrame.opacity = 1 - a
    ColorPickerFrame.hasOpacity = true
    
    -- Try to set color using available method
    if ColorPickerFrame.SetColorRGB then
      pcall(ColorPickerFrame.SetColorRGB, ColorPickerFrame, r, g, b)
    end
    if ColorPickerFrame.SetOpacity then
      pcall(ColorPickerFrame.SetOpacity, ColorPickerFrame, 1 - a)
    end
    -- Ensure OpacitySliderFrame allows 0 (fully transparent)
    -- Note: OpacitySliderFrame:SetValue() expects alpha (0-1), not opacity
    if OpacitySliderFrame and OpacitySliderFrame.SetMinMaxValues then
      OpacitySliderFrame:SetMinMaxValues(0, 1)
      OpacitySliderFrame:SetValue(a)
    end
    
    -- Use swatchFunc for real-time updates if available (newer API)
    if ColorPickerFrame.SetupColorPickerAndShow then
      ColorPickerFrame:SetupColorPickerAndShow({
        swatchFunc = UpdateBgColor,
        hasOpacity = true,
        opacityFunc = UpdateBgColor,
        r = r,
        g = g,
        b = b,
        opacity = 1 - a,
        cancelFunc = CancelBgColor,
      })
    else
      -- Fallback to older API
      ColorPickerFrame.func = UpdateBgColor
      ColorPickerFrame.opacityFunc = UpdateBgColor
      ColorPickerFrame.cancelFunc = CancelBgColor
      ColorPickerFrame:Show()
    end
  end)

  panel.refresh = function()
    -- Refresh texture dropdown when panel is opened (LSM might have loaded)
    if RefreshTextureDropdown then
      RefreshTextureDropdown()
    end
    -- Re-initialize dropdown to ensure it works
    if textureDropdown then
      UIDropDownMenu_Initialize(textureDropdown, InitializeTextureDropdown)
    end
    -- Update color swatches when options panel is opened
    if UpdateFillColorSwatch then UpdateFillColorSwatch() end
    if UpdateBgColorSwatch then UpdateBgColorSwatch() end
    if UpdateHealthColorSwatch then UpdateHealthColorSwatch() end
    if UpdatePowerColorSwatch then UpdatePowerColorSwatch() end
    -- Refresh model ID input field with current value
    if modelIdEditBox and SetModelIdText then
      SetModelIdText()
    end
  end
  
  panel.okay = function()
    -- Called automatically by OnValueChanged handlers
  end

  panel.default = function()
    -- Reset Combo Points
    local comboCfg = ensureComboTable()
    comboCfg.x = nil
    comboCfg.y = nil
    comboCfg.radius = nil
    comboCfg.cameraX = nil
    comboCfg.cameraY = nil
    comboCfg.cameraZ = nil
    comboCfg.enabled = nil
    comboCfg.testMode = nil
    comboCfg.modelId = nil
    comboXSlider:SetValue(0)
    comboYSlider:SetValue(-60)
    comboRadiusSlider:SetValue(50)
    if cameraXSlider then cameraXSlider:SetValue(-1.2) end
    if cameraYSlider then cameraYSlider:SetValue(0.0) end
    if cameraZSlider then cameraZSlider:SetValue(0.0) end
    comboEnabledCheckbox:SetChecked(true)
    if testModeCheckbox then testModeCheckbox:SetChecked(false) end
    if modelIdEditBox then
      local defaultId = GetDefaultModelId()
      modelIdEditBox:SetText(tostring(defaultId))
    end
    if WiseHudOrbs_SetEnabled then WiseHudOrbs_SetEnabled(true) end
    if WiseHudOrbs_ApplyLayout then WiseHudOrbs_ApplyLayout() end
    
    -- Reset Health/Power
    local healthCfg = ensureLayoutTable()
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
    widthSlider:SetValue(260)
    heightSlider:SetValue(415)
    offsetSlider:SetValue(185)
    offsetYSlider:SetValue(90)
    healthEnabledCheckbox:SetChecked(true)
    powerEnabledCheckbox:SetChecked(true)
    if WiseHudHealth_SetEnabled then WiseHudHealth_SetEnabled(true) end
    if WiseHudPower_SetEnabled then WiseHudPower_SetEnabled(true) end
    if WiseHudHealth_ApplyLayout then WiseHudHealth_ApplyLayout() end
    if WiseHudPower_ApplyLayout then WiseHudPower_ApplyLayout() end
    
    -- Reset Cast Bar
    WiseHudDB = WiseHudDB or {}
    WiseHudDB.castLayout = WiseHudDB.castLayout or {}
    local castCfg = WiseHudDB.castLayout
    castCfg.width = nil
    castCfg.height = nil
    castCfg.offsetX = nil
    castCfg.offsetY = nil
    castCfg.enabled = nil
    castCfg.texture = nil -- legacy
    castCfg.fillTexture = nil
    castCfg.bgTexture = nil
    castCfg.fillR = nil
    castCfg.fillG = nil
    castCfg.fillB = nil
    castCfg.bgR = nil
    castCfg.bgG = nil
    castCfg.bgB = nil
    castCfg.bgA = nil
    castCfg.showText = nil
    if castWidthSlider then castWidthSlider:SetValue(200) end
    if castHeightSlider then castHeightSlider:SetValue(20) end
    if castXSlider then castXSlider:SetValue(0) end
    if castYSlider then castYSlider:SetValue(-200) end
    if castEnabledCheckbox then castEnabledCheckbox:SetChecked(true) end
    if showTextCheck then showTextCheck:SetChecked(true) end
    if textureDropdown then
      UIDropDownMenu_SetText(textureDropdown, "Blizzard")
      UIDropDownMenu_SetSelectedValue(textureDropdown, "Blizzard")
    end
    castCfg.texture = nil
    castCfg.fillR = nil
    castCfg.fillG = nil
    castCfg.fillB = nil
    castCfg.bgR = nil
    castCfg.bgG = nil
    castCfg.bgB = nil
    castCfg.bgA = nil
    if fillColorButton then
      UpdateFillColorSwatch()
    end
    if bgColorButton then
      UpdateBgColorSwatch()
    end
    if WiseHudCast_SetEnabled then WiseHudCast_SetEnabled(true) end
    if WiseHudCast_UpdateTexture then WiseHudCast_UpdateTexture() end
    if WiseHudCast_UpdateColors then WiseHudCast_UpdateColors() end
    if WiseHudCast_ApplyLayout then WiseHudCast_ApplyLayout() end
  end

  local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name, panel.name)
  category.ID = panel.name
  Settings.RegisterAddOnCategory(category)

  WiseHudOptionsCategory = category
end

function WiseHudOptions_OnPlayerLogin()
  CreateOptionsPanel()
end

