# 장비 · 룬 · 보석 · 공명 — 후속 설계

**현황(구조):** [`docs/architecture/equipment.md`](../architecture/equipment.md).  
이 문서는 **미구현** 로드맵만 다룬다 (희귀도 경제, 책장 격자, 특수 방). 인벤 소켓 UI는 구현됨.

관련: [`stats.md`](stats.md) (접두사·기술 게이지) · [`combat.md`](combat.md) (세션은 결과만 소비) · [`hud.md`](hud.md) (기술 4칸) · [`save-load.md`](save-load.md) (메타/런) · [`village.md`](village.md) (등록은 허브) · [`map.md`](map.md) (특수 방은 v2) · [`loot.md`](loot.md) (방 클리어 장비) · [`shop.md`](shop.md) (골드 가격. `eq.economy`와 분리).

---

## 한 줄

장비는 기존 `ItemData`를 유지하고, 룬·보석은 별도 가방에서 주무기 기술 칸을 채우며, 공명은 빌더와 분리된 서비스가 계산한다. 카드 등록은 마을 메타다.

---

## 확정 결정

| # | 결정 |
|---|------|
| 1 | 룬·보석은 `InventoryData.runes` / `gems`에 둔다. `ItemCategory`와 5×6 장비 격자는 유지. |
| 2 | `ItemData`는 기존 필드 유지. `socket_layout`, 호환 태그, `intrinsic_effects`만 추가. `AttackData` / `SkillData` / `AffixData` 승격은 이 시스템의 전제가 아니다. |
| 3 | 룬은 `main_hand`만. `off_hand`는 보석·접두사. HUD 4칸 소스는 `equipped.main_hand.skills`. |
| 4 | 던전은 획득·장착·보관만. 카드 등록은 마을 제단만. |
| 5 | 기술 게이지·마나([`stats.md`](stats.md) v1.3)를 룬 발동보다 먼저. 런 JSON([`save-load.md`](save-load.md) v2)을 소켓 디스크 저장보다 먼저. |
| 6 | 접두사만 `CombatStats` 수치. 보석은 기술 플래그·조건·원소 행동. `CombatStatsBuilder.AFFIX_FIELDS`를 보석이 더하지 않는다. |

NRFW에서 가져올 것은 **희귀도 = 슬롯 구성**이다. Focus 바, 패링, 얼굴 버튼 룬, 추출 시 장비 파괴는 가져오지 않는다.

---

## 로드맵

| 단계 | 범위 | 상태 | 선행 |
|------|------|------|------|
| 현황 | `ItemData`, `affixes` 합산, HUD 기술 이름 4칸 | 구현됨 → 인벤 구조 문서 | — |
| **선행 A** | 기술 게이지 + 마나 자동 발동 | 구현됨 | 이름만 있는 `skills`로 검증 |
| **eq.sockets** | `SocketLayout` 표시. 전투 변화 없음 | 구현됨 | — |
| **eq.runes** | `RuneData`, `InventoryData.runes`, `skills` 채움, 자동 발동 | 구현됨 | 선행 A |
| **eq.gems** | `GemData`, `ResonanceService` | 구현됨 | eq.runes |
| **선행 B** | `slot_N_run.json` | 구현됨 (기본) — [`save-load.md`](save-load.md) v2 | — |
| **eq.persist** | 런에 소켓·룬·보석 인스턴스 | 구현됨 | 선행 B |
| **eq.register** | 마을 제단, 책장, 메타 카드 | 제단 구현됨 — 책장 격자 UI는 후속 | 메타 JSON은 v1 슬롯으로 가능 |
| **인벤 소켓 UI** | 장비↔MOD 양방향 꽂기/빼기 | 구현됨 → [`architecture/equipment.md`](../architecture/equipment.md) | eq.runes / eq.gems |
| **eq.economy** | 희귀도별 슬롯·인챈트 소비 튜닝 (골드 아님 — [`shop.md`](shop.md)) | 설계만 | eq.gems |
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
| `InventoryData` | `slots` 30칸, `EQUIP_SLOTS`, 재화, 퀵 아이템/음식 |
| `ItemCatalog` | 템플릿 `id` → 인스턴스 복제. 세이브는 `id` + 오버라이드 |
| `CombatStatsBuilder` | 속성 + 장착 방어 + `affixes` 합산의 **유일 경로** |
| HUD 기술 | `equipped.main_hand.skills` 최대 4, `{button, name, mana_cost, …}` 자동 발동 |
| 자원 | 마나. Focus 바가 아님 |

