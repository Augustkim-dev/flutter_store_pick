-- Insert sample brands
INSERT INTO brands (name, description) VALUES
('Wear Moi', '프랑스 발레 전문 브랜드'),
('Capezio', '미국 댄스웨어 브랜드'),
('Gaynor Minden', '프리미엄 포인트 슈즈 브랜드'),
('Bloch', '호주 댄스웨어 브랜드'),
('Repetto', '프랑스 명품 발레 브랜드'),
('Sansha', '프랑스 댄스웨어 브랜드'),
('Grishko', '러시아 발레 브랜드'),
('Russian Pointe', '러시아 포인트 슈즈 전문'),
('So Danca', '브라질 댄스웨어 브랜드'),
('Mirella', '발레 의류 전문 브랜드');

-- Insert sample shops with image URLs
INSERT INTO shops (
    name, shop_type, description, image_url, rating, review_count,
    address, phone, latitude, longitude, business_hours, 
    parking_available, fitting_available,
    website_url, shipping_fee, free_shipping_min, delivery_info,
    brands, categories, is_verified
) VALUES
-- 오프라인 매장
(
    '발레리나 하우스',
    'offline',
    '강남 최대 규모의 발레 용품 전문점',
    'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=800',
    4.8, 127,
    '서울특별시 강남구 신사동 123-45',
    '02-1234-5678',
    37.5172, 127.0286,
    '평일 10:00-20:00, 주말 11:00-19:00',
    true, true,
    NULL, NULL, NULL, NULL,
    ARRAY['Wear Moi', 'Capezio', 'Bloch'],
    ARRAY['레오타드', '타이즈', '슈즈'],
    true
),
(
    '프리마 발레샵',
    'offline',
    '발레 전문가가 운영하는 부티크 샵',
    'https://images.unsplash.com/photo-1514228742587-6b1558fcca3d?w=800',
    4.9, 89,
    '서울특별시 서초구 서초동 789-12',
    '02-9876-5432',
    37.4877, 127.0174,
    '평일 11:00-19:00, 토요일 11:00-17:00, 일요일 휴무',
    false, true,
    NULL, NULL, NULL, NULL,
    ARRAY['Gaynor Minden', 'Repetto', 'Grishko'],
    ARRAY['포인트슈즈', '레오타드', '액세서리'],
    true
),

-- 온라인 쇼핑몰
(
    '발레마켓',
    'online',
    '국내 최대 발레 용품 온라인 쇼핑몰',
    'https://images.unsplash.com/photo-1556906781-9a412961c28c?w=800',
    4.7, 342,
    NULL, NULL, NULL, NULL, NULL, NULL, NULL,
    'https://www.balletmarket.co.kr',
    3000, 50000,
    '평일 오후 2시 이전 주문시 당일 발송',
    ARRAY['Wear Moi', 'Capezio', 'Sansha', 'So Danca'],
    ARRAY['레오타드', '타이즈', '슈즈', '연습복'],
    true
),
(
    '댄스플러스',
    'online',
    '발레&댄스 용품 전문 온라인몰',
    'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=800',
    4.5, 218,
    NULL, NULL, NULL, NULL, NULL, NULL, NULL,
    'https://www.danceplus.kr',
    2500, 30000,
    '평일 오후 4시 이전 주문시 익일 도착',
    ARRAY['Bloch', 'Mirella', 'So Danca'],
    ARRAY['레오타드', '워머', '가방'],
    false
),

-- 하이브리드 (온/오프라인)
(
    '아라베스크',
    'hybrid',
    '온/오프라인 통합 발레 전문점',
    'https://images.unsplash.com/photo-1490723286627-4b66e6b2882a?w=800',
    4.6, 156,
    '서울특별시 마포구 서교동 456-78',
    '02-3456-7890',
    37.5547, 126.9222,
    '평일 11:00-20:00, 주말 12:00-18:00',
    true, true,
    'https://www.arabesque.kr',
    3000, 40000,
    '온라인 주문 후 매장 픽업 가능',
    ARRAY['Russian Pointe', 'Grishko', 'Wear Moi'],
    ARRAY['포인트슈즈', '튜투', '레오타드'],
    true
),
(
    '그라세 발레',
    'hybrid',
    '프리미엄 발레 용품 셀렉샵',
    'https://images.unsplash.com/photo-1518834107812-67b0b7c58434?w=800',
    4.7, 94,
    '서울특별시 강남구 청담동 234-56',
    '02-5678-1234',
    37.5197, 127.0471,
    '평일 10:30-19:30, 토요일 11:00-18:00, 일요일 휴무',
    true, true,
    'https://www.grace-ballet.com',
    0, 0,
    '무료배송, 매장 픽업 가능',
    ARRAY['Repetto', 'Gaynor Minden', 'Wear Moi'],
    ARRAY['레오타드', '포인트슈즈', '액세서리'],
    true
),

-- 추가 오프라인 매장
(
    '포인트 발레샵',
    'offline',
    '포인트 슈즈 전문점',
    'https://images.unsplash.com/photo-1508807526345-15e9b5f4eaff?w=800',
    4.8, 67,
    '서울특별시 종로구 인사동 123-4',
    '02-7890-1234',
    37.5734, 126.9869,
    '평일 10:00-19:00, 주말 휴무',
    false, true,
    NULL, NULL, NULL, NULL,
    ARRAY['Gaynor Minden', 'Russian Pointe', 'Grishko'],
    ARRAY['포인트슈즈', '토슈즈', '액세서리'],
    false
),

-- 추가 온라인 쇼핑몰
(
    '발레스토어',
    'online',
    '합리적인 가격의 발레 용품점',
    'https://images.unsplash.com/photo-1599309329365-0a9ed45a1da3?w=800',
    4.4, 128,
    NULL, NULL, NULL, NULL, NULL, NULL, NULL,
    'https://www.balletstore.co.kr',
    2500, 25000,
    '평일 오후 3시 이전 주문시 당일 발송',
    ARRAY['Capezio', 'So Danca', 'Sansha'],
    ARRAY['레오타드', '타이즈', '슈즈'],
    false
),
(
    '튜투샵',
    'online',
    '튜투 및 무대 의상 전문',
    'https://images.unsplash.com/photo-1595908129746-57ca1a63dd4d?w=800',
    4.6, 73,
    NULL, NULL, NULL, NULL, NULL, NULL, NULL,
    'https://www.tutushop.kr',
    5000, 100000,
    '주문 제작 상품 2-3주 소요',
    ARRAY['Custom', 'Wear Moi', 'Mirella'],
    ARRAY['튜투', '무대의상', '액세서리'],
    true
),

-- 추가 하이브리드 매장
(
    '발레리노',
    'hybrid',
    '초보자를 위한 친절한 발레샵',
    'https://images.unsplash.com/photo-1574482620811-1aa16ffe3c82?w=800',
    4.5, 186,
    '서울특별시 송파구 잠실동 567-89',
    '02-4567-8901',
    37.5145, 127.1028,
    '평일 10:00-21:00, 주말 10:00-20:00',
    true, false,
    'https://www.ballerino.co.kr',
    3000, 35000,
    '온라인 주문 매장 수령시 10% 할인',
    ARRAY['Capezio', 'Bloch', 'So Danca'],
    ARRAY['입문용품', '레오타드', '슈즈'],
    false
);