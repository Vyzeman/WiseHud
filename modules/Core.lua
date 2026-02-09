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
    -- Only real resource changes (e.g. mana/energy/rage) should
    -- affect the power alpha, not combo points or similar.
    local currentType, currentToken = UnitPowerType("player")

    -- Depending on the client, the event provides either the token ("MANA", "ENERGY", ...)
    -- or the numeric index. We only accept it when it matches the player's
    -- current primary resource.
    if powerType == currentToken or powerType == currentType then
      WiseHudCombatInfo.lastPowerChange = GetTime()
    end
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
  if WiseHudOrbs_ApplyAlpha then
    WiseHudOrbs_ApplyAlpha()
  end
end

function WiseHudCore_OnUpdate(elapsed)
  updateElapsed = updateElapsed + elapsed
  -- Recompute target alpha on a throttled interval to avoid
  -- running the heavier state checks every single frame.
  -- 0.3s is a good compromise between responsiveness and performance.
  if updateElapsed >= 0.3 then
    updateElapsed = 0

    -- In combat the alpha stays fixed (combat alpha), so we only
    -- need to recompute the target alpha out of combat
    -- (for the transition from "nonFull" to "idle" after FADE_IDLE_DELAY).
    local inCombat = WiseHudCombatInfo and WiseHudCombatInfo.inCombat
    if not inCombat then
      if WiseHudHealth_ApplyAlpha then
        WiseHudHealth_ApplyAlpha()
      end
      if WiseHudPower_ApplyAlpha then
        WiseHudPower_ApplyAlpha()
      end
      if WiseHudOrbs_ApplyAlpha then
        WiseHudOrbs_ApplyAlpha()
      end
    end
  end

  if WiseHudHealth_UpdateAlpha then
    WiseHudHealth_UpdateAlpha(elapsed)
  end
  if WiseHudPower_UpdateAlpha then
    WiseHudPower_UpdateAlpha(elapsed)
  end
  if WiseHudOrbs_UpdateAlpha then
    WiseHudOrbs_UpdateAlpha(elapsed)
  end
  
  if WiseHudOrbs_UpdateAnimations then
    WiseHudOrbs_UpdateAnimations(elapsed)
  end
end

