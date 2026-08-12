# 인게임 HUD

탐험/전투 중 상시 UI. 메뉴 셸([`menu_shell`](../../ui/shell/menu_shell.tscn))과 분리되며, 메뉴가 열리면 숨긴다.

설계 배경: [`docs/design/hud.md`](../design/hud.md).

---

## 위치

| 역할 | 경로 |
|------|------|
| 루트 | [`ui/hud/game_hud.tscn`](../../ui/hud/game_hud.tscn) + [`game_hud.gd`](../../ui/hud/game_hud.gd) |
| 자원 바 | [`ui/hud/components/resource_bars.*`](../../ui/hud/components/resource_bars.tscn) |
| 지역·버전 | [`ui/hud/components/world_info.*`](../../ui/hud/components/world_info.tscn) |
| 기술·퀵슬롯 | [`ui/hud/components/action_bar.*`](../../ui/hud/components/action_bar.tscn) |
| 슬롯 | [`ui/hud/components/hud_slot.*`](../../ui/hud/components/hud_slot.tscn) |
| 앱 버전 | [`ui/hud/app_version.gd`](../../ui/hud/app_version.gd) |
| 소유 | [`ui/ui_manager.gd`](../../ui/ui_manager.gd) |

CanvasLayer: HUD `layer = 0`, MenuShell `10`, DevOverlay `100`.

---

## 화면 구성

| 영역 | 내용 |
|------|------|
| 좌상 | XP(흰) → 마나(주황) → HP(빨강) + `EXP/MP/HP 현재/최대` (`tr`: 경험치/마나/체력) |
| 우상 | 지역명 (`tr(location_id)`) · `AppVersion` (`M  N  P`) |
| 좌하 | 기술 4칸(상) + 주무기·보조·아이템·음식(하) |
| 중앙 | 없음 |

초상화·시계·맵 아이콘·재화·중앙 프롬프트는 없음.

---

## 씬 트리

```
GameHud (CanvasLayer)
└── Root (Control, full rect, mouse ignore)
    ├── TopRow (HBox)
    │   ├── ResourceBars
    │   ├── Spacer
    │   └── WorldInfo
    └── ActionBar
        ├── SkillRow (HudSlot × 4)
        └── EquipRow (Main / Off / Item / Food)
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
| 기술 | `equipped.main_hand.skills` (최대 4, 빈 이름 → Empty) |
| 퀵 | `main_hand`, `off_hand`, `quick_item`, `quick_food` |

`UIManager.apply_save_game` / 메뉴 닫힘 시 `GameHud.refresh`.  
`popup_visibility_changed(true)` → HUD 숨김.

---

## API

```
UIManager.set_location(id)
GameHud.setup(stats, inventory, location_id)
GameHud.refresh(stats?, inventory?)
GameHud.set_location(location_id)
GameHud.set_menu_open(is_open)
```

v1은 표시만. 퀵/기술 사용 입력은 후속.
