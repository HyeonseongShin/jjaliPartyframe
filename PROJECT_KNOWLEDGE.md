# jjaliPartyFrame — 프로젝트 지식 문서

> 이 문서는 Claude 프로젝트 Knowledge에 업로드하여 새 세션에서도 컨텍스트를 유지하기 위한 파일입니다.
> 마지막 업데이트: 2026-04-02

---

## 1. 프로젝트 개요

**이름:** jjali's Party Frame
**파일명/폴더명:** `jjaliPartyFrame` (첫 글자 소문자 유지 — 변경 금지)
**제작자:** jjali (닉네임)
**목적:** WoW 기본 파티 프레임이 불편하여 제작한 커스텀 파티 프레임 애드온
**주요 플레이:** 복원 드루이드 (Restoration Druid), 한국어 클라이언트
**WoW 버전:** Midnight Retail (Interface: 120001)
**GitHub:** `git@github.com:HyeonseongShin/jjaliPartyframe.git`
**로컬 경로:** `C:\Users\bugbe\OneDrive\Workspace\claude\jjaliPartyFrame\`

---

## 2. 핵심 기술 제약사항 (반드시 숙지)

### 2-1. Lua 버전: 5.1
WoW 클라이언트는 **Lua 5.1**을 사용한다.
- `goto` / `::label::` 문법 — **사용 불가** (Lua 5.2+)
- 대신 `if ... then ... end` 블록으로 대체

```lua
-- ❌ 금지 (Lua 5.2+)
if not x then goto continue end
::continue::

-- ✅ 올바른 방법 (Lua 5.1)
if x then
    -- 처리
end
```

### 2-2. WoW Midnight Secret Value 시스템
Midnight 확장팩부터 **전투 중 HP/파워 수치에 직접 산술 연산 불가**.
- `UnitHealth() / UnitHealthMax()` 같은 나눗셈 → 전투 중 오류
- **해결:** `UnitHealthPercent(unit)` API 사용 (0~100 반환)
- `SetMinMaxValues` / `SetValue`에는 Raw 값 그대로 전달 가능

```lua
-- ✅ 올바른 방법
f.hpBar:SetMinMaxValues(0, UnitHealthMax(unit))
f.hpBar:SetValue(UnitHealth(unit))
local hpPct = (UnitHealthPercent(unit) or 100) / 100
f.hpBar:SetStatusBarColor(self:HPColor(hpPct))
```

### 2-3. SecureActionButtonTemplate
- 클릭 힐은 `SecureActionButtonTemplate`으로 구현
- **전투 중(`InCombatLockdown() == true`) 어트리뷰트 수정 불가**
- 스펠 변경(SpellPicker, AssignSpell)은 반드시 비전투 중에만 허용

### 2-4. C_SpellBook API (Midnight 기준)
```lua
C_SpellBook.GetNumSpellBookSkillLines()
C_SpellBook.GetSpellBookSkillLineInfo(lineIdx)   -- lineInfo.itemIndexOffset, lineInfo.numSpells
C_SpellBook.GetSpellBookItemInfo(slotIdx, Enum.SpellBookSpellBank.Player)
C_SpellBook.GetSpellBookItemName(slotIdx, Enum.SpellBookSpellBank.Player)
C_SpellBook.GetSpellBookItemTexture(slotIdx, Enum.SpellBookSpellBank.Player)
Enum.SpellBookItemType.Spell   -- 액티브 스펠 필터링
```

### 2-5. 스펠명: 한국어 클라이언트
사용자는 한국어 클라이언트를 사용한다. 스펠명은 한국어로 지정.
- 재성장 (Regrowth)
- 재생 (Rejuvenation)
- 치유의 손길 (Healing Touch)

---

## 3. 파일 구조 및 로드 순서

```
jjaliPartyFrame/
├── jjaliPartyFrame.toc   # 메타데이터, SavedVariables 선언
├── Core.lua              # 전역 테이블, DB, 이벤트, 슬래시 커맨드
├── Frames.lua            # 컨테이너 + 유닛 프레임 생성/업데이트
├── Buffs.lua             # 버프/디버프 아이콘
├── SpellPicker.lua       # 스펠북 기반 스펠 선택 UI
└── Options.lua           # /jjali 옵션 패널
```

**TOC 파일:**
```
## Interface: 120001
## Title: jjali's Party Frame
## Notes: jjali의 커스텀 파티 프레임 - HP/MP 바, 역할 아이콘, 버프/디버프, 클릭 힐
## Author: jjali
## Version: 1.0.0
## DefaultState: Enabled
## SavedVariables: jjaliPartyFrameDB

Core.lua
Frames.lua
Buffs.lua
SpellPicker.lua
Options.lua
```

---

## 4. 아키텍처 설계

### 전역 테이블 구조
```lua
jjaliPartyFrame = {}   -- 전역 (WoW 전역 네임스페이스)
local CP = jjaliPartyFrame  -- 로컬 별칭

CP.db       -- 기본 설정값 (SavedVariables 로드 전 기본값)
CP.colors   -- 색상 정의
CP.units    -- 유닛 목록 {"player","party1","party2","party3","party4"}
CP.frames   -- 유닛 → 프레임 맵
CP.container -- 단일 컨테이너 프레임
CP.locked   -- 드래그 잠금 상태
CP.Options      -- Options.lua 모듈
CP.SpellPicker  -- SpellPicker.lua 모듈
```

### SavedVariables 스키마 (`jjaliPartyFrameDB`)
```lua
{
    locked     = false,
    layout     = "vertical",   -- "vertical" | "horizontal"
    width      = 200,
    height     = 52,
    maxBuffs   = 6,
    maxDebuffs = 3,
    spells     = {
        left   = "재성장",
        right  = "재생",
        middle = "치유의 손길",
    },
    position   = { point = "TOPLEFT", x = 20, y = -200 },
}
```

### 컨테이너 구조
```
[Container Frame]  (jjaliPartyFrameContainer)
  └─ [Handle Bar]  (16px 높이, 드래그 영역)
       └─ [Label]  "jjali's Party Frame"
  └─ [UnitFrame: player]     (SecureActionButtonTemplate)
  └─ [UnitFrame: party1]
  └─ [UnitFrame: party2]
  └─ [UnitFrame: party3]
  └─ [UnitFrame: party4]
