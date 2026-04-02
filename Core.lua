-- jjaliPartyFrame/Core.lua
-- 애드온 전역 테이블 및 설정

jjaliPartyFrame = {}
local CP = jjaliPartyFrame

-- ─── 설정 ───────────────────────────────────────────────────────────────────
CP.db = {
    width    = 200,
    height   = 62,
    padding  = 5,     -- 프레임 간 간격
    anchorX  = -220,  -- UIParent 기준 X 오프셋
    anchorY  = -200,  -- UIParent 기준 Y 오프셋

    -- 클릭 힐 스펠 (본인 클래스에 맞게 수정)
    spells = {
        left   = "Flash Heal",          -- 왼쪽 클릭
        right  = "Renew",               -- 오른쪽 클릭
        middle = "Power Word: Shield",  -- 미들 클릭
    },

    -- 버프/디버프 아이콘 설정
    maxBuffs   = 8,
    maxDebuffs = 4,
    auraSize   = 16,
}

-- ─── 색상 정의 ───────────────────────────────────────────────────────────────
CP.colors = {
    hp = {
        high = { 0.2, 0.8, 0.3 },   -- 60% 이상
        mid  = { 0.9, 0.8, 0.1 },   -- 30~60%
        low  = { 0.9, 0.2, 0.2 },   -- 30% 미만
    },
    power = {
        MANA        = { 0.2, 0.4, 0.9 },
        RAGE        = { 0.8, 0.1, 0.1 },
        FOCUS       = { 0.8, 0.6, 0.1 },
        ENERGY      = { 0.9, 0.9, 0.1 },
        RUNIC_POWER = { 0.0, 0.8, 1.0 },
        FURY        = { 0.7, 0.1, 0.9 },
        PAIN        = { 1.0, 0.6, 0.0 },
        MAELSTROM   = { 0.0, 0.6, 1.0 },
        INSANITY    = { 0.4, 0.0, 0.8 },
        SOUL_SHARDS = { 0.5, 0.1, 0.6 },
        ASTRAL      = { 0.3, 0.8, 0.5 },
        ARCANE_CHARGES = { 0.2, 0.6, 1.0 },
        COMBO_POINTS = { 1.0, 0.8, 0.1 },
    },
    debuff = {
        Magic   = { 0.2, 0.6, 1.0 },
        Curse   = { 0.6, 0.0, 1.0 },
        Disease = { 0.6, 0.4, 0.0 },
        Poison  = { 0.0, 0.6, 0.0 },
        default = { 0.8, 0.0, 0.0 },
    },
}

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
    return 0.2, 0.4, 0.9  -- 기본: 파란색
end

-- ─── 유닛 목록 ───────────────────────────────────────────────────────────────
CP.units  = { "player", "party1", "party2", "party3", "party4" }
CP.frames = {}  -- unit -> frame

-- ─── 이벤트 핸들러 ───────────────────────────────────────────────────────────
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
        CP:InitFrames()

    elseif event == "GROUP_ROSTER_UPDATE"
        or event == "PLAYER_ROLES_ASSIGNED"
        or event == "ROLE_CHANGED_INFORM" then
        CP:UpdateAll()

    elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH"
        or event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER"
        or event == "UNIT_CONNECTION" or event == "UNIT_FLAGS" then
        local f = CP.frames[arg1]
        if f then CP:UpdateFrame(f) end

    elseif event == "UNIT_AURA" then
        local f = CP.frames[arg1]
        if f then CP:UpdateAuras(f) end
    end
end)

-- ─── 슬래시 커맨드 ───────────────────────────────────────────────────────────
SLASH_JJALIPARTY1 = "/jjali"
SLASH_JJALIPARTY2 = "/jpf"
SlashCmdList["JJALIPARTY"] = function(msg)
    if msg == "reset" then
        for _, f in pairs(CP.frames) do
            f:ClearAllPoints()
        end
        CP:LayoutFrames()
        print("|cffff9900jjali's Party Frame:|r 프레임 위치를 초기화했습니다.")
    elseif msg == "reload" then
        CP:UpdateAll()
        print("|cffff9900jjali's Party Frame:|r 프레임을 새로고침했습니다.")
    else
        print("|cffff9900jjali's Party Frame 명령어:|r")
        print("  /jjali reset   - 프레임 위치 초기화")
        print("  /jjali reload  - 프레임 새로고침")
    end
end
