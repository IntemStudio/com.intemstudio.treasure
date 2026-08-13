# 인벤토리 UI

인벤토리 탭 본문 스펙. 전체화면 크롬(Overlay / TopBar / Footer / pause)은 [`ui/shell/menu_shell.tscn`](../../ui/shell/menu_shell.tscn)이 소유하고, 이 문서는 **Inventory 콘텐츠 패널**만 다룹니다.

소켓·룬·보석·공명·제단: [`equipment.md`](equipment.md). 후속(인벤에서 꽂기 UI 등): [`docs/design/equipment.md`](../design/equipment.md).  
방 클리어 장비 드랍: [`loot.md`](loot.md).

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
| Left | 카테고리 `WPN`/`ARM`/`CON`/`MAT`/`TOL`/`MOD` + 용량 라벨 + 5×6 그리드 (`GRID_SIZE` 30, **빈 칸 포함 항상 표시**). `MOD`는 `runes[]`+`gems[]` 합쳐 표시(상세는 `ModifierDetailPanel`). Body 1/3 |
| Center | 선택 상세: 장비 `ItemDetailPanel` / 룬·보석 `ModifierDetailPanel`. Body 1/3 |
| Right | 장비 슬롯(80×80, 가방과 동일, 이름 텍스트), 3D 프리뷰(160×160), 속성 요약, 무게 등급. Body 1/3 |
| Footer (셸) | SORT / EQUIP·UNEQUIP / DISCARD / CLOSE (`MOD` 탭에서는 DISCARD·CLOSE) |

---

## 씬 트리 (콘텐츠)

```
InventoryContent (Control, inventory_theme)
└── Body (HBoxContainer)
    ├── LeftColumn
    │   ├── CategoryTabs (… + MOD)
    │   ├── BagCapacityLabel
    │   └── ItemGrid (columns = 5)
    ├── CenterColumn
    │   ├── ItemDetailPanel
    │   └── ModifierDetailPanel
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
    ├── BodyHost  ← InventoryContent / MapContent / StatsContent / SettingsContent
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

- **카테고리:** WEAPON / ARMOR / CONSUMABLE / MATERIAL / TOOL + UI 탭 `MOD`(룬·보석 합본). `runes[]` / `gems[]`는 `ItemCategory`가 아님 ([`equipment.md`](equipment.md))  
- **정렬 사이클:** `time` → `name` → `weight` → `rarity` (`MOD`에서는 비활성)  
- **장비 슬롯:** `InventoryData.EQUIP_SLOTS`. 상세에 `SocketLayout.describe()`  
- **룬·보석:** `MOD` 탭에서 목록·상세·버리기. 소켓 꽂기 UI는 아직 없음  
- **푸터 액션:** `sort`, `equip`, `discard`, `close`  
- **그리드 슬롯:** 이름 텍스트(`HudSlot`과 동일). 선택 시 `UIColors.GOLD` + `SELECT_BORDER` (스탯 `AttributeRowSelected` / 설정 행과 동일)  
- **입력:** 카테고리 `1`/`3`·LT/RT, 그리드 이동, Equip / Discard / Sort, Esc → `request_close`  
- **포커스:** 가방 오른쪽 끝에서 `→` → 착용 슬롯. 착용 슬롯 왼쪽 끝에서 `←` → 가방. 착용 슬롯 안에서는 3×3 이동

셸 탭 전환은 Q/E·LB/RB (`ui_nav_*_tab`) → TopBar. Map은 순환 탭에 포함됩니다 (`TopBar.CYCLEABLE_TABS`).
