-- Fix Relationships between Orders and Profiles
-- This casts the text 'user_id' to 'uuid' and adds the missing Foreign Key.

DO $$ 
BEGIN
    -- 1. Convert user_id column from text to uuid safely
    ALTER TABLE "public"."orders" ALTER COLUMN "user_id" TYPE uuid USING "user_id"::uuid;

    -- 2. Check if constraint already exists to avoid errors
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.table_constraints 
        WHERE constraint_name = 'orders_user_id_fkey_profiles'
    ) THEN
        ALTER TABLE "public"."orders" 
        ADD CONSTRAINT "orders_user_id_fkey_profiles" 
        FOREIGN KEY ("user_id") 
        REFERENCES "public"."profiles"("id") 
        ON DELETE CASCADE;
    END IF;

    -- Instruct PostgREST to reload the schema cache so the UI immediately works
    NOTIFY pgrst, 'reload schema';
END $$;
