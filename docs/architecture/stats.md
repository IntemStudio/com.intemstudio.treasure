# 스탯 UI

스탯 탭 본문 스펙. 모달 크롬(Overlay / TopBar 제목 / Footer / pause, Sheet 1440×800)은 [`ui/shell/menu_shell.tscn`](../../ui/shell/menu_shell.tscn)이 소유하고, 이 문서는 **Stats 콘텐츠 패널**만 다룹니다. 단독 Sheet 팝업 (탭 순환 없음).

후속(Focus→Mana 라벨·무게 전투 보정): [`docs/design/stats.md`](../design/stats.md).  
기술 게이지·마나 자동 발동은 전투 ([`combat.md`](combat.md) · [`equipment.md`](equipment.md)).

**현황:** v1.1 — COMBAT 열·`CombatStatsBuilder` 표시 소스·Defense 키·Insight 토글.

---

## 위치

| 역할 | 경로 |
|------|------|
| 셸 | [`ui/shell/menu_shell.tscn`](../../ui/shell/menu_shell.tscn) |
| 본문 | [`ui/stats/stats_content.tscn`](../../ui/stats/stats_content.tscn) + [`stats_content.gd`](../../ui/stats/stats_content.gd) |
| 테마 | [`ui/stats/themes/stats_theme.tres`](../../ui/stats/themes/stats_theme.tres) |
| 데이터 | [`ui/stats/resources/character_stats.gd`](../../ui/stats/resources/character_stats.gd), [`character_stats.tres`](../../ui/stats/resources/character_stats.tres) |
| 합산 | [`data/combat/combat_stats_builder.gd`](../../data/combat/combat_stats_builder.gd) |
| 초상화 | [`ui/stats/shaders/hex_portrait.gdshader`](../../ui/stats/shaders/hex_portrait.gdshader) |

공통 TopBar / Footer: [`ui/shared/`](../../ui/shared/).

패널 계약: `setup(ui_manager, footer)` → `activate(stats, inventory)` / `deactivate()` → Esc·BACK 시 `request_close`.

---

## 화면 구성

| 영역 | 내용 |
|------|------|
| TopBar (셸) | 상단 밴드(72) — 제목만 |
| Body | 중단 밴드 — expand |
| Footer (셸) | 하단 밴드(72) — 프롬프트 |
| Left | 초상화, Attribute Points, 속성 목록 (Health~Equip Load), Insight 시 선택 속성 설명. Body 1/4 |
| Right | GENERAL / COMBAT / DEFENSE / WEIGHT + 무기 데미지 테이블. Body 3/4 |
| Footer (셸) | LEVEL-UP / INSIGHT / BACK |

---

## 씬 트리 (콘텐츠)

```
StatsContent (Control, stats_theme)
└── Body (HBoxContainer)
    ├── LeftPanel
    │   ├── Portrait
    │   ├── PointsRow (< / Attribute Points / value / >)
    │   ├── AttributeList
    │   └── InsightHint (선택 속성 설명, 토글)
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
└── Overlay → Root (margin 40) → Main
    ├── TopBar
    ├── BodyHost  ← InventoryContent / MapContent / StatsContent / SettingsContent
    └── Footer
```

---

## 컴포넌트

```
ui/stats/components/
  attribute_row.*
  stat_row.*
  weapon_stat_row.*
```

---

## 데이터·조작

- **속성:** `CharacterStats.ATTRIBUTE_IDS` (포인트 투자 시 선택 행 기준)
- **GENERAL:** Life / Stamina / Stamina Regen / Focus / Focus Gain
- **COMBAT:** `CombatStatsBuilder.build(stats, inventory)` — Damage, Attack Speed, Crit, Magic Damage, Damage to All, Vampirism, Regen, Counter, Evasion, Magic HP, Retaliation. 전투 조우와 **같은** 빌더
- **DEFENSE:** Defense (빌더 값). Poise·원소는 표시하지 않음
- **Insight:** X로 토글. 왼쪽 목록에서 고른 속성이 올리는 능력치 (`ATTR_DESC_*`)
- **WEIGHT:** max / current / class label / bar — `weight_current`는 빌더가 장착 무게로 동기화
- **무기 테이블:** 빌더가 장착 무기 행으로 `stats.weapons`를 덮어씀
- **푸터 액션:** `level_up`, `insight`(로컬 토글), `close`
- **새 캐릭터:** 레벨 1, XP 0 (`CharacterStats.apply_new_game_start`, `xp_to_next` = CSV 레벨 1 = 50)
- **전투 XP:** 승리 시 `CharacterStats.add_xp` ([`combat.md`](combat.md)). HUD·스탯은 `UIManager.refresh_character_views`로 갱신
- **입력:** 상하 속성 선택, Enter 투자, Insight, Esc → `request_close`

탭 전환은 없다 — 인벤/맵/스탯/설정은 각각 단독 Sheet. Map은 HUD 미니맵·메뉴에서 `open_tab(MAP)`으로만 연다.
