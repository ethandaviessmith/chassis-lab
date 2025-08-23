# Project Configuration Instructions

To complete the retro UI and feel for ChassisLab, please make the following manual changes in the Godot editor:

## 1. Add Autoload Scripts:

1. Open the project in Godot
2. Go to Project > Project Settings
3. Navigate to the "Autoload" tab
4. Add the following autoloads:
   - Name: RetroThemeManager
   - Path: res://scripts/RetroThemeManager.gd
   - Enable: ✓
   - Add
   - Name: SoundManager
   - Path: res://scripts/managers/SoundManager.gd
   - Enable: ✓
   - Add

## 2. Create Required Sound Files:

Create basic sound effects in the assets/sfx folder:
- click.wav
- hover.wav
- attach_part.wav
- detach_part.wav

You can use a tool like SFXR (https://sfxr.me/) or Chiptone (https://sfbgames.itch.io/chiptone) to generate retro-style sound effects.

## 3. Add Screen Shake to Main Scene:

1. Open your main scene
2. Add the ScreenShake node as a child:
   - Right-click on the root node
   - Add Child Node
   - Search for "ScreenShake" (custom type from scripts/utils/ScreenShake.gd)
   - Add

## 4. Apply Retro Theme to UI:

1. Open the Project Settings
2. Navigate to "GUI > Theme"
3. Set "Custom Theme" to "res://assets/themes/retro_theme.tres"

## 5. Apply Terminal Background:

1. Open your main UI scenes
2. Add a TerminalBackground node:
   - Right-click on the root node or appropriate parent
   - Add Child Node
   - Search for "TerminalBackground" (custom type)
   - Add
3. Position the TerminalBackground at the bottom of the node hierarchy to act as a background

## 6. Use RetroUtils for Colors:

Refactor your code to use the RetroUtils.Colors class for consistent colors across your UI.

Example:
```gdscript
# Instead of
button.modulate = Color("#ffffff")

# Use
button.modulate = RetroUtils.Colors.UI_TEXT
```

## 7. Add Screen Effects:

To add the CRT and scanline effects to your game, call:
```gdscript
# From any script that needs it:
$TerminalBackground.apply_scanlines()
```

## 8. Test the Results:

Start your game and check for:
- Pixel font rendering
- CRT/scanline effects
- Sound effects when attaching parts
- Screen shake when appropriate
- Terminal-style UI backgrounds

Adjust settings as needed for the desired retro feel.
