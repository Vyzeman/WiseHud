local ADDON_NAME = ...

-- Orb module & model options

-- Central defaults
local ORB_DEFAULTS = WiseHudConfig.GetOrbsDefaults()
local ORB_PRESETS = WiseHudConfig.GetOrbPresets and WiseHudConfig.GetOrbPresets() or {}

local MAX_POINTS = ORB_DEFAULTS.maxPointsFallback

local DEFAULT_MODEL_ID = ORB_DEFAULTS.modelId
local ORB_SIZE = ORB_DEFAULTS.orbSize
local DEFAULT_RADIUS = ORB_DEFAULTS.radius
local TOP_ANGLE = math.rad(ORB_DEFAULTS.topAngleDeg)
local ARC_LENGTH = math.rad(ORB_DEFAULTS.arcLengthDeg)

local orbs = {}
local orbAnimations = {}
local orbsFrame = nil
local orbsCurrentAlpha = nil
local orbsTargetAlpha = nil
local lastKnownPoints = nil
local EnsureCameraPosition -- forward declaration so it can be used earlier
local UpdateOrbs           -- forward declaration so it can be used earlier
local GetPowerTypeForClass -- forward declaration so it can be used earlier
local orbsReinitializedAfterFirstPoints = false -- for relog fix: one-time re-create after first point
local orbsCameraReady = false
local cameraStabilizeTicker = nil

-- Default camera position (X, Y, Z) from central config
local DEFAULT_CAMERA_X = ORB_DEFAULTS.cameraX
local DEFAULT_CAMERA_Y = ORB_DEFAULTS.cameraY
local DEFAULT_CAMERA_Z = ORB_DEFAULTS.cameraZ

-- Default alpha settings for Orbs (percent, 0–100),
-- configured separately from Health/Power.
local DEFAULT_ALPHA_COMBAT    = (ORB_DEFAULTS.alpha and ORB_DEFAULTS.alpha.combat)   or 100
local DEFAULT_ALPHA_NONFULL   = (ORB_DEFAULTS.alpha and ORB_DEFAULTS.alpha.nonFull)  or 50
local DEFAULT_ALPHA_FULL_IDLE = (ORB_DEFAULTS.alpha and ORB_DEFAULTS.alpha.fullIdle) or 0

local CUSTOM_PRESET_KEY = "custom"

-- Get or create a dedicated parent frame for all orbs so
-- alpha/visibility can be controlled centrally without
-- affecting the rest of the WiseHud elements.
local function GetOrbsFrame()
  if not WiseHudFrame then
    return nil
  end

  if not orbsFrame or not orbsFrame.GetParent or orbsFrame:GetParent() ~= WiseHudFrame then
    orbsFrame = CreateFrame("Frame", "WiseHudOrbsFrame", WiseHudFrame)
    -- Orbs should follow the main HUD position/size but
    -- stay in their own sub-frame.
    orbsFrame:SetAllPoints(WiseHudFrame)
    -- Keep strata/frame level high enough so models render
    -- above the basic HUD art, similar to previous setup.
    orbsFrame:SetFrameStrata("HIGH")
    orbsFrame:SetFrameLevel(20)
  end

  return orbsFrame
end

local function FindOrbPreset(presetKey)
  if not presetKey or presetKey == "" then
    return nil
  end
  for _, preset in ipairs(ORB_PRESETS) do
    if preset.key == presetKey then
      return preset
    end
  end
  return nil
end

local function GetOrbsSettings()
  WiseHudDB = WiseHudDB or {}
  WiseHudDB.comboSettings = WiseHudDB.comboSettings or {}
  return WiseHudDB.comboSettings
end

