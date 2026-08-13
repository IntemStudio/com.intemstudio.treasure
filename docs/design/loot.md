# 전리품 / 드랍 — 후속 설계

**v1 현황(구조):** [`docs/architecture/loot.md`](../architecture/loot.md)  
이 문서는 **후속** 로드맵을 다룬다. v1 장비 드랍은 구현됨.

관련: [`combat.md`](combat.md) (지급 훅) · [`equipment.md`](equipment.md) (종류 축) · [`village.md`](village.md) (전멸·`reward_mult`) · [`hud.md`](hud.md) (획득 토스트) · [`game-log.md`](game-log.md) (같은 획득을 로그에도) · [`save-load.md`](save-load.md) (메타 인벤) · [`inventory.md`](../architecture/inventory.md) (가방 30칸).

---

## 한 줄

방의 적을 **모두** 처치하면 장비를 인벤에 넣고, 원정 중에 갈아끼운다. 첫 구현은 장비만. 룬·보석 칸은 테이블에만 연다.

---

## 확정 결정

| # | 결정 |
|---|------|
| 1 | 킬마다 떨어뜨리지 않는다. `win`일 때만. 후퇴·패배는 없음. |
| 2 | 종류 축은 `equipment` / `rune` / `gem`. `ItemCategory`에 `RUNE`/`GEM`을 넣지 않는다 ([`equipment.md`](equipment.md)). |
| 3 | **v1은 `equipment`만** 굴린다. 룬·보석 가중치 0. |
| 4 | 개수 1~N. NORMAL보다 BOSS가 많다. 같은 풀. |
| 5 | `ItemCatalog.get_item(id)` 복제. 접두사 롤러·지역 풀 없음. |
| 6 | 가방이 가득하면 **넣지 않고** 알림. 오래된 칸을 밀지 않는다. |
| 7 | 메타 인벤에 바로 넣는다. 전멸·보스 귀환 후에도 남는다 (XP와 같음). 런 가방 없음. |
| 8 | 인벤을 자동으로 열지 않는다. 짧은 토스트. |
| 9 | 장착은 기존 메뉴. **다음 방** `CombatStatsBuilder.build`부터 반영. 이번 세션은 입장 스냅샷. |
| 10 | 게시판 `reward_mult`는 v1 드랍에 쓰지 않는다 (문구만, [`village.md`](village.md)). |

---

## 로드맵

| 단계 | 범위 | 상태 |
|------|------|------|
| **v1** | 방 `win` → 장비 1~N, 카탈로그 복제, 가득 시 스킵, 토스트, 메타 인벤 | 구현됨 → [`architecture/loot.md`](../architecture/loot.md) |
| **v1.1** | 룬·보석 가중치, 소모품 종류, `reward_mult`·지역 풀 | 설계만 — [`equipment.md`](equipment.md) eq.runes 이후 |
| **v2** | 접두사 롤러, 보스 희귀도, 시드 재현 강화 | 설계만 |

---

## v1 — 장비만

### 지급 시점

`EncounterDirector._apply_win`에서 XP·HP와 같이. `START`·이미 `cleared`는 전투가 없으므로 드랍도 없다. 같은 방 재입장으로 두 번 주지 않는다.

```
win
  → pending_xp, HP/마나 반영
  → LootService.grant(inventory, table, ctx)
  → 빈 칸에 ItemCatalog 복제
  → 토스트
  → refresh_character_views
  → BOSS면 return_to_village()  (지급·세이브 이후)
```

세션은 전리품을 모른다. XP처럼 `pending_*`를 디렉터가 소비한다.

### 종류

```text
LootKind: equipment | rune | gem | consumable
```

`consumable`은 v1 가중치 0. 퀵 슬롯 물약용 구멍 ([`hud.md`](hud.md) v1.1). 골드는 아이템이 아니다.

| kind | v1 | 넣는 곳 |
|------|----|---------|
| `equipment` | 100% | `InventoryData.slots` (`ItemData`) |
| `rune` | 0% | 나중에 `runes[]` |
| `gem` | 0% | 나중에 `gems[]` |
| `consumable` | 0% | 나중에 `slots` (CON) |

### 개수

테이블 필드. 구현 직전 튜닝.

| 방 | min | max (초안) |
|----|-----|------------|
| NORMAL | 1 | 2 |
| BOSS | 2 | 3 |

`count = rng.randi_range(min, max)`. 풀이 비면 0.

### 풀

`ItemCatalog`에서 `category`가 `WEAPON` 또는 `ARMOR`인 템플릿. `CONSUMABLE` / `MATERIAL` / `TOOL`은 제외.

동일 `id` 중복 허용 (클레이모어 두 자루). 인스턴스는 `duplicate(true)`. 접두사는 템플릿 그대로.

가중치 v1은 균등. 지역(`dungeon_id`)은 인카운터만 가른다. 드랍 풀은 하나.

### 가방 가득

`InventoryData.find_empty_slot()`. `-1`이면 그 아이템과 남은 횟수는 버린다. 이미 넣은 것은 유지.

토스트: 넣은 이름 + 스킵이 있으면 가득 문구. 고르기 UI·자동 폐기는 없음.

### 수명

인벤은 메타 `slot_N.json`. 넣는 즉시 세이브 대상.

