local ADDON_NAME = ...

-- Player cast bar module for WiseHud

local WiseHud = WiseHudFrame

-- Central defaults
local CAST_DEFAULTS = WiseHudConfig.GetCastDefaults()

-- Use LibSharedMedia-3.0 (if available) so textures from other addons
-- (e.g. ElvUI) can be selected dynamically.
local LSM = nil
do
  local libStub = _G.LibStub
  if libStub and type(libStub) == "table" and type(libStub.GetLibrary) == "function" then
    LSM = libStub:GetLibrary("LibSharedMedia-3.0", true)
  end
end

-- Fallback texture when LSM is not available or texture not found
local FALLBACK_TEXTURE = "Interface\\TargetingFrame\\UI-StatusBar"

local function FetchStatusBarTexture(name)
  if type(name) ~= "string" or name == "" then
    name = "Blizzard"
  end

  -- Update LSM reference in case it loaded later
  if not LSM then
    local libStub = _G.LibStub
    if libStub and type(libStub) == "table" and type(libStub.GetLibrary) == "function" then
      LSM = libStub:GetLibrary("LibSharedMedia-3.0", true)
    end
  end

  -- Always try LSM first
  if LSM and LSM.Fetch then
    local tex = LSM:Fetch("statusbar", name, true)
    if tex then
      return tex
    end
  end

  -- Fallback to Blizzard texture if LSM not available or texture not found
  return FALLBACK_TEXTURE
end

local function GetCastTexture()
  WiseHudDB = WiseHudDB or {}
  WiseHudDB.castLayout = WiseHudDB.castLayout or {}
  local cfg = WiseHudDB.castLayout

  -- Use texture (new unified option), fallback to fillTexture/bgTexture for backward compatibility,
  -- then to the central default texture name.
  local name = cfg.texture or cfg.fillTexture or cfg.bgTexture or CAST_DEFAULTS.textureName
  return FetchStatusBarTexture(name)
end

local function GetFillTexture()
  return GetCastTexture()
end

local function GetBackgroundTexture()
  return GetCastTexture()
end

-- Default cast bar color (from central config)
local DEFAULT_CAST_COLOR_R = (CAST_DEFAULTS.fill.r or 242) / 255
local DEFAULT_CAST_COLOR_G = (CAST_DEFAULTS.fill.g or 242) / 255
local DEFAULT_CAST_COLOR_B = (CAST_DEFAULTS.fill.b or 10) / 255

-- Default background color (from central config)
local DEFAULT_BG_COLOR_R = (CAST_DEFAULTS.bg.r or 77) / 255
local DEFAULT_BG_COLOR_G = (CAST_DEFAULTS.bg.g or 77) / 255
local DEFAULT_BG_COLOR_B = (CAST_DEFAULTS.bg.b or 77) / 255
local DEFAULT_BG_COLOR_A = (CAST_DEFAULTS.bg.a or 80) / 100

local function GetCastColor()
  WiseHudDB = WiseHudDB or {}
  WiseHudDB.castLayout = WiseHudDB.castLayout or {}
  local cfg = WiseHudDB.castLayout
  local r = cfg.fillR ~= nil and cfg.fillR / 255 or DEFAULT_CAST_COLOR_R
  local g = cfg.fillG ~= nil and cfg.fillG / 255 or DEFAULT_CAST_COLOR_G
  local b = cfg.fillB ~= nil and cfg.fillB / 255 or DEFAULT_CAST_COLOR_B
  return r, g, b
end

local function GetBackgroundColor()
  WiseHudDB = WiseHudDB or {}
  WiseHudDB.castLayout = WiseHudDB.castLayout or {}
  local cfg = WiseHudDB.castLayout
  local r = cfg.bgR ~= nil and cfg.bgR / 255 or DEFAULT_BG_COLOR_R
  local g = cfg.bgG ~= nil and cfg.bgG / 255 or DEFAULT_BG_COLOR_G
  local b = cfg.bgB ~= nil and cfg.bgB / 255 or DEFAULT_BG_COLOR_B
  local a = cfg.bgA ~= nil and cfg.bgA / 100 or DEFAULT_BG_COLOR_A
  return r, g, b, a
