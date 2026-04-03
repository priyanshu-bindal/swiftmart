-- ============================================================
-- SwiftMart Seed Data
-- ============================================================

-- 1. Categories (8 categories)
INSERT INTO public.categories (id, name, icon_url, color_hex, sort_order, is_active) VALUES
  ('c1000000-0000-0000-0000-000000000000', 'Fruits', 'https://cdn-icons-png.flaticon.com/512/3194/3194591.png', '#FFEBEE', 1, true),
  ('c2000000-0000-0000-0000-000000000000', 'Vegetables', 'https://cdn-icons-png.flaticon.com/512/2153/2153788.png', '#E8F5E9', 2, true),
  ('c3000000-0000-0000-0000-000000000000', 'Dairy', 'https://cdn-icons-png.flaticon.com/512/3014/3014496.png', '#E3F2FD', 3, true),
  ('c4000000-0000-0000-0000-000000000000', 'Snacks', 'https://cdn-icons-png.flaticon.com/512/2515/2515150.png', '#FFF3E0', 4, true),
  ('c5000000-0000-0000-0000-000000000000', 'Beverages', 'https://cdn-icons-png.flaticon.com/512/3014/3014458.png', '#F3E5F5', 5, true),
  ('c6000000-0000-0000-0000-000000000000', 'Bakery', 'https://cdn-icons-png.flaticon.com/512/3014/3014408.png', '#FFF8E1', 6, true),
  ('c7000000-0000-0000-0000-000000000000', 'Meat', 'https://cdn-icons-png.flaticon.com/512/3194/3194595.png', '#FFEBEE', 7, true),
  ('c8000000-0000-0000-0000-000000000000', 'Personal Care', 'https://cdn-icons-png.flaticon.com/512/3014/3014467.png', '#E0F7FA', 8, true)
ON CONFLICT (id) DO NOTHING;

