local ADDON_NAME = ...

-- Player power/energy bar module for WiseHud

local WiseHud = WiseHudFrame

local POWER_TEXTURE    = "Interface\\AddOns\\WiseHud\\textures\\CleanCurves"
local POWER_BG         = "Interface\\AddOns\\WiseHud\\textures\\CleanCurvesBG"

local DEFAULT_BAR_WIDTH   = 290
local DEFAULT_BAR_HEIGHT  = 415
local DEFAULT_BAR_OFFSETX = 185
local DEFAULT_BAR_OFFSETY = 90

-- Alpha defaults in percent (0–100)
local DEFAULT_ALPHA_COMBAT    = 70
local DEFAULT_ALPHA_NONFULL   = 40
local DEFAULT_ALPHA_FULL_IDLE = 0

-- Colors based on IceHUD PlayerMana defaults
local ICEHUD_POWER_COLORS = {
  MANA        = {  62 / 255,  54 / 255, 152 / 255 },
  RAGE        = { 171 / 255,  59 / 255,  59 / 255 },
  ENERGY      = { 218 / 255, 231 / 255,  31 / 255 },
  FOCUS       = { 242 / 255, 149 / 255,  98 / 255 },
  RUNIC_POWER = {  62 / 255,  54 / 255, 152 / 255 },
  INSANITY    = { 150 / 255,  50 / 255, 255 / 255 },
  FURY        = { 201 / 255,  66 / 255, 253 / 255 },
  MAELSTROM   = {  62 / 255,  54 / 255, 152 / 255 },
  PAIN        = { 255 / 255, 156 / 255,   0 / 255 },
}

local powerBar, powerBG
local currentAlpha = 0
local targetAlpha  = 0

local function GetBarLayout()
  local cfg = (WiseHudDB and WiseHudDB.barLayout) or {}
  local w  = cfg.width   or DEFAULT_BAR_WIDTH
  local h  = cfg.height  or DEFAULT_BAR_HEIGHT
  local ox = cfg.offset  or DEFAULT_BAR_OFFSETX
  local oy = cfg.offsetY or DEFAULT_BAR_OFFSETY
  return w, h, ox, oy
end

local function IsPowerEnabled()
  local cfg = (WiseHudDB and WiseHudDB.barLayout) or {}
  return cfg.powerEnabled ~= false
end

local FADE_IDLE_DELAY = 5 -- Seconds since last power change until full idle

local function GetAlphaSettings()
  WiseHudDB = WiseHudDB or {}
  WiseHudDB.alphaSettings = WiseHudDB.alphaSettings or {}
  local cfg = WiseHudDB.alphaSettings
  local combat    = cfg.combatAlpha    or DEFAULT_ALPHA_COMBAT
  local nonFull   = cfg.nonFullAlpha   or DEFAULT_ALPHA_NONFULL
  local fullIdle  = cfg.fullIdleAlpha  or DEFAULT_ALPHA_FULL_IDLE
  return combat / 100, nonFull / 100, fullIdle / 100
end

function WiseHudPower_ApplyAlpha()
  if not powerBar or not powerBG then return end
  
  -- Check if Power is enabled
  if not IsPowerEnabled() then
    powerBar:Hide()
    powerBG:Hide()
    return
  end

  local combatAlpha, nonFullAlpha, fullIdleAlpha = GetAlphaSettings()

  local inCombat = (WiseHudCombatInfo and WiseHudCombatInfo.inCombat)
    or (UnitAffectingCombat("player") and true or false)

  local sinceChange = WiseHudCombatInfo and WiseHudCombatInfo.lastPowerChange
    and (GetTime() - WiseHudCombatInfo.lastPowerChange) or nil

  if inCombat then
    targetAlpha = combatAlpha
  elseif sinceChange and sinceChange < FADE_IDLE_DELAY then
    -- Recently power changed -> non-full alpha
    targetAlpha = nonFullAlpha
  else
    -- No change for a long time -> full idle
    targetAlpha = fullIdleAlpha
  end

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

  if currentAlpha == nil then
    currentAlpha = targetAlpha
  end

  local speed = 5 -- Higher = faster transitions
  local diff = targetAlpha - currentAlpha

  if math.abs(diff) < 0.01 then
    currentAlpha = targetAlpha
  else
    currentAlpha = currentAlpha + diff * math.min(1, speed * elapsed)
  end

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
  
  local w, h, offsetX, offsetY = GetBarLayout()

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
    powerBar:SetValue(power)

    -- Check for custom color first
    WiseHudDB = WiseHudDB or {}
    WiseHudDB.barLayout = WiseHudDB.barLayout or {}
    local cfg = WiseHudDB.barLayout
    
    if cfg.powerR ~= nil and cfg.powerG ~= nil and cfg.powerB ~= nil then
      -- Use custom color
      powerBar:SetStatusBarColor(cfg.powerR / 255, cfg.powerG / 255, cfg.powerB / 255)
    else
      -- Color like in IceHUD
      local clr
      if powerToken and ICEHUD_POWER_COLORS[powerToken] then
        clr = ICEHUD_POWER_COLORS[powerToken]
      elseif ICEHUD_POWER_COLORS[powerType] then
        clr = ICEHUD_POWER_COLORS[powerType]
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