# WiseHud

A customizable Heads-Up Display (HUD) addon for World of Warcraft that displays health, power/resource bars, and combo point orbs in an elegant, configurable interface.

## Features

### Health & Power Bars
- Vertical health and power bars with customizable positioning
- Smooth alpha transitions based on combat state and recent changes
- Configurable size, position, and offset
- Support for all power types (Mana, Energy, Rage, Focus, etc.) with appropriate colors

### Combo Point Orbs
- Dynamic combo point display using 3D models
- Supports multiple classes:
  - **Rogue**: Combo Points
  - **Monk**: Chi
  - **Warlock**: Soul Shards
  - **Paladin**: Holy Power
  - **Druid (Feral)**: Combo Points
- Circular arrangement with configurable radius and center position
- Smooth animations for orb appearance and updates
- Automatic detection of class and specialization

### Cast Bar
- Customizable cast bar with smooth animations
- Configurable position, size, and appearance
- Support for custom statusbar textures via LibSharedMedia-3.0
- Alpha transitions and visual feedback

### Options Panel
- Three-tab interface for organized settings:
  - **Orb Resource**: Combo point/orb configuration
  - **Health/Power**: Health and power bar settings
  - **Cast Bar**: Cast bar configuration and appearance
- Individual enable/disable toggles for each module
- Sliders for fine-tuning positions, sizes, and layout
- All settings are saved and persist across sessions

## Installation

1. Download the latest release
2. Extract the `WiseHud` folder to your `World of Warcraft\_retail_\Interface\AddOns\` directory
3. Restart World of Warcraft or type `/reload` in-game
4. Open the options panel via the AddOns menu or type `/wisehud` (if slash command is implemented)

## Configuration

Access the options panel through:
- **Interface Options** → **AddOns** → **WiseHud**

### Orb Resource Tab
- **Enable Orbs**: Toggle combo point/orb display
- **X Position**: Horizontal position of orb center
- **Y Position**: Vertical position of orb center
- **Radius**: Distance of orbs from center point

### Health/Power Tab
- **Enable Health**: Toggle health bar display
- **Enable Power**: Toggle power bar display
- **Width**: Bar width
- **Height**: Bar height
- **Offset**: Horizontal offset from center
- **Y Offset**: Vertical offset from center

### Cast Bar Tab
- **Enable Cast Bar**: Toggle cast bar display
- **X Position**: Horizontal position of cast bar
- **Y Position**: Vertical position of cast bar
- **Width**: Cast bar width
- **Height**: Cast bar height
- **Texture**: Select statusbar texture (requires LibSharedMedia-3.0)

## Requirements

- World of Warcraft: The War Within (Interface version 120000)
- **LibSharedMedia-3.0** (optional, for custom cast bar textures)

## Saved Variables

All settings are stored in `WiseHudDB` and persist across sessions.

## Version

Current Version: **1.0.4**

## Author

Vyzeman

## License

See LICENSE file for details.

## Credits

- Inspired by IceHUD and ArcHUD
- Uses resources from IceHUD
- Uses custom textures for the bar graphics

## Support

For issues, suggestions, or contributions, please visit the project repository.
