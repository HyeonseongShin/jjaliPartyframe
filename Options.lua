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

-- ─── 헬퍼: EditBox ───────────────────────────────────────────────────────────
local function MakeEditBox(parent, w, text)
    local eb = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    eb:SetSize(w, 22)
    eb:SetAutoFocus(false)
    eb:SetMaxLetters(50)
    eb:SetText(text or "")
    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    return eb
end

-- ─── 패널 생성 ────────────────────────────────────────────────────────────────
function OPT:Build()
    local panel = CreateFrame("Frame", "jjaliPartyFrameOptions", UIParent,
                              "BackdropTemplate")
    panel:SetSize(320, 420)
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

    local btnUnlock = MakeButton(panel, 88, 26, "🔓 잠금 해제", function()
        CP:SetLocked(false)
    end)
    btnUnlock:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, y)

    local btnLock = MakeButton(panel, 88, 26, "🔒 잠금", function()
        CP:SetLocked(true)
    end)
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

    -- ════════════════════════════════
    -- 섹션: 클릭 힐 스펠
    -- ════════════════════════════════
    MakeDivider(panel, y); y = y - 14
    local spellLabel = MakeLabel(panel, "클릭 힐 스펠", 11)
    spellLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, y)
    y = y - 22

    local spellDefs = {
        { key = "left",   label = "왼쪽 클릭" },
        { key = "right",  label = "오른쪽 클릭" },
        { key = "middle", label = "미들 클릭" },
    }
    self.spellBoxes = {}

    for _, def in ipairs(spellDefs) do
        local lbl = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, y)
        lbl:SetText(def.label)
        lbl:SetTextColor(0.8, 0.8, 0.8)

        local eb = MakeEditBox(panel, 170, CP.db.spells[def.key])
        eb:SetPoint("TOPLEFT", panel, "TOPLEFT", 110, y + 3)

        local applyKey = def.key
        eb:SetScript("OnEnterPressed", function(self)
            self:ClearFocus()
            CP.db.spells[applyKey] = self:GetText()
            CP:SaveDB()
            -- 모든 프레임에 어트리뷰트 즉시 반영 (비전투 중만 가능)
            if not InCombatLockdown() then
                for _, f in pairs(CP.frames) do
                    if applyKey == "left"   then f:SetAttribute("*spell1", self:GetText()) end
                    if applyKey == "right"  then f:SetAttribute("*spell2", self:GetText()) end
                    if applyKey == "middle" then f:SetAttribute("*spell3", self:GetText()) end
                end
            end
        end)

        self.spellBoxes[def.key] = eb
        y = y - 28
    end

    local spellHint = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    spellHint:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, y)
    spellHint:SetText("Enter를 눌러 적용합니다.")
    spellHint:SetTextColor(0.5, 0.5, 0.5)
    y = y - 30

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

function OPT:RefreshSpellBoxes()
    if not self.spellBoxes then return end
    for key, eb in pairs(self.spellBoxes) do
        eb:SetText(CP.db.spells[key] or "")
    end
end

-- ─── 열기/닫기 ────────────────────────────────────────────────────────────────
function OPT:Toggle()
    if not self.panel then self:Build() end

    if self.panel:IsShown() then
        self.panel:Hide()
    else
        self:RefreshLayoutButtons()
        self:RefreshLockButtons()
        self:RefreshSpellBoxes()
        self.panel:Show()
    end
end
