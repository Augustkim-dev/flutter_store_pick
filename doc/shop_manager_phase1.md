# 상점관리자 Phase 1 개발 계획

## 📋 개요
상점관리자 기능의 Phase 1 개발로, PRD에서 정의한 필수 기능들을 구현합니다.

## 🎯 개발 목표
상점 운영자가 효율적으로 상점을 관리하고 고객과 소통할 수 있는 핵심 기능 제공

## 📅 개발 일정
- **전체 기간**: 3주 (15 영업일)
- **시작일**: 2025-01-20
- **종료일**: 2025-02-07

## 🔧 Phase 1 구현 범위

### 1. 상점 기본 정보 관리
- ✅ 상점 정보 수정 (이름, 설명, 연락처)
- ✅ 상점 유형별 정보 관리
  - 오프라인: 주소, 주차/시착 가능 여부
  - 온라인: 웹사이트 URL, 배송 정책
  - 복합: 오프라인 + 온라인 정보
- ✅ 상점 이미지 업로드 및 관리

### 2. 영업시간/배송정보 설정
- ✅ 오프라인 상점 영업시간 관리
- ✅ 온라인 상점 배송 정책 설정
- ✅ 임시 휴무/공지 기능

### 3. 리뷰 답글 기능
- ✅ 리뷰 목록 조회
- ✅ 리뷰 답글 작성 (1회만)
- ✅ 답글 수정/삭제
- ✅ 미답변 리뷰 필터링

### 4. 기본 통계 대시보드
- ✅ 주요 지표 표시 (평점, 리뷰수, 즐겨찾기)
- ✅ 평점 분포 차트
- ✅ 일간/주간/월간 통계
- ✅ 조회수 추이 그래프

## 💾 데이터베이스 스키마 변경

### 1. review_replies 테이블 (신규)
```sql
CREATE TABLE review_replies (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  review_id UUID NOT NULL REFERENCES reviews(id) ON DELETE CASCADE,
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(review_id) -- 리뷰당 답글 1개만
);

-- 인덱스
CREATE INDEX idx_review_replies_review_id ON review_replies(review_id);
CREATE INDEX idx_review_replies_shop_id ON review_replies(shop_id);
```

### 2. announcements 테이블 (신규)
```sql
CREATE TABLE announcements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  content TEXT NOT NULL,
  is_pinned BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  valid_from DATE,
  valid_until DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 인덱스
CREATE INDEX idx_announcements_shop_id ON announcements(shop_id);
CREATE INDEX idx_announcements_active ON announcements(is_active, shop_id);
```

### 3. shop_stats 뷰 (신규)
```sql
CREATE OR REPLACE VIEW shop_stats AS
SELECT 
  s.id AS shop_id,
  s.name AS shop_name,
  COUNT(DISTINCT r.id) AS review_count,
  AVG(r.rating)::NUMERIC(3,2) AS average_rating,
  COUNT(DISTINCT f.user_id) AS favorite_count,
  COUNT(DISTINCT CASE 
    WHEN r.created_at >= NOW() - INTERVAL '7 days' 
    THEN r.id 
  END) AS weekly_reviews,
  COUNT(DISTINCT CASE 
    WHEN f.created_at >= NOW() - INTERVAL '7 days' 
    THEN f.user_id 
  END) AS weekly_favorites
FROM shops s
LEFT JOIN reviews r ON s.id = r.shop_id
LEFT JOIN favorites f ON s.id = f.shop_id
GROUP BY s.id, s.name;
```

### 4. reviews_with_replies 뷰 (수정)
```sql
CREATE OR REPLACE VIEW reviews_with_replies AS
SELECT 
  r.*,
  u.username,
  u.full_name,
  u.avatar_url,
  rr.id AS reply_id,
  rr.content AS reply_content,
  rr.created_at AS reply_created_at,
  rr.updated_at AS reply_updated_at
FROM reviews r
LEFT JOIN profiles u ON r.user_id = u.id
LEFT JOIN review_replies rr ON r.id = rr.review_id
ORDER BY r.created_at DESC;
```

## 📁 파일 구조

### 신규 파일
```
lib/
├── models/
│   ├── announcement.dart        # 공지사항 모델
│   └── review_reply.dart        # 리뷰 답글 모델
├── services/
│   ├── announcement_service.dart # 공지사항 서비스
│   └── review_reply_service.dart # 리뷰 답글 서비스
├── screens/shop/
│   ├── announcement_list_screen.dart    # 공지사항 목록
│   ├── announcement_edit_screen.dart    # 공지사항 작성/수정
│   └── shop_stats_screen.dart          # 상세 통계 화면
└── widgets/
    ├── review_reply_dialog.dart    # 답글 작성 다이얼로그
    ├── stat_chart.dart             # 통계 차트 위젯
    └── announcement_card.dart      # 공지사항 카드
```