-- 2. Products (5 for each category, total 40)
INSERT INTO public.products (id, name, description, price, mrp, unit, stock_qty, category_id, image_url, is_active, is_featured, tags) VALUES
  -- Fruits
  ('p1000000-0000-0000-0000-000000000001', 'Banana Robusta', 'Fresh bananas', 52.00, 60.00, '6 pcs', 50, 'c1000000-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1603833665858-e61d17a86224?w=500&q=80', true, true, ARRAY['fruit', 'fresh']),
  ('p1000000-0000-0000-0000-000000000002', 'Apple Royal Gala', 'Crunchy fresh apples imported', 140.00, 180.00, '4 pcs', 40, 'c1000000-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1570913149827-d2ac84ab3f9a?w=500&q=80', true, false, ARRAY['fruit', 'apple']),
  ('p1000000-0000-0000-0000-000000000003', 'Papaya Semi Ripe', 'Sweet semi ripe papaya', 65.00, 80.00, '1 pc', 30, 'c1000000-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1617112848504-bd5786f1e56b?w=500&q=80', true, false, ARRAY['fruit']),
  ('p1000000-0000-0000-0000-000000000004', 'Watermelon Kiran', 'Sweet and juicy watermelon', 85.00, 110.00, '1 pc (2-3 kg)', 20, 'c1000000-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1581084224058-29e2d534f3fb?w=500&q=80', true, false, ARRAY['fruit', 'summer']),
  ('p1000000-0000-0000-0000-000000000005', 'Grapes Green Seedless', 'Sweet green seedless grapes', 90.00, 120.00, '500g', 35, 'c1000000-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1599818815124-7ef2662c76ae?w=500&q=80', true, true, ARRAY['fruit']),

  -- Vegetables
  ('p2000000-0000-0000-0000-000000000001', 'Fresh Onion (Pyaz)', 'Local fresh onions', 35.00, 50.00, '1 kg', 100, 'c2000000-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1620574387735-364701ea11c4?w=500&q=80', true, true, ARRAY['veg', 'essential']),
  ('p2000000-0000-0000-0000-000000000002', 'Tomato Hybrid', 'Red ripe tomatoes', 45.00, 60.00, '500g', 80, 'c2000000-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1561136594-7f68413baa99?w=500&q=80', true, false, ARRAY['veg', 'essential']),
  ('p2000000-0000-0000-0000-000000000003', 'Potato (Aloo)', 'Regular potatoes', 30.00, 45.00, '1 kg', 150, 'c2000000-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1518977676601-2e6b01ec3cb6?w=500&q=80', true, false, ARRAY['veg', 'essential']),
  ('p2000000-0000-0000-0000-000000000004', 'Capsicum Green', 'Fresh green capsicum', 50.00, 70.00, '500g', 40, 'c2000000-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1600277388708-34fa12411add?w=500&q=80', true, false, ARRAY['veg', 'fresh']),
  ('p2000000-0000-0000-0000-000000000005', 'Carrot Orange', 'Fresh roots carrots', 60.00, 80.00, '1 kg', 60, 'c2000000-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?w=500&q=80', true, false, ARRAY['veg', 'salad']),

  -- Dairy
  ('p3000000-0000-0000-0000-000000000001', 'Amul Taaza Toned Milk', 'UHT pasteurized milk', 72.00, 72.00, '1L', 200, 'c3000000-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=500&q=80', true, true, ARRAY['dairy', 'milk']),
  ('p3000000-0000-0000-0000-000000000002', 'Amul Butter Pasteurized', 'Classic salted butter', 58.00, 60.00, '100g', 120, 'c3000000-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1589985270826-4b7bb135f272?w=500&q=80', true, false, ARRAY['dairy', 'butter']),
  ('p3000000-0000-0000-0000-000000000003', 'Mother Dairy Classic Curd', 'Thick curd set naturally', 35.00, 35.00, '400g', 60, 'c3000000-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1563514264669-0ebbe51ccca3?w=500&q=80', true, false, ARRAY['dairy', 'curd']),
  ('p3000000-0000-0000-0000-000000000004', 'Amul Cheese Slices', 'Processed cheese slices', 140.00, 150.00, '200g', 50, 'c3000000-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1486297678162-eb2a19b0a32d?w=500&q=80', true, false, ARRAY['dairy', 'cheese']),
  ('p3000000-0000-0000-0000-000000000005', 'Milky Mist Paneer', 'Fresh malai paneer', 85.00, 95.00, '200g', 75, 'c3000000-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1629824635951-692b1574bc6f?w=500&q=80', true, true, ARRAY['dairy', 'paneer']),

  -- Snacks
  ('p4000000-0000-0000-0000-000000000001', 'Lay''s India''s Magic Masala', 'Crispy potato chips', 20.00, 20.00, '50g', 250, 'c4000000-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1566478989037-eade3f7e3ba9?w=500&q=80', true, true, ARRAY['snack', 'chips']),
  ('p4000000-0000-0000-0000-000000000002', 'Haldiram''s Bhujia Sev', 'Crispy chickpea flour noodles', 105.00, 110.00, '400g', 150, 'c4000000-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1626082929543-6df5992a543e?w=500&q=80', true, false, ARRAY['snack', 'namkeen']),
  ('p4000000-0000-0000-0000-000000000003', 'Kurkure Masala Munch', 'Spicy corn puffs', 20.00, 20.00, '90g', 200, 'c4000000-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1599508704512-2f19efd1e35f?w=500&q=80', true, false, ARRAY['snack', 'chips']),
  ('p4000000-0000-0000-0000-000000000004', 'Doritos Cheese Nachos', 'Cheesy tortilla chips', 45.00, 50.00, '90g', 120, 'c4000000-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1629367448834-58e17b8f9e68?w=500&q=80', true, false, ARRAY['snack', 'nachos']),
  ('p4000000-0000-0000-0000-000000000005', 'Bikano Aloo Bhujia', 'Spicy potato snack', 90.00, 100.00, '400g', 100, 'c4000000-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1604908177453-7462950a6a3b?w=500&q=80', true, false, ARRAY['snack', 'namkeen']),

  -- Beverages
  ('p5000000-0000-0000-0000-000000000001', 'Coca-Cola Original', 'Carbonated soft drink', 40.00, 40.00, '750ml', 150, 'c5000000-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=500&q=80', true, true, ARRAY['beverage', 'cold drink']),
  ('p5000000-0000-0000-0000-000000000002', 'Sprite Lemon Lime', 'Clear lemon-lime soda', 40.00, 40.00, '750ml', 140, 'c5000000-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1624517452488-04869289c4ca?w=500&q=80', true, false, ARRAY['beverage', 'cold drink']),
  ('p5000000-0000-0000-0000-000000000003', 'Red Bull Energy Drink', 'Energy drink cans', 115.00, 125.00, '250ml', 80, 'c5000000-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1634027732976-13a8934dfde2?w=500&q=80', true, false, ARRAY['beverage', 'energy']),
  ('p5000000-0000-0000-0000-000000000004', 'Tata Tea Premium', 'Desh ki chai', 245.00, 280.00, '500g', 100, 'c5000000-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1594631252845-29fc4cc8c0a1?w=500&q=80', true, false, ARRAY['beverage', 'tea']),
  ('p5000000-0000-0000-0000-000000000005', 'Nescafe Classic Coffee', '100% pure coffee', 310.00, 340.00, '100g', 60, 'c5000000-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1559525839-b184a4d698c7?w=500&q=80', true, true, ARRAY['beverage', 'coffee']),

  -- Bakery
  ('p6000000-0000-0000-0000-000000000001', 'Britannia White Bread', 'Soft daily white bread', 45.00, 50.00, '400g', 50, 'c6000000-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1598373182133-52452f7691ef?w=500&q=80', true, true, ARRAY['bakery', 'bread']),
  ('p6000000-0000-0000-0000-000000000002', 'Britannia Good Day Cookies', 'Butter cookies', 32.00, 35.00, '200g', 200, 'c6000000-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1499636136210-6f4ee915583e?w=500&q=80', true, false, ARRAY['bakery', 'cookies']),
  ('p6000000-0000-0000-0000-000000000003', 'Parle-G Gluco Biscuits', 'Original glucose biscuits', 10.00, 10.00, '130g', 300, 'c6000000-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=500&q=80', true, false, ARRAY['bakery', 'biscuits']),
  ('p6000000-0000-0000-0000-000000000004', 'English Oven Burger Buns', 'Soft sesame burger buns', 35.00, 40.00, '4 pcs', 40, 'c6000000-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1509358271058-acd26ccafdb6?w=500&q=80', true, false, ARRAY['bakery', 'bun']),
  ('p6000000-0000-0000-0000-000000000005', 'Kwality Dry Fruit Cake', 'Plum and dry fruit cake', 150.00, 180.00, '350g', 30, 'c6000000-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1542826438-bd32f43d626f?w=500&q=80', true, false, ARRAY['bakery', 'cake']),

  -- Meat
  ('p7000000-0000-0000-0000-000000000001', 'Fresh Chicken Curry Cut', 'Tender halal chicken cuts', 240.00, 280.00, '500g', 40, 'c7000000-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1604503468506-a8da13fcdd90?w=500&q=80', true, true, ARRAY['meat', 'chicken']),
  ('p7000000-0000-0000-0000-000000000002', 'Chicken Mince (Kheema)', 'Lean chicken mince', 260.00, 290.00, '450g', 30, 'c7000000-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1588168333986-5078d3ae3976?w=500&q=80', true, false, ARRAY['meat', 'chicken']),
  ('p7000000-0000-0000-0000-000000000003', 'Mutton Curry Cut Raan', 'Premium goat meat', 650.00, 720.00, '500g', 20, 'c7000000-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1603048297172-c92544798d5e?w=500&q=80', true, false, ARRAY['meat', 'mutton']),
  ('p7000000-0000-0000-0000-000000000004', 'Farm Fresh White Eggs', 'Healthy white eggs', 84.00, 95.00, '12 pcs', 150, 'c7000000-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1587486913049-53fc88980cfc?w=500&q=80', true, true, ARRAY['meat', 'eggs']),
  ('p7000000-0000-0000-0000-000000000005', 'Rohu Fish Steaks', 'Fresh river fish steaks', 320.00, 380.00, '500g', 25, 'c7000000-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1615141982883-c7ad0e69fd62?w=500&q=80', true, false, ARRAY['meat', 'fish']),

  -- Personal Care
  ('p8000000-0000-0000-0000-000000000001', 'Dove Cream Beauty Bar', 'Moisturizing soap', 199.00, 230.00, '3x100g', 80, 'c8000000-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1600857062241-98e5dba7f214?w=500&q=80', true, true, ARRAY['care', 'soap']),
  ('p8000000-0000-0000-0000-000000000002', 'Colgate Strong Teeth', 'Calcium toothpaste', 99.00, 110.00, '200g', 120, 'c8000000-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1559598467-f8b76c8155d0?w=500&q=80', true, false, ARRAY['care', 'oral']),
  ('p8000000-0000-0000-0000-000000000003', 'Sunsilk Black Shine', 'Glossy hair shampoo', 280.00, 350.00, '650ml', 60, 'c8000000-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1631730486828-5e921eafbc97?w=500&q=80', true, false, ARRAY['care', 'hair']),
  ('p8000000-0000-0000-0000-000000000004', 'Nivea Soft Moisturiser', 'Light face cream', 220.00, 299.00, '200ml', 70, 'c8000000-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1556228578-0d85b1a4d571?w=500&q=80', true, false, ARRAY['care', 'face']),
  ('p8000000-0000-0000-0000-000000000005', 'Gillette Mach 3 Razor', 'Shaving razor with blades', 250.00, 300.00, '1 pack', 40, 'c8000000-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1595166258019-216503b2f5fe?w=500&q=80', true, false, ARRAY['care', 'shaving'])
