# jjaliPartyframe - Gemini Analysis

## Project Overview

**jjali's Party Frame** is a custom World of Warcraft addon designed for the Midnight (12.0.1) expansion. Its primary purpose is to enhance the default party frames by providing additional functionality and customization options for a better user experience.

**Key Features:**
*   **HP Bar:** Dynamically changes color (green, yellow, red) based on health percentage.
*   **MP/Power Bar:** Automatically adjusts color according to class-specific power types (mana, rage, energy, etc.).
*   **Role Icons:** Displays role icons (tank, healer, DPS) automatically.
*   **Buff/Debuff Icons:** Shows up to 8 buffs and 4 debuffs with distinct border colors for different types.
*   **Click-to-Heal:** Allows instant spell casting by clicking on party frames, even in combat.
*   **Draggable Frames:** Enables free movement of frames outside of combat.

**Technologies Used:**
*   **Lua:** The primary scripting language for World of Warcraft addons.
*   **World of Warcraft Addon API:** Utilizes specific WoW API functions, including `UnitHealthPercent()`, to comply with the "Secret Value" restrictions introduced in the Midnight expansion.

## Building and Running

This project is a World of Warcraft addon and does not require traditional "building" in the sense of compilation.

**Installation:**
1.  Copy the entire `jjaliPartyFrame` folder into the `World of Warcraft/_retail_/Interface/AddOns/` directory.
2.  Restart the game or reload the UI (`/reload`) to activate the addon.

**Configuration:**
*   **Click-Heal Spells:** To configure spells for click-to-heal functionality, edit the `spells` table at the top of `Core.lua` to match your class's abilities:
    ```lua
    spells = {
        left   = "Flash Heal",          -- Left click
        right  = "Renew",               -- Right click
        middle = "Power Word: Shield",  -- Middle click
    },
    ```

**Slash Commands:**
The following commands can be used in-game:
*   `/jjali reset` or `/jpf reset`: Resets the frame positions to their default.
*   `/jjali reload` or `/jpf reload`: Reloads the addon frames.

## Development Conventions

**File Structure:**
*   `jjaliPartyFrame.toc`: Contains addon metadata, version information, and defines the files to be loaded.
*   `Core.lua`: Handles core configurations, color definitions, and event handlers. This file also contains the click-heal spell definitions.
*   `Frames.lua`: Responsible for the creation, updating, and management of the party frames, including the click-heal logic.
*   `Buffs.lua`: Manages the display and logic for buff and debuff icons on the party frames.

**API Usage:**
The addon is designed to be compatible with World of Warcraft Midnight (Interface 120001) and specifically addresses the "Secret Value" restrictions by using the appropriate new APIs like `UnitHealthPercent()`.

**Language:**
The documentation (README.md) and comments within the `.toc` file indicate that Korean is used for descriptions and annotations.
