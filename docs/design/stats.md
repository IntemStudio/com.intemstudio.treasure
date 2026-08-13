# 능력치 — 후속 설계

**v1 현황(구조):** [`docs/architecture/stats.md`](../architecture/stats.md)  
이 문서는 **성장·전투 매핑**과 미구현 UI 열을 다룬다. 스탯 탭 레이아웃·포인트 투자는 구현됨.

성장은 No Rest for the Wicked식 **8속성 투자**. 전투·기술은 Loop Hero식 **자동 ATB 수치**.  
관련: [`combat.md`](combat.md) (세션 공식) · [`hud.md`](hud.md) (HP/마나·기술 칸) · [`village.md`](village.md) (원정 피로) · [`equipment.md`](equipment.md) (룬은 기술 소스, 보석은 접두사와 분리).

---

## 한 줄

속성은 풀과 스케일만 키우고, 한 판의 세기(회피·흡혈·반격·기술)는 장비 접두사와 자동 기술이 만든다.

---

## 로드맵

| 단계 | 범위 | 상태 |
|------|------|------|
| **v1** | 8속성 투자, GENERAL/DEFENSE/WEIGHT, 무기 표, XP→포인트 | 구현됨 → 구조 문서 |
| **v1.1** | 접두사 수치 키, `CombatStatsBuilder`가 전투 스탯 합산, 스탯 탭 COMBAT 열 | 구현됨 → 구조 문서 |
| **v1.2** | 세션이 회피·크리·흡혈·반격·리젠·Magic HP·스태미나 적용 | 구현됨 → [`combat.md`](../architecture/combat.md) |
| **v1.3** | 기술 게이지 + 마나 소모 자동 발동, Focus→Mana 표기 | 설계만 — HUD는 [`hud.md`](hud.md) |
| **v2** | 무게 등급 전투 보정, Poise=ATB 저항, 원소 피해 연동 | 설계만 |

계수(`k`)는 빌더 상수·`combat_rules.tres`에서 튜닝한다.

---

## 층

```
CharacterStats.attributes     # 투자 (세이브)
        ↓ recalculate_derived
CharacterStats.general/defense/weight/hp/mana   # 표시·자원 풀
        ↓ CombatStatsBuilder.build(character, inventory)
CombatStats                   # 전투 스냅샷 (세션만 사용)
```

스탯 탭 COMBAT 열과 전투 시작은 **같은** `CombatStatsBuilder.build`를 쓴다. 공식을 두 곳에 두지 않는다.

| 층 | 역할 | 지금 |
|----|------|------|
| `CharacterStats` | 8속성, HP/마나, 표시용 파생 | 구현. 전투 숫자는 빌더 |
| `CombatStats` | Loop Hero 전투 필드 + 스태미나 | 구현. 빌더가 채움 |
| `CombatRules` | 방어 곡선, ATB, 스태미나 비용, Magic HP·반격 규칙 | 구현. 세션이 소비 |
| `ItemData.affixes` | 접두사 | `id`/`value`/`text` |
| `ItemData.skills` | 무기 기술 4칸 | HUD 이름만 (v1.3 전) |

---

## v1 — 유지

`ATTRIBUTE_IDS` 8개를 바꾸지 않는다. 레벨당 3포인트, 시작값 10.

새 투자 속성을 만들지 않는다. Attack Speed·Vampirism 등은 **파생 + 접두사**다.

---

## 8속성 — 의미

실시간 액션용 의미는 버린다. 자동전투에 맞게 재정의한다.

| id | 라벨 | 투자 시 | 버리지 않는 NRFW 의미 |
|----|------|---------|----------------------|
| `health` | Health | `max_hp` | — |
| `stamina` | Stamina | 전투 스태미나 풀·재생. 공격/반격 25, 회피 10. 고갈 → Tired(회피 반감) | 구르기·공격 횟수 바 |
| `strength` | Strength | 물리 피해, Defense, Retaliation. 힘 스케일 무기 | — |
| `dexterity` | Dexterity | Attack Speed, Evasion, Crit, Counter. 민첩 스케일 무기 | — |
| `intelligence` | Intelligence | Magic Damage, Damage to All, **공격 기술 위력**. 지능 스케일 무기 | — |
| `faith` | Faith | Vampirism, Regen, Magic HP, **유지 기술 위력**. 신앙 스케일 무기 | — |
| `focus` | Focus → **Mana** (v1.3 표기) | 기술 자원. `mana_max` / 재생. 기술 ATB가 찰 때 소모 | 100점마다 룬 바 추가, 수동 룬 |
| `equip_load` | Equip Load | 무게 한도. 등급이 전투 보정 (v2) | 퀵스텝/롤/숄더배시 |

