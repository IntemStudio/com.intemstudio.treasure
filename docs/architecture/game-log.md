# 게임 로그

인게임 HUD 우하의 스크롤 텍스트. 전투에서 일어난 이산 행동을 다시 읽는다.  
플로팅 데미지·전리품 토스트와 병행한다.

후속: [`docs/design/game-log.md`](../design/game-log.md).  
색 (bbcode 토큰): [`ui-colors.md`](ui-colors.md).

---

## 위치

| 역할 | 경로 |
|------|------|
| 엔트리 | [`data/log/game_log_entry.gd`](../../data/log/game_log_entry.gd) |
| 버퍼 | [`data/log/game_log.gd`](../../data/log/game_log.gd) |
| 포맷 | [`data/log/game_log_formatter.gd`](../../data/log/game_log_formatter.gd) |
| 뷰 | [`ui/hud/components/game_log_view.tscn`](../../ui/hud/components/game_log_view.tscn) + [`game_log_view.gd`](../../ui/hud/components/game_log_view.gd) |
| 소유 | [`ui/ui_manager.gd`](../../ui/ui_manager.gd) `game_log` |
| 훅 | [`combat_session.gd`](../../world/combat/combat_session.gd) `action_resolved` · [`encounter_director.gd`](../../world/combat/encounter_director.gd) start/end · `dungeon.gd` 구절 |

Autoload 아님. `CombatSession`은 로그 타입을 모른다. 세이브 JSON에 없음.

메뉴가 열리면 `GameHud`와 함께 숨긴다. **전투 중에는 유지**.  
마을에서는 HUD가 꺼지고 로그 뷰도 없다.  
`unbind_dungeon` / 마을·타이틀 귀환 시 `clear`.

---

## 흐름

```
CombatSession.action_resolved
EncounterDirector.combat_started / combat_finished
        │  Dictionary payload
        ▼
UIManager.push_log → GameLog.push (링 200)
        │  signal entry_added
        ▼
GameLogView  (GameHud 우하, 배속/후퇴 위)
```

표시 시점에 `tr()` + bbcode. `LocaleManager.locale_changed`면 버퍼를 다시 그린다.

---

## 이벤트 (v1)

틱(리젠·스태미나)은 없음. `unit_hit`는 플로트용으로 유지.

| kind | 내용 |
|------|------|
| `combat.start` | 적 표시명 나열 구분선 |
| `hit` | 타격. flags: `crit` `skill` `counter` `retaliation` `damage_all`. 흡혈은 `heal_amount` 같은 줄 |
| `evade` | 회피 (`unit_hit(..., 0)`과 함께) |
| `death` | HP 0 |
| `tired` | Tired **진입** 한 번 |
| `combat.end` | `win` / `lose` / `retreat` |
| `loot.grant` | 획득 표시명 나열 (`LOOT_GOT`) |
| `loot.skip` | 가방 가득 (`LOOT_INVENTORY_FULL`) |
| `verse.read` | 구절 한 줄 (`VERSE_LINE_*`, `actor_name` = locale 키) |
| `question.open` | 가운데 소문 개방 (`QUESTION_OPEN`) |
| `ending.take` / `ending.seal` / `ending.empty` | 결말 (`ENDING_*`) |

---

## API

```
UIManager.push_log(payload)
UIManager.clear_log()
GameLog.push(payload) -> GameLogEntry
GameLog.clear()
signal GameLog.entry_added(entry)
signal GameLog.cleared
GameHud.bind_game_log(log)
CombatSession.signal action_resolved(payload)
```