-- Returns orb alpha settings as 0–1 values (combat, nonFull, fullIdle)
local function GetOrbsAlphaSettings()
  local cfg = GetOrbsSettings()
  local combat   = cfg.orbCombatAlpha   or DEFAULT_ALPHA_COMBAT
  local nonFull  = cfg.orbNonFullAlpha  or DEFAULT_ALPHA_NONFULL
  local fullIdle = cfg.orbFullIdleAlpha or DEFAULT_ALPHA_FULL_IDLE
  return combat / 100, nonFull / 100, fullIdle / 100
end

local function RecomputeOrbsTargetAlpha()
  -- Independent alpha logic for Orbs that mirrors the semantics
  -- of Health/Power, but uses its own settings and still relies
  -- on the shared WiseHudCombatInfo timestamps (separate field).
  local combatAlpha, nonFullAlpha, fullIdleAlpha = GetOrbsAlphaSettings()

  local inCombat = (WiseHudCombatInfo and WiseHudCombatInfo.inCombat)
    or (UnitAffectingCombat and UnitAffectingCombat("player") and true or false)

  -- When Orbs test mode is active, force combat alpha so
  -- they stay visible while configuring them.
  local cfg = GetOrbsSettings()
  if cfg.testMode then
    inCombat = true
  end

  local sinceChange
  if WiseHudCombatInfo and WiseHudCombatInfo.lastOrbChange then
    sinceChange = GetTime() - WiseHudCombatInfo.lastOrbChange
  end

  if inCombat then
    orbsTargetAlpha = combatAlpha
  elseif sinceChange and sinceChange < 5 then -- same fade delay as Health/Power
    orbsTargetAlpha = nonFullAlpha
  else
    orbsTargetAlpha = fullIdleAlpha
  end
end

function WiseHudOrbs_ApplyAlpha()
  -- Recompute desired alpha based on Orb-specific settings.
  RecomputeOrbsTargetAlpha()

  if orbsCurrentAlpha == nil then
    orbsCurrentAlpha = orbsTargetAlpha
  end

  -- Apply alpha directly to each orb model so the effect
  -- is guaranteed to affect the PlayerModel frames.
  if orbsCurrentAlpha ~= nil then
    for _, orb in ipairs(orbs) do
      if orb and orb.SetAlpha then
        pcall(orb.SetAlpha, orb, orbsCurrentAlpha)
      end
    end
  end
end

function WiseHudOrbs_UpdateAlpha(elapsed)
  if not orbsTargetAlpha or not WiseHudHP_SmoothAlpha then
    return
  end

  orbsCurrentAlpha = WiseHudHP_SmoothAlpha(orbsCurrentAlpha, orbsTargetAlpha, elapsed)
  if orbsCurrentAlpha ~= nil then
    for _, orb in ipairs(orbs) do
      if orb and orb.SetAlpha then
        pcall(orb.SetAlpha, orb, orbsCurrentAlpha)
      end
    end
  end
end

-- Determine class/spec specific default orb preset.
-- Falls back to "void_orb" if nothing matches or APIs are unavailable.
local function GetDefaultOrbPresetForClass()
  local _, class = UnitClass("player")
  if not class then
    return "void_orb"
  end

  class = string.upper(class)

  local specId = nil
  -- Use globals via _G to avoid bare undefined globals for the linter.
  local getSpec = _G and _G.GetSpecialization or nil
  local getSpecInfo = _G and _G.GetSpecializationInfo or nil
  if getSpec and getSpecInfo then
    local specIndex = getSpec()
    if specIndex then
      specId = getSpecInfo(specIndex)
    end
  end

  -- Windwalker Monk -> Chi
  -- Windwalker spec ID is 269 in Retail.
  if class == "MONK" and specId == 269 then
    return "chi_orb"
  end

  -- Rogue (all specs) -> White Flame
  if class == "ROGUE" then
    return "flame_orb_2"
  end

  -- Feral Druid (spec ID 103) -> White Flame
  if class == "DRUID" and specId == 103 then
    return "flame_orb_2"
  end

  -- Holy specs -> Solar (Holy Paladin 65, Holy Priest 257)
  if specId == 65 or specId == 257 then
    return "solar_orb"
  end

  -- Warlock (all specs) -> Void
  if class == "WARLOCK" then
    return "void_orb"
  end

  -- Fallback: keep previous default
  return "void_orb"
