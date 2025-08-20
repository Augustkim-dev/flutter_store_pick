# 상점관리자 Phase 1-1 개발 계획 (보완)

## 📋 개요
Phase 1에서 미완성된 기본 기능을 완성하고, 상점 정보가 실제 사용자에게 올바르게 표시되도록 구현

## 🎯 개발 목표
PRD 3.1절의 상점 정보 관리 기능을 완전히 구현하고, 입력된 정보가 메인 화면과 상세 화면에서 제대로 표시되도록 함

## 📅 개발 일정
- **전체 기간**: 1주 (5 영업일)
- **시작일**: 즉시
- **완료일**: 5일 후

## 🔍 현재 상태 분석

### ✅ 완료된 기능
- 리뷰 답글 시스템
- 통계 대시보드 (기본)
- 공지사항 관리
- 영업시간 설정 (별도 화면)

### ⚠️ 부분적으로 구현된 기능
- **상점 정보 수정 화면 (ShopEditScreen)**
  - ✅ 기본 정보 수정 기능 작동
  - ✅ 상점 유형별 기본 설정 가능
  - ⚠️ Supabase 저장 테스트 필요
  - ❌ PRD 추가 요구사항 70% 미구현:
    - 브랜드/카테고리 관리
    - 이미지 갤러리
    - 상세 위치, 점심시간
    - 결제수단, CS정보
    - 복합 상점 특화 기능

### ❌ 미완성 기능 (PRD 기준)
1. **공통 정보 관리**
   - ❌ 취급 브랜드 관리
   - ❌ 상품 카테고리 관리
   - ❌ 상점 이미지 갤러리

2. **오프라인 상점 정보**
   - ❌ 상세 위치 설명
   - ❌ 점심시간 설정
   - ❌ 휠체어 접근성
   - ❌ 아동 동반 가능
   - ❌ 오시는 길 상세 정보

3. **온라인 상점 정보**  
   - ❌ 모바일 웹 지원 여부
   - ❌ 지역별 배송비
   - ❌ 당일배송 가능 여부
   - ❌ 결제 수단 정보
   - ❌ 고객센터 정보
   - ❌ 교환/환불 정책

4. **복합 상점 정보**
   - ❌ 매장 픽업 서비스
   - ❌ 온라인 주문 → 오프라인 수령

5. **표시 기능**
   - ❌ 메인 화면에서 상점 정보 미표시
   - ❌ 상세 화면에서 추가 정보 미표시

## 💾 데이터베이스 스키마 보완

### 1. shops 테이블 확장
```sql
-- 기존 shops 테이블에 컬럼 추가
ALTER TABLE shops ADD COLUMN IF NOT EXISTS 
  -- 공통 정보
  business_number VARCHAR(20),
  image_urls TEXT[], -- 갤러리 이미지들
  
  -- 오프라인 상점 정보
  detailed_location TEXT, -- 상세 위치 (2층, 지하 등)
  lunch_break_start TIME,
  lunch_break_end TIME,
  wheelchair_accessible BOOLEAN DEFAULT FALSE,
  kids_friendly BOOLEAN DEFAULT FALSE,
  directions_public TEXT, -- 대중교통 안내
  directions_walking TEXT, -- 도보 경로
  parking_info TEXT, -- 주차 정보
  
  -- 온라인 상점 정보
  mobile_web_support BOOLEAN DEFAULT TRUE,
  same_day_delivery BOOLEAN DEFAULT FALSE,
  payment_methods TEXT[], -- 결제 수단
  cs_hours TEXT, -- 고객센터 운영시간
  cs_phone VARCHAR(20),
  cs_kakao VARCHAR(100),
  cs_email VARCHAR(100),
  exchange_policy TEXT,
  refund_policy TEXT,
  return_shipping_fee INTEGER,
  
  -- 복합 상점 정보
  pickup_service BOOLEAN DEFAULT FALSE,
  online_to_offline BOOLEAN DEFAULT FALSE;
```

### 2. shop_brands 테이블 (신규)
```sql
CREATE TABLE IF NOT EXISTS shop_brands (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  brand_id UUID NOT NULL REFERENCES brands(id),
  is_main BOOLEAN DEFAULT FALSE,
  stock_status VARCHAR(20) DEFAULT 'in_stock', -- in_stock, low_stock, out_of_stock
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(shop_id, brand_id)
);
```

