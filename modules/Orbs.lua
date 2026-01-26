local ADDON_NAME = ...

-- Orb module & model options

local WiseHud = WiseHudFrame

local MAX_POINTS = 7  
-- local DEFAULT_MODEL_PATH = "spells/7fx_priest_voidorb_state.m2"  -- Void Orb model (like in WeakAuras)
local DEFAULT_MODEL_ID = 1372960
local DEFAULT_MODEL_PATH = DEFAULT_MODEL_ID
local ORB_SIZE = 54
local DEFAULT_RADIUS = 50
local TOP_ANGLE = math.rad(90)
local ARC_LENGTH = math.rad(360)

local orbs = {}
local orbAnimations = {}

-- Default camera position (X, Y, Z)
local DEFAULT_CAMERA_X = -1.2
local DEFAULT_CAMERA_Y = 0.0
local DEFAULT_CAMERA_Z = 0.0

local function GetOrbsSettings()
  WiseHudDB = WiseHudDB or {}
  WiseHudDB.comboSettings = WiseHudDB.comboSettings or {}
  return WiseHudDB.comboSettings
end

-- Get camera position from settings
local function GetCameraPosition()
  local cfg = GetOrbsSettings()
  local x = cfg.cameraX or DEFAULT_CAMERA_X
  local y = cfg.cameraY or DEFAULT_CAMERA_Y
  local z = cfg.cameraZ or DEFAULT_CAMERA_Z
  return x, y, z
end

-- Helper function to set camera position for an orb
local function SetOrbCameraPosition(orb)
  if orb and orb.SetPosition then
    local x, y, z = GetCameraPosition()
    pcall(orb.SetPosition, orb, x, y, z)
    pcall(orb.SetFacing, orb, 0)
    pcall(orb.SetAnimation, orb, 0)
  end
end

-- Helper function to configure orb model settings
local function ConfigureOrbModel(orb)
  if not orb then return end
  pcall(orb.SetModelScale, orb, 1)
  pcall(orb.SetRotation, orb, 0)
  pcall(orb.SetPortraitZoom, orb, 0)
  pcall(orb.SetKeepModelOnHide, orb, true)
  SetOrbCameraPosition(orb)
end

local function GetOrbsX()
  local cfg = GetOrbsSettings()
  return cfg.x or 0
end

local function GetOrbsY()
  local cfg = GetOrbsSettings()
  return cfg.y or 0
end

local function GetOrbsRadius()
  local cfg = GetOrbsSettings()
  return cfg.radius or DEFAULT_RADIUS
end

local function IsOrbsEnabled()
  local cfg = GetOrbsSettings()
  return cfg.enabled ~= false
end

local function IsTestModeEnabled()
  local cfg = GetOrbsSettings()
  return cfg.testMode == true
end

local function GetModelPath()
  local cfg = GetOrbsSettings()
  if cfg.modelId then
    -- Try to parse as number first
    local asNumber = tonumber(cfg.modelId)
    if asNumber then
      return asNumber
    else
      -- Return as string if it's not a number (could be a file path)
      return cfg.modelId
    end
  end
  return DEFAULT_MODEL_PATH
end

local function ApplyModelPathToExistingOrbs()
  local modelPath = GetModelPath()
  for _, orb in ipairs(orbs) do
    if orb and orb.SetModel then
      if modelPath and modelPath ~= "" then
        local asNumber = nil
        if type(modelPath) == "number" then
          asNumber = modelPath
        elseif type(modelPath) == "string" then
          asNumber = tonumber(modelPath)
        end
        
        if asNumber then
          local ok = pcall(orb.SetModel, orb, asNumber)
          if ok then
            C_Timer.After(0.1, function()
              if orb and orb.SetModelScale then
                ConfigureOrbModel(orb)
                orb:SetAlpha(1)
              end
            end)
          else
            -- Try SetDisplayInfo as fallback
            local ok2 = pcall(orb.SetDisplayInfo, orb, asNumber)
            if ok2 then
              C_Timer.After(0.1, function()
                if orb and orb.SetModelScale then
                  ConfigureOrbModel(orb)
                  orb:SetAlpha(1)
                end
              end)
            end
          end
        elseif type(modelPath) == "string" then
          -- String path (like .m2 file)
          local ok = pcall(orb.SetModel, orb, modelPath)
          if ok then
            C_Timer.After(0.1, function()
              if orb and orb.SetModelScale then
                ConfigureOrbModel(orb)
                orb:SetAlpha(1)
              end
            end)
          end
        end
      end
    end
  end
