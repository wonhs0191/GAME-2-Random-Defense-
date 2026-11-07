# 에셋 라이선스 점검

2026-11-07 기준. 각 제작자 페이지를 직접 읽어 확인했다. 법률 자문이 아니며, Steam 출시 전 표시된 항목은 사용자가 확인해야 한다.

## 출시 전 확인 필요

1. **C등급 공격 이펙트의 출처.** `entities/units/PRD-C-*/` 프레임이 어느 팩에서 왔는지 저장소에 기록이 없다. Notion 후보는 codemanu, xyezawr, ansimuz이고 이 중 codemanu 페이지는 본문("public domain", 표기 불필요)과 사이드바(CC BY 4.0)가 서로 다르다. xyezawr, ansimuz는 제작자 목록 페이지에 약관이 없어 제품 페이지를 봐야 한다. 출처를 찾아 약관을 확인하고, 불분명하면 `tools/generate_effects.gd`로 교체한다. B등급 일부도 이 이펙트를 재활용한다.
2. **deep-fold 배경 이미지.** 생성기 페이지가 게임 사용은 허용하지만 이미지를 단독으로 또는 에셋 팩으로 배포하는 것은 금지한다. 게임에 포함해 배포하는 것은 괜찮으나, 저장소를 공개한다면 이미지가 그대로 노출되는 점을 검토한다. 상업 이용 허가는 약관이 아니라 제작자의 댓글 답변으로만 확인된다.
3. **deep-fold 행성 이미지.** 페이지의 MIT 표기는 코드 기준이다. FAQ가 게임 사용을 자유롭게 허용하지만 내보낸 이미지 약관을 따로 쓰지는 않았다.
4. **레퍼런스 이미지.** 증강 패널은 상용 게임 화면을 구조만 참고했다. 화면 자체는 쓰지 않았다.

## 항목별 정리

| 에셋 | 위치 | 약관 | 의무 | 상태 |
|---|---|---|---|---|
| Godot Engine | 실행 파일 | MIT | 저작권·라이선스 고지 | 설정 창에 표기 |
| 외계 함선 (Foozle Void Fleet) | `entities/enemies/`, `scenes/title/enemy/`, `scenes/lobby/ship/` | CC0 | 없음 | 문제없음 |
| DNF BitBit 폰트 | `assets/fonts/` | SIL OFL 1.1, Copyright (c) 2022 NEOPLE Inc. | 라이선스 전문 동봉, 폰트 단독 판매 금지. 출처 표기 권장 | `assets/fonts/OFL.txt` 동봉, 설정 창에 표기 |
| C등급·타이틀 행성 (deep-fold) | `entities/units/PRD-C-*`, `scenes/title/unit/` | 게임 사용 허용, 표기 불필요 | 없음 | 위 3번 참고 |
| 배경 (deep-fold로 추정) | `scenes/lobby/background_img/`, `scenes/title/title_screen_background.png` | 게임 사용 허용 | 단독 배포 금지 | 위 2번 참고. 출처 기록 없음 |
| C등급 공격 이펙트 | `entities/units/PRD-C-*` | 미확인 | 미확인 | **위 1번** |
| B~S 행성, A·S 이펙트 | `entities/units/generated/` | 프로젝트 자체 생성 | 없음 | `tools/`로 재생성 가능 |
| 효과음, BGM | `assets/audio/` | 프로젝트 자체 생성 | 없음 | `tools/generate_audio.py`로 재생성 가능 |

세계관 문구의 일부는 Notion의 GPT 초안을 다듬은 것이다. 상표 충돌 검색은 하지 않았다.
