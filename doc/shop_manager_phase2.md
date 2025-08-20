# 상점관리자 Phase 2 개발 계획

## 📋 개요
상점관리자 기능의 Phase 2 개발로, 프로모션 관리와 상세 분석 기능을 구현합니다.

## 🎯 개발 목표
상점 운영자가 효과적으로 마케팅을 수행하고 상세한 분석을 통해 인사이트를 얻을 수 있도록 지원

## 📅 개발 일정
- **전체 기간**: 2주 (10 영업일)
- **예상 시작일**: Phase 1 완료 후
- **예상 종료일**: 시작일로부터 2주 후

## 🔧 Phase 2 구현 범위

### 1. 프로모션 관리 시스템
#### 1.1 프로모션 생성 및 관리
- ✅ 할인 이벤트 생성
- ✅ 쿠폰 코드 발급 및 관리
- ✅ 시즌별 이벤트 설정
- ✅ 프로모션 기간 설정
- ✅ 대상 상품/브랜드 지정

#### 1.2 프로모션 유형
- **할인 이벤트**: 퍼센트/금액 할인
- **쿠폰 발행**: 고유 코드 생성
- **번들 상품**: 묶음 할인
- **무료 배송**: 조건부 무료배송
- **신상품 출시**: 런칭 이벤트

#### 1.3 프로모션 분석
- 프로모션별 조회수
- 클릭률 (CTR)
- 전환율 추적
- ROI 분석

### 2. 상세 통계 분석
#### 2.1 트래픽 분석
- ✅ 시간대별 방문자 수
- ✅ 요일별 트래픽 패턴
- ✅ 월별 추이 분석
- ✅ 피크 시간대 파악

#### 2.2 유입 경로 분석
- ✅ 검색 키워드 분석
- ✅ 지도/검색/직접 유입 비율
- ✅ 지역별 방문자 분포
- ✅ 리퍼러 분석

#### 2.3 고객 행동 분석
- ✅ 평균 체류 시간
- ✅ 재방문율
- ✅ 이탈률
- ✅ 전환 깔때기

### 3. 이미지 갤러리 관리
#### 3.1 이미지 업로드
- ✅ 다중 이미지 업로드
- ✅ 이미지 압축 및 최적화
- ✅ 썸네일 자동 생성
- ✅ 드래그 앤 드롭 지원

#### 3.2 갤러리 관리
- ✅ 이미지 순서 변경
- ✅ 대표 이미지 설정
- ✅ 카테고리별 분류
- ✅ 이미지 설명 추가

### 4. 공지사항 고도화
#### 4.1 리치 텍스트 에디터
- ✅ 텍스트 서식 지원 (굵게, 기울임, 밑줄)
- ✅ 링크 삽입
- ✅ 이미지 삽입
- ✅ 목록 생성

#### 4.2 공지사항 템플릿
- ✅ 자주 사용하는 템플릿 저장
- ✅ 카테고리별 템플릿
- ✅ 변수 치환 기능

## 💾 데이터베이스 스키마 확장

### 1. promotions 테이블 (확장)
```sql
CREATE TABLE promotions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  promotion_type VARCHAR(50) NOT NULL, -- discount, coupon, bundle, free_shipping, new_product
  discount_type VARCHAR(20), -- percentage, fixed_amount
  discount_value DECIMAL(10, 2),
  coupon_code VARCHAR(50),
  min_purchase_amount DECIMAL(10, 2),
  max_discount_amount DECIMAL(10, 2),
  usage_limit INTEGER,
  used_count INTEGER DEFAULT 0,
  target_type VARCHAR(50), -- all, specific_brands, specific_categories
  target_ids UUID[], -- brand_ids or category_ids
  banner_image_url TEXT,
  start_date TIMESTAMP WITH TIME ZONE,
  end_date TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 프로모션 사용 내역
CREATE TABLE promotion_usage (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  promotion_id UUID NOT NULL REFERENCES promotions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id),
  used_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  order_amount DECIMAL(10, 2),
  discount_amount DECIMAL(10, 2),
  UNIQUE(promotion_id, user_id) -- 사용자당 1회 제한
);

-- 프로모션 통계
CREATE TABLE promotion_analytics (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  promotion_id UUID NOT NULL REFERENCES promotions(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  view_count INTEGER DEFAULT 0,
  click_count INTEGER DEFAULT 0,
  conversion_count INTEGER DEFAULT 0,
  revenue DECIMAL(10, 2) DEFAULT 0,
  UNIQUE(promotion_id, date)
);
```

### 2. shop_analytics 테이블
```sql
CREATE TABLE shop_analytics (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  hour INTEGER, -- 0-23 for hourly data, NULL for daily summary
  visitor_count INTEGER DEFAULT 0,
  page_views INTEGER DEFAULT 0,
  average_duration INTEGER, -- in seconds
  bounce_rate DECIMAL(5, 2),
  new_visitors INTEGER DEFAULT 0,
  returning_visitors INTEGER DEFAULT 0,
  UNIQUE(shop_id, date, hour)
);

-- 검색 키워드 추적
CREATE TABLE search_keywords (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  keyword VARCHAR(255) NOT NULL,
  search_count INTEGER DEFAULT 1,
  click_count INTEGER DEFAULT 0,
  date DATE NOT NULL,
  UNIQUE(shop_id, keyword, date)
);

-- 유입 경로
CREATE TABLE referral_sources (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  source VARCHAR(50) NOT NULL, -- map, search, direct, social, etc.
  medium VARCHAR(50),
  campaign VARCHAR(100),
  visitor_count INTEGER DEFAULT 0,
  date DATE NOT NULL,
  UNIQUE(shop_id, source, date)
);
```

