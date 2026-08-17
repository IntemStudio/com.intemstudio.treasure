# 분지 수색 / 이름돌 / 제단 아래

**세계관:** [`world.md`](world.md) (시점만. 이 문서가 시스템).  
**현황:** 게시판 = 분지 나침반 + 이름돌, 인카운터 = `dungeon_id`+`zone_id`, 보스 승리 = `unlock_next` 후 마을. 제단 아래 = 결말 3택.  
허브: [`village.md`](village.md). 서가: [`bookshelf.md`](bookshelf.md). 세이브: [`save-load.md`](save-load.md) · [`architecture/save-load.md`](../architecture/save-load.md). 전투: [`combat.md`](combat.md) · [`architecture/combat.md`](../architecture/combat.md). 룻: [`loot.md`](loot.md). 층: [`map.md`](map.md).

---

## 한 줄

소문 Sheet에서 **이름돌 점**을 고르면 그 **구역 하나**를 생성한다. 구절 셋을 읽으면 **제단 아래**가 열린다. 그 승리 후 결말 세 갈래. 길이 열은 접는다.

---

## 확정 결정

| # | 결정 |
|---|------|
| 1 | 새 Autoload·Sheet·퀘스트 로그 없음. `ChallengeBoard` + `SaveManager.meta` + `RegionEncounters` + `GameLog` + 룻 오버레이 자리. |
| 2 | 이야기 게이트 = `verses_read`. 룻 게이트 = `open_cards`. 합치지 않음. |
| 3 | `ChallengeDef.LENGTHS` / `length_id` / `reward_mult` **폐기**. 런 키는 `dungeon_id` + `zone_id`. |
| 4 | 한 원정 = 한 구역. 생성기는 현행 `FloorMap.generate(seed, room_count)`. `RoomType` 추가 없음. 이름돌 = 그 구역 `START`. |
| 5 | 이름돌·구절은 **메타**. 전멸·보스 귀환 후에도 남음. 런 JSON에 두지 않음. |
| 6 | Map 탭 = 같은 구역 안 방 이동. 이름돌 선택은 게시판만. |
| 7 | 구절은 상처당 한 줄. 중간 구역 `START` 입장 시 1회. 로그 + 우패널. 컷신·저널 탭 없음. |
| 8 | `verses_read` 고유 `dungeon_id` ≥ 3 → 게시판 가운데 `altar_below` 점. 넷 다 필요 없음. |
| 9 | 교차 소문 = locale 키 분기만. 새 씬·새 방 타입 없음. |
| 10 | 제단 아래 보스 승리 → 즉시 `return_to_village` 하지 않음. 결말 3택 후 마을. |
| 11 | 결말 조건은 이 문서. 엔딩 전용 타이틀 씬은 후속. |
| 12 | 서비스는 `RefCounted` 하나 (`BasinProgress`, `CardRegistrationService`와 동형). Autoload 금지. |

---

## 로드맵

| 단계 | 범위 | 선행 |
|------|------|------|
| **basin.zones** | `zone_id`, 길이 열 삭제, 입구만 선택, 클리어 시 다음 돌, 구역 인카운터 비중, 위치 카피 | **구현됨** |
| **basin.verse** | 중간 `START`에서 구절, `verses_read`, 로그·우패널 | **구현됨** |
| **basin.altar** | 3행 → `altar_below` 점·런 | **구현됨** |
| **basin.map** | 소문 Sheet를 분지 점으로 (같은 데이터) | **구현됨** |
| **basin.cross** | 설명 키 분기 | **구현됨** |
| **basin.ending** | 제단 아래 승리 3택 | **구현됨** |

`basin.zones`만으로 플레이 가능. 이야기 본체는 verse+altar. 지도는 나침반.

---

## ID

### 상처 (`dungeon_id`)

`cemetery` · `grove` · `mansion` · `battlefield` · `altar_below`

`altar_below`는 `RegionEncounters.normalize_region` 기본값(묘지)으로 떨어지면 안 된다. 테이블에 별도 항.

### 구역 (`zone_id`)

