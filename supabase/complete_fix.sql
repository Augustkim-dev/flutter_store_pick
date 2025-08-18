-- 완전한 RLS 정책 수정 스크립트
-- Supabase SQL Editor에서 실행하세요

-- 1. profiles 테이블의 기존 정책 모두 삭제
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
DROP POLICY IF EXISTS "Users can delete own profile" ON profiles;

-- 2. profiles 테이블에 새로운 정책 생성
-- 모든 사용자가 프로필을 조회할 수 있음
CREATE POLICY "Anyone can view profiles" 
ON profiles FOR SELECT 
USING (true);

-- 인증된 사용자는 자신의 프로필을 생성할 수 있음
CREATE POLICY "Users can create own profile" 
ON profiles FOR INSERT 
WITH CHECK (auth.uid() = id);

-- 인증된 사용자는 자신의 프로필을 수정할 수 있음
CREATE POLICY "Users can update own profile" 
ON profiles FOR UPDATE 
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- 인증된 사용자는 자신의 프로필을 삭제할 수 있음
CREATE POLICY "Users can delete own profile" 
ON profiles FOR DELETE 
USING (auth.uid() = id);

-- 3. favorites 테이블의 기존 정책 삭제
DROP POLICY IF EXISTS "Users can manage own favorites" ON favorites;
DROP POLICY IF EXISTS "Users can view all favorites" ON favorites;
DROP POLICY IF EXISTS "Users can insert own favorites" ON favorites;
DROP POLICY IF EXISTS "Users can update own favorites" ON favorites;
DROP POLICY IF EXISTS "Users can delete own favorites" ON favorites;

-- 4. favorites 테이블에 새로운 정책 생성
-- 모든 사용자가 즐겨찾기를 조회할 수 있음 (선택적)
CREATE POLICY "Anyone can view favorites" 
ON favorites FOR SELECT 
USING (true);

-- 인증된 사용자는 자신의 즐겨찾기를 추가할 수 있음
CREATE POLICY "Users can add own favorites" 
ON favorites FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- 인증된 사용자는 자신의 즐겨찾기를 수정할 수 있음
CREATE POLICY "Users can update own favorites" 
ON favorites FOR UPDATE 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- 인증된 사용자는 자신의 즐겨찾기를 삭제할 수 있음
CREATE POLICY "Users can delete own favorites" 
ON favorites FOR DELETE 
USING (auth.uid() = user_id);

-- 5. 테스트: 현재 정책 확인
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename IN ('profiles', 'favorites')
ORDER BY tablename, policyname;