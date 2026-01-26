local ADDON_NAME = ...

-- Shared core for WiseHud: Combat/change state and alpha updates

WiseHudCombatInfo = WiseHudCombatInfo or {
  inCombat = false,
  lastCombatEnd = 0,
  lastHealthChange = 0,
  lastPowerChange = 0,
}

local updateElapsed = 0

function WiseHudCore_OnPlayerLogin()
  local now = GetTime()
  WiseHudCombatInfo.lastHealthChange = now
  WiseHudCombatInfo.lastPowerChange  = now
end

function WiseHudCore_OnPowerEvent(unit, powerType)
  if unit == "player" then
    WiseHudCombatInfo.lastPowerChange = GetTime()
  end
  if WiseHudPower_OnPowerEvent then
    WiseHudPower_OnPowerEvent(unit, powerType)
  end
end

function WiseHudCore_OnHealthEvent(unit)
  if unit == "player" then
    WiseHudCombatInfo.lastHealthChange = GetTime()
  end
  if WiseHudHealth_OnHealthEvent then
    WiseHudHealth_OnHealthEvent(unit)
  end
end

function WiseHudCore_OnCombatStateChanged(inCombat)
  WiseHudCombatInfo.inCombat = inCombat
  if not inCombat then
    WiseHudCombatInfo.lastCombatEnd = GetTime()
  end
  if WiseHudHealth_ApplyAlpha then
    WiseHudHealth_ApplyAlpha()
  end
  if WiseHudPower_ApplyAlpha then
    WiseHudPower_ApplyAlpha()
  end
end

function WiseHudCore_OnUpdate(elapsed)
  updateElapsed = updateElapsed + elapsed
  if updateElapsed >= 0.2 then
    updateElapsed = 0
    if WiseHudHealth_ApplyAlpha then
      WiseHudHealth_ApplyAlpha()
    end
    if WiseHudPower_ApplyAlpha then
      WiseHudPower_ApplyAlpha()
    end
  end

  if WiseHudHealth_UpdateAlpha then
    WiseHudHealth_UpdateAlpha(elapsed)
  end
  if WiseHudPower_UpdateAlpha then
    WiseHudPower_UpdateAlpha(elapsed)
  end
  
  if WiseHudOrbs_UpdateAnimations then
    WiseHudOrbs_UpdateAnimations(elapsed)
  end
end

