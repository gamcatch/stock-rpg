# 🏗️ Stock RPG : 시스템 아키텍처 및 기술 명세서 (Architecture & Tech Spec)

> **엔진**: Godot Engine 4.x (Vulkan Forward Mobile Renderer)  
> **언어**: GDScript 2.0  
> **장르**: 실시간 주식 정보 시각화 방치형 RPG (Idle Stock Market Visualizer RPG)  
> **타겟 플랫폼**: Android (arm64-v8a) 세로 모드 (Portrait, FHD+ 1080×2400)  
> **패키지 식별자**: `com.ddan.stockrpg`  
> **최종 갱신일**: 2026-10-05  

---

## 1. 프로젝트 구조 (Project Tree)

```
stock-rpg/
├── assets/                          # 스프라이트, UI 테마 폰트, SFX 신시사이저
│   ├── branding/                    # 런처 아이콘(icon.png, 192, 432) 및 스플래시(splash.png)
│   ├── fonts/                       # 모바일 가독 폰트
│   └── icons/                       # 차트 캔들스틱, 섹터 아이콘, 배당금 코인
├── doc/                             # 기획 및 기술 명세 아카이브 (PRD, GDD, Architecture 등)
├── scenes/
│   ├── main.tscn                    # 🌐 대형 오픈월드 증시 맵 (중앙 증시 대교차로 + 8방위 고속도로 + 8대 섹터 성역 192종목)
│   ├── main.gd                      # 고속도로 렌더링, 192종목 성역 배치, VI 배리어 렌더링, 트럼프 계단식 보스전 루프
│   ├── player.tscn                  # 🐜 단일 주인공 개미 투자자 (Ant Investor)
│   ├── player.gd                    # 방치형 자율 사냥 AI, 고속도로 크루즈, VI 즉시 이탈(10분 쿨타임), 독백 말풍선
│   ├── enemy.tscn                   # 📉 캔들스틱 몬스터 (패닉셀, 가짜뉴스, 거대 음봉, 공매도 베어보스, 트럼프 보스)
│   ├── exp_gem.tscn                 # 💎 배당금 젬 인스턴스 (수익률 누적 및 레벨업 EXP)
│   ├── projectile.tscn              # 🟢 양봉 빔, 손절 라이트닝, 유동성 투사체
│   └── ui/                          # 📱 세로 화면 HUD 및 편의 시스템
│       ├── hud.tscn                 # 실시간 뉴스 티커, 섹터 현황 전광판, 레이더 미니맵, [국장/미장], [AUTO], [소리], [1X/2X/3X]
│       ├── hud.gd                   # HUD 애니메이션, 실시간 속보 수신, 방치형 AUTO, 배속 및 사운드 토글 제어
│       ├── radar_minimap.gd         # 360도 8방위 고속도로 및 섹터 허브 레이더 네비게이션
│       ├── waypoint_overlay.gd      # 화면 외곽 섹터 및 중앙 광장 하이테크 웨이포인트 화살표
│       ├── level_up_menu.tscn       # 📈 투자 전략 매수 카드 선택창 (방치형 3.5초 자동선택 타이머 탑재)
│       ├── virtual_joystick.tscn    # 모바일 터치 가상 조이스틱
│       └── game_over_menu.tscn      # 정산 및 KOSPI 재도전 메뉴
├── scripts/
│   ├── global.gd                    # 전역 상태, 방치형 AUTO 플래그, 게임 배속, 계좌 총자산, 스킬 트리
│   ├── market_data_manager.gd       # 8대 섹터 192개 종목 실시간 시세 연동, VI 발동/냉각 제어, 성역 좌표 매핑
│   ├── market_data_fetcher.gd       # 실시간 국내/해외 주식 시세 및 속보 HTTP 수신
│   ├── sound_manager.gd             # 절차적 오디오 신시사이저 & 오디오/햅틱 스로틀링, 마스터 음소거 제어
│   └── portfolio_manager.gd         # 단일 개미의 종목 매수/보유 지분 및 배당금 관리
├── export_presets.cfg               # 안드로이드 익스포트 프리셋 (com.ddan.stockrpg)
├── Makefile                         # 빌드/설치 파이프라인 (stock_rpg.apk)
└── project.godot                    # 뷰포트 1080×2400 (세로 모드), main_scene="res://scenes/main.tscn"
```