```

---

## 5. 각 파일 전체 코드

### Core.lua
```lua
-- jjaliPartyFrame/Core.lua
jjaliPartyFrame = {}
local CP = jjaliPartyFrame

CP.db = {
    width    = 200,
    height   = 52,
    padding  = 4,
    layout   = "vertical",
    spells = {
        left   = "재성장",
        right  = "재생",
        middle = "치유의 손길",
    },
    maxBuffs   = 6,
    maxDebuffs = 3,
    auraSize   = 16,
}

CP.colors = {
    hp = {
        high = { 0.2, 0.8, 0.3 },
        mid  = { 0.9, 0.8, 0.1 },
        low  = { 0.9, 0.2, 0.2 },
    },
    power = {
        MANA           = { 0.2, 0.4, 0.9 },
        RAGE           = { 0.8, 0.1, 0.1 },
        FOCUS          = { 0.8, 0.6, 0.1 },
        ENERGY         = { 0.9, 0.9, 0.1 },
        RUNIC_POWER    = { 0.0, 0.8, 1.0 },
        FURY           = { 0.7, 0.1, 0.9 },
        PAIN           = { 1.0, 0.6, 0.0 },
        MAELSTROM      = { 0.0, 0.6, 1.0 },
        INSANITY       = { 0.4, 0.0, 0.8 },
        SOUL_SHARDS    = { 0.5, 0.1, 0.6 },
        ASTRAL         = { 0.3, 0.8, 0.5 },
        ARCANE_CHARGES = { 0.2, 0.6, 1.0 },
        COMBO_POINTS   = { 1.0, 0.8, 0.1 },
    },
    debuff = {
        Magic   = { 0.2, 0.6, 1.0 },
        Curse   = { 0.6, 0.0, 1.0 },
        Disease = { 0.6, 0.4, 0.0 },
        Poison  = { 0.0, 0.6, 0.0 },
        default = { 0.8, 0.0, 0.0 },
    },
}

CP.units     = { "player", "party1", "party2", "party3", "party4" }
CP.frames    = {}
CP.container = nil
CP.locked    = false

function CP:HPColor(pct)
    if pct > 0.6 then return unpack(self.colors.hp.high)
    elseif pct > 0.3 then return unpack(self.colors.hp.mid)
    else return unpack(self.colors.hp.low)
    end
end

function CP:PowerColor(token)
    local c = self.colors.power[token]
    if c then return unpack(c) end
    return 0.2, 0.4, 0.9
end

function CP:InitDB()
    if not jjaliPartyFrameDB then jjaliPartyFrameDB = {} end
    local sv = jjaliPartyFrameDB
    self.locked = sv.locked or false
    if sv.layout   then self.db.layout   = sv.layout   end
    if sv.width    then self.db.width    = sv.width    end
    if sv.height   then self.db.height   = sv.height   end
    if sv.maxBuffs   then self.db.maxBuffs   = sv.maxBuffs   end
    if sv.maxDebuffs then self.db.maxDebuffs = sv.maxDebuffs end
    if sv.spells then
        for k, v in pairs(sv.spells) do self.db.spells[k] = v end
    end
end

function CP:SaveDB()
    local sv = jjaliPartyFrameDB
    sv.locked     = self.locked
    sv.layout     = self.db.layout
    sv.width      = self.db.width
    sv.height     = self.db.height
    sv.maxBuffs   = self.db.maxBuffs
    sv.maxDebuffs = self.db.maxDebuffs
    sv.spells     = {}
    for k, v in pairs(self.db.spells) do sv.spells[k] = v end
end

local SPELL_ATTR = { left = "*spell1", right = "*spell2", middle = "*spell3" }
function CP:AssignSpell(slot, spellName)
    self.db.spells[slot] = spellName
    self:SaveDB()
    if not InCombatLockdown() then
        for _, f in pairs(self.frames) do
            f:SetAttribute(SPELL_ATTR[slot], spellName)
        end
    end
end

function CP:SaveContainerPos()
    if not self.container then return end
    local point, _, _, x, y = self.container:GetPoint()
    jjaliPartyFrameDB.position = { point = point, x = x, y = y }
end

function CP:LoadContainerPos()
    local pos = jjaliPartyFrameDB and jjaliPartyFrameDB.position
    if pos then
        self.container:ClearAllPoints()
        self.container:SetPoint(pos.point, UIParent, pos.point, pos.x, pos.y)
        return true
    end
    return false
end

function CP:SetLocked(locked)
    self.locked = locked
    jjaliPartyFrameDB.locked = locked
    if self.container and self.container.handle then
        local h = self.container.handle
        if locked then
            h.bg:SetColorTexture(0.08, 0.08, 0.08, 0.95)
            h.label:SetTextColor(0.6, 0.6, 0.6)
        else
            h.bg:SetColorTexture(1.0, 0.55, 0.0, 0.9)
            h.label:SetTextColor(0.05, 0.05, 0.05)
        end
    end
    if CP.Options and CP.Options.RefreshLockButtons then
        CP.Options:RefreshLockButtons()
    end
end

