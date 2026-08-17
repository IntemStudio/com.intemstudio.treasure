# UI 색 — Gruvbox Dark

단일 의미 소스: [`ui/shared/ui_colors.gd`](../../ui/shared/ui_colors.gd) (`class_name UIColors`).  
팔레트: **Gruvbox Dark** (`PALETTE_ID = "gruvbox_dark"`).  
Const는 `Color(r,g,b,a)` float (hex는 아래 표). `Color.html`은 const에서 class_name 해석이 깨져 쓰지 않는다.  
검증: `godot --headless --path . -s res://ui/shared/verify_ui_colors.gd`.

설정에서 테마를 고르는 기능은 **없음**.  
`ponytail:` 나중에 `SettingsManager`가 테마를 바꾸면 **토큰 이름은 유지**하고 hex만 교체.

관련: [`hud.md`](hud.md) · [`inventory.md`](inventory.md) · [`combat.md`](combat.md) · [`game-log.md`](game-log.md).

---

## 규칙

1. 스크립트 UI 색은 `UIColors.*`만. 새 `Color(r,g,b)` 금지.
2. 알파만 다를 때 새 토큰을 만들지 않는다 → `UIColors.with_alpha(c, a)`.
3. bbcode hex → `UIColors.html(c)`.
4. `CLEAR` / `DIM` / `OUTLINE` / `Color.WHITE` / 죽은 액터 `modulate` 알파는 연산자. 팔레트 아님.
5. **유닛 `body_color`** (`data/combat/units/*.tres`)는 월드 데이터. UI 팔레트에 넣지 않는다. 액터는 그리지 않음 — 본체는 표시명 ([`combat.md`](combat.md)).
6. Theme `.tres` / 씬 bake는 스크립트 상수를 못 읽는다 → **같은 hex를 복제**. verify가 어긋남을 잡는다.
7. **`MinimapStyle`** 기본값도 `UIColors` / `with_alpha`만. 팔레트 float를 `@export`에 다시 쓰지 않는다.
8. 왼쪽 선택·포커스 바는 **`UISelectStyle`** (`ui/shared/ui_select_style.gd`). 색은 `UIColors`.

---

## 토큰

| 토큰 | hex | 역할 |
|------|-----|------|
| `BG_OVERLAY` | `#1d2021` @0.72 | 메뉴·딤 오버레이 |
| `PANEL_BG` | `#3c3836` @0.55 | 패널 |
| `SLOT_BG` | `#1d2021` @0.70 | 슬롯 배경 |
| `SLOT_BG_SOLID` | `#282828` | 벽·불투명 슬롯 |
| `SLOT_BORDER` | `#7c6f64` | 비선택 테두리 |
| `HOVER_BG` / `SELECT_BG` | `#32302f` | 호버·선택 배경 |
| `TEXT_MAIN` | `#ebdbb2` | 본문 |
| `TEXT_MUTED` | `#928374` | 캡션·비활성 |
| `TEXT_LORE` | `#d5c4a1` | 로어·부제 |
| `TEXT_INVERSE` | `#1d2021` | 아웃라인 베이스 |
| `GOLD` | `#d79921` | 강조·선택 글자·문틀 |
| `SELECT_BORDER` | `#fabd2f` @0.95 | 선택 테두리 |
| `POSITIVE` / `NEGATIVE` | `#b8bb26` / `#fb4934` | 이득 / 위험 |
| `HP_FILL` | `#cc241d` | HUD·전투 HP 바 |
| `XP_FILL` | `#ebdbb2` | XP 바 |
| `MANA_FILL` | `#fe8019` | 마나 바 |
| `ATB_FILL` / `BAR_BG` | `#a89984` / `#282828` @0.90 | ATB·바 배경 |
| `MAP_START` / `NORMAL` / `BOSS` / `LOCKED` | `#458588` / `#504945` / `#cc241d` / `#1d2021` | 맵·방. `MAP_START`는 DevOverlay 딤·테두리·제목 |
| `RARE_GLOW` | = `RARITY_RARE` | 호환 별칭 |

### 희귀도

| 단 | 토큰 | hex |
|----|------|-----|
| COMMON | `RARITY_COMMON` | `#7c6f64` |
| UNCOMMON | `RARITY_UNCOMMON` | `#b8bb26` |
| RARE | `RARITY_RARE` | `#83a598` |
| LEGENDARY | `RARITY_LEGENDARY` | `#fabd2f` |

호출은 `ItemData.color_for_rarity` / `item.get_rarity_color()`만. UI 위젯에 희귀도 match를 두지 않는다.

---

## Theme 복제

| 파일 | 맞춤 |
|------|------|
| [`ui/shared/themes/ui_theme.tres`](../../ui/shared/themes/ui_theme.tres) | 슬롯/장비 StyleBox + Label = `TEXT_MAIN`. 슬롯 테두리 2px, `anti_aliasing` off. 런타임은 duplicate 후 `border_color`만. |
| [`ui/inventory/themes/inventory_theme.tres`](../../ui/inventory/themes/inventory_theme.tres) | Label |
| [`ui/stats/themes/stats_theme.tres`](../../ui/stats/themes/stats_theme.tres) | 행 선택 + progress `GOLD` / `HP_FILL` |

씬 `theme_override_colors`는 에디터 미리보기용 bake. `_ready`에서 이미 덮는 곳은 런타임 `UIColors`가 우선.

## 선택 UI

왼쪽 선택·포커스 바 기하: [`ui/shared/ui_select_style.gd`](../../ui/shared/ui_select_style.gd) (`UISelectStyle`).  
색은 계속 `UIColors` (`SELECT_BORDER` / `GOLD` / idle). StyleBox를 화면마다 다시 만들지 않는다.

## 팝업 레이아웃

딤은 풀스크린. 패널은 중앙 Sheet/Dialog, 또는 플레이어 메뉴 풀스크린. 바깥 여백 ≥ `UIPopupLayout.MARGIN` (80) — Sheet/Dialog만.  
Sheet/Dialog는 `PanelContainer` + `UIPopupLayout.make_sheet_style()` (배경 `SLOT_BG_SOLID`, 테두리 `SLOT_BORDER` 무채색, content margin = `PANEL_BORDER` so 상·하 밴드가 테두리를 덮지 않음).  
본문 좌·우 컬럼은 `UIPopupLayout.make_column_panel_style()` (`PANEL_BG` + `SLOT_BORDER`, inset 16). 설정·인벤·맵·스탯·게시판·제단·서가·대장간. 컬럼 안 `ItemDetailPanel`은 `flatten_inner_panel`로 이중 테두리를 뺀다.  
Sheet 내부 **상·중·하**: 상단은 좌·우·상(테두리 안쪽) flush, 하단은 좌·우·하 flush. 중단만 `PANEL_INSET` + `clip_contents`. 상·하 높이 `BAND_HEIGHT` 72.

| 등급 | 크기 | 상수 | 예 |
|------|------|------|-----|
| Fullscreen | 뷰포트 | — | MenuShell 플레이어 메뉴 (인벤/맵/스탯/설정, TopBar 4탭) |
| Sheet | 1440×800 | `SHEET_SIZE` | 마을 게시판/제단/서가/대장간 (TopBar 4탭), 룻 선택, 타이틀 설정 |
| Dialog | 760×480 | `DIALOG_SIZE` | DevOverlay |

소스: [`ui/shared/ui_popup_layout.gd`](../../ui/shared/ui_popup_layout.gd).  
마을 `VillageShell`은 허브 크롬(상·하)만. 게시판/제단/서가/대장간은 MenuShell Sheet 4탭.
