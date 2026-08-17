# 인게임 HUD

탐험 중 상시 UI. 메뉴 셸([`menu_shell`](../../ui/shell/menu_shell.tscn))과 분리되며, **메뉴가 열리면** 숨긴다. 전투 중에는 유지한다([`combat.md`](combat.md)). **마을 허브에서는 숨긴다** — 크롬은 [`village.md`](village.md) `VillageShell`.

후속: [`docs/design/hud.md`](../design/hud.md).  
미니맵: [`minimap.md`](minimap.md) · 후속 [`docs/design/minimap.md`](../design/minimap.md).  
게임 로그: [`docs/architecture/game-log.md`](game-log.md) · 후속 [`docs/design/game-log.md`](../design/game-log.md).  
색: [`ui-colors.md`](ui-colors.md) (Gruvbox Dark / `UIColors`).

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
| 전리품 토스트 | `LootToast` / `LootToastTimer` ([`loot.md`](loot.md)) |
| 앱 버전 | [`ui/hud/app_version.gd`](../../ui/hud/app_version.gd) |
| 소유 | [`ui/ui_manager.gd`](../../ui/ui_manager.gd) |

CanvasLayer: HUD `layer = 0`, CombatHud `1`, MenuShell `10`, DevOverlay `100`.  
DevOverlay 크롬: 딤·패널 테두리·제목 = `MAP_START` (청록). 플레이어 메뉴(금·갈)와 구분.

전투 중: `UIManager.set_combat_active(true)` → 월드 입력 차단. **GameHud는 유지** (메뉴 오픈 시에만 숨김).

---

## 화면 구성

| 영역 | 내용 |
|------|------|
| 좌상 | XP(흰) → 마나(주황) → HP(빨강) + `EXP/MP/HP 현재/최대` (`tr`: 경험치/마나/체력) |
| 우상 | 지역명 · `AppVersion` **위**, 그 아래 미니맵 (안개 격자) |
| 좌중 | `[인벤토리]` `[맵]` `[스탯]` `[설정]` (마을에선 HUD 자체 숨김) |
| 좌하 | 장착 룬 0~6칸(상) + 주무기·보조·소모품·요리(하) |
| 우하 | 게임 로그 (배속/후퇴 **위**) |
| 상단 중앙 | 방 `win` 전리품 토스트 (~3초, [`loot.md`](loot.md)) |
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
    ├── MenuNav                 # [인벤토리]/[맵]/[스탯]/[설정]
    ├── ActionBar
    │   ├── SkillRow (HudSlot × 꽂힌 룬 수, 0~6)
    │   └── EquipRow (Main / Off / Item / Food)
    └── GameLogView
```

---

## 데이터 바인딩

| HUD | 소스 |
|-----|------|
| XP | `CharacterStats.xp` / `xp_to_next` |
| 마나 | `CharacterStats.mana` / `mana_max` (`recalculate_derived` 시 `general.focus` → `mana_max`). 전투 중 `set_combat_resources`로 세션 마나 반영 |
| HP | `CharacterStats.hp` / `hp_max` |
| 지역 | `UIManager.location_id` → `set_location`. 던전은 `ZONE_TITLE_*` / `LOCATION_ALTAR_BELOW` (`bind_dungeon(..., location_key)`). 방 타입 Entrance/Boss로 덮지 않음 |
| 버전 | `AppVersion.MAJOR/MINOR/PATCH` (세이브 `version`과 별개) |
| 미니맵 | `FloorMap` via `bind_floor_map` (`visited` / `neighbors` / `room_type`) |
| 기술 | `ResonanceService.list_equipped_rune_skills` (장착 부위 꽂힌 룬만, 최대 6). `RuneData.icon_for_kind` + 이름 ([`inventory.md`](inventory.md) 아이콘). 전투 중 게이지 충전. 마나 되는 첫 **액티브** 자동 발동 ([`equipment.md`](equipment.md) · [`combat.md`](combat.md)) |
| 퀵 | `main_hand`, `off_hand`, `quick_item`, `quick_food`. `ItemData.icon` + 이름 |
| 로그 | `UIManager.game_log` via `bind_game_log`. 전투 `action_resolved` + start/end + loot + 구절/결말 |
| 토스트 | `UIManager.show_loot_toast` → `LootToast` |

`UIManager.apply_save_game` / 메뉴 닫힘 / 전투 승패 후 `refresh_character_views` 시 `GameHud.refresh`.  
소켓 꽂기/빼기는 마을 대장간에서 `UIManager.refresh_hud` ([`equipment.md`](equipment.md)).  
`popup_visibility_changed(true)` → HUD 숨김. `set_combat_active`는 HUD를 숨기지 않는다.  
`bind_dungeon` / `unbind_dungeon` → `bind_floor_map` / `unbind_floor_map`.  
미니맵 클릭 → `map_open_requested` → Map 탭. **전투 중이면 무시** ([`minimap.md`](minimap.md)).

---

## API

```
UIManager.set_location(id)
UIManager.bind_dungeon(floor_map, room_host, location_key="")
UIManager.set_combat_active(bool)   # HUD 유지
UIManager.refresh_character_views()
UIManager.refresh_hud()            # HUD만. 인벤 포커스 유지
GameHud.setup(stats, inventory, location_id)
GameHud.refresh(stats?, inventory?)
GameHud.set_location(location_id)
GameHud.set_menu_open(is_open)      # 메뉴일 때만 숨김. hub면 유지 숨김
GameHud.set_hub_mode(bool)          # true면 HUD 숨김
GameHud.bind_floor_map(floor_map)
GameHud.unbind_floor_map()
GameHud.bind_game_log(log)
UIManager.push_log(payload)
UIManager.clear_log()
UIManager.show_loot_toast(result)
GameHud.show_loot_toast(result)
signal GameHud.map_open_requested
```
퀵/기술 사용 입력은 후속.