ON CONFLICT (id) DO NOTHING;


-- 3. Banners (2 active banners)
INSERT INTO public.banners (id, image_url, cta_url, display_order, is_active, starts_at, ends_at) VALUES
  ('b1000000-0000-0000-0000-000000000001', 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&q=80&w=1974', '/browse_categories', 1, true, NOW() - INTERVAL '1 day', NOW() + INTERVAL '30 days'),
  ('b1000000-0000-0000-0000-000000000002', 'https://images.unsplash.com/photo-1621939514649-280e227845cb?auto=format&fit=crop&q=80&w=2070', '/products/p4000000-0000-0000-0000-000000000001', 2, true, NOW() - INTERVAL '1 day', NOW() + INTERVAL '30 days')
ON CONFLICT (id) DO NOTHING;


-- 4. Flash Deals (3 deals ending in 24hrs)
INSERT INTO public.flash_deals (id, product_id, discount_percent, start_time, end_time, max_qty, is_active) VALUES
  ('f1000000-0000-0000-0000-000000000001', 'p1000000-0000-0000-0000-000000000001', 20.00, NOW() - INTERVAL '1 hour', NOW() + INTERVAL '24 hours', 100, true),
  ('f1000000-0000-0000-0000-000000000002', 'p2000000-0000-0000-0000-000000000001', 30.00, NOW() - INTERVAL '1 hour', NOW() + INTERVAL '24 hours', 50, true),
  ('f1000000-0000-0000-0000-000000000003', 'p3000000-0000-0000-0000-000000000001', 15.00, NOW() - INTERVAL '1 hour', NOW() + INTERVAL '24 hours', 200, true)
ON CONFLICT (id) DO NOTHING;


-- 5. Coupons (3 coupon codes)
INSERT INTO public.coupons (id, code, discount_type, discount_value, min_order_value, max_uses, valid_until, is_active) VALUES
  ('u1000000-0000-0000-0000-000000000001', 'SAVE10', 'percent', 10.00, 299.00, 1000, NOW() + INTERVAL '30 days', true),
  ('u1000000-0000-0000-0000-000000000002', 'FLAT50', 'flat', 50.00, 499.00, 500, NOW() + INTERVAL '15 days', true),
  ('u1000000-0000-0000-0000-000000000003', 'WELCOME20', 'percent', 20.00, 199.00, 10000, NOW() + INTERVAL '365 days', true)
ON CONFLICT (id) DO NOTHING;


-- 6. Home Config (SDUI JSON)
INSERT INTO public.home_config (id, config, is_active) VALUES
  ('h1000000-0000-0000-0000-000000000001', '
    {
      "sections": [
        {
          "type": "banner_carousel",
          "visible": true
        },
        {
          "type": "category_row",
          "title": "Shop by Category",
          "visible": true
        },
        {
          "type": "flash_deals_row",
          "title": "Flash Deals",
          "subtitle": "Grab them before they are gone!",
          "visible": true
        },
        {
          "type": "product_grid",
          "title": "Featured Products",
          "visible": true
        }
      ]
    }
  '::jsonb, true)
ON CONFLICT (id) DO NOTHING;
