-- jjaliPartyFrame/Frames.lua
-- 컨테이너 + 유닛 프레임 생성 및 업데이트

local CP = jjaliPartyFrame

local ROLE_COORDS = {
    TANK    = { 0,   0.5, 0,   0.5 },
    HEALER  = { 0.5, 1.0, 0,   0.5 },
    DAMAGER = { 0,   0.5, 0.5, 1.0 },
}

local HANDLE_H = 16  -- 드래그 핸들 높이

-- ─── 컨테이너 크기 계산 ───────────────────────────────────────────────────────
local function ContainerSize()
    local db   = CP.db
    local n    = #CP.units
    local aura = db.auraSize + 6
    local fh   = db.height + aura  -- 버프/디버프 포함 유닛 프레임 총 높이

    if db.layout == "horizontal" then
        local w = n * db.width + (n - 1) * db.padding
        return w, HANDLE_H + fh
    else
        local h = HANDLE_H + n * fh + (n - 1) * db.padding
        return db.width, h
    end
end

-- ─── 컨테이너 생성 ────────────────────────────────────────────────────────────
local function CreateContainer()
    local w, h = ContainerSize()
    local c = CreateFrame("Frame", "jjaliPartyFrameContainer", UIParent)
    c:SetSize(w, h)
    c:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 20, -200)
    c:SetFrameStrata("MEDIUM")
    c:SetMovable(true)
    c:SetClampedToScreen(true)

    -- 컨테이너 배경 (투명 — 핸들만 보임)
    c:EnableMouse(false)

    -- ── 드래그 핸들 ──
    local handle = CreateFrame("Frame", nil, c)
    handle:SetPoint("TOPLEFT",  c, "TOPLEFT",  0,  0)
    handle:SetPoint("TOPRIGHT", c, "TOPRIGHT", 0,  0)
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

    -- 드래그 동작
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

-- ─── 유닛 프레임 생성 ─────────────────────────────────────────────────────────
local function CreateUnitFrame(unit)
    local db = CP.db
    local c  = CP.container

    local f = CreateFrame("Button", "jjaliPartyUnitFrame_" .. unit,
                          c, "SecureActionButtonTemplate")
    f:SetSize(db.width, db.height)
    f:SetFrameStrata("MEDIUM")
    f:RegisterForClicks("AnyUp")

    -- 클릭 힐
    f:SetAttribute("unit",    unit)
    f:SetAttribute("*type1",  "spell")
    f:SetAttribute("*spell1", db.spells.left)
    f:SetAttribute("*type2",  "spell")
    f:SetAttribute("*spell2", db.spells.right)
    f:SetAttribute("*type3",  "spell")
    f:SetAttribute("*spell3", db.spells.middle)

    -- 배경
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.05, 0.05, 0.05, 0.88)

    -- 테두리
    local border = f:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT",     f, "TOPLEFT",     -1,  1)
    border:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT",  1, -1)
    border:SetColorTexture(0.12, 0.12, 0.12, 1)
    border:SetDrawLayer("BORDER", -1)

    -- HP 바
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

    -- 역할 아이콘
    local roleIcon = f:CreateTexture(nil, "OVERLAY")
    roleIcon:SetSize(14, 14)
    roleIcon:SetPoint("TOPRIGHT", hpBar, "TOPRIGHT", -2, -3)
    roleIcon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-ROLES")
    roleIcon:Hide()
    f.roleIcon = roleIcon

    -- MP/파워 바
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

    -- 사망/오프라인 오버레이
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

    -- 버프/디버프 영역
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

-- ─── 레이아웃: 유닛 프레임 위치 정렬 ─────────────────────────────────────────
function CP:LayoutFrames()
    local db   = self.db
    local aura = db.auraSize + 6
    local fh   = db.height + aura  -- 버프/디버프 포함 유닛 높이

    -- 컨테이너 크기 재조정
    local cw, ch = ContainerSize()
    self.container:SetSize(cw, ch)

    for i, unit in ipairs(self.units) do
        local f = self.frames[unit]
        if not f then goto continue end

        f:SetSize(db.width, db.height)
        f:ClearAllPoints()

        if db.layout == "horizontal" then
            -- 가로: 핸들 아래, 좌→우 정렬
            local xOff = (i - 1) * (db.width + db.padding)
            f:SetPoint("TOPLEFT", self.container, "TOPLEFT", xOff, -HANDLE_H)
        else
            -- 세로: 핸들 아래, 위→아래 정렬
            local yOff = -HANDLE_H - (i - 1) * (fh + db.padding)
            f:SetPoint("TOPLEFT", self.container, "TOPLEFT", 0, yOff)
        end

        -- 핸들 너비를 컨테이너에 맞게
        self.container.handle:SetPoint("TOPRIGHT", self.container, "TOPRIGHT", 0, 0)

        ::continue::
    end
end

-- ─── 유닛 프레임 업데이트 ─────────────────────────────────────────────────────
function CP:UpdateFrame(f)
    local unit = f.unit
    if not UnitExists(unit) then
        f:Hide()
        return
    end
    f:Show()

    local isDead    = UnitIsDeadOrGhost(unit)
    local isOffline = not UnitIsConnected(unit)

    -- HP
    f.hpBar:SetMinMaxValues(0, UnitHealthMax(unit))
    f.hpBar:SetValue(UnitHealth(unit))
    local hpPct = (UnitHealthPercent(unit) or 100) / 100
    f.hpBar:SetStatusBarColor(self:HPColor(hpPct))

    -- 이름
    local name = UnitName(unit) or unit
    if #name > 13 then name = name:sub(1, 12) .. "…" end
    f.nameText:SetText(name)

    -- HP 수치
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

    -- 사망/오프라인 오버레이
    if isDead or isOffline then
        f.deadOverlay:Show()
        f.deadText:SetText(isDead and "사 망" or "오프라인")
        f.deadText:SetTextColor(isDead and 0.9 or 0.5, isDead and 0.2 or 0.5, isDead and 0.2 or 0.5)
        f.deadText:Show()
    else
        f.deadOverlay:Hide()
        f.deadText:Hide()
    end

    -- MP/파워
    local powerTypeId = UnitPowerType(unit)
    f.mpBar:SetMinMaxValues(0, UnitPowerMax(unit, powerTypeId))
    f.mpBar:SetValue(UnitPower(unit, powerTypeId))
    local _, powerToken = UnitPowerType(unit)
    f.mpBar:SetStatusBarColor(self:PowerColor(powerToken))

    -- 역할 아이콘
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

-- ─── 초기화 ───────────────────────────────────────────────────────────────────
function CP:InitFrames()
    if PartyFrame and not InCombatLockdown() then
        PartyFrame:Hide()
        PartyFrame:UnregisterAllEvents()
    end

    -- 컨테이너 생성
    if not self.container then
        self.container = CreateContainer()
    end

    -- 유닛 프레임 생성
    for _, unit in ipairs(self.units) do
        if not self.frames[unit] then
            self.frames[unit] = CreateUnitFrame(unit)
        end
    end

    -- 레이아웃 적용
    self:LayoutFrames()

    -- 저장된 위치 복원
    if not self:LoadContainerPos() then
        self.container:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 20, -200)
    end

    -- 잠금 상태 적용
    self:SetLocked(self.locked)

    self:UpdateAll()
end