| dungeon_id | 깊이 | zone_id | room_count | 구절 | 수호자 |
|------------|------|---------|------------|------|--------|
| cemetery | 입구 | `graves` | 8 | 아니오 | 아니오 |
| cemetery | 중간 | `ossuary` | 8 | **예** | 아니오 |
| cemetery | 심층 | `crypt` | 8 | 아니오 | 아니오 |
| cemetery | 수호자 | `bone_altar` | 6 | 아니오 | 뼈 수호자 |
| grove | 입구 | `path` | 8 | 아니오 | 아니오 |
| grove | 중간 | `thicket` | 8 | **예** | 아니오 |
| grove | 심층 | `roots` | 8 | 아니오 | 아니오 |
| grove | 수호자 | `mother_tree` | 6 | 아니오 | 둥지 어미 |
| mansion | 입구 | `garden` | 8 | 아니오 | 아니오 |
| mansion | 중간 | `servants` | 8 | **예** | 아니오 |
| mansion | 심층 | `hall` | 8 | 아니오 | 아니오 |
| mansion | 수호자 | `lord_chamber` | 6 | 아니오 | 뱀파이어 군주 |
| battlefield | 입구 | `field` | 8 | 아니오 | 아니오 |
| battlefield | 중간 | `camp` | 8 | **예** | 아니오 |
| battlefield | 심층 | `trench` | 8 | 아니오 | 아니오 |
| battlefield | 수호자 | `war_altar` | 6 | 아니오 | 전쟁 망령 |
| altar_below | — | `mouth` | 8 | 아니오 | 제단 아래 보스 |
| altar_below | 비움 | `mouth_deep` | 12 | 아니오 | 같은 보스, 강화 풀 |

다음 돌: 입구 → 중간 → 심층 → 수호자. 수호자 다음은 없음.

키: `"cemetery:ossuary"`. `name_stones[]`에 이 문자열.

---

## 메타 (`slot_N.json` `meta`)

서가 키는 유지. `CardRegistrationService.ensure_meta` 또는 `BasinProgress.seed_meta`가 아래를 시드. 슬롯 저장 경로는 현행 [`architecture/save-load.md`](../architecture/save-load.md).

```text
name_stones[]     # "dungeon_id:zone_id"
verses_read[]     # dungeon_id  (cemetery|grove|mansion|battlefield)
ending            # "" | take | seal | empty
altar_emptied     # bool
```

**새 게임 시드**

```text
name_stones = [
  cemetery:graves, grove:path, mansion:garden, battlefield:field
]
verses_read = []
ending = ""
altar_emptied = false
```

구키 `length_id`는 런에만 있었다. 메타 마이그레이션 없음. 옛 런 파일은 마을 복귀 시 삭제되므로 무시.

`ending == seal`이면 `verses_read.size() >= 3`이어도 `altar_below` 점을 열지 않음.

---

## 런 (`slot_N_run.json`)

| 키 | 내용 |
|----|------|
| `dungeon_id` | 상처 또는 `altar_below` |
| `zone_id` | 위 표 |
| `seed` / `room_count` | 현행 |
| `current` / `visited` / `cleared` | 현행 |
| `runes` / `gems` / `socketed` | 현행 |

`length_id` / `reward_mult` 쓰지 않음. `SaveManager.save_run`에 남아 있으면 버려도 됨.

```
ChallengeDef.build_run_params(dungeon_id, zone_id, seed=-1) -> Dictionary
```

에디터에서 `dungeon.tscn` 직접 실행: `cemetery` + `graves` + `randi()` + 8방.

---

## 게시판

`ChallengeBoard`: 분지 나침반 + **해금된 이름돌**. 길이 열 없음.

- 나침반: 북 `cemetery` · 서 `grove` · 동 `mansion` · 남 `battlefield`. 가운데 = `altar_below` 또는 `SHELTER_LABEL`.
- 잠긴 돌: 목록에 없음. 포커스 불가.
- `altar_below` 점: `BasinProgress.can_open_altar(meta)`일 때만.
- CHALLENGE: `set_pending_run` + `save_run` + `dungeon.tscn` (현행).
- 우패널: 구역 제목·설명. `verses_read`에 있는 행은 구절을 그대로 표시. 안 읽은 행은 안개.
- 가운데 잠김 카피: `QUESTION_FOG` = 이 쉼터는 무엇을 덮고 있는가.

`can_open_altar(meta)`:

```text
ending != "seal"
AND not altar_emptied
AND verses_read 고유 dungeon_id >= 3
```

`ending == empty`이고 `altar_emptied == false`면 점은 `mouth_deep`. 그 런을 이기면 `altar_emptied = true` (take여도 점 닫힘).

---

## 이름돌 해금

구역 **보스 방 승리** + 룻 확정 후 `return_to_village` 직전에:

```
BasinProgress.unlock_next(meta, dungeon_id, zone_id)
```

입구/중간/심층만 다음 돌을 `name_stones`에 추가. 이미 있으면 no-op.

전멸·후퇴: 다음 돌 없음. 이미 읽은 구절은 유지.

수호자 승리: 다음 돌 없음. 마을.

제단 아래: 해금 없음. 결말 3택.

---

## 구절

`EncounterDirector.on_room_entered`: `START`는 전투 스킵 유지.

그 직후 `dungeon.gd` `_try_read_verse`: 중간 구역이면:

