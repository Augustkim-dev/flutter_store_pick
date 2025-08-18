# Supabase RLS 정책 수정 가이드

## 문제
- profiles 테이블의 RLS 정책이 사용자가 자신의 프로필을 생성하는 것을 막고 있음
- 오류 메시지: "new row violates row-level security policy for table profiles"
- 이로 인해 즐겨찾기 기능이 작동하지 않음 (foreign key constraint 오류)

## 해결 방법

### 방법 1: Supabase Dashboard에서 직접 수정

1. [Supabase Dashboard](https://app.supabase.com)에 로그인
2. 프로젝트 선택
3. 왼쪽 메뉴에서 **Authentication** → **Policies** 클릭
4. **profiles** 테이블 찾기
5. 기존 정책 확인하고 다음 정책이 있는지 확인:
   - SELECT: 모든 사용자 허용
   - INSERT: auth.uid() = id 조건으로 허용 ⚠️ **이 정책이 없으면 추가 필요**
   - UPDATE: auth.uid() = id 조건으로 허용
   - DELETE: auth.uid() = id 조건으로 허용

6. INSERT 정책이 없다면:
   - "New Policy" 클릭
   - "For full customization" 선택
   - Policy name: `Users can create own profile`
   - Allowed operation: INSERT
   - Target roles: authenticated
   - WITH CHECK expression: `auth.uid() = id`
   - Save

### 방법 2: SQL Editor에서 스크립트 실행

1. Supabase Dashboard에서 **SQL Editor** 클릭
2. 새 쿼리 생성
3. `complete_fix.sql` 파일의 내용을 복사하여 붙여넣기
4. "Run" 버튼 클릭
5. 성공 메시지 확인

### 방법 3: 빠른 수정 (임시)

RLS를 일시적으로 비활성화 (개발 중에만 사용):

```sql
-- ⚠️ 경고: 프로덕션에서는 사용하지 마세요!
-- profiles 테이블 RLS 비활성화
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;

-- favorites 테이블 RLS 비활성화  
ALTER TABLE favorites DISABLE ROW LEVEL SECURITY;
```

다시 활성화:
```sql
-- RLS 다시 활성화
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;
```

## 확인 방법

1. 앱에서 로그아웃
2. 다시 로그인
3. 마이페이지 → "Test Favorites" 실행
4. 모든 테스트가 ✅로 표시되는지 확인
5. 홈 화면에서 즐겨찾기 버튼 테스트

## 예상 결과

수정 후:
- ✅ Profile 생성 성공
- ✅ 즐겨찾기 추가/제거 성공
- ✅ 마이페이지에서 즐겨찾기 목록 확인 가능

## 문제가 계속되면

1. Supabase Dashboard에서 **Database** → **Tables** 
2. profiles 테이블 확인
3. RLS가 활성화되어 있는지 확인
4. 정책이 올바르게 설정되었는지 확인

또는 임시로 RLS를 비활성화하여 테스트 후 문제를 파악