end

-- Default cast bar dimensions (from central config)
local DEFAULT_CAST_WIDTH = CAST_DEFAULTS.width or 200
local DEFAULT_CAST_HEIGHT = CAST_DEFAULTS.height or 20
local DEFAULT_CAST_OFFSETX = CAST_DEFAULTS.offsetX or 0
local DEFAULT_CAST_OFFSETY = CAST_DEFAULTS.offsetY or -200

local castBar, castBG, castIcon
local isCasting = false
local isChanneling = false
local castStartTime = 0
local castDuration = 0
local castEndTime = 0
local castSpellName = ""
local castSpellIcon = nil

local function GetCastLayout()
  WiseHudDB = WiseHudDB or {}
  WiseHudDB.castLayout = WiseHudDB.castLayout or {}
  local cfg = WiseHudDB.castLayout
  local w = cfg.width or DEFAULT_CAST_WIDTH
  local h = cfg.height or DEFAULT_CAST_HEIGHT
  local ox = cfg.offsetX or DEFAULT_CAST_OFFSETX
  local oy = cfg.offsetY or DEFAULT_CAST_OFFSETY
  return w, h, ox, oy
end

local function IsCastEnabled()
  WiseHudDB = WiseHudDB or {}
  WiseHudDB.castLayout = WiseHudDB.castLayout or {}
  local cfg = WiseHudDB.castLayout
  return cfg.enabled ~= false
end

local function IsTextEnabled()
  WiseHudDB = WiseHudDB or {}
  WiseHudDB.castLayout = WiseHudDB.castLayout or {}
  local cfg = WiseHudDB.castLayout
  if cfg.showText == nil then
    return CAST_DEFAULTS.showText -- Default from central config
  end
  return cfg.showText
end

local function CreateCastBar()
  if castBar then return end
  if not WiseHud then return end

  -- Background
  castBG = WiseHud:CreateTexture(nil, "BACKGROUND")
  castBG:SetTexture(GetBackgroundTexture())
  local bgR, bgG, bgB, bgA = GetBackgroundColor()
  castBG:SetVertexColor(bgR, bgG, bgB, bgA)
  castBG:Hide()

  -- Foreground bar
  castBar = CreateFrame("StatusBar", "WiseHudCast", WiseHud)
  castBar:SetStatusBarTexture(GetFillTexture())
  castBar:SetOrientation("HORIZONTAL")
  local fillR, fillG, fillB = GetCastColor()
  castBar:SetStatusBarColor(fillR, fillG, fillB)
  castBar:SetMinMaxValues(0, 1)
  castBar:SetValue(0)
  castBar:Hide()

  -- Icon
  castIcon = castBar:CreateTexture(nil, "ARTWORK")
  castIcon:SetSize(20, 20)
  castIcon:SetPoint("RIGHT", castBar, "LEFT", -5, 0)
  castIcon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
  castIcon:Hide()

  -- Spell name text
  local castText = castBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  castText:SetPoint("CENTER", castBar, "CENTER", 0, 0)
  castText:SetTextColor(1, 1, 1)
  castBar.text = castText

  WiseHudCast_ApplyLayout()
end

