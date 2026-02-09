local ADDON_NAME = ...

-- Helper functions for Options UI elements and database access

-- Database helper functions
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

-- Standard padding for option section contents
local SECTION_PADDING_LEFT = 12
local SECTION_PADDING_RIGHT = 12
local SECTION_PADDING_TOP = 12
local SECTION_PADDING_BOTTOM = 12

-- UI Element Helper Functions

local function CreateSlider(parent, name, label, minVal, maxVal, step, defaultValue, textFormat, onChangeCallback)
  -- Create container frame for label and slider
  local container = CreateFrame("Frame", name .. "Container", parent)
  container:SetSize(400, 50)
  
  -- Make container wider to accommodate edit box
  container:SetWidth(480)
  
  -- Store initial min/max for reference
  container.initialMin = minVal
  container.initialMax = maxVal
  container.currentMin = minVal
  container.currentMax = maxVal
  container.step = step
  container.textFormat = textFormat
  
  -- Label above slider
  local labelText = container:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  labelText:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
  labelText:SetTextColor(1, 1, 1)
  labelText:SetText(label)
  container.label = labelText
  
  -- Value display next to label
  local valueText = container:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  valueText:SetPoint("LEFT", labelText, "RIGHT", 10, 0)
  valueText:SetTextColor(1, 0.82, 0)
  container.valueText = valueText
  
  -- EditBox for direct value input (will be positioned after slider is created)
  local editBox = CreateFrame("EditBox", name .. "EditBox", container, "InputBoxTemplate")
  editBox:SetSize(80, 20)
  editBox:SetAutoFocus(false)
  -- Don't use SetNumeric(true) as it blocks negative numbers (the minus sign)
  -- We'll validate manually in the handlers instead
  editBox:SetJustifyH("CENTER")
  editBox:Show() -- Ensure it's visible
  editBox:Enable() -- Ensure it's enabled
  container.editBox = editBox
  
  -- Add input validation to allow numbers, decimal point, minus sign, and percent sign
  -- This replaces SetNumeric(true) which blocks negative numbers
  -- Note: The "%" sign is allowed but will be removed when parsing the value
  editBox:SetScript("OnChar", function(self, char)
    local text = self:GetText() or ""
    local cursorPos = self:GetCursorPosition()
    
    -- Remove "%" from text for validation (it's allowed but not part of the number)
    local textForValidation = text:gsub("%%", "")
    
    -- Validate the text after the character was inserted
    -- Allow: empty, "-", ".", "-.", digits, "-digits", "digits.digits", "-digits.digits"
    -- Also allow "%" at the end (will be removed when parsing)
    local isValid = false
    
    if textForValidation == "" or textForValidation == "-" or textForValidation == "." or textForValidation == "-." then
      -- Allow partial input during typing
      isValid = true
    elseif textForValidation:match("^-?%d+$") then
      -- Integer (with optional minus): -123, 123
      isValid = true
    elseif textForValidation:match("^-?%d+%.%d*$") then
      -- Decimal with digits before dot: 12.34, -12.34, 12.
      isValid = true
    elseif textForValidation:match("^-?%.%d+$") then
      -- Decimal starting with dot: .5, -.5
      isValid = true
    end
    
    -- Also allow "%" character (will be removed when parsing)
    if char == "%" then
      isValid = true
    end
    
    if not isValid then
      -- Invalid input - remove the character that was just added
      local beforeChar = text:sub(1, cursorPos - 1)
      local afterChar = text:sub(cursorPos + 1)
      self:SetText(beforeChar .. afterChar)
      self:SetCursorPosition(cursorPos - 1)
    end
  end)
  
  -- Function to update slider range if value is outside current range
  local function ExpandSliderRange(value)
    local newMin = container.currentMin
    local newMax = container.currentMax
    local expanded = false
    
    if value < container.currentMin then
      newMin = math.floor(value / step) * step - (step * 2) -- Add some padding
      expanded = true
    elseif value > container.currentMax then
      newMax = math.ceil(value / step) * step + (step * 2) -- Add some padding
      expanded = true
    end
    
    if expanded then
      container.currentMin = newMin
      container.currentMax = newMax
      local slider = container.slider
      slider:SetMinMaxValues(newMin, newMax)
      _G[slider:GetName() .. "Low"]:SetText(tostring(newMin))
      _G[slider:GetName() .. "High"]:SetText(tostring(newMax))
    end
  end
  
  -- Function to update display and edit box
  local function UpdateDisplay(value)
    -- Ensure value is a number
    value = tonumber(value) or 0
    
    local displayText = textFormat and string.format(textFormat, value) or tostring(value)
    if valueText then
      valueText:SetText(displayText)
    end
    
    -- Update edit box - always use raw value without format for easier editing
    -- The format (like "%d%%" or "%.1f") is only for display, not for input
    -- This allows users to type numbers without special characters like "%"
    local editBoxText
    -- Always show raw number in edit box, regardless of format
    -- This makes it easier to edit, especially for percentages
    if value == math.floor(value) then
      -- Integer value (including negative integers)
      editBoxText = tostring(math.floor(value))
    else
      -- Decimal value (including negative decimals)
      editBoxText = tostring(value)
    end
    
    if editBox then
      -- Always set text, even if it's "0", negative, or decimal
      -- Force set the text to ensure it updates, especially for negative and decimal values
      editBox:SetText(editBoxText)
      editBox:SetCursorPosition(0)
      
      -- Ensure edit box is visible and enabled
      if not editBox:IsShown() then
        editBox:Show()
      end
      if not editBox:IsEnabled() then
        editBox:Enable()
      end
    end
  end
  
  -- Slider
  local slider = CreateFrame("Slider", name, container, "OptionsSliderTemplate")
  slider:SetPoint("TOPLEFT", labelText, "BOTTOMLEFT", 0, -8)
  slider:SetPoint("RIGHT", container, "RIGHT", -90, 0) -- Leave space for edit box
  slider:SetMinMaxValues(minVal, maxVal)
  slider:SetValueStep(step)
  slider:SetObeyStepOnDrag(true)
  
  -- Store slider reference in container BEFORE calling ExpandSliderRange
  container.slider = slider
  
  -- Position edit box to the right of slider
  editBox:SetPoint("LEFT", slider, "RIGHT", 10, 0)
  
  -- Set initial value, expanding range if needed
  -- Handle both nil and numeric values (0 is valid)
  local initialValue = defaultValue
  if initialValue == nil then
    initialValue = minVal
  end
  
  -- Ensure initialValue is a number
  initialValue = tonumber(initialValue) or minVal
  
  -- Expand range BEFORE setting up the slider to ensure the value fits
  ExpandSliderRange(initialValue)
  
  -- Ensure slider range matches the expanded range
  slider:SetMinMaxValues(container.currentMin, container.currentMax)
  
  -- Min/Max labels
  _G[slider:GetName() .. "Low"]:SetText(tostring(container.currentMin))
  _G[slider:GetName() .. "High"]:SetText(tostring(container.currentMax))
  _G[slider:GetName() .. "Text"]:Hide() -- Hide default text, we use our own
  
  -- Set up OnValueChanged handler BEFORE setting initial value
  slider:SetScript("OnValueChanged", function(self, value)
    local roundedValue
    if step < 1 then
      roundedValue = math.floor(value / step + 0.5) * step
    else
      roundedValue = math.floor(value + 0.5)
    end
    
    UpdateDisplay(roundedValue)
    
    if onChangeCallback then
      onChangeCallback(self, roundedValue)
    end
  end)
  
  -- Round initial value to step before setting
  local roundedInitialValue
  if step < 1 then
    roundedInitialValue = math.floor(initialValue / step + 0.5) * step
  else
    roundedInitialValue = math.floor(initialValue + 0.5)
  end
  
  -- Ensure rounded value is within the expanded range
  roundedInitialValue = math.max(container.currentMin, math.min(container.currentMax, roundedInitialValue))
  
  -- Prepare edit box text BEFORE setting slider value
  -- This ensures we have the correct text ready, especially for negative and decimal values
  local editBoxText
  if textFormat then
    editBoxText = string.format(textFormat, roundedInitialValue)
  else
    editBoxText = tostring(roundedInitialValue)
  end
  
  -- Set the edit box text FIRST, before setting the slider value
  -- This ensures negative and decimal values are displayed correctly from the start
  if editBox then
    editBox:SetText(editBoxText)
    editBox:SetCursorPosition(0)
    if not editBox:IsShown() then
      editBox:Show()
    end
    if not editBox:IsEnabled() then
      editBox:Enable()
    end
  end
  
  -- Set initial value AFTER setting up the handler and ensuring range is correct
  -- The OnValueChanged handler will be triggered, but we've already set the edit box
  slider:SetValue(roundedInitialValue)
  
  -- Immediately update display with the initial value (after slider is set)
  -- This ensures everything is in sync, especially for negative and decimal values
  UpdateDisplay(roundedInitialValue)
  
  -- Get the actual value from the slider (in case it was clamped or adjusted)
  -- Use a small delay to ensure the slider has processed the value change
  -- This is especially important for negative and decimal values
  C_Timer.After(0.01, function()
    if slider and editBox and container then
      local actualSliderValue = slider:GetValue()
      local roundedActualValue
      if step < 1 then
        roundedActualValue = math.floor(actualSliderValue / step + 0.5) * step
      else
        roundedActualValue = math.floor(actualSliderValue + 0.5)
      end
      
      -- Check if edit box text matches the slider value
      local currentText = editBox:GetText() or ""
      local currentNum = tonumber(currentText)
      
      -- Always update if the value doesn't match or if edit box is empty
      -- This is critical for negative and decimal values
      if currentText == "" or currentNum == nil or math.abs(currentNum - roundedActualValue) > 0.001 then
        UpdateDisplay(roundedActualValue)
      end
    end
  end)
  
  -- Force edit box update with multiple delays to catch any edge cases
  -- Some edit boxes might not be ready immediately, especially for negative and decimal values
  -- Always update to ensure negative and decimal values are displayed correctly
  C_Timer.After(0.05, function()
    if editBox and slider and container then
      local currentValue = slider:GetValue()
      local roundedCurrentValue
      if step < 1 then
        roundedCurrentValue = math.floor(currentValue / step + 0.5) * step
      else
        roundedCurrentValue = math.floor(currentValue + 0.5)
      end
      local currentText = editBox:GetText() or ""
      local currentNum = tonumber(currentText)
      
      -- Always update if empty, nil, or doesn't match slider value
      -- This is especially important for negative and decimal values
      -- Force update by always calling UpdateDisplay to ensure consistency
      if currentText == "" or currentText == nil or currentNum == nil or (currentNum and math.abs(currentNum - roundedCurrentValue) > 0.001) then
        UpdateDisplay(roundedCurrentValue)
        -- Also explicitly set the text to be absolutely sure
        if editBox then
          local editBoxText
          if textFormat then
            editBoxText = string.format(textFormat, roundedCurrentValue)
          else
            editBoxText = tostring(roundedCurrentValue)
          end
          editBox:SetText(editBoxText)
          editBox:SetCursorPosition(0)
        end
      end
    end
  end)
  
  C_Timer.After(0.15, function()
    if editBox and slider and container then
      local currentValue = slider:GetValue()
      local roundedCurrentValue
      if step < 1 then
        roundedCurrentValue = math.floor(currentValue / step + 0.5) * step
      else
        roundedCurrentValue = math.floor(currentValue + 0.5)
      end
      local currentText = editBox:GetText() or ""
      local currentNum = tonumber(currentText)
      
      -- Always update if empty, nil, or doesn't match slider value
      -- This is especially important for negative and decimal values
      -- Force update by always calling UpdateDisplay to ensure consistency
      if currentText == "" or currentText == nil or currentNum == nil or (currentNum and math.abs(currentNum - roundedCurrentValue) > 0.001) then
        UpdateDisplay(roundedCurrentValue)
        -- Also explicitly set the text to be absolutely sure
        if editBox then
          local editBoxText
          if textFormat then
            editBoxText = string.format(textFormat, roundedCurrentValue)
          else
            editBoxText = tostring(roundedCurrentValue)
          end
          editBox:SetText(editBoxText)
          editBox:SetCursorPosition(0)
        end
      end
    end
  end)
  
  -- Also update when the frame is shown (in case it's created while hidden)
  container:SetScript("OnShow", function()
    if editBox and slider then
      -- Use a small delay to ensure everything is ready
      -- This is critical for negative and decimal values
      C_Timer.After(0.01, function()
        if editBox and slider and container then
          local currentValue = slider:GetValue()
          local roundedCurrentValue
          if step < 1 then
            roundedCurrentValue = math.floor(currentValue / step + 0.5) * step
          else
            roundedCurrentValue = math.floor(currentValue + 0.5)
          end
          -- Always update to ensure edit box matches slider value
          -- This fixes cases where the edit box might have an old/stale value or be empty
          UpdateDisplay(roundedCurrentValue)
          -- Also explicitly set the text to be absolutely sure, especially for negative and decimal values
          if editBox then
            local editBoxText
            if textFormat then
              editBoxText = string.format(textFormat, roundedCurrentValue)
            else
              editBoxText = tostring(roundedCurrentValue)
            end
            editBox:SetText(editBoxText)
            editBox:SetCursorPosition(0)
          end
        end
      end)
    end
  end)
  
  -- EditBox handlers
  editBox:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
    local text = self:GetText() or ""
    text = strtrim(text)
    -- Remove any format characters like "%" before parsing
    text = text:gsub("%%", "")
    local numValue = tonumber(text)
    
    if numValue then
      -- Expand range if needed
      ExpandSliderRange(numValue)
      
      -- Round to step
      local roundedValue
      if step < 1 then
        roundedValue = math.floor(numValue / step + 0.5) * step
      else
        roundedValue = math.floor(numValue + 0.5)
      end
      
      -- Update slider
      slider:SetValue(roundedValue)
      UpdateDisplay(roundedValue)
      
      if onChangeCallback then
        onChangeCallback(slider, roundedValue)
      end
    else
      -- Invalid input, restore current value
      UpdateDisplay(slider:GetValue())
    end
  end)
  
  editBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
    UpdateDisplay(slider:GetValue())
  end)
  
  editBox:SetScript("OnEditFocusLost", function(self)
    local text = self:GetText() or ""
    text = strtrim(text)
    -- Remove any format characters like "%" before parsing
    text = text:gsub("%%", "")
    local numValue = tonumber(text)
    
    if numValue then
      ExpandSliderRange(numValue)
      local roundedValue
      if step < 1 then
        roundedValue = math.floor(numValue / step + 0.5) * step
      else
        roundedValue = math.floor(numValue + 0.5)
      end
      slider:SetValue(roundedValue)
      UpdateDisplay(roundedValue)
      if onChangeCallback then
        onChangeCallback(slider, roundedValue)
      end
    else
      UpdateDisplay(slider:GetValue())
    end
  end)
  
  -- Slider reference already set earlier, just store the functions
  container.UpdateDisplay = UpdateDisplay
  container.ExpandSliderRange = ExpandSliderRange
  return container
