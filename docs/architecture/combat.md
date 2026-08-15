# 자동 전투

던전 **현재 방**에서 시작하는 **탑다운 ATB 자동 전투**.  
후속: [`docs/design/combat.md`](../design/combat.md). 방 `win` 장비: [`loot.md`](loot.md).  
인게임 텍스트 로그: [`game-log.md`](game-log.md). 기술·공명: [`equipment.md`](equipment.md).  
색 (포커스 금·HP 바): [`ui-colors.md`](ui-colors.md).

**현황:** v2 방 안 전장 + 고급 스탯(회피·크리·흡혈·반격·리젠·Magic HP·스태미나/Tired) + 히어로 기술 게이지·마나 자동 발동 + **고정 타겟**(클릭으로 변경). GameHud·미니맵 전투 중 유지.

---

## 위치

| 역할 | 경로 |
|------|------|
| 규칙 | [`data/combat/combat_rules.gd`](../../data/combat/combat_rules.gd) · [`combat_rules.tres`](../../data/combat/combat_rules.tres) |
| 최종 스탯 | [`data/combat/combat_stats.gd`](../../data/combat/combat_stats.gd) |
| 합산 | [`data/combat/combat_stats_builder.gd`](../../data/combat/combat_stats_builder.gd) |
| 유닛 | [`data/combat/combat_unit_def.gd`](../../data/combat/combat_unit_def.gd) · [`units/`](../../data/combat/units/) |
| 인카운터 | [`data/combat/encounter_def.gd`](../../data/combat/encounter_def.gd) · [`encounters/{region}/`](../../data/combat/encounters/) |
| 지역 테이블 | [`data/combat/region_encounters.gd`](../../data/combat/region_encounters.gd) |
| 세션 | [`world/combat/combat_session.gd`](../../world/combat/combat_session.gd) |
| 아레나 | [`world/combat/combat_arena.gd`](../../world/combat/combat_arena.gd) |
| 액터 | [`world/combat/combatant_actor.tscn`](../../world/combat/combatant_actor.tscn) |
| 디렉터 | [`world/combat/encounter_director.gd`](../../world/combat/encounter_director.gd) |
| 크롬 | [`ui/combat/combat_hud.tscn`](../../ui/combat/combat_hud.tscn) + [`combat_hud.gd`](../../ui/combat/combat_hud.gd) |
| 바인딩 | [`scenes/dungeon/dungeon.gd`](../../scenes/dungeon/dungeon.gd) · [`ui/ui_manager.gd`](../../ui/ui_manager.gd) |

CanvasLayer: HUD `0`, CombatHud `1`, MenuShell `10`, DevOverlay `100`.  
유닛은 방 월드 `Node2D`. 머리 위: 이름 · HP 바 + `현재/최대` · ATB.  
피격 시 `unit_hit` → `CombatantActor` 플로팅 데미지.  
이산 행동 `action_resolved` → 게임 로그 ([`game-log.md`](game-log.md)).

---

## 흐름

1. `dungeon.gd` `_ready` — `pending_run.dungeon_id`로 세션·아레나·Hud·디렉터 생성, `bind_dungeon` / `bind_combat`
2. `EncounterDirector.setup(..., dungeon_id)` — `RegionEncounters.load_pair`로 지역 normal/boss 캐시
3. `RoomHost.enter_room` → `FloorMap.room_changed`
4. `EncounterDirector.on_room_entered` — `START`/`cleared`면 skip
5. `CombatStatsBuilder.build` → `CombatSession.start` (현재 HP 스냅샷)
6. `UIManager.set_combat_active(true)` → 월드 입력 차단. **GameHud 유지**
7. `CombatArena.start(room)` — Player 숨김, 적 수 진형 슬롯에 액터 스폰(`y_sort`); `CombatHud.show_combat` (배속·후퇴)
8. 세션 `_process`로 ATB·**기술 게이지**·고급 히트 공식 (`speed_mult`). 배속은 같은 던전에서 방 이동 후에도 유지. **타겟:** 전투 시작 시 우선순위가 같은 생존 적 중 하나를 고르고, 죽을 때까지 유지 (`target_mode=sticky`). 적을 클릭하면 히어로 포커스를 바꿈 (금색 테두리). 죽으면 다음 생존 적으로 재지정
9. 메뉴 오픈 → `get_tree().paused` → ATB 일시정지. 미니맵 클릭은 Map 탭을 열지 않음
10. `combat_ended` → Arena `clear` + `CombatHud.hide_combat` + `set_combat_active(false)`

### 히트 순서

