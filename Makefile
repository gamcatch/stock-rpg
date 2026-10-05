# ==============================================================================
# Stock RPG : 개미 군단의 투자 여정 (Android Build & Deploy Makefile)
# ==============================================================================

GODOT          ?= /opt/homebrew/bin/godot
ADB            ?= adb
BUILD_DIR      := build/android
APK_NAME       := stock_rpg.apk
APK_PATH       := $(BUILD_DIR)/$(APK_NAME)
PACKAGE_NAME   := com.ddan.stockrpg
ACTIVITY_NAME  := com.godot.game.GodotAppLauncher

.PHONY: all build install run launch deploy logcat uninstall clean devices help

all: build

## 🔨 build: Godot 헤드리스 모드로 Android Debug APK 빌드
build:
	@echo "🚀 [1/2] Android APK 빌드 시작..."
	@mkdir -p $(BUILD_DIR)
	@$(GODOT) --headless --export-debug "Android" $(APK_PATH)
	@echo "✅ [2/2] 빌드 완료: $(APK_PATH)"
	@ls -lh $(APK_PATH)

## 📲 install: 연결된 Android 디바이스(adb)에 APK 설치
install:
	@echo "📲 안드로이드 기기에 APK 설치 중..."
	@if [ ! -f $(APK_PATH) ]; then \
		echo "❌ APK 파일이 없습니다. 먼저 'make build'를 실행합니다."; \
		$(MAKE) build; \
	fi
	@$(ADB) install -r $(APK_PATH)
	@echo "✅ 설치 성공!"

## 🚀 run / launch: 설치된 게임을 폰에서 즉시 실행
run: launch
launch:
	@echo "🎮 스마트폰에서 게임 실행 중 ($(PACKAGE_NAME))..."
	@$(ADB) shell am start -n $(PACKAGE_NAME)/$(ACTIVITY_NAME)
	@echo "✅ 게임이 실행되었습니다!"

## ⚡ deploy: 빌드 -> 설치 -> 실행을 한 번에 원클릭 수행
deploy: build install launch
	@echo "🎉 원클릭 배포 및 실행 완료!"

## 📜 logcat: 게임의 실시간 Godot 엔진 로그 모니터링
logcat:
	@echo "🔍 실시간 Godot 게임 로그 출력 중 (종료: Ctrl+C)..."
	@$(ADB) logcat -c
	@$(ADB) logcat -s "godot:*" "GodotApp:*"

## 🗑️ uninstall: 기기에서 게임 앱 삭제
uninstall:
	@echo "🗑️ 앱 삭제 중 ($(PACKAGE_NAME))..."
	@$(ADB) uninstall $(PACKAGE_NAME)
	@echo "✅ 삭제 완료!"

## 📱 devices: 연결된 adb 기기 목록 확인
devices:
	@$(ADB) devices -l

## 🧹 clean: 빌드된 APK 및 임시 파일 삭제
clean:
	@echo "🧹 빌드 폴더 정리 중..."
	@rm -rf $(BUILD_DIR)
	@echo "✅ 정리 완료!"

## ❓ help: 사용 가능한 Makefile 명령어 안내
help:
	@echo "=============================================================="
	@echo "🐜 Bull Run Survivors - Android 빌드/배포 명령어 목록"
	@echo "=============================================================="
	@echo "  make build      : Android Debug APK 빌드 ($(APK_PATH))"
	@echo "  make install    : 연결된 폰에 APK 설치 (adb install -r)"
	@echo "  make run        : 폰에서 게임 즉시 실행 (launch)"
	@echo "  make deploy     : 빌드 + 설치 + 실행을 한 번에 원클릭 실행 🚀"
	@echo "  make logcat     : 실시간 Godot 인게임 로그 모니터링"
	@echo "  make devices    : 연결된 adb 기기 상태 확인"
	@echo "  make uninstall  : 폰에서 앱 삭제"
	@echo "  make clean      : 빌드 폴더($(BUILD_DIR)) 정리"
	@echo "=============================================================="