end

local function NormalizePresetKey(presetKey)
  -- Keep preset resolution consistent with the options UI.
  if not presetKey or presetKey == "" or presetKey == "default" then
    return GetDefaultOrbPresetForClass()
  end
  return presetKey
end

-- Get camera position from settings / presets
local function GetCameraPosition()
  local cfg = GetOrbsSettings()
  local presetKey = NormalizePresetKey(cfg.modelPreset)
  local x, y, z

  -- For non-custom presets, use camera values from the preset table (if available)
  if presetKey ~= CUSTOM_PRESET_KEY then
    local preset = FindOrbPreset(presetKey)
    if preset then
      x = preset.cameraX
      y = preset.cameraY
      z = preset.cameraZ
    end
  end

  -- Fallbacks: for custom preset, or if preset has no camera values
  if x == nil or y == nil or z == nil then
    x = cfg.cameraX or DEFAULT_CAMERA_X
    y = cfg.cameraY or DEFAULT_CAMERA_Y
    z = cfg.cameraZ or DEFAULT_CAMERA_Z
  end

  return x, y, z
end

-- Helper function to check if orb model is ready
local function IsOrbModelReady(orb)
  if not orb then return false end
  if orb.GetModelFileID then
    local ok, fileID = pcall(orb.GetModelFileID, orb)
    if ok and fileID and fileID ~= 0 then
      return true
    end
  end
  return false
end

-- Helper function to set camera position for an orb
local function SetOrbCameraPosition(orb, force)
  if orb and orb.SetPosition then
    local x, y, z = GetCameraPosition()
    -- Only set position if model is ready, or orb is shown, or force is true
    local modelReady = IsOrbModelReady(orb)
    if force or modelReady or orb:IsShown() then
      pcall(orb.SetPosition, orb, x, y, z)
      pcall(orb.SetFacing, orb, 0)
      pcall(orb.SetAnimation, orb, 0)
      return true
    end
  end
  return false
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
  return cfg.x or ORB_DEFAULTS.x
end

local function GetOrbsY()
  local cfg = GetOrbsSettings()
  return cfg.y or ORB_DEFAULTS.y
end

local function GetOrbsRadius()
  local cfg = GetOrbsSettings()
  return cfg.radius or DEFAULT_RADIUS
end

local function GetOrbsLayoutType()
  local cfg = GetOrbsSettings()
  return cfg.layoutType or ORB_DEFAULTS.layoutType or "circle"
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
  local presetKey = NormalizePresetKey(cfg.modelPreset)

  -- If a non-custom preset is selected, use its modelId from the preset table
  if presetKey ~= CUSTOM_PRESET_KEY then
    local preset = FindOrbPreset(presetKey)
    if preset and preset.modelId then
      return preset.modelId
    end
  end

  -- Custom preset (or no valid preset): fall back to stored modelId or default
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

  return DEFAULT_MODEL_ID
end

local function NormalizeModelPath(modelPath)
  if not modelPath or modelPath == "" then
    return nil
  end

  if type(modelPath) == "number" then
    return modelPath
  end

  if type(modelPath) == "string" then
    local trimmed = strtrim(modelPath)
    if trimmed == "" then
      return nil
    end
    local asNumber = tonumber(trimmed)
    if asNumber then
      return asNumber
    end
    return trimmed
  end

  return nil
end

local function ApplyModelToOrb(orb, modelPath)
  if not orb or not orb.SetModel then
    return false
  end

  local normalized = NormalizeModelPath(modelPath)
  if not normalized then
    return false
  end

  if type(normalized) == "number" then
    local ok = pcall(orb.SetModel, orb, normalized)
    if ok then
      return true
    end
    -- Try SetDisplayInfo as fallback
    local ok2 = pcall(orb.SetDisplayInfo, orb, normalized)
    return ok2 == true
  end

  -- String path (like .m2 file)
  return pcall(orb.SetModel, orb, normalized) == true