function CP:SetLayout(layout)
    self.db.layout = layout
    jjaliPartyFrameDB.layout = layout
    self:LayoutFrames()
    if CP.Options and CP.Options.RefreshLayoutButtons then
        CP.Options:RefreshLayoutButtons()
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
eventFrame:RegisterEvent("ROLE_CHANGED_INFORM")
eventFrame:RegisterEvent("UNIT_HEALTH")
eventFrame:RegisterEvent("UNIT_MAXHEALTH")
eventFrame:RegisterEvent("UNIT_POWER_UPDATE")
eventFrame:RegisterEvent("UNIT_MAXPOWER")
eventFrame:RegisterEvent("UNIT_CONNECTION")
eventFrame:RegisterEvent("UNIT_FLAGS")
eventFrame:RegisterEvent("UNIT_AURA")

eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "PLAYER_LOGIN" then
        CP:InitDB()
        CP:InitFrames()
    elseif event == "GROUP_ROSTER_UPDATE"
        or event == "PLAYER_ROLES_ASSIGNED"
        or event == "ROLE_CHANGED_INFORM" then
        CP:UpdateAll()
    elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH"
        or event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER"
        or event == "UNIT_CONNECTION"   or event == "UNIT_FLAGS" then
        local f = CP.frames[arg1]
        if f then CP:UpdateFrame(f) end
    elseif event == "UNIT_AURA" then
        local f = CP.frames[arg1]
        if f then CP:UpdateAuras(f) end
    end
end)

SLASH_JJALIPARTYFRAME1 = "/jjali"
SLASH_JJALIPARTYFRAME2 = "/jpf"
SlashCmdList["JJALIPARTYFRAME"] = function(msg)
    if msg == "" or msg == nil then
        if CP.Options then CP.Options:Toggle() end
    elseif msg == "lock" then
        CP:SetLocked(true)
    elseif msg == "unlock" then
        CP:SetLocked(false)
    elseif msg == "reset" then
        jjaliPartyFrameDB.position = nil
        CP.container:ClearAllPoints()
        CP.container:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 20, -200)
        print("|cffff9900jjali's Party Frame:|r 위치를 초기화했습니다.")
    else
        print("|cffff9900jjali's Party Frame 명령어:|r")
        print("  /jjali         - 옵션 패널 열기")
        print("  /jjali lock    - 프레임 잠금")
        print("  /jjali unlock  - 프레임 잠금 해제")
        print("  /jjali reset   - 위치 초기화")
    end
end
```

### Frames.lua
```lua
-- jjaliPartyFrame/Frames.lua
local CP = jjaliPartyFrame

local ROLE_COORDS = {
    TANK    = { 0,   0.5, 0,   0.5 },
    HEALER  = { 0.5, 1.0, 0,   0.5 },
    DAMAGER = { 0,   0.5, 0.5, 1.0 },
}
local HANDLE_H = 16

local function ContainerSize()
    local db   = CP.db
    local n    = #CP.units
    local aura = db.auraSize + 6
    local fh   = db.height + aura
    if db.layout == "horizontal" then
        local w = n * db.width + (n - 1) * db.padding
        return w, HANDLE_H + fh
    else
        local h = HANDLE_H + n * fh + (n - 1) * db.padding
        return db.width, h
    end
end

local function CreateContainer()
    local w, h = ContainerSize()
    local c = CreateFrame("Frame", "jjaliPartyFrameContainer", UIParent)
    c:SetSize(w, h)
    c:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 20, -200)
    c:SetFrameStrata("MEDIUM")
    c:SetMovable(true)
    c:SetClampedToScreen(true)
    c:EnableMouse(false)

    local handle = CreateFrame("Frame", nil, c)
    handle:SetPoint("TOPLEFT",  c, "TOPLEFT",  0, 0)
    handle:SetPoint("TOPRIGHT", c, "TOPRIGHT", 0, 0)
    handle:SetHeight(HANDLE_H)
    handle:EnableMouse(true)

    local hbg = handle:CreateTexture(nil, "BACKGROUND")
    hbg:SetAllPoints()
    hbg:SetColorTexture(0.08, 0.08, 0.08, 0.95)
    handle.bg = hbg

    local label = handle:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("CENTER", handle, "CENTER")
    label:SetText("jjali's Party Frame")
    label:SetTextColor(0.6, 0.6, 0.6)
    handle.label = label

    handle:SetScript("OnMouseDown", function(self, btn)
        if btn == "LeftButton" and not InCombatLockdown() and not CP.locked then
            c:StartMoving()
        end
    end)
    handle:SetScript("OnMouseUp", function()
        c:StopMovingOrSizing()
        CP:SaveContainerPos()
    end)

    c.handle = handle
    return c
end

