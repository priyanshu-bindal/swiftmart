-- Exhaustive RLS Override for SwiftMart Admin Dashboard
-- This forces SELECT, INSERT, UPDATE, DELETE permissions for the 'authenticated' role across ALL tables.
-- Run this completely.

DO $$ 
DECLARE
    t text;
BEGIN
    FOR t IN 
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
          AND table_name IN ('products', 'categories', 'orders', 'order_items', 'coupons', 'flash_deals', 'banners', 'profiles')
    LOOP
        -- Enable RLS
        EXECUTE format('ALTER TABLE "public".%I ENABLE ROW LEVEL SECURITY', t);
        
        -- Drop ALL existing policies for the table (clears confusing overlap)
        DECLARE
            pol RECORD;
        BEGIN
            FOR pol IN SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = t
            LOOP
                EXECUTE format('DROP POLICY IF EXISTS %I ON "public".%I', pol.policyname, t);
            END LOOP;
        END;

        -- Create master admin fallback policies for authenticated users
        EXECUTE format('CREATE POLICY "Master SELECT" ON "public".%I FOR SELECT TO authenticated USING (true)', t);
        EXECUTE format('CREATE POLICY "Master INSERT" ON "public".%I FOR INSERT TO authenticated WITH CHECK (true)', t);
        EXECUTE format('CREATE POLICY "Master UPDATE" ON "public".%I FOR UPDATE TO authenticated USING (true) WITH CHECK (true)', t);
        EXECUTE format('CREATE POLICY "Master DELETE" ON "public".%I FOR DELETE TO authenticated USING (true)', t);
        
        RAISE NOTICE 'Reset RLS on %', t;
    END LOOP;
END $$;
