-- ============================================================
-- SwiftMart — Orders & Order Items Tables
-- Run in Supabase SQL Editor
-- ============================================================

-- Drop existing (dev only)
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;

-- Orders table
CREATE TABLE orders (
  id               UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id          TEXT NOT NULL,
  status           TEXT NOT NULL DEFAULT 'CONFIRMED'
                   CHECK (status IN ('CONFIRMED','PREPARING','OUT_FOR_DELIVERY','DELIVERED','CANCELLED')),
  subtotal         NUMERIC(12,2) NOT NULL DEFAULT 0,
  delivery_fee     NUMERIC(12,2) NOT NULL DEFAULT 40,
  discount_amount  NUMERIC(12,2) NOT NULL DEFAULT 0,
  total            NUMERIC(12,2) NOT NULL DEFAULT 0,
  coupon_code      TEXT,
  payment_method   TEXT NOT NULL DEFAULT 'cod',
  address_id       UUID REFERENCES addresses(id) ON DELETE SET NULL,
  delivery_address JSONB,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Order items table
CREATE TABLE order_items (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  order_id    UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id  UUID NOT NULL,
  name        TEXT NOT NULL DEFAULT '',
  image_url   TEXT,
  unit        TEXT,
  quantity    INT NOT NULL DEFAULT 1,
  unit_price  NUMERIC(12,2) NOT NULL DEFAULT 0,
  total_price NUMERIC(12,2) NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_created_at ON orders(created_at DESC);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);

-- RLS
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

-- Policies: orders
CREATE POLICY "Users can read own orders"
  ON orders FOR SELECT TO authenticated
  USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert own orders"
  ON orders FOR INSERT TO authenticated
  WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update own orders"
  ON orders FOR UPDATE TO authenticated
  USING (auth.uid()::text = user_id);

-- Policies: order_items (via order ownership)
CREATE POLICY "Users can read own order items"
  ON order_items FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_items.order_id
        AND orders.user_id = auth.uid()::text
    )
  );

CREATE POLICY "Users can insert own order items"
  ON order_items FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_items.order_id
        AND orders.user_id = auth.uid()::text
    )
  );

-- Grants
GRANT ALL ON orders TO authenticated;
GRANT ALL ON order_items TO authenticated;

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER orders_updated_at
  BEFORE UPDATE ON orders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Enable Realtime for live status updates
ALTER PUBLICATION supabase_realtime ADD TABLE orders;
