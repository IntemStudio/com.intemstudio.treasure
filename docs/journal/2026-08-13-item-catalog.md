# 일지 — 아이템·룬·보석 카탈로그

**날짜:** 2026-08-13  
**관련:** [장비](2026-08-13-equipment.md) · [인벤토리 슬롯](2026-08-13-inventory.md) · [보상 3택1](2026-08-13-loot-choice.md) · [양손 무기](2026-08-14-two-hand.md)

> **이후:** Warplate·Cinder Loop는 전설. 음수 접두사 없음 — [2026-08-16](2026-08-16-equipment.md).

---

## 한 줄 요약

슬롯별 장비 27종과 룬 5·보석 5를 카탈로그에 넣었습니다. 전투의 새 kind·보석 행동은 아직 이름만 있습니다.

---

## 무엇이 되나요

### 장비
- `ItemDefaults`에 머리·가슴·다리·주무기·보조·반지·도구 각 3개
- `ItemCatalog`가 기존 샘플(`ItemBootstrap`)과 함께 등록
- 반지·방패는 `ARMOR` → 방 보상 풀에 포함 ([보상 3택1](2026-08-13-loot-choice.md))
- 도구는 `TOOL` → 방 보상에는 안 나오고, 개발 오버레이에서 지급 가능

### 룬·보석
- Flurry / Tide / Hymn / Ward / Thorn Verse
- Frostglass / Grave Pearl / Sanctum Tear / Root Amber / Ash Veil
- 기존 Counter·Pierce·Erupt, Bloodstone·Wind·Ember·Chain 유지

### 장착
- 반지·도구는 선호 칸이 차 있으면 짝 칸(`ring_2` / `tool_2` 등)으로 장착
- 양손 무기(클레이모어·필드 파이크)는 주·보조를 함께 해제하고, 보조를 끼면 양손이 가방으로 간다 ([양손 무기](2026-08-14-two-hand.md))
- 아이템·룬·보석 표시명/유형/접두사·기술명은 `ui_strings.csv` en/ko (`tr`)

---

## 직접 확인해 볼 때

1. 새 프로필: Iron Longsword + Splintered Buckler만 장착 (가방·룬·보석 비움)
2. 개발 오버레이에서 새 무기·갑옷·도구·룬·보석 지급 → 인벤 상세
3. 반지 두 개, 도구 두 개 장착 (짝 칸)
4. 방 보상 풀에 새 무기·갑옷이 섞임. 도구는 안 나옴 ([보상 3택1](2026-08-13-loot-choice.md))  
5. Hymn 등 새 룬을 꽂으면 HUD 이름은 뜨고, 발동은 지금처럼 강타 배율

---

## 아직 없는 것

- `combo` / `aoe` / `heal` / `ward` / `thorns` 세션 분기
- 새 보석 `behavior_flags` 전투 적용
- 지역별 드랍 풀

인벤 소켓 꽂기: [2026-08-14-socket-ui](2026-08-14-socket-ui.md).

---

## 참고

- 구조: [`docs/architecture/equipment.md`](../architecture/equipment.md)  
- 데이터: [`item_defaults.gd`](../../ui/inventory/resources/item_defaults.gd) · [`rune_catalog.gd`](../../data/equipment/rune_catalog.gd) · [`gem_catalog.gd`](../../data/equipment/gem_catalog.gd)