### 수정 파일
```
lib/
├── models/
│   └── review.dart              # reply 필드 추가
├── screens/shop/
│   ├── shop_dashboard_screen.dart # 대시보드 기능 확장
│   └── shop_edit_screen.dart     # 상점 정보 수정 강화
└── widgets/
    └── review_item.dart          # 답글 표시 추가
```

## 📦 필요한 패키지

```yaml
dependencies:
  # 차트 및 그래프
  fl_chart: ^0.68.0
  
  # 이미지 처리
  image_picker: ^1.0.0
  cached_network_image: ^3.3.0
  
  # 날짜 선택
  table_calendar: ^3.0.9
  
  # 상태 관리 (기존)
  provider: ^6.1.1
```

## 🚀 구현 순서

### Week 1: 데이터 레이어 및 기본 기능
**Day 1-2: 데이터베이스 설정**
- [ ] Supabase에 새 테이블 생성
- [ ] 뷰 생성 및 권한 설정
- [ ] RLS(Row Level Security) 정책 설정

**Day 3-4: 모델 및 서비스 구현**
- [ ] announcement.dart 모델 생성
- [ ] review_reply.dart 모델 생성
- [ ] announcement_service.dart 구현
- [ ] review_reply_service.dart 구현
- [ ] review.dart 모델 업데이트 (reply 필드)

**Day 5: 상점 정보 관리**
- [ ] shop_edit_screen.dart 개선
- [ ] 상점 유형별 입력 필드 추가
- [ ] 이미지 업로드 기능

### Week 2: UI 구현
**Day 6-7: 리뷰 답글 시스템**
- [ ] review_reply_dialog.dart 구현
- [ ] review_item.dart 수정 (답글 표시)
- [ ] 답글 작성/수정/삭제 기능

**Day 8-9: 통계 대시보드**
- [ ] shop_dashboard_screen.dart 확장
- [ ] stat_chart.dart 위젯 구현
- [ ] 통계 필터링 (일/주/월)

**Day 10: 공지사항 기능**
- [ ] announcement_list_screen.dart 구현
- [ ] announcement_edit_screen.dart 구현
- [ ] announcement_card.dart 위젯

### Week 3: 통합 및 최적화
**Day 11-12: 통합 테스트**
- [ ] 전체 기능 통합 테스트
- [ ] 엣지 케이스 처리
- [ ] 에러 핸들링 개선

**Day 13: 성능 최적화**
- [ ] 이미지 로딩 최적화
- [ ] 데이터 페이징 구현
- [ ] 캐싱 전략 적용

**Day 14-15: 마무리**
- [ ] 버그 수정
- [ ] UI/UX 개선
- [ ] 문서화

## ✅ 완료 기준

### 기능적 요구사항
- [x] 상점 정보를 수정할 수 있다
- [x] 영업시간/배송정보를 설정할 수 있다
- [x] 리뷰에 답글을 작성/수정/삭제할 수 있다
- [x] 통계 대시보드에서 주요 지표를 확인할 수 있다
- [x] 공지사항을 작성/수정/삭제할 수 있다

### 비기능적 요구사항
- [x] 모든 API 응답 시간 < 2초
- [x] 이미지 업로드 < 5MB 제한
- [x] 오프라인 모드 지원 (캐싱)
- [x] 에러 메시지 사용자 친화적

## 🧪 테스트 계획

### 단위 테스트
- 모든 서비스 클래스 메서드
- 모델 클래스 직렬화/역직렬화

### 통합 테스트
- 리뷰 답글 작성 플로우
- 상점 정보 수정 플로우
- 공지사항 CRUD 플로우

### UI 테스트
- 대시보드 렌더링
- 차트 표시
- 이미지 업로드

## 📝 주의사항

1. **권한 체크**: 모든 작업에서 상점 소유자 확인 필수
2. **데이터 검증**: 입력 데이터 유효성 검사 철저히
3. **에러 처리**: 사용자 친화적 에러 메시지 제공
4. **성능**: 대량 데이터 처리 시 페이징 적용
5. **보안**: SQL Injection, XSS 방지

## 🔄 다음 단계 (Phase 2)
- 프로모션 관리 시스템
- 상세 통계 분석 (유입 경로, 검색어)
- 단골 고객 관리
- 인증 뱃지 시스템

## 📊 성공 지표
- 상점관리자 주 1회 이상 접속률: 70%
- 리뷰 답글률: 80% 이상
- 평균 답글 시간: 24시간 이내
- 기능 사용률: 각 기능별 50% 이상