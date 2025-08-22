-- Events 테이블 생성
CREATE TABLE IF NOT EXISTS public.events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    shop_id UUID NOT NULL REFERENCES public.shops(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    event_type VARCHAR(50) NOT NULL DEFAULT 'special',
    image_url TEXT,
    banner_url TEXT,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT true,
    is_featured BOOLEAN DEFAULT false,
    discount_rate VARCHAR(50),
    promo_code VARCHAR(50),
    target_products TEXT,
    terms TEXT,
    priority INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 인덱스 생성
CREATE INDEX idx_events_shop_id ON public.events(shop_id);
CREATE INDEX idx_events_active ON public.events(is_active);
CREATE INDEX idx_events_featured ON public.events(is_featured);
CREATE INDEX idx_events_dates ON public.events(start_date, end_date);

-- RLS 정책
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;

-- 모든 사용자가 활성 이벤트 조회 가능
CREATE POLICY "Public can view active events" ON public.events
    FOR SELECT USING (is_active = true);

-- 상점 소유자는 자신의 이벤트 관리 가능
CREATE POLICY "Shop owners can manage their events" ON public.events
    FOR ALL USING (
        shop_id IN (
            SELECT id FROM public.shops 
            WHERE owner_id = auth.uid()
        )
    );

-- Updated_at 트리거
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER handle_events_updated_at
    BEFORE UPDATE ON public.events
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- 샘플 데이터 (선택사항)
INSERT INTO public.events (shop_id, title, description, event_type, start_date, end_date, is_featured, discount_rate)
SELECT 
    s.id,
    CASE 
        WHEN random() < 0.3 THEN '신규 오픈 기념 세일'
        WHEN random() < 0.6 THEN '시즌 특별 할인'
        ELSE '브랜드 데이'
    END,
    '특별한 혜택을 놓치지 마세요!',
    CASE 
        WHEN random() < 0.3 THEN 'sale'
        WHEN random() < 0.6 THEN 'special'
        ELSE 'season'
    END,
    CURRENT_DATE - INTERVAL '5 days',
    CURRENT_DATE + INTERVAL '10 days',
    random() < 0.3,
    CASE 
        WHEN random() < 0.5 THEN '최대 30% 할인'
        ELSE '최대 50% 할인'
    END
FROM public.shops s
LIMIT 5;