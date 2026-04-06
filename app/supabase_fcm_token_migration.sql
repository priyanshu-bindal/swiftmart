-- ============================================================
-- SwiftMart — Add fcm_token column to profiles table
-- Run in Supabase SQL Editor
-- ============================================================

-- Add fcm_token column if it doesn't exist
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- Index for quick lookups when sending notifications
CREATE INDEX IF NOT EXISTS idx_profiles_fcm_token ON profiles(fcm_token) WHERE fcm_token IS NOT NULL;

-- Grant update on fcm_token
GRANT UPDATE (fcm_token, updated_at) ON profiles TO authenticated;
