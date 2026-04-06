-- ============================================================
-- SwiftMart — Coupons & Addresses Tables
-- Run this in your Supabase SQL Editor
-- ============================================================

-- 1. DROP existing tables if they exist (dev environment only!)
DROP TABLE IF EXISTS coupons CASCADE;
DROP TABLE IF EXISTS addresses CASCADE;

-- 2. CREATE coupons table
CREATE TABLE coupons (
  id            UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  code          TEXT NOT NULL UNIQUE,
  description   TEXT NOT NULL DEFAULT '',
  terms         TEXT NOT NULL DEFAULT '',
  discount_type TEXT NOT NULL DEFAULT 'flat' CHECK (discount_type IN ('percentage', 'flat', 'free_delivery')),
  discount_value NUMERIC(10,2) NOT NULL DEFAULT 0,
  min_order_value NUMERIC(10,2) NOT NULL DEFAULT 0,
  max_discount  NUMERIC(10,2) NOT NULL DEFAULT 0,
  valid_from    TIMESTAMPTZ NOT NULL DEFAULT now(),
  valid_to      TIMESTAMPTZ NOT NULL DEFAULT (now() + INTERVAL '30 days'),
  is_active     BOOLEAN NOT NULL DEFAULT true,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. CREATE addresses table
CREATE TABLE addresses (
  id            UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id       TEXT NOT NULL,
  label         TEXT NOT NULL DEFAULT 'Home' CHECK (label IN ('Home', 'Work', 'Other')),
  flat_no       TEXT NOT NULL DEFAULT '',
  floor         TEXT,
  building_name TEXT NOT NULL DEFAULT '',
  area          TEXT NOT NULL DEFAULT '',
  landmark      TEXT,
  full_address  TEXT NOT NULL DEFAULT '',
  lat           DOUBLE PRECISION,
  lng           DOUBLE PRECISION,
  is_default    BOOLEAN NOT NULL DEFAULT false,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index for fast lookups
CREATE INDEX idx_addresses_user_id ON addresses(user_id);

-- 4. Enable RLS (Row Level Security)
ALTER TABLE coupons ENABLE ROW LEVEL SECURITY;
ALTER TABLE addresses ENABLE ROW LEVEL SECURITY;

-- Coupons: both anon and authenticated users can read active coupons
CREATE POLICY "anon can read active coupons"
  ON coupons FOR SELECT
  TO anon
  USING (is_active = true);

CREATE POLICY "authenticated can read active coupons"
  ON coupons FOR SELECT
  TO authenticated
  USING (is_active = true);

-- Grant schema + table access
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON coupons TO anon, authenticated;
GRANT ALL ON addresses TO authenticated;

-- Addresses: users can only see/manage their own addresses
CREATE POLICY "Users can read own addresses"
  ON addresses FOR SELECT
  USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert own addresses"
  ON addresses FOR INSERT
  WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update own addresses"
  ON addresses FOR UPDATE
  USING (auth.uid()::text = user_id);

CREATE POLICY "Users can delete own addresses"
  ON addresses FOR DELETE
  USING (auth.uid()::text = user_id);

-- ============================================================
-- 5. SEED DATA — Coupons
-- ============================================================

INSERT INTO coupons (code, description, terms, discount_type, discount_value, min_order_value, max_discount, valid_from, valid_to, is_active)
VALUES
  (
    'SAVE50',
    'Get 50% OFF on your first order',
    'Valid for orders above ₹200. Max discount ₹150.',
    'percentage',
    50,
    200,
    150,
    now(),
    now() + INTERVAL '60 days',
    true
  ),
  (
    'FREESHIP',
    'No delivery fee on your order',
    'Applicable on all orders above ₹100.',
    'free_delivery',
    40,
    100,
    40,
    now(),
    now() + INTERVAL '90 days',
    true
  ),
  (
    'FRESH20',
    'Flat ₹20 off on fresh produce',
    'Valid on fruits & vegetables category. Min order ₹150.',
    'flat',
    20,
    150,
    20,
    now(),
    now() + INTERVAL '30 days',
    true
  ),
  (
    'WELCOME100',
    'Flat ₹100 off for new users',
    'Valid for first-time orders only. Min order ₹500.',
    'flat',
    100,
    500,
    100,
    now(),
    now() + INTERVAL '45 days',
    true
  );

-- ============================================================
-- 6. SEED DATA — Addresses (placeholder user_id — replace with your real UID)
-- After login, run this with your actual user_id:
--   UPDATE addresses SET user_id = 'YOUR_ACTUAL_UID';
-- ============================================================

-- NOTE: Replace 'PLACEHOLDER_UID' with your real Supabase auth UID
-- You can find it via: SELECT id FROM auth.users LIMIT 1;

-- INSERT INTO addresses (user_id, label, flat_no, floor, building_name, area, landmark, full_address, is_default)
-- VALUES
--   ('PLACEHOLDER_UID', 'Home', '402', '4th Floor', 'Sapphire Apartments', 'Skyline Boulevard, Silicon Valley', 'Opposite Central Park', '402, 4th Floor, Sapphire Apartments, Skyline Boulevard, Silicon Valley', true),
--   ('PLACEHOLDER_UID', 'Work', 'Suite 500', '5th Floor', 'Tech Park East', 'Innovation Way, CA 94043', 'Near Metro Station', 'Suite 500, 5th Floor, Tech Park East, Innovation Way, CA 94043', false),
--   ('PLACEHOLDER_UID', 'Other', '101', 'Ground Floor', 'Central Library', '5th Ave, CA 94085', '', '101, Ground Floor, Central Library, 5th Ave, CA 94085', false);
