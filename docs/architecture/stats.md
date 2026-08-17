# 스탯 UI

스탯 탭 본문 스펙. 모달 크롬(Overlay / TopBar 4탭 / Footer / pause)은 [`ui/shell/menu_shell.tscn`](../../ui/shell/menu_shell.tscn)이 소유하고, 이 문서는 **Stats 콘텐츠 패널**만 다룹니다. 인벤·맵·스탯·설정은 하나의 풀스크린 플레이어 메뉴.

후속(Focus→Mana 라벨·무게 전투 보정): [`docs/design/stats.md`](../design/stats.md).  
기술 게이지·마나 자동 발동은 전투 ([`combat.md`](combat.md) · [`equipment.md`](equipment.md)).

**현황:** v1.1 — COMBAT 열·`CombatStatsBuilder` 표시 소스·Defense 키·속성·부가 스탯 설명 상시.

---

## 위치

| 역할 | 경로 |
|------|------|
| 셸 | [`ui/shell/menu_shell.tscn`](../../ui/shell/menu_shell.tscn) |
| 본문 | [`ui/stats/stats_content.tscn`](../../ui/stats/stats_content.tscn) + [`stats_content.gd`](../../ui/stats/stats_content.gd) |
| 테마 | [`ui/stats/themes/stats_theme.tres`](../../ui/stats/themes/stats_theme.tres) |
| 데이터 | [`ui/stats/resources/character_stats.gd`](../../ui/stats/resources/character_stats.gd), [`character_stats.tres`](../../ui/stats/resources/character_stats.tres) |
| 합산 | [`data/combat/combat_stats_builder.gd`](../../data/combat/combat_stats_builder.gd) |
| 검증 | [`data/combat/verify_combat_stats_builder.gd`](../../data/combat/verify_combat_stats_builder.gd) (`STAT_DESC_*` 키 포함) |
| 초상화 | [`ui/stats/shaders/hex_portrait.gdshader`](../../ui/stats/shaders/hex_portrait.gdshader) |
| 문구 | [`locale/ui_strings.csv`](../../locale/ui_strings.csv) — `ATTR_DESC_*` · `STAT_DESC_*` |

공통 TopBar / Footer: [`ui/shared/`](../../ui/shared/).

검증: `godot --headless --path . -s res://data/combat/verify_combat_stats_builder.gd`

패널 계약: `setup(ui_manager, footer)` → `activate(stats, inventory)` / `deactivate()` → Esc·BACK 시 `request_close`.

---

## 화면 구성

| 영역 | 내용 |
|------|------|
| TopBar (셸) | 상단 밴드(72) — `[인벤토리] [맵] [스탯] [설정]` + 재화·체력 |
| Body | 중단 밴드 — expand |
| Footer (셸) | 하단 밴드(72) — 프롬프트 |
| Left | 초상화(`icon.svg`), Attribute Points, 속성 목록 (Health~Equip Load, 시트 아이콘), 선택 속성 또는 부가 스탯 설명. Body 1/4 |
| Right | GENERAL / COMBAT / DEFENSE / WEIGHT + 무기 데미지 테이블. Body 3/4 |
| Footer (셸) | LEVEL-UP / BACK |

---

## 씬 트리 (콘텐츠)

```
StatsContent (Control, stats_theme)
└── Body (HBoxContainer)
    ├── LeftPanel
    │   ├── Portrait
    │   ├── PointsRow (< / Attribute Points / value / >)
    │   ├── AttributeList
    │   └── InsightHint (선택 속성 또는 부가 스탯 설명)
    └── RightPanel
        ├── Columns
        │   ├── GeneralCol
        │   ├── CombatCol
        │   ├── DefenseCol
        │   └── WeightCol (max / current / class / bar)
        └── WeaponTable
            ├── Header (Weapon / Base / Attr Bonus / Other / Total)
            └── WeaponRows
```

셸 쪽:

```
MenuShell (CanvasLayer)
└── Overlay → Safe → Center → Sheet (플레이어 메뉴는 뷰포트 크기)
    └── Main
        ├── TopBar          # [인벤토리] [맵] [스탯] [설정]
        ├── BodyHost
        └── Footer
```

---

## 컴포넌트

```
ui/stats/components/
  attribute_row.*   # 투자 행. AttributeRow / Hover / Selected
  stat_row.*        # GENERAL/COMBAT/DEFENSE. 같은 variation 재사용
  weapon_stat_row.*
```

---

## 데이터·조작

- **속성:** `CharacterStats.ATTRIBUTE_IDS` (포인트 투자 시 선택 행 기준). 행 아이콘은 `StatsContent._attribute_icon` → `ItemData.sheet_icon` ([`inventory.md`](inventory.md) 아이콘). 초상화는 `icon.svg`
- **GENERAL:** Life / Stamina / Stamina Regen / Focus / Focus Gain
- **COMBAT:** `CombatStatsBuilder.build(stats, inventory)` — Damage, Attack Speed, Crit Chance, Crit Damage, Magic Damage, Damage to All, Vampirism, Regen, Counter, Evasion, Magic HP, Retaliation. 전투 조우와 **같은** 빌더. 무기 피해만 속성 스케일, 나머지 필드는 갑옷·접두사
- **DEFENSE:** Defense (빌더 값). Poise·원소는 표시하지 않음
- **설명:** 왼쪽 `InsightHint` 상시. 속성 = `ATTR_DESC_*`, 부가 = `STAT_DESC_*` (수식 숫자는 적지 않음). Insight 토글·푸터 X·`stats_insight` 없음
- **투자 vs 열람:** 왼쪽 선택 행이 포인트 대상. GENERAL/COMBAT/DEFENSE를 고르면 설명만 바뀜. Enter / LEVEL-UP은 왼쪽 속성에 투자
- **WEIGHT:** max / current / class label / bar — `weight_current`는 빌더가 장착 무게로 동기화. 설명 열람 없음 (전투 보정은 설계 v2)
- **무기 테이블:** 빌더가 장착 무기 행으로 `stats.weapons`를 덮어씀. 설명 열람 없음
- **푸터 액션:** `level_up`, `close`
- **새 캐릭터:** 레벨 1, XP 0 (`CharacterStats.apply_new_game_start`, `xp_to_next` = CSV 레벨 1 = 50)
- **전투 XP:** 승리 시 `CharacterStats.add_xp` ([`combat.md`](combat.md)). HUD·스탯은 `UIManager.refresh_character_views`로 갱신
- **입력:** 상하 = 현재 열(속성 또는 부가). 좌우 = 속성 ↔ GENERAL ↔ COMBAT ↔ DEFENSE. 마우스 호버/클릭 `StatRow` = 부가 설명. Enter 투자, Esc → `request_close`

Q/E·LB/RB로 인벤/맵/스탯/설정 탭 전환. Map은 HUD 미니맵·`[맵]`·메뉴 탭에서 `open_tab(MAP)`.
