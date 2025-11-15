-- Create a test user for development
-- Email: ds@coyoteforge.com
-- Password: all4Datastore!

-- First, create the auth user
-- Note: In production, users should be created through the Supabase Auth API
-- This is for local development only

DO $$
DECLARE
    user_id uuid;
BEGIN
    -- Generate a UUID for the user
    user_id := gen_random_uuid();

    -- Insert into auth.users
    INSERT INTO auth.users (
        id,
        instance_id,
        email,
        encrypted_password,
        email_confirmed_at,
        created_at,
        updated_at,
        raw_app_meta_data,
        raw_user_meta_data,
        aud,
        role,
        confirmation_token
    ) VALUES (
        user_id,
        '00000000-0000-0000-0000-000000000000',
        'ds@coyoteforge.com',
        crypt('all4Datastore!', gen_salt('bf')),
        NOW(),
        NOW(),
        NOW(),
        '{"provider": "email", "providers": ["email"]}',
        '{"name": "DataStore User"}',
        'authenticated',
        'authenticated',
        ''
    ) ON CONFLICT (email) DO NOTHING;

    -- Create profile for the user
    INSERT INTO public.profile (
        user_id,
        handle,
        created_at,
        created_by,
        updated_at
    ) VALUES (
        user_id,
        'datastore',
        NOW(),
        user_id,
        NOW()
    ) ON CONFLICT (user_id) DO NOTHING;

    -- Create wallet balance for the user
    INSERT INTO public.wallet_balance (
        user_id,
        balance,
        created_at,
        updated_at
    ) VALUES (
        user_id,
        1000, -- Start with 1000 STBF points
        NOW(),
        NOW()
    ) ON CONFLICT (user_id) DO NOTHING;

    -- Add user to sensitive_user table with phone
    INSERT INTO public.sensitive_user (
        user_id,
        email,
        phone,
        created_at,
        created_by,
        updated_at
    ) VALUES (
        user_id,
        'ds@coyoteforge.com',
        '+1234567890', -- Default phone number
        NOW(),
        user_id,
        NOW()
    ) ON CONFLICT (user_id) DO NOTHING;

    RAISE NOTICE 'User created successfully with ID: %', user_id;
    RAISE NOTICE 'Email: ds@coyoteforge.com';
    RAISE NOTICE 'Handle: datastore';
    RAISE NOTICE 'Initial balance: 1000 STBF points';
END $$;

-- Verify the user was created
SELECT
    u.id,
    u.email,
    u.created_at,
    p.handle,
    w.balance as stbf_points
FROM auth.users u
LEFT JOIN public.profile p ON p.user_id = u.id
LEFT JOIN public.wallet_balance w ON w.user_id = u.id
WHERE u.email = 'ds@coyoteforge.com';