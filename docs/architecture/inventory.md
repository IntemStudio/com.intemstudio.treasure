# 인벤토리 UI

인벤토리 탭 본문 스펙. 모달 크롬(Overlay / TopBar 제목 / Footer / pause, Sheet 1440×800)은 [`ui/shell/menu_shell.tscn`](../../ui/shell/menu_shell.tscn)이 소유하고, 이 문서는 **Inventory 콘텐츠 패널**만 다룹니다. 팝업 기하: [`ui-colors.md`](ui-colors.md) · `UIPopupLayout`. 인벤·스탯·설정·맵·소문·서가·대장간은 **각각 단독 Sheet** (TopBar 탭 순환 없음).

소켓·룬·보석·공명·서가 봉인: [`equipment.md`](equipment.md).  
방 클리어 장비 드랍: [`loot.md`](loot.md). 상세 골드: [`shop.md`](shop.md).  
색·희귀도: [`ui-colors.md`](ui-colors.md) (`UIColors` / `ItemData.color_for_rarity`).

---

## 위치

| 역할 | 경로 |
|------|------|
| 셸 | [`ui/shell/menu_shell.tscn`](../../ui/shell/menu_shell.tscn) |
| 본문 | [`ui/inventory/inventory_content.tscn`](../../ui/inventory/inventory_content.tscn) + [`inventory_content.gd`](../../ui/inventory/inventory_content.gd) |
| 테마 | [`ui/inventory/themes/inventory_theme.tres`](../../ui/inventory/themes/inventory_theme.tres) |
| 데이터 | [`ui/inventory/resources/inventory_data.gd`](../../ui/inventory/resources/inventory_data.gd), [`item_data.gd`](../../ui/inventory/resources/item_data.gd), [`item_defaults.gd`](../../ui/inventory/resources/item_defaults.gd) |
| 아이콘 | [`assets/icons/32x32.png`](../../assets/icons/32x32.png) · `ItemData.sheet_icon` · [`verify_item_icons.gd`](../../ui/inventory/resources/verify_item_icons.gd) |

공통 TopBar / Footer: [`ui/shared/`](../../ui/shared/).

패널 계약: `setup(ui_manager, footer)` → `activate(stats, inventory)` / `deactivate()` → Esc·CLOSE 시 `request_close`.

---

## 화면 구성

