-- jjaliPartyFrame/SpellPicker.lua
-- 스펠북에서 스킬 목록을 읽어 선택하는 컴포넌트
-- 단일 책임: 스펠 선택 UI만 담당. 할당은 Core:AssignSpell()에 위임.

local CP = jjaliPartyFrame
CP.SpellPicker = {}
local SP = CP.SpellPicker

local ENTRY_H  = 26
local PICKER_W = 230
local PICKER_H = 330

-- ─── 캐시 ─────────────────────────────────────────────────────────────────────
SP.cache       = {}   -- { name, icon }[]
SP.dirty       = true -- 스펠북 변경 시 재빌드 필요
SP.frame       = nil
SP.currentSlot = nil
SP.onSelect    = nil

function SP:InvalidateCache()
    self.dirty = true
end

-- C_SpellBook에서 전체 스펠을 읽어 캐시 구성 (lazy, 중복 제거, 알파벳 정렬)
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

                -- 배운 액티브 스펠만 포함
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

-- 스펠 이름으로 아이콘 조회 (Options 슬롯 표시용)
function SP:GetIconForSpell(name)
    -- 캐시가 없으면 빌드
    self:BuildSpellList()
    for _, spell in ipairs(self.cache) do
        if spell.name == name then return spell.icon end
    end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- ─── UI 빌드 (최초 Open 시 1회 실행) ──────────────────────────────────────────
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

    -- 닫기 버튼
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", 2, 2)
    closeBtn:SetScript("OnClick", function() SP:Close() end)

    -- 검색창
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

    -- 스크롤 프레임
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

-- ─── 엔트리 버튼 생성 (재사용) ───────────────────────────────────────────────
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

-- ─── 목록 렌더링 ─────────────────────────────────────────────────────────────
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
            if not buttons[i] then
                buttons[i] = CreateEntryButton(child)
            end
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

-- ─── 공개 인터페이스 ──────────────────────────────────────────────────────────
function SP:Open(slot, anchorFrame, onSelectFn)
    -- 전투 중 어트리뷰트 수정 불가 → 차단
    if InCombatLockdown() then
        print("|cffff9900jjali's Party Frame:|r 전투 중에는 스펠을 변경할 수 없습니다.")
        return
    end

    self.currentSlot = slot
    self.onSelect    = onSelectFn

    if not self.frame then self:BuildFrame() end

    self:BuildSpellList()

    -- 앵커 프레임 오른쪽에 배치, 화면 밖이면 왼쪽으로
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
    if self.onSelect then
        self.onSelect(self.currentSlot, spellName)
    end
    self:Close()
end

-- ─── SPELLS_CHANGED 감지 → 캐시 무효화 ──────────────────────────────────────
local watcher = CreateFrame("Frame")
watcher:RegisterEvent("SPELLS_CHANGED")
watcher:SetScript("OnEvent", function()
    CP.SpellPicker:InvalidateCache()
end)
