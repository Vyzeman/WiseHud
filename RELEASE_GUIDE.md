# WiseHud Release Guide

## Pre-Release Checklist

### ✅ Code Quality
- [x] All comments translated to English
- [x] No debug print() statements
- [x] No test/debug code
- [x] Proper error handling with pcall
- [x] Code is clean and well-structured

### ✅ Documentation
- [x] README.md created
- [x] CHANGELOG.md created
- [x] LICENSE file added (MIT)
- [x] .toc file updated with metadata

### 📋 Before Release
- [ ] Test all features in-game
- [ ] Verify all classes work correctly (Rogue, Monk, Warlock, Paladin, Druid)
- [ ] Test options panel functionality
- [ ] Verify saved variables persist correctly
- [ ] Take screenshots for the release page
- [ ] Create a release video (optional but recommended)

## Release Platforms

### 1. CurseForge (Recommended)
**URL**: https://www.curseforge.com/wow/addons

**Steps**:
1. Create a CurseForge account
2. Go to "Submit a Project"
3. Choose "World of Warcraft" → "Addon"
4. Fill in project details:
   - Name: WiseHud
   - Summary: Customizable HUD with health, power, and combo point orbs
   - Description: Copy from README.md
   - Category: Combat
   - License: MIT
5. Upload the addon folder as a ZIP file
6. Add screenshots (at least 1, recommended 3-5)
7. Set version number (0.1.0)
8. Submit for review

**ZIP Structure**:
```
WiseHud.zip
└── WiseHud/
    ├── WiseHud.toc
    ├── WiseHud.lua
    ├── README.md
    ├── LICENSE
    ├── CHANGELOG.md
    ├── modules/
    │   ├── Core.lua
    │   ├── Health.lua
    │   ├── Power.lua
    │   ├── Combo.lua
    │   └── Options.lua
    └── textures/
        ├── CleanCurves.blp
        ├── CleanCurves-flipped.blp
        └── CleanCurvesBG.blp
```

### 2. WoWInterface
**URL**: https://www.wowinterface.com/

**Steps**:
1. Create an account
2. Go to "AddOns" → "Submit/Update"
3. Fill in similar information as CurseForge
4. Upload ZIP file
5. Add screenshots

### 3. GitHub (Optional)
**URL**: https://github.com/

**Steps**:
1. Create a GitHub repository
2. Initialize with README, LICENSE, CHANGELOG
3. Upload all files
4. Create a release tag (v0.1.0)
5. Link from CurseForge/WoWInterface

## Creating the Release ZIP

### Windows PowerShell:
```powershell
# Navigate to parent directory
cd D:\Projects

# Create ZIP (exclude unnecessary files)
Compress-Archive -Path WiseHud\* -DestinationPath WiseHud-v0.1.0.zip -Force
```

### Manual:
1. Select the `WiseHud` folder
2. Right-click → "Send to" → "Compressed (zipped) folder"
3. Rename to `WiseHud-v0.1.0.zip`

**Important**: The ZIP should contain the `WiseHud` folder, not its contents directly.

## Screenshots Recommendations

Take screenshots showing:
1. Default HUD appearance in combat
2. Options panel (both tabs)
3. Different classes showing their resource orbs
4. Customized layout example

**Screenshot Tips**:
- Use high resolution (1920x1080 or higher)
- Show UI clearly without clutter
- Include different scenarios (combat, idle, different classes)
- Name files descriptively: `wisehud-combat.jpg`, `wisehud-options.jpg`, etc.

## Version Numbering

Follow [Semantic Versioning](https://semver.org/):
- **MAJOR.MINOR.PATCH** (e.g., 1.0.0)
- **MAJOR**: Breaking changes
- **MINOR**: New features, backwards compatible
- **PATCH**: Bug fixes

Current: **0.1.0** (Initial release)

## Post-Release

1. Monitor for bug reports
2. Respond to user feedback
3. Update CHANGELOG.md for future versions
4. Consider adding:
   - Slash commands (`/wisehud`)
   - More customization options
   - Additional class support
   - Localization support

## Future Enhancements (Optional)

- [ ] Add slash commands for quick access
- [ ] Support for more classes/specs
- [ ] Additional orb models
- [ ] Color customization for bars
- [ ] Profile system for multiple configurations
- [ ] Localization (L10n) support