end

function WiseHudOrbs_ApplyModelPathToExistingOrbs()
  ApplyModelPathToExistingOrbs()
end

local POWER_TYPE_COMBO_POINTS = 4
local POWER_TYPE_CHI = 12
local POWER_TYPE_SOUL_SHARDS = 7
local POWER_TYPE_HOLY_POWER = 9
local POWER_TYPE_MAELSTROM = 11
local POWER_TYPE_INSANITY = 13
local POWER_TYPE_ARCANE_CHARGES = 16
local POWER_TYPE_FURY = 17
local POWER_TYPE_PAIN = 18

local currentPowerType = nil
local currentMaxPoints = MAX_POINTS

local function GetPowerTypeForClass()
  local _, class = UnitClass("player")
  if not class then return nil end
  
  class = string.upper(class)
  
  if class == "ROGUE" or class == "DRUID" then
    return POWER_TYPE_COMBO_POINTS
  elseif class == "MONK" then
    return POWER_TYPE_CHI
  elseif class == "WARLOCK" then
    return POWER_TYPE_SOUL_SHARDS
  elseif class == "PALADIN" then
    return POWER_TYPE_HOLY_POWER
  end
  
  local powerTypes = {
    POWER_TYPE_COMBO_POINTS,
    POWER_TYPE_CHI,
    POWER_TYPE_SOUL_SHARDS,
    POWER_TYPE_HOLY_POWER,
    POWER_TYPE_MAELSTROM,
    POWER_TYPE_INSANITY,
    POWER_TYPE_ARCANE_CHARGES,
    POWER_TYPE_FURY,
    POWER_TYPE_PAIN
  }
  
  for _, pt in ipairs(powerTypes) do
    local maxPower = UnitPowerMax("player", pt)
    if maxPower and maxPower > 0 then
      return pt
    end
  end
  
  return nil
end

local function GetMaxPoints()
  if currentMaxPoints and currentMaxPoints > 0 then
    return currentMaxPoints
  end
  local powerType = GetPowerTypeForClass()
  if powerType then
    local maxPower = UnitPowerMax("player", powerType)
    if maxPower and maxPower > 0 then
      currentMaxPoints = maxPower
      return maxPower
    end
  end
  return MAX_POINTS
end

