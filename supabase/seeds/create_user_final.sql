-- Create a test user for development
-- Email: ds@coyoteforge.com
-- Password: all4Datastore!

DO $$
DECLARE
    new_user_id uuid;
    existing_user_id uuid;
BEGIN
    -- Check if user already exists
    SELECT id INTO existing_user_id FROM auth.users WHERE email = 'ds@coyoteforge.com';

    IF existing_user_id IS NOT NULL THEN
        new_user_id := existing_user_id;
        RAISE NOTICE 'User already exists with ID: %', new_user_id;

        -- Delete the user to recreate it fresh
        DELETE FROM auth.identities WHERE user_id = existing_user_id;
        DELETE FROM public.profile WHERE user_id = existing_user_id;
        DELETE FROM public.wallet_balance WHERE user_id = existing_user_id;
        DELETE FROM auth.users WHERE id = existing_user_id;

        RAISE NOTICE 'Deleted existing user to recreate fresh';
    END IF;

    -- Generate a UUID for the user
    new_user_id := gen_random_uuid();

    -- Insert into auth.users with proper defaults for text fields
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
        confirmation_token,
        recovery_token,
        email_change_token_new,
        email_change_token_current,
        reauthentication_token,
        phone_change_token,
        email_change,
        phone_change
    ) VALUES (
        new_user_id,
        '00000000-0000-0000-0000-000000000000',
        'ds@coyoteforge.com',
        crypt('all4Datastore!', gen_salt('bf')),
        NOW(),
        NOW(),
        NOW(),
        '{"provider": "email", "providers": ["email"]}',
        '{"name": "DataStore User", "full_name": "DataStore Admin"}',
        'authenticated',
        'authenticated',
        '',  -- confirmation_token
        '',  -- recovery_token
        '',  -- email_change_token_new
        '',  -- email_change_token_current
        '',  -- reauthentication_token
        '',  -- phone_change_token
        '',  -- email_change
        ''   -- phone_change
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
        new_user_id::text,
        new_user_id,
        jsonb_build_object(
            'sub', new_user_id::text,
            'email', 'ds@coyoteforge.com',
            'email_verified', true
        ),
        'email',
        NOW(),
        NOW(),
        NOW()
    );

    -- Create profile
    INSERT INTO public.profile (
        user_id,
        handle,
        created_at,
        created_by,
        updated_at,
        updated_by
    ) VALUES (
        new_user_id,
        'datastore',
        NOW(),
        new_user_id,
        NOW(),
        new_user_id
    );

    -- Create wallet balance
    INSERT INTO public.wallet_balance (
        user_id,
        balance,
        created_at,
        updated_at
    ) VALUES (
        new_user_id,
        1000, -- Start with 1000 STBF points
        NOW(),
        NOW()
    );

    RAISE NOTICE '=================================';
    RAISE NOTICE 'User Setup Complete!';
    RAISE NOTICE '=================================';
    RAISE NOTICE 'User ID: %', new_user_id;
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
    u.email_confirmed_at,
    u.created_at,
    u.role,
    p.handle,
    w.balance as stbf_points
FROM auth.users u
LEFT JOIN public.profile p ON p.user_id = u.id
LEFT JOIN public.wallet_balance w ON w.user_id = u.id
WHERE u.email = 'ds@coyoteforge.com';