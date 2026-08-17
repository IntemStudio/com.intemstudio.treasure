# 장비 · 룬 · 보석 · 공명 — 후속 설계

**현황(구조):** [`docs/architecture/equipment.md`](../architecture/equipment.md).  
이 문서는 **미구현** 로드맵만 다룬다 (패시브 전투 훅, 특수 방). 소켓·인벤 UI·서가는 구현됨. `eq.economy`(희귀도=소켓)는 **폐기**.

관련: [`world.md`](world.md) (단독 사냥꾼·룬·보석·등록=이름 남기기) · [`altar.md`](altar.md) (제단 봉인) · [`bookshelf.md`](bookshelf.md) (서가·open_cards) · [`stats.md`](stats.md) (접두사·기술 게이지) · [`combat.md`](combat.md) (세션은 결과만 소비) · [`hud.md`](hud.md) (장착 룬 0~6) · [`save-load.md`](save-load.md) (메타/런) · [`village.md`](village.md) (등록은 허브) · [`map.md`](map.md) (특수 방은 v2) · [`loot.md`](loot.md) (방 클리어 장비) · [`shop.md`](shop.md) (골드 가격. 소켓 수와 분리).

---

## 한 줄

장비는 기존 `ItemData`를 유지하고, 룬·보석은 별도 가방에서 부위 소켓을 채우며, 공명은 빌더와 분리된 서비스가 계산한다. 카드 등록은 마을 메타다.

---

## 확정 결정

| # | 결정 |
|---|------|
| 1 | 룬·보석은 `InventoryData.runes` / `gems`에 둔다. `ItemCategory`와 분리. 장비는 탭별 `bags` 5×5. |
| 2 | `ItemData`는 기존 필드 유지. `socket_layout`, 호환 태그, `intrinsic_effects`만 추가. `AttackData` / `SkillData` / `AffixData` 승격은 이 시스템의 전제가 아니다. |
| 3 | 소켓 수는 **부위 고정** (`SocketLayout.for_slot`). 희귀도는 색·접두사·상점가만. 액티브 룬(`strike`/`combo`/`aoe`)은 `main_hand` 세트 2. 패시브는 `off_hand`·머리·가슴·다리. HUD는 `list_equipped_rune_skills` (꽂힌 룬 0~6). 게이지는 액티브만. |
| 4 | 던전은 획득·장착·보관만. 카드 등록(봉인)은 마을 **제단**만. |
| 5 | 기술 게이지·마나([`stats.md`](stats.md) v1.3)를 룬 발동보다 먼저. 런 JSON([`save-load.md`](save-load.md) v2)을 소켓 디스크 저장보다 먼저. |
| 6 | 접두사만 `CombatStats` 수치. 보석은 기술 플래그·조건·원소 행동. `CombatStatsBuilder.AFFIX_FIELDS`를 보석이 더하지 않는다. |
| 7 | `eq.economy` 폐기. 희귀도로 칸을 바꾸지 않는다. 인챈트·넘친 소켓 가방 반환은 YAGNI. 접두사 롤은 [`loot.md`](loot.md) v2. |

NRFW에서 가져오지 않은 것: 희귀도=슬롯 구성, Focus 바, 패링, 얼굴 버튼 룬, 추출 시 장비 파괴.

---

## 로드맵

| 단계 | 범위 | 상태 | 선행 |
|------|------|------|------|
| 현황 | `ItemData`, `affixes` 합산, HUD 장착 룬 0~6 | 구현됨 → 구조 문서 | — |
| **선행 A** | 기술 게이지 + 마나 자동 발동 | 구현됨 | 이름만 있는 `skills`로 검증 |
| **eq.sockets** | `SocketLayout.for_slot`. 전투 변화 없음 | 구현됨 | — |
| **eq.runes** | `RuneData`, `InventoryData.runes`, 액티브/패시브 부위 | 구현됨 | 선행 A |
| **eq.gems** | `GemData`, `ResonanceService` | 구현됨 | eq.runes |
| **선행 B** | `slot_N_run.json` | 구현됨 (기본) — [`save-load.md`](save-load.md) v2 | — |
| **eq.persist** | 런에 소켓·룬·보석 인스턴스 | 구현됨 | 선행 B |
| **eq.register** | 마을 제단 봉인, 메타 카드 | hub.altar — [`altar.md`](altar.md) | 메타 JSON은 v1 슬롯으로 가능 |
| **shelf.v1** | `unlocked_shelves` 룻 · 제단 분리 | 대체됨 | |
| **shelf.v2** | 희귀도 단 · E1 · open_cards | 대체 → shelf.v3 | |
| **shelf.v3** | 룬/보석 판 · 시드 `#1` · 희귀도/E1 없음 | 구현됨 — [`bookshelf.md`](bookshelf.md) | eq.register |
| **인벤 소켓 UI** | 장비↔MOD 양방향 꽂기/빼기 | 대장간 Sheet로 이동 → [`architecture/equipment.md`](../architecture/equipment.md) | eq.runes / eq.gems |
| **eq.economy** | 희귀도별 슬롯·인챈트 | **폐기** | — |
| **패시브 훅** | 갑옷·방패 룬의 게이지 외 전투 효과 | 설계만 | eq.runes |
| **map v2** | 룬 제단·보석 광맥 등 `room_type` | 설계만 — [`map.md`](map.md) | — |