end

local function CreateCheckbox(parent, name, label, defaultValue, onChangeCallback)
  local checkbox = CreateFrame("CheckButton", name, parent, "InterfaceOptionsCheckButtonTemplate")
  _G[checkbox:GetName() .. "Text"]:SetText(label)
  checkbox:SetChecked(defaultValue ~= false)
  
  checkbox:SetScript("OnClick", function(self)
    if onChangeCallback then
      onChangeCallback(self, self:GetChecked())
    end
  end)
  
  return checkbox
end

-- Create a section frame with background and border for grouping controls
local function CreateSectionFrame(parent, name, title, width, height)
  local section = CreateFrame("Frame", name, parent)
  section:SetSize(width or 500, height or 100)
  
  -- Expose standard inner padding so sections can place their first child consistently
  section.paddingLeft = SECTION_PADDING_LEFT
  section.paddingRight = SECTION_PADDING_RIGHT
  section.paddingTop = SECTION_PADDING_TOP
  section.paddingBottom = SECTION_PADDING_BOTTOM
  
  -- Title (created outside/above the section frame so it's not hidden behind borders)
  local titleText = nil
  if title then
    titleText = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    titleText:SetTextColor(1, 0.82, 0)
    titleText:SetText(title)
    section.title = titleText
  end
  
  -- Background
  local bg = section:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints(section)
  bg:SetColorTexture(0.15, 0.15, 0.15, 0.6)
  section.bg = bg
  
  -- Border lines
  local borderTop = section:CreateTexture(nil, "BORDER")
  borderTop:SetPoint("TOPLEFT", section, "TOPLEFT", 0, 0)
  borderTop:SetPoint("TOPRIGHT", section, "TOPRIGHT", 0, 0)
  borderTop:SetHeight(1)
  borderTop:SetColorTexture(0.4, 0.4, 0.4, 0.8)
  
  local borderBottom = section:CreateTexture(nil, "BORDER")
  borderBottom:SetPoint("BOTTOMLEFT", section, "BOTTOMLEFT", 0, 0)
  borderBottom:SetPoint("BOTTOMRIGHT", section, "BOTTOMRIGHT", 0, 0)
  borderBottom:SetHeight(1)
  borderBottom:SetColorTexture(0.4, 0.4, 0.4, 0.8)
  
  local borderLeft = section:CreateTexture(nil, "BORDER")
  borderLeft:SetPoint("TOPLEFT", section, "TOPLEFT", 0, 0)
  borderLeft:SetPoint("BOTTOMLEFT", section, "BOTTOMLEFT", 0, 0)
  borderLeft:SetWidth(1)
  borderLeft:SetColorTexture(0.4, 0.4, 0.4, 0.8)
  
  local borderRight = section:CreateTexture(nil, "BORDER")
  borderRight:SetPoint("TOPRIGHT", section, "TOPRIGHT", 0, 0)
  borderRight:SetPoint("BOTTOMRIGHT", section, "BOTTOMRIGHT", 0, 0)
  borderRight:SetWidth(1)
  borderRight:SetColorTexture(0.4, 0.4, 0.4, 0.8)
  
  section.borderTop = borderTop
  section.borderBottom = borderBottom
  section.borderLeft = borderLeft
  section.borderRight = borderRight
  
  -- Store title text reference for positioning
  section.titleText = titleText
  
  return section
end

local function CreateColorPicker(parent, name, label, getColorFunc, setColorFunc, updateSwatchFunc, hasAlpha)
  local colorButton = CreateFrame("Button", name, parent, "UIPanelButtonTemplate")
  colorButton:SetSize(140, 32)
  colorButton:SetText("Pick Color")
  
  local colorSwatch = colorButton:CreateTexture(nil, "OVERLAY")
  colorSwatch:SetSize(22, 22)
  colorSwatch:SetPoint("LEFT", colorButton, "LEFT", 6, 0)
  colorSwatch:SetTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
  
  local colorTexture = colorButton:CreateTexture(nil, "ARTWORK")
  colorTexture:SetSize(18, 18)
  colorTexture:SetPoint("CENTER", colorSwatch, "CENTER", 0, 0)
  colorTexture:SetTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
  colorTexture:Show()
  
  colorButton.texture = colorTexture
  colorButton.updateSwatch = updateSwatchFunc or function() end
  
  colorButton:SetScript("OnClick", function()
    local r, g, b, a = getColorFunc()
    local origR, origG, origB, origA = r, g, b, a
    
    local function UpdateColor()
      local newR, newG, newB
      if ColorPickerFrame.GetColorRGB then
        -- WoW's ColorPickerFrame:GetColorRGB normally returns r, g, b as separate numbers.
        -- Some UIs may wrap/override it to return a table, so handle both cases safely.
        local ok, r1, g1, b1 = pcall(ColorPickerFrame.GetColorRGB, ColorPickerFrame)
        if ok then
          if type(r1) == "table" then
            -- Table-style return: { r = ..., g = ..., b = ... } or { [1] = r, [2] = g, [3] = b }
            newR = r1.r or r1[1] or r
            newG = r1.g or r1[2] or g
            newB = r1.b or r1[3] or b
          else
            -- Standard return: r, g, b numbers
            newR = r1 or r
            newG = g1 or g
            newB = b1 or b
          end
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
      
      local newA = a
      if hasAlpha then
        if OpacitySliderFrame and OpacitySliderFrame.GetValue then
          newA = OpacitySliderFrame:GetValue()
        elseif ColorPickerFrame.GetColorAlpha then
          local ok, alphaVal = pcall(ColorPickerFrame.GetColorAlpha, ColorPickerFrame)
          if ok then
            newA = alphaVal
          else
            newA = 1 - (ColorPickerFrame.opacity or (1 - a))
          end
        elseif ColorPickerFrame.GetOpacity then
          local ok, opacityVal = pcall(ColorPickerFrame.GetOpacity, ColorPickerFrame)
          if ok then
            newA = 1 - opacityVal
          else
            newA = 1 - (ColorPickerFrame.opacity or (1 - a))
          end
        else
          newA = 1 - (ColorPickerFrame.opacity or (1 - a))
        end
        newA = math.max(0, math.min(1, newA))
      end
      
      setColorFunc(newR, newG, newB, newA)
      if colorButton.updateSwatch then colorButton.updateSwatch() end
    end
    
    local function CancelColor()
      setColorFunc(origR, origG, origB, origA)
      if colorButton.updateSwatch then colorButton.updateSwatch() end
    end
    
    ColorPickerFrame.r = r
    ColorPickerFrame.g = g
    ColorPickerFrame.b = b
    if hasAlpha then
      ColorPickerFrame.opacity = 1 - a
      ColorPickerFrame.hasOpacity = true
      if OpacitySliderFrame and OpacitySliderFrame.SetMinMaxValues then
        OpacitySliderFrame:SetMinMaxValues(0, 1)
        OpacitySliderFrame:SetValue(a)
      end
    else
      ColorPickerFrame.hasOpacity = false
    end
    
    if ColorPickerFrame.SetColorRGB then
      pcall(ColorPickerFrame.SetColorRGB, ColorPickerFrame, r, g, b)
    end
    if hasAlpha and ColorPickerFrame.SetOpacity then
      pcall(ColorPickerFrame.SetOpacity, ColorPickerFrame, 1 - a)
    end
    
    if ColorPickerFrame.SetupColorPickerAndShow then
      ColorPickerFrame:SetupColorPickerAndShow({
        swatchFunc = UpdateColor,
        hasOpacity = hasAlpha or false,
        opacityFunc = hasAlpha and UpdateColor or nil,
        r = r,
        g = g,
        b = b,
        opacity = hasAlpha and (1 - a) or nil,
        cancelFunc = CancelColor,
      })
    else
      ColorPickerFrame.func = UpdateColor
      ColorPickerFrame.opacityFunc = hasAlpha and UpdateColor or nil
      ColorPickerFrame.cancelFunc = CancelColor
      ColorPickerFrame:Show()
    end
  end)
  
  return colorButton
end

-- Check if LibStub and LibSharedMedia are available
local function CheckLSMAvailability()
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

-- Create a reset button with confirmation dialog
local function CreateResetButton(parent, buttonName, dialogName, dialogText, tabInstance, anchorPoint, anchorTo, relativePoint, xOffset, yOffset)
  local resetButton = CreateFrame("Button", buttonName, parent, "UIPanelButtonTemplate")
  -- Compact link-style button: only text, no visible frame
  resetButton:SetSize(140, 20)
  resetButton:SetText("Reset to Default")

  -- Remove panel button art and rely purely on text hover.
  -- We can't pass nil into Set*Texture safely, so hide the existing textures instead.
  local normalTexObj = resetButton:GetNormalTexture()
  if normalTexObj then
    normalTexObj:SetTexture("Interface\\Buttons\\WHITE8x8")
    normalTexObj:SetVertexColor(0, 0, 0, 0) -- fully transparent
  end
  local pushedTexObj = resetButton:GetPushedTexture()
  if pushedTexObj then
    pushedTexObj:SetTexture("Interface\\Buttons\\WHITE8x8")
    pushedTexObj:SetVertexColor(0, 0, 0, 0)
  end
  local highlightTexObj = resetButton:GetHighlightTexture()
  if highlightTexObj then
    highlightTexObj:SetTexture("Interface\\Buttons\\WHITE8x8")
    highlightTexObj:SetVertexColor(0, 0, 0, 0)
  end

  -- Use small neutral fonts
  resetButton:SetNormalFontObject("GameFontNormalSmall")
  resetButton:SetHighlightFontObject("GameFontHighlightSmall")
  resetButton:SetDisabledFontObject("GameFontDisableSmall")

  local fs = resetButton:GetFontString()
  local normalR, normalG, normalB = 0.8, 0.8, 0.8
  local hoverR, hoverG, hoverB = 1.0, 0.82, 0.0 -- same gold as section titles
  if fs then
    fs:ClearAllPoints()
    fs:SetPoint("CENTER", resetButton, "CENTER", 0, 0)
    fs:SetTextColor(normalR, normalG, normalB, 1)
  end

  resetButton:HookScript("OnEnter", function(self)
    local fontString = self:GetFontString()
    if fontString and self:IsEnabled() then
      fontString:SetTextColor(hoverR, hoverG, hoverB, 1)
    end
  end)
  resetButton:HookScript("OnLeave", function(self)
    local fontString = self:GetFontString()
    if fontString and self:IsEnabled() then
      fontString:SetTextColor(normalR, normalG, normalB, 1)
    end
  end)
  
  -- Default to bottom right if no anchor point specified
  anchorPoint = anchorPoint or "BOTTOMRIGHT"
  anchorTo = anchorTo or parent
  relativePoint = relativePoint or "BOTTOMRIGHT"
  xOffset = xOffset or -20
  yOffset = yOffset or 20
  
  resetButton:SetPoint(anchorPoint, anchorTo, relativePoint, xOffset, yOffset)
  
  resetButton:SetScript("OnClick", function()
    StaticPopup_Show(dialogName, nil, nil, tabInstance)
  end)
  
  -- Register static popup if not already registered
  if not StaticPopupDialogs[dialogName] then
    StaticPopupDialogs[dialogName] = {
      text = dialogText,
      button1 = "Yes",
      button2 = "No",
      OnAccept = function(self, data)
        local tabInstance = data
        if tabInstance and tabInstance.Reset then
          tabInstance:Reset()
        end
      end,
      timeout = 0,
      whileDead = true,
      hideOnEscape = true,
      preferredIndex = 3,
    }
  end
  
  return resetButton
end

-- Export functions
WiseHudOptionsHelpers = {
  ensureLayoutTable = ensureLayoutTable,
  ensureAlphaTable = ensureAlphaTable,
  ensureComboTable = ensureComboTable,
  -- Expose standard section padding so all tabs can use consistent offsets
  SECTION_PADDING_LEFT = SECTION_PADDING_LEFT,
  SECTION_PADDING_RIGHT = SECTION_PADDING_RIGHT,
  SECTION_PADDING_TOP = SECTION_PADDING_TOP,
  SECTION_PADDING_BOTTOM = SECTION_PADDING_BOTTOM,
  CreateSlider = CreateSlider,
  CreateCheckbox = CreateCheckbox,
  CreateColorPicker = CreateColorPicker,
  CreateSectionFrame = CreateSectionFrame,
  CheckLSMAvailability = CheckLSMAvailability,
  CreateResetButton = CreateResetButton,
  -- Shared helper to refresh a slider container from config + defaults
  RefreshSliderFromConfig = function(sliderContainer, configValue, defaultValue)
    if not sliderContainer or not sliderContainer.slider then return end

    local value = configValue
    if value == nil then
      value = defaultValue
    end

    value = tonumber(value)
    if not value then return end

    -- Expand range if needed
    if sliderContainer.ExpandSliderRange then
      sliderContainer.ExpandSliderRange(value)
    end

    -- Update slider range if it was expanded
    if sliderContainer.currentMin and sliderContainer.currentMax then
      local slider = sliderContainer.slider
      slider:SetMinMaxValues(sliderContainer.currentMin, sliderContainer.currentMax)
      local sliderName = slider:GetName()
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
  end,
}
