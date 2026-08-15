# 일지 — 소켓 · 룬 HUD

**날짜:** 2026-08-16  
**관련:** [장비](2026-08-13-equipment.md) · [인벤 소켓 UI](2026-08-14-socket-ui.md) · [인게임 HUD](2026-08-12-hud.md) · [상점 가격](2026-08-15-shop.md) · [보상 3택1](2026-08-13-loot-choice.md)

---

## 한 줄 요약

소켓 수는 **부위**로 고정됩니다. 희귀도는 색·접두사·가격만. 주무기는 액티브 세트 2, 갑옷·보조는 패시브. HUD는 꽂힌 룬 0~6칸입니다.

---

## 무엇이 되나요

- 부위: 주무기 룬 2 + 핵심/보조 각 2. 갑옷·보조 1/1/1. 반지·도구는 핵심 보석만
- 액티브(`strike`/`combo`/`aoe`)는 주무기만 게이지 발동. 패시브는 HUD 이름만
- 상세에서 XYAB 칸 없음. 소켓 행은 `rune0, core0, aux0, rune1…`
- 룬 상세에 장착 부위(Fits). 보석 상세에 주입 효과 설명
- 인벤 상세는 `판매 가격 N골드`. 룻 카드는 골드 숨김
- `EPIC` 없음 (COMMON / UNCOMMON / RARE / LEGENDARY). 옛 세이브 희귀도 3+ → 전설
- `eq.economy`(희귀도=소켓) 폐기. 넘친 소켓은 로드 시 삭제 (가방 반환 없음)
- 검증: `godot --headless --path . -s res://data/equipment/verify_socket_layout.gd`

슬롯 테두리 2px·AA off, 가방 칸 80px 고정, 착용 열 스크롤 거터, 룻 Sheet 상·중·하 밴드.

---

## 직접 확인해 볼 때

1. 커먼 검과 전설 검의 소켓 수가 같은지  
2. 강타 룬은 무기만, 찬가 룬은 갑옷·보조만인지  
3. 무기 룬 둘 → HUD 두 칸, 게이지가 액티브만 쓰는지  
4. 갑옷 룬은 HUD에만 있고 발동하지 않는지  
5. 인벤에 판매가가 보이고 룻 카드에는 골드가 없는지  
6. 개발 오버레이에서 희귀도를 바꿔도 칸 수가 그대로인지  

---

## 아직 없는 것

- 패시브 룬 전투 훅  
- 특수 방(룬 제단·보석 광맥)  
- 접두사 롤러 (loot v2)  

---

## 참고

- 구조: [`docs/architecture/equipment.md`](../architecture/equipment.md) · [`hud.md`](../architecture/hud.md) · [`shop.md`](../architecture/shop.md) · [`save-load.md`](../architecture/save-load.md)
- 설계: [`docs/design/equipment.md`](../design/equipment.md)
