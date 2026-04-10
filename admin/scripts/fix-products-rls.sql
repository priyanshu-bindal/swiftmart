-- Run this in your Supabase Dashboard > SQL Editor
-- Adds RLS policies so authenticated admin users can manage products

-- INSERT policy
CREATE POLICY "Authenticated users can insert products"
ON public.products
FOR INSERT
TO authenticated
WITH CHECK (true);

-- UPDATE policy
CREATE POLICY "Authenticated users can update products"
ON public.products
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- DELETE policy
CREATE POLICY "Authenticated users can delete products"
ON public.products
FOR DELETE
TO authenticated
USING (true);

-- SELECT policy (if not already set)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'products'
    AND policyname = 'Authenticated users can view products'
  ) THEN
    EXECUTE 'CREATE POLICY "Authenticated users can view products"
    ON public.products
    FOR SELECT
    TO authenticated
    USING (true)';
  END IF;
END $$;
