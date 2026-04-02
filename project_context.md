# Context Summary: jjaliPartyFrame
> Last updated: 2026-04-02 | Language: English (token-efficient)

---

## 1. Core Objective
Custom WoW party frame addon replacing Blizzard default — Restoration Druid-focused, Korean client, WoW Midnight (12.0.1).

---

## 2. Key Decisions

- **Addon identifier:** `jjaliPartyFrame` — lowercase-first, never change
- **Container architecture:** single draggable container frame with 16px handle bar; all 5 unit frames as children (not independent)
- **Layout:** vertical / horizontal toggle, saved to `jjaliPartyFrameDB`
- **Click-heal:** `SecureActionButtonTemplate` — left/right/middle → spell attributes `*spell1/2/3`
- **Spell assignment:** SpellPicker singleton reads live spellbook (C_SpellBook API), no hardcoding
- **HP bar range:** `SetMinMaxValues(0, 100)` + `SetValue(UnitHealthPercent())` — avoids Secret Value arithmetic
- **HPColor threshold:** 0~100 scale (60/30), NOT 0~1 scale
- **SpellBook field name:** `lineInfo.numSpellBookItems` (Midnight) with fallback `or lineInfo.numSpells`
- **Spell names:** Korean — 회복 (Regrowth), 재생 (Rejuvenation), 치유의 손길 (Healing Touch)
- **Git:** commit freely; push ONLY when user explicitly asks

---

## 3. Constraints & Rules

### Lua 5.1 (hard constraint)
- `goto` / `::label::` → **banned** (Lua 5.2+ only)
- Replace with `if x then ... end` blocks

### Midnight Secret Value System
- Arithmetic on HP/Power values during combat → runtime error
- `UnitHealth() / UnitHealthMax()` division → **banned**
- `math.floor(UnitHealthPercent())` → **banned** (arithmetic on secret number)
- Use `string.format("%d%%", UnitHealthPercent())` for display
- Use `UnitHealthPercent()` (0~100) directly as bar value

### SecureActionButtonTemplate
- Attribute modification during `InCombatLockdown()` → **banned**
- All spell assignment logic must guard with `if not InCombatLockdown() then`

### C_SpellBook API (Midnight)
```lua
C_SpellBook.GetNumSpellBookSkillLines()
C_SpellBook.GetSpellBookSkillLineInfo(lineIdx)
  → lineInfo.itemIndexOffset, lineInfo.numSpellBookItems  -- NOT numSpells
C_SpellBook.GetSpellBookItemInfo(slotIdx, Enum.SpellBookSpellBank.Player)
C_SpellBook.GetSpellBookItemName(slotIdx, Enum.SpellBookSpellBank.Player)
C_SpellBook.GetSpellBookItemTexture(slotIdx, Enum.SpellBookSpellBank.Player)
Enum.SpellBookItemType.Spell  -- active spell filter
```

### Skill usage
- Feature design → `anthropic-skills:system-design`
- Code implementation → `anthropic-skills:clean-code-implementation`
- Both are user-created custom skills (not Anthropic defaults)

---

## 4. Current Status

### Completed features
- [x] HP bar — color gradient by percent (green/yellow/red), Secret Value compliant
- [x] MP/Power bar — per-class power type color
- [x] Role icon — TANK / HEALER / DAMAGER
- [x] Buff icons — max 6, pool pattern
- [x] Debuff icons — max 3, dispel-type border color (Magic/Curse/Disease/Poison)
- [x] Click-heal — SecureActionButtonTemplate, left/right/middle
- [x] Single container + drag handle (orange=unlocked, dark=locked)
- [x] Vertical / horizontal layout toggle
- [x] Position save/restore via SavedVariables
- [x] Lock / unlock
- [x] `/jjali` options panel (layout, position, spell slots, buff/debuff counters)
- [x] SpellPicker — live spellbook list, real-time filter, singleton with slot param

