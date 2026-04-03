-- ============================================================
-- SwiftMart Database Schema
-- Includes users, products, orders, cart, and SDUI configs
-- Run this in the Supabase SQL Editor
-- ============================================================

-- 1. Create users table (Keep existing)
CREATE TABLE IF NOT EXISTS public.users (
  id          UUID        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email       TEXT,
  name        TEXT,
  avatar_url  TEXT,
  fcm_token   TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Enable Row Level Security (Keep existing)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- 3. RLS policies for users (Keep existing)
CREATE POLICY "Users can view their own row"
  ON public.users FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can insert their own row"
  ON public.users FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own row"
  ON public.users FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- 4. Auto-create user row on signup (trigger) (Keep existing)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.users (id, email, name, avatar_url)
  VALUES (
    new.id,
    new.email,
    COALESCE(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
    new.raw_user_meta_data->>'avatar_url'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop old trigger if it exists, then recreate
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- ============================================================
-- NEW TABLES (E-commerce Core)
-- ============================================================

-- 5. Categories
CREATE TABLE public.categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  icon_url text,
  color_hex text,
  sort_order int DEFAULT 0,
  is_active bool DEFAULT true
);

-- 6. Products
CREATE TABLE public.products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  price numeric NOT NULL,
  mrp numeric,
  unit text,
  stock_qty int DEFAULT 0,
  category_id uuid REFERENCES public.categories(id) ON DELETE SET NULL,
  image_url text,
  is_active bool DEFAULT true,
  is_featured bool DEFAULT false,
  tags text[]
);

-- 7. Cart Items
CREATE TABLE public.cart_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  quantity int NOT NULL CHECK (quantity > 0),
  created_at timestamptz DEFAULT NOW()
);

-- 8. Orders
CREATE TABLE public.orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  status text NOT NULL CHECK (status IN ('placed','confirmed','packed','out_for_delivery','delivered','cancelled')) DEFAULT 'placed',
  subtotal numeric NOT NULL,
  discount numeric DEFAULT 0,
  total numeric NOT NULL,
  delivery_address jsonb NOT NULL,
  coupon_code text,
  created_at timestamptz DEFAULT NOW()
);

-- 9. Order Items
CREATE TABLE public.order_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE RESTRICT,
  quantity int NOT NULL CHECK (quantity > 0),
  price_at_purchase numeric NOT NULL
);

-- 10. Coupons
CREATE TABLE public.coupons (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text UNIQUE NOT NULL,
  discount_type text NOT NULL CHECK (discount_type IN ('flat','percent')),
  discount_value numeric NOT NULL,
  min_order_value numeric DEFAULT 0,
  max_uses int,
  used_count int DEFAULT 0,
  valid_until timestamptz,
  is_active bool DEFAULT true
);

-- 11. Flash Deals
CREATE TABLE public.flash_deals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  discount_percent numeric NOT NULL,
  start_time timestamptz NOT NULL,
  end_time timestamptz NOT NULL,
  max_qty int,
  sold_qty int DEFAULT 0,
  is_active bool DEFAULT true
);

-- 12. Banners
CREATE TABLE public.banners (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  image_url text NOT NULL,
  cta_url text,
  display_order int DEFAULT 0,
  is_active bool DEFAULT true,
  starts_at timestamptz,
  ends_at timestamptz
);

-- 13. Home Config (SDUI)
CREATE TABLE public.home_config (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  config jsonb NOT NULL,
  is_active bool DEFAULT true,
  updated_at timestamptz DEFAULT NOW()
);

-- 14. User FCM Tokens
CREATE TABLE public.user_fcm_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  token text NOT NULL,
  platform text,
  updated_at timestamptz DEFAULT NOW()
);

-- ============================================================
-- RLS POLICIES
-- ============================================================

-- Enable RLS
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coupons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.flash_deals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.banners ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.home_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_fcm_tokens ENABLE ROW LEVEL SECURITY;


-- Public read policies (is_active = true)
CREATE POLICY "Public read active categories" ON public.categories FOR SELECT USING (is_active = true);
CREATE POLICY "Public read active products" ON public.products FOR SELECT USING (is_active = true);
CREATE POLICY "Public read active flash deals" ON public.flash_deals FOR SELECT USING (is_active = true);
CREATE POLICY "Public read active banners" ON public.banners FOR SELECT USING (is_active = true);
CREATE POLICY "Public read active home config" ON public.home_config FOR SELECT USING (is_active = true);

-- Authenticated read/write for user's own items
CREATE POLICY "Users manage own cart items" ON public.cart_items FOR ALL TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Users manage own orders" ON public.orders FOR ALL TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Users manage own order items" ON public.order_items FOR ALL TO authenticated USING (
  EXISTS (SELECT 1 FROM public.orders WHERE id = order_items.order_id AND user_id = auth.uid())
);
CREATE POLICY "Users manage own fcm tokens" ON public.user_fcm_tokens FOR ALL TO authenticated USING (auth.uid() = user_id);

-- Authenticated read for active coupons
CREATE POLICY "Authenticated read on active coupons" ON public.coupons FOR SELECT TO authenticated USING (is_active = true);

-- Note: Service role has bypass RLS privileges by default for backend operations.
