# 인게임 HUD

탐험 중 상시 UI. 메뉴 셸([`menu_shell`](../../ui/shell/menu_shell.tscn))과 분리되며, **메뉴가 열리면** 숨긴다. 전투 중에는 유지한다([`combat.md`](combat.md)).

후속: [`docs/design/hud.md`](../design/hud.md).  
미니맵: [`minimap.md`](minimap.md) · 후속 [`docs/design/minimap.md`](../design/minimap.md).  
게임 로그: [`game-log.md`](game-log.md) · 후속 [`docs/design/game-log.md`](../design/game-log.md).

---

## 위치

| 역할 | 경로 |
|------|------|
| 루트 | [`ui/hud/game_hud.tscn`](../../ui/hud/game_hud.tscn) + [`game_hud.gd`](../../ui/hud/game_hud.gd) |
| 자원 바 | [`ui/hud/components/resource_bars.*`](../../ui/hud/components/resource_bars.tscn) |
| 지역·버전 | [`ui/hud/components/world_info.*`](../../ui/hud/components/world_info.tscn) |
| 미니맵 | [`ui/hud/components/minimap.*`](../../ui/hud/components/minimap.tscn) |
| 기술·퀵슬롯 | [`ui/hud/components/action_bar.*`](../../ui/hud/components/action_bar.tscn) |
| 슬롯 | [`ui/hud/components/hud_slot.*`](../../ui/hud/components/hud_slot.tscn) |
| 게임 로그 | [`ui/hud/components/game_log_view.*`](../../ui/hud/components/game_log_view.tscn) |
| 앱 버전 | [`ui/hud/app_version.gd`](../../ui/hud/app_version.gd) |
| 소유 | [`ui/ui_manager.gd`](../../ui/ui_manager.gd) |

CanvasLayer: HUD `layer = 0`, CombatHud `1`, MenuShell `10`, DevOverlay `100`.

전투 중: `UIManager.set_combat_active(true)` → 월드 입력 차단. **GameHud는 유지** (메뉴 오픈 시에만 숨김).

---

## 화면 구성

| 영역 | 내용 |
|------|------|
| 좌상 | XP(흰) → 마나(주황) → HP(빨강) + `EXP/MP/HP 현재/최대` (`tr`: 경험치/마나/체력) |
| 우상 | 지역명 · `AppVersion` **위**, 그 아래 미니맵 (안개 격자) |
| 좌하 | 기술 4칸(상) + 주무기·보조·아이템·음식(하) |
| 우하 | 게임 로그 (배속/후퇴 **위**) |
| 중앙 | 없음 |

초상화·시계·맵 아이콘·재화·중앙 프롬프트는 없음.

---

## 씬 트리

```
GameHud (CanvasLayer)
└── Root (Control, full rect, mouse ignore)
    ├── ResourceBars
    ├── TopRight (VBox)
    │   ├── WorldInfo
    │   └── MiniMap
    ├── ActionBar
    │   ├── SkillRow (HudSlot × 4)
    │   └── EquipRow (Main / Off / Item / Food)
    └── GameLogView
```

---

## 데이터 바인딩

| HUD | 소스 |
|-----|------|
| XP | `CharacterStats.xp` / `xp_to_next` |
| 마나 | `CharacterStats.mana` / `mana_max` (`recalculate_derived` 시 `general.focus` → `mana_max`) |
| HP | `CharacterStats.hp` / `hp_max` |
| 지역 | `UIManager.location_id` → `set_location` |
| 버전 | `AppVersion.MAJOR/MINOR/PATCH` (세이브 `version`과 별개) |
| 미니맵 | `FloorMap` via `bind_floor_map` (`visited` / `neighbors` / `room_type`) |
| 기술 | `equipped.main_hand.skills` (최대 4, 빈 이름 → Empty). 이름 텍스트만 |
| 퀵 | `main_hand`, `off_hand`, `quick_item`, `quick_food`. 이름 텍스트만 (아이콘 없음) |
| 로그 | `UIManager.game_log` via `bind_game_log`. 전투 `action_resolved` + start/end |

`UIManager.apply_save_game` / 메뉴 닫힘 / 전투 승패 후 `refresh_character_views` 시 `GameHud.refresh`.  
`popup_visibility_changed(true)` → HUD 숨김. `set_combat_active`는 HUD를 숨기지 않는다.  
`bind_dungeon` / `unbind_dungeon` → `bind_floor_map` / `unbind_floor_map`.  
미니맵 클릭 → `map_open_requested` → Map 탭. **전투 중이면 무시** ([`minimap.md`](minimap.md)).

---

## API

```
UIManager.set_location(id)
UIManager.set_combat_active(bool)   # HUD 유지
UIManager.refresh_character_views()
GameHud.setup(stats, inventory, location_id)
GameHud.refresh(stats?, inventory?)
GameHud.set_location(location_id)
GameHud.set_menu_open(is_open)      # 메뉴일 때만 숨김
GameHud.bind_floor_map(floor_map)
GameHud.unbind_floor_map()
GameHud.bind_game_log(log)
UIManager.push_log(payload)
UIManager.clear_log()
signal GameHud.map_open_requested
```

퀵/기술 사용 입력은 후속.
