# 마을 제단 — hub.altar (1차)

**현황(구조):** [`docs/architecture/village.md`](../architecture/village.md) · [`equipment.md`](../architecture/equipment.md).  
세계관: [`world.md`](world.md) (바침은 제단, 서가는 기록). 제단 아래 런은 [`basin.md`](basin.md) — 이 문서와 다른 장소.

---

## 한 줄

마을 **제단** Sheet에서 보유 룬·보석을 봉인한다. **서가**는 5×5 기록만 본다.

---

## 확정 결정

| # | 결정 |
|---|------|
| 1 | 서가 이름 유지. 역할 = 기록. 「도감」 카피 금지. |
| 2 | 바침 UI = `MenuShell` `Tab.ALTAR`. 새 Autoload·CanvasLayer·월드 클릭 없음. |
| 3 | HubNav / 마을 탭: `게시판 · 제단 · 서가 · 대장간`. 단축키 **Q / W / E / R**. |
| 4 | `ALTAR`는 `SMITHY`와 같이 **허브만**. |
| 5 | 제단 본문 = 보유·미소켓·미등록 목록. 5×5 복제 금지. |
| 6 | 봉인 = 현행 `CardRegistrationService.register`. 규칙 변경 없음. |
| 7 | 서가는 봉인하지 않음. |
| 8 | 제단 NPC 없음. |
| 9 | 결말 `seal`은 오버레이 → `register` 직행. |
| 10 | 메타 키 추가 없음. |

---

## UI

씬: [`ui/village/altar.tscn`](../../ui/village/altar.tscn).

좌: 룬\|보석 탭 + 오퍼 목록 (`AltarCardSlot.set_card`). 우: `ModifierDetailPanel`.  
푸터: 오퍼 있으면 `REGISTER`+`BACK`, 없으면 `BACK`.  
빈 목록: `No runes or gems to register`. 확인: `Confirm register rune/gem`.

입력: 목록 상하. 탭 순환 `inventory_category_prev|next`. 서가 격자 이동 없음.

---

## 단축키

| 장소 | 액션 | 키 |
|------|------|-----|
| 게시판 | `village_board` | Q |
| 제단 | `village_altar` | W |
| 서가 | `village_shelf` | E |
| 대장간 | `village_smithy` | R |

---

## 관련

| 문서 | 연결 |
|------|------|
| [`world.md`](world.md) | 바침은 제단, 서가는 기록 |
| [`bookshelf.md`](bookshelf.md) | 5×5 기록 · `open_cards` |
| [`village.md`](village.md) | HubNav |
| [`architecture/village.md`](../architecture/village.md) | 현황 |
| [`architecture/equipment.md`](../architecture/equipment.md) | `register` |
