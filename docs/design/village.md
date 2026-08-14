# 마을 허브 / 도전 게시판

**미구현 후속:** 이어하기 던전 복귀 · 후퇴=원정 포기 · 여관/상점.  
**현황(구조):** [`docs/architecture/village.md`](../architecture/village.md) — `VillageShell` + `MenuShell` Sheet(소문·서가·인벤·스탯·설정). 걸어다니기·월드 존 클릭·제단 단독 UI는 **폐기**.  
서가: [`bookshelf.md`](bookshelf.md) (`shelf.v3`). 상점 가격: [`shop.md`](shop.md) (`shop.price` 구현, NPC는 후속).  
세계관(단독 보물 사냥꾼·마을=쉼터): [`world.md`](world.md). DD 햄릿은 **허브 UX 참고**만.  
런 파일: [`save-load.md`](save-load.md) v2. 층 생성: [`map.md`](map.md). 전투 종료: [`combat.md`](combat.md).

타이틀·프로필은 [`title.md`](../architecture/title.md). **게임 플레이의 집**은 `village.tscn`.

---

## 한 줄

프로필을 고르면 **마을 허브**로 들어가고, **소문(Sheet)** 에서 확정한 뒤에만 던전 맵을 생성한다.

---

## 목표 루프

```
타이틀 → 프로필
        ↓
      마을 (고정 배경, FloorGenerator / Player 없음)
        ↓  HubNav [소문] → 지역·길이 → 도전 확정
      RunState 작성 → FloorMap.generate → dungeon.tscn
        ↓
      탐험 / 방 전투 (현행)
        ↓  클리어 · 전멸 · (후퇴는 v1.1에서 마을)
      런 정산·삭제 → 마을
```

| 역할 | 다키스트 던전 1 | 이 게임 |
|------|-----------------|---------|
| 허브 | 햄릿 | 마을 씬 + VillageShell |
| 출발 UI | Embark (전체화면) | **소문 Sheet** (`ChallengeBoard` in MenuShell) |
| 맵 생성 | Embark 직후 | 소문 **도전 확정** 직후 |
| 영구 데이터 | 영지·영웅 | 메타 `slot_N.json` |
| 일회 원정 | 퀘스트 던전 | 런 `slot_N_run.json` (쓰기·삭제. 이어하기는 후속) |

타이틀은 슬롯 선택만 한다. 패배해도 타이틀이 아니라 마을로 돌아온다.

---

## 로드맵

| 단계 | 범위 | 상태 |
|------|------|------|
| **v1** | 마을 씬, 게시판, 확정 시 생성·입장, 전멸→마을 | 구현됨 (UX는 hub.shell로 갱신) |
| **hub.shell** | VillageShell · 소문/서가 Sheet · 걸어다니기 없음 · 제단 UI→서가 | 구현됨 → architecture |
| **shelf.v3** | 룬/보석 판 · open_cards · 봉인 | 구현됨 — [`bookshelf.md`](bookshelf.md) |
| **v1.1** | 런 JSON 쓰기·삭제, 이어하기 시 던전 복귀, 후퇴=원정 포기, 정산 | 파일 쓰기·마을 복귀 시 삭제는 구현됨. 던전 이어하기·후퇴 포기는 후속 |
| **v1.region** | 게시판 지역 4종 + en/ko + 지역별 인카운터 | 구현됨 |
| **v2** | 여관, 상점 NPC, 길이별 난이도 | 설계만 |

---

## v1 — 허브 + 소문 (현행 요약)

초기 초안(월드 존·전체화면 오버레이)은 **폐기**. 길이·지역 표·확정 흐름·원정 종료 규칙은 유지.

### 위치

| 역할 | 경로 |
|------|------|
| 마을 루트 | [`scenes/village/village.tscn`](../../scenes/village/village.tscn) + [`village.gd`](../../scenes/village/village.gd) |
| 마을 셸 | [`ui/village/village_shell.tscn`](../../ui/village/village_shell.tscn) |
| 소문 | [`ui/village/challenge_board.tscn`](../../ui/village/challenge_board.tscn) — MenuShell `Tab.BOARD` |
| 서가 | [`ui/village/bookshelf.tscn`](../../ui/village/bookshelf.tscn) — `Tab.SHELF` |
| 원정 파라미터 | [`data/village/challenge_def.gd`](../../data/village/challenge_def.gd) · `SaveManager.pending_run` |
| 게임 진입 | [`profile_select.gd`](../../scenes/title/profile_select.gd) → `village.tscn` |
| 던전 기동 | [`dungeon.gd`](../../scenes/dungeon/dungeon.gd) — `take_pending_run`으로 `generate` |

소문·서가는 **MenuShell Sheet**. 월드 오브젝트 클릭으로 열지 않는다.  
씬 트리 상세: [`architecture/village.md`](../architecture/village.md).

### 마을 · HUD

- 고정 배경만. 플레이어 이동 없음. HP는 허브 입장 시 최대. 여관·상점은 v2.
- 허브: GameHud 숨김, `VillageShell` TopBar + HubNav + 게임 로그.
- 던전: GameHud·미니맵 유지. Map Sheet는 던전만.