end

local function AfterModelApplied(orb)
  C_Timer.After(0.1, function()
    if not orb or not orb.SetModelScale then
      return
    end
    ConfigureOrbModel(orb)
  end)
end

local function ApplyModelPathToExistingOrbs()
  local modelPath = GetModelPath()
  local success = false
  local attempted = false

  local normalized = NormalizeModelPath(modelPath)
  if normalized then
    attempted = true
  end

  for _, orb in ipairs(orbs) do
    if orb and normalized then
      if ApplyModelToOrb(orb, normalized) then
        success = true
        AfterModelApplied(orb)
      end
    end
  end

  return success, attempted
end

-- Wait for models to load and then set camera position for all orbs
local function WaitForModelsAndSetCamera(maxAttempts, checkInterval)
  maxAttempts = maxAttempts or 50  -- Maximum number of attempts (50 * 0.1s = 5 seconds max)
  checkInterval = checkInterval or 0.1  -- Check interval in seconds
  
  local attempts = 0
  -- Some models won't actually load while the PlayerModel is hidden.
  -- When the user switches presets with 0 combo points, all orbs are hidden,
  -- so we temporarily show them with alpha=0 to force model loading, then restore.
  local forceLoadState = {}

  local function MaybeForceLoadModel(orb)
    if not orb or forceLoadState[orb] then
      return
    end

    -- Only do this for currently hidden/inactive orbs to avoid affecting visible ones.
    local wasShown = false
    local wasScale = 1.0
    local wasAlpha = 1.0
    pcall(function() wasShown = orb:IsShown() end)
    pcall(function() wasScale = orb:GetScale() end)
    pcall(function() wasAlpha = orb:GetAlpha() end)

    if wasShown and wasScale and wasScale >= 0.1 then
      return
    end

    forceLoadState[orb] = {
      wasShown = wasShown,
      wasScale = wasScale,
      wasAlpha = wasAlpha,
    }

    pcall(orb.SetAlpha, orb, 0)
    orb:Show()
    pcall(orb.SetScale, orb, 1.0)
  end

  local function RestoreForceLoadStates()
    for orb, st in pairs(forceLoadState) do
      if orb and st then
        if st.wasAlpha ~= nil then
          pcall(orb.SetAlpha, orb, st.wasAlpha)
        end
        if st.wasScale ~= nil then
          pcall(orb.SetScale, orb, st.wasScale)
        end
        if st.wasShown == false then
          orb:Hide()
        end
      end
    end
    forceLoadState = {}
  end

  local function checkAndSet()
    attempts = attempts + 1
    local allReady = true
    local hasOrbs = false
    local readyCount = 0
    
    -- Check if all orbs have models loaded
    for _, orb in ipairs(orbs) do
      if orb then
        hasOrbs = true
        if IsOrbModelReady(orb) then
          readyCount = readyCount + 1
          -- Set camera position as soon as this orb is ready
          SetOrbCameraPosition(orb, true)
        else
          allReady = false
          -- Force-load models for hidden/inactive orbs so camera can be applied
          MaybeForceLoadModel(orb)
        end
      end
    end
    
    -- If all models are ready or we've tried enough times, ensure all cameras are set
    if (allReady and hasOrbs) or attempts >= maxAttempts then
      -- Restore any temporary show/alpha/scale changes
      RestoreForceLoadStates()
      -- Final pass: ensure all orbs have camera set
      for _, orb in ipairs(orbs) do
        if orb then
          SetOrbCameraPosition(orb, true)
        end
      end
    else
      -- Check again after interval
      C_Timer.After(checkInterval, checkAndSet)
    end
  end
  
  -- Start checking
  checkAndSet()
