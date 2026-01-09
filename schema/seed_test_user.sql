-- Seed Data for test user
-- Run this to create a demo user

-- ============================================
-- TEST USER
-- ============================================
-- Password: test123 (Argon2id hash)
DO $$
DECLARE
    test_user_id UUID := gen_random_uuid();
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.users WHERE username = 'test' LIMIT 1) THEN
        INSERT INTO public.users (id, username, email, password, role, profile_image, balance) VALUES
        (test_user_id::TEXT, 'test', 'test@example.com', '$argon2id$v=19$m=65536,t=2,p=4$9jxOCCocOObYAQsSZSdn/Q$D/aHTk8cP1Ut7K5PxazEd6s4W0GC7YtRfVKyCYU8f/4', 'user', 'avatar-1.png', 15000);

        -- Add some purchase history for the test user
        INSERT INTO dashboard.credit_purchases (user_id, credits, amount_paid, status, purchased_at) VALUES
        (test_user_id::TEXT, 5750, 19.99, 'completed', NOW() - INTERVAL '7 days'),
        (test_user_id::TEXT, 2750, 9.99, 'completed', NOW() - INTERVAL '14 days'),
        (test_user_id::TEXT, 1000, 4.99, 'completed', NOW() - INTERVAL '30 days');

        RAISE NOTICE 'Created test user (test/test123) with purchase history!';
    ELSE
        RAISE NOTICE 'Test user already exists, skipping.';
    END IF;
END $$;
