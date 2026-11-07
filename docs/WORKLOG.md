# 작업 로그

세션이 끊겨도 이 파일만 보고 이어갈 수 있게 유지한다. 단계가 끝날 때마다 "현재 위치"를 갱신하고 로그를 아래에 추가한다.

## 현재 위치

- **브랜치:** `feature/M2-waves` (`feature/M1-combat` 위에 분기, 미푸시, `develop` 미병합)
- **상태:** M2 구현 완료. 사용자 확인 대기.
- **다음 할 일:** 사용자 플레이 피드백 반영, 최종 보스 통과 규칙 결정(아래 "사용자 플레이 때 확인할 것" 4번). 그다음 M3.
- **사용자 플레이:** 아직 안 함. 피드백이 와 있으면 그것부터 반영한다.
- **막힌 것:** 없음.

## 재개 방법

1. [PLAN.md](PLAN.md)로 방향 확인, 이 파일의 "현재 위치" 확인.
2. `git status`, `git log --oneline -10`으로 실제 상태 대조. `title_screen.tscn` 한 줄 변경만 남아 있으면 정상이다.
3. `test_runner`를 돌려 통과를 확인한다. `.godot` 캐시가 없으면 먼저 `--import`.
4. 체크리스트의 첫 미완료 항목부터 진행.

## 주의 사항

- 프로젝트는 Godot 4.7.2다. 4.2.1 에디터로 저장하지 않는다.
- `scenes/title/title_screen.tscn`의 UID 한 줄 변경은 작업 전부터 있던 것이다. 커밋할 때 뺀다: `git add -A -- . ':!scenes/title/title_screen.tscn'`
- 커밋 메시지는 `^_^ [M2] 내용` 형식, 끝에 Co-Authored-By 줄.
- GroMoon 로컬 작업(UNIT-005, MAP-005, UNIT-006 일부)은 원격에 없다. 푸시되면 `grid.gd`에서 충돌하며, 이쪽 구현을 기준으로 정리한다.
- Notion 태스크 상태는 아직 안 바꿨다. 사용자 허락 후 갱신한다.

## 사용자 플레이 때 확인할 것

1. 드래그 손맛, UNIT-005 드래그 버그 재현 여부.
2. ZONE 장판 위치가 랜덤인 것이 재미있는지.
3. 초반 속도와 뽑기 비용. Easy는 후반까지 위협이 약해 지루할 수 있다.
4. 최종 보스 규칙. 지금은 일반 보스처럼 라이프 5만 깎으므로, 통과시켜도 라이프가 남으면 Clear다. 도달 시 즉시 패배로 바꿀지 결정한다.
5. Hard, Extreme 맵 경로가 배치 고민을 만드는지. 적 크기는 현재 값(소형 1.25배)을 유지했다.

## 명령

Godot 경로:
- Windows: `C:\Users\wonhs\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`
- macOS: `/Applications/Godot.app/Contents/MacOS/Godot`

macOS에는 `timeout`이 없다. 아래 명령의 `timeout N` 자리에 `perl -e 'alarm shift; exec @ARGV' N`을 쓴다.

```bash
GODOT="/c/Users/wonhs/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"
"$GODOT" --headless --path . --import
timeout 120 "$GODOT" --headless --path . --fixed-fps 60 res://tests/test_runner.tscn
timeout 60 "$GODOT" --path . --fixed-fps 60 res://tests/screenshot.tscn -- <저장폴더> Easy 10
timeout 60 "$GODOT" --path . --fixed-fps 60 res://tests/menu_shot.tscn -- <저장폴더>
timeout 45 "$GODOT" --path . res://tests/input_test.tscn
timeout 1700 "$GODOT" --headless --path . --fixed-fps 60 res://tests/balance_sim.tscn
```

- `test_runner`: 로직 전체 (헤드리스).
- `input_test`: 마우스 이벤트로 버튼·드래그 확인 (창 모드 필요).
- `balance_sim`: 봇이 난이도별로 2판씩 플레이하고 결과 출력 (`boss_leaks`는 경로 끝에 닿은 보스 수).
- `screenshot`: 마지막 인자는 시작 웨이브. 보스 화면은 10, 최종 보스 화면은 총 웨이브 수.

주의: 스크립트 파싱 오류가 나면 Godot이 종료되지 않고 멈춘다. 반드시 `timeout`을 붙이고 로그는 파일로 받는다.

## 체크리스트

### M0 기반