end

-- Initialize orb camera once after login, especially for the case
-- where the player logs in with 0 resources and all orbs are hidden.
-- We trigger the robust model-load logic in this case,
-- without artificial test mode or layout manipulation.
local function InitializeOrbsCameraAfterLogin()
  if not orbs or #orbs == 0 then
    return
  end

  -- Only activate if we really log in with 0 points.
  -- IMPORTANT: Do NOT use the Blizzard API GetComboPoints(unit, target) here,
  -- but use our own helper logic directly via PowerType/UnitPower,
  -- to avoid argument errors.
  local points = 0
  if GetPowerTypeForClass then
    local powerType = GetPowerTypeForClass()
    if powerType then
      local maxPower = UnitPowerMax("player", powerType)
      if maxPower and maxPower > 0 then
        points = UnitPower("player", powerType) or 0
      end
    end
  end
  if points > 0 then return end

  -- Load models and set camera, even if all orbs are hidden.
  WaitForModelsAndSetCamera()
end

function WiseHudOrbs_ApplyModelPathToExistingOrbs()
  local success, attempted = ApplyModelPathToExistingOrbs()
  -- After applying model, wait for models to load and then set camera position
  -- The camera position is read from settings via GetCameraPosition()
  if attempted and success then
    WaitForModelsAndSetCamera()
  end
  return success, attempted
end

-- Test if a model ID/path can be loaded by creating a temporary test orb
local function TestModelPath(modelPath)
  if not modelPath or modelPath == "" then
    return false
  end
  
  -- Create a temporary test orb (use UIParent as parent, will be cleaned up)
  local testOrb = CreateFrame("PlayerModel", nil, UIParent)
  testOrb:SetSize(ORB_SIZE, ORB_SIZE)
  testOrb:SetFrameStrata("TOOLTIP")
  testOrb:SetFrameLevel(1000)
  testOrb:SetPoint("CENTER", UIParent, "CENTER", -10000, -10000) -- Position off-screen
  testOrb:SetAlpha(0) -- Make it invisible
  testOrb:Show()
  
  local success = false
  local asNumber = nil
  
  if type(modelPath) == "number" then
    asNumber = modelPath
  elseif type(modelPath) == "string" then
    asNumber = tonumber(modelPath)
  end
  
  if asNumber then
    -- Try SetModel first
    local ok = pcall(testOrb.SetModel, testOrb, asNumber)
    if ok then
      success = true
      -- Clean up after a short delay
      C_Timer.After(0.1, function()
        if testOrb then
          testOrb:Hide()
          testOrb:SetParent(nil)
          testOrb = nil
        end
      end)
    else
      -- Try SetDisplayInfo as fallback
      local ok2 = pcall(testOrb.SetDisplayInfo, testOrb, asNumber)
      if ok2 then
        success = true
        C_Timer.After(0.1, function()
          if testOrb then
            testOrb:Hide()
            testOrb:SetParent(nil)
            testOrb = nil
          end
        end)
      else
        -- Clean up immediately if both failed
        testOrb:Hide()
        testOrb:SetParent(nil)
        testOrb = nil
      end
    end
  elseif type(modelPath) == "string" then
    -- String path (like .m2 file)
    local ok = pcall(testOrb.SetModel, testOrb, modelPath)
    if ok then
      success = true
      C_Timer.After(0.1, function()
        if testOrb then
          testOrb:Hide()
          testOrb:SetParent(nil)
          testOrb = nil
        end
      end)
    else
      -- Clean up immediately if failed
      testOrb:Hide()
      testOrb:SetParent(nil)
      testOrb = nil
    end
  else
    -- Clean up if invalid type
    testOrb:Hide()
    testOrb:SetParent(nil)
    testOrb = nil
  end
  
  return success
end

