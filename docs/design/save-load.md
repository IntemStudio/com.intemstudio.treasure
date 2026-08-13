# 세이브 / 로드 — 후속 설계

**v1 현황(구조):** [`docs/architecture/save-load.md`](../architecture/save-load.md)  
이 문서는 **미구현** 로드맵만 다룬다.

최종 목표는 4레이어 분리(메타 / 런 / 설정 / 헤더·무결성). v1은 메타 + 설정 분리 + `version`/`meta`까지 반영됨.

---

## 로드맵

| 단계 | 범위 | 상태 |
|------|------|------|
| v1 | 메타 슬롯 JSON, 프로필 슬롯 UI, `` ` `` 개발 오버레이 | 구현됨 → 구조 문서 |
| **v1.1** | 무결성 강화, 선택적 자동 저장 | 설계만 |
| **v2** | 런·던전 상태 분리, 메타↔런 병합 | 설계만 |

---

## v1.1 — 무결성 (레이어 4 확장)

- `meta.build`, `meta.git_commit` (또는 앱 버전 문자열)
- 페이로드 체크섬 / HMAC (손상·치트 감지)
- 불일치 시 `corrupt` 또는 경고 후 로드 정책
- (선택) 팝업 직후·주기적 자동 저장 UI

설정(`settings.cfg`)과 슬롯 JSON은 계속 분리.

---

## v2 — 런 (레이어 2)

### 저장소

```
user://saves/
  slot_N.json       # 메타 (기존)
  slot_N_run.json   # 런 (신규) — 메타와 수명·저장 빈도 분리
```

### 포함 후보
던전 id, 층, 시드, 탐험 맵 상태, 런 전용 인벤/버프.  
맵·방 텔레포트 스펙: [`map.md`](map.md).

### 규칙 예
- 귀환 성공 → 런 보상만 메타에 병합 후 `clear_run`
- 사망 → 런만 삭제 (메타 유지). 전투 사망 정책: [`combat.md`](combat.md)

### API (예정)

```
SaveManager.save_run(slot, run)
SaveManager.load_run(slot) -> RunState
SaveManager.clear_run(slot)
```

`SaveGame`에 `run` 필드를 두되, 디스크에서는 별도 파일 권장.

### 마이그레이션
구버전 단일 파일에 런 필드가 섞여 있으면 마이그레이터로 `slot_N_run.json`으로 분리.

---

## 비목표 (당분간)

- 클라우드 동기화, 멀티플레이어
- `ItemData` 전체 JSON 덤프, `character_stats.tres`에 직접 세이브
- 암호화 (필요 시 v1.1 HMAC 이후)
