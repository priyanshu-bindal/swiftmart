-- SQLite / PostgreSQL SQL Script to update image URLs for SwiftMart products
-- Run this in your Supabase SQL editor

-- Fruits & Vegetables
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1553284965-83fd3e82fa5a?auto=format&fit=crop&w=800&q=80' WHERE name = 'Fresh Mango';
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1528825871115-3581a5387919?auto=format&fit=crop&w=800&q=80' WHERE name = 'Banana';
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?auto=format&fit=crop&w=800&q=80' WHERE name = 'Tomatoes';
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1518977676601-b53f82aba655?auto=format&fit=crop&w=800&q=80' WHERE name = 'Potatoes';
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1518977822534-7049a61ee0c2?auto=format&fit=crop&w=800&q=80' WHERE name = 'Onions';
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1576045057995-568f588f82fb?auto=format&fit=crop&w=800&q=80' WHERE name = 'Spinach';
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1563514948011-002d75f2845a?auto=format&fit=crop&w=800&q=80' WHERE name = 'Green Capsicum';
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?auto=format&fit=crop&w=800&q=80' WHERE name = 'Carrots';
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1596368708356-6e1efb714eb9?auto=format&fit=crop&w=800&q=80' WHERE name = 'Ginger';

-- Dairy
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1563636619-e9143da7973b?auto=format&fit=crop&w=800&q=80' WHERE name = 'Whole Milk';
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1588195538326-c5b1e9f80a1b?auto=format&fit=crop&w=800&q=80' WHERE name = 'Amul Butter';
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1570197781387-c1eaab6eb46f?auto=format&fit=crop&w=800&q=80' WHERE name = 'Amul Dahi Curd';
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1631452180519-c014fe946bc0?auto=format&fit=crop&w=800&q=80' WHERE name = 'Paneer Fresh';
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1621539207085-f86a24ed12a4?auto=format&fit=crop&w=800&q=80' WHERE name = 'Nestle Munch Milk';

-- Snacks
UPDATE products SET image_url = 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cb/Lay%27s_Potato_Chips_Original.jpg/800px-Lay%27s_Potato_Chips_Original.jpg' WHERE name = 'Lay''s Classic Salted Chips';
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1600350756711-2eb25e36fe04?auto=format&fit=crop&w=800&q=80' WHERE name = 'Kurkure Masala Munch';
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?auto=format&fit=crop&w=800&q=80' WHERE name = 'Parle-G Biscuits';
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1590080874088-eec648e18f8e?auto=format&fit=crop&w=800&q=80' WHERE name = 'Monaco Classic Crackers';
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1499636136210-6f4ee915583e?auto=format&fit=crop&w=800&q=80' WHERE name = 'Hide & Seek Chocolate Chips';
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1612929633738-8fe44f7ec841?auto=format&fit=crop&w=800&q=80' WHERE name = 'Maggi 2-Minute Noodles';

-- Beverages
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1597481499750-3e6b22637e12?auto=format&fit=crop&w=800&q=80' WHERE name = 'Tata Tea Premium';
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1559525839-b184a4d698c7?auto=format&fit=crop&w=800&q=80' WHERE name = 'Nescafe Classic Coffee';
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1600271886742-f049cd451bba?auto=format&fit=crop&w=800&q=80' WHERE name = 'Real Fruit Juice Mixed';
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1523362628745-0c100150b504?auto=format&fit=crop&w=800&q=80' WHERE name = 'Bisleri Water Bottle';
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1601114224767-f58c707d853e?auto=format&fit=crop&w=800&q=80' WHERE name = 'Tropicana Orange Juice';
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1589182373726-e4f658ab50f0?auto=format&fit=crop&w=800&q=80' WHERE name = 'Horlicks Health Drink';

-- Bakery
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=800&q=80' WHERE name = 'Britannia Bread';
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1582294101680-e83fa41f173b?auto=format&fit=crop&w=800&q=80' WHERE name = 'English Muffins';
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1557089706-68d01f11a432?auto=format&fit=crop&w=800&q=80' WHERE name = 'Britannia Good Day Butter';
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=800&q=80' WHERE name = 'brown bread whole wheat';
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1555507036-ab1f40ce88cb?auto=format&fit=crop&w=800&q=80' WHERE name = 'Croissant Plain';

-- Meat & Seafood
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1604503468506-a8da13d82791?auto=format&fit=crop&w=800&q=80' WHERE name = 'Chicken Breast Boneless';
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1506976785307-8732e854ad03?auto=format&fit=crop&w=800&q=80' WHERE name = 'Eggs Farm Fresh';
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1615141982883-c7ad0e69fd62?auto=format&fit=crop&w=800&q=80' WHERE name = 'Rohu Fish Fresh';
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1559742811-822873691df8?auto=format&fit=crop&w=800&q=80' WHERE name = 'Prawns Medium';
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1603048297172-c92544798d5e?auto=format&fit=crop&w=800&q=80' WHERE name = 'Mutton Curry Cut';

-- Personal Care
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1600857062241-98e5dba7f214?auto=format&fit=crop&w=800&q=80' WHERE name = 'Dove Soap Bar';
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1599305090598-fe179d501227?auto=format&fit=crop&w=800&q=80' WHERE name = 'Head & Shoulders Shampoo';
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1559564104-eeb19c238b68?auto=format&fit=crop&w=800&q=80' WHERE name = 'Colgate Strong Teeth';
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1584305574647-0cc9deac258f?auto=format&fit=crop&w=800&q=80' WHERE name = 'Dettol Hand Wash';
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?auto=format&fit=crop&w=800&q=80' WHERE name = 'Vaseline Body Lotion';

-- Household
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1610557892470-55d9e80c0bce?auto=format&fit=crop&w=800&q=80' WHERE name = 'Surf Excel Matic Powder';
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1585670149967-b4f4da88cc9f?auto=format&fit=crop&w=800&q=80' WHERE name = 'Vim Dishwash Bar';
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1584813470613-28ad1779872e?auto=format&fit=crop&w=800&q=80' WHERE name = 'Harpic Toilet Cleaner';
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1596489370605-72d829986b8f?auto=format&fit=crop&w=800&q=80' WHERE name = 'Good Knight Mosquito Coil';
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1585670210693-e7fdd16b14d8?auto=format&fit=crop&w=800&q=80' WHERE name = 'Scotch-Brite Scrub Pad';