local function CreateUnitFrame(unit)
    local db = CP.db
    local c  = CP.container
    local f = CreateFrame("Button", "jjaliPartyUnitFrame_" .. unit,
                          c, "SecureActionButtonTemplate")
    f:SetSize(db.width, db.height)
    f:SetFrameStrata("MEDIUM")
    f:RegisterForClicks("AnyUp")

    f:SetAttribute("unit",    unit)
    f:SetAttribute("*type1",  "spell")
    f:SetAttribute("*spell1", db.spells.left)
    f:SetAttribute("*type2",  "spell")
    f:SetAttribute("*spell2", db.spells.right)
    f:SetAttribute("*type3",  "spell")
    f:SetAttribute("*spell3", db.spells.middle)

    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.05, 0.05, 0.05, 0.88)

    local border = f:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT",     f, "TOPLEFT",     -1,  1)
    border:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT",  1, -1)
    border:SetColorTexture(0.12, 0.12, 0.12, 1)
    border:SetDrawLayer("BORDER", -1)

    local hpBar = CreateFrame("StatusBar", nil, f)
    hpBar:SetPoint("TOPLEFT",  f, "TOPLEFT",   2, -2)
    hpBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
    hpBar:SetHeight(db.height - 14)
    hpBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    hpBar:SetStatusBarColor(0.2, 0.8, 0.3)
    hpBar:SetMinMaxValues(0, 1)
    hpBar:SetValue(1)
    f.hpBar = hpBar

    local hpBg = hpBar:CreateTexture(nil, "BACKGROUND")
    hpBg:SetAllPoints()
    hpBg:SetColorTexture(0, 0, 0, 0.4)

    local nameText = hpBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameText:SetPoint("LEFT",  hpBar, "LEFT",   4,   0)
    nameText:SetPoint("RIGHT", hpBar, "RIGHT", -22,  0)
    nameText:SetJustifyH("LEFT")
    nameText:SetWordWrap(false)
    f.nameText = nameText

    local hpText = hpBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hpText:SetPoint("RIGHT", hpBar, "RIGHT", -4, 0)
    hpText:SetJustifyH("RIGHT")
    f.hpText = hpText

    local roleIcon = f:CreateTexture(nil, "OVERLAY")
    roleIcon:SetSize(14, 14)
    roleIcon:SetPoint("TOPRIGHT", hpBar, "TOPRIGHT", -2, -3)
    roleIcon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-ROLES")
    roleIcon:Hide()
    f.roleIcon = roleIcon

    local mpBar = CreateFrame("StatusBar", nil, f)
    mpBar:SetPoint("TOPLEFT",  hpBar, "BOTTOMLEFT",  0, -2)
    mpBar:SetPoint("TOPRIGHT", hpBar, "BOTTOMRIGHT", 0, -2)
    mpBar:SetHeight(6)
    mpBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    mpBar:SetStatusBarColor(0.2, 0.4, 0.9)
    mpBar:SetMinMaxValues(0, 1)
    mpBar:SetValue(1)
    f.mpBar = mpBar

    local mpBg = mpBar:CreateTexture(nil, "BACKGROUND")
    mpBg:SetAllPoints()
    mpBg:SetColorTexture(0, 0, 0, 0.4)

    local deadOverlay = f:CreateTexture(nil, "OVERLAY")
    deadOverlay:SetPoint("TOPLEFT",     hpBar, "TOPLEFT")
    deadOverlay:SetPoint("BOTTOMRIGHT", mpBar,  "BOTTOMRIGHT")
    deadOverlay:SetColorTexture(0, 0, 0, 0.65)
    deadOverlay:Hide()
    f.deadOverlay = deadOverlay

    local deadText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    deadText:SetPoint("CENTER", hpBar, "CENTER")
    deadText:Hide()
    f.deadText = deadText

    local auraFrame = CreateFrame("Frame", nil, f)
    auraFrame:SetPoint("TOPLEFT",  mpBar, "BOTTOMLEFT",  0, -3)
    auraFrame:SetPoint("TOPRIGHT", mpBar, "BOTTOMRIGHT", 0, -3)
    auraFrame:SetHeight(db.auraSize + 2)
    f.auraFrame = auraFrame

    f.buffIcons   = {}
    f.debuffIcons = {}
    f.unit = unit
    return f
end

function CP:LayoutFrames()
    local db   = self.db
    local aura = db.auraSize + 6
    local fh   = db.height + aura
    local cw, ch = ContainerSize()
    self.container:SetSize(cw, ch)

    for i, unit in ipairs(self.units) do
        local f = self.frames[unit]
        if f then
            f:SetSize(db.width, db.height)
            f:ClearAllPoints()
            if db.layout == "horizontal" then
                local xOff = (i - 1) * (db.width + db.padding)
                f:SetPoint("TOPLEFT", self.container, "TOPLEFT", xOff, -HANDLE_H)
            else
                local yOff = -HANDLE_H - (i - 1) * (fh + db.padding)
                f:SetPoint("TOPLEFT", self.container, "TOPLEFT", 0, yOff)
            end
            self.container.handle:SetPoint("TOPRIGHT", self.container, "TOPRIGHT", 0, 0)
        end
    end
end

function CP:UpdateFrame(f)
    local unit = f.unit
    if not UnitExists(unit) then
        f:Hide()
        return
    end
    f:Show()

    local isDead    = UnitIsDeadOrGhost(unit)
    local isOffline = not UnitIsConnected(unit)

    f.hpBar:SetMinMaxValues(0, UnitHealthMax(unit))
    f.hpBar:SetValue(UnitHealth(unit))
    local hpPct = (UnitHealthPercent(unit) or 100) / 100
    f.hpBar:SetStatusBarColor(self:HPColor(hpPct))

    local name = UnitName(unit) or unit
    if #name > 13 then name = name:sub(1, 12) .. "…" end
    f.nameText:SetText(name)

    if isDead then
        f.hpText:SetText("사망")
        f.hpText:SetTextColor(0.9, 0.2, 0.2)
    elseif isOffline then
        f.hpText:SetText("오프")
        f.hpText:SetTextColor(0.5, 0.5, 0.5)
    else
        f.hpText:SetText(math.floor(UnitHealthPercent(unit) or 100) .. "%")
        f.hpText:SetTextColor(1, 1, 1)
    end

    if isDead or isOffline then
        f.deadOverlay:Show()
        f.deadText:SetText(isDead and "사 망" or "오프라인")
        f.deadText:SetTextColor(isDead and 0.9 or 0.5, isDead and 0.2 or 0.5, isDead and 0.2 or 0.5)
        f.deadText:Show()
    else
        f.deadOverlay:Hide()
        f.deadText:Hide()
    end

    local powerTypeId = UnitPowerType(unit)
    f.mpBar:SetMinMaxValues(0, UnitPowerMax(unit, powerTypeId))
    f.mpBar:SetValue(UnitPower(unit, powerTypeId))
    local _, powerToken = UnitPowerType(unit)
    f.mpBar:SetStatusBarColor(self:PowerColor(powerToken))

    local role   = UnitGroupRolesAssigned(unit)
    local coords = ROLE_COORDS[role]
    if coords then
        f.roleIcon:SetTexCoord(unpack(coords))
        f.roleIcon:Show()
    else
        f.roleIcon:Hide()
    end

    self:UpdateAuras(f)
