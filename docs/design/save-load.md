# 세이브 / 로드 — 후속 설계

**v1 현황(구조):** [`docs/architecture/save-load.md`](../architecture/save-load.md)  
이 문서는 **미구현** 로드맵만 다룬다. `slot_N_run.json` 쓰기·삭제는 구현됨. 이어하기 던전 복귀·메타↔런 병합 정산은 후속.

---

## 로드맵

| 단계 | 범위 | 상태 |
|------|------|------|
| v1 | 메타 슬롯 JSON, 프로필 슬롯 UI, `` ` `` 개발 오버레이 | 구현됨 → 구조 문서 |
| **v1.1** | 무결성 강화, 선택적 자동 저장 | 설계만 |
| **v2** | 런·던전 상태 분리, 메타↔런 병합 | 파일 쓰기·삭제·장비 스냅샷 구현됨. 던전 이어하기·정산 병합은 후속 |

---

## v1.1 — 무결성 (레이어 4 확장)

- `meta.build`, `meta.git_commit` (또는 앱 버전 문자열)
- 페이로드 체크섬 / HMAC (손상·치트 감지)
- 불일치 시 `corrupt` 또는 경고 후 로드 정책
- (선택) 팝업 직후·주기적 자동 저장 UI

설정(`settings.cfg`)과 슬롯 JSON은 계속 분리.

---

## v2 — 런 (레이어 2)

쓰기·삭제·스냅샷은 구현됨 ([`architecture/save-load.md`](../architecture/save-load.md)). 아래는 **남은 것**.

### 아직 없는 규칙

- 이어하기: 런 있으면 던전(시드로 `generate` 후 `visited`/`cleared`/`current` 덮어쓰기), 없으면 마을
- 귀환 성공 → 런 보상만 메타에 병합 후 `clear_run` → 마을 (지금은 장비를 이미 메타에 넣으므로 병합할 전리품 가방이 없음, [`loot.md`](loot.md))
- 후퇴 → 원정 포기 확인 → `clear_run` → 마을 (지금은 입구 잔류)
- `dungeon._ready`가 `load_run`으로 복원하지 않음. `pending_run`으로 새 층만 연다

### API (구현됨)

```
SaveManager.save_run(slot, run)
SaveManager.load_run(slot) -> Dictionary
SaveManager.clear_run(slot)
SaveManager.has_run(slot) -> bool
SaveSerializer.run_equipment_snapshot(inventory)
```

`load_run`은 읽기만. 프로필·마을이 던전 씬으로 보내지 않는다.

---

## 비목표 (당분간)

- 클라우드 동기화, 멀티플레이어
- `ItemData` 전체 JSON 덤프, `character_stats.tres`에 직접 세이브
- 암호화 (필요 시 v1.1 HMAC 이후)
