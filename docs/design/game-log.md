# 게임 로그 — 후속 설계

**v1 현황(구조):** [`docs/architecture/game-log.md`](../architecture/game-log.md)  
이 문서는 **미구현** 로드맵만 다룬다.

관련: [`combat.md`](combat.md) (세션 이벤트) · [`hud.md`](hud.md) (GameHud 패널) · [`loot.md`](loot.md) (토스트 ≠ 로그) · [`village.md`](village.md) (허브에서도 HUD 유지) · [`settings.md`](settings.md) (상세도 v1.1).

---

## 한 줄

방 안에서 **지금 무슨 일이 일어났는지** 텍스트로 다시 읽는다. 숫자는 머리 위에 잠깐 뜨고, 로그는 문장으로 남는다.

---

## 확정 결정

| # | 결정 |
|---|------|
| 1 | 이름은 **게임 로그**. 채팅·킬피드·전투 전용 파서가 아니다. 카테고리는 데이터로만 둔다. |
| 2 | **인게임 HUD**에 상시 표시. 메뉴가 열리면 GameHud와 같이 숨긴다. 전투 중에도 유지. |
| 3 | 플로팅 데미지·전리품 토스트와 **병행**. 로그가 그것들을 대체하지 않는다. |
| 4 | 생산자는 **구조화 이벤트**만 보낸다. 문장·색·`tr()`은 로그 쪽. |
| 5 | `unit_hit`는 플로트용으로 유지. 로그는 더 풍부한 `action_resolved` (또는 동등)를 구독. |
| 6 | **Autoload 없음.** `UIManager`가 버퍼를 소유. `CombatSession`은 로그를 모른다. |
| 7 | 세이브에 넣지 않는다. 던전 퇴장·마을 귀환 시 비운다. |
| 8 | 리젠·스태미나 틱은 남기지 않는다. 이산 행동만 (타격·회피·스킬·처치·승패). |
| 9 | 방 입장마다 한 줄은 없다. 전투 시작이 곧 조우 기록. |
| 10 | 중앙·좌하 액션바·우상 미니맵을 가리지 않는다. **우하**, 배속/후퇴 **위**. |

---

## 로드맵

| 단계 | 범위 | 상태 |
|------|------|------|
| **v1** | 우하 패널, 전투 이산 행동 + 승패, 링 버퍼, `tr` 한 줄 | 구현됨 → [`architecture/game-log.md`](../architecture/game-log.md) |
| **loot 연동** | `grant` / 가득 스킵을 같은 버퍼에 | 구현됨 — [`loot.md`](loot.md) |
| **v1.1** | 상세도 설정, 호버 시 스크롤 정지, 페이드 | 설계만 — [`settings.md`](settings.md) |
| **v2** | 줄 클릭 → 유닛 패널, 전투 종료 요약 | 설계만 — combat v2c |

---

## v1 — 우하 스크롤

### 역할 분담

| 채널 | 역할 | 수명 |
|------|------|------|
| 플로팅 | 피격 순간 숫자 | 1~2초. 회피(`amount` 0)는 생략 |
| 토스트 | 방 `win` 획득 알림 | 몇 초. 인벤 비오픈 ([`loot.md`](loot.md)) |
| **로그** | 다시 읽기 | 최근 N줄. 원정이 끝나면 폐기 |

회피·크리·흡혈·반격·Tired·스킬 자동 발동은 플로트만으로 구분되지 않는다. 로그가 그 공백을 메운다.

### 화면

GameHud `layer = 0`. CombatHud 배속/후퇴는 `layer = 1` 우하 (`offset_top = -72`).

```
우하
├── GameLogView     # 배속 버튼 위. 가로 ~280, 최근 8~12줄
└── CombatHud       # 배속 · 후퇴 (현행)
```

- 최신이 **아래**. 위는 히스토리.
- Root는 `mouse ignore` 유지. 패널만 스크롤 시 마우스 수신.
- 미니맵·액션바·자원 바와 겹치지 않음. HUD 비목표(중앙 프롬프트)와 같음.
- 마을 허브: 미니맵은 숨겨도 로그 패널은 둔다. v1 마을 이벤트는 거의 없음.

수치(높이·폰트)는 구현 직전. 배속 버튼을 가리면 안 된다.

### 버퍼

링 버퍼 **200줄**. 넘치면 가장 오래된 줄 삭제.

| 시점 | 동작 |
|------|------|
| 전투 시작 | **구분선** (비우지 않음 — 이전 방 전리품을 남김) |
| `win` / `lose` / `retreat` | 결과 한 줄. 버퍼 유지 |
| `return_to_village` / 타이틀 | `clear` |
| 에디터 단독 던전 재시작 | `clear` |

세이브·런 JSON에 로그 필드 없음 ([`save-load.md`](save-load.md)).

### 이벤트 (v1)

틱이 아닌 **이산 행동**만.