function WiseHudOrbs_TestModelPath(modelPath)
  return TestModelPath(modelPath)
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

function GetPowerTypeForClass()
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

  local parentFrame = GetOrbsFrame()
  if not parentFrame then
    return
  end
  if #orbs > 0 then
    local maxPoints = GetMaxPoints()
    if #orbs ~= maxPoints then
      for i, orb in ipairs(orbs) do
        if orb then
          orb:Hide()
          if orb.fallbackTexture then orb.fallbackTexture:Hide() end
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
            if ApplyModelToOrb(orb, modelPath) then
              ConfigureOrbModel(orb)
            end
          end
        end
      end
    end
    return
  end
  

  local radius = GetOrbsRadius()
  local maxPoints = GetMaxPoints()
  WiseHudFrame:SetSize(radius * 2 + ORB_SIZE, radius * 2 + ORB_SIZE)

  for i = 1, maxPoints do
    local orb = CreateFrame("PlayerModel", "WiseHudOrb"..i, parentFrame)
    orb:SetSize(ORB_SIZE, ORB_SIZE)
    orb:SetFrameStrata("HIGH")
    orb:SetFrameLevel(20)
    orb:SetKeepModelOnHide(true)

    local modelPath = GetModelPath()
    local modelLoaded = ApplyModelToOrb(orb, modelPath)
    if modelLoaded then
      AfterModelApplied(orb)
    else
      local fallbackTexture = orb:CreateTexture(nil, "ARTWORK")
      fallbackTexture:SetAllPoints(orb)
      fallbackTexture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
      fallbackTexture:SetVertexColor(1, 1, 0, 1)
      orb.fallbackTexture = fallbackTexture
    end

    -- Start fully visible; no mini-scale for debugging/fine-tuning
    orb:SetAlpha(1)
    orb:SetScale(1)
    orb:ClearAllPoints()
    orb:SetPoint("CENTER", parentFrame, "CENTER", 0, 0)
    
    orb:Hide()
    
    orbs[i] = orb
    orbAnimations[i] = { 
      currentX = nil,
      currentY = nil,
      targetX = 0,
      targetY = 0,
    }
  end

  -- Ensure container alpha is applied once orbs exist
  WiseHudOrbs_ApplyAlpha()
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

local function SetOrbActive(orbIndex, isActive)
  local orb = orbs[orbIndex]
  if not orb then return end

  if isActive then
    orb:Show()
    orb:SetScale(1)
  else
    orb:Hide()
  end
end

function WiseHudOrbs_UpdateAnimations(elapsed)
  local positionSpeed = 6
  local maxPoints = GetMaxPoints()
  
  for i = 1, maxPoints do
    local anim = orbAnimations[i]
    if anim and orbs[i] then
      local orb = orbs[i]
      if anim.currentX == nil or anim.currentY == nil then
        anim.currentX = anim.targetX
        anim.currentY = anim.targetY
        orb:ClearAllPoints()
        local parentFrame = GetOrbsFrame() or WiseHudFrame
        orb:SetPoint("CENTER", parentFrame, "CENTER", anim.currentX, anim.currentY)
      end

      local posDiffX = anim.targetX - (anim.currentX or 0)
      local posDiffY = anim.targetY - (anim.currentY or 0)
      local posDistance = math.sqrt(posDiffX * posDiffX + posDiffY * posDiffY)
      
      if posDistance > 0.5 then
        local moveAmount = math.min(1, positionSpeed * elapsed)
        anim.currentX = anim.currentX + posDiffX * moveAmount
        anim.currentY = anim.currentY + posDiffY * moveAmount
        
        orb:ClearAllPoints()
        local parentFrame = GetOrbsFrame() or WiseHudFrame
        orb:SetPoint("CENTER", parentFrame, "CENTER", anim.currentX, anim.currentY)
      else
        anim.currentX = anim.targetX
        anim.currentY = anim.targetY
        orb:ClearAllPoints()
        local parentFrame = GetOrbsFrame() or WiseHudFrame
        orb:SetPoint("CENTER", parentFrame, "CENTER", anim.currentX, anim.currentY)
      end
    end
  end