| 항목 | 마을 | 던전 |
|------|------|------|
| 소문 / 서가 | Sheet | 없음 |
| 인벤 / 스탯 / 설정 | Sheet | Sheet |
| 설정 → 나가기 | **타이틀** | v1: 타이틀. v1.1: **마을**(원정 포기) 추가 |

Sheet가 열려 있으면 Esc/BACK은 그 Sheet만 닫는다.

### 소문 Sheet · 지역 · 길이

맵을 미리 보여 주지 않는다. 열기만으로는 `FloorGenerator`를 호출하지 않는다.  
좌: **지역** 열 + **길이** 열. 우: 설명. ←/→ 열 전환.

| id | en | ko |
|----|----|----|
| `cemetery` | Cemetery | 묘지 |
| `grove` | Grove | 숲 |
| `mansion` | Mansion | 영지 |
| `battlefield` | Battlefield | 전장 |

| id | 표시 (en / ko) | `room_count` | 보상 배수 (표시만) |
|----|----------------|--------------|-------------------|
| `short` | Short / 짧음 | 8 | ×1 |
| `normal` | Normal / 보통 | 12 | ×1.5 |
| `long` | Long / 긴 | 16 | ×2 |

보상 배수는 **UI 문구**만 ([`loot.md`](loot.md) · [`shop.md`](shop.md)).

| 조작 | 동작 |
|------|------|
| ← / → | 지역 ↔ 길이 열 |
| 상하 / 클릭 | 행 포커스 · 우 패널 갱신 |
| `ui_accept` / CHALLENGE | 도전 확정 → 생성 + 던전 입장 |
| `ui_cancel` / BACK | Sheet 닫기. 맵 없음 |

### 도전 확정 · 원정 종료

```
소문 CHALLENGE
  → seed = randi()
  → save_run + pending_run
  → dungeon.tscn → FloorMap.generate(seed, room_count)
```

| 결과 | 현행 |
|------|------|
| 보스 클리어 / 전멸 | `return_to_village()` — 메타 유지, `clear_run` |
| 후퇴 | 입구 유지 (포기·마을은 v1.1) |
| 설정 → 메인 메뉴 | 타이틀 |

에디터에서 `dungeon.tscn` 직접 실행 시 `pending_run` 없으면 `randi()` + 12방 폴백.

### API

```
ChallengeBoard.setup(ui_manager, footer)
Bookshelf.setup(ui_manager, footer)
UIManager.open_tab(BOARD | SHELF | …)
UIManager.return_to_village()
UIManager.set_hub_mode(true)
UIManager.refresh_bookshelf()
```

---

## v1.1 — 런 세이브 · 원정 수명

[`save-load.md`](save-load.md) 레이어 2와 맞춘다.

- 도전 확정 → `save_run` (`dungeon_id`, `length_id`, `seed`, `room_count`, 이후 `current` / `visited` / `cleared`)
- 이어하기: 런 있으면 `dungeon.tscn`(시드로 `generate` 후 플래그 덮어쓰기), 없으면 `village.tscn`
- 보스 클리어 → 정산 → 메타 병합 → `clear_run` → 마을
- 후퇴 → 원정 포기 확인 → `clear_run` → 마을
- 전멸 → 런만 삭제 → 마을
- 던전 설정에 **마을로 돌아가기**(원정 포기)

중도 세이브는 던전에서 메타+런을 같이 쓴다. 마을에서는 메타만 있고 런 파일이 없다.

---

## v2 — 햄릿 확장

- 여관: 유료 또는 무료 HP/마나 회복
- 상점: 인벤과 별도 NPC. 구매·판매가는 [`shop.md`](shop.md) `ShopPricing`
- 보급(횃불·식량): Stamina 상한/재생과 같이 검토 ([`stats.md`](stats.md))
- 파티 편성: 전투 다수 아군 이후
- 길이별 적 레벨·방당 랜덤 조우

소문·서가는 **Sheet** 유지. 월드에 퀘스트 목록을 펼치지 않는다.

---

## 관련 문서

| 문서 | 현행 |
|------|------|
| [`title.md`](../architecture/title.md) | 프로필 → `village.tscn` |
| [`map.md`](map.md) | 소문 확정 후 `generate` |
| [`save-load.md`](save-load.md) | 런 쓰기·삭제. 던전 이어하기는 후속 |
| [`combat.md`](combat.md) | `lose` → `return_to_village()` |
| [`hud.md`](hud.md) | 허브에서 GameHud 숨김 |
| [`equipment.md`](equipment.md) · [`bookshelf.md`](bookshelf.md) | 서가 봉인 |
| [`shop.md`](shop.md) | v2 NPC가 `ShopPricing` 호출 |

---

## 비목표 (당분간)

- 게시판에서 층 미리보기·시드 리롤
- 월드 존 클릭으로 소문/서가 열기
- 4인 파티, 스테이지 코치, 스트레스·기벽, 건물 업그레이드, 묘지
- 사이드뷰 햄릿, 출발 전 보급 쇼핑 강제
- 전멸 시 캐릭터/슬롯 삭제, 마을 절차 생성·전투
- 클라우드, 원정 중 전투 세이브