| kind | 한 줄 (초안) | 비고 |
|------|----------------|------|
| `combat.start` | `— {encounter} —` | 구분선 + 인카운터 표시명 |
| `hit` | `{actor} → {target}  {n}` | 평타. `crit`면 접미 |
| `hit` + skill | `{actor} [{skill}] → {target}  {n}` | 자동 발동과 평타를 한 줄로 |
| `evade` | `{target} 회피` | 플로트 생략과 맞춤 |
| `heal` (vamp) | 같은 타격 줄에 `+{n}` | 별줄 아님 |
| `retaliation` / `counter` | `{actor} → {target}  {n}` + 접미 | 타격과 주체가 다르므로 **별줄** |
| `damage_all` | 대상마다 한 줄 | 회피면 `evade` |
| `death` | `{name} 처치` | |
| `tired` | `{name} 탈진` | **진입 시 한 번**. 틱 없음 |
| `combat.end` | 승리 / 패배 / 후퇴 | `result` |
| `loot.grant` | 토스트와 **같은 키** | loot v1과 같이 |
| `loot.skip` | `LOOT_INVENTORY_FULL` | |

남기지 않음: `regen_per_sec`, 스태미나 소모/재생, Magic HP를 HP와 쪼갠 표기, 방 이동, 메뉴 개폐.

흡혈은 접미로 붙여 줄 수를 줄인다. 반격·카운터는 누가 때렸는지가 바뀌므로 새 줄.

### 페이로드

생산자는 번역 키를 모른다.

```
{
  category: "combat" | "loot" | "system",
  kind: String,
  actor_id: String,
  actor_name: String,     # 이미 tr된 표시명 가능
  target_id: String,
  target_name: String,
  amount: int,
  flags: PackedStringArray,  # crit, skill, counter, retaliation, vampirism, damage_all
  skill_name: String,
  result: String             # win / lose / retreat
}
```

포맷터가 `kind` + `flags` → `tr` 키. 키 초안(구현 직전 [`locale/ui_strings.csv`](../../locale/ui_strings.csv)):

`LOG_HIT` / `LOG_HIT_CRIT` / `LOG_SKILL` / `LOG_EVADE` / `LOG_DEATH` / `LOG_TIRED` / `LOG_WIN` / `LOG_LOSE` / `LOG_RETREAT` / `LOG_COMBAT_START` / `LOG_COUNTER` / `LOG_RETALIATION`

전리품은 `LOOT_GOT` / `LOOT_INVENTORY_FULL` 재사용 ([`loot.md`](loot.md)).

색(초안): 피해 밝은 빨강, 크리 금, 회피 회색, 회복 녹, 시스템 Muted, 처치/승패 강조. 테마 토큰은 구현 직전.

### 세션 훅

```
CombatSession.signal unit_hit(unit_id, amount)           # 유지 — 플로트
CombatSession.signal action_resolved(payload: Dictionary) # 신규 — 로그
EncounterDirector.combat_started / combat_finished        # start/end 줄
```

히트 순서([`architecture/combat.md`](../architecture/combat.md))와 같은 지점에서 emit:

1. 회피 성공 → `evade` (`unit_hit(..., 0)`과 함께)
2. 본타 → `hit` (+ `crit` / `skill` 플래그)
3. `damage_all` → 대상별 `hit` 또는 `evade`
4. 흡혈 → 직전 `hit`에 `vampirism` + amount (별 emit 없음이 이상적)
5. 반격·카운터 → 별 `hit` + 플래그
6. HP 0 → `death`
7. 스태미나 0으로 Tired 진입 → `tired`

세션이 문자열을 조립하지 않는다. 아레나는 `action_resolved`를 구독하지 않는다.

### 위치 (예정)

| 역할 | 경로 |
|------|------|
| 엔트리 | `data/log/game_log_entry.gd` (`class_name`, Resource 또는 얇은 RefCounted) |
| 버퍼 | `data/log/game_log.gd` (`push` / `clear` / `entries`) |
| 포맷 | 같은 폴더 또는 뷰 내부. `tr` + 색 |
| 뷰 | `ui/hud/components/game_log_view.*` — GameHud 자식 |
| 소유 | [`ui_manager.gd`](../../ui/ui_manager.gd) |
| 훅 | [`combat_session.gd`](../../world/combat/combat_session.gd) `action_resolved` · [`encounter_director.gd`](../../world/combat/encounter_director.gd) start/end · loot `grant` 시 |

```
CombatSession / EncounterDirector / LootService
        │  payload
        ▼
UIManager.game_log.push(entry)
        │  signal entry_added
        ▼
GameLogView   (GameHud, 우하)
```

```
GameHud (CanvasLayer)
└── Root
    ├── ResourceBars
    ├── TopRight (WorldInfo, MiniMap)
    ├── ActionBar
    └── GameLogView          # 신규, 우하
```

### API (예정)

