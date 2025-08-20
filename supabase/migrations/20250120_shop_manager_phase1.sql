-- Shop Manager Phase 1 Database Schema
-- Created: 2025-01-20
-- Description: Tables and views for shop manager core features

-- 1. Review Replies Table
-- Stores shop owner replies to customer reviews (one reply per review)
CREATE TABLE IF NOT EXISTS review_replies (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  review_id UUID NOT NULL REFERENCES reviews(id) ON DELETE CASCADE,
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(review_id) -- Ensures only one reply per review
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_review_replies_review_id ON review_replies(review_id);
CREATE INDEX IF NOT EXISTS idx_review_replies_shop_id ON review_replies(shop_id);

-- Enable RLS (Row Level Security)
ALTER TABLE review_replies ENABLE ROW LEVEL SECURITY;

-- RLS Policies for review_replies
-- Allow shop owners to insert replies for their own shops
CREATE POLICY "Shop owners can insert replies" ON review_replies
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM shops 
      WHERE shops.id = shop_id 
      AND shops.owner_id = auth.uid()
    )
  );

-- Allow shop owners to update their own replies
CREATE POLICY "Shop owners can update their replies" ON review_replies
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM shops 
      WHERE shops.id = shop_id 
      AND shops.owner_id = auth.uid()
    )
  );

-- Allow shop owners to delete their own replies
CREATE POLICY "Shop owners can delete their replies" ON review_replies
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM shops 
      WHERE shops.id = shop_id 
      AND shops.owner_id = auth.uid()
    )
  );

-- Allow everyone to read replies
CREATE POLICY "Everyone can read replies" ON review_replies
  FOR SELECT
  USING (true);

-- 2. Announcements Table
-- Stores shop announcements and notices
CREATE TABLE IF NOT EXISTS announcements (
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

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_announcements_shop_id ON announcements(shop_id);
CREATE INDEX IF NOT EXISTS idx_announcements_active ON announcements(is_active, shop_id);
CREATE INDEX IF NOT EXISTS idx_announcements_pinned ON announcements(is_pinned, shop_id);

-- Enable RLS
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;

-- RLS Policies for announcements
-- Shop owners can manage their announcements
CREATE POLICY "Shop owners can insert announcements" ON announcements
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM shops 
      WHERE shops.id = shop_id 
      AND shops.owner_id = auth.uid()
    )
  );

CREATE POLICY "Shop owners can update announcements" ON announcements
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM shops 
      WHERE shops.id = shop_id 
      AND shops.owner_id = auth.uid()
    )
  );

CREATE POLICY "Shop owners can delete announcements" ON announcements
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM shops 
      WHERE shops.id = shop_id 
      AND shops.owner_id = auth.uid()
    )
  );

-- Everyone can read active announcements
CREATE POLICY "Everyone can read active announcements" ON announcements
  FOR SELECT
  USING (is_active = true OR EXISTS (
    SELECT 1 FROM shops 
    WHERE shops.id = shop_id 
    AND shops.owner_id = auth.uid()
  ));

-- 3. Shop Statistics View
-- Aggregates shop statistics for dashboard
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

-- Grant select permission on the view
GRANT SELECT ON shop_stats TO authenticated;

-- 4. Reviews with Replies View
-- Joins reviews with their replies for easier querying
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

-- Grant select permission on the view
GRANT SELECT ON reviews_with_replies TO authenticated;

-- 5. Active Announcements View
-- Shows only currently active announcements
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

-- Grant select permission on the view
GRANT SELECT ON active_announcements TO authenticated;

-- 6. Update trigger for updated_at columns
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to review_replies
CREATE TRIGGER update_review_replies_updated_at 
  BEFORE UPDATE ON review_replies 
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

-- Apply trigger to announcements
CREATE TRIGGER update_announcements_updated_at 
  BEFORE UPDATE ON announcements 
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

-- 7. Shop daily views tracking (for analytics)
CREATE TABLE IF NOT EXISTS shop_views (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  view_date DATE NOT NULL DEFAULT CURRENT_DATE,
  view_count INTEGER DEFAULT 1,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(shop_id, user_id, view_date)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_shop_views_shop_id ON shop_views(shop_id);
CREATE INDEX IF NOT EXISTS idx_shop_views_date ON shop_views(view_date);

-- Enable RLS
ALTER TABLE shop_views ENABLE ROW LEVEL SECURITY;

-- Everyone can insert views
CREATE POLICY "Anyone can log views" ON shop_views
  FOR INSERT
  WITH CHECK (true);

-- Shop owners can read their own shop views
CREATE POLICY "Shop owners can read their views" ON shop_views
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM shops 
      WHERE shops.id = shop_id 
      AND shops.owner_id = auth.uid()
    )
  );

-- 8. Shop view statistics aggregation
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

-- Grant select permission on the view
GRANT SELECT ON shop_view_stats TO authenticated;

-- 9. Create a function to increment shop views
CREATE OR REPLACE FUNCTION increment_shop_view(p_shop_id UUID)
RETURNS void AS $$
BEGIN
  INSERT INTO shop_views (shop_id, user_id, view_date, view_count)
  VALUES (p_shop_id, auth.uid(), CURRENT_DATE, 1)
  ON CONFLICT (shop_id, user_id, view_date)
  DO UPDATE SET view_count = shop_views.view_count + 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION increment_shop_view TO authenticated;

-- Migration completion message
DO $$
BEGIN
  RAISE NOTICE 'Shop Manager Phase 1 schema migration completed successfully';
END $$;