무기 `scales_with`는 STR/DEX/INT/Faith 중 **1~2개**만 받는다. 네 속성에 분산 투자는 자동전투에서 약해지게.

원정 피로(횃불·식량, [`village.md`](village.md) v2)는 새 스탯이 아니다. 같은 Stamina의 상한 또는 재생을 깎는다.

HUD에 스태미나 바를 상시 두지 않는다. 전투 중 표시는 [`combat.md`](combat.md) 구현 직전.

---

## 파생 전투 스탯

`CombatStats` 필드. 속성에 넣지 않고 표시만 한다.

| 필드 | 주 공급 | 효과 |
|------|---------|------|
| `damage_min` / `damage_max` | 무기 total × 스케일 | 평타. Defense에 깎임 |
| `attack_speed` | DEX + 접두사 + Light | `CombatRules.attacks_per_sec`의 IAS |
| `evasion` | DEX + 경장갑 + 접두사 | 완전 회피. 스태미나 10 |
| `crit_chance` / `crit_damage` | DEX + 접두사 | 크리. 방어 무시 여부는 구현 직전 |
| `counter_chance` | DEX + 접두사 | 피격·회피 시 반격. ATB 리셋 |
| `defense` | STR + 갑옷 + Heavy | Loop Hero 곡선 (`apply_defense`). **NRFW % Armor와 병행하지 않음** |
| `vampirism` | Faith + 접두사 | 입힌 피해 % 회복 |
| `regen_per_sec` | Faith + 접두사 | 전투 중·방 이동 중 |
| `magic_hp` | Faith + 장신구 | 전투마다 리필, HP보다 먼저 |
| `magic_damage` | INT + 접두사 | 방어 무시 추가 피해 |
| `damage_all` | INT + 광역 기술/접두사 | 주 타깃 외 간접 피해 |
| `retaliation` | STR + Heavy + 투구류 | 맞을 때 반사. Defense에 깎임 |

적 유닛 `.tres`도 같은 `CombatStats`를 쓴다. 히어로만 빌더를 통과한다.

---

## v1.1 — 빌더·접두사

### 접두사

`ItemData.affixes`에 합산 키를 넣는다. `text`는 UI용으로 유지.

```
{ "id": "crit_chance", "value": 0.10, "positive": true, "text": "+10% Critical Chance" }
```

`id`는 `CombatStats` 필드명과 같게. 장착 슬롯만 합산. 음수 접두사는 `value` 음수.

### 빌더

```
CombatStatsBuilder.build(character, inventory) -> CombatStats
```

인벤이 없으면 속성·무기 표만. 있으면 장착 접두사·`attack`/`defense`를 더한다.

초안 합산 (10 초과분 `over = attr - 10`):

| 출력 | 식 |
|------|----|
| `max_hp` | `character.hp_max` |
| `damage_*` | 주무기 total, 구간비 현행 `WEAPON_RANGE_RATIO` |
| `attack_speed` | `over(dex) * 0.01` + 접두사 |
| `evasion` | `over(dex) * 0.005` + 접두사 |
| `crit_chance` | `over(dex) * 0.005` + 접두사 |
| `crit_damage` | 기본 1.4 + 접두사 |
| `counter_chance` | `over(dex) * 0.005` + 접두사 |
| `defense` | 갑옷 `ItemData.defense` + `over(str) * 1` + 접두사. **`defense.armor` 키를 전투에 그대로 복사하지 않음** |
| `vampirism` | `over(faith) * 0.005` + 접두사 |
| `regen_per_sec` | `over(faith) * 0.1` + 접두사 |
| `magic_hp` | `over(faith) * 1` + 접두사 |
| `magic_damage` | `over(int) * 0.5` + 접두사 |
| `damage_all` | 접두사·광역 기술 (속성만으로는 0에 가깝게) |
| `retaliation` | `over(str) * 0.3` + 접두사 |

`recalculate_derived`의 `defense["armor"]`는 표시용 Defense로 이름을 바꾼다. 값은 빌더 `defense`와 같게 맞춘다.

### 스탯 탭 열 (v1.1)

왼쪽 8속성은 유지.

| 열 | 내용 |
|----|------|
| **GENERAL** | Life, Stamina, Stamina Regen, Mana, Mana Regen (`Focus` / `Focus Gain` 라벨 폐기) |
| **COMBAT** | Damage, Attack Speed, Crit, Magic Damage, Damage to All, Vampirism, Regen, Counter, Evasion, Magic HP, Retaliation |
| **DEFENSE** | Defense. Poise·원소 4종은 v2까지 접어둠 |
| **WEIGHT** | 현행 max / current / class / bar |