end

function CP:UpdateAll()
    for _, f in pairs(self.frames) do
        self:UpdateFrame(f)
    end
end

function CP:InitFrames()
    if PartyFrame and not InCombatLockdown() then
        PartyFrame:Hide()
        PartyFrame:UnregisterAllEvents()
    end

    if not self.container then
        self.container = CreateContainer()
    end

    for _, unit in ipairs(self.units) do
        if not self.frames[unit] then
            self.frames[unit] = CreateUnitFrame(unit)
        end
    end

    self:LayoutFrames()

    if not self:LoadContainerPos() then
        self.container:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 20, -200)
    end

    self:SetLocked(self.locked)
    self:UpdateAll()
end
```

### Buffs.lua
```lua
-- jjaliPartyFrame/Buffs.lua
local CP = jjaliPartyFrame

local function GetIcon(parent, list, index, isDebuff)
    if list[index] then return list[index] end
    local size = CP.db.auraSize
    local icon = CreateFrame("Frame", nil, parent)
    icon:SetSize(size, size)

    local tex = icon:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    icon.tex = tex

    local ct = icon:CreateFontString(nil, "OVERLAY")
    ct:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1)
    ct:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
    ct:SetTextColor(1, 1, 1)
    icon.count = ct

    if isDebuff then
        local border = icon:CreateTexture(nil, "OVERLAY")
        border:SetPoint("TOPLEFT",     icon, "TOPLEFT",     -1,  1)
        border:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT",  1, -1)
        border:SetColorTexture(0.8, 0, 0, 1)
        border:SetDrawLayer("OVERLAY", -1)
        icon.border = border
    end

    list[index] = icon
    return icon
end

function CP:UpdateAuras(f)
    local unit   = f.unit
    local db     = self.db
    local size   = db.auraSize

    local buffCount = 0
    local i = 1
    while buffCount < db.maxBuffs do
        local data = C_UnitAuras.GetBuffDataByIndex(unit, i)
        if not data then break end
        i = i + 1
        if data.icon then
            buffCount = buffCount + 1
            local icon = GetIcon(f.auraFrame, f.buffIcons, buffCount, false)
            icon:SetPoint("TOPLEFT", f.auraFrame, "TOPLEFT",
                          (buffCount - 1) * (size + 1), 0)
            icon.tex:SetTexture(data.icon)
            icon.count:SetText(data.applications and data.applications > 1
                               and data.applications or "")
            icon:Show()
        end
    end
    for j = buffCount + 1, #f.buffIcons do f.buffIcons[j]:Hide() end

    local offsetX   = buffCount * (size + 1) + (buffCount > 0 and 4 or 0)
    local debuffCount = 0
    i = 1
    while debuffCount < db.maxDebuffs do
        local data = C_UnitAuras.GetDebuffDataByIndex(unit, i)
        if not data then break end
        i = i + 1
        if data.icon then
            debuffCount = debuffCount + 1
            local icon = GetIcon(f.auraFrame, f.debuffIcons, debuffCount, true)
            icon:SetPoint("TOPLEFT", f.auraFrame, "TOPLEFT",
                          offsetX + (debuffCount - 1) * (size + 2), 0)
            icon.tex:SetTexture(data.icon)
            icon.count:SetText(data.applications and data.applications > 1
                               and data.applications or "")
            if icon.border then
                local dc = self.colors.debuff[data.dispelName]
                         or self.colors.debuff.default
                icon.border:SetColorTexture(unpack(dc))
            end
            icon:Show()
        end
    end
    for j = debuffCount + 1, #f.debuffIcons do f.debuffIcons[j]:Hide() end
end
```

### SpellPicker.lua
```lua
-- jjaliPartyFrame/SpellPicker.lua
local CP = jjaliPartyFrame
CP.SpellPicker = {}
local SP = CP.SpellPicker

local ENTRY_H  = 26
local PICKER_W = 230
local PICKER_H = 330

SP.cache       = {}
SP.dirty       = true
SP.frame       = nil
SP.currentSlot = nil
SP.onSelect    = nil

function SP:InvalidateCache() self.dirty = true end

function SP:BuildSpellList()
    if not self.dirty then return end
    self.cache = {}
    local seen = {}

    local numLines = C_SpellBook.GetNumSpellBookSkillLines()
    for lineIdx = 1, numLines do
        local lineInfo = C_SpellBook.GetSpellBookSkillLineInfo(lineIdx)
        if lineInfo then
            local slotStart  = lineInfo.itemIndexOffset + 1
            local slotFinish = lineInfo.itemIndexOffset + lineInfo.numSpells
            for slotIdx = slotStart, slotFinish do
                local itemInfo = C_SpellBook.GetSpellBookItemInfo(
                    slotIdx, Enum.SpellBookSpellBank.Player)
                if itemInfo and itemInfo.itemType == Enum.SpellBookItemType.Spell then
                    local name = C_SpellBook.GetSpellBookItemName(
                        slotIdx, Enum.SpellBookSpellBank.Player)
                    if name and not seen[name] then
                        seen[name] = true
                        local icon = C_SpellBook.GetSpellBookItemTexture(
                            slotIdx, Enum.SpellBookSpellBank.Player)
                        table.insert(self.cache, { name = name, icon = icon })
                    end
                end
            end
        end
    end

    table.sort(self.cache, function(a, b) return a.name < b.name end)
    self.dirty = false