| 결과 | 전리품 |
|------|--------|
| 다음 방 | 가방에 있음. 메뉴에서 장착 → 다음 전투 스냅샷 |
| 후퇴 (입구) | 유지 (원정 계속) |
| 보스 `win` | `return_to_village()`가 슬롯 저장 |
| 전멸 | 마을 저장. 층은 버려도 인벤은 남음 |
| 원정 포기 (v1.1) | 메타 인벤이므로 이미 넣은 장비는 남음. 런만 삭제 |

루프히어로처럼 런 장비를 버리려면 세이브 v2 런 가방이 필요하다. v1 비목표.

### 토스트

인벤·보상 패널을 열지 않는다. GameHud에 짧은 텍스트. CombatHud는 `hide_combat` 이후라 쓰지 않는다.  
같은 `LootResult`를 게임 로그에도 한 줄로 남긴다. 토스트를 대체하지 않는다 ([`game-log.md`](game-log.md)).

- 넣음: 표시명 나열 (`tr` 가능하면 `tr`)
- 스킵: `LOOT_INVENTORY_FULL`
- 보스: 씬이 바뀌면 토스트는 생략돼도 됨. 지급·저장은 먼저.

키 (초안): `LOOT_GOT` / `LOOT_INVENTORY_FULL`. 구현 직전 [`locale/ui_strings.csv`](../../locale/ui_strings.csv).

### 시드

있으면 `pending_run.seed` + 방 좌표로 `RandomNumberGenerator`. 에디터 단독 던전은 `randi()`. 재현은 v2에서 테이블과 같이 검증.

### 위치 (예정)

| 역할 | 경로 |
|------|------|
| 종류·테이블 | `data/loot/loot_table.gd` · `loot_table.tres` (구현됨) |
| 지급 | `data/loot/loot_service.gd` (`RefCounted`, 구현됨) |
| 훅 | [`encounter_director.gd`](../../world/combat/encounter_director.gd) `_apply_win` |
| 토스트 | GameHud `LootToast` (구현됨). MenuShell 아님 |

```
LootService.grant(inventory, catalog, table, ctx) -> LootResult
# ctx: room_type, seed?, cell: Vector2i
# LootResult: granted: Array[ItemData], skipped: int
```

`CombatSession` / `EncounterDef`에 드랍 필드를 넣지 않는다. 방 타입 + 전역 테이블.

### API (예정)

```
UIManager.show_loot_toast(result)
InventoryData.find_empty_slot() -> int   # 유지
ItemCatalog.get_item(id) -> ItemData     # 유지
```

---

## v1.1 — 종류를 켜기

룬·보석 가중치를 테이블에 채운다. 소켓·가방은 [`equipment.md`](equipment.md)가 먼저. `consumable`은 HUD 퀵 실사용과 같이.

`reward_mult`·지역 풀은 여기. 게시판 문구와 맞출지 구현 직전.

---

## v2 — 생성

템플릿 + 접두사 시드. 보스 희귀도. 고정 시드 재현 ([`equipment.md`](equipment.md) 검증).

---

## 검증

- NORMAL `win` 후 가방에 WEAPON/ARMOR만 생기는가. 물약·광석·낚싯대는 없는가.
- 개수가 테이블 min~max인가. 보스가 평균적으로 더 많은가.
- 가득이면 추가되지 않고 토스트가 뜨는가. 기존 칸은 유지되는가.
- 메뉴에서 장착 후 **다음** 방 전투 스탯이 바뀌는가. 이번 세션은 그대로인가.
- 전멸·보스 귀환 후 마을 인벤에 남아 있는가.
- 후퇴·패배에 아이템이 없는가. `cleared` 재입장에 두 번째 드랍이 없는가.
- 룬·보석 가중치 0일 때 `runes[]`/`gems[]`가 늘지 않는가.
- 인벤이 자동으로 열리지 않는가.

---

## 관련 문서에 미치는 결정

| 문서 | 점 |
|------|----|
| [`combat.md`](combat.md) | `win`에 전리품. 세션은 XP만 쌓음 |
| [`village.md`](village.md) | 전멸해도 방 전리품은 메타에 남음. `reward_mult`는 드랍에 미사용 |
| [`equipment.md`](equipment.md) | 던전 획득 = 이 문서 v1 장비. 룬·보석은 v1.1 |
| [`hud.md`](hud.md) | 획득 토스트. 인벤 자동 오픈 없음 |
| [`game-log.md`](game-log.md) | `grant`가 토스트와 `push_log`를 같이 호출 |
| [`save-load.md`](save-load.md) | 방 전리품 = 메타 인벤. 런 레이어 불필요 |
| [`architecture/inventory.md`](../architecture/inventory.md) | `find_empty_slot`이 드랍 삽입점 |

---

## 비목표 (당분간)

- 킬 단위 드랍, 바닥 픽업, 상자 방
- 룬·보석·소모품 실제 지급 (테이블 칸만)
- 접두사 롤러, 지역별 장비 풀
- `reward_mult`로 개수·희귀도
- 가방 가득 시 교체 UI·자동 폐기
- 전멸 시 런 전리품 몰수 (세이브 v2)
- 전투 중 스탯 재빌드
- 골드 드랍, 월드 드랍 메시
- 데스폿 보상 화면, 루프히어로 카드
