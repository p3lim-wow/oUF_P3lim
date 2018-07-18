### Changes in 80000.31-Release:

- Changed: Update Interface version
- Changed: Using oUF tag logic for pet hp instead of our own
- Changed: Using custom colors for Experience
- Fixed: Compatibility with Battle for Azeroth

### Changes in 70300.30-Release:

- Added: Font library (PixelFont)
- Fixed: Combo points not being colored correctly
- Changed: Updated for oUF_Experience changes

### Changes in 70300.29-Release:

- Changed: Update Interface version
- Changed: Height of raid/party frames
- Fixed: Boss and Arena frames not always showing

### Changes in 70200.28-Release:

- Fixed: Error from ClassPower callback

### Changes in 70200.27-Release:

- Added: Mana bars on group healers
- Added: Honor support to the Experience bar tooltip
- Changed: Update Interface version
- Changed: Updated to latest version of oUF
- Changed: Experience bar tooltip anchor

### Changes in 70100.26-Release:

- Changed: Update Interface version
- Changed: Auto-adjust the castbar spark to the frame height
- Fixed: Portrait cropping issues
- Fixed: Not showing all 10 combo points for rogues with the Anticipation talent
- Fixed: Aura tooltip being covered by the cursor
- Removed: Leftover Warlords of Draenor compatibility code

### Changes in 70000.25-Release:

- Changed: Using animated status bar for the Experience element
- Fixed: Cooldown spirals

### Changes in 70000.24-Release:

- Added: Support for new class power icons introduced in Legion
- Added: Totem element support
- Added: Power prediction element support
- Added: Fallback font for non-latin languages
- Added: Highlight for buffs on target that can be stolen or removed
- Added: New tooltip for the experience bar
- Changed: Update Interface version
- Changed: Sort raid/party by role (tank > healer > damager)
- Changed: Increased the max buffs on the target to 27 (lines up nicely)
- Fixed: Target name appearing behind portrait
- Fixed: Words wrapping incorrectly (still)
- Fixed: Various issues concerning API changes in Legion
- Removed: Unsupported class power icons

### Changes in 60100.23-Release:

- Changed: Update Interface version
- Changed: Update Experience embed
- Fixed: Words wrapping incorrectly

### Changes in 60000.22-Release:

- Added: Duration for target's buffs
- Added: Simple tooltip for the experience bar
- Changed: Update oUF embed
- Changed: Update Experience embed
- Fixed: Errors when entering a vehicle
- Fixed: Text rendered below the cooldown spiral
- Fixed: Cooldown/durations showing negative values during bad connection
- Fixed: Runes rendering issue
- Fixed: Combat resurrect icon on party/raid frames
- Fixed: Class icons sometimes incorrectly sized (or hidden)
- Fixed: Pet health on the player frame not updating correctly
- Fixed: Not showing the 6th chi for monks
- Fixed: Incorrect outline on the buff/debuff durations
- Fixed: Issues regarding the name/cast info on target
- Removed: Buffs on the player frame

### Changes in 60000.21-Release:

- Added: Support for MovableFrames plugin
- Added: Support for Shaman's Maelstrom Weapon (same as combo points)
- Changed: Update Interface version
- Changed: Update oUF embed
- Changed: Update Experience embed
- Changed: Tags rewritten for performance and readability
- Fixed: EclipseBar issues
- Fixed: Arena preparation frames
- Fixed: Tags rendering behind the portrait
- Fixed: Role icons rendering behind the ready check icons
- Fixed: Divide by zero bug
- Removed: Unintentional debuffs on arena frames
- Removed: Compatability code for "Mists of Pandaria" expansion

### Changes in 50400.20-Release:

- Added: Support for "Warlords of Draenor" expansion
- Added: Support for Portraits element
- Added: Support for ClassIcons element
- Added: Support for ResurrectIcon element
- Added: Support for Threat element
- Added: Custom demonic fury element
- Added: Custom cpoints tag with colors
- Added: Support for the rogue talent "Anticipation"
- Added: Metadata file for the curseforge packager
- Added: License
- Changed: Update oUF embed
- Changed: Update Experience embed
- Changed: EclipseBar and Runes element simplified
- Changed: Use short values on health tags
- Removed: Unbuffed tag on party and raid
- Removed: Almost all class power tags from player

### Changes in 50400.19-Release:

- Added: Support for EclipseBar element
- Added: Custom soulshards tag to player
- Added: Custom demonic fury tag to player
- Added: Pet health value tag to player
- Added: Burning Embers element to player
- Fixed: Combo points position
- Removed: Support for AltPowerBar element

### Changes in 50400.18-Release:

