local ADDON_NAME = ...

-- Central configuration for WiseHud default values.
-- This file defines ONLY defaults / constants.
-- All runtime state continues to live in WiseHudDB.

WiseHudConfig = WiseHudConfig or {}
WiseHudConfig.defaults = WiseHudConfig.defaults or {}

-- Cast bar defaults
WiseHudConfig.defaults.cast = {
  -- Layout
  width = 230,
  height = 20,
  offsetX = 0,
  offsetY = 20,

  -- Default texture name (LibSharedMedia key)
  textureName = "Blizzard Raid Bar",

  -- Default for "Show Spell Name"
  showText = true,

  -- Fill color (RGB 0-255)
  fill = {
    r = 255,
    g = 255,
    b = 255,
  },

  -- Background color (RGB 0-255, alpha 0-100)
  bg = {
    r = 24,
    g = 24,
    b = 24,
    a = 80,
  },
}

-- Shared Health/Power bar defaults
WiseHudConfig.defaults.healthPower = {
  -- Layout of the curved health/power bars
  layout = {
    width   = 260,
    height  = 415,
    offsetX = 200,
    offsetY = 100,
  },

  -- Alpha defaults in percent (0–100)
  alpha = {
    combat    = 40,
    nonFull   = 20,
    fullIdle  = 0,
  },

  -- Bar colors (RGB 0-255)
  colors = {
    health = {
      r = 37,
      g = 164,
      b = 30,
    },
    power = {
      r = 62,
      g = 54,
      b = 152,
    },
  },

  -- Default per-power-type colors (normalized 0-1, used by Power.lua)
  -- Based on IceHUD PlayerMana defaults
  powerTypeColors = {
    MANA        = {  62 / 255,  54 / 255, 152 / 255 },
    RAGE        = { 171 / 255,  59 / 255,  59 / 255 },
    ENERGY      = { 218 / 255, 231 / 255,  31 / 255 },
    FOCUS       = { 242 / 255, 149 / 255,  98 / 255 },
    RUNIC_POWER = {  62 / 255,  54 / 255, 152 / 255 },
    INSANITY    = { 150 / 255,  50 / 255, 255 / 255 },
    FURY        = { 201 / 255,  66 / 255, 253 / 255 },
    MAELSTROM   = {  62 / 255,  54 / 255, 152 / 255 },
    PAIN        = { 255 / 255, 156 / 255,   0 / 255 },
  },
}

-- Orb resource defaults
WiseHudConfig.defaults.orbs = {
  -- Position & layout
  x      = 0,
  y      = -50,
  radius = 35,
  -- Layout type: "circle" (default), "horizontal", "vertical"
  layoutType = "circle",

  -- Visual/layout constants
  orbSize      = 54,
  topAngleDeg  = 90,
  arcLengthDeg = 360,
  maxPointsFallback = 7,

  -- Camera position
  cameraX = -3,
  cameraY =  0.0,
  cameraZ =  -1.7,

  -- Default model (ID)
  modelId = 1372960,

  -- Alpha defaults for Orbs in percent (0–100),
  -- same semantics as Health/Power but configured separately:
  -- combat    = alpha while in combat
  -- nonFull   = alpha out of combat shortly after a change
  -- fullIdle  = alpha out of combat and idle for a while
  alpha = {
    combat   = 100, -- fully visible in combat
    nonFull  = 50,  -- half transparent out of combat after recent change
    fullIdle = 0,   -- fully hidden when idle out of combat
  },
}

-- Orb model presets (each with model FileDataID and camera defaults)
WiseHudConfig.defaults.orbPresets = {
  {
    key     = "void_orb",
    name    = "Void",
    modelId = WiseHudConfig.defaults.orbs.modelId,
    cameraX = WiseHudConfig.defaults.orbs.cameraX,
    cameraY = WiseHudConfig.defaults.orbs.cameraY,
    cameraZ = WiseHudConfig.defaults.orbs.cameraZ,
  },
  {
    key     = "flame_orb",
    name    = "Flame",
    modelId = 450902,
    cameraX = -3,
    cameraY =  0.0,
    cameraZ =  -1.7,
  },
  {
    key     = "flame_orb_2",
    name    = "White Flame",
    modelId = 450903,
    cameraX = -3,
    cameraY =  0.0,
    cameraZ =  -1.7,
  },
  {
    key     = "magma_orb",
    name    = "Magma",
    modelId = 524767,
    cameraX = 0,
    cameraY = 0,
    cameraZ = 0,
  },
  {
    key     = "chi_orb",
    name    = "Chi",
    modelId = 610172,
    cameraX = 0,
    cameraY = 0,
    cameraZ = 0,
  },
  {
    key     = "solar_orb",
    name    = "Solar",
    modelId = 959518,
    cameraX = 0,
    cameraY = 0,
    cameraZ = 0,
  },
  {
    key     = "shadow_orb",
    name    = "Shadow",
    modelId = 3081600,
    cameraX = 0,
    cameraY = 0,
    cameraZ = 0,
  },
  {
    key     = "frost_orb",
    name    = "Frost",
    modelId = 3567592,
    cameraX = 0,
    cameraY = 0,
    cameraZ = 0,
  },
  {
    key     = "maw_orb",
    name    = "Maw",
    modelId = 4058682,
    cameraX = -3,
    cameraY =  0.0,
    cameraZ =  -1.7,
  },
  {
    key     = "earth_orb",
    name    = "Earth",
    modelId = 4204648,
    cameraX = -3,
    cameraY =  0.0,
    cameraZ =  -1.7,
  },
  {
    key     = "lightning_orb",
    name    = "Lightning",
    modelId = 840357,
    cameraX = -3,
    cameraY =  0.0,
    cameraZ =  -1.7,
  },
  {
    key     = "purple_lightning_orb",
    name    = "Purple Lightning",
    modelId = 840373,
    cameraX = -3,
    cameraY =  0.0,
    cameraZ =  -1.7,
  },
  {
    key     = "green_lightning_orb",
    name    = "Green Lightning",
    modelId = 1502965,
    cameraX = -3,
    cameraY =  0.0,
    cameraZ =  -1.7,
  }
}

function WiseHudConfig.GetCastDefaults()
  return WiseHudConfig.defaults.cast
end

function WiseHudConfig.GetHealthPowerDefaults()
  return WiseHudConfig.defaults.healthPower
end

function WiseHudConfig.GetOrbsDefaults()
  return WiseHudConfig.defaults.orbs
end

function WiseHudConfig.GetOrbPresets()
  return WiseHudConfig.defaults.orbPresets
end

