# 작업 로그

세션이 끊겨도 이 파일만 보고 이어갈 수 있게 유지한다. 단계가 끝날 때마다 "현재 위치"를 갱신하고 로그를 아래에 추가한다.

## 현재 위치

- **브랜치:** `feature/M0-foundation` (`develop`에서 분기, 미푸시)
- **진행 중:** M0 기반 작업
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
"$GODOT" --headless --path . --fixed-fps 60 res://tests/test_runner.tscn
```

## 체크리스트

### M0 기반

- [ ] Godot 4.7.2 업그레이드, 임포트 확인
- [ ] UnitData, EnemyData, 공용 씬, tres 생성
- [ ] 기존 유닛·적 씬과 중복 스크립트 제거 (UNIT-005 해결)
- [ ] 격자 20×9, 경로 칸 금지, 드롭 하이라이팅 (MAP-005 재구현)
- [ ] 경로 타일 정렬, 경로 표시
- [ ] 테스트 러너, M0 검증, 커밋

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