- [x] Godot 4.7.2 업그레이드, 임포트 확인
- [x] UnitData, EnemyData, 공용 씬, tres 생성
- [x] 기존 유닛·적 씬과 중복 스크립트 제거 (UNIT-005 해결)
- [x] 격자 20×9, 경로 칸 금지, 드롭 하이라이팅 (MAP-005 재구현)
- [x] 경로 타일 정렬, 경로 표시
- [x] 테스트 러너, M0 검증, 커밋

### M1 전투

- [x] 적 HP, 경로 이동, 라이프 감소
- [x] SHOT, ZONE 공격, 자동 타겟팅
- [x] 골드, 뽑기 비용
- [x] WaveManager, 웨이브 진행
- [x] HUD, Gameover, Clear
- [x] 테스트, 화면 확인, 커밋
- [ ] 사용자 플레이 확인 (사용자가 나중에 진행)

### M2 웨이브

- [x] `feature/M1-combat`에서 `feature/M2-waves` 분기
- [x] 세력 전환: `WaveManager.faction`을 전체 웨이브 1/3마다 Nautolan → Klaed → Nairan으로 변경
- [x] 보스: 10웨이브마다 `dreadnought` + 보스 체력 배율, 마지막 웨이브는 최종 보스, HUD에 보스 웨이브 표시
- [x] 적 겹침 완화 (MAP-001 TODO): 경로별 분산 또는 함선별 속도 차이 확인
- [x] Hard, Extreme 맵: `scenes/game/maps/hard.tscn`, `extreme.tscn`은 현재 빈 씬. Path2D 여러 개로 분기 구성, 제어점은 타일 중앙(x = 64c + 32, y = 96 + 64r), `game_play.gd`의 `MAP_SCENES` 교체
- [x] 적 크기 확인 (MAP-001 TODO: 조금 더 크게)
- [x] 테스트 추가: 세력 전환, 보스 스폰, 다중 경로 스폰과 칸 금지
- [x] `balance_sim` 재측정, 결과 기록
- [x] 화면 확인, 커밋
- [ ] 사용자 플레이 확인

### M3 이후

[PLAN.md](PLAN.md) 5장 참고. 시작할 때 이 목록을 세분화한다.

## 로그

### 2026-11-07

- Notion 기획, 태스크, 스케치, repo 에셋, git 이력 조사 완료. 추천안 6개 승인.
- `docs/PLAN.md`, `docs/WORKLOG.md` 작성, `feature/M0-foundation` 생성.
- **M0 완료.** 테스트 110건 통과, 창 실행 스크린샷 확인.
  - 유닛 12개 씬과 적 8개 씬을 공용 씬 + tres로 교체 (`data/units` 12개, `data/enemies` 24개). 3세력 함선 전부 데이터로 등록됨.
  - 텍스처는 경로로 지연 로드 (시트 1장 9MB, 29종 전부 올리면 부담).
  - 드래그는 `GridManager`만 담당. 버튼 놓침은 `Input.is_mouse_button_pressed` 폴링으로 방지.
  - 격자는 `Grid` 노드를 y=64로 내리고 20×9칸. 위 64px는 HUD, 아래 80px는 버튼 영역.
  - 경로 제어점을 타일 중앙으로 정렬, 시작점을 화면 밖 -40으로 이동.
  - MAP-005는 Notion의 "크리스탈" 버전 채택 (마지막 저장본). 드래그 중 사거리 원 추가.
  - `WaveManager` 신규. `easy.gd`, `normal.gd` 삭제, 맵 씬은 Path2D만 보유.
  - Hard, Extreme은 M2 전까지 Normal 경로를 임시 사용.
- 사용자 PC에서 Godot 4.2.1 에디터(PID 3420)가 이 프로젝트를 열고 있었음. 프로젝트는 이제 4.7이므로 4.2.1로 저장하면 안 됨. 사용자에게 알릴 것.
- **M1 구현 완료.** 로직 259건, 마우스 입력 테스트, 봇 시뮬레이션 통과.
  - `GameState` 오토로드(골드, 라이프, 종료), `HUD` 씬, 결과 패널, `Projectile`, `ZoneField` 추가.
  - SHOT은 사거리 안 가장 앞선 적 추적. ZONE은 사거리 안 경로 위 임의 지점에 장판. 다른 칸으로 옮기면 위치를 다시 뽑고, 제자리에 놓으면 유지.
  - 시작 골드 100, 뽑기 20G, 웨이브 보상 10 + 웨이브×2, 체력 배율 1 + 0.15n + 0.01n².
  - 현재 전 유닛 C등급, 뽑기는 균등 확률. 등급 가중치는 M3.
  - **M0 실수 수정:** 적 씬 삭제 시 로비 난이도 버튼의 장식 함선 참조를 놓쳤음. `scenes/lobby/ship/`에 장식 전용 씬으로 복구하고, 끊어진 참조를 찾는 테스트 추가.
  - `GridManager`가 마우스 위치를 입력 이벤트로 추적하도록 변경 (합성 이벤트 테스트 가능).
