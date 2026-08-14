# 타이틀 + 프로필 선택

앱 진입(`run/main_scene`) 타이틀과 Hollow Knight 스타일 **프로필 선택** 스펙.  
인게임 [`menu_shell`](../../ui/shell/menu_shell.tscn)과 분리된 씬이며, pause 오버레이를 쓰지 않습니다.

세이브 슬롯 규칙은 [`save-load.md`](save-load.md)를 따릅니다 (`SaveManager.SLOT_COUNT = 4`).  
문구는 `tr()` + [`locale/ui_strings.csv`](../../locale/ui_strings.csv) (`LocaleManager`).

---

## 위치

| 역할 | 경로 |
|------|------|
| 타이틀 (main_scene) | [`scenes/title/title.tscn`](../../scenes/title/title.tscn) + [`title.gd`](../../scenes/title/title.gd) |
| 프로필 선택 | [`scenes/title/profile_select.tscn`](../../scenes/title/profile_select.tscn) + [`profile_select.gd`](../../scenes/title/profile_select.gd) |
| 슬롯 카드 | [`scenes/title/components/profile_slot.tscn`](../../scenes/title/components/profile_slot.tscn) + [`profile_slot.gd`](../../scenes/title/components/profile_slot.gd) |
| 설정 오버레이 | [`ui/settings/settings_content.tscn`](../../ui/settings/settings_content.tscn) + Footer ([`settings.md`](settings.md)) |
| 게임 진입 | [`scenes/village/village.tscn`](../../scenes/village/village.tscn) ([`village.md`](village.md)). 던전은 게시판 확정 후 ([`map.md`](map.md)) |
| UI 회귀 (수동) | [`scenes/ui_test.tscn`](../../scenes/ui_test.tscn) |
| 부트 로드 | [`ui/ui_manager.gd`](../../ui/ui_manager.gd) (`current_slot >= 0`이면 슬롯 로드) |

---

## 화면 구성

| 영역 | 내용 |
|------|------|
| Background | `UIColors.TEXT_INVERSE` (`#1d2021`) |
| Brand | 상단 중앙 게임명 (`TEXT_MAIN`) |
| MenuStack | **좌하단** Start / Settings / Quit |
| ProfileSelect | Start 시 전체 화면 — 가로 4슬롯 + 하단 Back |
| SettingsHost | Settings 시 딤 + settings_content + BACK |

---

## 씬 트리

```
Title (Control)
├── Background
├── BrandLabel
├── MenuAnchor (bottom-left)
│   └── MenuStack → Start / Settings / Quit
├── ProfileHost
│   └── ProfileSelect
│       ├── TitleLabel  # tr("Select Profile") → en / 프로필 선택
│       ├── SlotRow → ProfileSlot × SLOT_COUNT
│       └── BackButton  # tr("Back")
└── SettingsHost (CanvasLayer)
    ├── Dim
    └── SettingsRoot → SettingsBodyHost + SettingsFooterHost
```

---

## 컴포넌트

```
scenes/title/
  title.*
  profile_select.*
  components/
    profile_slot.*
```

---

## 플로우·조작

1. **Start** → 프로필 선택 (메뉴·브랜드 숨김)
2. **빈 슬롯** → `SaveManager.new_game(slot)` (레벨 1, XP 0) → `village.tscn`
3. **유효 슬롯** → `SaveManager.load_game(slot)` → `village.tscn`
4. **삭제(`× Delete` / `× 삭제`)** → 슬롯 내 2단 확인 → `delete_slot`
5. **Settings** → settings_content (게임 플레이/조작/디스플레이/오디오). 타이틀에서는 **나가기 탭 숨김**. 서브 탭은 `Q`/`E` ([`settings.md`](settings.md))
6. **Quit** → `get_tree().quit()`

| ProfileSlot 상태 | UI |
|------------------|-----|
| `empty` | 중앙 `New Game` / `새 게임` |
| `occupied` | `Level %d` / `레벨 %d` · 플레이 시간 · 푸터 삭제 버튼 (캐릭터 이름 메타 없음) |
| `confirm_delete_1` | `Delete the selected profile?` / `선택한 프로필을 지웁니까?` 예/아니요 |
| `confirm_delete_2` | `Continue?` / `계속합니까?` 예/아니요 |

### 플레이 시간·삭제 버튼

| 키 / 표시 | en | ko |
|-----------|----|----|
| 플레이 시간 `tr("%dH %dM")` | `1H 1M` | `1시간 1분` |
| 삭제 버튼 | `× Delete` | `× 삭제` (`tr("Delete")`) |

- 아니요 / `ui_cancel` → occupied 복귀. 예 → 1단→2단, 2단→삭제 후 empty  
- corrupt / incompatible: 로드 거부, 삭제는 가능 (`Corrupt`/`Incompatible` · `손상됨`/`호환되지 않음`)  
- **입력:** 타이틀 상하·Accept / 프로필 좌우·Accept·Cancel / 확인 중 예·아니요  

`UIManager`: `SaveManager.current_slot >= 0`이면 해당 슬롯 로드, `-1`이면 더미(에디터에서 dungeon/ui_test 직접 실행).

---

## 비범위

- 슬롯 스크린샷·마스크/재화 아이콘 실데이터  
- 타이틀 BGM, 종료 확인 팝업  
- 별도 `game.tscn` (플레이 허브는 [`village.md`](village.md), 던전은 도전 후)
