-- Create a test user for development
-- Email: ds@coyoteforge.com
-- Password: all4Datastore!

DO $$
DECLARE
    user_id uuid;
    existing_user_id uuid;
BEGIN
    -- Check if user already exists
    SELECT id INTO existing_user_id FROM auth.users WHERE email = 'ds@coyoteforge.com';

    IF existing_user_id IS NOT NULL THEN
        user_id := existing_user_id;
        RAISE NOTICE 'User already exists with ID: %', user_id;
    ELSE
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
            role
        ) VALUES (
            user_id,
            '00000000-0000-0000-0000-000000000000',
            'ds@coyoteforge.com',
            crypt('all4Datastore!', gen_salt('bf')),
            NOW(),
            NOW(),
            NOW(),
            '{"provider": "email", "providers": ["email"]}',
            '{"name": "DataStore User", "full_name": "DataStore Admin"}',
            'authenticated',
            'authenticated'
        );

        -- Create identity for the user
        INSERT INTO auth.identities (
            provider_id,
            user_id,
            identity_data,
            provider,
            last_sign_in_at,
            created_at,
            updated_at
        ) VALUES (
            user_id::text, -- provider_id is usually the same as user_id for email auth
            user_id,
            jsonb_build_object(
                'sub', user_id::text,
                'email', 'ds@coyoteforge.com',
                'email_verified', true
            ),
            'email',
            NOW(),
            NOW(),
            NOW()
        );

        RAISE NOTICE 'User created successfully with ID: %', user_id;
    END IF;

    -- Create or update profile
    INSERT INTO public.profile (
        user_id,
        handle,
        created_at,
        created_by,
        updated_at,
        updated_by
    ) VALUES (
        user_id,
        'datastore',
        NOW(),
        user_id,
        NOW(),
        user_id
    )
    ON CONFLICT (profile.user_id) DO UPDATE
    SET handle = 'datastore',
        updated_at = NOW(),
        updated_by = EXCLUDED.updated_by;

    -- Create or update wallet balance
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
    )
    ON CONFLICT (wallet_balance.user_id) DO UPDATE
    SET balance = wallet_balance.balance + 0, -- Don't change if exists
        updated_at = NOW();

    RAISE NOTICE '=================================';
    RAISE NOTICE 'User Setup Complete!';
    RAISE NOTICE '=================================';
    RAISE NOTICE 'Email: ds@coyoteforge.com';
    RAISE NOTICE 'Password: all4Datastore!';
    RAISE NOTICE 'Handle: datastore';
    RAISE NOTICE 'Initial balance: 1000 STBF points';
    RAISE NOTICE '=================================';
END $$;

-- Verify the user was created
SELECT
    u.id,
    u.email,
    u.created_at,
    u.role,
    p.handle,
    w.balance as stbf_points
FROM auth.users u
LEFT JOIN public.profile p ON p.user_id = u.id
LEFT JOIN public.wallet_balance w ON w.user_id = u.id
WHERE u.email = 'ds@coyoteforge.com';