end

function UpdateOrbs()
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
  
  -- If camera is not yet initialized, keep orbs completely hidden
  -- (except in test mode) so they don't briefly flash with
  -- incorrect camera settings in the first combat.
  if not orbsCameraReady and not IsTestModeEnabled() then
    for i = 1, #orbs do
      if orbs[i] then
        orbs[i]:Hide()
      end
    end
    return
  end
  
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
        local layout = GetOrbsLayoutType()
        local radius = GetOrbsRadius()

        if layout == "horizontal" then
          -- Evenly distribute orbs along a horizontal line centered on (0,0)
          if activeCount == 1 then
            x = 0
            y = 0
          else
            local spacing = radius
            local middleIndex = (activeCount + 1) / 2
            local offsetFromMiddle = i - middleIndex
            x = offsetFromMiddle * spacing
            y = 0
          end
        elseif layout == "vertical" then
          -- Evenly distribute orbs along a vertical line centered on (0,0)
          if activeCount == 1 then
            x = 0
            y = 0
          else
            local spacing = radius
            local middleIndex = (activeCount + 1) / 2
            local offsetFromMiddle = i - middleIndex
            x = 0
            y = offsetFromMiddle * spacing
          end
        else
          -- Default circular / arc layout
          if activeCount == 1 then
            x = 0
            y = 0
          else
            local angleStep = ARC_LENGTH / activeCount
            local middleIndex = math.ceil(activeCount / 2)
            local offsetFromMiddle = (middleIndex - i) * angleStep
            local angle = TOP_ANGLE - offsetFromMiddle
            x = math.cos(angle) * radius
            y = math.sin(angle) * radius
          end
        end
        
        local offsetX = GetOrbsX()
        local offsetY = GetOrbsY()
        x = x + offsetX
        y = y + offsetY
        
        local anim = orbAnimations[i]
        if anim then
          anim.targetX = x
          anim.targetY = y
          -- First-time init is handled in WiseHudOrbs_UpdateAnimations via nil sentinel.
        end
        
        SetOrbActive(i, true)
      else
        SetOrbActive(i, false)
      end
    end
  end

  -- After each layout update, we enforce the current camera position
  -- for all orbs, so that later changes (e.g. by the client when
  -- loading models) are overwritten again.
  EnsureCameraPosition()
end

function EnsureCameraPosition(force)
  -- Lightweight: apply to shown or already-loaded models.
  -- Hidden orbs that haven't loaded yet are handled by WaitForModelsAndSetCamera
  -- during explicit preset/model changes and first-login initialization.
  force = force == true
  for i, orb in ipairs(orbs) do
    if orb then
      SetOrbCameraPosition(orb, force)
    end
  end
end

local function CancelCameraStabilization()
  if cameraStabilizeTicker and cameraStabilizeTicker.Cancel then
    pcall(cameraStabilizeTicker.Cancel, cameraStabilizeTicker)
  end
  cameraStabilizeTicker = nil
end

local function StartCameraStabilization()
  -- Re-apply camera a few times to "win" against late client changes.
  -- This is cancelable so we don't accumulate many overlapping timers.
  CancelCameraStabilization()

  if not C_Timer then
    return
  end

  if C_Timer.NewTicker then
    cameraStabilizeTicker = C_Timer.NewTicker(0.5, function()
      EnsureCameraPosition(true)
    end, 8)
    return
  end

  if C_Timer.After then
    local times = {0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0}
    for _, delay in ipairs(times) do
      C_Timer.After(delay, function()
        EnsureCameraPosition(true)
      end)
    end
  end
end

