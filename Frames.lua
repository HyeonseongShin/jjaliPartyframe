-- jjaliPartyFrame/Frames.lua
-- 파티 프레임 생성 및 업데이트

local CP = jjaliPartyFrame

-- 역할 아이콘 텍스처 좌표 (Interface\LFGFrame\UI-LFG-ICON-ROLES)
local ROLE_COORDS = {
    TANK    = { 0,   0.5, 0,   0.5 },
    HEALER  = { 0.5, 1.0, 0,   0.5 },
    DAMAGER = { 0,   0.5, 0.5, 1.0 },
}

-- ─── 단일 유닛 프레임 생성 ────────────────────────────────────────────────────
local function CreateUnitFrame(unit)
    local db = CP.db

    -- SecureActionButtonTemplate: 전투 중 클릭 힐 가능
    local f = CreateFrame("Button", "jjaliPartyFrameFrame_" .. unit,
                          UIParent, "SecureActionButtonTemplate")
    f:SetSize(db.width, db.height)
    f:SetFrameStrata("MEDIUM")
    f:RegisterForClicks("AnyUp")

    -- 클릭 힐 어트리뷰트
    f:SetAttribute("unit",   unit)
    f:SetAttribute("*type1", "spell")
    f:SetAttribute("*spell1", db.spells.left)
    f:SetAttribute("*type2", "spell")
    f:SetAttribute("*spell2", db.spells.right)
    f:SetAttribute("*type3", "spell")
    f:SetAttribute("*spell3", db.spells.middle)

    -- 드래그로 이동 (비전투 중)
    f:SetMovable(true)
    f:SetScript("OnMouseDown", function(self, btn)
        if btn == "LeftButton" and not InCombatLockdown() then
            self:StartMoving()
        end
    end)
    f:SetScript("OnMouseUp", function(self)
        self:StopMovingOrSizing()
    end)

    -- ── 배경 ──
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.05, 0.05, 0.05, 0.88)

    -- ── 테두리 ──
    local border = f:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT",     f, "TOPLEFT",     -1,  1)
    border:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT",  1, -1)
    border:SetColorTexture(0.12, 0.12, 0.12, 1)
    border:SetDrawLayer("BORDER", -1)

    -- ── HP 바 ──
    local hpBar = CreateFrame("StatusBar", nil, f)
    hpBar:SetPoint("TOPLEFT",  f, "TOPLEFT",   2, -2)
    hpBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
    hpBar:SetHeight(24)
    hpBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    hpBar:SetStatusBarColor(0.2, 0.8, 0.3)
    hpBar:SetMinMaxValues(0, 1)
    hpBar:SetValue(1)
    f.hpBar = hpBar

    -- HP 바 배경
    local hpBg = hpBar:CreateTexture(nil, "BACKGROUND")
    hpBg:SetAllPoints()
    hpBg:SetColorTexture(0, 0, 0, 0.4)

    -- 이름 텍스트 (HP 바 위)
    local nameText = hpBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameText:SetPoint("LEFT",  hpBar, "LEFT",  4, 0)
    nameText:SetPoint("RIGHT", hpBar, "RIGHT", -22, 0)  -- 역할 아이콘 공간 확보
    nameText:SetJustifyH("LEFT")
    nameText:SetWordWrap(false)
    f.nameText = nameText

    -- HP 수치 텍스트
    local hpText = hpBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hpText:SetPoint("RIGHT", hpBar, "RIGHT", -4, 0)
    hpText:SetJustifyH("RIGHT")
    f.hpText = hpText

    -- ── 역할 아이콘 ──
    local roleIcon = f:CreateTexture(nil, "OVERLAY")
    roleIcon:SetSize(16, 16)
    roleIcon:SetPoint("TOPRIGHT", hpBar, "TOPRIGHT", -2, -4)
    roleIcon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-ROLES")
    roleIcon:Hide()
    f.roleIcon = roleIcon

    -- ── MP/파워 바 ──
    local mpBar = CreateFrame("StatusBar", nil, f)
    mpBar:SetPoint("TOPLEFT",  hpBar, "BOTTOMLEFT",  0, -2)
    mpBar:SetPoint("TOPRIGHT", hpBar, "BOTTOMRIGHT", 0, -2)
    mpBar:SetHeight(8)
    mpBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    mpBar:SetStatusBarColor(0.2, 0.4, 0.9)
    mpBar:SetMinMaxValues(0, 1)
    mpBar:SetValue(1)
    f.mpBar = mpBar

    local mpBg = mpBar:CreateTexture(nil, "BACKGROUND")
    mpBg:SetAllPoints()
    mpBg:SetColorTexture(0, 0, 0, 0.4)

    -- ── 사망/오프라인 오버레이 ──
    local deadOverlay = f:CreateTexture(nil, "OVERLAY")
    deadOverlay:SetPoint("TOPLEFT",  hpBar, "TOPLEFT")
    deadOverlay:SetPoint("BOTTOMRIGHT", mpBar, "BOTTOMRIGHT")
    deadOverlay:SetColorTexture(0, 0, 0, 0.65)
    deadOverlay:Hide()
    f.deadOverlay = deadOverlay

    local deadText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    deadText:SetPoint("CENTER", hpBar, "CENTER")
    deadText:Hide()
    f.deadText = deadText

    -- ── 버프/디버프 영역 ──
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