local function CreateOrbs()
  if not WiseHudFrame then
    return
  end
  
  local maxPoints = GetMaxPoints()
  
  if #orbs > 0 then
    if #orbs ~= maxPoints then
      for i, orb in ipairs(orbs) do
        if orb then
          orb:Hide()
          if orb.testTexture then
            orb.testTexture:Hide()
          end
          if orb.texture then
            orb.texture:Hide()
          end
        end
      end
      orbs = {}
      orbAnimations = {}
    else
      for i, orb in ipairs(orbs) do
        if orb and orb.GetModelFileID then
        local ok, fileID = pcall(orb.GetModelFileID, orb)
        if not ok then
          fileID = nil
        end
        if not fileID or fileID == 0 then
          local modelPath = GetModelPath()
          
          local asNumber = nil
          if type(modelPath) == "number" then
            asNumber = modelPath
          elseif type(modelPath) == "string" then
            asNumber = tonumber(modelPath)
          end
          
          if asNumber then
            local ok, err = pcall(orb.SetModel, orb, asNumber)
            if ok then
              ConfigureOrbModel(orb)
            end
          elseif type(modelPath) == "string" then
            local ok, err = pcall(orb.SetModel, orb, modelPath)
            if ok then
              ConfigureOrbModel(orb)
            end
          end
        end
      end
      end
    end
    return
  end
  

  local WiseHud = WiseHudFrame
  local radius = GetOrbsRadius()
  local maxPoints = GetMaxPoints()
  WiseHud:SetSize(radius * 2 + ORB_SIZE, radius * 2 + ORB_SIZE)

  for i = 1, maxPoints do
    local orb = CreateFrame("PlayerModel", "WiseHudOrb"..i, WiseHud)
    orb:SetSize(ORB_SIZE, ORB_SIZE)
    orb:SetFrameStrata("HIGH")
    orb:SetFrameLevel(20)
    orb:SetKeepModelOnHide(true)

    local modelPath = GetModelPath()
    local modelLoaded = false
    
    local asNumber = nil
    if type(modelPath) == "number" then
      asNumber = modelPath
    elseif type(modelPath) == "string" then
      if modelPath:match("%.m2$") or modelPath:match("%.M2$") then
        asNumber = nil
      else
        asNumber = tonumber(modelPath)
        if not asNumber then
          asNumber = nil
        end
      end
    end
    
    if asNumber then
      local ok, err = pcall(orb.SetModel, orb, asNumber)
      if ok then
        C_Timer.After(0.15, function()
          if not orb or not orb.SetModelScale then
            return
          end
          pcall(orb.SetKeepModelOnHide, orb, true)
          pcall(orb.SetModelScale, orb, 1)
          C_Timer.After(0.05, function()
            SetOrbCameraPosition(orb)
          end)
        end)
        modelLoaded = true
      else
        local ok2, err2 = pcall(orb.SetDisplayInfo, orb, asNumber)
        if ok2 then
          C_Timer.After(0.05, function()
            if not orb or not orb.SetModelScale then
              return
            end
            ConfigureOrbModel(orb)
          end)
          modelLoaded = true
        end
      end
    end
    
    if not modelLoaded then
      local texture = orb:CreateTexture(nil, "ARTWORK")
      texture:SetAllPoints(orb)
      texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
      texture:SetVertexColor(1, 1, 0, 1)
      orb.texture = texture
    else
      if orb.texture then
        orb.texture:Hide()
        orb.texture = nil
      end
      if orb.testTexture then
        orb.testTexture:Hide()
      end
    end

    orb:SetAlpha(1)
    orb:SetScale(0.01)
    orb:ClearAllPoints()
    orb:SetPoint("CENTER", WiseHudFrame, "CENTER", 0, 0)
    
    if not modelLoaded then
      local testTexture = orb:CreateTexture(nil, "BACKGROUND")
      testTexture:SetAllPoints(orb)
      testTexture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
      testTexture:SetVertexColor(1, 0, 0, 0.5)
      orb.testTexture = testTexture
    else
      C_Timer.After(0.5, function()
        if orb and orb.GetModelFileID then
          local ok, fileID = pcall(orb.GetModelFileID, orb)
          if ok and (not fileID or fileID == 0) then
            if orb and not orb.testTexture then
              local ok2, testTexture = pcall(orb.CreateTexture, orb, nil, "BACKGROUND")
              if ok2 and testTexture then
                testTexture:SetAllPoints(orb)
                testTexture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                testTexture:SetVertexColor(1, 0, 0, 0.5)
                orb.testTexture = testTexture
              end
            end
          end
        end
      end)
    end
    
    orb:Hide()
    
    orbs[i] = orb
    orbAnimations[i] = { 
      currentScale = 0.01, 
      targetScale = 0.01, 
      currentX = 0,
      currentY = 0,
      targetX = 0,
      targetY = 0,
      animating = false 
    }
  end
end

