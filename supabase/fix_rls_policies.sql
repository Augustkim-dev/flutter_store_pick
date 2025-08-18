-- profiles 테이블의 RLS 정책 수정

-- 기존 정책 삭제
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;

-- 새로운 정책 생성

-- 1. 모든 사용자가 프로필을 조회할 수 있음
CREATE POLICY "Public profiles are viewable by everyone" 
ON profiles FOR SELECT 
USING (true);

-- 2. 사용자는 자신의 프로필을 생성할 수 있음 (INSERT)
CREATE POLICY "Users can insert own profile" 
ON profiles FOR INSERT 
WITH CHECK (auth.uid() = id);

-- 3. 사용자는 자신의 프로필을 수정할 수 있음 (UPDATE)
CREATE POLICY "Users can update own profile" 
ON profiles FOR UPDATE 
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- 4. 사용자는 자신의 프로필을 삭제할 수 있음 (DELETE)
CREATE POLICY "Users can delete own profile" 
ON profiles FOR DELETE 
USING (auth.uid() = id);

-- favorites 테이블의 RLS 정책도 확인
DROP POLICY IF EXISTS "Users can manage own favorites" ON favorites;

-- favorites 테이블에 대한 새로운 정책
CREATE POLICY "Users can view all favorites" 
ON favorites FOR SELECT 
USING (true);

CREATE POLICY "Users can insert own favorites" 
ON favorites FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own favorites" 
ON favorites FOR UPDATE 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own favorites" 
ON favorites FOR DELETE 
USING (auth.uid() = user_id);