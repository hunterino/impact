-- Create a test user for development
-- Email: ds@coyoteforge.com
-- Password: all4Datastore!

-- Create user using Supabase's auth functions
DO $$
DECLARE
    user_id uuid;
BEGIN
    -- Generate a UUID for the user
    user_id := gen_random_uuid();

    -- Insert into auth.users without ON CONFLICT
    -- Check if user already exists first
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'ds@coyoteforge.com') THEN
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

        -- Create identity for the user (required for Supabase auth)
        INSERT INTO auth.identities (
            id,
            user_id,
            identity_data,
            provider,
            last_sign_in_at,
            created_at,
            updated_at
        ) VALUES (
            gen_random_uuid(),
            user_id,
            jsonb_build_object(
                'sub', user_id,
                'email', 'ds@coyoteforge.com',
                'email_verified', true
            ),
            'email',
            NOW(),
            NOW(),
            NOW()
        );

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
        );

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
        );

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
        );

        RAISE NOTICE 'User created successfully!';
        RAISE NOTICE 'User ID: %', user_id;
        RAISE NOTICE 'Email: ds@coyoteforge.com';
        RAISE NOTICE 'Password: all4Datastore!';
        RAISE NOTICE 'Handle: datastore';
        RAISE NOTICE 'Initial balance: 1000 STBF points';
    ELSE
        RAISE NOTICE 'User with email ds@coyoteforge.com already exists';
    END IF;
END $$;

-- Verify the user was created
SELECT
    u.id,
    u.email,
    u.created_at,
    u.role,
    p.handle,
    w.balance as stbf_points,
    su.phone
FROM auth.users u
LEFT JOIN public.profile p ON p.user_id = u.id
LEFT JOIN public.wallet_balance w ON w.user_id = u.id
LEFT JOIN public.sensitive_user su ON su.user_id = u.id
WHERE u.email = 'ds@coyoteforge.com';