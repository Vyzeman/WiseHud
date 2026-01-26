local ADDON_NAME = ...

-- Base Tab Class for Options Panel

local OptionsTab = {}
OptionsTab.__index = OptionsTab

function OptionsTab:new(parent, panel)
  local instance = setmetatable({}, self)
  instance.parent = parent
  instance.panel = panel
  instance.elements = {}
  return instance
end

function OptionsTab:Create()
  -- Override in subclasses
  error("OptionsTab:Create() must be implemented in subclass")
end

function OptionsTab:Refresh()
  -- Override in subclasses if needed
end

function OptionsTab:Reset()
  -- Override in subclasses
  error("OptionsTab:Reset() must be implemented in subclass")
end

-- Export class
WiseHudOptionsBaseTab = OptionsTab