### 3. shop_categories 테이블 (신규)
```sql
CREATE TABLE IF NOT EXISTS shop_categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  category_name VARCHAR(50) NOT NULL, -- 토슈즈, 레오타드, 타이즈 등
  is_specialized BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(shop_id, category_name)
);
```

### 4. shipping_regions 테이블 (신규)
```sql
CREATE TABLE IF NOT EXISTS shipping_regions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  region_name VARCHAR(50) NOT NULL, -- 서울, 경기, 제주 등
  shipping_fee INTEGER NOT NULL,
  estimated_days INTEGER DEFAULT 2,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(shop_id, region_name)
);
```

## 🚀 구현 계획

### Day 0: 기존 기능 검증 완료 ✅
#### 상점 정보 수정 기능 현황
- [x] ShopEditScreen 접근 및 UI - 정상 작동
- [x] 기본 정보 수정 기능 - 작동 확인
  - ✅ 상점명, 설명, 전화번호 수정 가능
  - ✅ 상점 유형 변경 가능 (오프라인/온라인/복합)
  - ✅ 오프라인: 주소, 영업시간, 주차/시착 설정 가능
  - ✅ 온라인: 웹사이트, 배송비, 무료배송 조건 설정 가능
- [ ] Supabase 저장 연동 테스트 필요
- [x] PRD 대비 구현율: 약 30% (기본 기능만 구현)

### Day 1: 데이터 모델 및 서비스 확장
#### 오전: 모델 클래스 확장
- [ ] Shop 모델에 누락된 필드 추가
- [ ] ShopBrand 모델 생성
- [ ] ShopCategory 모델 생성
- [ ] ShippingRegion 모델 생성

#### 오후: 서비스 레이어 구현
- [ ] ShopService 확장 (새 필드 CRUD)
- [ ] BrandService 확장 (shop_brands 관리)
- [ ] CategoryService 생성
- [ ] ShippingService 생성

### Day 2: 상점 편집 화면 개선
#### 오전: UI 구조 개선
- [ ] ShopEditScreen을 탭 구조로 변경
  - 기본 정보 탭
  - 상점 유형별 정보 탭
  - 브랜드/카테고리 탭
  - 이미지 관리 탭

#### 오후: 기본 정보 입력 폼
- [ ] 사업자 번호 입력
- [ ] 연락처 정보 확장
- [ ] 이미지 갤러리 업로드

### Day 3: 상점 유형별 정보 관리
#### 오전: 오프라인 상점 정보
- [ ] 상세 위치 입력
- [ ] 점심시간 설정
- [ ] 편의시설 체크박스
- [ ] 오시는 길 텍스트 에디터

#### 오후: 온라인 상점 정보
- [ ] 배송 정책 상세 설정
- [ ] 지역별 배송비 테이블
- [ ] 결제 수단 멀티 선택
- [ ] CS 정보 입력 폼
- [ ] 교환/환불 정책 에디터

### Day 4: 브랜드/카테고리 관리 및 표시
#### 오전: 관리 UI
- [ ] 브랜드 검색 및 추가 다이얼로그
- [ ] 주력 브랜드 설정
- [ ] 카테고리 선택 UI
- [ ] 전문 카테고리 표시

#### 오후: 메인/상세 화면 표시
- [ ] ShopCard 위젯 개선
  - 상점 유형 뱃지
  - 주요 브랜드 표시
  - 영업 상태 표시
- [ ] ShopDetailScreen 대폭 개선
  - 정보 탭 추가
  - 상점 유형별 정보 표시
  - 이미지 갤러리 뷰어

### Day 5: 통합 및 최적화
#### 오전: 복합 상점 기능
- [ ] 픽업 서비스 설정
- [ ] 온/오프라인 연계 옵션

#### 오후: 테스트 및 마무리
- [ ] 전체 플로우 테스트
- [ ] 데이터 유효성 검증
- [ ] UI/UX 개선
- [ ] 버그 수정

## 📁 파일 구조