function WiseHudOrbs_OnPlayerLogin()
  -- Reset testMode on login (not persisted)
  local cfg = GetOrbsSettings()
  cfg.testMode = nil
  orbsReinitializedAfterFirstPoints = false
  
  if #orbs > 0 then
    for i, orb in ipairs(orbs) do
      if orb then
        orb:Hide()
        if orb.fallbackTexture then orb.fallbackTexture:Hide() end
      end
    end
    orbs = {}
    orbAnimations = {}
  end

  -- Delay orb creation slightly after login/reload so the game client and
  -- other addons have time to finish their own model/camera initialization.
  -- This avoids showing "ugly" orbs during the first moments after loading.
  if C_Timer and C_Timer.After then
    C_Timer.After(2.0, function()
      if not IsOrbsEnabled() then return end

      CreateOrbs()

      -- Special initialization for the case where we log in with 0 resources:
      -- ensures that the camera is set once properly,
      -- even if all orbs are (still) hidden.
      InitializeOrbsCameraAfterLogin()

      -- Apply camera immediately once after creation so the initial
      -- visible state already uses the correct camera settings.
      if WiseHudOrbs_UpdateCameraPosition then
        WiseHudOrbs_UpdateCameraPosition()
      end

      -- Now position/update orbs based on current power so they appear.
      UpdateOrbs()
    end)
  else
    -- Fallback: immediate creation if C_Timer is unavailable
    CreateOrbs()
    if WiseHudOrbs_UpdateCameraPosition then
      WiseHudOrbs_UpdateCameraPosition()
    end
    UpdateOrbs()
  end

end

function WiseHudOrbs_OnPowerUpdate(unit, powerType)
  if unit ~= "player" then return end
  
  if powerType then
    local currentType = GetPowerTypeForClass()
    if powerType == currentType or IsComboPointType(powerType) then
      -- When we see points > 0 for the first time after a fresh login/relog,
      -- we force a one-time complete re-create of the orbs. This effectively
      -- mirrors the behavior of a /reload and fixes cases where the client
      -- doesn't correctly render individual PlayerModel frames.
      local points = GetComboPoints()

      -- Track combo-like resource changes separately from the main
      -- power resource so Orbs can use their own alpha fade logic.
      if WiseHudCombatInfo then
        if lastKnownPoints == nil or points ~= lastKnownPoints then
          lastKnownPoints = points
          WiseHudCombatInfo.lastOrbChange = GetTime()
        end
      end
      if points > 0 and not orbsReinitializedAfterFirstPoints then
        orbsReinitializedAfterFirstPoints = true

        -- Hard reset existing orbs
        for i, orb in ipairs(orbs) do
          if orb then
            orb:Hide()
            if orb.fallbackTexture then orb.fallbackTexture:Hide() end
          end
        end
        orbs = {}
        orbAnimations = {}

        -- Rebuild + apply camera + update layout
        CreateOrbs()
        if WiseHudOrbs_UpdateCameraPosition then
          WiseHudOrbs_UpdateCameraPosition()
        end
      end

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
  -- Make sure all orb models are loaded (also for currently inactive/hidden orbs)
  if WiseHudOrbs_ApplyModelPathToExistingOrbs then
    WiseHudOrbs_ApplyModelPathToExistingOrbs()
  end

  -- Apply camera immediately (forced) and then stabilize it briefly
  EnsureCameraPosition(true)

  -- Mark camera as initialized and fade orbs in with a fresh layout update
  if not orbsCameraReady then
    orbsCameraReady = true
    -- Apply alpha once on the shared parent frame instead
    -- of per-orb to keep behavior centralized.
    WiseHudOrbs_ApplyAlpha()
    UpdateOrbs()
  else
    -- Even after initialization, re-apply camera (forced) for all orbs.
    EnsureCameraPosition(true)
  end

  StartCameraStabilization()
end

function WiseHudOrbs_UpdateCameraOnly()
  EnsureCameraPosition(true)
  StartCameraStabilization()
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