- 봇 결과 (C 유닛만, 조합·강화 없음, 경로 최적 배치):

| 난이도 | 도달 웨이브 | 시간 | 결과 |
|---|---|---|---|
| Easy | 30/30 | 34~35분 | 클리어, 라이프 21~24 남음 |
| Normal | 25~26/40 | 25~28분 | 패배 |
| Hard | 21/50 | 20분 | 패배 |
| Extreme | 13/60 | 13분 | 패배 |

  Normal 이상은 조합·강화·증강이 있어야 깰 수 있는 곡선이다. M3~M4 후 다시 맞춘다. 봇이 화면 중앙에 그대로 두면 Normal은 웨이브 4~5에서 진다. 뽑은 유닛이 경로 사거리 밖에 생기기 때문이다.
- 코드 리뷰 지적 1건 수정: 처치된 적이 같은 프레임에 경로 끝에 닿으면 골드와 라이프가 둘 다 처리되던 문제. 회귀 테스트 추가.
- 최종 확인: 로직 261건, 마우스 입력 테스트 통과. 사용자 요청으로 M1에서 작업 중단, 다음은 M2.
- **M2 구현 완료.** 로직 373건, 마우스 입력 테스트 통과. 작업 환경이 macOS로 바뀜 (Godot 4.7.2 동일, Apple M1).
  - 세력은 `faction_for_wave`로 웨이브 번호에서 계산한다. Easy 기준 1~10 Nautolan, 11~20 Klaed, 21~30 Nairan.
  - 보스는 10웨이브마다, 호위를 절반으로 줄이고 맨 뒤에 나온다. 체력 배율 일반 2배, 최종 3배, 최종 보스 크기 1.5배. 처음 값 3배/6배는 Easy 봇이 보스를 하나도 못 잡아 낮췄다.
  - 보스 웨이브는 HUD 웨이브 표시가 빨간색 `BOSS WAVE`로 바뀌고, 준비 시간에 "보스 출현 N초"를 보여 준다.
  - Hard는 입구와 출구를 공유하는 위아래 2갈래, Extreme은 입구 2 × 출구 2로 경로 4개이고 중앙 복도를 공유한다.
  - 겹침 완화: 적마다 경로 중심에서 ±12px 벗어나 이동(`lane`). 대형 함선은 같은 속도로 줄지어 겹치므로 앞 함선 길이만큼 스폰 간격을 늘렸다. 함선별 속도 차이는 M1 그대로다.
  - 경로 표시는 `CanvasGroup`으로 묶어 공유 구간이 진해지지 않게 했다.
  - 적 크기: 스크린샷 확인 결과 소형 함선 약 50px로 경로 폭(40px)과 행성에 어울려 수치는 바꾸지 않았다. 체력바 폭은 스프라이트 크기에 비례하도록 변경.
- 봇 결과 (C 유닛만, 조합·강화 없음, 경로 최적 배치):

| 난이도 | 도달 웨이브 | 시간 | 보스 통과 | 결과 |
|---|---|---|---|---|
| Easy | 30/30 | 36~37분 | 1기 (최종 보스) | 클리어, 라이프 25 남음 |
| Normal | 28~29/40 | 33~35분 | 2기 | 패배 |
| Hard | 13~16/50 | 11~15분 | 1기 | 패배 |
| Extreme | 13~14/60 | 12~13분 | 1기 | 패배 |

  Hard는 M1의 21웨이브에서 13~16으로 내려갔다. 이전 값은 임시로 쓰던 Normal 경로(약 3400px) 기준이고, 새 맵은 약 2400px로 더 짧다. Normal 이상은 여전히 조합·강화·증강을 전제로 한 곡선이라 M3~M4 후 다시 맞춘다. 봇이 Normal 이상에서 마지막 웨이브까지 간 적은 없으므로, 그 구간은 웨이브 구성 테스트로만 확인했다.
- 고의 결함 4종(세력 고정, Hard 맵 교체, 분산 제거, 대형 함선 간격 제거)을 넣어 새 테스트가 모두 잡아내는 것을 확인했다.
- 에디터가 `project.godot`의 `[gui]` 두 줄 순서를 바꾼다. 내용 변화가 없어 커밋하지 않았다.