---

## 현재 전제

새 시스템은 이 경로를 대체하지 않는다.

```text
CharacterStats.attributes
        ↓
ItemData 장착 + InventoryData
        ↓
CombatStatsBuilder.build(character, inventory)
        ↓
CombatStats
        ↓
CombatSession
        ↓
ATB 자동 전투
```

| 역할 | 현재 |
|------|------|
| `ItemData` | `id`, `category`, `rarity`, `equip_slot`, `two_handed`, `attack`/`attack_bonus`, `defense`/`defense_bonus`, `scales_with`(String), `affixes`/`skills`(`Array[Dictionary]`) |
| `InventoryData` | 탭별 `bags` 25칸, `runes`/`gems` 합산 25, `EQUIP_SLOTS`, 재화, 퀵 아이템/음식 |
| `ItemCatalog` | 템플릿 `id` → 인스턴스 복제. 세이브는 `id` + 오버라이드 |
| `CombatStatsBuilder` | 속성 + 장착 방어 + `affixes` 합산의 **유일 경로** |
| HUD 기술 | `list_equipped_rune_skills` 최대 6. 액티브만 게이지 발동. 패시브는 이름만 ([`architecture/equipment.md`](../architecture/equipment.md)) |
| 자원 | 마나. Focus 바가 아님 |

맵은 아이작식 방 격자, 전투는 루프 히어로식 ATB. 전투 중 공격·패링·구르기·룬 버튼은 없다.

---

## 책임 분리

```text
장비(ItemData) = 무엇으로 싸우는가 — 기본 공격, 타입, 고유 효과, 슬롯 용량
룬             = 어떤 기술을 자동 발동하는가 — 액티브는 주무기, 패시브는 갑옷·보조 (HUD 표시, 전투 훅은 후속)
보석           = 그 기술이 어떤 성질·조건으로 작동하는가
접두사(affixes)= CombatStats 수치 (공속, 크리, vampirism 비율 …)
공명           = 장비 타입 + 룬 + 보석 → 강화 기술 데이터
카드 등록      = 이번 런의 룬·보석 개체를 포기하고 마을 메타를 진행
```

같은 `CombatStats` 필드를 장비 기본값·접두사·보석·룬이 모두 올리지 않는다.

```text
장비: 검의 기본 피해와 item_type
룬:   자동 발동 검 기술 (마나)
보석: 그 발동에 화염·빙결·흡혈 **행동**을 붙임 (비율 필드에 가산 금지)
접두사: attack_speed, crit_chance, vampirism **수치**
```

---

## ItemData 확장

별도 `EquipmentDefinition`을 만들지 않는다. **추가만** 한다.

```gdscript
# 유지: id, display_name, item_type, category, rarity, icon, tier,
# attack, attack_bonus, defense, defense_bonus, scales_with,
# skills (Array[Dictionary]), affixes (Array[Dictionary]),
# cost, gain (오버라이드. 공식은 shop.md), flavor_text, required_stat, required_value,
# durability, weight, stackable, quantity, equip_slot

@export var socket_layout: SocketLayout
@export var compatible_rune_tags: Array[StringName]
@export var compatible_gem_tags: Array[StringName]
@export var intrinsic_effects: Array[Dictionary]
```

`EQUIP_SLOTS`와 카테고리(`WEAPON` / `ARMOR` / `CONSUMABLE` / `MATERIAL` / `TOOL`)와 `ItemRarity`(COMMON / UNCOMMON / RARE / LEGENDARY)는 유지한다. `EPIC`은 없다. 저주 enum은 넣지 않는다. 대가는 `cursed` 태그 또는 음수 접두사로 둔다.

장비 본체는 카드 등록 대상이 아니다.

`AttackData` / `SkillData` / `AffixData` / `scales_with: Array`로의 승격은 **별도 마이그레이션**. 룬 연결은 `skills` Dictionary에 `rune_id` 키를 얹는 것으로 충분하다.

