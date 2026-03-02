local ADDON_NAME = ...

-- Player health bar module for WiseHud

local WiseHud = WiseHudFrame

-- Central defaults (shared with Power, provided by Core)
local HP_DEFAULTS = WiseHudHP_DEFAULTS or WiseHudConfig.GetHealthPowerDefaults()

local healthBar, healthBG, absorbBar
local currentAlpha = 0
local targetAlpha  = 0

-- Use flipped foreground texture so the fill follows the inner curve
local HEALTH_TEXTURE   = "Interface\\AddOns\\WiseHud\\textures\\CleanCurves-flipped"
local HEALTH_BG        = "Interface\\AddOns\\WiseHud\\textures\\CleanCurvesBG"

-- Light overlay color for absorbs (rendered behind the main health bar)
local DEFAULT_ABSORB_COLOR_R = 0.95
local DEFAULT_ABSORB_COLOR_G = 0.95
local DEFAULT_ABSORB_COLOR_B = 0.95

-- Local alias for the absorb API (may be nil on very old clients)
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs

-- Default health bar color (from central defaults, based on IceHUD PlayerHealth)
local DEFAULT_HEALTH_COLOR_R = (HP_DEFAULTS.colors.health.r or 37) / 255
local DEFAULT_HEALTH_COLOR_G = (HP_DEFAULTS.colors.health.g or 164) / 255
local DEFAULT_HEALTH_COLOR_B = (HP_DEFAULTS.colors.health.b or 30) / 255

local function GetHealthColor()
  WiseHudDB = WiseHudDB or {}
  WiseHudDB.barLayout = WiseHudDB.barLayout or {}
  local cfg = WiseHudDB.barLayout
  local r = cfg.healthR ~= nil and cfg.healthR / 255 or DEFAULT_HEALTH_COLOR_R
  local g = cfg.healthG ~= nil and cfg.healthG / 255 or DEFAULT_HEALTH_COLOR_G
  local b = cfg.healthB ~= nil and cfg.healthB / 255 or DEFAULT_HEALTH_COLOR_B
  return r, g, b
end

function WiseHudHealth_UpdateColor()
  if not healthBar then return end
  local r, g, b = GetHealthColor()
  healthBar:SetStatusBarColor(r, g, b)
end

local function IsHealthEnabled()
  local cfg = (WiseHudDB and WiseHudDB.barLayout) or {}
  return cfg.healthEnabled ~= false
end

function WiseHudHealth_ApplyAlpha()
  if not healthBar or not healthBG then return end
  
  -- Check if Health is enabled
  if not IsHealthEnabled() then
    healthBar:Hide()
    healthBG:Hide()
    if absorbBar then
      absorbBar:Hide()
    end
    return
  end

  -- Compute the desired alpha for the health bar from shared helper
  targetAlpha = WiseHudHP_ComputeTargetAlpha("lastHealthChange")

  -- Initial snapping if no alpha has been set yet
  if currentAlpha == nil then
    currentAlpha = targetAlpha
    healthBar:SetAlpha(currentAlpha)
    healthBG:SetAlpha(currentAlpha)
    if absorbBar then
      absorbBar:SetAlpha(currentAlpha)
    end
  end
end

function WiseHudHealth_UpdateAlpha(elapsed)
  if not healthBar or not healthBG then return end
  if targetAlpha == nil then return end
  
  currentAlpha = WiseHudHP_SmoothAlpha(currentAlpha, targetAlpha, elapsed)

  healthBar:SetAlpha(currentAlpha)
  healthBG:SetAlpha(currentAlpha)
  if absorbBar then
    absorbBar:SetAlpha(currentAlpha)
  end
end

function WiseHudHealth_ApplyLayout()
  if not healthBar or not healthBG then return end
  
  -- Check if Health is enabled
  if not IsHealthEnabled() then
    healthBar:Hide()
    healthBG:Hide()
    return
  end
  
  local w, h, offsetX, offsetY = WiseHudHP_GetBarLayout()

  healthBG:SetSize(w, h)
  healthBG:ClearAllPoints()
  healthBG:SetPoint("RIGHT", WiseHud, "CENTER", -offsetX, offsetY)
  healthBG:SetTexCoord(1, 0, 0, 1)
  healthBG:Show()

  healthBar:SetSize(w, h)
  healthBar:ClearAllPoints()
  healthBar:SetPoint("RIGHT", WiseHud, "CENTER", -offsetX, offsetY)
  healthBar:Show()
