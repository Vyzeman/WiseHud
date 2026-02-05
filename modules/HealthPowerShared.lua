local ADDON_NAME = ...

-- Shared helpers for Health/Power modules
local HP_DEFAULTS = WiseHudConfig.GetHealthPowerDefaults()

-- Expose shared defaults so Health/Power can reuse them without recomputing.
WiseHudHP_DEFAULTS = HP_DEFAULTS

local DEFAULT_BAR_WIDTH   = (HP_DEFAULTS.layout and HP_DEFAULTS.layout.width)   or 260
local DEFAULT_BAR_HEIGHT  = (HP_DEFAULTS.layout and HP_DEFAULTS.layout.height)  or 415
local DEFAULT_BAR_OFFSETX = (HP_DEFAULTS.layout and HP_DEFAULTS.layout.offsetX) or 200
local DEFAULT_BAR_OFFSETY = (HP_DEFAULTS.layout and HP_DEFAULTS.layout.offsetY) or 100

local DEFAULT_ALPHA_COMBAT    = (HP_DEFAULTS.alpha and HP_DEFAULTS.alpha.combat)   or 40
local DEFAULT_ALPHA_NONFULL   = (HP_DEFAULTS.alpha and HP_DEFAULTS.alpha.nonFull)  or 20
local DEFAULT_ALPHA_FULL_IDLE = (HP_DEFAULTS.alpha and HP_DEFAULTS.alpha.fullIdle) or 0

local FADE_IDLE_DELAY = 5 -- Seconds since last change until full idle alpha

-- Helper: safely detect whether a numeric value can be used in arithmetic
-- (avoids errors like "attempt to perform arithmetic on ... (a secret value)").
local function WiseHudHP_IsSafeNumber(v)
  if type(v) ~= "number" then
    return false
  end
  local ok = pcall(function()
    local _ = v + 0 -- will error if v is a "secret" value
  end)
  return ok
end

-- Returns layout for the curved health/power bars (width, height, offsetX, offsetY)
function WiseHudHP_GetBarLayout()
  local cfg = (WiseHudDB and WiseHudDB.barLayout) or {}
  local w  = cfg.width   or DEFAULT_BAR_WIDTH
  local h  = cfg.height  or DEFAULT_BAR_HEIGHT
  local ox = cfg.offset  or DEFAULT_BAR_OFFSETX
  local oy = cfg.offsetY or DEFAULT_BAR_OFFSETY
  return w, h, ox, oy
end

-- Returns alpha settings as 0-1 values (combat, nonFull, fullIdle)
function WiseHudHP_GetAlphaSettings()
  WiseHudDB = WiseHudDB or {}
  WiseHudDB.alphaSettings = WiseHudDB.alphaSettings or {}
  local cfg = WiseHudDB.alphaSettings
  local combat    = cfg.combatAlpha    or DEFAULT_ALPHA_COMBAT
  local nonFull   = cfg.nonFullAlpha   or DEFAULT_ALPHA_NONFULL
  local fullIdle  = cfg.fullIdleAlpha  or DEFAULT_ALPHA_FULL_IDLE
  return combat / 100, nonFull / 100, fullIdle / 100
end

-- Compute target alpha for a bar based on combat state and last-change timestamp field on WiseHudCombatInfo
function WiseHudHP_ComputeTargetAlpha(lastChangeField)
  local combatAlpha, nonFullAlpha, fullIdleAlpha = WiseHudHP_GetAlphaSettings()

  local inCombat = (WiseHudCombatInfo and WiseHudCombatInfo.inCombat)
    or (UnitAffectingCombat("player") and true or false)

  -- If the Orbs test mode is active, force combat alpha so the bars stay visible
  if WiseHudDB and WiseHudDB.comboSettings and WiseHudDB.comboSettings.testMode then
    inCombat = true
  end

  local sinceChange
  if WiseHudCombatInfo and WiseHudCombatInfo[lastChangeField] then
    sinceChange = GetTime() - WiseHudCombatInfo[lastChangeField]
  end

  if inCombat then
    return combatAlpha
  elseif sinceChange and sinceChange < FADE_IDLE_DELAY then
    return nonFullAlpha
  else
    return fullIdleAlpha
  end
end

-- Shared smoothing for alpha transitions (returns new currentAlpha)
function WiseHudHP_SmoothAlpha(currentAlpha, targetAlpha, elapsed)
  if targetAlpha == nil then
    return currentAlpha
  end

  if currentAlpha == nil then
    return targetAlpha
  end

  local speed = 5 -- Higher = faster transitions
  local diff = targetAlpha - currentAlpha

  if math.abs(diff) < 0.01 then
    return targetAlpha
  else
    return currentAlpha + diff * math.min(1, speed * elapsed)
  end
end

