-- jjaliPartyFrame/Buffs.lua
-- 버프/디버프 아이콘 표시

local CP = jjaliPartyFrame

-- ─── 아이콘 프레임 생성/재사용 ────────────────────────────────────────────────
local function GetIcon(parent, list, index, isDebuff)
    if list[index] then return list[index] end

    local size = CP.db.auraSize
    local icon = CreateFrame("Frame", nil, parent)
    icon:SetSize(size, size)

    -- 아이콘 텍스처
    local tex = icon:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)  -- 아이콘 기본 테두리 제거
    icon.tex = tex

    -- 중첩 수 텍스트
    local ct = icon:CreateFontString(nil, "OVERLAY")
    ct:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1)
    ct:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
    ct:SetTextColor(1, 1, 1)
    icon.count = ct

    -- 디버프 테두리 (디버프 종류에 따라 색 변경)
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

-- ─── 버프/디버프 업데이트 ─────────────────────────────────────────────────────
function CP:UpdateAuras(f)
    local unit   = f.unit
    local db     = self.db
    local size   = db.auraSize

    -- ── 버프 ──
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
    -- 남은 버프 아이콘 숨기기
    for j = buffCount + 1, #f.buffIcons do
        f.buffIcons[j]:Hide()
    end

    -- ── 디버프 (버프 오른쪽에 표시, 약간 간격) ──
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

            -- 디버프 종류별 테두리 색상
            if icon.border then
                local dc = self.colors.debuff[data.dispelName]
                         or self.colors.debuff.default
                icon.border:SetColorTexture(unpack(dc))
            end

            icon:Show()
        end
    end
    -- 남은 디버프 아이콘 숨기기
    for j = debuffCount + 1, #f.debuffIcons do
        f.debuffIcons[j]:Hide()
    end
end
