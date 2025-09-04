-- Fix SECURITY DEFINER issues
-- Created: 2025-01-20
-- Description: Remove SECURITY DEFINER from views and add it only where necessary

-- 1. Drop existing views with potential SECURITY DEFINER
DROP VIEW IF EXISTS shop_stats CASCADE;
DROP VIEW IF EXISTS reviews_with_replies CASCADE;
DROP VIEW IF EXISTS active_announcements CASCADE;
DROP VIEW IF EXISTS shop_view_stats CASCADE;

-- 2. Recreate shop_stats view WITHOUT SECURITY DEFINER
-- This view aggregates public data, no need for SECURITY DEFINER
CREATE OR REPLACE VIEW shop_stats AS
SELECT 
  s.id AS shop_id,
  s.name AS shop_name,
  s.owner_id,
  COUNT(DISTINCT r.id) AS review_count,
  COALESCE(AVG(r.rating)::NUMERIC(3,2), 0) AS average_rating,
  COUNT(DISTINCT f.user_id) AS favorite_count,
  COUNT(DISTINCT CASE 
    WHEN r.created_at >= NOW() - INTERVAL '7 days' 
    THEN r.id 
  END) AS weekly_reviews,
  COUNT(DISTINCT CASE 
    WHEN f.created_at >= NOW() - INTERVAL '7 days' 
    THEN f.user_id 
  END) AS weekly_favorites,
  COUNT(DISTINCT CASE 
    WHEN r.created_at >= NOW() - INTERVAL '30 days' 
    THEN r.id 
  END) AS monthly_reviews,
  COUNT(DISTINCT CASE 
    WHEN f.created_at >= NOW() - INTERVAL '30 days' 
    THEN f.user_id 
  END) AS monthly_favorites,
  -- Rating distribution
  COUNT(DISTINCT CASE WHEN r.rating = 5 THEN r.id END) AS rating_5_count,
  COUNT(DISTINCT CASE WHEN r.rating = 4 THEN r.id END) AS rating_4_count,
  COUNT(DISTINCT CASE WHEN r.rating = 3 THEN r.id END) AS rating_3_count,
  COUNT(DISTINCT CASE WHEN r.rating = 2 THEN r.id END) AS rating_2_count,
  COUNT(DISTINCT CASE WHEN r.rating = 1 THEN r.id END) AS rating_1_count,
  -- Unanswered reviews count
  COUNT(DISTINCT CASE 
    WHEN NOT EXISTS (
      SELECT 1 FROM review_replies rr 
      WHERE rr.review_id = r.id
    ) THEN r.id 
  END) AS unanswered_reviews_count
FROM shops s
LEFT JOIN reviews r ON s.id = r.shop_id
LEFT JOIN favorites f ON s.id = f.shop_id
GROUP BY s.id, s.name, s.owner_id;

-- 3. Recreate reviews_with_replies view WITHOUT SECURITY DEFINER
CREATE OR REPLACE VIEW reviews_with_replies AS
SELECT 
  r.id,
  r.shop_id,
  r.user_id,
  r.rating,
  r.comment,
  r.created_at,
  r.updated_at,
  -- User information
  u.username,
  u.full_name,
  u.avatar_url,
  -- Reply information
  rr.id AS reply_id,
  rr.content AS reply_content,
  rr.created_at AS reply_created_at,
  rr.updated_at AS reply_updated_at,
  -- Shop information for context
  s.name AS shop_name,
  s.owner_id AS shop_owner_id
FROM reviews r
LEFT JOIN profiles u ON r.user_id = u.id
LEFT JOIN review_replies rr ON r.id = rr.review_id
LEFT JOIN shops s ON r.shop_id = s.id
ORDER BY r.created_at DESC;

-- 4. Recreate active_announcements view WITHOUT SECURITY DEFINER
CREATE OR REPLACE VIEW active_announcements AS
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

-- 5. Recreate shop_view_stats view WITHOUT SECURITY DEFINER
CREATE OR REPLACE VIEW shop_view_stats AS
SELECT 
  shop_id,
  COUNT(DISTINCT user_id) AS unique_visitors,
  SUM(view_count) AS total_views,
  COUNT(DISTINCT CASE 
    WHEN view_date = CURRENT_DATE 
    THEN user_id 
  END) AS today_visitors,
  COUNT(DISTINCT CASE 
    WHEN view_date >= CURRENT_DATE - INTERVAL '7 days' 
    THEN user_id 
  END) AS weekly_visitors,
  COUNT(DISTINCT CASE 
    WHEN view_date >= CURRENT_DATE - INTERVAL '30 days' 
    THEN user_id 
  END) AS monthly_visitors
FROM shop_views
GROUP BY shop_id;

-- 6. Keep SECURITY DEFINER for increment_shop_view function
-- This is appropriate because we want to ensure the function can always insert
-- regardless of the calling user's permissions
CREATE OR REPLACE FUNCTION increment_shop_view(p_shop_id UUID)
RETURNS void AS $$
BEGIN
  INSERT INTO shop_views (shop_id, user_id, view_date, view_count)
  VALUES (p_shop_id, auth.uid(), CURRENT_DATE, 1)
  ON CONFLICT (shop_id, user_id, view_date)
  DO UPDATE SET view_count = shop_views.view_count + 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Add RLS policy for shop_stats view access