local function GetComboPoints()
  local powerType = GetPowerTypeForClass()
  
  if not powerType then
    powerType = Enum.PowerType and Enum.PowerType.ComboPoints or POWER_TYPE_COMBO_POINTS
  end
  
  if currentPowerType ~= powerType then
    currentPowerType = powerType
    local maxPower = UnitPowerMax("player", powerType)
    if maxPower and maxPower > 0 then
      currentMaxPoints = maxPower
    end
  end
  
  local maxPower = UnitPowerMax("player", powerType)
  if maxPower and maxPower > 0 then
    local points = UnitPower("player", powerType)
    if points then
      if maxPower ~= currentMaxPoints then
        currentMaxPoints = maxPower
      end
      return points
    end
  end
  
  return 0
end

local function IsComboPointType(powerType)
  if not powerType then return false end
  
  if type(powerType) == "number" then
    return powerType == POWER_TYPE_COMBO_POINTS
        or powerType == POWER_TYPE_CHI
        or powerType == POWER_TYPE_SOUL_SHARDS
        or powerType == POWER_TYPE_HOLY_POWER
        or powerType == POWER_TYPE_MAELSTROM
        or powerType == POWER_TYPE_INSANITY
        or powerType == POWER_TYPE_ARCANE_CHARGES
        or powerType == POWER_TYPE_FURY
        or powerType == POWER_TYPE_PAIN
  end
  
  -- If powerType is a string (for compatibility)
  if type(powerType) == "string" then
    return powerType == "COMBO_POINTS" 
        or powerType == "CHI" 
        or powerType == "SOUL_SHARDS"
        or powerType == "HOLY_POWER"
        or powerType == "MAELSTROM"
        or powerType == "INSANITY"
        or powerType == "ARCANE_CHARGES"
        or powerType == "FURY"
        or powerType == "PAIN"
  end
  
  return false
end

local function AnimateOrbScale(orbIndex, targetScale)
  if not orbs[orbIndex] then 
    return 
  end
  
  local orb = orbs[orbIndex]
  local anim = orbAnimations[orbIndex]
  
  if not anim then
    orbAnimations[orbIndex] = { currentScale = 0.01, targetScale = 0.01, animating = false }
    anim = orbAnimations[orbIndex]
  end
  
  -- Scale must be > 0, use 0.01 as minimum
  local minScale = 0.01
  if targetScale <= 0 then
    targetScale = minScale
  end
  
  -- If target scale hasn't changed, still check if orb should be displayed
  if anim.targetScale == targetScale and not anim.animating then
    -- Ensure orb is shown/hidden even if animation is already complete
    if targetScale > minScale then
      if not orb:IsShown() then
        orb:Show()
        if orb.testTexture then
          orb.testTexture:Show()
        end
      else
        if orb.testTexture and not orb.testTexture:IsShown() then
          orb.testTexture:Show()
        end
      end
      local currentScale = orb:GetScale()
      if math.abs(currentScale - targetScale) > 0.01 then
        orb:SetScale(targetScale)
      else
      end
    else
      if orb:IsShown() then
        orb:Hide()
      else
      end
    end
    return
  end
  
  anim.targetScale = targetScale
  anim.animating = true
  
  if targetScale > minScale then
    orb:Show()
    if orb.testTexture then
      orb.testTexture:Show()
    end
    if anim.currentScale < minScale + 0.01 then
      anim.currentScale = minScale + 0.01
      orb:SetScale(anim.currentScale)
    end
  else
    if orb.testTexture then
      orb.testTexture:Hide()
    end
  end
end

