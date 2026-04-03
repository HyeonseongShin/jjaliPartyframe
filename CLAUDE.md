# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

WoW Midnight (Interface 120001) custom party frame addon. Restoration Druid-focused, Korean client. Replaces the default Blizzard party frames with a single draggable container holding 5 unit frames (player + party1~4).

**Installation:** Copy folder to `World of Warcraft/_retail_/Interface/AddOns/jjaliPartyFrame/`, then `/reload` in-game.

**In-game slash commands:** `/jjali` or `/jpf` → `lock` | `unlock` | `reset` (no argument opens options panel)

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
Many values returned by WoW APIs (`UnitHealth`, `UnitPower`, `UnitHealthMax`, aura `duration`, `applications`, etc.) are opaque "secret numbers" — Lua arithmetic **and comparisons** on them throw a runtime error.

**API-first principle:** Before writing pcall workarounds, check [warcraft.wiki.gg](https://warcraft.wiki.gg) for an official API that returns a regular number directly. Patch 12.0.0 added several such APIs.

```lua
-- ❌ BANNED (arithmetic and comparisons on secret values)
local pct = UnitHealth(unit) / UnitHealthMax(unit)
if data.duration > 300 then ...
data.applications > 1

-- ✅ PREFERRED: use official APIs that return regular numbers
-- HP% for text display (Patch 12.0.0+) — returns regular 0~100 float
local hpPct100 = UnitHealthPercent(unit, true, CurveConstants.ScaleTo100)
f.hpText:SetFormattedText("%d%%", hpPct100)
-- CurveConstants.ScaleTo100: curve object that scales the result to 0~100

-- ✅ CORRECT: HP bar — pass raw secret values to WoW engine (engine decodes internally)
f.hpBar:SetMinMaxValues(0, UnitHealthMax(unit))
f.hpBar:SetValue(UnitHealth(unit))

-- ✅ CORRECT: read back as regular Lua numbers via GetValue/GetMinMaxValues
local cur = f.hpBar:GetValue()
local _, max = f.hpBar:GetMinMaxValues()
local hpPct = (max and max > 0) and (cur / max) or 0
-- hpPct is 0~1 float — used for HPColor()

-- ✅ FALLBACK: pcall for secret values with no official decoded API
local ok, result = pcall(function() return data.duration == 0 or data.duration > 300 end)
local isLongBuff = ok and result or false

-- HPColor receives 0~1 float (result of GetValue/GetMinMaxValues division)
-- high: > 0.6,  mid: > 0.3,  low: <= 0.3
```

**Known secret values with no decoded API (as of 12.0.0):**
- `AuraData.duration` / `expirationTime` — use pcall for comparisons
- `AuraData.applications` — cannot be displayed; set count text to `""`
- `UnitPower` / `UnitPowerMax` — pass directly to `SetMinMaxValues`/`SetValue`

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
| HP bar range | `SetMinMaxValues(0, UnitHealthMax)` + `SetValue(UnitHealth)` — raw secret values |
| HP% text | `UnitHealthPercent(unit, true, CurveConstants.ScaleTo100)` → 0~100 regular float |
| HPColor input | 0~1 float (from `GetValue()/GetMinMaxValues()`) |
| API reference | https://warcraft.wiki.gg |

## Skills

프로젝트 루트 `.skill/` 디렉토리에 작업 보조 스킬이 있습니다. 해당 상황이 되면 반드시 사용하세요.

| 파일 | 사용 시점 |
|------|-----------|
| `context-archiving.skill` | 유저가 "컨텍스트 저장", "새 세션용 요약" 등을 요청할 때 — 해당 파일의 포맷을 따라 출력 |
| `knowledge_output.md` | 컨텍스트 요약 출력의 템플릿 구조 참고용 |

> `clean-code.skill`, `system-design.skill` 은 ZIP 포맷으로 현재 직접 읽기 불가. 내용 확인 후 추가 예정.

## Debugging (In-Game)

- BugGrabber + BugSack — catches Lua errors
- ViragDevTool, WowLua — runtime inspection
- `/console scriptErrors 1` — show errors in chat
- `/reload` — reload UI after file changes