### 수정/확장 파일
```
lib/
├── models/
│   ├── shop.dart (확장)
│   ├── shop_brand.dart (신규)
│   ├── shop_category.dart (신규)
│   └── shipping_region.dart (신규)
├── services/
│   ├── shop_service.dart (확장)
│   ├── category_service.dart (신규)
│   └── shipping_service.dart (신규)
├── screens/
│   ├── shop_detail_screen.dart (대폭 개선)
│   └── shop/
│       ├── shop_edit_screen.dart (대폭 개선)
│       ├── shop_edit_tabs/
│       │   ├── basic_info_tab.dart (신규)
│       │   ├── offline_info_tab.dart (신규)
│       │   ├── online_info_tab.dart (신규)
│       │   ├── brands_categories_tab.dart (신규)
│       │   └── images_tab.dart (신규)
│       └── widgets/
│           ├── brand_selector.dart (신규)
│           ├── category_selector.dart (신규)
│           └── shipping_region_editor.dart (신규)
└── widgets/
    ├── shop_card.dart (개선)
    ├── shop_info_section.dart (신규)
    ├── image_gallery_viewer.dart (신규)
    └── business_status_badge.dart (신규)
```

## 🎨 UI/UX 개선 사항

### 1. ShopEditScreen 개선
```
┌────────────────────────────────┐
│     상점 정보 수정              │
├────────────────────────────────┤
│ [기본] [오프라인] [온라인] [브랜드] [이미지] │
├────────────────────────────────┤
│                                │
│    (탭별 콘텐츠)                │
│                                │
└────────────────────────────────┘
```

### 2. ShopDetailScreen 개선
```
┌────────────────────────────────┐
│     [상점 이미지 갤러리]         │
├────────────────────────────────┤
│ 상점명     [영업중] [오프라인]   │
│ ⭐ 4.5 (리뷰 23)  ❤️ 찜하기    │
├────────────────────────────────┤
│ [정보] [리뷰] [공지] [이벤트]    │
├────────────────────────────────┤
│                                │
│    (탭별 콘텐츠)                │
│                                │
└────────────────────────────────┘
```

### 3. 정보 탭 구성
- **기본 정보**: 설명, 연락처, 주소
- **영업 정보**: 영업시간, 휴무일, 점심시간
- **편의시설**: 주차, 시착실, 휠체어, 아동
- **브랜드**: 취급 브랜드 목록
- **배송/결제**: (온라인) 배송비, 결제수단
- **고객센터**: (온라인) CS 정보
- **오시는 길**: (오프라인) 상세 안내

## ✅ 완료 기준

### 기능적 요구사항
- [x] PRD 3.1.1~3.1.4의 모든 정보를 입력할 수 있다
- [x] 입력된 정보가 DB에 올바르게 저장된다
- [x] 메인 화면에서 상점 정보가 표시된다
- [x] 상세 화면에서 모든 정보를 확인할 수 있다
- [x] 상점 유형별로 적절한 정보만 표시된다

### 비기능적 요구사항
- [x] 이미지 업로드 5MB 제한
- [x] 폼 유효성 검증
- [x] 반응형 UI
- [x] 로딩 상태 표시

## 🧪 테스트 시나리오

### 1. 오프라인 상점
- 모든 오프라인 정보 입력
- 영업시간/점심시간 표시 확인
- 오시는 길 정보 확인

### 2. 온라인 상점
- 배송 정책 입력 및 표시
- 결제 수단 표시
- CS 정보 확인

### 3. 복합 상점
- 온/오프라인 정보 동시 관리
- 픽업 서비스 표시

## 📝 주의사항

1. **데이터 마이그레이션**: 기존 상점 데이터 보존
2. **하위 호환성**: 기존 API와 호환 유지
3. **점진적 개선**: 기능별 단계적 배포
4. **성능**: 이미지 로딩 최적화
5. **접근성**: 모든 정보에 라벨 제공

## 🎯 예상 효과

- **정보 완성도**: 50% → 95%
- **사용자 만족도**: 상점 정보 신뢰성 향상
- **전환율**: 상세 정보로 인한 방문/구매 증가
- **운영 효율**: 정보 관리 일원화

## 🔄 다음 단계
Phase 1-1 완료 후:
1. 사용자 피드백 수집
2. Phase 2 진행 (프로모션 관리)
3. 지속적인 UI/UX 개선