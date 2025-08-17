# CLAUDE.md

이 파일은 이 저장소에서 코드로 작업할 때 Claude Code (claude.ai/code)에 대한 지침을 제공합니다.

## 프로젝트 개요

발레 용품 상점 찾기 서비스를 위한 Flutter 애플리케이션입니다. 오프라인/온라인 발레 용품점을 통합 검색하고, 오프라인 매장은 지도 기반으로 찾을 수 있는 모바일 앱입니다.

### 주요 기능
- 오프라인/온라인 발레 용품점 통합 검색
- 오프라인 매장 지도 기반 위치 검색
- 상점별 취급 브랜드 및 판매 정보
- 회원 등급 시스템 (일반/상점/관리자)

## 개발 명령어

### Flutter 기본 명령어
```bash
# 의존성 설치
flutter pub get

# 앱 실행 (디버그 모드)
flutter run

# 특정 디바이스에서 실행
flutter run -d [device_id]

# 릴리즈 모드로 실행
flutter run --release

# 코드 분석 (린트)
flutter analyze

# 테스트 실행
flutter test

# 특정 테스트 파일 실행
flutter test test/[test_file_name].dart

# 빌드 (Android APK)
flutter build apk

# 빌드 (iOS)
flutter build ios

# 빌드 (Web)
flutter build web

# Flutter 디바이스 목록 확인
flutter devices

# Flutter doctor (환경 체크)
flutter doctor
```

## 프로젝트 구조

### 핵심 디렉토리
- `lib/`: 메인 소스 코드
  - `main.dart`: 앱 진입점
- `test/`: 유닛 테스트 및 위젯 테스트
- `android/`: Android 플랫폼 특화 코드
- `ios/`: iOS 플랫폼 특화 코드
- `doc/`: 프로젝트 문서 (PRD 포함)

### 기술 스택 (계획)
- **Frontend**: Flutter 3.8.1+
- **Backend**: Supabase (인증, DB, 스토리지)
- **Map API**: 네이버 지도 API
- **State Management**: Riverpod 또는 Provider
- **Analytics**: Firebase Analytics
- **Crash Reporting**: Firebase Crashlytics

## 데이터 모델 설계

주요 엔티티:
- **profiles**: 사용자 프로필 (일반/상점/관리자)
- **shops**: 상점 정보 (오프라인/온라인/복합)
- **brands**: 브랜드 정보
- **reviews**: 리뷰 시스템
- **favorites**: 즐겨찾기
- **promotions**: 이벤트/프로모션

상점 유형별 특화 정보:
- **오프라인**: 위치(위도/경도), 영업시간, 주차/시착 가능 여부
- **온라인**: 웹사이트 URL, 배송 정책, CS 정보

## 개발 시 주의사항

1. **상점 유형 구분**: 오프라인/온라인/복합 상점 유형에 따라 UI와 기능이 달라집니다
2. **지도 기능**: 오프라인 상점만 지도에 표시되며, 온라인 상점은 목록 뷰에서만 표시
3. **권한 관리**: 일반 회원, 상점 회원, 관리자 권한을 명확히 구분
4. **린트 규칙**: `analysis_options.yaml`의 flutter_lints 규칙 준수

## 향후 구현 예정 기능

1차 개발 범위:
- 회원 인증 시스템
- 지도 기반 오프라인 매장 검색
- 온라인 쇼핑몰 목록 및 검색
- 상점 정보 CRUD
- 리뷰 시스템
- 관리자 대시보드

2차 개발 계획:
- 상품 직접 판매 및 결제
- 온라인 상점 가격 비교
- 발레 학원 정보 추가
- 커뮤니티 기능