function WiseHudCast_ApplyLayout()
  if not castBar or not castBG then return end

  if not IsCastEnabled() then
    castBar:Hide()
    castBG:Hide()
    castIcon:Hide()
    if castBar.text then castBar.text:Hide() end
    return
  end

  local w, h, offsetX, offsetY = GetCastLayout()

  castBG:SetSize(w, h)
  castBG:ClearAllPoints()
  castBG:SetPoint("CENTER", WiseHud, "CENTER", offsetX, offsetY)
  -- Only show background if actually casting
  if not isCasting and not isChanneling then
    castBG:Hide()
  end

  castBar:SetSize(w, h)
  castBar:ClearAllPoints()
  castBar:SetPoint("CENTER", WiseHud, "CENTER", offsetX, offsetY)
  -- Only show bar if actually casting
  if not isCasting and not isChanneling then
    castBar:Hide()
    castIcon:Hide()
    if castBar.text then castBar.text:Hide() end
  else
    -- Show/hide text based on setting
    if castBar.text then
      if IsTextEnabled() then
        castBar.text:Show()
      else
        castBar.text:Hide()
      end
    end
  end
end

function WiseHudCast_Update(elapsed)
  if not castBar or not isCasting and not isChanneling then
    return
  end

  local currentTime = GetTime()
  local remaining = 0
  local progress = 0

  if isChanneling then
    remaining = castEndTime - currentTime
    if remaining <= 0 then
      remaining = 0
      isChanneling = false
      castBar:Hide()
      castBG:Hide()
      castIcon:Hide()
      return
    end
    progress = remaining / castDuration
  else
    remaining = castEndTime - currentTime
    if remaining <= 0 then
      remaining = 0
      isCasting = false
      castBar:Hide()
      castBG:Hide()
      castIcon:Hide()
      return
    end
    progress = 1 - (remaining / castDuration)
  end

  castBar:SetValue(progress)
end

function WiseHudCast_OnPlayerLogin()
  CreateCastBar()
end

function WiseHudCast_OnSpellCastStart(unit, castGUID, spellID)
  if unit ~= "player" then return end
  if not IsCastEnabled() then return end

  local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible, spellId = UnitCastingInfo("player")
  if not name then
    return
  end

  isCasting = true
  isChanneling = false
  castStartTime = startTime / 1000
  castEndTime = endTime / 1000
  castDuration = castEndTime - castStartTime
  castSpellName = name
  castSpellIcon = texture

  if castBar then
    local fillR, fillG, fillB = GetCastColor()
    castBar:SetStatusBarColor(fillR, fillG, fillB)
    castBar:SetValue(0)
    if castBar.text then
      if IsTextEnabled() then
        castBar.text:SetText(name)
        castBar.text:Show()
      else
        castBar.text:Hide()
      end
    end
    if castIcon and texture then
      castIcon:SetTexture(texture)
      castIcon:Show()
    end
    castBar:Show()
    castBG:Show()
  end
end

function WiseHudCast_OnSpellCastStop(unit, castGUID, spellID)
  if unit ~= "player" then return end

  -- If we're channeling, ignore this event - it's likely from double-pressing
  -- the channel ability. Only UNIT_SPELLCAST_CHANNEL_STOP should stop channels.
  if isChanneling then
    -- Verify that we're still actually channeling
    local name = UnitChannelInfo("player")
    if name then
      -- Still channeling, ignore this stop event
      return
    end
    -- Not channeling anymore, but isChanneling was true - channel must have ended
    -- Let it fall through to clean up
  end

  isCasting = false
  isChanneling = false

  if castBar then
    castBar:Hide()
    castBG:Hide()
    castIcon:Hide()
  end
end

function WiseHudCast_OnSpellCastFailed(unit, castGUID, spellID)
  if unit ~= "player" then return end

  -- If we're channeling, ignore failed events (they can be false positives)
  if isChanneling then
    local name = UnitChannelInfo("player")
    if name then
      -- Still channeling, ignore this failed event
      return
    end
  end

  isCasting = false
  isChanneling = false

  if castBar then
    castBar:SetStatusBarColor(1, 0, 0)
    C_Timer.After(0.3, function()
      if castBar then
        castBar:Hide()
        castBG:Hide()
        castIcon:Hide()
      end
    end)
  end
end