맵은 아이작식 방 격자, 전투는 루프 히어로식 ATB. 전투 중 공격·패링·구르기·룬 버튼은 없다.

---

## 책임 분리

```text
장비(ItemData) = 무엇으로 싸우는가 — 기본 공격, 타입, 고유 효과, 슬롯 용량
룬             = 어떤 기술을 자동 발동하는가 — main_hand.skills를 채움
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

`EQUIP_SLOTS`와 카테고리(`WEAPON` / `ARMOR` / `CONSUMABLE` / `MATERIAL` / `TOOL`)와 `ItemRarity`는 유지한다. 저주 enum은 넣지 않는다. 대가는 `EPIC`의 음수 접두사 또는 `cursed` 태그로 둔다.

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
템플릿 ItemData: socket_layout = 칸 용량 (희귀도·부위)
인스턴스 오버라이드: socketed[{index, kind, instance_uid}]
런(slot_N_run.json, 선행 B 이후): runes[], gems[], socketed
메타(slot_N.json): 등록 카드, 책장, 천장 — 인스턴스 배열과 섞지 않음
```

`ItemCatalog`는 장비용으로 유지한다. 룬·보석은 별도 카탈로그(또는 같은 패턴의 `RuneCatalog` / `GemCatalog`). `ItemData` JSON 통째 덤프 금지는 [`save-load.md`](save-load.md)와 같다.

---

## 희귀도와 슬롯 경제

희귀도는 전투력만이 아니라 **소켓 vs 접두사 구성**을 정한다. NRFW의 Common 캔버스 / Magical 슬롯 소비 / Plagued 대가를 `ItemRarity`에 대응한다.

| 희귀도 | 방향 |
|--------|------|
| COMMON | 보석 칸이 많고 `affixes`는 적거나 없음. 무기 룬 칸은 HUD 한도(4)까지 열 수 있음 |
| UNCOMMON | 보석 1, 긍정 접두사 |
| RARE | 긍정 접두사 증가, 보석·여분 룬 칸이 줄어들 수 있음 |
| EPIC | 접두사가 많고 대가 1줄 가능 |
| LEGENDARY | `intrinsic` 고정, 슬롯 자유도 낮음 |

슬롯이 많은 COMMON과 고유 효과가 강한 LEGENDARY가 서로 다른 이유로 가치가 있게 한다. 인챈트/개조가 칸을 줄이면 **별도 UX**로 빠져나가는 룬·보석을 가방으로 되돌린다. 장비 파괴를 기본 규칙으로 쓰지 않는다.

---

## 소켓

```text
RUNE:          main_hand만. 결과는 equipped.main_hand.skills (최대 4)
CORE_GEM:      해당 룬의 공명 조건
AUXILIARY_GEM: 범위·연쇄 등. 없어도 기본·공명 유지
AFFIX:         소켓이 아님. 기존 affixes
```

초기 한도 (eq.economy에서 튜닝):

```text
main_hand: 룬 1~4, 핵심 보석 0~1, 보조 보석은 COMMON 여분 칸
head/chest/legs: 보석 0~1, 접두사는 희귀도
ring_*: 보석 0~1, 접두사 0~1
tool_*: 탐험·발견 보석 (기술 공명 아님)
off_hand: 보석·접두사만. 룬 없음
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
룬만        → skills에 기본 기술. 게이지+마나로 자동 발동
+ 호환 핵심 보석 → 같은 칸의 강화 기술 (RESONANT)
+ 보조/조건 → 추가 효과 (COMPLETE). 보조를 빼도 기본/공명 유지
```

