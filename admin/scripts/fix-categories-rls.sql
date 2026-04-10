-- ============================================================
-- Fix RLS policies for categories and banners tables
-- Run this in your Supabase SQL Editor
-- ============================================================

-- ── CATEGORIES ───────────────────────────────────────────────

-- Allow anyone to read categories (public read)
DROP POLICY IF EXISTS "Public can read categories" ON categories;
CREATE POLICY "Public can read categories"
  ON categories FOR SELECT
  USING (true);

-- Allow authenticated users to insert categories
DROP POLICY IF EXISTS "Authenticated users can insert categories" ON categories;
CREATE POLICY "Authenticated users can insert categories"
  ON categories FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Allow authenticated users to update categories
DROP POLICY IF EXISTS "Authenticated users can update categories" ON categories;
CREATE POLICY "Authenticated users can update categories"
  ON categories FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Allow authenticated users to delete categories
DROP POLICY IF EXISTS "Authenticated users can delete categories" ON categories;
CREATE POLICY "Authenticated users can delete categories"
  ON categories FOR DELETE
  TO authenticated
  USING (true);

-- ── BANNERS ──────────────────────────────────────────────────

-- Allow anyone to read banners (public read)
DROP POLICY IF EXISTS "Public can read banners" ON banners;
CREATE POLICY "Public can read banners"
  ON banners FOR SELECT
  USING (true);

-- Allow authenticated users to insert banners
DROP POLICY IF EXISTS "Authenticated users can insert banners" ON banners;
CREATE POLICY "Authenticated users can insert banners"
  ON banners FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Allow authenticated users to update banners
DROP POLICY IF EXISTS "Authenticated users can update banners" ON banners;
CREATE POLICY "Authenticated users can update banners"
  ON banners FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Allow authenticated users to delete banners
DROP POLICY IF EXISTS "Authenticated users can delete banners" ON banners;
CREATE POLICY "Authenticated users can delete banners"
  ON banners FOR DELETE
  TO authenticated
  USING (true);

-- ── PRODUCTS ─────────────────────────────────────────────────
-- (In case products also has this issue)

DROP POLICY IF EXISTS "Public can read products" ON products;
CREATE POLICY "Public can read products"
  ON products FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Authenticated users can insert products" ON products;
CREATE POLICY "Authenticated users can insert products"
  ON products FOR INSERT
  TO authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS "Authenticated users can update products" ON products;
CREATE POLICY "Authenticated users can update products"
  ON products FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

DROP POLICY IF EXISTS "Authenticated users can delete products" ON products;
CREATE POLICY "Authenticated users can delete products"
  ON products FOR DELETE
  TO authenticated
  USING (true);
