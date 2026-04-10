-- Fix for "Could not find the 'image_url' column of 'categories' in the schema cache"
ALTER TABLE categories ADD COLUMN IF NOT EXISTS image_url TEXT;
ALTER TABLE categories ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
ALTER TABLE categories ADD COLUMN IF NOT EXISTS sort_order INTEGER DEFAULT 0;

-- Just to be completely safe, ensure it exists on banners too
ALTER TABLE banners ADD COLUMN IF NOT EXISTS image_url TEXT;