보석 없음 ≠ 기술 잠김. 호환되지 않는 룬은 소켓에 들어가지 않는다.

예: 반격 룬 → `counter` 계열 자동기. 관통 룬 → `damage_all` 또는 관통 플래그. 수동 패링/도약이 아니다.

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
마을 제단: 확인창 → 개체 제거 → 장비 유지 → skills/공명 갱신
         → 책장 기록 → 인접 후보 갱신
```

등록 결과:

```text
룬 등록:        장비 유지, 해당 skills 칸 비움
핵심 보석 등록: 기본 룬 유지, 공명만 해제
보조 보석 등록: 추가 효과만 제거
```

확인창에 넣을 것: 장착 여부, 기술 영향, 비활성화될 효과, 카드 번호·책장, 등록 보상, 인접 발견, 복제품/설계도. 해당 개체는 되돌릴 수 없다.

제단은 도전 게시판·MenuShell 탭이 아닌 **마을 전용 전체화면**. UI는 구현됨. 책장 격자·인접 해금 표시는 후속. [`village.md`](village.md).

---

## 책장과 세이브

책장은 전투 보드·타일 카드가 아니다. 마을에서 보는 메타 도감. [`combat.md`](combat.md) 타일/카드 비목표를 유지한다.

```text
런 slot_N_run.json (선행 B 이후)
  장착 장비, socketed uid, runes[], gems[], 공명 스냅샷, 방, 시드

메타 slot_N.json
  등록 카드, 책장 해금, 발견 정보, 천장, 설계도