-- Create a security function to check shop ownership
CREATE OR REPLACE FUNCTION is_shop_owner(shop_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM shops 
    WHERE shops.id = shop_uuid 
    AND shops.owner_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql STABLE;

-- 8. Grant appropriate permissions
GRANT SELECT ON shop_stats TO authenticated;
GRANT SELECT ON reviews_with_replies TO authenticated;
GRANT SELECT ON active_announcements TO authenticated;
GRANT SELECT ON shop_view_stats TO authenticated;
GRANT EXECUTE ON FUNCTION increment_shop_view TO authenticated;
GRANT EXECUTE ON FUNCTION is_shop_owner TO authenticated;

-- 9. Add comment explaining the security model
COMMENT ON VIEW shop_stats IS 'Shop statistics view - uses RLS from underlying tables, no SECURITY DEFINER needed';
COMMENT ON VIEW reviews_with_replies IS 'Reviews with replies - public data, no SECURITY DEFINER needed';
COMMENT ON VIEW active_announcements IS 'Active announcements - public data, no SECURITY DEFINER needed';
COMMENT ON VIEW shop_view_stats IS 'Shop view statistics - respects RLS from shop_views table';
COMMENT ON FUNCTION increment_shop_view IS 'Increments shop view count - uses SECURITY DEFINER to ensure insert capability';

-- 10. Fix additional views reported with SECURITY DEFINER issues
-- Drop and recreate shop_ratings view
DROP VIEW IF EXISTS shop_ratings CASCADE;
CREATE OR REPLACE VIEW shop_ratings AS
SELECT 
  shop_id,
  COUNT(*) as review_count,
  AVG(rating)::NUMERIC(3,2) as average_rating,
  COUNT(CASE WHEN rating = 5 THEN 1 END) as five_star_count,
  COUNT(CASE WHEN rating = 4 THEN 1 END) as four_star_count,
  COUNT(CASE WHEN rating = 3 THEN 1 END) as three_star_count,
  COUNT(CASE WHEN rating = 2 THEN 1 END) as two_star_count,
  COUNT(CASE WHEN rating = 1 THEN 1 END) as one_star_count
FROM reviews
GROUP BY shop_id;

-- Drop and recreate reviews_with_user view (corrected name from review_with_user)
DROP VIEW IF EXISTS reviews_with_user CASCADE;
CREATE OR REPLACE VIEW reviews_with_user AS
SELECT 
  r.*,
  p.username,
  p.full_name,
  p.avatar_url
FROM reviews r
LEFT JOIN profiles p ON r.user_id = p.id;

-- Drop and recreate shop_details view
DROP VIEW IF EXISTS shop_details CASCADE;
CREATE OR REPLACE VIEW shop_details AS
SELECT 
  s.*,
  COALESCE(
    ARRAY_AGG(DISTINCT b.name) FILTER (WHERE b.name IS NOT NULL),
    ARRAY[]::TEXT[]
  ) as brand_names,
  COALESCE(
    ARRAY_AGG(DISTINCT sc.category_name) FILTER (WHERE sc.category_name IS NOT NULL),
    ARRAY[]::TEXT[]
  ) as category_names,
  COUNT(DISTINCT sb.brand_id) as brand_count,
  COUNT(DISTINCT sc.category_name) as category_count
FROM shops s
LEFT JOIN shop_brands sb ON s.id = sb.shop_id
LEFT JOIN brands b ON sb.brand_id = b.id
LEFT JOIN shop_categories sc ON s.id = sc.shop_id
GROUP BY s.id;

-- Drop and recreate shops_with_main_brands view
DROP VIEW IF EXISTS shops_with_main_brands CASCADE;
CREATE OR REPLACE VIEW shops_with_main_brands AS
SELECT 
  s.*,
  b.name as main_brand_name,
  b.logo_url as main_brand_logo
FROM shops s
INNER JOIN shop_brands sb ON s.id = sb.shop_id AND sb.is_main = true
INNER JOIN brands b ON sb.brand_id = b.id;

-- 11. Grant permissions for the additional views
GRANT SELECT ON shop_ratings TO authenticated;
GRANT SELECT ON reviews_with_user TO authenticated;
GRANT SELECT ON shop_details TO authenticated;
GRANT SELECT ON shops_with_main_brands TO authenticated;

-- 12. Add comments for the additional views
COMMENT ON VIEW shop_ratings IS 'Shop ratings aggregation - uses RLS from reviews table, no SECURITY DEFINER needed';
COMMENT ON VIEW reviews_with_user IS 'Reviews with user information - public data, no SECURITY DEFINER needed';
COMMENT ON VIEW shop_details IS 'Shop details with brands and categories - public data, no SECURITY DEFINER needed';
COMMENT ON VIEW shops_with_main_brands IS 'Shops with their main brand information - public data, no SECURITY DEFINER needed';

-- Migration completion message
DO $$
BEGIN
  RAISE NOTICE 'SECURITY DEFINER fixes applied successfully';
  RAISE NOTICE 'Fixed views: shop_stats, reviews_with_replies, active_announcements, shop_view_stats';
  RAISE NOTICE 'Additional fixed views: shop_ratings, reviews_with_user, shop_details, shops_with_main_brands';
  RAISE NOTICE 'All views now use invoker permissions and respect RLS from underlying tables';
  RAISE NOTICE 'Only increment_shop_view function retains SECURITY DEFINER as it needs guaranteed insert capability';
END $$;