end

function SP:GetIconForSpell(name)
    self:BuildSpellList()
    for _, spell in ipairs(self.cache) do
        if spell.name == name then return spell.icon end
    end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

function SP:BuildFrame()
    local f = CreateFrame("Frame", "jjaliSpellPicker", UIParent, "BackdropTemplate")
    f:SetSize(PICKER_W, PICKER_H)
    f:SetFrameStrata("TOOLTIP")
    f:SetClampedToScreen(true)
    f:Hide()

    f:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 22,
        insets = { left=8, right=8, top=8, bottom=8 },
    })

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", 2, 2)
    closeBtn:SetScript("OnClick", function() SP:Close() end)

    local search = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    search:SetSize(PICKER_W - 36, 20)
    search:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -12)
    search:SetAutoFocus(true)
    search:SetMaxLetters(64)
    search:SetScript("OnTextChanged", function(self)
        SP:FilterAndRender(self:GetText())
    end)
    search:SetScript("OnEscapePressed", function() SP:Close() end)
    f.searchBox = search

    local scrollFrame = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT",     f, "TOPLEFT",     10, -40)
    scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -28, 10)
    f.scrollFrame = scrollFrame

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(PICKER_W - 42, 1)
    scrollFrame:SetScrollChild(scrollChild)
    f.scrollChild = scrollChild

    f.entryButtons = {}
    self.frame = f
end

local function CreateEntryButton(parent)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(PICKER_W - 44, ENTRY_H)

    local highlightBg = btn:CreateTexture(nil, "BACKGROUND")
    highlightBg:SetAllPoints()
    highlightBg:SetColorTexture(0, 0, 0, 0)
    btn.highlightBg = highlightBg

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(18, 18)
    icon:SetPoint("LEFT", btn, "LEFT", 2, 0)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    btn.icon = icon

    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("LEFT",  icon,  "RIGHT", 5, 0)
    label:SetPoint("RIGHT", btn,   "RIGHT", 0, 0)
    label:SetJustifyH("LEFT")
    label:SetWordWrap(false)
    btn.label = label

    btn:SetScript("OnEnter", function(self)
        self.highlightBg:SetColorTexture(1, 0.75, 0, 0.18)
    end)
    btn:SetScript("OnLeave", function(self)
        self.highlightBg:SetColorTexture(0, 0, 0, 0)
    end)
    btn:SetScript("OnClick", function(self)
        SP:SelectSpell(self.spellName)
    end)

    return btn
end

function SP:FilterAndRender(filter)
    local lower = filter:lower()
    local filtered = {}
    for _, spell in ipairs(self.cache) do
        if lower == "" or spell.name:lower():find(lower, 1, true) then
            table.insert(filtered, spell)
        end
    end
    self:RenderList(filtered)
end

