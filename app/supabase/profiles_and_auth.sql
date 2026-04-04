-- ============================================================
-- SwiftMart — Supabase Auth + profiles (run in SQL Editor)
-- ============================================================
--
-- Option A — Greenfield `profiles` table (matches the app rewrite prompt)
-- If you use this, set AuthService.profileTable to 'profiles' in Flutter
-- and migrate FKs from public.users → public.profiles where needed.
--

CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  full_name text,
  email text,
  avatar_url text,
  fcm_token text,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Profiles are viewable by owner"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Profiles are insertable by owner"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Profiles are updatable by owner"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE OR REPLACE FUNCTION public.handle_new_user_profiles()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, email, avatar_url)
  VALUES (
    new.id,
    new.raw_user_meta_data->>'full_name',
    new.email,
    new.raw_user_meta_data->>'avatar_url'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN new;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created_profiles ON auth.users;

CREATE TRIGGER on_auth_user_created_profiles
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user_profiles();

-- ============================================================
-- Option B — Existing SwiftMart schema already uses public.users
-- The Flutter app defaults to profileTable = 'users' (see AuthService).
-- Ensure column exists:
-- ============================================================

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS fcm_token text;

-- If you rely on full_name in metadata, your existing handle_new_user()
-- on public.users already maps raw_user_meta_data->>'full_name' into users.name.