---

## 룬·보석 보관

`ItemCategory`에 `RUNE` / `GEM`을 넣지 않는다. 장비 격자와 카탈로그는 `ItemData` 전용이다.

```text
InventoryData.slots / equipped   → ItemData (현행)
InventoryData.runes              → Array[RuneInstance]
InventoryData.gems               → Array[GemInstance]
```

인스턴스는 템플릿 `rune_id` / `gem_id` + `instance_uid`. 장착은 장비 소켓이 `instance_uid`를 가리킨다. 등록한 uid는 가방에서 제거하고 재장착할 수 없다.

세이브:

```text
템플릿 ItemData: socket_layout = 칸 용량 (부위. 희귀도와 무관)
인스턴스 오버라이드: socketed[{index, kind, instance_uid}]
런(slot_N_run.json, 선행 B 이후): runes[], gems[], socketed
메타(slot_N.json): 등록 카드, 책장, 천장 — 인스턴스 배열과 섞지 않음
```

`ItemCatalog`는 장비용으로 유지한다. 룬·보석은 별도 카탈로그(또는 같은 패턴의 `RuneCatalog` / `GemCatalog`). `ItemData` JSON 통째 덤프 금지는 [`save-load.md`](save-load.md)와 같다.

---

## 희귀도와 슬롯

소켓 수는 부위 고정. 희귀도는 색·접두사·상점가. 옛 전제(희귀도=칸, COMMON 캔버스 / LEGENDARY 슬롯 잠금, `eq.economy`)는 **폐기**.

| 부위 | 룬 | 핵심 | 보조 |
|------|----|------|------|
| 주무기 | 2 (액티브 세트 A/B) | 2 | 2 |
| 갑옷 / 보조무기 | 1 (패시브) | 1 | 1 |
| 반지 / 도구 | 0 | 1 | 0 |

인덱스 짝: `rune` i ↔ `core_gem` i ↔ `aux_gem` i.  
장비 파괴를 기본 규칙으로 쓰지 않는다. 레이아웃 밖 `socketed`는 로드 시 삭제 (가방 반환 없음).

---

## 소켓

```text
RUNE:          액티브 = main_hand 0·1. 패시브 = off_hand / head / chest / legs
CORE_GEM:      해당 룬(또는 반지·도구)의 공명 조건
AUXILIARY_GEM: 범위·연쇄 등. 없어도 기본·공명 유지
AFFIX:         소켓이 아님. 기존 affixes
```

한도 (`SocketLayout.for_slot`, 후속 튜닝 대상 아님):

```text
main_hand: 룬 2, 핵심 2, 보조 2
off_hand / head / chest / legs: 룬 1, 핵심 1, 보조 1
ring_* / tool_*: 핵심 1. 룬 없음
```

호환은 태그. `CombatSession`과 인벤 UI에서 조합을 판정하지 않는다.

---

## 룬

```gdscript
class_name RuneData
extends Resource

@export var rune_id: StringName
@export var rarity: ItemData.ItemRarity
@export var shelf_id: StringName
@export var card_number: int
@export var required_equipment_tags: Array[StringName]
@export var skill_name: String
@export var mana_cost: int
@export var resonance_tags: Array[StringName]
@export var registration_effects: Array[Dictionary]
```

전투 스킬 본문(`SkillData`)은 stats v1.3 기술 리소스와 맞출 때 붙인다. 그 전에는 `skill_name` + `mana_cost` + 태그만으로 HUD와 게이지를 연결한다.

```text
액티브 룬만   → 주무기 skills. 게이지+마나로 자동 발동
패시브 룬     → HUD 이름. 전투 훅은 후속
+ 호환 핵심 보석 → 같은 칸의 강화 기술 (RESONANT)
+ 보조/조건 → 추가 효과 (COMPLETE). 보조를 빼도 기본/공명 유지
```

보석 없음 ≠ 기술 잠김. 호환되지 않는 룬은 소켓에 들어가지 않는다.

예: 관통 룬(`strike`) → 주무기 자동기. 찬가 룬(`heal`) → 갑옷·보조 HUD. 수동 패링/도약이 아니다.

---

## 보석

```gdscript
class_name GemData
extends Resource

@export var gem_id: StringName
@export var rarity: ItemData.ItemRarity
@export var shelf_id: StringName
@export var card_number: int
@export var gem_type: StringName
@export var resonance_tags: Array[StringName]
@export var slot_effects: Dictionary  # equip_slot → 행동 키 (수치 필드명 금지)
@export var registration_effects: Array[Dictionary]
```

