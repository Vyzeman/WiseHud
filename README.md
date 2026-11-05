# WiseHud

A customizable Heads-Up Display (HUD) addon for World of Warcraft that shows health, power/resources, and class resource orbs in an elegant, configurable interface.

## Features

### Health & Power Bars
- Vertical health and power bars with customizable positioning
- Smooth alpha transitions based on combat state
- Configurable size, position, and offset
- Support for all power types (Mana, Energy, Rage, Focus, Runic Power, etc.) with appropriate colors

### Resource Orbs
- Dynamic resource / combo point display using 3D models
- Supports multiple classes:
  - **Rogue**: Combo Points
  - **Monk**: Chi
  - **Warlock**: Soul Shards
  - **Paladin**: Holy Power
  - **Druid (Feral)**: Combo Points
  - **Death Knight**: Runes / Runic Power visualization
- Circular arrangement with configurable radius and center position
- Configurable orb size to better match your personal UI scale
- Smooth animations for orb appearance and updates
- Automatic detection of class and specialization

### Cast Bar
- Customizable cast bar with smooth animations
- Configurable position, size, and appearance
- Support for custom statusbar textures via LibSharedMedia-3.0
- Alpha transitions and visual feedback

### Options Panel
- Three-tab interface for organized settings:
  - **Orb Resource**: Resource / orb configuration
  - **Health/Power**: Health and power bar settings
  - **Cast Bar**: Cast bar configuration and appearance
- Individual enable/disable toggles for each module
- Sliders for fine-tuning positions, sizes, and layout
- All settings are saved and persist across sessions

## Installation

1. Download the latest release
2. Extract the `WiseHud` folder to your `World of Warcraft\_retail_\Interface\AddOns\` directory
   - For WoW Forever, use the Forever client folder instead, typically `World of Warcraft\_forever_\Interface\AddOns\`
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

- World of Warcraft Retail (Interface version 120005)
- World of Warcraft: Forever (Interface version 16001, via `WiseHud_Forever.toc`)
- **LibSharedMedia-3.0** (optional, for custom cast bar textures)

## Saved Variables

All settings are stored in `WiseHudDB` and persist across sessions.

## Version

Current Version: **1.1.4**

## Author

Vyzeman

## License

See LICENSE file for details.

## Credits

- Inspired by IceHUD and ArcHUD
- Uses resources from IceHUD
- Uses custom textures for the bar graphics

## Creating a Release

WiseHud uses automated packaging and deployment to CurseForge via GitHub Actions.

### Prerequisites

The repository owner must add a CurseForge API token as a GitHub Actions secret named `CF_API_KEY`:
1. Generate an API token from your CurseForge account
2. Go to the repository Settings → Secrets and variables → Actions
3. Add a new repository secret named `CF_API_KEY` with your token

### Release Process

To create a new release:

```bash
git tag 1.1.5
git push origin 1.1.5
```

The GitHub Actions workflow will automatically:
- Package the addon using the BigWigsMods packager
- Upload the release to CurseForge (project ID: 1446690)
- Create a GitHub release with the packaged addon

The tag version (e.g., `1.1.5`) will be automatically substituted into the TOC files' `## Version:` field.

### Important Notes

- Only push tags when you're ready to release - each tag push triggers a new CurseForge upload
- The version in the TOC files uses `@project-version@` which is replaced by the packager during build
- During development (non-packaged), the addon will show "@project-version@" as its version, which is normal

## Support

For issues, suggestions, or contributions, please visit the project repository.