function SP:RenderList(spells)
    local child   = self.frame.scrollChild
    local buttons = self.frame.entryButtons
    child:SetHeight(math.max(1, #spells * ENTRY_H))
    for i = 1, math.max(#spells, #buttons) do
        if i <= #spells then
            local spell = spells[i]
            if not buttons[i] then buttons[i] = CreateEntryButton(child) end
            local btn = buttons[i]
            btn:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -(i - 1) * ENTRY_H)
            btn.icon:SetTexture(spell.icon)
            btn.label:SetText(spell.name)
            btn.spellName = spell.name
            btn:Show()
        elseif buttons[i] then
            buttons[i]:Hide()
        end
    end
end

function SP:Open(slot, anchorFrame, onSelectFn)
    if InCombatLockdown() then
        print("|cffff9900jjali's Party Frame:|r 전투 중에는 스펠을 변경할 수 없습니다.")
        return
    end
    self.currentSlot = slot
    self.onSelect    = onSelectFn
    if not self.frame then self:BuildFrame() end
    self:BuildSpellList()
    self.frame:ClearAllPoints()
    self.frame:SetPoint("TOPLEFT", anchorFrame, "TOPRIGHT", 6, 0)
    self.frame.searchBox:SetText("")
    self.frame.searchBox:SetFocus()
    self:FilterAndRender("")
    self.frame:Show()
end

function SP:Close()
    if self.frame then self.frame:Hide() end
    self.currentSlot = nil
    self.onSelect    = nil
end

function SP:SelectSpell(spellName)
    if self.onSelect then self.onSelect(self.currentSlot, spellName) end
    self:Close()
end

local watcher = CreateFrame("Frame")
watcher:RegisterEvent("SPELLS_CHANGED")
watcher:SetScript("OnEvent", function()
    CP.SpellPicker:InvalidateCache()
end)
```

### Options.lua
```lua
-- jjaliPartyFrame/Options.lua
local CP = jjaliPartyFrame
CP.Options = {}
local OPT = CP.Options

local function MakeButton(parent, w, h, text, onClick)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(w, h)
    btn:SetText(text)
    btn:SetScript("OnClick", onClick)
    return btn
end

local function MakeLabel(parent, text, size, r, g, b)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetText(text)
    fs:SetFont(fs:GetFont(), size or 11, "OUTLINE")
    fs:SetTextColor(r or 1, g or 0.8, b or 0.2)
    return fs
end

local function MakeDivider(parent, yRef)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("TOPLEFT",  parent, "TOPLEFT",   12, yRef)
    line:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -12, yRef)
    line:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    return line
end

function OPT:Build()
    local panel = CreateFrame("Frame", "jjaliPartyFrameOptions", UIParent, "BackdropTemplate")
    panel:SetSize(320, 420)
    panel:SetPoint("CENTER")
    panel:SetFrameStrata("DIALOG")
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:SetClampedToScreen(true)
    panel:Hide()

    panel:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile     = true, tileSize = 32, edgeSize = 26,
        insets   = { left=9, right=9, top=9, bottom=9 },
    })

    local titleBar = CreateFrame("Frame", nil, panel)
    titleBar:SetPoint("TOPLEFT",  panel, "TOPLEFT",  0, 0)
    titleBar:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, 0)
    titleBar:SetHeight(30)
    titleBar:EnableMouse(true)
    titleBar:SetScript("OnMouseDown", function() panel:StartMoving() end)
    titleBar:SetScript("OnMouseUp",   function() panel:StopMovingOrSizing() end)

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", panel, "TOP", 0, -14)
    title:SetText("jjali's Party Frame")
    title:SetTextColor(1, 0.8, 0.1)

    local closeBtn = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 2, 2)
    closeBtn:SetScript("OnClick", function() panel:Hide() end)

    local y = -44

    -- 레이아웃 섹션
    MakeDivider(panel, y); y = y - 14
    local layoutLabel = MakeLabel(panel, "레이아웃", 11)
    layoutLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, y)
    y = y - 26

    local btnVertical = MakeButton(panel, 130, 26, "▼  세로 정렬", function()
        CP:SetLayout("vertical")
    end)
    btnVertical:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, y)

    local btnHorizontal = MakeButton(panel, 130, 26, "▶  가로 정렬", function()
        CP:SetLayout("horizontal")
    end)
    btnHorizontal:SetPoint("TOPLEFT", panel, "TOPLEFT", 156, y)
    y = y - 36

    self.btnVertical   = btnVertical
    self.btnHorizontal = btnHorizontal

    -- 위치 섹션
    MakeDivider(panel, y); y = y - 14
    local posLabel = MakeLabel(panel, "위치", 11)
    posLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, y)
    y = y - 26

    local btnUnlock = MakeButton(panel, 88, 26, "🔓 잠금 해제", function() CP:SetLocked(false) end)
    btnUnlock:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, y)
    local btnLock = MakeButton(panel, 88, 26, "🔒 잠금", function() CP:SetLocked(true) end)
    btnLock:SetPoint("TOPLEFT", panel, "TOPLEFT", 112, y)
    local btnReset = MakeButton(panel, 88, 26, "↺  초기화", function()
        jjaliPartyFrameDB.position = nil
        CP.container:ClearAllPoints()
        CP.container:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 20, -200)
    end)
    btnReset:SetPoint("TOPLEFT", panel, "TOPLEFT", 208, y)
    y = y - 14

    local lockHint = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lockHint:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, y)
    lockHint:SetText("잠금 해제 상태에서 핸들 바를 드래그하여 이동하세요.")
    lockHint:SetTextColor(0.6, 0.6, 0.6)
    y = y - 30

    self.btnLock   = btnLock
    self.btnUnlock = btnUnlock

    -- 클릭 힐 스펠 섹션
    MakeDivider(panel, y); y = y - 14
    local spellLabel = MakeLabel(panel, "클릭 힐 스펠", 11)
    spellLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, y)
    y = y - 26

    local SLOT_DEFS = {
        { key = "left",   label = "왼쪽 클릭" },
        { key = "right",  label = "오른쪽 클릭" },
        { key = "middle", label = "미들 클릭"   },
    }
    self.spellSlots = {}

    for _, def in ipairs(SLOT_DEFS) do
        local lbl = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, y)
        lbl:SetText(def.label)
        lbl:SetTextColor(0.8, 0.8, 0.8)

        local iconFrame = CreateFrame("Frame", nil, panel)
        iconFrame:SetSize(20, 20)
        iconFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", 96, y + 1)
        local iconTex = iconFrame:CreateTexture(nil, "ARTWORK")
        iconTex:SetAllPoints()
        iconTex:SetTexCoord(0.07, 0.93, 0.07, 0.93)

        local nameLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        nameLabel:SetPoint("LEFT",  iconFrame, "RIGHT", 4,   0)
        nameLabel:SetPoint("RIGHT", panel,     "RIGHT", -70, y)
        nameLabel:SetJustifyH("LEFT")
        nameLabel:SetWordWrap(false)
        nameLabel:SetTextColor(1, 1, 1)

        local slotKey   = def.key
        local changeBtn = MakeButton(panel, 56, 20, "변경", nil)
        changeBtn:SetPoint("RIGHT", panel, "RIGHT", -12, y + 10)
        changeBtn:SetScript("OnClick", function(self)
            CP.SpellPicker:Open(slotKey, self, function(slot, spellName)
                CP:AssignSpell(slot, spellName)
                OPT:RefreshSpellSlots()
            end)
        end)

        self.spellSlots[def.key] = { icon = iconTex, name = nameLabel }
        y = y - 30
    end

    local combatHint = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    combatHint:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, y)
    combatHint:SetText("스펠북에서 직접 선택합니다. 전투 중 변경 불가.")
    combatHint:SetTextColor(0.5, 0.5, 0.5)
    y = y - 26

    -- 버프/디버프 섹션
    MakeDivider(panel, y); y = y - 14
    local dispLabel = MakeLabel(panel, "버프/디버프", 11)
    dispLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, y)
    y = y - 26

    local function MakeCounter(parent, xBase, yPos, labelTxt, getter, setter, minV, maxV)
        local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("TOPLEFT", parent, "TOPLEFT", xBase, yPos)
        lbl:SetText(labelTxt)
        lbl:SetTextColor(0.8, 0.8, 0.8)

        local valText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        valText:SetPoint("TOPLEFT", parent, "TOPLEFT", xBase + 80, yPos)
        valText:SetText(tostring(getter()))

        local btnM = MakeButton(parent, 22, 22, "-", function()
            local v = math.max(minV, getter() - 1)
            setter(v); valText:SetText(tostring(v))
        end)
        btnM:SetPoint("TOPLEFT", parent, "TOPLEFT", xBase + 100, yPos + 2)

        local btnP = MakeButton(parent, 22, 22, "+", function()
            local v = math.min(maxV, getter() + 1)
            setter(v); valText:SetText(tostring(v))
        end)
        btnP:SetPoint("TOPLEFT", parent, "TOPLEFT", xBase + 126, yPos + 2)
    end

    MakeCounter(panel, 16, y,
        "버프 최대",
        function() return CP.db.maxBuffs end,
        function(v) CP.db.maxBuffs = v; CP:SaveDB() end,
        1, 12)
    MakeCounter(panel, 166, y,
        "디버프 최대",
        function() return CP.db.maxDebuffs end,
        function(v) CP.db.maxDebuffs = v; CP:SaveDB() end,
        1, 8)

    self.panel = panel
