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
│   ├── battle/                      # ⚔️ 방치형 자동 전투 필드 및 단일 플레이어
│   │   ├── battle_field.tscn        # 상단 자동 전투 메인 필드 (배경, 웨이브 제어)
│   │   ├── battle_field.gd          # 캔들 몬스터 스폰, 웨이브 루프, 보스전 진입 관리
│   │   ├── player_ant.tscn          # 단일 주인공 개미 플레이어 인스턴스
│   │   ├── player_ant.gd            # 개미 100% 자율 전진, 자동 사격, 위성 오브 공전
│   │   ├── stock_candle_enemy.tscn  # 실제 종목 데이터 기반 상승(🔴)/하락(🔵) 캔들 몬스터
│   │   ├── stock_candle_enemy.gd    # 등락률 기반 오라, 피격 및 배당 젬 드랍
│   │   ├── stock_orbiter.tscn       # 보유 종목 위성 오브 (개미 주변 공전 자동사격)
│   │   ├── news_event_portal.tscn   # 속보 발령 시 개미 근처에 스폰되는 긴급 포털
│   │   └── damage_number.tscn       # MTS 스타일 플로팅 데미지/회복 텍스트
│   ├── ui/                          # 📱 세로 화면 UI 및 탭 시스템
│   │   ├── main_screen.tscn         # 세로 분할 메인 컨테이너 (상단 뷰포트 + 하단 탭)
│   │   ├── main_screen.gd           # Safe Area 보정, 탭 전환, 실시간 티커 전광판 제어
│   │   ├── tab_stats.tscn           # 개미 기본 스탯 강화 탭 (공격력/체력/치명타)
│   │   ├── tab_portfolio.tscn       # 실제 종목 매수/보유 현황 및 배당금 탭
│   │   ├── tab_market.tscn          # 8대 섹터 증시 현황 및 던전 선택 탭
│   │   ├── idle_reward_popup.tscn   # 오프라인 방치 배당금 수령 모달 팝업
│   │   └── share_receipt.tscn       # MTS 수익률 인증 영수증 캡처 & 공유 모달
├── scripts/
│   ├── autoload/                    # 🌐 전역 싱글톤 매니저
│   │   ├── global.gd                # 전역 상태, 계좌 총자산, 스테이지 진행도, 컬러 테마
│   │   ├── portfolio_manager.gd     # 단일 개미의 종목 매수/보유 지분 및 위성 오브 관리
│   │   ├── idle_manager.gd          # 오프라인 경과 시간 계산 및 분당 배당금 정산
│   │   ├── market_data_manager.gd   # 실시간 한·미 증시 데이터 통신 & 주식 속보 타전
│   │   ├── sound_manager.gd         # 절차적 오디오 신시사이저 (MTS 체결음, 레벨업음)
│   │   └── save_system.gd           # 로컬 JSON 암호화 세이브 & 무결성 검증
├── export_presets.cfg               # 안드로이드 익스포트 프리셋 (com.ddan.stockrpg)
├── Makefile                         # 빌드/설치 파이프라인 (stock_rpg.apk)
└── project.godot                    # 뷰포트 1080×2400 (세로 모드), 오토로드 등록
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
