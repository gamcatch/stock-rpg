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
│   ├── main.tscn                    # 🌐 대형 오픈월드 증시 맵 (중앙 증시 대교차로 + 8방위 고속도로 + 8대 섹터 성역)
│   ├── main.gd                      # 고속도로 렌더링, 섹터 바이옴, 종목별 성역/제단 및 몬스터 스폰 루프
│   ├── player.tscn                  # 🐜 단일 주인공 개미 투자자 (Ant Investor)
│   ├── player.gd                    # 방치형 자율 사냥 AI, 고속도로 순회, 속보 제단 출동, 터치 조작 오버라이드
│   ├── enemy.tscn                   # 📉 캔들스틱 몬스터 (패닉셀, 가짜뉴스, 거대 음봉, 공매도 베어보스, 트럼프 보스)
│   ├── exp_gem.tscn                 # 💎 배당금 젬 인스턴스 (수익률 누적 및 레벨업 EXP)
│   ├── projectile.tscn              # 🟢 양봉 빔, 손절 라이트닝, 유동성 투사체
│   └── ui/                          # 📱 세로 화면 HUD 및 편의 시스템
│       ├── hud.tscn                 # 실시간 뉴스 티커, 섹터 현황 전광판, 레이더 미니맵, [AUTO], [1X/2X], [국장/미장]
│       ├── hud.gd                   # HUD 애니메이션, 실시간 속보 수신, 방치형 AUTO 및 배속 제어
│       ├── radar_minimap.gd         # 360도 8방위 고속도로 및 섹터 허브 레이더 네비게이션
│       ├── waypoint_overlay.gd      # 화면 외곽 섹터 및 중앙 광장 하이테크 웨이포인트 화살표
│       ├── level_up_menu.tscn       # 📈 투자 전략 매수 카드 선택창 (방치형 3.5초 자동선택 타이머 탑재)
│       ├── virtual_joystick.tscn    # 모바일 터치 가상 조이스틱
│       └── game_over_menu.tscn      # 정산 및 KOSPI 재도전 메뉴
├── scripts/
│   ├── global.gd                    # 전역 상태, 방치형 AUTO 플래그, 게임 배속, 계좌 총자산, 스킬 트리
│   ├── market_data_manager.gd       # 8대 섹터 및 80+ 종목 실시간 시세 연동, 속보 타전, 성역 좌표 매핑
│   ├── market_data_fetcher.gd       # 실시간 국내/해외 주식 시세 및 속보 HTTP 수신
│   ├── sound_manager.gd             # 절차적 오디오 신시사이저 (MTS 체결음, 레벨업음, 경보음)
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

### 2.2 `PortfolioManager` (`scripts/portfolio_manager.gd`)
- **역할**: 단일 개미 플레이어가 보유한 실제 종목 지분 및 위성 오브 관리.
- **기능**:
  - 시드머니로 종목 주식 매수 (예: 삼성전자 10주, SK하이닉스 5주).
  - 보유 종목 수에 따라 개미 주변을 공전하는 `StockOrbiter` 인스턴스 생성.
  - 보유 종목의 실제 배당수익률 합산 ➔ 분당 방치 배당금 계산.

### 2.3 `IdleManager` (`scripts/idle_manager.gd`)
- **역할**: 오프라인 경과 시간(최대 24시간) 동안의 배당금 계산 및 접속 시 원클릭 정산.

### 2.4 `MarketDataManager` (`scripts/market_data_manager.gd`)
- **역할**: 한국/미국 실제 증시 데이터 파싱 및 실시간 주식 속보 타전.
- **시그널**: `signal breaking_news_alert(headline, stock_name, sector_key, effect_type, duration)`
  - 속보 수신 시 전투 필드 내 개미 플레이어 근처에 `NewsEventPortal` 즉각 스폰.

---

## 3. 자동 전투 및 렌더링 파이프라인

- **상단 45% 영역**: `BattleField` 노드에서 개미 플레이어가 전방으로 자율 전진하며, 화면 우측/전방에서 몰려오는 실제 종목 캔들 몬스터들을 자동 격파.
- **중단 10% 영역**: 실시간 시황 전광판 티커 및 누적 배당금 수령 버튼.
- **하단 45% 영역**: 탭 기반의 개미 스펙업 및 주식 매수 대시보드.