end

function OPT:RefreshLayoutButtons()
    if not self.panel then return end
    local isVert = CP.db.layout == "vertical"
    self.btnVertical:SetEnabled(not isVert)
    self.btnHorizontal:SetEnabled(isVert)
end

function OPT:RefreshLockButtons()
    if not self.panel then return end
    self.btnLock:SetEnabled(not CP.locked)
    self.btnUnlock:SetEnabled(CP.locked)
end

function OPT:RefreshSpellSlots()
    if not self.spellSlots then return end
    for key, slot in pairs(self.spellSlots) do
        local spellName = CP.db.spells[key]
        slot.name:SetText(spellName or "없음")
        local icon = CP.SpellPicker:GetIconForSpell(spellName or "")
        slot.icon:SetTexture(icon)
    end
end

function OPT:Toggle()
    if not self.panel then self:Build() end
    if self.panel:IsShown() then
        self.panel:Hide()
    else
        self:RefreshLayoutButtons()
        self:RefreshLockButtons()
        self:RefreshSpellSlots()
        self.panel:Show()
    end
end
```

---

## 6. 개발 규칙 및 사용자 선호사항

### Git 규칙
- **커밋은 자유롭게 해도 됨**
- **푸시는 사용자가 명시적으로 요청할 때만** ("푸시해줘" 라고 할 때만)
- Remote: `git@github.com:HyeonseongShin/jjaliPartyframe.git`
- SSH: `~/.ssh/config`에 `IdentityFile ~/.ssh/github` 설정됨

### 스킬 사용 규칙
- **기능 설계 시:** `anthropic-skills:system-design` 스킬 사용
- **코드 구현 시:** `anthropic-skills:clean-code-implementation` 스킬 사용
- 이 두 스킬은 jjali가 직접 만든 커스텀 스킬 (Anthropic 기본 제공 아님)

### 코딩 규칙
- 애드온 이름: `jjaliPartyFrame` (첫 글자 소문자 고정)
- Lua 5.1 문법만 사용 (`goto` 금지)
- 한국어 주석 및 UI 텍스트 사용

---

## 7. 알려진 버그 및 수정 이력

| 버그 | 원인 | 수정 방법 |
|------|------|-----------|
| SpellPicker.lua:34 `goto` 오류 | Lua 5.1 미지원 문법 | `if lineInfo then ... end` 블록으로 교체 |
| Frames.lua:196 `goto` 오류 | Lua 5.1 미지원 문법 | `if f then ... end` 블록으로 교체 |
| 프레임 앵커 -220px (화면 밖) | anchorX = -220 오기입 | anchorX = 20 으로 수정 |
| 전투 중 HP% 연산 오류 | Midnight Secret Value | `UnitHealthPercent()` 사용으로 교체 |
| 영문 스펠명 인식 안됨 | 한국어 클라이언트 | 한국어 스펠명으로 변경 |
| 5개 프레임 개별 이동 | 컨테이너 없음 | 단일 컨테이너 + 드래그 핸들 구조로 재설계 |

---

## 8. 디버깅 도구

사용자가 설치한 WoW 애드온 디버깅 도구:
- **BugGrabber** + **BugSack**: 런타임 에러 캐치 및 표시
- `/console scriptErrors 1`: 인게임 에러 출력 활성화
- **ViragDevTool**: 전역 변수 탐색기
- **WowLua**: 인게임 Lua 콘솔

---

## 9. 다음 작업 후보

현재 구현 완료된 기능:
- [x] HP/MP 바 (색상 변화 포함)
- [x] 역할 아이콘 (탱/힐/딜)
- [x] 버프/디버프 아이콘 (종류별 테두리 색)
- [x] 클릭 힐 (SecureActionButtonTemplate)
- [x] 컨테이너 그룹 + 드래그 핸들
- [x] 세로/가로 레이아웃 전환
- [x] 위치 저장/복원 (SavedVariables)
- [x] 잠금/잠금 해제
- [x] /jjali 옵션 패널
- [x] SpellPicker (스펠북에서 직접 선택)

향후 추가 가능한 기능:
- [ ] 프레임 크기 조절 옵션
- [ ] 플레이어 프레임 숨기기 옵션
- [ ] 인원수에 따라 자동 표시/숨김
- [ ] 힐 흡수량(Absorb) 표시
- [ ] 레이드 프레임 지원 (5인 초과)
