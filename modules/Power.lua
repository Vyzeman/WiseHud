local ADDON_NAME = ...

-- Player power/energy bar module for WiseHud

local WiseHud = WiseHudFrame

-- Central defaults (shared with Health, provided by Core)
local HP_DEFAULTS = WiseHudHP_DEFAULTS or WiseHudConfig.GetHealthPowerDefaults()

local POWER_TEXTURE    = "Interface\\AddOns\\WiseHud\\textures\\CleanCurves"
local POWER_BG         = "Interface\\AddOns\\WiseHud\\textures\\CleanCurvesBG"

-- Default per-power-type colors from central config (normalized 0-1)
local POWER_TYPE_COLORS = HP_DEFAULTS.powerTypeColors

local powerBar, powerBG
local currentAlpha = 0
local targetAlpha  = 0

local function IsPowerEnabled()
  local cfg = (WiseHudDB and WiseHudDB.barLayout) or {}
  return cfg.powerEnabled ~= false
end

function WiseHudPower_ApplyAlpha()
  if not powerBar or not powerBG then return end
  
  -- Check if Power is enabled
  if not IsPowerEnabled() then
    powerBar:Hide()
    powerBG:Hide()
    return
  end

  -- Compute the desired alpha for the power bar from shared helper
  targetAlpha = WiseHudHP_ComputeTargetAlpha("lastPowerChange")

  -- Initial snapping if no alpha has been set yet
  if currentAlpha == nil then
    currentAlpha = targetAlpha
    powerBar:SetAlpha(currentAlpha)
    powerBG:SetAlpha(currentAlpha)
  end
end

function WiseHudPower_UpdateAlpha(elapsed)
  if not powerBar or not powerBG then return end
  if targetAlpha == nil then return end
  
  currentAlpha = WiseHudHP_SmoothAlpha(currentAlpha, targetAlpha, elapsed)

  powerBar:SetAlpha(currentAlpha)
  powerBG:SetAlpha(currentAlpha)
end

function WiseHudPower_ApplyLayout()
  if not powerBar or not powerBG then return end
  
  -- Check if Power is enabled
  if not IsPowerEnabled() then
    powerBar:Hide()
    powerBG:Hide()
    return
  end
  
  local w, h, offsetX, offsetY = WiseHudHP_GetBarLayout()

  powerBG:SetSize(w, h)
  powerBG:ClearAllPoints()
  powerBG:SetPoint("LEFT", WiseHud, "CENTER", offsetX, offsetY)
  powerBG:Show()

  powerBar:SetSize(w, h)
  powerBar:ClearAllPoints()
  powerBar:SetPoint("LEFT", WiseHud, "CENTER", offsetX, offsetY)
  powerBar:Show()
end

local function CreatePowerBar()
  if powerBar then return end

  powerBG = WiseHud:CreateTexture(nil, "BACKGROUND")
  powerBG:SetTexture(POWER_BG)


  powerBar = CreateFrame("StatusBar", "WiseHudPower", WiseHud)
  powerBar:SetStatusBarTexture(POWER_TEXTURE)
  powerBar:SetOrientation("VERTICAL")
  powerBar:SetMinMaxValues(0, 1)
  powerBar:SetValue(1)

  local pbTex = powerBar:GetStatusBarTexture()
  if pbTex then
    pbTex:SetTexCoord(1, 0, 0, 1)
  end

  -- Apply layout (size/position)
  WiseHudPower_ApplyLayout()
  WiseHudPower_ApplyAlpha()
  -- Jump directly to target alpha when creating
  currentAlpha = targetAlpha
  powerBar:SetAlpha(currentAlpha)
  powerBG:SetAlpha(currentAlpha)
end

local function UpdatePower()
  if not powerBar then return end
  local powerType, powerToken = UnitPowerType("player")
  local power = UnitPower("player", powerType)
  local powerMax = UnitPowerMax("player", powerType)

  if powerMax and powerMax > 0 then
    powerBar:SetMinMaxValues(0, powerMax)
    -- Directly set the player power value (no smoothing, avoids secret-value math issues)
    powerBar:SetValue(power)

    -- Check for custom color first
    WiseHudDB = WiseHudDB or {}
    WiseHudDB.barLayout = WiseHudDB.barLayout or {}
    local cfg = WiseHudDB.barLayout
    
    if cfg.powerR ~= nil and cfg.powerG ~= nil and cfg.powerB ~= nil then
      -- Use custom color
      powerBar:SetStatusBarColor(cfg.powerR / 255, cfg.powerG / 255, cfg.powerB / 255)
    else
      -- Color like in IceHUD, from central config
      local clr
      if powerToken and POWER_TYPE_COLORS[powerToken] then
        clr = POWER_TYPE_COLORS[powerToken]
      elseif POWER_TYPE_COLORS[powerType] then
        clr = POWER_TYPE_COLORS[powerType]
      end

      if clr then
        powerBar:SetStatusBarColor(clr[1], clr[2], clr[3])
      end
    end
  end

  WiseHudPower_ApplyAlpha()
end

function WiseHudPower_OnPlayerLogin()
  CreatePowerBar()
  UpdatePower()
end

function WiseHudPower_OnPowerEvent(unit, powerType)
  if unit ~= "player" then return end
  UpdatePower()
end

-- Called by options to enable/disable Power
function WiseHudPower_SetEnabled(enabled)
  local cfg = (WiseHudDB and WiseHudDB.barLayout) or {}
  cfg.powerEnabled = enabled
  WiseHudPower_ApplyLayout()
  WiseHudPower_ApplyAlpha()
end

function WiseHudPower_UpdateColor()
  if not powerBar then return end
  UpdatePower() -- This will apply the color
end