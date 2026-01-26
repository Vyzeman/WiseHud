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

-- UI Element Helper Functions

local function CreateSlider(parent, name, label, minVal, maxVal, step, defaultValue, textFormat, onChangeCallback)
  -- Create container frame for label and slider
  local container = CreateFrame("Frame", name .. "Container", parent)
  container:SetSize(400, 50)
  
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
  
  -- Slider
  local slider = CreateFrame("Slider", name, container, "OptionsSliderTemplate")
  slider:SetPoint("TOPLEFT", labelText, "BOTTOMLEFT", 0, -8)
  slider:SetPoint("RIGHT", container, "RIGHT", 0, 0)
  slider:SetMinMaxValues(minVal, maxVal)
  slider:SetValueStep(step)
  slider:SetObeyStepOnDrag(true)
  slider:SetValue(defaultValue)
  
  -- Min/Max labels
  _G[slider:GetName() .. "Low"]:SetText(tostring(minVal))
  _G[slider:GetName() .. "High"]:SetText(tostring(maxVal))
  _G[slider:GetName() .. "Text"]:Hide() -- Hide default text, we use our own
  
  -- Initial value display
  local displayText = textFormat and string.format(textFormat, defaultValue) or tostring(defaultValue)
  valueText:SetText(displayText)
  
  slider:SetScript("OnValueChanged", function(self, value)
    local roundedValue
    if step < 1 then
      roundedValue = math.floor(value / step + 0.5) * step
    else
      roundedValue = math.floor(value + 0.5)
    end
    
    local displayText = textFormat and string.format(textFormat, roundedValue) or tostring(roundedValue)
    valueText:SetText(displayText)
    
    if onChangeCallback then
      onChangeCallback(self, roundedValue)
    end
  end)
  
  container.slider = slider
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

-- Export functions
WiseHudOptionsHelpers = {
  ensureLayoutTable = ensureLayoutTable,
  ensureAlphaTable = ensureAlphaTable,
  ensureComboTable = ensureComboTable,
  CreateSlider = CreateSlider,
  CreateCheckbox = CreateCheckbox,
  CreateColorPicker = CreateColorPicker,
  CreateSectionFrame = CreateSectionFrame,
  CheckLSMAvailability = CheckLSMAvailability,
}