1. 회피 (Tired면 `tired_evasion_mult`). 성공 시 스태미나 소모, `unit_hit(..., 0)` (플로팅 생략)
2. 본타 → Defense → Crit 배율 → `magic_damage`(방어 무시 추가)
3. Magic HP를 HP보다 먼저 깎음
4. `damage_all` → 다른 생존 적 (회피만, 반격 없음)
5. Vampirism · Retaliation · Counter (`CombatRules` 플래그)
6. 틱: `regen_per_sec`, 스태미나 재생. 공격/반격/회피 비용. 0이면 Tired

히어로 스냅샷: [`CombatStatsBuilder`](../../data/combat/combat_stats_builder.gd) ([`stats.md`](stats.md)).  
기술: 평타 ATB와 별도 `skill_atb`. 가득 차면 `list_equipped_rune_skills` 목록에서 마나가 되는 첫 **액티브**(`strike`/`combo`/`aoe`)를 자동 발동. 패시브는 건너뜀. 부족하면 평타만 ([`equipment.md`](equipment.md) · HUD 충전 바).

| 결과 | 처리 |
|------|------|
| `win` | `RoomData.cleared = true`, 남은 HP 반영, XP, **장비 드랍** ([`loot.md`](loot.md)). **보스**면 `return_to_village()` |
| `lose` | `UIManager.return_to_village()` (슬롯 저장, 런 삭제, 메타 유지) |
| `retreat` | 입장 시 HP 복구, `RoomHost.enter_room(ZERO)` (입구) |

HP/XP·가방은 메타에 남는다. 방 `cleared`/`visited`는 런 JSON에 쓴다. 마을 복귀 시 런 파일 삭제 ([`save-load.md`](save-load.md)). 허브: [`village.md`](village.md).

---

## API

```
UIManager.bind_combat(director)
UIManager.set_combat_active(bool)     # GameHud 유지
UIManager.is_combat_active() -> bool
EncounterDirector.setup(ui, floor_map, room_host, session, arena, hud, dungeon_id="")
EncounterDirector.set_dungeon_id(id)
EncounterDirector.on_room_entered(room)
EncounterDirector.start(room, override?) -> bool
EncounterDirector.is_active() -> bool
EncounterDirector.request_retreat()
EncounterDirector.force_start_current() -> bool
EncounterDirector.force_result(result)
RegionEncounters.normalize_region(id) / load_pair(id)
CombatArena.setup(player)
CombatArena.bind_session(session)
CombatArena.start(room_node, state, encounter)
CombatArena.clear(show_player)
basic_room.get_ally_slot_global(index)
basic_room.get_enemy_slot_global(index, enemy_count)
CombatHud.bind_session(session)
CombatHud.show_combat(state, encounter)
CombatHud.hide_combat()
CombatSession.cycle_speed() / get_speed_mult()
CombatSession.set_hero_focus(unit_id) -> bool
CombatSession.get_hero_focus_id() -> String
signal combat_ended(result)  # "win" / "lose" / "retreat"
signal unit_hit(unit_id, amount)
signal action_resolved(payload)
```

맵 텔레포트·미니맵 클릭: 전투 중 거부. WASD: `is_world_input_blocked()`.

---

## 지역 인카운터

게시판 `dungeon_id` → [`RegionEncounters`](../../data/combat/region_encounters.gd) → `encounters/{region}/normal.tres` · `boss.tres`.  
에디터 단독 실행·알 수 없는 id → `cemetery`. 구 `normal_slimes` / `boss_brute`는 폴백·디버그용.

| 지역 | NORMAL | BOSS |
|------|--------|------|
| cemetery | Skeleton + Watcher | Bone Guardian |
| grove | Ratwolf + Spider | Nest Mother |
| mansion | Ghoul + Vampire | Vampire Lord |
| battlefield | Ghost + Goblin | War Specter |

방 슬롯: `basic_room` `ALLY_SLOTS`(히어로 왼쪽 중앙) / `get_enemy_slot_global(index, enemy_count)` 진형(1 정면, 2 위·아래, 3 삼각형, 4 뒷줄). Marker2D 슬롯 없음. 액터 호스트 `y_sort_enabled`. 유닛 표시명 `tr(display_name)`.

---

## 디버그

DevOverlay `[캐릭터]` 탭: 강제 조우 / 승리 / 패배 / 후퇴. `[아이템]` 탭: 장비·보석·룬 지급, 장비 희귀도 변경(`ItemData.apply_rarity` → 색·가격, 소켓은 부위로 다시 찍고 넘친 칸 트림). `[서가]` 탭: 룬/보석 판 `open_cards` 전 칸 해금 (`CardRegistrationService.open_all_on_shelf`).