### Bug fix history (all resolved)
| Bug | Root cause | Fix |
|-----|-----------|-----|
| `goto` parse error (SpellPicker.lua:34, Frames.lua:196) | Lua 5.1 has no `goto` | Replaced with `if x then ... end` |
| Frames off-screen | anchorX = -220 | anchorX = 20 |
| English spell names not recognized | Korean client | Replaced with Korean spell names |
| `attempt to perform arithmetic on secret number` (Frames.lua:231) | `/100` on Secret Value | `SetMinMaxValues(0,100)` + `SetValue(hpPct)` |
| `math.floor` on secret number (Frames.lua:247) | arithmetic on Secret Value | `string.format("%d%%", ...)` |
| `numSpells` nil (SpellPicker.lua:36) | Midnight renamed field | `numSpellBookItems or numSpells` |
| HPColor always returning "low" color | threshold was 0.6/0.3 but input was 0~100 | changed to 60/30 |

### Next task candidates
- [ ] Frame size adjustment in options
- [ ] Auto show/hide based on group size
- [ ] Absorb (heal absorption) bar display
- [ ] Hide player frame option
- [ ] Raid frame support (> 5 players)

---

## 5. Key References

| Item | Value |
|------|-------|
| WoW version | Midnight Retail, Interface 120001 |
| Local path | `C:\Users\bugbe\OneDrive\Workspace\claude\jjaliPartyFrame\` |
| GitHub remote | `git@github.com:HyeonseongShin/jjaliPartyframe.git` |
| SSH key | `~/.ssh/github` (non-standard name, configured in `~/.ssh/config`) |
| SavedVariables global | `jjaliPartyFrameDB` |
| Container frame name | `jjaliPartyFrameContainer` |
| Slash commands | `/jjali`, `/jpf` |
| TOC Interface | `120001` |
| Default position | `TOPLEFT`, x=20, y=-200 |
| Handle height | `16` (px) |
| Default spells | left=재성장, right=재생, middle=치유의 손길 |
| Default maxBuffs | 6 |
| Default maxDebuffs | 3 |
| Default auraSize | 16 (px) |

### File load order
```
Core.lua → Frames.lua → Buffs.lua → SpellPicker.lua → Options.lua
```

### Global table structure
```lua
jjaliPartyFrame (global) / CP (local alias)
  CP.db          -- settings + SavedVariables mirror
  CP.colors      -- hp/power/debuff color tables
  CP.units       -- {"player","party1","party2","party3","party4"}
  CP.frames      -- unit string → frame map
  CP.container   -- single container frame
  CP.locked      -- drag lock state
  CP.Options     -- Options module
  CP.SpellPicker -- SpellPicker module
```

### Debuff border colors
```lua
Magic=blue(0.2,0.6,1), Curse=purple(0.6,0,1), Disease=brown(0.6,0.4,0), Poison=green(0,0.6,0)
```

---

## 6. Glossary & Inferences

| Term | Meaning |
|------|---------|
| Secret Value | Midnight API: HP/Power numbers are opaque during combat; Lua arithmetic on them throws error |
| `jjaliPartyFrameDB` | SavedVariables table persisted across sessions |
| SpellPicker | Singleton UI for selecting spells from live spellbook; opened per-slot |
| `CP` | Local alias for `jjaliPartyFrame` global table, used in every file |
| Handle bar | 16px draggable title bar at top of container; orange=unlocked, dark gray=locked |
| `SPELL_ATTR` | `{left="*spell1", right="*spell2", middle="*spell3"}` — SecureButton attribute keys |
| Debugging tools | BugGrabber + BugSack (installed), ViragDevTool, WowLua, `/console scriptErrors 1` |
| Korean client | All spell names must be Korean; SpellPicker reads live spellbook so language auto-matches |
| `numSpellBookItems` | Midnight renamed `numSpells` field in `GetSpellBookSkillLineInfo()` return table |
