-- ============================================================
-- SwiftMart — Fix: Grant coupons read access to all roles
-- Run this in Supabase SQL Editor if coupons aren't loading
-- ============================================================

-- Drop the old restrictive policy
DROP POLICY IF EXISTS "Anyone can read active coupons" ON coupons;

-- Re-create with explicit role grants for anon + authenticated
CREATE POLICY "anon can read active coupons"
  ON coupons FOR SELECT
  TO anon
  USING (is_active = true);

CREATE POLICY "authenticated can read active coupons"
  ON coupons FOR SELECT
  TO authenticated
  USING (is_active = true);

-- Also ensure the schema is accessible
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON coupons TO anon, authenticated;

-- Verify: check coupons exist
SELECT id, code, discount_type, discount_value, is_active, valid_to 
FROM coupons 
WHERE is_active = true 
  AND valid_to > now();
