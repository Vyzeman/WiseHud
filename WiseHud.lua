local ADDON_NAME = ...

WiseHudDB = WiseHudDB or {}

-- True when a Midnight/Forever API returned a secret value.
-- Secret values may be stored and passed to widgets, but not compared.
function WiseHud_IsSecret(value)
  return type(issecretvalue) == "function" and issecretvalue(value) or false
end

local WiseHud = CreateFrame("Frame", "WiseHudFrame", UIParent)

-- Frame layout
local HUD_OFFSET_Y = -145
-- Health/Power/Combo modules live in modules/*.lua and hook into events below

WiseHud:SetScript("OnEvent", function(self, event, ...)
  if event == "PLAYER_LOGIN" then
    -- Position the HUD centered like ArcHUD
    WiseHud:ClearAllPoints()
    WiseHud:SetPoint("CENTER", UIParent, "CENTER", 0, HUD_OFFSET_Y)

    if WiseHudOptions_OnPlayerLogin then
      WiseHudOptions_OnPlayerLogin()
    end

    -- Core init (combat/change state)
    if WiseHudCore_OnPlayerLogin then
      WiseHudCore_OnPlayerLogin()
    end

    if WiseHudHealth_OnPlayerLogin then
      WiseHudHealth_OnPlayerLogin()
    end
    if WiseHudPower_OnPlayerLogin then
      WiseHudPower_OnPlayerLogin()
    end
    if WiseHudOrbs_OnPlayerLogin then
      WiseHudOrbs_OnPlayerLogin()
    end
    if WiseHudCast_OnPlayerLogin then
      WiseHudCast_OnPlayerLogin()
    end
  elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_POWER_FREQUENT" then
    local unit, powerType = ...
    if WiseHudCore_OnPowerEvent then
      WiseHudCore_OnPowerEvent(unit, powerType)
    end
    if WiseHudOrbs_OnPowerUpdate then
      WiseHudOrbs_OnPowerUpdate(unit, powerType)
    end
  elseif event == "RUNE_POWER_UPDATE" then
    -- Death Knight runes: treat as orb resource updates driven by rune count.
    if WiseHudOrbs_OnPowerUpdate then
      WiseHudOrbs_OnPowerUpdate("player")
    end
  elseif event == "UNIT_MAXPOWER" or event == "UNIT_DISPLAYPOWER" then
    local unit = ...
    if WiseHudPower_OnPowerEvent then
      WiseHudPower_OnPowerEvent(unit, "MANA")
    end
  elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
    local unit = ...
    if WiseHudCore_OnHealthEvent then
      WiseHudCore_OnHealthEvent(unit)
    end
  elseif event == "UNIT_ABSORB_AMOUNT_CHANGED" then
    local unit = ...
    if WiseHudCore_OnHealthEvent then
      WiseHudCore_OnHealthEvent(unit)
    end
  elseif event == "PLAYER_REGEN_DISABLED" then
    if WiseHudCore_OnCombatStateChanged then
      WiseHudCore_OnCombatStateChanged(true)
    end
  elseif event == "PLAYER_REGEN_ENABLED" then
    if WiseHudCore_OnCombatStateChanged then
      WiseHudCore_OnCombatStateChanged(false)
    end
  elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
    if WiseHudOrbs_OnSpecChanged then
      WiseHudOrbs_OnSpecChanged()
    end
    if WiseHudPower_OnPowerEvent then
      WiseHudPower_OnPowerEvent("player")
    end
  elseif event == "UNIT_SPELLCAST_START" then
    local unit, castGUID, spellID = ...
    if WiseHudCast_OnSpellCastStart then
      WiseHudCast_OnSpellCastStart(unit, castGUID, spellID)
    end
  elseif event == "UNIT_SPELLCAST_STOP" then
    local unit, castGUID, spellID = ...
    if WiseHudCast_OnSpellCastStop then
      WiseHudCast_OnSpellCastStop(unit, castGUID, spellID)
    end
  elseif event == "UNIT_SPELLCAST_FAILED" then
    local unit, castGUID, spellID = ...
    if WiseHudCast_OnSpellCastFailed then
      WiseHudCast_OnSpellCastFailed(unit, castGUID, spellID)
    end
  elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
    local unit, castGUID, spellID = ...
    if WiseHudCast_OnSpellCastInterrupted then
      WiseHudCast_OnSpellCastInterrupted(unit, castGUID, spellID)
    end
  elseif event == "UNIT_SPELLCAST_DELAYED" then
    local unit, castGUID, spellID = ...
    if WiseHudCast_OnSpellCastDelayed then
      WiseHudCast_OnSpellCastDelayed(unit, castGUID, spellID)
    end
  elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
    local unit, castGUID, spellID = ...
    if WiseHudCast_OnSpellCastChannelStart then
      WiseHudCast_OnSpellCastChannelStart(unit, castGUID, spellID)
    end
  elseif event == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
    local unit, castGUID, spellID = ...
    if WiseHudCast_OnSpellCastChannelUpdate then
      WiseHudCast_OnSpellCastChannelUpdate(unit, castGUID, spellID)
    end
  elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
    local unit, castGUID, spellID = ...
    if WiseHudCast_OnSpellCastChannelStop then
      WiseHudCast_OnSpellCastChannelStop(unit, castGUID, spellID)
    end
  elseif event == "PLAYER_ENTERING_WORLD" then
    -- Currently not used for orbs; kept for future hooks if needed.
  end
end)

-- OnUpdate ticker from Core, so Health/Power modules only need to read
WiseHud:SetScript("OnUpdate", function(self, elapsed)
  if WiseHudCore_OnUpdate then
    WiseHudCore_OnUpdate(elapsed)
  end
  if WiseHudCast_Update then
    WiseHudCast_Update(elapsed)
  end
end)

-- Unknown events abort the file on Forever, so each registration is isolated.
local function RegisterEventSafe(event)
  pcall(WiseHud.RegisterEvent, WiseHud, event)
end

RegisterEventSafe("PLAYER_LOGIN")
RegisterEventSafe("UNIT_POWER_UPDATE")
RegisterEventSafe("UNIT_POWER_FREQUENT")
RegisterEventSafe("RUNE_POWER_UPDATE")
RegisterEventSafe("UNIT_MAXPOWER")
RegisterEventSafe("UNIT_DISPLAYPOWER")
RegisterEventSafe("UNIT_HEALTH")
RegisterEventSafe("UNIT_MAXHEALTH")
RegisterEventSafe("UNIT_ABSORB_AMOUNT_CHANGED")
RegisterEventSafe("PLAYER_REGEN_ENABLED")
RegisterEventSafe("PLAYER_REGEN_DISABLED")
RegisterEventSafe("PLAYER_SPECIALIZATION_CHANGED")
RegisterEventSafe("UNIT_SPELLCAST_START")
RegisterEventSafe("UNIT_SPELLCAST_STOP")
RegisterEventSafe("UNIT_SPELLCAST_FAILED")
RegisterEventSafe("UNIT_SPELLCAST_INTERRUPTED")
RegisterEventSafe("UNIT_SPELLCAST_DELAYED")
RegisterEventSafe("UNIT_SPELLCAST_CHANNEL_START")
RegisterEventSafe("UNIT_SPELLCAST_CHANNEL_UPDATE")
RegisterEventSafe("UNIT_SPELLCAST_CHANNEL_STOP")
RegisterEventSafe("PLAYER_ENTERING_WORLD")

