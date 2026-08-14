# 서가 / 책장 — shelf.v3

**현황(구조):** [`docs/architecture/equipment.md`](../architecture/equipment.md) · [`loot.md`](../architecture/loot.md) · [`village.md`](../architecture/village.md).  
세계관: [`world.md`](world.md) (등록 = 이름 남기기, 룬·보석 기록. 「유물」 금지).  
장비·공명: [`equipment.md`](equipment.md). 허브: [`village.md`](village.md). 룻: [`loot.md`](loot.md).

---

## 한 줄

마을 **서가**에서 룬·보석을 보고, 보유분을 **봉인**하면 이웃 칸이 열려 다음 수색 드랍 풀에 합류한다.

---

## 확정 결정 (shelf.v3)

| # | 결정 |
|---|------|
| 1 | 서가 탭 = **룬 \| 보석** (`shelf_rune` / `shelf_gem`). |
| 2 | 해금 본선 = **바침 → 동 판 4방 OPEN**. OPEN = 이름 공개 **+** 드랍. |
| 3 | `open_cards` (`shelf_id:card_number`) = UI·드랍 공통 키. |
| 4 | 시작 OPEN = 각 판 **`card_number == 1`만**. |
| 5 | **1칸 = 템플릿 1개**. 룬 판·보석 판 분리. |
| 6 | 동 id **재봉인 불가**. |
| 7 | 룬·보석 **희귀도 없음**. 장비 `ItemData.rarity`만 유지. |
| 8 | E1·희귀도 단·골드/업적 해금 **없음**. |
| 9 | `unlocked_shelves` = 항상 두 판 (탭 잠금 없음). |
| 10 | 격자 = 5×5. 인접 = 동 행·열 4방(행 끝 wrap 없음). |
| 11 | HubNav: 소문 · 서가. 용어 = 룬·보석. |

---

## 로드맵

| 단계 | 범위 | 상태 |
|------|------|------|
| shelf.v1 | `unlocked_shelves` 룻 · 제단 분리 | 대체됨 |
| shelf.v2 | `open_cards` · 희귀도 단 · E1 | 대체됨 |
| **shelf.v3** | 룬/보석 판 · 시드 `#1` · 희귀도/E1 제거 | **구현됨** |
| shelf.pity | `card_pity` | 후속 |
| shelf.unlock 특수 방 | map v2 열쇠 | 후속 |

---

## 메타 스키마

```text
registered_cards[]   { kind, id, instance_uid, shelf_id, card_number }
open_cards[]         "shelf_id:card_number"
unlocked_shelves[]   ["shelf_rune", "shelf_gem"] 항상
card_pity            {} — 미사용
```

구키: `shelf_common|uncommon|rare`, `discovered_cards` → `ensure_meta`에서 폐기 후 `#1` 시드.  
`registered_cards`는 카탈로그로 `shelf_id`/`card_number` 재기입.

### 칸 상태

| 상태 | 의미 | 드랍 |
|------|------|------|
| `FOG` | 칸 미OPEN | 불가 |
| `OPEN` | 풀림 | **가능** |
| `REGISTERED` | 봉인됨 | 가능 |
| `EMPTY` | 템플릿 없는 번호 | — |

`SHELF_LOCKED`는 탭 잠금이 없어 사실상 미사용.

---

## 룻 게이트

```text
RUNE: pool = shelf_rune templates with card_number ∈ open_cards
GEM:  pool = shelf_gem templates with card_number ∈ open_cards
WEAPON | ARMOR: 게이트 없음
```

---

## 봉인 시

1. 이미 등록된 id → 거부  
2. 가방 개체 제거 (소켓 uid 제외), 장비 유지, 공명 재계산  
3. `registered_cards` append  
4. self + 동 판 인접 → `open_cards`  
5. 다른 판(룬↔보석)으로 전파 없음  

---

## UI

| 항목 | 설정 |
|------|------|
| 씬 | `ui/village/bookshelf.tscn` |
| 탭 | Rune · Gem |
| 봉인 | OPEN/FOG 칸에 보유분 있으면 푸터 봉인 + 확인 |
| 상세 | OPEN·REGISTERED만 이름 |

---

## 검증

`godot --headless --path . -s res://data/equipment/verify_bookshelf.gd`

---

## 비범위

- `card_pity` · 룬/보석 희귀도 재도입 · E1  
- 특수 방 열쇠 · 장비 룻 게이트  

---

## 관련

| 문서 | 연결 |
|------|------|
| [`world.md`](world.md) | 룬·보석 · 이름 남기기 |
| [`equipment.md`](equipment.md) | 등록·공명 |
| [`village.md`](village.md) | VillageShell |
| [`loot.md`](loot.md) | 3택1 |
| [`architecture/equipment.md`](../architecture/equipment.md) | 현황 |