```text
if zone.has_verse and dungeon_id not in verses_read:
    verses_read.append(dungeon_id)
    GameLog: VERSE_LINE_*
    save_to_slot   # 런 중에도 메타. 방 이동 시 런만 쓰는 현행과 다름
```

구절을 런 중에 잃으면 안 된다. 중간 `START` 입장 시 메타를 같이 쓴다.

말투 고정 ([`world.md`](world.md) 15번). locale 값, 키만 신규:

| 키 | ko |
|----|----|
| `VERSE_LINE_CEMETERY` | 이름을 남기면 잠든다 |
| `VERSE_LINE_GROVE` | 덮이면 잊힌다 |
| `VERSE_LINE_MANSION` | 피로 붙들면 내 것이 된다 |
| `VERSE_LINE_BATTLEFIELD` | 갈리면 깨어난다 |

우패널은 `verses_read` 순서대로 이 네 키. 안 읽은 행은 안개.

셋 모인 뒤 게시판을 열면 가운데 점. 로그: `QUESTION_OPEN`.

---

## 인카운터

`RegionEncounters.load_pair(dungeon_id, zone_id)` → `{normal, boss}`.

- 입구·중간·심층: 기존 지역 `normal.tres` 재사용 가능. **보스 방만** 입구=약한 믹스, 심층=정예 믹스. 새 유닛 없음.
- 수호자 구역: NORMAL = 그 지역 심층 믹스, BOSS = 현행 `encounters/{region}/boss.tres`.
- `altar_below` / `mouth`: 새 `encounters/altar_below/normal.tres` + `boss.tres`. 보스는 기존 유닛 조합으로 시작해도 됨 (새 스프라이트 후속).
- `mouth_deep`: 같은 보스 유닛, `enemy_level` 4 (`mouth`는 3). 세션·HUD에서 곱하지 않음. EncounterDef에서만.

폴백: 모르는 id → `cemetery` + `graves`.

---

## 위치 HUD

`LOCATION_VILLAGE` 유지.

던전: `tr(ZONE_TITLE_{DUNGEON}_{ZONE})` 예: 묘지 · 납골당.  
제단 아래: `LOCATION_ALTAR_BELOW` = 제단 아래.

`dungeon.gd` → `UIManager.bind_dungeon(..., location_key)`. 방 타입(Entrance/Boss)으로 덮지 않음.

---

## 교차 소문 (`basin.cross`)

새 콘텐츠 없음. `ChallengeBoard` 상세 `desc_key`만.

규칙 (하드코드 표, 최대 4행):

| 보는 구역 | 조건 | desc_key |
|-----------|------|----------|
| `mansion:garden` | `cemetery` ∈ verses_read | `ZONE_DESC_MANSION_GARDEN_X_CEMETERY` |
| `grove:path` | `battlefield` ∈ verses_read | `ZONE_DESC_GROVE_PATH_X_BATTLEFIELD` |
| `cemetery:graves` | `mansion` ∈ verses_read | `ZONE_DESC_CEMETERY_GRAVES_X_MANSION` |
| `battlefield:field` | `grove` ∈ verses_read | `ZONE_DESC_BATTLEFIELD_FIELD_X_GROVE` |

조건 미충족 시 기본 `ZONE_DESC_*`.

---

## 결말 (`basin.ending`)

제단 아래(`mouth` 또는 `mouth_deep`) **보스 승리** 후.

1. 현행 3택1 **하지 않음**. 룻 오퍼 1장 고정.
2. 템플릿: 기존 룬 `sanctum_verse` (Rune of the Sanctum). 새 「유물」 id 없음. 이미 봉인·보유여도 인스턴스 1개 추가 시도. 가방 가득이면 Take만 막고 Seal/Empty는 인스턴스 없이 불가 → 로그 `BAG_FULL` 후 마을(엔딩 미기록). 이 코너만 예외.
3. 오버레이 버튼 3. 룻 카드와 같은 CanvasLayer.

| id | 가능 | 효과 |
|----|------|------|
| `take` | 인스턴스를 인벤 `runes`에 넣음 | `ending=take`. 점 유지. 마을 |
| `seal` | `CardRegistrationService` 봉인 (재봉인 불가 규칙 그대로. 이미 REGISTERED면 이 버튼 숨김) | `ending=seal`. `name_stones` 입구 4개로 리셋. `altar_below` 점 닫음. `verses_read` 유지하되 점은 `ending`으로 닫음. 마을 |
| `empty` | `open_cards.size() >= EMPTY_OPEN_MIN` AND `not altar_emptied` AND 이번 런이 `mouth` (deep 아님) AND 인스턴스를 **봉인하지 않음** (가방에 남김) | `ending=empty`. `altar_emptied`는 아직 false. 마을. 점만 `mouth_deep`으로 |

