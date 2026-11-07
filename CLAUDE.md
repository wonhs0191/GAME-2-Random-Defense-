# Planet Random Defense

Godot 4.7.2, GDScript. 픽셀 랜덤 디펜스. 사용자는 전체 게임 완성을 맡긴 상태다.

**세션 시작 시 [docs/WORKLOG.md](docs/WORKLOG.md)의 "현재 위치"부터 읽고 이어서 진행한다.** 방향은 [docs/PLAN.md](docs/PLAN.md).

## 작업 규칙

- 단계가 끝날 때마다 WORKLOG의 "현재 위치", 체크리스트, 로그를 갱신한다.
- 마일스톤별 `feature/*` 브랜치에 로컬 커밋까지만 한다. 푸시와 `develop` 병합은 사용자 확인 후.
- Notion 태스크는 허락 없이 수정하지 않는다.
- 외부 에셋 다운로드는 건별로 확인받는다.
- 커밋 메시지는 사용자 관례(`^_^ ` 접두, 한국어)를 따른다.
- `scenes/title/title_screen.tscn`의 UID 한 줄 변경은 작업 전부터 있던 것이다. 함께 커밋하지 않는다.

## 구조 원칙

- 드래그와 입력은 `GridManager`만 담당한다.
- 유닛·적 추가는 `data/` 아래 tres 추가로 끝나야 한다.
- 맵 씬은 경로만 가진다.
