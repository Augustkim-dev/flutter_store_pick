-- Missing Views Creation
-- Created: 2025-01-20
-- Description: Flutter 앱에서 필요한 누락된 뷰 생성

-- ========================================
-- 1. active_announcements 뷰 생성
-- ========================================

DROP VIEW IF EXISTS active_announcements CASCADE;

CREATE VIEW active_announcements AS
SELECT 
  a.*,
  s.name AS shop_name,
  s.owner_id AS shop_owner_id
FROM announcements a
JOIN shops s ON a.shop_id = s.id
WHERE a.is_active = true
  AND (a.valid_from IS NULL OR a.valid_from <= CURRENT_DATE)
  AND (a.valid_until IS NULL OR a.valid_until >= CURRENT_DATE)
ORDER BY a.is_pinned DESC, a.created_at DESC;

-- 권한 부여
GRANT SELECT ON active_announcements TO authenticated;

-- ========================================
-- 2. reviews_with_replies 뷰 생성
-- ========================================

DROP VIEW IF EXISTS reviews_with_replies CASCADE;

CREATE VIEW reviews_with_replies AS
SELECT 
  r.id,
  r.shop_id,
  r.user_id,
  r.rating,
  r.comment,
  r.created_at,
  r.updated_at,
  p.username,
  p.full_name,
  p.avatar_url,
  rr.id AS reply_id,
  rr.content AS reply_content,
  rr.created_at AS reply_created_at,
  rr.updated_at AS reply_updated_at,
  s.name AS shop_name,
  s.owner_id AS shop_owner_id
FROM reviews r
LEFT JOIN profiles p ON r.user_id = p.id
LEFT JOIN review_replies rr ON r.id = rr.review_id
LEFT JOIN shops s ON r.shop_id = s.id
ORDER BY r.created_at DESC;

-- 권한 부여
GRANT SELECT ON reviews_with_replies TO authenticated;

-- ========================================
-- 3. shop_view_stats 뷰 생성 (shop_views 테이블이 있는 경우)
-- ========================================

-- shop_views 테이블이 있는지 확인하고 뷰 생성
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'shop_views'
  ) THEN
    -- 뷰가 이미 있으면 삭제
    DROP VIEW IF EXISTS shop_view_stats CASCADE;
    
    -- 뷰 생성
    CREATE VIEW shop_view_stats AS
    SELECT 
      shop_id,
      COUNT(DISTINCT user_id) AS unique_visitors,
      SUM(view_count) AS total_views,
      COUNT(DISTINCT user_id) FILTER (WHERE view_date = CURRENT_DATE) AS today_visitors,
      COUNT(DISTINCT user_id) FILTER (WHERE view_date >= CURRENT_DATE - INTERVAL '7 days') AS weekly_visitors,
      COUNT(DISTINCT user_id) FILTER (WHERE view_date >= CURRENT_DATE - INTERVAL '30 days') AS monthly_visitors
    FROM shop_views
    GROUP BY shop_id;
    
    -- 권한 부여
    GRANT SELECT ON shop_view_stats TO authenticated;
    
    RAISE NOTICE 'shop_view_stats view created successfully';
  ELSE
    RAISE NOTICE 'shop_views table not found, skipping shop_view_stats view creation';
  END IF;
END $$;

-- ========================================
-- 4. shops_with_main_brands 뷰 생성
-- ========================================

DROP VIEW IF EXISTS shops_with_main_brands CASCADE;

CREATE VIEW shops_with_main_brands AS
SELECT 
  s.*,
  b.name as main_brand_name,
  b.logo_url as main_brand_logo
FROM shops s
INNER JOIN shop_brands sb ON s.id = sb.shop_id AND sb.is_main = true
INNER JOIN brands b ON sb.brand_id = b.id;

-- 권한 부여
GRANT SELECT ON shops_with_main_brands TO authenticated;

-- ========================================
-- 5. 완료 메시지
-- ========================================

DO $$
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Missing views created successfully';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Created views:';
  RAISE NOTICE '- active_announcements';
  RAISE NOTICE '- reviews_with_replies';
  RAISE NOTICE '- shop_view_stats (if shop_views table exists)';
  RAISE NOTICE '- shops_with_main_brands';
  RAISE NOTICE '========================================';
END $$;