end

-- Update the absorb overlay so it reflects current absorbs.
-- WoW 12.0 Secret Values:
-- Treat the return value from UnitGetTotalAbsorbs as an opaque value
-- and avoid doing any math or comparisons with it. We only pass it
-- directly into the status bar API to avoid secret-value errors.
local function UpdateAbsorb(hp, hpMax)
  if not absorbBar or not UnitGetTotalAbsorbs then return end
  if not hpMax or hpMax <= 0 then
    absorbBar:Hide()
    return
  end

  local totalAbsorbs = UnitGetTotalAbsorbs("player")
  if not totalAbsorbs then
    absorbBar:Hide()
    return
  end

  absorbBar:SetMinMaxValues(0, hpMax)
  absorbBar:SetValue(totalAbsorbs)
  absorbBar:Show()
end

local function CreateHealthBar()
  if healthBar then return end
  if not WiseHud then return end

  -- Background on the left side
  healthBG = WiseHud:CreateTexture(nil, "BACKGROUND")
  healthBG:SetTexture(HEALTH_BG)

  -- Foreground bar
  healthBar = CreateFrame("StatusBar", "WiseHudHealth", WiseHud)
  healthBar:SetStatusBarTexture(HEALTH_TEXTURE)
  healthBar:SetOrientation("VERTICAL")
  local r, g, b = GetHealthColor()
  healthBar:SetStatusBarColor(r, g, b)
  healthBar:SetMinMaxValues(0, 1)
  healthBar:SetValue(1)

  -- Absorb overlay bar (sits above the main health bar)
  absorbBar = CreateFrame("StatusBar", "WiseHudAbsorb", healthBar)
  absorbBar:SetStatusBarTexture(HEALTH_TEXTURE)
  absorbBar:SetOrientation("VERTICAL")
  -- No reverse fill: grows like the main health bar from bottom to top
  absorbBar:SetStatusBarColor(DEFAULT_ABSORB_COLOR_R, DEFAULT_ABSORB_COLOR_G, DEFAULT_ABSORB_COLOR_B)
  absorbBar:SetMinMaxValues(0, 1)
  absorbBar:SetValue(0)
  absorbBar:SetFrameStrata(healthBar:GetFrameStrata())
  absorbBar:SetFrameLevel(healthBar:GetFrameLevel() + 1)
  absorbBar:ClearAllPoints()
  absorbBar:SetAllPoints(healthBar)
  absorbBar:Hide()

  -- Apply layout (size/position)
  WiseHudHealth_ApplyLayout()
  WiseHudHealth_ApplyAlpha()
  -- Jump directly to target alpha when creating
  currentAlpha = targetAlpha
  healthBar:SetAlpha(currentAlpha)
  healthBG:SetAlpha(currentAlpha)
  if absorbBar then
    absorbBar:SetAlpha(currentAlpha)
  end
end

local function UpdateHealth()
  if not healthBar then return end
  local hp = UnitHealth("player")
  local hpMax = UnitHealthMax("player")
  if hpMax and hpMax > 0 then
    healthBar:SetMinMaxValues(0, hpMax)
    -- Directly set the player health value (no smoothing, avoids secret-value math issues)
    healthBar:SetValue(hp)
    UpdateAbsorb(hp, hpMax)
  elseif absorbBar then
    absorbBar:Hide()
  end

  WiseHudHealth_ApplyAlpha()
end

function WiseHudHealth_OnPlayerLogin()
  CreateHealthBar()
  UpdateHealth()
end

function WiseHudHealth_OnHealthEvent(unit)
  if unit ~= "player" then return end
  UpdateHealth()
end

-- Called by options to enable/disable Health
function WiseHudHealth_SetEnabled(enabled)
  local cfg = (WiseHudDB and WiseHudDB.barLayout) or {}
  cfg.healthEnabled = enabled
  WiseHudHealth_ApplyLayout()
  WiseHudHealth_ApplyAlpha()
end

