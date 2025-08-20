# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2025-01-20

### Added
- **상점관리자 Phase 1-1 완료**
  - 상점 편집 화면 탭 구조로 전면 개편
    - 기본 정보, 오프라인, 온라인, 브랜드/카테고리, 이미지 탭으로 구분
    - 각 탭별 전문화된 입력 폼 제공
  - 데이터 모델 대폭 확장
    - Shop 모델에 30개 이상의 새로운 필드 추가
    - ShopBrand, ShopCategory, ShippingRegion 모델 신규 생성
  - 오프라인 상점 세부 기능
    - 상세 위치 설명 (층수, 구역 등)
    - 점심시간 설정 기능
    - 편의시설 체크박스 (휠체어 접근성, 아동 동반 등)
    - 대중교통/도보 경로 안내
  - 온라인 상점 세부 기능
    - 지역별 차등 배송비 설정
    - 결제 수단 멀티 선택
    - CS 채널별 정보 입력 (전화, 카카오톡, 이메일)
    - 교환/환불 정책 상세 설정
  - 복합 상점 특화 기능
    - 매장 픽업 서비스 설정
    - 온라인 주문 → 오프라인 수령 옵션
  - 브랜드/카테고리 관리
    - 취급 브랜드 검색 및 추가
    - 주력 브랜드 설정
    - 전문 카테고리 표시
  - 이미지 갤러리 시스템
    - 다중 이미지 업로드
    - 이미지 순서 변경
    - 썸네일 자동 생성

### Improved
- **메인 화면 및 상세 화면 개선**
  - ShopCard 위젯 정보 표시 강화
    - 상점 유형별 뱃지 표시
    - 주요 브랜드 표시
    - 실시간 영업 상태 표시
  - ShopDetailScreen 대폭 개선
    - 정보 탭 신규 추가
    - 이미지 갤러리 뷰어 구현
    - 상점 유형별 맞춤 정보 표시
- **성능 최적화**
  - 이미지 로딩 최적화 (lazy loading, 캐싱)
  - 데이터 페칭 개선 (batch loading)
  - UI 렌더링 최적화
- **코드 구조 개선**
  - 서비스 레이어 확장 및 모듈화
  - 재사용 가능한 위젯 컴포넌트 생성
  - 에러 핸들링 강화

### Fixed
- Supabase 데이터 저장 시 발생하던 타입 불일치 오류 수정
- 영업시간 표시 로직 버그 수정
- 이미지 업로드 크기 제한 적용 (5MB)
- 폼 유효성 검증 누락 부분 보완

### Technical Details
- **New Database Tables**
  - `shop_brands`: 상점별 브랜드 관리
  - `shop_categories`: 상점별 카테고리 관리
  - `shipping_regions`: 지역별 배송비 설정
- **Extended shops Table**
  - 30+ 새로운 컬럼 추가
  - 오프라인/온라인/복합 상점별 전용 필드
- **New Services**
  - CategoryService: 카테고리 CRUD
  - ShippingService: 배송 정책 관리
  - ImageService: 이미지 업로드/관리

## [1.0.0] - 2024-12-25

### Added
- **앱 브랜딩 변경**
  - 앱 이름을 "발레플러스 (Ballet+)"로 변경
  - 새로운 앱 아이콘 적용 (`ballet_plus_app_icon.png`)
  - Android 패키지명 변경: `com.accu86.flutter_store_pick` → `com.accu.balletPlus`
  - iOS 번들 ID 변경: `com.accu86.flutterStorePick` → `com.accu.balletPlus`
  - 스플래시 화면 앱 이름 업데이트

- **Firebase 통합**
  - Firebase Core, Remote Config, Analytics 패키지 추가
  - Firebase 프로젝트 연동 (`balletplus-519b5`)
  - Android/iOS용 Firebase 설정 파일 자동 생성
  - `firebase_options.dart` 파일 생성

- **버전 관리 시스템**
  - `VersionService` 클래스 구현
    - 앱 버전 체크 로직
    - Remote Config를 통한 버전 정보 관리
    - 강제/선택적 업데이트 구분 로직
    - 서버 점검 모드 지원
  - 버전 업데이트 다이얼로그 UI 구현
    - 강제 업데이트 다이얼로그 (닫기 불가)
    - 선택적 업데이트 다이얼로그 (나중에 업데이트 가능)
    - 서버 점검 안내 다이얼로그
  - 스플래시 화면에 버전 체크 통합

- **Remote Config 매개변수**
  - `minimum_version`: 최소 필수 버전
  - `latest_version`: 최신 버전
  - `maintenance_mode`: 서버 점검 모드
  - `maintenance_message`: 서버 점검 메시지
  - `update_message`: 업데이트 안내 메시지
  - `update_url_android`: Android 스토어 URL
  - `update_url_ios`: iOS 스토어 URL

- **개발 도구**
  - FlutterFire CLI 설정
  - Remote Config 템플릿 파일 (`remoteconfig.template.json`)
  - Firebase 설정 가이드 문서 (`FIREBASE_SETUP.md`)

### Changed
- 스플래시 화면 로직 개선
  - Firebase 초기화 후 버전 체크 수행
  - 버전 체크 중 로딩 표시기 추가
  - 조건에 따른 다이얼로그 표시 및 화면 전환

### Fixed
- 버전 체크 로직 버그 수정
  - `force_update` 플래그와 무관하게 minimum_version 기준으로만 강제 업데이트 판단
  - 최소 버전 충족 시 선택적 업데이트로 처리

### Technical Details
- **Dependencies Added**
  - `firebase_core: ^3.8.0`
  - `firebase_remote_config: ^5.2.0`
  - `firebase_analytics: ^11.3.6`
  - `package_info_plus: ^8.1.3`
  - `url_launcher: ^6.3.1`
  - `flutter_launcher_icons: ^0.13.1` (dev)

- **Project Structure**
  - `lib/services/version_service.dart`: 버전 관리 서비스
  - `lib/widgets/update_dialog.dart`: 업데이트 다이얼로그 UI
  - `lib/firebase_options.dart`: Firebase 설정 옵션

### Configuration
- Android `minSdkVersion`: 23 (Firebase 요구사항)
- iOS 최소 버전: 12.0 (Firebase 요구사항)

## [0.9.0] - 2024-12-20 (Pre-release)

### Initial Features
- 발레 용품점 통합 검색 시스템
- 오프라인/온라인 매장 구분
- 네이버 지도 API 연동
- Supabase 백엔드 통합
- 회원 등급 시스템 (일반/상점/관리자)
- 리뷰 시스템
- 즐겨찾기 기능
- 상점 관리자 기능