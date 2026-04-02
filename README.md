# jjali's Party Frame

World of Warcraft **Midnight (12.0.1)** 호환 커스텀 파티 프레임 애드온.
기본 파티 프레임의 불편함을 해소하기 위해 제작되었습니다.

## 기능

- **HP 바** — 체력 % 에 따라 초록 → 노랑 → 빨강으로 색상 변화
- **MP/파워 바** — 클래스별 파워 타입 색상 자동 적용 (마나, 분노, 에너지 등)
- **역할 아이콘** — 탱커 / 힐러 / 딜러 역할 자동 표시
- **버프/디버프 아이콘** — 버프 최대 8개, 디버프 최대 4개 표시 (종류별 테두리 색상)
- **클릭 힐** — 프레임 클릭으로 스펠 즉시 시전 (전투 중 가능)
- **드래그 이동** — 비전투 중 프레임 자유 이동

## 호환성

| 항목 | 내용 |
|------|------|
| WoW 버전 | Midnight Retail (Interface 120001) |
| API | Blizzard Secret Value 시스템 대응 완료 |

Midnight 확장팩부터 도입된 **Secret Value** 제한(전투 중 HP/파워 수치 산술 연산 불가)에 대응하여
`UnitHealthPercent()` 등 Midnight 신규 API를 사용합니다.

## 설치

```
World of Warcraft/_retail_/Interface/AddOns/jjaliPartyFrame/
```

위 경로에 `jjaliPartyFrame` 폴더를 복사한 뒤 게임을 재시작하거나 애드온을 리로드하세요.

## 클릭 힐 스펠 설정

`Core.lua` 상단의 `spells` 항목을 본인 클래스에 맞게 수정하세요:

```lua
spells = {
    left   = "Flash Heal",          -- 왼쪽 클릭
    right  = "Renew",               -- 오른쪽 클릭
    middle = "Power Word: Shield",  -- 미들 클릭
},
```

## 슬래시 커맨드

| 커맨드 | 설명 |
|--------|------|
| `/jjali reset` | 프레임 위치 초기화 |
| `/jjali reload` | 프레임 새로고침 |
| `/jpf reset` | 동일 (단축 커맨드) |
| `/jpf reload` | 동일 (단축 커맨드) |

## 파일 구조

```
jjaliPartyFrame/
├── jjaliPartyFrame.toc   # 애드온 메타데이터
├── Core.lua              # 설정, 색상, 이벤트 핸들러
├── Frames.lua            # 프레임 생성/업데이트, 클릭 힐
└── Buffs.lua             # 버프/디버프 아이콘
```
