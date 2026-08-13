# 자동 전투

던전 **현재 방**에서 시작하는 **탑다운 ATB 자동 전투**.  
후속: [`docs/design/combat.md`](../design/combat.md).

**현황:** v2 방 안 전장 (평타·방어 공식·플로팅 데미지·승패/후퇴). GameHud·미니맵 전투 중 유지.

---

## 위치

| 역할 | 경로 |
|------|------|
| 규칙 | [`data/combat/combat_rules.gd`](../../data/combat/combat_rules.gd) · [`combat_rules.tres`](../../data/combat/combat_rules.tres) |
| 최종 스탯 | [`data/combat/combat_stats.gd`](../../data/combat/combat_stats.gd) |
| 합산 | [`data/combat/combat_stats_builder.gd`](../../data/combat/combat_stats_builder.gd) |
| 유닛 | [`data/combat/combat_unit_def.gd`](../../data/combat/combat_unit_def.gd) · [`units/`](../../data/combat/units/) |
| 인카운터 | [`data/combat/encounter_def.gd`](../../data/combat/encounter_def.gd) · [`encounters/`](../../data/combat/encounters/) |
| 세션 | [`world/combat/combat_session.gd`](../../world/combat/combat_session.gd) |
| 아레나 | [`world/combat/combat_arena.gd`](../../world/combat/combat_arena.gd) |
| 액터 | [`world/combat/combatant_actor.tscn`](../../world/combat/combatant_actor.tscn) |
| 디렉터 | [`world/combat/encounter_director.gd`](../../world/combat/encounter_director.gd) |
| 크롬 | [`ui/combat/combat_hud.tscn`](../../ui/combat/combat_hud.tscn) + [`combat_hud.gd`](../../ui/combat/combat_hud.gd) |
| 바인딩 | [`scenes/dungeon/dungeon.gd`](../../scenes/dungeon/dungeon.gd) · [`ui/ui_manager.gd`](../../ui/ui_manager.gd) |

CanvasLayer: HUD `0`, CombatHud `1`, MenuShell `10`, DevOverlay `100`.  
유닛은 방 월드 `Node2D`. 머리 위: 이름 · HP 바 + `현재/최대` · ATB.  
피격 시 `unit_hit` → `CombatantActor` 플로팅 데미지.

---

## 흐름

1. `dungeon.gd` `_ready` — 세션·아레나·Hud·디렉터 생성, `bind_dungeon` / `bind_combat`
2. `RoomHost.enter_room` → `FloorMap.room_changed`
3. `EncounterDirector.on_room_entered` — `START`/`cleared`면 skip
4. `CombatStatsBuilder.build` → `CombatSession.start` (현재 HP 스냅샷)
5. `UIManager.set_combat_active(true)` → 월드 입력 차단. **GameHud 유지**
6. `CombatArena.start(room)` — Player 숨김, 슬롯에 액터 스폰; `CombatHud.show_combat` (배속·후퇴)
7. 세션 `_process`로 ATB·평타·방어 공식 (`speed_mult`)
8. 메뉴 오픈 → `get_tree().paused` → ATB 일시정지. 미니맵 클릭은 Map 탭을 열지 않음
9. `combat_ended` → Arena `clear` + `CombatHud.hide_combat` + `set_combat_active(false)`

| 결과 | 처리 |
|------|------|
| `win` | `RoomData.cleared = true`, 남은 HP 반영, `CharacterStats.add_xp`, HUD 갱신 |
| `lose` | `UIManager.return_to_title()` |
| `retreat` | 입장 시 HP 복구, `RoomHost.enter_room(ZERO)` (입구) |

HP/XP는 메타 `character`에 남는다. 층·`cleared`는 세이브하지 않음 ([`save-load.md`](save-load.md)).

---

## API

```
UIManager.bind_combat(director)
UIManager.set_combat_active(bool)     # GameHud 유지
UIManager.is_combat_active() -> bool
EncounterDirector.setup(ui, floor_map, room_host, session, arena, hud)
EncounterDirector.on_room_entered(room)
EncounterDirector.start(room, override?) -> bool
EncounterDirector.is_active() -> bool
EncounterDirector.request_retreat()
EncounterDirector.force_start_current() -> bool
EncounterDirector.force_result(result)
CombatArena.setup(player)
CombatArena.bind_session(session)
CombatArena.start(room_node, state, encounter)
CombatArena.clear(show_player)
CombatHud.bind_session(session)
CombatHud.show_combat(state, encounter)
CombatHud.hide_combat()
CombatSession.cycle_speed() / get_speed_mult()
signal combat_ended(result)  # "win" / "lose" / "retreat"
signal unit_hit(unit_id, amount)
```

맵 텔레포트·미니맵 클릭: 전투 중 거부. WASD: `is_world_input_blocked()`.

---

## v1 인카운터

| 방 | 리소스 |
|----|--------|
| NORMAL | `encounters/normal_slimes.tres` (슬라임 ×2, 후퇴 가능) |
| BOSS | `encounters/boss_brute.tres` (후퇴 불가) |

방 슬롯: `basic_room` `AllySlot0` / `EnemySlot0..2`.

---

## 디버그

DevOverlay Character 탭: 강제 조우 / 승리 / 패배 / 후퇴.
