-- Fix RLS Policies for SwiftMart Admin Dashboard
-- This script grants the "authenticated" role full CRUD access to these tables.
-- In a production environment, you should add a check for a specific admin role (e.g. check if profiles.role = 'admin')

-- 1. CATEGORIES
ALTER TABLE "public"."categories" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON "public"."categories";
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON "public"."categories";
DROP POLICY IF EXISTS "Enable update for authenticated users only" ON "public"."categories";
DROP POLICY IF EXISTS "Enable delete for authenticated users only" ON "public"."categories";

CREATE POLICY "Enable read access for authenticated users" ON "public"."categories" FOR SELECT TO authenticated USING (true);
CREATE POLICY "Enable insert for authenticated users only" ON "public"."categories" FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Enable update for authenticated users only" ON "public"."categories" FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Enable delete for authenticated users only" ON "public"."categories" FOR DELETE TO authenticated USING (true);


-- 2. ORDERS
ALTER TABLE "public"."orders" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON "public"."orders";
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON "public"."orders";
DROP POLICY IF EXISTS "Enable update for authenticated users only" ON "public"."orders";
DROP POLICY IF EXISTS "Enable delete for authenticated users only" ON "public"."orders";

CREATE POLICY "Enable read access for authenticated users" ON "public"."orders" FOR SELECT TO authenticated USING (true);
CREATE POLICY "Enable insert for authenticated users only" ON "public"."orders" FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Enable update for authenticated users only" ON "public"."orders" FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Enable delete for authenticated users only" ON "public"."orders" FOR DELETE TO authenticated USING (true);


-- 3. COUPONS
ALTER TABLE "public"."coupons" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON "public"."coupons";
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON "public"."coupons";
DROP POLICY IF EXISTS "Enable update for authenticated users only" ON "public"."coupons";
DROP POLICY IF EXISTS "Enable delete for authenticated users only" ON "public"."coupons";

CREATE POLICY "Enable read access for authenticated users" ON "public"."coupons" FOR SELECT TO authenticated USING (true);
CREATE POLICY "Enable insert for authenticated users only" ON "public"."coupons" FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Enable update for authenticated users only" ON "public"."coupons" FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Enable delete for authenticated users only" ON "public"."coupons" FOR DELETE TO authenticated USING (true);


-- 4. FLASH DEALS
ALTER TABLE "public"."flash_deals" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON "public"."flash_deals";
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON "public"."flash_deals";
DROP POLICY IF EXISTS "Enable update for authenticated users only" ON "public"."flash_deals";
DROP POLICY IF EXISTS "Enable delete for authenticated users only" ON "public"."flash_deals";

CREATE POLICY "Enable read access for authenticated users" ON "public"."flash_deals" FOR SELECT TO authenticated USING (true);
CREATE POLICY "Enable insert for authenticated users only" ON "public"."flash_deals" FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Enable update for authenticated users only" ON "public"."flash_deals" FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Enable delete for authenticated users only" ON "public"."flash_deals" FOR DELETE TO authenticated USING (true);


-- 5. BANNERS
ALTER TABLE "public"."banners" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON "public"."banners";
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON "public"."banners";
DROP POLICY IF EXISTS "Enable update for authenticated users only" ON "public"."banners";
DROP POLICY IF EXISTS "Enable delete for authenticated users only" ON "public"."banners";

CREATE POLICY "Enable read access for authenticated users" ON "public"."banners" FOR SELECT TO authenticated USING (true);
CREATE POLICY "Enable insert for authenticated users only" ON "public"."banners" FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Enable update for authenticated users only" ON "public"."banners" FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Enable delete for authenticated users only" ON "public"."banners" FOR DELETE TO authenticated USING (true);


-- 6. PROFILES (Note: They might already have a restrictive policy for self-edit)
ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admins can update any profile" ON "public"."profiles";
DROP POLICY IF EXISTS "Admins can delete profiles" ON "public"."profiles";

CREATE POLICY "Admins can update any profile" ON "public"."profiles" FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Admins can delete profiles" ON "public"."profiles" FOR DELETE TO authenticated USING (true);
