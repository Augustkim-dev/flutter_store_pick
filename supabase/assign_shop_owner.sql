-- 특정 사용자를 특정 상점의 관리자로 설정

-- 1. 사용자를 shop_owner 권한으로 변경
UPDATE profiles 
SET user_type = 'shop_owner'
WHERE id = '3ddc2f3d-55c1-4713-8928-5a276101a99b';

-- 2. 상점에 owner_id 설정
UPDATE shops 
SET owner_id = '3ddc2f3d-55c1-4713-8928-5a276101a99b'
WHERE id = '33196250-377f-46d0-b52e-161cf8b2fb36';

-- 3. 결과 확인
SELECT 
    p.id as user_id,
    p.username,
    p.user_type,
    s.id as shop_id,
    s.name as shop_name,
    s.owner_id
FROM profiles p
JOIN shops s ON s.owner_id = p.id
WHERE p.id = '3ddc2f3d-55c1-4713-8928-5a276101a99b';

-- 4. 해당 상점에 영업시간 샘플 데이터 추가 (선택사항)
INSERT INTO business_hours (shop_id, day_of_week, open_time, close_time, is_closed)
VALUES 
    ('33196250-377f-46d0-b52e-161cf8b2fb36', 0, '10:00', '18:00', false), -- 일요일
    ('33196250-377f-46d0-b52e-161cf8b2fb36', 1, '09:00', '20:00', false), -- 월요일
    ('33196250-377f-46d0-b52e-161cf8b2fb36', 2, '09:00', '20:00', false), -- 화요일
    ('33196250-377f-46d0-b52e-161cf8b2fb36', 3, '09:00', '20:00', false), -- 수요일
    ('33196250-377f-46d0-b52e-161cf8b2fb36', 4, '09:00', '20:00', false), -- 목요일
    ('33196250-377f-46d0-b52e-161cf8b2fb36', 5, '09:00', '20:00', false), -- 금요일
    ('33196250-377f-46d0-b52e-161cf8b2fb36', 6, '10:00', '19:00', false)  -- 토요일
ON CONFLICT (shop_id, day_of_week) DO NOTHING;