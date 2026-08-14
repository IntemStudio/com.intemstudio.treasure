# 인벤토리 UI

인벤토리 탭 본문 스펙. 전체화면 크롬(Overlay / TopBar / Footer / pause)은 [`ui/shell/menu_shell.tscn`](../../ui/shell/menu_shell.tscn)이 소유하고, 이 문서는 **Inventory 콘텐츠 패널**만 다룹니다.

소켓·룬·보석·공명·제단: [`equipment.md`](equipment.md).  
방 클리어 장비 드랍: [`loot.md`](loot.md). 상세 Cost/Gain: [`docs/design/shop.md`](../design/shop.md).

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
| Center | 선택 상세: 장비 `ItemDetailPanel`(이름·등급·유형) / 룬·보석 `ModifierDetailPanel`. Body 1/3 |
| Right | 장비 슬롯(80×80, 가방과 동일, 이름 텍스트), 3D 프리뷰(160×160), 속성 요약, 무게 등급. Body 1/3 |
| Footer (셸) | SORT / EQUIP·UNEQUIP / SOCKET·UNSOCKET / DISCARD / CLOSE. pick 모드 `BACK`. `MOD`는 SOCKET·DISCARD·CLOSE |

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
  socket_row.*
  equipment_slot.*
  category_tab.*
  affix_line.*
  skill_slot_row.*
```

---

## 데이터·조작

- **카테고리:** WEAPON / ARMOR / CONSUMABLE / MATERIAL / TOOL + UI 탭 `MOD`(룬·보석 합본). `runes[]` / `gems[]`는 `ItemCategory`가 아님 ([`equipment.md`](equipment.md))  
- **정렬 사이클:** `time` → `name` → `weight` → `rarity` (`MOD`에서는 비활성)  
- **장비 슬롯:** `InventoryData.EQUIP_SLOTS`. 착용 중이면 이름·테두리가 희귀도 색. 상세에 소켓 행(`SocketRow`)  
- **양손 무기:** `ItemData.two_handed`. 장착 시 `main_hand`와 `off_hand`를 모두 가방으로 되돌림. 양손 착용 중 보조를 끼면 양손이 가방으로 가고 주무기 칸은 빈다. 한손+보조를 빼려면 가방에 빈 칸이 하나 더 필요  
- **ATK/DEF 비교:** 가방·보상 카드에서 고른 장비의 공격/방어 옆 초록(`+`)·빨강(`-`) 숫자는 같은 슬롯 착용 장비 대비 차이. 착용 칸을 보거나 슬롯이 비었거나 수치가 같으면 숨김  
- **Cost/Gain:** 상세가 `item.cost` / `item.gain`을 그대로 표시. 카탈로그 대부분은 0. 공식·상점: [`shop.md`](../design/shop.md)  
- **룬·보석:** `MOD` 탭에서 목록·상세·버리기·소켓. 장비 상세 소켓 행에서 꽂기/빼기. 호환만 강조 (`pick_modifier` / `pick_slot`)  
- **푸터 액션:** `sort`, `equip`, `socket` / `unsocket`, `discard`, `close` / pick 모드 `back`  
- **그리드 슬롯:** 이름 텍스트(`HudSlot`과 동일). 선택 시 `UIColors.GOLD` + `SELECT_BORDER` (스탯 `AttributeRowSelected` / 설정 행과 동일). MOD에 꽂힌 uid는 `SOCKETED` 뱃지  
- **입력:** 카테고리 `1`/`3`·LT/RT, 그리드 이동, 가방 우클릭·더블클릭·Enter/A 장착(또는 소켓), 착용 칸 우클릭·더블클릭 해제, X 버리기, Sort, Esc → pick 취소 또는 `request_close`  
- **포커스:** 가방 오른쪽 끝에서 `→` → 착용 슬롯. 착용 슬롯 왼쪽 끝에서 `←` → 가방. 착용에서 `↓` → 소켓 행. 소켓에서 `←`/`→` → 가방/착용

셸 탭 전환은 Q/E·LB/RB (`ui_nav_*_tab`) → TopBar. Map은 순환 탭에 포함됩니다 (`TopBar.CYCLEABLE_TABS`).