function WiseHudCast_OnSpellCastInterrupted(unit, castGUID, spellID)
  if unit ~= "player" then return end

  -- If we're channeling, check if it's really interrupted
  if isChanneling then
    local name = UnitChannelInfo("player")
    if name then
      -- Still channeling, not actually interrupted (might be from double-press)
      return
    end
  end

  isCasting = false
  isChanneling = false

  if castBar then
    castBar:Hide()
    castBG:Hide()
    castIcon:Hide()
  end
end

function WiseHudCast_OnSpellCastDelayed(unit, castGUID, spellID)
  if unit ~= "player" then return end
  if not isCasting then return end

  local name, text, texture, startTime, endTime = UnitCastingInfo("player")
  if name then
    castStartTime = startTime / 1000
    castEndTime = endTime / 1000
    castDuration = castEndTime - castStartTime
  end
end

function WiseHudCast_OnSpellCastChannelStart(unit, castGUID, spellID)
  if unit ~= "player" then return end
  if not IsCastEnabled() then return end

  local name, text, texture, startTime, endTime, isTradeSkill, notInterruptible, spellId = UnitChannelInfo("player")
  if not name then
    return
  end

  isCasting = false
  isChanneling = true
  castStartTime = startTime / 1000
  castEndTime = endTime / 1000
  castDuration = castEndTime - castStartTime
  castSpellName = name
  castSpellIcon = texture

  if castBar then
    local fillR, fillG, fillB = GetCastColor()
    castBar:SetStatusBarColor(fillR, fillG, fillB)
    castBar:SetValue(1)
    if castBar.text then
      if IsTextEnabled() then
        castBar.text:SetText(name)
        castBar.text:Show()
      else
        castBar.text:Hide()
      end
    end
    if castIcon and texture then
      castIcon:SetTexture(texture)
      castIcon:Show()
    end
    castBar:Show()
    castBG:Show()
  end
end

function WiseHudCast_OnSpellCastChannelUpdate(unit, castGUID, spellID)
  if unit ~= "player" then return end
  if not isChanneling then return end

  local name, text, texture, startTime, endTime = UnitChannelInfo("player")
  if name then
    castStartTime = startTime / 1000
    castEndTime = endTime / 1000
    castDuration = castEndTime - castStartTime
  end
end

function WiseHudCast_OnSpellCastChannelStop(unit, castGUID, spellID)
  if unit ~= "player" then return end

  isCasting = false
  isChanneling = false

  if castBar then
    castBar:Hide()
    castBG:Hide()
    castIcon:Hide()
  end
end

function WiseHudCast_SetEnabled(enabled)
  WiseHudDB = WiseHudDB or {}
  WiseHudDB.castLayout = WiseHudDB.castLayout or {}
  WiseHudDB.castLayout.enabled = enabled
  WiseHudCast_ApplyLayout()
end

function WiseHudCast_UpdateTexture()
  -- Ensure castbar exists before updating
  if not castBar or not castBG then
    CreateCastBar()
    if not castBar or not castBG then return end
  end
  
  -- Update LSM reference in case it loaded later
  if not LSM then
    local libStub = _G.LibStub
    if libStub and type(libStub) == "table" and type(libStub.GetLibrary) == "function" then
      LSM = libStub:GetLibrary("LibSharedMedia-3.0", true)
    end
  end
  
  -- Update textures
  castBar:SetStatusBarTexture(GetFillTexture())
  castBG:SetTexture(GetBackgroundTexture())
end

function WiseHudCast_UpdateColors()
  -- Ensure castbar exists before updating
  if not castBar or not castBG then
    CreateCastBar()
    if not castBar or not castBG then return end
  end
  local fillR, fillG, fillB = GetCastColor()
  castBar:SetStatusBarColor(fillR, fillG, fillB)
  local bgR, bgG, bgB, bgA = GetBackgroundColor()
  castBG:SetVertexColor(bgR, bgG, bgB, bgA)
end
