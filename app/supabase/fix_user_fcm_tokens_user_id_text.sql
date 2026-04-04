-- Convert user_fcm_tokens.user_id to text to match Firebase UID strings.
-- Safe for existing deployments where user_id may still be uuid.

ALTER TABLE public.user_fcm_tokens
DROP CONSTRAINT IF EXISTS user_fcm_tokens_user_id_fkey;

ALTER TABLE public.user_fcm_tokens
ALTER COLUMN user_id TYPE text USING user_id::text;

DROP POLICY IF EXISTS "Users manage own fcm tokens" ON public.user_fcm_tokens;

CREATE POLICY "Users manage own fcm tokens"
ON public.user_fcm_tokens
FOR ALL
TO authenticated
USING (auth.uid()::text = user_id);
