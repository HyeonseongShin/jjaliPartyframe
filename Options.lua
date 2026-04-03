-- jjaliPartyFrame/Options.lua
-- 설정 UI 패널

local CP = jjaliPartyFrame
CP.Options = {}
local OPT = CP.Options

-- ─── 헬퍼: 버튼 생성 ─────────────────────────────────────────────────────────
local function MakeButton(parent, w, h, text, onClick)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(w, h)
    btn:SetText(text)
    btn:SetScript("OnClick", onClick)
    return btn
end

-- ─── 헬퍼: 섹션 라벨 ─────────────────────────────────────────────────────────
local function MakeLabel(parent, text, size, r, g, b)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetText(text)
    fs:SetFont(fs:GetFont(), size or 11, "OUTLINE")
    fs:SetTextColor(r or 1, g or 0.8, b or 0.2)
    return fs
end

-- ─── 헬퍼: 구분선 ────────────────────────────────────────────────────────────
local function MakeDivider(parent, yRef)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("TOPLEFT",  parent, "TOPLEFT",   12, yRef)
    line:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -12, yRef)
    line:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    return line
end


-- ─── 패널 생성 ────────────────────────────────────────────────────────────────
function OPT:Build()
    local panel = CreateFrame("Frame", "jjaliPartyFrameOptions", UIParent,
                              "BackdropTemplate")
    panel:SetSize(320, 560)
    panel:SetPoint("CENTER")
    panel:SetFrameStrata("DIALOG")
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:SetClampedToScreen(true)
    panel:Hide()

    -- 배경
    panel:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile     = true, tileSize = 32, edgeSize = 26,
        insets   = { left=9, right=9, top=9, bottom=9 },
    })

    -- 타이틀 바 (드래그)
    local titleBar = CreateFrame("Frame", nil, panel)
    titleBar:SetPoint("TOPLEFT",  panel, "TOPLEFT",   0, 0)
    titleBar:SetPoint("TOPRIGHT", panel, "TOPRIGHT",  0, 0)
    titleBar:SetHeight(30)
    titleBar:EnableMouse(true)
    titleBar:SetScript("OnMouseDown", function() panel:StartMoving() end)
    titleBar:SetScript("OnMouseUp",   function() panel:StopMovingOrSizing() end)

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", panel, "TOP", 0, -14)
    title:SetText("jjali's Party Frame")
    title:SetTextColor(1, 0.8, 0.1)

    -- 닫기 버튼
    local closeBtn = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 2, 2)
    closeBtn:SetScript("OnClick", function() panel:Hide() end)

    local y = -44  -- 현재 Y 커서

    -- ════════════════════════════════
    -- 섹션: 레이아웃
    -- ════════════════════════════════
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

    -- ════════════════════════════════
    -- 섹션: 위치 잠금
    -- ════════════════════════════════
    MakeDivider(panel, y); y = y - 14
    local posLabel = MakeLabel(panel, "위치", 11)
    posLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, y)
    y = y - 26

    local btnUnlock = MakeButton(panel, 88, 26, "잠금 해제", function()
        CP:SetLocked(false)
    end)
    btnUnlock:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, y)

    local btnLock = MakeButton(panel, 88, 26, "잠금", function()
        CP:SetLocked(true)
    end)
    btnLock:SetPoint("TOPLEFT", panel, "TOPLEFT", 112, y)

    local btnReset = MakeButton(panel, 88, 26, "초기화", function()
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

    -- ════════════════════════════════
    -- 섹션: 클릭 힐 스펠
    -- ════════════════════════════════
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
        -- 슬롯 라벨
        local lbl = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, y)
        lbl:SetText(def.label)
        lbl:SetTextColor(0.8, 0.8, 0.8)

        -- 스펠 아이콘
        local iconFrame = CreateFrame("Frame", nil, panel)
        iconFrame:SetSize(20, 20)
        iconFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", 96, y + 1)
        local iconTex = iconFrame:CreateTexture(nil, "ARTWORK")
        iconTex:SetAllPoints()
        iconTex:SetTexCoord(0.07, 0.93, 0.07, 0.93)

        -- 변경 버튼 → SpellPicker 열기 (TOPLEFT 기준으로 배치)
        local slotKey   = def.key
        local changeBtn = MakeButton(panel, 56, 20, "변경", nil)
        changeBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", 252, y - 2)

        -- 현재 스펠 이름
        local nameLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        nameLabel:SetPoint("LEFT",  iconFrame, "RIGHT", 4, 0)
        nameLabel:SetPoint("RIGHT", changeBtn, "LEFT", -4, 0)
        nameLabel:SetJustifyH("LEFT")
        nameLabel:SetWordWrap(false)
        nameLabel:SetTextColor(1, 1, 1)
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

    -- ════════════════════════════════
    -- 섹션: 표시 설정
    -- ════════════════════════════════
    MakeDivider(panel, y); y = y - 14
    local dispLabel = MakeLabel(panel, "버프/디버프", 11)
    dispLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, y)
    y = y - 26

    -- 버프 최대 개수
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
            setter(v)
            valText:SetText(tostring(v))
        end)
        btnM:SetPoint("TOPLEFT", parent, "TOPLEFT", xBase + 100, yPos + 2)

        local btnP = MakeButton(parent, 22, 22, "+", function()
            local v = math.min(maxV, getter() + 1)
            setter(v)
            valText:SetText(tostring(v))
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

    y = y - 32

    -- ════════════════════════════════
    -- 섹션: 프레임 크기
    -- ════════════════════════════════
    MakeDivider(panel, y); y = y - 14
    local sizeLabel = MakeLabel(panel, "프레임 크기", 11)
    sizeLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, y)
    y = y - 28

    -- 너비
    local wLbl = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    wLbl:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, y)
    wLbl:SetText("너비")
    wLbl:SetTextColor(0.8, 0.8, 0.8)

    local wBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    wBox:SetSize(46, 20)
    wBox:SetPoint("TOPLEFT", panel, "TOPLEFT", 46, y + 2)
    wBox:SetMaxLetters(4)
    wBox:SetAutoFocus(false)
    wBox:SetText(tostring(CP.db.width))

    local wPxLbl = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    wPxLbl:SetPoint("LEFT", wBox, "RIGHT", 3, 0)
    wPxLbl:SetText("px")
    wPxLbl:SetTextColor(0.6, 0.6, 0.6)

    -- 높이
    local hLbl = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hLbl:SetPoint("TOPLEFT", panel, "TOPLEFT", 114, y)
    hLbl:SetText("높이")
    hLbl:SetTextColor(0.8, 0.8, 0.8)

    local hBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    hBox:SetSize(46, 20)
    hBox:SetPoint("TOPLEFT", panel, "TOPLEFT", 144, y + 2)
    hBox:SetMaxLetters(3)
    hBox:SetAutoFocus(false)
    hBox:SetText(tostring(CP.db.height))

    local hPxLbl = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hPxLbl:SetPoint("LEFT", hBox, "RIGHT", 3, 0)
    hPxLbl:SetText("px")
    hPxLbl:SetTextColor(0.6, 0.6, 0.6)

    -- 적용 버튼
    local function ApplySize()
        if InCombatLockdown() then
            print("|cffff9900jjali's Party Frame:|r 전투 중에는 크기를 변경할 수 없습니다.")
            return
        end
        local w = tonumber(wBox:GetText())
        local h = tonumber(hBox:GetText())
        if not w or not h or w < 80 or w > 500 or h < 20 or h > 200 then
            print("|cffff9900jjali's Party Frame:|r 유효하지 않은 값입니다. (너비 80~500, 높이 20~200)")
            return
        end
        CP.db.width  = w
        CP.db.height = h
        CP:SaveDB()
        CP:ApplyFrameSize()
    end

    local applyBtn = MakeButton(panel, 56, 22, "적용", ApplySize)
    applyBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", 208, y)

    wBox:SetScript("OnEnterPressed", ApplySize)
    hBox:SetScript("OnEnterPressed", ApplySize)
    y = y - 30

    local sizeHint = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sizeHint:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, y)
    sizeHint:SetText("비전투 상태에서만 적용됩니다. (너비 80~500, 높이 20~200)")
    sizeHint:SetTextColor(0.5, 0.5, 0.5)

    self.wBox = wBox
    self.hBox = hBox
    self.panel = panel
end

-- ─── 상태 반영 ────────────────────────────────────────────────────────────────
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

-- 스펠 슬롯 UI 갱신 (아이콘 + 이름)
function OPT:RefreshSpellSlots()
    if not self.spellSlots then return end
    for key, slot in pairs(self.spellSlots) do
        local spellName = CP.db.spells[key]
        slot.name:SetText(spellName or "없음")
        local icon = CP.SpellPicker:GetIconForSpell(spellName or "")
        slot.icon:SetTexture(icon)
    end
end

function OPT:RefreshSizeInputs()
    if self.wBox then self.wBox:SetText(tostring(CP.db.width))  end
    if self.hBox then self.hBox:SetText(tostring(CP.db.height)) end
end

-- ─── 열기/닫기 ────────────────────────────────────────────────────────────────
function OPT:Toggle()
    if not self.panel then self:Build() end

    if self.panel:IsShown() then
        self.panel:Hide()
    else
        self:RefreshLayoutButtons()
        self:RefreshLockButtons()
        self:RefreshSpellSlots()
        self:RefreshSizeInputs()
        self.panel:Show()
    end
end