- Added: Arena frames
- Added: Arena preparation frames
- Changed: Update Interface version
- Changed: Update oUF embed
- Changed: Update Experience embed
- Removed: Fancy CLEU tracking for combo points
- Removed: Buff filters

### Changes in 50300.17-Release:

- Added: Support for Runes element
- Changed: Update Interface version
- Changed: Update oUF embed
- Changed: Update buff and debuff filter

### Changes in 50200.16-Release:

- Changed: Update Interface version
- Changed: Update oUF embed
- Remove: Dropdown spawning logic (oUF handles this now)

### Changes in 50100.15-Release:

- Added: Support for AltPowerBar element
- Changed: Update Interface version
- Changed: Update oUF embed
- Removed: Support for "Savage Defense" ability

### Changes in 50001.14-Release:

- Added: Metadata file for the curseforge packager

### Changes in 50001.13-Release:

- Added: Support for "Savage Defense" ability
- Added: Countdown time on buffs and debuffs
- Added: Support for ReadyCheck element
- Changed: Embed oUF
- Changed: Embed Experience plugin
- Changed: Track CLEU changes for combo points for accuracy
- Changed: Update buff and debuff filter
- Fixed: Castbar frame strata

### Changes in 50001.12-Release:

- Added: Support for "Mists of Pandaria" expansion
- Added: Support for Experience plugin
- Changed: Update Interface version
- Changed: Disable default UI boss frames
- Changed: Update buff and debuff filter
- Fixed: Taints caused by Blizzard leaking a global variable
- Removed: Support for oUF 1.5
- Removed: Support for Fader plugin

### Changes in 40300.11-Release:

- Added: Boss frames
- Added: Support for Fader plugin
- Added: [holypower] tag on player
- Changed: Only show raid when it's less than 27 players
- Changed: Update buff filter
- Fixed: Name going off the frame

### Changes in 40300.10-Release:

- Changed: Update Interface version
- Changed: Update support for 1.6
- Changed: Update buff and debuff filter
- Changed: Show debuffs while in a vehicle
- Changed: Anchor focus and target's target to their closest relative
- Changed: Added support for packagers to set the version automatically
- Fixed: Friendly unit health tag
- Removed: Threat texture
- Removed: Support for "Glyph of Shred"

### Changes in 40200.9-Release:

- Added: Threat texture
- Changed: Update buff filter
- Fixed: Make sure we have "Glyph of Shred" active

### Changes in 40200.8-Release:

- Added: Raid frames
- Added: Castbar in form of a tag and spark on target
- Added: Debuffs to player
- Added: Buff and debuff filters
- Added: Support for "Glyph of Shred" on target debuffs
- Changed: Update Interface version
- Removed: Pet frame

### Changes in 40100.7-Release:

- Added: Party frames
- Added: Castbar in form of a tag and spark on player and pet
- Changed: Update Interface version
- Changed: Font flag on focus, target and target's target
- Fixed: Focus debuff position
- Removed: Threat tag
- Removed: Pet happiness coloring

### Changes in 40000.6-Release:

- Removed: Temporary fix for clicks

### Changes in 40000.5-Beta:

- Changed: Update Interface version
- Changed: Update support for 1.5
- Changed: Font flags to "OUTLINEMONOCHROME"

### Changes in 30300.4-Beta:

- Added: New font (Semplice Regular)
- Changed: Update support for 1.4
- Changed: Positions of all units and elements
- Removed: Custom dropdown
- Removed: Buff and debuff filters
- Removed: Castbar element
- Removed: Runes element
- Removed: Custom statusbar texture

### Changes in 30300.3-Beta:

- Added: New font (Marke Eigenbau)
- Added: Support for Runes element
- Added: Castbar to pets (for vehicle support)
- Added: Custom dropdown for player
- Added: Whitelisted debuffs for target
- Changed: Update Interface version
- Changed: Update buff filter
- Changed: Height on all frames
- Changed: [pvptime] tag symbol and formatting
- Fixed: Only show [pthreat] if threat percentage is above 0
- Removed: Countdown time on player buffs

### Changes in 30200.2-Beta:

- Added: [druidpower], [pthreat] and [pvptime] tags on player
- Added: Icon to castbar
- Added: Assistant and Leader element to player
- Changed: Health value element to only show [phealth] tag
- Changed: Castbar position
- Fixed: Experience bar width
- Removed: Support for RuneBar plugin
- Removed: Support for Reputation plugin
- Removed: Support for BarFader plugin
- Removed: Aura owner tooltip
- Removed: DruidPower element
- Removed: Global names
- Removed: Castbar on everything but player and target