| 영역 | 내용 |
|------|------|
| TopBar (셸) | 상단 밴드(72) — 제목만 |
| Body | 중단 밴드 — expand |
| Footer (셸) | 하단 밴드(72) — 프롬프트 |
| Left | 탭별 **5×5 = 25칸** (`GRID_SIZE`, 빈 칸 포함 항상 표시). 칸 80×80 (`SIZE_SHRINK_BEGIN` — FILL이면 테두리 1px가 먹힘). 장비/소모품/재료/도구는 각자 `bags[tab]` 보유. `MOD`는 미소켓 `runes[]`+`gems[]` 합산 최대 25. Body 1/3 |
| Center | 선택 상세: 장비 `ItemDetailPanel`(이름·등급·유형·소켓·`SOCKET_EFFECTS`) / 룬·보석 `ModifierDetailPanel`. Body 1/3 |
| Right | 장비 슬롯(80×80, 가방과 동일). 비면 부위 실루엣, 착용 중이면 `item.icon`+이름. 속성 요약, 무게 등급. Body 1/3 |
| Footer (셸) | SORT / EQUIP·UNEQUIP / DISCARD / CLOSE. `MOD`는 DISCARD·CLOSE |

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
        └── RightScroll
            └── RightScrollGutter  # 스크롤바 폭만큼 margin_right
                └── RightInner
                    ├── EquipmentLayout (무기·보조 / 투구·갑옷·바지 / 반지·반지 / 도구·도구)
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
```

---

## 데이터·조작

- **카테고리:** 장비(WEAPON+ARMOR) / CONSUMABLE / MATERIAL / TOOL + UI 탭 `MOD`(룬·보석). 탭마다 가방 25칸. `runes[]` / `gems[]`는 `ItemCategory`가 아님 ([`equipment.md`](equipment.md)). 탭은 시트 아이콘 + 라벨 (`CategoryTab`)  
- **정렬 사이클:** `time` → `name` → `weight` → `rarity` (`MOD`에서는 비활성)  
- **장비 슬롯:** `InventoryData.EQUIP_SLOTS`. 비면 `ItemDefaults.icon_for_equip_slot` 실루엣(알파 0.35). 착용 중이면 `item.icon` + 이름·테두리가 희귀도 색. 상세에 소켓 행(`SocketRow`)과 꽂힌 룬 기술·이 부위 보석 효과(설명 `SKILL_KIND_*_DESC` / `GEM_FX_*_DESC`). 접두사는 `STAT_DESC_*`  
- **양손 무기:** `ItemData.two_handed`. 장착 시 `main_hand`와 `off_hand`를 모두 가방으로 되돌림. 양손 착용 중 보조를 끼면 양손이 가방으로 가고 주무기 칸은 빈다. 한손+보조를 빼려면 가방에 빈 칸이 하나 더 필요  
- **ATK/DEF 비교:** 가방·보상 카드에서 고른 장비의 공격/방어 옆 초록(`+`)·빨강(`-`) 숫자는 같은 슬롯 착용 장비 대비 차이. 착용 칸을 보거나 슬롯이 비었거나 수치가 같으면 숨김  
- **골드 가격:** 가진 아이템은 [`ShopPricing`](shop.md) `sell_price` → `판매 가격 N골드`. 구매 후보는 `buy_price` → `구매 가격 N골드` (`set_gold_price`). `item.cost` / `item.gain`은 오버라이드(둘 다 0이면 공식)  
- **룬·보석:** `MOD` 탭에서 미소켓만 목록·상세·버리기 (`RuneData.icon` / `GemData.icon`). 꽂기/빼기는 마을 대장간 ([`equipment.md`](equipment.md)). 꽂힌 인스턴스는 가방에서 빠지고 장비 `socketed`에만 남음. 장비 상세는 소켓 행 + 적용 효과(설명 포함)  
- **푸터 액션:** `sort`, `equip`, `discard`, `close`  
- **그리드 슬롯:** `ItemData.icon` (`assets/icons/32x32.png` 32px 셀) + 이름. 선택 시 `UIColors.GOLD` + `SELECT_BORDER` (스탯 `AttributeRowSelected` / 설정 행과 동일)  
- **입력:** 카테고리 `1`/`3`·LT/RT, 그리드 이동, 가방 우클릭·더블클릭·Enter/A 장착, 착용 칸 우클릭·더블클릭 해제, X 버리기, Sort, Esc → `request_close`  
- **포커스:** 가방 오른쪽 끝에서 `→` → 착용 슬롯. 착용 슬롯 왼쪽 끝에서 `←` → 가방

셸 탭 전환은 Q/E·LB/RB (`ui_nav_*_tab`) → TopBar. Map은 순환 탭에 포함됩니다 (`TopBar.CYCLEABLE_TABS`).

DevOverlay `[아이템]`은 같은 `InventorySlot` / `ItemDetailPanel` / `ModifierDetailPanel`을 재사용한다 ([`save-load.md`](save-load.md)).

---

## 아이콘

시트 [`assets/icons/32x32.png`](../../assets/icons/32x32.png) — 16열 × 32px. `ItemData.sheet_icon(col, row)` → AtlasTexture (`filter_clip`, nearest). 타입·부위 셀이지 id 맵이 아님. 프리미엄 시트로 갈 때 PNG + 좌표만 바꾼다.

| 쓰는 곳 | 매핑 |
|---------|------|
| 아이템 | `ItemDefaults.icon_for` → `ItemData.icon` |
| 빈 착용 칸 | `ItemDefaults.icon_for_equip_slot` |
| 카테고리 탭 | `CATEGORY_DEFS` col/row → `CategoryTab.icon` |
| 룬 | `RuneData.icon_for_kind` ([`equipment.md`](equipment.md)) |
| 보석 | `GemData.icon_for` (공명 태그 → 타입) |
| 스탯 속성 행 | `StatsContent._attribute_icon`. 초상화는 `icon.svg` ([`stats.md`](stats.md)) |
| HUD 기술 / 퀵 | kind / `ItemData.icon` ([`hud.md`](hud.md)) |

서가 OPEN·REGISTERED 칸·소켓 찬 칸·룻 상세는 같은 `icon` 필드를 쓴다. 빈 소켓·룻 토스트·미니맵 글자·전투 액터는 시트 없음.

`godot --headless --path . -s res://ui/inventory/resources/verify_item_icons.gd`