```
UIManager.push_log(payload)          # 또는 game_log.push
UIManager.clear_log()
GameLog.push(entry)
GameLog.clear()
signal GameLog.entry_added(entry)
signal GameLog.cleared
CombatSession.signal action_resolved(payload)
UIManager.show_loot_toast(result)    # 유지. 토스트 + push_log 둘 다
```

`RichTextLabel`(bbcode) 또는 줄 라벨 스택. 200줄이면 가상 스크롤은 v1 불필요. 줄이 늘어나면 v1.1.

---

## loot 연동

토스트는 “방금 획득”용, 로그는 “이 방에서 뭘 먹었지”용. `LootService.grant` 결과를 **한 곳에서** 둘 다 호출한다.

- 넣음: 이름마다 한 줄 또는 나열 한 줄 — 구현 직전. 토스트와 문구를 맞춘다.
- 스킵: 가득 문구. 이미 넣은 줄은 유지.
- 보스 `win` 후 씬 전환: 토스트는 생략돼도 됨 ([`loot.md`](loot.md)). 로그는 마을에서 `clear`되므로 **보스 전리품은 토스트/인벤이 진실**. 로그에만 의존하지 않음.

loot v1이 없으면 로그 v1은 전투만.

---

## v1.1 — 읽기 품질

설정 게임 플레이 탭 ([`settings.md`](settings.md) v2 자리). cfg `user://settings.cfg`.

| 키 (초안) | 기본 | 의미 |
|-----------|------|------|
| `log.verbosity` | `actions` | `notable` = 스킬·회피·크리·처치·승패만 / `actions` = v1 전체 타격 |
| `log.fade` | false | 몇 초 무이벤트면 투명, 호버·새 줄이면 복귀 |
| `log.pause_on_hover` | true | 호버 중 뷰포트 스크롤 고정. 버퍼는 계속 `push` |

타임스탬프는 시계 HUD가 없으므로 기본 끔. 전투 상대 시각이 필요하면 구현 직전.

필터 탭(전투/전리품)은 채널이 늘기 전엔 넣지 않는다.

---

## v2 — 조회

- 줄의 유닛 id 클릭 → combat v2c 하단 스탯 패널 포커스. 탐험 중이면 무시.
- 전투 종료 한 줄 요약: 준 피해 / 받은 피해 / 처치 수. 세션이 누적하고 디렉터가 `push`.
- 클립보드 복사는 DevOverlay만. 플레이어 설정 아님.

---

## 검증

- 일반 방 전투 중 우하에 타격·회피·승패가 보이는가. 배속/후퇴를 가리지 않는가.
- 회피 시 플로트는 없고 로그에 `회피`가 있는가.
- 크리·스킬·반격이 평타와 구분되는가. 리젠 틱이 없는가.
- 메뉴를 열면 로그가 숨고, 닫으면 버퍼가 그대로인가 (전투 일시정지와 맞춤).
- 다음 방 전투 시작에 구분선이 있고, 이전 방 `win` 줄이 남는가.
- 마을 귀환 후 로그가 비는가. 세이브 JSON에 로그 키가 없는가.
- 언어 전환 시 **이후 줄**이 `tr`되는가. 이미 그린 줄은 다시 포맷하거나, 표시 시점에 `tr` (구현 직전 택1).
- loot v1 이후: 토스트와 로그가 같은 획득을 말하는가. 인벤이 자동으로 열리지 않는가.

---

## 관련 문서에 미치는 결정

| 문서 | 점 |
|------|----|
| [`hud.md`](hud.md) | 우하 `GameLogView`. 중앙 없음 유지. 메뉴 시 숨김 |
| [`combat.md`](combat.md) | `action_resolved`. `unit_hit` 유지. 세션은 로그 타입 모름 |
| [`loot.md`](loot.md) | `grant`가 토스트와 `push_log`를 같이. 로그가 토스트를 대체하지 않음 |
| [`village.md`](village.md) | 귀환 시 `clear`. v1 제단/게시판 문구는 로그 필수 아님 |
| [`settings.md`](settings.md) | 상세도·페이드는 v1.1. v1 설정 행 없음 |
| [`save-load.md`](save-load.md) | 로그 비영속. 런 JSON에도 없음 |
| [`architecture/hud.md`](../architecture/hud.md) | 구현 시 씬 트리·바인딩에 `GameLogView` |

---

## 비목표 (당분간)

- 채팅, 파티/귓속말, 시스템 채널 탭
- WoW식 파싱 원문·초당 리젠 줄
- 킬피드 전용 UI, 화면 중앙 자막
- 로그 세이브·원정 리플레이
- 줄 클릭 유닛 선택 (v2)
- 설정 상세도 (v1.1)
- DevOverlay에 로그 덤프를 기본 기능으로
- 방 입장·맵 이동·메뉴 개폐를 한 줄로
- CombatHud로 로그를 옮기기 (전투가 끝나면 패널이 사라짐)