`EMPTY_OPEN_MIN = 12`.

`mouth_deep` 승리 후: `empty` 버튼 없음. `take` / `seal`만. 이기면 `altar_emptied=true`.

엔딩 씬 없음. 로그 `ENDING_TAKE` / `ENDING_SEAL` / `ENDING_EMPTY`.

---

## 서비스 API

[`data/village/basin_progress.gd`](../../data/village/basin_progress.gd) — `class_name BasinProgress extends RefCounted`.

```
seed_meta(meta) -> Dictionary
stone_key(dungeon_id, zone_id) -> String
is_stone_open(meta, dungeon_id, zone_id) -> bool
list_open_stones(meta) -> Array[Dictionary]  # {dungeon_id, zone_id}
unlock_next(meta, dungeon_id, zone_id) -> Dictionary
try_read_verse(meta, dungeon_id, zone_id) -> bool   # true면 이번이 첫 읽기
can_open_altar(meta) -> bool
altar_zone_id(meta) -> String   # mouth | mouth_deep
apply_ending(meta, ending_id) -> Dictionary
can_empty(meta, zone_id) -> bool
mark_altar_deep_cleared(meta) -> Dictionary
```

`SaveManager`는 카드 메타처럼 get/set만. 로직은 서비스.

검증: [`data/village/verify_basin_progress.gd`](../../data/village/verify_basin_progress.gd) (headless SceneTree).  
체크: 시드 4입구, 입구 클리어→중간, 구절 중복 없음, 3행→altar, seal→점 닫힘, empty 조건.

---

## 카피 키

`REGION_*` 유지. 길이 키(`CHALLENGE_SHORT` 등)는 UI에서 제거. csv 행은 남겨 둠.

`ZONE_TITLE_*`, `ZONE_DESC_*`, `VERSE_LINE_*`, `QUESTION_FOG`, `QUESTION_OPEN`, `LOCATION_ALTAR_BELOW`, `ENDING_TAKE` / `SEAL` / `EMPTY`, 교차 desc.

세계관 말: 웨이포인트·퀘스트·유물·Embark 금지 — [`world.md`](world.md).

---

## 구현 위치

| 파일 | 일 |
|------|----|
| [`data/village/challenge_def.gd`](../../data/village/challenge_def.gd) | 구역 표, `build_run_params` |
| [`data/village/basin_progress.gd`](../../data/village/basin_progress.gd) | 메타 게이트 |
| [`autoload/save_manager.gd`](../../autoload/save_manager.gd) | `META_KEYS` 복사 · `seed_meta` |
| [`ui/village/challenge_board.gd`](../../ui/village/challenge_board.gd) + tscn | 나침반 + 이름돌 |
| [`data/combat/region_encounters.gd`](../../data/combat/region_encounters.gd) | `load_pair(dungeon_id, zone_id)` |
| [`world/combat/encounter_director.gd`](../../world/combat/encounter_director.gd) | `zone_id` · `unlock_next` · 결말 |
| [`scenes/dungeon/dungeon.gd`](../../scenes/dungeon/dungeon.gd) | `zone_id`, 위치, `try_read_verse` + `save_to_slot` |
| [`ui/loot/ending_choice_overlay.tscn`](../../ui/loot/ending_choice_overlay.tscn) | take / seal / empty |
| [`locale/ui_strings.csv`](../../locale/ui_strings.csv) | 구역·구절·결말 |
| [`architecture/village.md`](../architecture/village.md) · [`save-load.md`](../architecture/save-load.md) · [`combat.md`](../architecture/combat.md) | 현황 |

---

## 비목표

- 퀘스트 로그, NPC, 분지 보행, 새 CanvasLayer 허브
- `RoomType.NAME_STONE` / 특수 방
- 길이 열과 이름돌 병행
- 이야기 XP·날짜·평판
- 제단 아래를 다섯 번째 `REGIONS` 행으로 일반 상처와 섞기 (점은 게이트)
- 결말용 새 아이템 id·「유물」
- 이어하기 던전 복귀 (현행 후속 유지)

---

## 관련

| 문서 | 연결 |
|------|------|
| [`world.md`](world.md) | 분지·질문·구절·결말 시점 |
| [`village.md`](village.md) | 소문 Sheet·허브 |
| [`bookshelf.md`](bookshelf.md) | `open_cards` · 봉인 |
| [`save-load.md`](save-load.md) | 메타/런 |
| [`combat.md`](combat.md) | 보스 승리·마을 복귀 |
| [`loot.md`](loot.md) | 3택1. 제단 아래는 1장+결말 |
| [`map.md`](map.md) | 구역 안 방 격자 |
| [`architecture/village.md`](../architecture/village.md) | 현행 게시판 |