function WiseHudOrbs_UpdateAnimations(elapsed)
  local animationSpeed = 8
  local positionSpeed = 6
  local minScale = 0.01
  local maxPoints = GetMaxPoints()
  
  for i = 1, maxPoints do
    local anim = orbAnimations[i]
    if anim and orbs[i] then
      local orb = orbs[i]
      local needsUpdate = false
      
      if anim.animating then
        local scaleDiff = anim.targetScale - anim.currentScale
        
        if math.abs(scaleDiff) < 0.01 then
          anim.currentScale = anim.targetScale
          anim.animating = false
          orb:SetScale(anim.currentScale)
          
          if anim.currentScale <= minScale then
            orb:Hide()
          end
        else
          anim.currentScale = anim.currentScale + scaleDiff * math.min(1, animationSpeed * elapsed)
          if anim.currentScale < minScale then
            anim.currentScale = minScale
          end
          orb:SetScale(anim.currentScale)
          needsUpdate = true
        end
      end
      
      local posDiffX = anim.targetX - anim.currentX
      local posDiffY = anim.targetY - anim.currentY
      local posDistance = math.sqrt(posDiffX * posDiffX + posDiffY * posDiffY)
      
      if posDistance > 0.5 then
        local moveAmount = math.min(1, positionSpeed * elapsed)
        anim.currentX = anim.currentX + posDiffX * moveAmount
        anim.currentY = anim.currentY + posDiffY * moveAmount
        
        orb:ClearAllPoints()
        orb:SetPoint("CENTER", WiseHudFrame, "CENTER", anim.currentX, anim.currentY)
        needsUpdate = true
      else
        anim.currentX = anim.targetX
        anim.currentY = anim.targetY
        orb:ClearAllPoints()
        orb:SetPoint("CENTER", WiseHudFrame, "CENTER", anim.currentX, anim.currentY)
      end
    end
  end
end

local function UpdateOrbs()
  if not IsOrbsEnabled() then
    for i = 1, #orbs do
      if orbs[i] then
        orbs[i]:Hide()
      end
    end
    return
  end
  
  local points = GetComboPoints()
  local maxPoints = GetMaxPoints()
  
  -- In test mode, always show maximum points
  if IsTestModeEnabled() then
    points = maxPoints
  end
  
  local activeCount = points
  
  for i = 1, maxPoints do
    local orb = orbs[i]
    if orb then
      if i <= points then
        local x, y
        
        if activeCount == 1 then
          x = 0
          y = 0
        else
          local angleStep = ARC_LENGTH / activeCount
          local middleIndex = math.ceil(activeCount / 2)
          local offsetFromMiddle = (middleIndex - i) * angleStep
          local angle = TOP_ANGLE - offsetFromMiddle
          local radius = GetOrbsRadius()
          x = math.cos(angle) * radius
          y = math.sin(angle) * radius
        end
        
        local offsetX = GetOrbsX()
        local offsetY = GetOrbsY()
        x = x + offsetX
        y = y + offsetY
        
        local anim = orbAnimations[i]
        if anim then
          anim.targetX = x
          anim.targetY = y
          if anim.currentX == 0 and anim.currentY == 0 then
            anim.currentX = x
            anim.currentY = y
            orb:ClearAllPoints()
            orb:SetPoint("CENTER", WiseHudFrame, "CENTER", x, y)
          end
        end
        
        AnimateOrbScale(i, 1.0)
        SetOrbCameraPosition(orb)
      else
        AnimateOrbScale(i, 0.01)
        SetOrbCameraPosition(orb)
      end
    end
  end
end

