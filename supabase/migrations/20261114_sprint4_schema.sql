-- ============================================================================
-- Ter The Cut Barbershop - Migration Script: Sprint 4
-- Modules: Feedback, Segmented Promos CRUD, In-App Notifications
-- Target Remote Database: tdbetcjkqeihudihsjlq.supabase.co
-- ============================================================================

-- 1. Table & Columns: Promos (Promo Berbasis Segmen Tier & Admin CRUD)
CREATE TABLE IF NOT EXISTS public.promos (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    discount_percent INT NOT NULL DEFAULT 10,
    target_tier TEXT NOT NULL DEFAULT 'all', -- 'all', 'silver', 'gold', 'platinum'
    start_date TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    end_date TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now() + interval '30 days'),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Upgrade existing promos table if it was created earlier
ALTER TABLE public.promos ADD COLUMN IF NOT EXISTS discount_percent INT NOT NULL DEFAULT 10;
ALTER TABLE public.promos ADD COLUMN IF NOT EXISTS target_tier TEXT NOT NULL DEFAULT 'all';
ALTER TABLE public.promos ADD COLUMN IF NOT EXISTS start_date TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now());
ALTER TABLE public.promos ADD COLUMN IF NOT EXISTS end_date TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now() + interval '30 days');
ALTER TABLE public.promos ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT true;

-- Index for querying active promotions
CREATE INDEX IF NOT EXISTS idx_promos_tier_active ON public.promos (target_tier, is_active, start_date);

-- 2. Table & Columns: Feedbacks (Kritik & Saran Pelanggan & Read-Only Admin)
CREATE TABLE IF NOT EXISTS public.feedbacks (
    id TEXT PRIMARY KEY,
    customer_id TEXT,
    user_id TEXT,
    user_name TEXT NOT NULL DEFAULT 'Pelanggan Ter The Cut',
    user_phone TEXT,
    category TEXT NOT NULL DEFAULT 'Pelayanan',
    rating INT DEFAULT 5,
    message TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Upgrade existing feedbacks table
ALTER TABLE public.feedbacks ADD COLUMN IF NOT EXISTS user_id TEXT;
ALTER TABLE public.feedbacks ADD COLUMN IF NOT EXISTS user_name TEXT NOT NULL DEFAULT 'Pelanggan Ter The Cut';
ALTER TABLE public.feedbacks ADD COLUMN IF NOT EXISTS user_phone TEXT;
ALTER TABLE public.feedbacks ADD COLUMN IF NOT EXISTS category TEXT NOT NULL DEFAULT 'Pelayanan';
ALTER TABLE public.feedbacks ADD COLUMN IF NOT EXISTS rating INT DEFAULT 5;
ALTER TABLE public.feedbacks ALTER COLUMN customer_id DROP NOT NULL;

-- Index for sorting feedback by recency
CREATE INDEX IF NOT EXISTS idx_feedbacks_created_at ON public.feedbacks (created_at DESC);

-- 3. Table & Columns: Notifications (In-App Notification Center)
CREATE TABLE IF NOT EXISTS public.notifications (
    id TEXT PRIMARY KEY,
    customer_id TEXT,
    user_id TEXT,
    title TEXT NOT NULL,
    message TEXT,
    body TEXT,
    type TEXT NOT NULL DEFAULT 'general', -- 'booking', 'points', 'reward', 'general'
    is_read BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Upgrade existing notifications table
ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS user_id TEXT;
ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS message TEXT;
ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS type TEXT NOT NULL DEFAULT 'general';

-- Index for user notifications
CREATE INDEX IF NOT EXISTS idx_notifications_customer_id ON public.notifications (customer_id, created_at DESC);

-- 4. Enable Row Level Security (RLS) & Policies
ALTER TABLE public.promos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feedbacks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    -- Policy for promos (Read, Insert, Update, Delete for all clients)
    DROP POLICY IF EXISTS "Allow all operations on promos" ON public.promos;
    CREATE POLICY "Allow all operations on promos" ON public.promos FOR ALL USING (true) WITH CHECK (true);

    -- Policy for feedbacks
    DROP POLICY IF EXISTS "Allow all operations on feedbacks" ON public.feedbacks;
    CREATE POLICY "Allow all operations on feedbacks" ON public.feedbacks FOR ALL USING (true) WITH CHECK (true);

    -- Policy for notifications
    DROP POLICY IF EXISTS "Allow all operations on notifications" ON public.notifications;
    CREATE POLICY "Allow all operations on notifications" ON public.notifications FOR ALL USING (true) WITH CHECK (true);
END $$;