### 3. shop_images 테이블 (개선)
```sql
CREATE TABLE shop_images (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  thumbnail_url TEXT,
  title VARCHAR(255),
  description TEXT,
  category VARCHAR(50), -- exterior, interior, product, event
  display_order INTEGER DEFAULT 0,
  is_primary BOOLEAN DEFAULT FALSE,
  width INTEGER,
  height INTEGER,
  file_size INTEGER, -- in bytes
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## 📁 파일 구조

### 신규 파일
```
lib/
├── models/
│   ├── promotion.dart
│   ├── promotion_usage.dart
│   ├── shop_analytics.dart
│   └── shop_image.dart
├── services/
│   ├── promotion_service.dart
│   ├── analytics_service.dart
│   └── image_service.dart
├── screens/shop/
│   ├── promotions/
│   │   ├── promotion_list_screen.dart
│   │   ├── promotion_edit_screen.dart
│   │   └── promotion_detail_screen.dart
│   ├── analytics/
│   │   ├── analytics_dashboard_screen.dart
│   │   ├── traffic_analysis_screen.dart
│   │   └── keyword_analysis_screen.dart
│   └── gallery/
│       ├── image_gallery_screen.dart
│       └── image_upload_screen.dart
└── widgets/
    ├── promotion_card.dart
    ├── analytics_chart.dart
    ├── traffic_heatmap.dart
    └── image_picker_widget.dart
```

## 📦 추가 필요 패키지

```yaml
dependencies:
  # 이미지 처리
  image_cropper: ^5.0.0
  image_compression_flutter: ^1.0.3
  photo_view: ^0.14.0
  
  # 리치 텍스트 에디터
  flutter_quill: ^9.0.0
  
  # 차트 확장
  syncfusion_flutter_charts: ^24.0.0
  heatmap_calendar: ^1.0.5
  
  # 쿠폰/QR 코드
  qr_flutter: ^4.1.0
  barcode_widget: ^2.0.4
  
  # 애니메이션
  lottie: ^3.0.0
```

## 🚀 구현 순서

### Week 1: 프로모션 시스템 & 이미지 관리
**Day 1-2: 데이터베이스 & 모델**
- [ ] 프로모션 관련 테이블 생성
- [ ] 모델 클래스 구현
- [ ] 서비스 레이어 구현

**Day 3-4: 프로모션 UI**
- [ ] 프로모션 목록 화면
- [ ] 프로모션 생성/수정 화면
- [ ] 쿠폰 코드 생성기

**Day 5: 이미지 갤러리**
- [ ] 이미지 업로드 기능
- [ ] 갤러리 관리 화면
- [ ] 이미지 최적화

### Week 2: 상세 분석 & 최적화
**Day 6-7: 분석 대시보드**
- [ ] 트래픽 분석 화면
- [ ] 시간대별 히트맵
- [ ] 유입 경로 차트

**Day 8: 키워드 분석**
- [ ] 검색 키워드 추적
- [ ] 인기 검색어 표시
- [ ] 키워드 트렌드

**Day 9: 통합 및 테스트**
- [ ] 기능 통합
- [ ] 성능 최적화
- [ ] 버그 수정

**Day 10: 마무리**
- [ ] UI/UX 개선
- [ ] 문서화
- [ ] 배포 준비

## ✅ 완료 기준

### 기능적 요구사항
- [x] 다양한 유형의 프로모션을 생성/관리할 수 있다
- [x] 프로모션 효과를 분석할 수 있다
- [x] 상세한 트래픽 분석을 확인할 수 있다
- [x] 이미지를 효율적으로 관리할 수 있다
- [x] 검색 키워드를 추적할 수 있다

### 비기능적 요구사항
- [x] 이미지 업로드 < 10MB 제한
- [x] 차트 렌더링 < 1초
- [x] 프로모션 생성 < 3초
- [x] 데이터 캐싱으로 로딩 최적화

## 🧪 테스트 계획

### 단위 테스트
- 프로모션 유효성 검증
- 할인 계산 로직
- 날짜 범위 체크

### 통합 테스트
- 프로모션 생성 → 활성화 → 사용
- 이미지 업로드 → 압축 → 저장
- 분석 데이터 수집 → 집계 → 표시

### 성능 테스트
- 대량 이미지 업로드
- 복잡한 차트 렌더링
- 실시간 통계 업데이트

## 📝 주의사항

1. **프로모션 중복 방지**: 동일 기간 중복 프로모션 체크
2. **이미지 최적화**: 업로드 시 자동 압축 및 리사이징
3. **데이터 정확성**: 분석 데이터 실시간 동기화
4. **쿠폰 보안**: 유니크 코드 생성 및 검증
5. **성능**: 대량 데이터 처리 시 페이지네이션

## 🔄 Phase 3 예고
- 단골 고객 관리 시스템
- 인증 뱃지 자동 부여
- FAQ 자동 생성
- 경쟁사 분석 대시보드

## 📊 예상 성과
- 프로모션 관리 효율성 80% 향상
- 데이터 기반 의사결정 가능
- 마케팅 ROI 측정 가능
- 고객 행동 패턴 파악