같은 보석이라도 `equip_slot`에 따라 **행동**이 달라질 수 있다.

```text
무기: 장착 룬의 속성·공명 조건
방어구: 피격·생존 반응 (세션 플래그)
ring_*: 유지 조건
tool_*: 탐험·발견 규칙
```

새 수치가 필요하면 먼저 `CombatStats`와 `CombatStatsBuilder`를 확장한 뒤, 접두사 `id`로만 합산한다. 원소 내성 수치는 stats v2(Heat/Cold/Electric/Plague) 이후.

---

## 공명

`ResonanceService`(RefCounted)만 평가한다. `CombatStatsBuilder`와 같은 도메인 계층. `CombatSession`은 `ResonanceResult`만 소비한다.

```gdscript
class_name ResonanceService
extends RefCounted

func evaluate(
	equipment: ItemData,
	rune: RuneData,
	core_gem: GemData,
	auxiliary_gems: Array[GemData]
) -> ResonanceResult:
	# 장비·룬 태그 실패 → INACTIVE
	# 공명 태그 불일치 → BASE_SKILL_ONLY
	# 핵심 일치 → RESONANT
	# 보조/조건 → COMPLETE
	pass
```

| 상태 | 의미 |
|------|------|
| `INACTIVE` | 장비와 룬 비호환. 해당 칸 기술 없음 |
| `BASE_SKILL_ONLY` | 룬 기본 기술만 |
| `RESONANT` | 핵심 보석 공명 |
| `COMPLETE` | 보조 보석 또는 조건까지 |

조합 이름은 데이터. 세션에 `검+반격+혈석`을 하드코딩하지 않는다.

HUD·인벤은 상태를 표시만 한다. 판정 코드를 복제하지 않는다.

---

## 카드 등록 (마을)

대상은 룬·보석 **인스턴스**. 장비는 유지한다.

NRFW 추출(룬을 남기고 무기 파괴)을 쓰지 않는다.

```text
던전: 획득 → 장착 또는 InventoryData.runes/gems 보관
마을 대장간: 장비 소켓에 룬·보석 꽂기/빼기
마을 제단: 확인창 → 개체 제거 → 장비 유지 → skills/공명 갱신
         → registered_cards + 인접 open_cards
```

등록 결과:

```text
룬 등록:        장비 유지, 해당 skills 칸 비움
핵심 보석 등록: 기본 룬 유지, 공명만 해제
보조 보석 등록: 추가 효과만 제거
```

확인창에 넣을 것: 장착 여부, 기술 영향, 비활성화될 효과, 카드 번호·서가. 해당 개체는 되돌릴 수 없다. 동 id 재봉인 불가.

봉인은 `VillageShell` **제단** 탭 (룬|보석 목록). 상세: [`altar.md`](altar.md). 서가는 5×5 기록만 — [`bookshelf.md`](bookshelf.md).

---

## 책장과 세이브

책장은 전투 보드·타일 카드가 아니다. 마을에서 보는 메타 도감. **shelf.v3:** [`bookshelf.md`](bookshelf.md).

```text
런 slot_N_run.json
  장착 장비, socketed uid, runes[], gems[], 공명 스냅샷, 방, 시드

메타 slot_N.json
  registered_cards, open_cards, unlocked_shelves, card_pity
```

전멸은 런만 지우고 등록 카드는 남긴다.

```text
open_cards: UI 공개 + 드랍 풀 (시작 각 판 #1)
unlocked_shelves: shelf_rune, shelf_gem (상시)
card 등록: 개체 소모 + 영구 기록 + 인접 OPEN
```

인접 계산은 `CardRegistrationService` / `ShelfDefinition`. UI에 격자 연산을 넣지 않는다.


---

## 방과 보상

현재 `room_type`: `START` / `NORMAL` / `BOSS`. 특수 방은 map v2.

방 `win` 지급은 [`loot.md`](loot.md). 룬·보석 풀 = `open_cards`.

---

## 구현 순서

1~7c와 shelf.v3·인벤 소켓 UI·부위 소켓은 구현됨 ([`architecture/equipment.md`](../architecture/equipment.md)). 남은 것은 패시브 전투 훅과 특수 방.

