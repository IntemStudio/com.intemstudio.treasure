# 스탯 UI

스탯 탭 본문 스펙. 전체화면 크롬(Overlay / TopBar / Footer / pause)은 [`ui/shell/menu_shell.tscn`](../../ui/shell/menu_shell.tscn)이 소유하고, 이 문서는 **Stats 콘텐츠 패널**만 다룹니다.

---

## 위치

| 역할 | 경로 |
|------|------|
| 셸 | [`ui/shell/menu_shell.tscn`](../../ui/shell/menu_shell.tscn) |
| 본문 | [`ui/stats/stats_content.tscn`](../../ui/stats/stats_content.tscn) + [`stats_content.gd`](../../ui/stats/stats_content.gd) |
| 테마 | [`ui/stats/themes/stats_theme.tres`](../../ui/stats/themes/stats_theme.tres) |
| 데이터 | [`ui/stats/resources/character_stats.gd`](../../ui/stats/resources/character_stats.gd), [`character_stats.tres`](../../ui/stats/resources/character_stats.tres) |
| 초상화 | [`ui/stats/shaders/hex_portrait.gdshader`](../../ui/stats/shaders/hex_portrait.gdshader) |

공통 TopBar / Footer: [`ui/shared/`](../../ui/shared/).

패널 계약: `setup(ui_manager, footer)` → `activate(stats, inventory)` / `deactivate()` → Esc·BACK 시 `request_close`.

---

## 화면 구성

| 영역 | 내용 |
|------|------|
| TopBar (셸) | 재화, `[인벤토리][맵][스탯][설정]`, 이름·레벨·XP·HP |
| Left | 초상화, Attribute Points, 속성 목록 (Health~Equip Load). Body 1/4 |
| Right | GENERAL / DEFENSE / WEIGHT 열(각 Body ~1/4) + 무기 데미지 테이블. Body 3/4 |
| Footer (셸) | LEVEL-UP / INSIGHT / BACK |

---

## 씬 트리 (콘텐츠)

```
StatsContent (Control, stats_theme)
└── Body (HBoxContainer)
    ├── LeftPanel
    │   ├── Portrait
    │   ├── PointsRow (< / Attribute Points / value / >)
    │   └── AttributeList
    └── RightPanel
        ├── Columns
        │   ├── GeneralCol
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
- **DEFENSE:** Armor / Poise / Heat / Cold / Electric / Plague  
- **WEIGHT:** max / current / class label / bar  
- **무기 테이블:** `stats.weapons` → Base / Attr Bonus / Other / Total  
- **푸터 액션:** `level_up`, `insight`, `close`  
- **새 캐릭터:** 레벨 1, XP 0 (`CharacterStats.apply_new_game_start`, `xp_to_next` = CSV 레벨 1 = 50)  
- **전투 XP:** 승리 시 `CharacterStats.add_xp` ([`combat.md`](combat.md)). HUD·스탯은 `UIManager.refresh_character_views`로 갱신  
- **입력:** 상하 속성 선택, Enter 투자, Insight, Esc → `request_close`

탭 전환은 Q/E·LB/RB → TopBar → `MenuShell`이 다른 콘텐츠를 `activate`합니다. Map은 순환 탭에 포함됩니다 (`TopBar.CYCLEABLE_TABS`).
