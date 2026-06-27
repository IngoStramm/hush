# Hush

**Hush** means **Hide Unwanted Screen HUD**.

Hush is a lightweight World of Warcraft Classic TBC Anniversary addon for hiding selected Blizzard UI elements. Its first job is hiding the default XP and reputation bars without using a larger frame-management addon.

## Compatibility

- World of Warcraft Classic TBC Anniversary
- Interface version: `20505`

## Installation

Download `Hush.zip` from the latest GitHub Release and extract it into:

```text
World of Warcraft/_anniversary_/Interface/AddOns/
```

After extraction, the addon folder should be:

```text
World of Warcraft/_anniversary_/Interface/AddOns/Hush/
```

Restart the game or reload the UI.

Do not use GitHub's green **Code > Download ZIP** button for installation. That downloads the source repository snapshot, not the packaged addon.

## Commands

- `/hush` - show current status.
- `/hush help` - show commands.
- `/hush on` - enable hiding.
- `/hush off` - disable hiding.
- `/hush xp` - toggle XP bar hiding.
- `/hush rep` - toggle reputation bar hiding.
- `/hush reset` - reset settings.

## Notes

Hush only manages the frames it knows about, instead of trying to replace a full frame mover such as MoveAny.

MoveAny labels the modern Blizzard status containers as:

- `StatusBar1` - `MainStatusTrackingBarContainer` (XP bar / reputation bar).
- `StatusBar2` - `SecondaryStatusTrackingBarContainer` (reputation bar).