local function EnsureCameraPosition()
  -- Ensure camera position is set for all orbs, even if they're hidden
  for i, orb in ipairs(orbs) do
    if orb then
      -- Temporarily show the orb to ensure model is loaded (if hidden)
      local wasShown = orb:IsShown()
      if not wasShown then
        orb:Show()
        -- Give the model a moment to load when shown
        if C_Timer and C_Timer.After then
          C_Timer.After(0.05, function()
            if orb and orb.SetPosition then
              SetOrbCameraPosition(orb)
            end
          end)
        end
      end
      
      -- Always try to set camera position, even if model isn't fully loaded yet
      SetOrbCameraPosition(orb)
      
      -- Check if model is loaded
      local hasModel = false
      if orb.GetModelFileID then
        local ok, fileID = pcall(orb.GetModelFileID, orb)
        if ok and fileID and fileID ~= 0 then
          hasModel = true
        end
      end
      
      -- If model is loaded, ensure position is set again (sometimes needed)
      if hasModel then
        SetOrbCameraPosition(orb)
        -- Set it again after a small delay to ensure it sticks
        if C_Timer and C_Timer.After then
          C_Timer.After(0.1, function()
            if orb and orb.SetPosition then
              SetOrbCameraPosition(orb)
            end
          end)
        end
      end
      
      -- Hide orb again if it was hidden before
      if not wasShown then
        -- Set position one more time before hiding
        SetOrbCameraPosition(orb)
        orb:Hide()
      end
    end
  end
end

function WiseHudOrbs_OnPlayerLogin()
  if #orbs > 0 then
    for i, orb in ipairs(orbs) do
      if orb then
        orb:Hide()
        if orb.testTexture then
          orb.testTexture:Hide()
        end
        if orb.texture then
          orb.texture:Hide()
        end
      end
    end
    orbs = {}
    orbAnimations = {}
  end
  CreateOrbs()
  
  -- Temporarily show all orbs to ensure models are loaded
  for i, orb in ipairs(orbs) do
    if orb then
      orb:Show()
    end
  end
  
  -- Set camera position immediately after creation
  if C_Timer and C_Timer.After then
    C_Timer.After(0.1, function()
      EnsureCameraPosition()
    end)
    C_Timer.After(0.3, function()
      EnsureCameraPosition()
    end)
  end
  
  -- Now update orbs (this will hide them if points are 0)
  UpdateOrbs()
  
  -- Ensure camera position is set after delays (when models are fully loaded)
  -- Important: Set position even after orbs are hidden (for 0 CP case)
  if C_Timer and C_Timer.After then
    C_Timer.After(0.5, function()
      EnsureCameraPosition()
      UpdateOrbs()
    end)
    C_Timer.After(0.8, function()
      EnsureCameraPosition()
    end)
    C_Timer.After(1.2, function()
      EnsureCameraPosition()
      UpdateOrbs()
    end)
    C_Timer.After(1.8, function()
      EnsureCameraPosition()
    end)
    C_Timer.After(2.5, function()
      EnsureCameraPosition()
    end)
  end
end

function WiseHudOrbs_OnPowerUpdate(unit, powerType)
  if unit ~= "player" then return end
  
  if powerType then
    local currentType = GetPowerTypeForClass()
    if powerType == currentType or IsComboPointType(powerType) then
      UpdateOrbs()
    end
  else
    UpdateOrbs()
  end
end

function WiseHudOrbs_OnSpecChanged()
  UpdateOrbs()
end

function WiseHudOrbs_SetEnabled(enabled)
  local cfg = GetOrbsSettings()
  cfg.enabled = enabled
  UpdateOrbs()
end

function WiseHudOrbs_UpdateCameraPosition()
  -- Update camera position for all existing orbs
  for i, orb in ipairs(orbs) do
    if orb then
      SetOrbCameraPosition(orb)
    end
  end
end

function WiseHudOrbs_ApplyLayout()
  if not WiseHudFrame then return end
  
  local x = GetOrbsX()
  local y = GetOrbsY()
  local radius = GetOrbsRadius()
  
  local currentWidth, currentHeight = WiseHudFrame:GetSize()
  local comboSize = radius * 2 + ORB_SIZE
  local maxSize = math.max(currentWidth or 0, currentHeight or 0, comboSize)
  if maxSize > (currentWidth or 0) or maxSize > (currentHeight or 0) then
    WiseHudFrame:SetSize(maxSize, maxSize)
  end
  
  if #orbs > 0 then
    UpdateOrbs()
  end
end

-- Export function to get default model ID
function WiseHudOrbs_GetDefaultModelId()
  return DEFAULT_MODEL_ID
end
