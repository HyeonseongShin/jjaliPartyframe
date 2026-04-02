# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

WoW Midnight (Interface 120001) custom party frame addon. Restoration Druid-focused, Korean client. Replaces the default Blizzard party frames with a single draggable container holding 5 unit frames (player + party1~4).

**Installation:** Copy folder to `World of Warcraft/_retail_/Interface/AddOns/jjaliPartyFrame/`, then `/reload` in-game.

**In-game slash commands:** `/jjali` or `/jpf` → `reset` | `reload`

## File Load Order

```
Core.lua → Frames.lua → Buffs.lua → SpellPicker.lua → Options.lua
```

The global table `jjaliPartyFrame` (local alias `CP`) is created in `Core.lua` and extended by every subsequent file. Never reorder the TOC load sequence.

## Architecture

```
jjaliPartyFrame (global) / CP (local alias)
  CP.db           -- settings table, mirrored to/from SavedVariables (jjaliPartyFrameDB)
  CP.colors       -- hp / power / debuff color tables
  CP.units        -- {"player","party1","party2","party3","party4"}
  CP.frames       -- unit string → unit frame map
  CP.container    -- single parent container frame (jjaliPartyFrameContainer)
  CP.locked       -- drag lock state (bool)
  CP.Options      -- Options panel module (Options.lua)
  CP.SpellPicker  -- SpellPicker singleton module (SpellPicker.lua)
```

**Container pattern:** All 5 unit frames are children of a single container frame with a 16px drag handle at the top (orange = unlocked, dark gray = locked). Layout (vertical/horizontal) and position are saved via `jjaliPartyFrameDB`.

**Click-heal:** Each unit frame uses `SecureActionButtonTemplate`. Spells are assigned via `*spell1/2/3` attributes (left/right/middle click). SpellPicker reads the live spellbook so spell names are always in the client language (Korean).

## Critical Constraints

### Lua 5.1
WoW runs Lua 5.1. `goto` / `::label::` are **banned** (Lua 5.2+ only). Use `if x then ... end` blocks instead.

### Midnight Secret Value System
HP/Power values returned by `UnitHealth()` / `UnitPower()` are opaque "secret numbers" during combat — Lua arithmetic on them throws a runtime error.

```lua
-- ❌ BANNED
local pct = UnitHealth(unit) / UnitHealthMax(unit)
math.floor(UnitHealthPercent(unit))

-- ✅ CORRECT
f.hpBar:SetMinMaxValues(0, 100)
f.hpBar:SetValue(UnitHealthPercent(unit))   -- 0~100, not arithmetic
string.format("%d%%", UnitHealthPercent(unit))  -- display

-- HPColor thresholds use 0~100 scale (not 0~1)
-- high: > 60,  mid: > 30,  low: <= 30
```

`SetMinMaxValues` / `SetValue` accept raw secret values directly — the WoW engine handles them internally without Lua arithmetic.

### SecureActionButtonTemplate (Combat Lockdown)
```lua
-- ❌ BANNED during combat
f:SetAttribute("*spell1", spellName)

-- ✅ Always guard spell assignment
if not InCombatLockdown() then
    f:SetAttribute("*spell1", spellName)
end
```

### C_SpellBook API (Midnight)
```lua
C_SpellBook.GetNumSpellBookSkillLines()
C_SpellBook.GetSpellBookSkillLineInfo(lineIdx)
  -- returns: lineInfo.itemIndexOffset, lineInfo.numSpellBookItems (NOT numSpells)
  -- use: lineInfo.numSpellBookItems or lineInfo.numSpells  (fallback for safety)
C_SpellBook.GetSpellBookItemInfo(slotIdx, Enum.SpellBookSpellBank.Player)
C_SpellBook.GetSpellBookItemName(slotIdx, Enum.SpellBookSpellBank.Player)
C_SpellBook.GetSpellBookItemTexture(slotIdx, Enum.SpellBookSpellBank.Player)
Enum.SpellBookItemType.Spell  -- filter for active spells only
```

### Spell Names (Korean client)
Default spells: `left=재성장`, `right=재생`, `middle=치유의 손길`. SpellPicker reads live spellbook so language is auto-matched — never hardcode English spell names.

## Key Values

| Item | Value |
|------|-------|
| SavedVariables global | `jjaliPartyFrameDB` |
| Container frame name | `jjaliPartyFrameContainer` |
| Default anchor | `TOPLEFT`, x=20, y=-200 |
| Handle height | 16px |
| Default maxBuffs / maxDebuffs | 6 / 3 |
| Default auraSize | 16px |
| TOC Interface | `120001` |
| Addon identifier | `jjaliPartyFrame` (lowercase-first, never change) |

## Debugging (In-Game)

- BugGrabber + BugSack — catches Lua errors
- ViragDevTool, WowLua — runtime inspection
- `/console scriptErrors 1` — show errors in chat
- `/reload` — reload UI after file changes
