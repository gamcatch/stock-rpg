# 📚 Stock RPG (개미의 투자 여정) - 개발 문서 아카이브 (Documentation)

본 디렉토리(`doc/`)는 **Stock RPG : 개미의 투자 여정 (실시간 주식 정보 방치형 모바일 RPG)**의 기획, 시스템 설계, 증시 데이터 연동 명세 및 기술 아키텍처를 총망라한 기술 문서 저장소입니다.

기존의 뱀파이어 서바이벌형 아레나 액션에서 **"단일 개미 플레이어의 방치형 실시간 주식 정보 시각화 RPG"**로의 장르 피벗 개발 계획 및 전체 사양을 담고 있습니다.

---

## 📑 문서 목차 (Document Index)

| 문서명 | 파일 경로 | 설명 |
| :--- | :--- | :--- |
| **제품 요구사항 정의서 (PRD)** | [PRD.md](file:///Users/sunglee/workspace/stock-rpg/doc/PRD.md) | 방치형 주식 정보 시각화 RPG 피벗 배경, 단일 개미 캐릭터, 세로형 UI/UX 및 단계별 개발 로드맵 |
| **게임 상세 기획서 (GDD)** | [GAME_DESIGN.md](file:///Users/sunglee/workspace/stock-rpg/doc/GAME_DESIGN.md) | 단일 개미 자동 전투 시스템, 실제 종목 캔들 사냥, 실시간 주식 속보 돌발 이벤트 및 배당금 방치 보상 |
| **8대 섹터 & 던전 가이드** | [SECTOR_GUIDE.md](file:///Users/sunglee/workspace/stock-rpg/doc/SECTOR_GUIDE.md) | 한·미 8대 섹터 테마 챕터/던전, 종목 드랍 테이블 및 실시간 증시 수급 버프 |
| **시스템 아키텍처 명세서** | [ARCHITECTURE.md](file:///Users/sunglee/workspace/stock-rpg/doc/ARCHITECTURE.md) | Godot 4.x 기반 자동 전투 엔진, 오프라인 방치 연산, 단일 플레이어 & 세로형 UI 파이프라인 |

---

## 🎮 핵심 컨셉 요약 (Pivot Summary)

- **장르**: 실시간 주식 정보 시각화 방치형 RPG (Idle Stock Market Visualizer RPG)
- **플랫폼 & 화면**: Android 모바일 세로 모드 (FHD+ 1080×2400)
- **패키지 식별자**: `com.ddan.stockrpg`
- **주요 특징**:
  1. **단일 플레이어 유형 (개미 투자자)**: 복잡한 5인 다중 캐릭터/가챠 배제 ➔ 단 1명의 주인공 개미를 집중 육성 및 100% 자율 사냥
  2. **살아있는 주식 정보 시각화**: 오늘 오른 종목(▲)은 붉은 상승 캔들로, 내린 종목(▼)은 푸른 음봉 캔들로 전장에 실시간 투영
  3. **실시간 주식 속보 돌발 이벤트**: 상단 MTS 뉴스 타전 시 개미 주변에 3~5분 한정 돌발 이벤트 포털/보물상자 즉시 생성
  4. **방치 & 배당금 시스템**: 사냥 골드로 우량주(삼성전자, 하이닉스, 엔비디아 등)를 매수하면 위성 오브로 공전하며 시간당 배당금 자동 누적
  5. **MTS 세로 UI & 절전 모드**: 상단 방치 사냥 뷰 + 하단 개미 스펙업 및 종목 매수 탭, 배터리 절전 다크 스크린 지원

---

## 🚀 빠른 시작 (Quick Start)

```bash
# 1. Godot 프로젝트 헤드리스 검증
godot --headless --quit-after 50

# 2. 안드로이드 APK 빌드
make build

# 3. 연결된 디바이스에 설치 및 실행
make install
```
