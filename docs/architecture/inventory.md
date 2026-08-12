# 인벤토리 UI

인벤토리 탭 본문 스펙. 전체화면 크롬(Overlay / TopBar / Footer / pause)은 [`ui/shell/menu_shell.tscn`](../../ui/shell/menu_shell.tscn)이 소유하고, 이 문서는 **Inventory 콘텐츠 패널**만 다룹니다.

---

## 위치

| 역할 | 경로 |
|------|------|
| 셸 | [`ui/shell/menu_shell.tscn`](../../ui/shell/menu_shell.tscn) |
| 본문 | [`ui/inventory/inventory_content.tscn`](../../ui/inventory/inventory_content.tscn) + [`inventory_content.gd`](../../ui/inventory/inventory_content.gd) |
| 테마 | [`ui/inventory/themes/inventory_theme.tres`](../../ui/inventory/themes/inventory_theme.tres) |
| 데이터 | [`ui/inventory/resources/inventory_data.gd`](../../ui/inventory/resources/inventory_data.gd), [`item_data.gd`](../../ui/inventory/resources/item_data.gd) |

공통 TopBar / Footer: [`ui/shared/`](../../ui/shared/).

패널 계약: `setup(ui_manager, footer)` → `activate(stats, inventory)` / `deactivate()` → Esc·CLOSE 시 `request_close`.

---

## 화면 구성

| 영역 | 내용 |
|------|------|
| TopBar (셸) | 재화, `[인벤토리][맵][스탯][설정]`, 이름·레벨·XP·HP |
| Left | 카테고리 `WPN`/`ARM`/`CON`/`MAT`/`TOL` (`tr` → 무기/방어구/소모품/재료/도구) + 5×6 그리드 (`GRID_SIZE` 30). Body 1/3 |
| Center | 선택 아이템 상세 (`ItemDetailPanel`). Body 1/3 |
| Right | 장비 슬롯, 3D 프리뷰(160×160), 속성 요약, 무게 등급. Body 1/3 |
| Footer (셸) | SORT / EQUIP·UNEQUIP / DISCARD / CLOSE |

---

## 씬 트리 (콘텐츠)

```
InventoryContent (Control, inventory_theme)
└── Body (HBoxContainer)
    ├── LeftColumn
    │   ├── CategoryTabs
    │   └── ItemGrid (columns = 5)
    ├── CenterColumn
    │   └── ItemDetailPanel
    └── RightColumn
        ├── EquipmentLayout (3열)
        ├── CharacterPreview (SubViewportContainer)
        ├── AttributeList
        └── LoadIndicator
```

셸 쪽:

```
MenuShell (CanvasLayer)
└── Overlay → Root (margin 40) → Main
    ├── TopBar
    ├── BodyHost  ← InventoryContent / StatsContent / SettingsContent
    └── Footer
```

---

## 컴포넌트

```
ui/inventory/components/
  inventory_slot.*
  item_detail_panel.*
  equipment_slot.*
  category_tab.*
  affix_line.*
  skill_slot_row.*
```

---

## 데이터·조작

- **카테고리:** WEAPON / ARMOR / CONSUMABLE / MATERIAL / TOOL  
- **정렬 사이클:** `time` → `name` → `weight` → `rarity`  
- **장비 슬롯:** `InventoryData.EQUIP_SLOTS`  
- **푸터 액션:** `sort`, `equip`, `discard`, `close`  
- **입력:** 카테고리 `1`/`3`·LT/RT, 그리드 이동, Equip / Discard / Sort, Esc → `request_close`

셸 탭 전환은 Q/E·LB/RB (`ui_nav_*_tab`) → TopBar. MAP 클릭은 셸을 닫고, Q/E 순환에서는 MAP을 건너뜁니다.
