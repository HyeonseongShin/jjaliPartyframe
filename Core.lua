-- jjaliPartyFrame/Core.lua
-- 애드온 전역 테이블 및 설정

jjaliPartyFrame = {}
local CP = jjaliPartyFrame

-- ─── 기본 설정 ────────────────────────────────────────────────────────────────
CP.db = {
    width    = 200,
    height   = 52,
    padding  = 4,
    layout   = "vertical",  -- "vertical" | "horizontal"

    -- 한국어 클라이언트 기준 스펠명 사용 (영문 클라이언트는 옵션 패널에서 변경)
    spells = {
        left   = "재성장",       -- Regrowth
        right  = "재생",         -- Rejuvenation
        middle = "치유의 손길",  -- Healing Touch
    },

    maxBuffs   = 6,
    maxDebuffs = 3,
    auraSize   = 16,
}

-- ─── 색상 정의 ────────────────────────────────────────────────────────────────
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

-- ─── 상태 ─────────────────────────────────────────────────────────────────────
CP.units     = { "player", "party1", "party2", "party3", "party4" }
CP.frames    = {}
CP.container = nil
CP.locked    = false

-- ─── 헬퍼 ────────────────────────────────────────────────────────────────────
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

-- ─── SavedVariables ───────────────────────────────────────────────────────────
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

-- ─── 잠금 ─────────────────────────────────────────────────────────────────────
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
    -- 옵션 패널 버튼 상태 갱신
    if CP.Options and CP.Options.RefreshLockButtons then
        CP.Options:RefreshLockButtons()
    end
end

-- ─── 레이아웃 변경 ───────────────────────────────────────────────────────────
function CP:SetLayout(layout)
    self.db.layout = layout
    jjaliPartyFrameDB.layout = layout
    self:LayoutFrames()
    if CP.Options and CP.Options.RefreshLayoutButtons then
        CP.Options:RefreshLayoutButtons()
    end
end

-- ─── 이벤트 ──────────────────────────────────────────────────────────────────
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

-- ─── 슬래시 커맨드 ───────────────────────────────────────────────────────────
SLASH_JJALIPARTYFRAME1 = "/jjali"
SLASH_JJALIPARTYFRAME2 = "/jpf"
SlashCmdList["JJALIPARTYFRAME"] = function(msg)
    if msg == "" or msg == nil then
        -- 옵션 패널 열기
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