---

## 2. 주요 싱글톤 아키텍처 (Autoload Singletons)

### 2.1 `Global` (`scripts/global.gd`)
- **역할**: 게임 세션 상태, 계좌 자산, 현재 KOSPI 등반 스테이지 관리.
- **핵심 변수**:
  - `account_balance: int`: 현재 보유 시드머니 (골드).
  - `current_index_level: int`: 현재 도달 지수 (예: KOSPI 2,750p).
  - `battle_speed: float`: 1.0x / 2.0x / 3.0x 배속 제어.
  - `is_power_saving_mode: bool`: 배터리 절전 다크 스크린 토글.

### 2.2 `MarketDataManager` (`scripts/market_data_manager.gd`)
- **역할**: 한국 96종목 + 미국 96종목(총 192종목) 실제 증시 데이터 파싱, 성역 좌표 생성, VI(변동성 완화장치) 관리.
- **핵심 메커니즘**:
  - `trigger_stock_vi(stock)`: 종목 과열 시 20초간 거래 일시 정지(단일가 냉각).
  - `signal stock_vi_triggered(stock_name, duration)`: VI 발동 시그널 브로드캐스트.
  - `signal breaking_news_alert(...)`: 속보 수신 시 전투 필드 이벤트 스폰.

### 2.3 `SoundManager` (`scripts/sound_manager.gd`)
- **역할**: 절차적 사운드 신시사이저 및 안드로이드 햅틱 진동 제어.
- **최적화 & 기능**:
  - **오디오 풀링**: 8채널 고정 플레이어 풀로 런타임 인스턴싱/GC 렉 완전 제거.
  - **스로틀링 (Throttling)**: 대량 몹 동시 타격/처치 시 오디오 클리핑 및 진동 과부하 방지.
  - **사운드 제어**: `sound_enabled` 플래그 및 마스터 오디오 버스 음소거 연동, 부드러운 -6dB 마스터 볼륨.

### 2.4 `PortfolioManager` (`scripts/portfolio_manager.gd`)
- **역할**: 단일 개미 플레이어가 보유한 실제 종목 지분 및 위성 오브 관리.
- **기능**:
  - 시드머니로 종목 주식 매수 (예: 삼성전자 10주, SK하이닉스 5주).
  - 보유 종목 수에 따라 개미 주변을 공전하는 `StockOrbiter` 인스턴스 생성.
  - 보유 종목의 실제 배당수익률 합산 ➔ 분당 방치 배당금 계산.

### 2.5 `IdleManager` (`scripts/idle_manager.gd`)
- **역할**: 오프라인 경과 시간(최대 24시간) 동안의 배당금 계산 및 접속 시 원클릭 정산.

---

## 3. 오픈월드 증시 맵 & 자동 순회 AI 파이프라인

- **초대형 오픈월드 규격**:
  - 중앙 증시 광장 반경 550px, 8방위 고속도로(Neon Highway) 길이 8,000px.
  - 섹터 허브 반경 1,800px, 12개 종목 성역 간격 995px로 192종목의 쾌적한 분산 배치.
- **오토플레이(AutoPlay AI) 및 쿨타임 시스템**:
  - 상승률 가중치(+300점/1%), 양수 상승 보너스(+3000점), 급등주 보너스(+1500점), 미방문 섹터 순회 보너스(+2500점)로 최적 타겟 자동 탐색.
  - **VI 발동 종목**: 즉시 이탈 및 **10분(600초)** 쿨타임 등록.
  - **파밍 완료 종목**: **5분(300초)** 쿨타임 등록.
  - **방문 섹터**: **90초** 쿨타임 등록으로 타 섹터 적극 순회 유도.
- **계단식 보스전 밸런스**:
  - 무한 시간 비례 난이도 증가 방지. **관세맨 트럼프 보스 격파 시점에만 적 능력치가 계단식으로 한 단계 상승**하여 안정적 파밍 환경 제공.