무기 표 유지: Base / Attr Bonus / Other / Total. Attr Bonus는 `scales_with`만.

Footer **Insight**: 선택한 속성이 올리는 능력치 설명 (`ATTR_DESC_*`). 버튼은 v1에 있음.

`Focus` → `Mana` 문자열은 [`hud.md`](hud.md) v2와 같이 v1.3에서 HUD와 동시에 바꾼다. v1.1 COMBAT 열은 영문 키 그대로여도 된다.

---

## v1.2 — 세션

[`combat.md`](combat.md) 소관. 스탯 설계가 요구하는 적용 순서:

1. 회피 판정 (실패 시에만 피해)
2. Magic HP → HP
3. Defense 또는 `magic_damage` 무시
4. Crit
5. Damage to All (주 타깃 외, 반격·직접기 트리거 없음)
6. Vampirism · Retaliation · Counter (규칙 플래그 그대로)
7. `regen_per_sec` 틱
8. 스태미나 소모/재생, Tired

평타 ATB는 현행. `CombatRules`의 스태미나·Magic HP·반격 상수는 재사용.

---

## v1.3 — 기술·마나

무기 `skills` 4칸·HUD 행은 유지한다. 전투 중 **수동 입력은 없다**.

- 평타 ATB와 별도 **기술 게이지**. 가득 차면 슬롯 순서로 발동, `mana` 소모
- 마나 부족이면 건너뛰고 평타만
- 위력: 무기 Base + INT(공격기) / Faith(유지기)
- HUD 4칸: 이름 + 충전. 키 바인딩은 탐험 소모품만 ([`hud.md`](hud.md) v1.1)

접두사 = 스탯. 기술 = 행동.

| 유형 | 스케일 | 전투 |
|------|--------|------|
| 강타 | STR | 평타 배율 |
| 연격 | DEX | 짧은 공속 또는 추가 타 |
| 광역 | INT | `damage_all` 한 방 |
| 마법탄 | INT | `magic_damage` |
| 흡혈 일격 | Faith | 이번 타 흡혈 증가 |
| 치유/재생 | Faith | Regen 버스트 |
| 보호막 | Faith | Magic HP |
| 반격 태세 | DEX/STR | 다음 피격 Counter 확정 |
| 가시 | STR | 짧은 Retaliation |

기술 데이터 리소스·밸런스 수치는 구현 직전. 캠프 특성(Loop Hero Trait)은 마을 여관/Insight **이후**.

---

## v2 — 무게·Poise·원소

### 무게 등급

현행 비율 유지: Light < 30%, Normal < 70%, Heavy.

| 등급 | 전투 (초안) |
|------|-------------|
| Light | +Evasion, +Attack Speed, Defense 감소 |
| Normal | 보정 없음 |
| Heavy | +Defense, +Retaliation, 공속·회피 감소 |

구르기 모션은 없다.

### Poise

실시간 경직이 없다. **맞을 때 ATB가 밀리지 않을 확률**(또는 밀림량 감소). `defense.poise`는 이 값. 세션 연동 전엔 표시만.

### 원소

Heat / Cold / Electric / Plague는 지역 4종과 나중에 맞춘다. `CombatStats`에 속성 피해가 생기기 전에는 DEFENSE에서 접어 둔다.

---

## 관련 문서에 미치는 결정

| 문서 | 점 |
|------|----|
| [`architecture/stats.md`](../architecture/stats.md) | v1 UI. COMBAT 열·라벨 변경은 이 문서 v1.1+ |
| [`combat.md`](combat.md) | 빌더 출력을 세션이 소비. 고급 스탯·기술 게이지는 전투 후속 |
| [`hud.md`](hud.md) | Focus→Mana. 전투 중 기술은 자동, 키는 소모품 |
| [`village.md`](village.md) | 보급 피로는 Stamina 상한/재생 |
| [`equipment.md`](equipment.md) | 접두사 `id`/`value`만 수치. 룬은 v1.3 게이지 소스. 보석은 `AFFIX_FIELDS`에 가산하지 않음 |

---

## 비목표 (당분간)

- 9번째 투자 속성 (공속·흡혈을 직접 찍기)
- NRFW % Armor와 Loop Hero Defense 동시 적용
- 포커스 바를 100점마다 한 칸씩 늘리기
- 전투 중 기술 수동 발동 (룬 버튼)
- Loop Hero 소환 스탯 (Skeleton Level 등) — 파티/소환 전까지
- 타일/카드 스탯 버프 ([`combat.md`](combat.md) 비목표)
- 클래스별 스탯 풀 잠금 (히어로 단일)
- 스탯 탭에 스태미나 상시 바 (GENERAL 수치만)