1. **현황 확인** — `ItemData`, `EQUIP_SLOTS`, 빌더, HUD `skills`, 세이브 `id`+오버라이드.  
2. **선행 A** — stats v1.3.  
3. **eq.sockets** — `SocketLayout.for_slot` + 인벤에 칸만 표시.  
4. **eq.runes** — `RuneData`, `runes[]`, 액티브/패시브 부위.  
5. **eq.gems** — `GemData`, `ResonanceService`.  
6. **eq.register → shelf.v3** — 룬/보석 판 · `open_cards` · 시드 `#1` — [`bookshelf.md`](bookshelf.md).  
7. **선행 B → eq.persist** — 런 JSON에 `runes`/`gems`/socketed.  
7b. **소켓 UI** — 마을 대장간에서 장비↔MOD 꽂기/빼기. 인벤은 표시만.  
8. **eq.economy** — 폐기. 칸 수는 부위 고정.  
9. **패시브 훅** — 갑옷·방패 룬의 전투 효과 (HUD 표시는 구현됨).

---

## 검증

- 기존 `ItemData` 로드·장착·빌더 합산이 깨지지 않는가.
- HUD 기술이 꽂힌 룬 수만큼(최대 6)인가. 소스가 `list_equipped_rune_skills`인가.
- 선행 A: 마나 부족 시 기술을 건너뛰고 평타만 하는가. 패시브 kind는 게이지가 건너뛰는가.
- 룬만으로 기본 기술이 자동 발동하는가. 보석 없다고 잠기지 않는가.
- 액티브 룬이 갑옷에, 패시브 룬이 주무기에 들어가지 않는가. 반지·도구에 룬 칸이 없는가.
- 희귀도를 바꿔도 소켓 수가 같은가.
- 공명 시 강화 기술이 같은 칸에 적용되는가. 보조 제거 후에도 기본/공명이 남는가.
- 보석이 `AFFIX_FIELDS`를 더하지 않는가. 합산이 빌더 밖에 없는가.
- 룬 봉인 시 장비가 남고 해당 `skills`만 비는가. NRFW식 장비 파괴가 없는가.
- 등록 uid를 다시 장착할 수 없는가. 전멸이 메타 카드를 지우지 않는가.
- 인접 OPEN이 동 판(룬↔보석 교차 없음)만인가.
- 고정 시드에서 보상·발견이 재현되는가.
- 인벤에서 호환 룬만 해당 부위 소켓에 들어가고, 빼면 HUD가 되돌아가는가.
- 양손 장착 시 주·보조가 가방으로 가고, 가방이 가득하면 장착이 거부되는가.

---

## 관련 문서에 미치는 결정

| 문서 | 점 |
|------|----|
| [`architecture/inventory.md`](../architecture/inventory.md) | 가방 UI·소켓 행·양손·ATK/DEF 비교. 데이터는 [`architecture/equipment.md`](../architecture/equipment.md) |
| [`architecture/equipment.md`](../architecture/equipment.md) | 구현 현황 |
| [`stats.md`](stats.md) | 접두사 = 스탯, 기술 = 행동. 룬은 v1.3 게이지의 데이터 소스. 보석은 `AFFIX_FIELDS`에 가산하지 않음 |
| [`combat.md`](combat.md) | 세션은 `ResonanceResult`만 소비. 마을 서가는 전투 타일/카드가 아님 |
| [`hud.md`](hud.md) | 장착 룬 0~6·액티브만 자동 발동. 전투 중 룬 버튼 없음 |
| [`save-load.md`](save-load.md) | 등록 카드는 메타. 소켓·룬·보석 인스턴스는 메타 인벤 + 런 스냅샷. 던전 이어하기는 후속 |
| [`village.md`](village.md) | HubNav 게시판·제단·서가·대장간. 여관·상점은 후속 |
| [`altar.md`](altar.md) | 마을 제단 봉인 |
| [`bookshelf.md`](bookshelf.md) | shelf.v3 룬/보석 판·기록·open_cards |
| [`shop.md`](shop.md) | 골드 가격. 소켓 수와 분리. `eq.economy` 폐기 |
| [`map.md`](map.md) | `START`/`NORMAL`/`BOSS` 유지. 특수 방은 v2 |
| [`loot.md`](loot.md) | 방 `win` 3택1. 룬·보석 풀 = `open_cards`. 접두사 롤러는 v2 |

---

## 비목표 (당분간)

- `EquipmentDefinition`으로 `ItemData`를 대체
- `ItemCategory.RUNE` / `GEM`으로 장비 격자에 섞기
- 희귀도로 소켓 수를 바꾸기 (`eq.economy`)
- 인챈트·넘친 소켓 가방 반환 UX
- 던전에서 카드 등록
- 등록 시 장비 파괴 (NRFW 추출)
- Focus 바, 수동 룬 버튼, 패링·구르기 입력
- 보석이 접두사와 같은 키로 수치 합산
- 전투 보드·타일 카드
- 루프 히어로 캠프 특성 — 여관/Insight 이후 ([`stats.md`](stats.md))