-- ─── 프레임 위치 정렬 ─────────────────────────────────────────────────────────
function CP:LayoutFrames()
    local db = self.db
    for i, unit in ipairs(self.units) do
        local f = self.frames[unit]
        if f then
            f:ClearAllPoints()
            f:SetPoint("TOPLEFT", UIParent, "TOPLEFT",
                       db.anchorX,
                       db.anchorY - (i - 1) * (db.height + db.padding))
        end
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
    -- SetMinMaxValues/SetValue 는 Secret Value를 직접 받을 수 있음 (WoW 엔진이 내부 처리)
    -- 산술/비교 연산이 필요한 곳은 Midnight 신규 API UnitHealthPercent() 사용 (비밀값 아님, 0~100)
    f.hpBar:SetMinMaxValues(0, UnitHealthMax(unit))
    f.hpBar:SetValue(UnitHealth(unit))
    local hpPct = (UnitHealthPercent(unit) or 100) / 100
    f.hpBar:SetStatusBarColor(self:HPColor(hpPct))

    -- 이름
    local name = UnitName(unit) or unit
    if #name > 13 then name = name:sub(1, 12) .. "…" end
    f.nameText:SetText(name)

    -- HP 수치 (Secret Value에 tostring/산술 불가 → 퍼센트로 표시)
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
        if isDead then
            f.deadText:SetText("사 망")
            f.deadText:SetTextColor(0.9, 0.2, 0.2)
        else
            f.deadText:SetText("오프라인")
            f.deadText:SetTextColor(0.5, 0.5, 0.5)
        end
        f.deadText:Show()
    else
        f.deadOverlay:Hide()
        f.deadText:Hide()
    end

    -- MP/파워 (동일하게 Secret Value를 UI에 직접 전달, 비교 연산 제거)
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

    -- 버프/디버프
    self:UpdateAuras(f)
end

-- ─── 전체 업데이트 ────────────────────────────────────────────────────────────
function CP:UpdateAll()
    for _, f in pairs(self.frames) do
        self:UpdateFrame(f)
    end
end

-- ─── 초기화 ───────────────────────────────────────────────────────────────────
function CP:InitFrames()
    -- 기본 파티 프레임 숨기기 (비전투 중에만 가능)
    if PartyFrame and not InCombatLockdown() then
        PartyFrame:Hide()
        PartyFrame:UnregisterAllEvents()
    end

    for _, unit in ipairs(self.units) do
        if not self.frames[unit] then
            self.frames[unit] = CreateUnitFrame(unit)
        end
    end

    self:LayoutFrames()
    self:UpdateAll()
end
