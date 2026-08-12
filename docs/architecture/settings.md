# 게임 설정

환경 설정 UI와 `user://settings.cfg` 영속화 **v1 구조**.  
설계·로드맵: [`docs/design/settings.md`](../design/settings.md)

---

## 위치

| 역할 | 경로 |
|------|------|
| Autoload | [`autoload/settings_manager.gd`](../../autoload/settings_manager.gd) |
| 언어 | [`autoload/locale_manager.gd`](../../autoload/locale_manager.gd) (번역·`set_language`; locale 저장은 SettingsManager) |
| UI | [`ui/settings/settings_content.tscn`](../../ui/settings/settings_content.tscn) |
| 행 컨트롤 | [`settings_cycle_row.gd`](../../ui/settings/components/settings_cycle_row.gd) · [`settings_toggle_row.gd`](../../ui/settings/components/settings_toggle_row.gd) · [`settings_slider_row.gd`](../../ui/settings/components/settings_slider_row.gd) |
| 오디오 버스 | [`default_bus_layout.tres`](../../default_bus_layout.tres) (Master / Music / SFX) |
| 폰트 | [`assets/fonts/KR/NotoSansKR-Regular.ttf`](../../assets/fonts/KR/NotoSansKR-Regular.ttf), [`NotoSerifKR-Regular.otf`](../../assets/fonts/KR/NotoSerifKR-Regular.otf) |
| 진입 | MenuShell Settings 탭, 타이틀 SettingsHost |
| 타이틀 복귀 | [`ui/ui_manager.gd`](../../ui/ui_manager.gd) `return_to_title()` |

세이브 슬롯 UI는 설정에 없음 → [`title.md`](title.md) 프로필 선택.

---

## 설정 파일

경로: `user://settings.cfg` ([`save-load.md`](save-load.md) 레이어 3).

| 섹션 | 키 | 기본 |
|------|-----|------|
| ui | locale | en |
| ui | font_family | `sans` (`sans` / `serif`) |
| display | width, height | 아래 **첫 실행 기본값** |
| display | mode | 아래 **첫 실행 기본값** |
| display | vsync | true |
| display | max_fps | 0 (후보 0/30/60/120/144) |
| audio | master, music, sfx | 1.0 |
| audio | background | false |

### 첫 실행 기본값 (`settings.cfg` 없을 때)

`SettingsManager`가 `OS.has_feature("editor")`로 분기한다. 이미 cfg가 있으면 저장값이 우선.

| 환경 | width × height | mode |
|------|----------------|------|
| 에디터 (F5) | 1600 × 900 | `window` |
| 빌드(내보내기) | 1920 × 1080 | `fullscreen` |

`project.godot`: 뷰포트는 1920×1080(디자인 기준), `window_*_override`는 1600×900(에디터 기동 창). 부트 후 `apply_all`이 cfg/기본값을 적용한다.

부트: SettingsManager `load_settings` → `apply_all`.  
`background=false`이면 앱 포커스 아웃 시 Master 뮤트.

---

## UI 구조

```
SettingsContent
├── SubTabRow → [Q]/[1] · SubTabs · [E]/[3]   # 타이틀 Q/E, 인게임 1/3
├── SettingsSplit                      # 게임플레이·조작·디스플레이·오디오
│   ├── LeftColumn → 탭별 패널(행)
│   ├── VSeparator
│   └── RightColumn → DetailTitle · DetailBody
└── ExitPanel                          # 나가기 전용
    ├── ExitList
    ├── VSeparator
    └── ExitDetail → 제목 · 본문 · 예/아니요
```

| 탭 | 좌 | 우 |
|----|----|----|
| 게임 플레이 | UI 섹션 + 언어·폰트 사이클 | `SETTINGS_DESC_LANGUAGE` / `SETTINGS_DESC_FONT` |
| 조작 | “준비 중” | `SETTINGS_DESC_CONTROLS` |
| 디스플레이 | 해상도·모드·VSync·프레임률 | 항목별 `SETTINGS_DESC_*` |
| 오디오 | 전체·음악·음향·백그라운드 | 항목별 `SETTINGS_DESC_*` |
| 나가기 | 목록 | 제목·설명(+확인 시 예/아니요) |

- **토글:** 체크박스(□/✓) + 켜기/끄기 (`SettingsToggleRow`)
- **사이클 / 슬라이더:** `SettingsCycleRow` / `SettingsSliderRow`
- 타이틀(`ui_manager == null`): **메인 메뉴로 나가기** 숨김
- **서브 탭 순환** (`_is_in_game()` = `ui_manager != null`):

| 진입 | 키캡 | InputMap |
|------|------|----------|
| 타이틀 | `Q` / `E` | `ui_nav_prev_tab` / `ui_nav_next_tab` |
| 인게임 | `1` / `3` | `inventory_category_prev` / `next` |

  인게임에서 Q/E는 MenuShell TopBar 탭용으로 남긴다. 푸터: BACK

---

## 로드·순환 의존

`UIManager` → MenuShell → `settings_content` → `UIManager` 타입 참조로 **const preload 순환**이 나면 PackedScene이 비어 Settings가 안 뜬다.  
v1은 MenuShell 본문·UIManager 셸·타이틀 설정을 **`load(path)` 시점 로드**로 끊는다.

---

## 나가기 흐름

```
Exit 확인(예)
  ├─ return_title → UIManager.return_to_title()
  │     close_all → paused=false → current_slot=-1 → title.tscn
  └─ quit_desktop → get_tree().quit()
```

---

## API 요지

```
SettingsManager.set_resolution / set_display_mode / set_vsync / set_max_fps
SettingsManager.set_master_volume / set_music_volume / set_sfx_volume / set_background_audio
SettingsManager.set_font_family  # sans | serif → ThemeDB + ui themes
SettingsManager.get_locale / set_locale
UIManager.return_to_title()
LocaleManager.set_language(code)  # persist → SettingsManager
```

번역: [`locale/ui_strings.csv`](../../locale/ui_strings.csv) (탭·항목·`SETTINGS_DESC_*`·나가기).