```

전멸은 런만 지우고 등록 카드는 남긴다.

```text
책장 해금: 해당 희귀도 룬·보석이 보상 풀에 등장 가능
카드 발견: 위치·정보 공개
카드 등록: 개체 소모 + 영구 기록
```

일반 등록은 일반 책장 인접만 연다. 상위 책장을 해금하지 않는다. 인접 계산은 `ShelfDefinition`(또는 도메인 서비스). UI에 격자 연산을 넣지 않는다. 필수 카드는 천장/보장으로 영구 봉인되지 않게 한다.

---

## 방과 보상

현재 `room_type`: `START` / `NORMAL` / `BOSS`. 특수 방은 map v2.

방 `win` 지급은 [`loot.md`](loot.md). v1은 장비만 (`ItemCatalog` 복제). 룬·보석 가중치는 loot v1.1 — 소켓·가방(eq.runes / eq.gems)이 먼저. 보상 UI는 호환·공명·등록 영향을 **표시**하고, 판정은 `ResonanceService`와 카탈로그가 한다.

---

## 구현 순서

1~7과 인벤 소켓 UI는 구현됨 ([`architecture/equipment.md`](../architecture/equipment.md)). 남은 것은 8과 특수 방.

1. **현황 확인** — `ItemData`, `EQUIP_SLOTS`, 빌더, HUD `skills`, 세이브 `id`+오버라이드.  
2. **선행 A** — stats v1.3. 부트스트랩 무기 `skills` 이름으로 게이지·마나·스킵을 검증. 룬 없음.  
3. **eq.sockets** — `SocketLayout` + 인벤에 칸만 표시.  
4. **eq.runes** — `RuneData`, `runes[]`, 주무기 소켓 → `skills`에 `name`/`rune_id`. 호환 태그. 자동 발동은 선행 A 경로.  
5. **eq.gems** — `GemData`, `ResonanceService`, UI에 4상태. 빌더와 수치 중복 없는지 검증.  
6. **eq.register** — 마을 제단, 메타 카드. 책장 격자 UI는 후속.  
7. **선행 B → eq.persist** — 런 JSON에 `runes`/`gems`/socketed.  
7b. **인벤 소켓 UI** — 장비↔MOD 꽂기/빼기.  
8. **eq.economy** — 희귀도별 칸, 인챈트 시 가방으로 반환 UX. 슬롯 수 ≠ 전투력.

---

## 검증

- 기존 `ItemData` 로드·장착·빌더 합산이 깨지지 않는가.
- HUD 기술이 최대 4칸, 소스가 `main_hand`만인가.
- 선행 A: 마나 부족 시 기술을 건너뛰고 평타만 하는가.
- 룬만으로 기본 기술이 자동 발동하는가. 보석 없다고 잠기지 않는가.
- 비호환 룬이 `main_hand`에 들어가지 않는가. `off_hand`에 룬 칸이 없는가.
- 공명 시 강화 기술이 같은 칸에 적용되는가. 보조 제거 후에도 기본/공명이 남는가.
- 보석이 `AFFIX_FIELDS`를 더하지 않는가. 합산이 빌더 밖에 없는가.
- 룬 등록 시 장비가 남고 해당 `skills`만 비는가. NRFW식 장비 파괴가 없는가.
- 등록 uid를 다시 장착할 수 없는가. 전멸이 메타 카드를 지우지 않는가.
- 일반 책장 등록이 상위 책장을 열지 않는가.
- 고정 시드에서 보상·발견이 재현되는가.
- 인벤에서 호환 룬만 주무기 소켓에 들어가고, 빼면 `skills`가 되돌아가는가.
- 양손 장착 시 주·보조가 가방으로 가고, 가방이 가득하면 장착이 거부되는가.

---

## 관련 문서에 미치는 결정

| 문서 | 점 |
|------|----|
| [`architecture/inventory.md`](../architecture/inventory.md) | 가방 UI·소켓 행·양손·ATK/DEF 비교. 데이터는 [`architecture/equipment.md`](../architecture/equipment.md) |
| [`architecture/equipment.md`](../architecture/equipment.md) | 구현 현황 |
| [`stats.md`](stats.md) | 접두사 = 스탯, 기술 = 행동. 룬은 v1.3 게이지의 데이터 소스. 보석은 `AFFIX_FIELDS`에 가산하지 않음 |
| [`combat.md`](combat.md) | 세션은 `ResonanceResult`만 소비. 마을 책장은 전투 타일/카드가 아님 |
| [`hud.md`](hud.md) | 기술 4칸·자동 발동 유지. 전투 중 룬 버튼 없음 |
| [`save-load.md`](save-load.md) | 등록 카드는 메타. 소켓·룬·보석 인스턴스는 메타 인벤 + 런 스냅샷. 던전 이어하기는 후속 |
| [`village.md`](village.md) | 제단 구현됨. 책장 격자·여관·상점은 후속. 게시판과 별개 |
| [`shop.md`](shop.md) | 골드 가격. `eq.economy`(소켓·인챈트)와 분리 |
| [`map.md`](map.md) | `START`/`NORMAL`/`BOSS` 유지. 특수 방은 v2 |
| [`loot.md`](loot.md) | 방 `win` 3택1. 룬·보석은 loot v1.1 |

---

## 비목표 (당분간)

- `EquipmentDefinition`으로 `ItemData`를 대체
- `ItemCategory.RUNE` / `GEM`으로 장비 격자에 섞기
- `off_hand` 룬, HUD 4칸을 주+보조 합산으로 바꾸기
- 던전 제단에서 카드 등록
- 등록 시 장비 파괴 (NRFW 추출)
- Focus 바, 수동 룬 버튼, 패링·구르기 입력
- 보석이 접두사와 같은 키로 수치 합산
- 전투 보드·타일 카드, 일반 등록으로 상위 책장 해금
- 루프 히어로 캠프 특성 — 여관/Insight 이후 ([`stats.md`](stats.md))
