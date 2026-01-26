# Changelog

All notable changes to WiseHud will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-01-21

### Added
- Initial release
- Health bar module with configurable positioning and alpha transitions
- Power bar module supporting all power types with appropriate colors
- Combo point orb system with 3D model display
- Multi-class support (Rogue, Monk, Warlock, Paladin, Feral Druid)
- Options panel with two-tab interface
- Individual enable/disable toggles for each module
- Configurable layout settings (position, size, radius)
- Smooth animations for orb updates
- Alpha transitions based on combat state and recent changes
- Saved variables for persistent configuration

### Technical
- Modular architecture with separate modules for Health, Power, Combo, Core, and Options
- Event-driven system for efficient updates
- Safe error handling with pcall for model loading
- Support for Interface version 120000 (The War Within)
