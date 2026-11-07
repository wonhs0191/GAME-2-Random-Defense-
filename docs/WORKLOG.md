# 작업 로그

세션이 끊겨도 이 파일만 보고 이어갈 수 있게 유지한다. 단계가 끝날 때마다 "현재 위치"를 갱신하고 로그를 아래에 추가한다.

## 현재 위치

- **브랜치:** `feature/M1-combat` (`feature/M0-foundation` 위에 분기, 둘 다 미푸시)
- **진행 중:** M1 전투
- **다음 할 일:** 아래 체크리스트 첫 미완료 항목
- **막힌 것:** 없음

## 재개 방법

1. [PLAN.md](PLAN.md)로 방향 확인, 이 파일의 "현재 위치" 확인.
2. `git status`, `git log --oneline -10`으로 실제 상태 대조.
3. 체크리스트의 첫 미완료 항목부터 진행.

## 명령

Godot 경로: `C:\Users\wonhs\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`

```bash
GODOT="/c/Users/wonhs/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"
"$GODOT" --headless --path . --import
timeout 120 "$GODOT" --headless --path . --fixed-fps 60 res://tests/test_runner.tscn
timeout 60 "$GODOT" --path . --fixed-fps 60 res://tests/screenshot.tscn -- <저장폴더> Easy
```

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

- [ ] 적 HP, 경로 이동, 라이프 감소
- [ ] SHOT, ZONE 공격, 자동 타겟팅
- [ ] 골드, 뽑기 비용
- [ ] WaveManager, 웨이브 진행
- [ ] HUD, Gameover, Clear
- [ ] 테스트, 화면 확인, 커밋
- [ ] 사용자 플레이 확인 (여기서 멈춤)

### M2 이후

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
