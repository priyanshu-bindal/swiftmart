BEGIN;

-- 1. Create the bucket if it doesn't exist and make sure it is public
INSERT INTO storage.buckets (id, name, public)
VALUES ('swiftmart-images', 'swiftmart-images', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- (RLS is already enabled by default on storage.objects, so we skip ALTER TABLE)

-- 3. Drop existing policies specific to this bucket to avoid conflicts
DROP POLICY IF EXISTS "Public Select" ON storage.objects;
DROP POLICY IF EXISTS "Auth Insert" ON storage.objects;
DROP POLICY IF EXISTS "Auth Update" ON storage.objects;
DROP POLICY IF EXISTS "Auth Delete" ON storage.objects;

-- 4. Create comprehensive policies for 'swiftmart-images'

-- Public select policy: ANYONE can view images from this bucket
CREATE POLICY "Public Select"
ON storage.objects FOR SELECT
USING (bucket_id = 'swiftmart-images');

-- Authenticated Insert Policy: logged-in users (Admins) can upload
CREATE POLICY "Auth Insert"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'swiftmart-images');

-- Authenticated Update Policy: logged-in users can overwrite/update images
CREATE POLICY "Auth Update"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'swiftmart-images');

-- Authenticated Delete Policy: logged-in users can delete images
CREATE POLICY "Auth Delete"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'swiftmart-images');

COMMIT;
