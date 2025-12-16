-- Seed Data for All Services
-- Run this after init.sql to populate initial data

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

        -- Add some characters for the test user
        INSERT INTO dashboard.characters (user_id, name, level, class, gold) VALUES
        (test_user_id::TEXT, 'ShadowBlade', 85, 'Assassin', 125000),
        (test_user_id::TEXT, 'HolyLight', 72, 'Priest', 89500),
        (test_user_id::TEXT, 'IronFist', 45, 'Warrior', 32000);

        RAISE NOTICE 'Created test user (test/test123) with purchase history and characters!';
    ELSE
        RAISE NOTICE 'Test user already exists, skipping.';
    END IF;
END $$;

-- ============================================
-- STORE ITEMS
-- ============================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dashboard.items LIMIT 1) THEN
        INSERT INTO dashboard.items (name, description, type, price, image) VALUES
        -- Costumes
        ('Shadow Cloak', 'A mysterious dark cloak that shrouds you in shadows.', 'costumes', 2500, '/assets/items/shadow-cloak.png'),
        ('Golden Armor Set', 'Gleaming armor fit for a champion.', 'costumes', 5000, '/assets/items/golden-armor.png'),
        ('Phoenix Wings', 'Fiery wings that leave trails of embers.', 'costumes', 7500, '/assets/items/phoenix-wings.png'),
        ('Frost Knight Armor', 'Ice-forged armor radiating cold.', 'costumes', 4500, '/assets/items/frost-knight.png'),
        
        -- Boosts
        ('XP Boost (1 Hour)', 'Double experience for 1 hour.', 'boosts', 500, '/assets/items/xp-boost.png'),
        ('XP Boost (24 Hours)', 'Double experience for 24 hours.', 'boosts', 2000, '/assets/items/xp-boost.png'),
        ('Gold Boost (1 Hour)', '50% more gold drops for 1 hour.', 'boosts', 750, '/assets/items/gold-boost.png'),
        ('Drop Rate Boost (1 Hour)', 'Increased rare item drop rate.', 'boosts', 1000, '/assets/items/drop-boost.png'),
        
        -- Bundles
        ('Starter Bundle', 'Perfect for new adventurers. Includes XP boost and basic costume.', 'bundles', 1500, '/assets/items/starter-bundle.png'),
        ('Premium Bundle', 'XP boost, gold boost, and exclusive armor set.', 'bundles', 8000, '/assets/items/premium-bundle.png'),
        ('Ultimate Bundle', 'Everything you need: all boosts and legendary costume.', 'bundles', 15000, '/assets/items/ultimate-bundle.png');

        RAISE NOTICE 'Seeded store items successfully!';
    ELSE
        RAISE NOTICE 'Store items already exist, skipping.';
    END IF;
END $$;

-- ============================================
-- FORUM CATEGORIES
-- ============================================
DO $$
DECLARE
    announcements_id UUID := gen_random_uuid();
    game_discussion_id UUID := gen_random_uuid();
    trading_id UUID := gen_random_uuid();
    updates_id UUID := gen_random_uuid();
    events_id UUID := gen_random_uuid();
    general_id UUID := gen_random_uuid();
    guides_id UUID := gen_random_uuid();
    buying_id UUID := gen_random_uuid();
    selling_id UUID := gen_random_uuid();
BEGIN
    IF NOT EXISTS (SELECT 1 FROM forum.categories LIMIT 1) THEN
        
        -- Parent categories
        INSERT INTO forum.categories (id, name, description, image, slug, is_locked, parent_id) VALUES
        (announcements_id::TEXT, 'Announcements', 'Official updates and important information.', '/assets/announcements.png', NULL, false, NULL),
        (game_discussion_id::TEXT, 'Game Discussion', 'General gameplay topics and strategies.', '/assets/gamediscussion.png', NULL, false, NULL),
        (trading_id::TEXT, 'Trading & Economy', 'Buy, sell, and trade in-game items.', '/assets/trading.png', NULL, false, NULL);

        -- Subcategories
        INSERT INTO forum.categories (id, name, description, image, slug, is_locked, parent_id) VALUES
        (updates_id::TEXT, 'Server Updates', 'Latest server patches and updates.', NULL, 'updates-patches', false, announcements_id::TEXT),
        (events_id::TEXT, 'Events', 'Upcoming and ongoing events.', NULL, 'events', false, announcements_id::TEXT),
        (general_id::TEXT, 'General Discussion', 'Talk about anything game related.', NULL, 'general-discussion', false, game_discussion_id::TEXT),
        (guides_id::TEXT, 'Strategies & Guides', 'Share your best strategies and tips.', NULL, 'strategies-guides', false, game_discussion_id::TEXT),
        (buying_id::TEXT, 'Buying', 'Looking to purchase items or services.', NULL, 'buying', false, trading_id::TEXT),
        (selling_id::TEXT, 'Selling', 'List items or services for sale.', NULL, 'selling', false, trading_id::TEXT);

        RAISE NOTICE 'Seeded forum categories successfully!';
    ELSE
        RAISE NOTICE 'Categories already exist, skipping seed.';
    END IF;
END $$;

-- ============================================
-- DEMO USERS (for forum content, no valid passwords)
-- ============================================
DO $$
DECLARE
    admin_id UUID := gen_random_uuid();
    user1_id UUID := gen_random_uuid();
    user2_id UUID := gen_random_uuid();
    user3_id UUID := gen_random_uuid();
    user4_id UUID := gen_random_uuid();
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.users WHERE username = 'GameMaster' LIMIT 1) THEN
        INSERT INTO public.users (id, username, email, password, role, profile_image, balance) VALUES
        (admin_id::TEXT, 'GameMaster', 'gm@example.com', 'nologin', 'admin', 'avatar-20.png', 0),
        (user1_id::TEXT, 'DragonSlayer', 'dragon@example.com', 'nologin', 'user', 'avatar-5.png', 5000),
        (user2_id::TEXT, 'MysticMage', 'mystic@example.com', 'nologin', 'user', 'avatar-12.png', 3200),
        (user3_id::TEXT, 'NightHunter', 'hunter@example.com', 'nologin', 'user', 'avatar-8.png', 8500),
        (user4_id::TEXT, 'IronGuard', 'guard@example.com', 'nologin', 'user', 'avatar-15.png', 1500);

        RAISE NOTICE 'Created demo users for forum content!';
    ELSE
        RAISE NOTICE 'Demo users already exist, skipping.';
    END IF;
END $$;

-- ============================================
-- FORUM THREADS AND POSTS
-- ============================================
DO $$
DECLARE
    admin_id TEXT;
    user1_id TEXT;
    user2_id TEXT;
    user3_id TEXT;
    user4_id TEXT;
    updates_cat TEXT;
    events_cat TEXT;
    general_cat TEXT;
    guides_cat TEXT;
    buying_cat TEXT;
    selling_cat TEXT;
    thread_id INTEGER;
BEGIN
    -- Get user IDs
    SELECT id INTO admin_id FROM public.users WHERE username = 'GameMaster';
    SELECT id INTO user1_id FROM public.users WHERE username = 'DragonSlayer';
    SELECT id INTO user2_id FROM public.users WHERE username = 'MysticMage';
    SELECT id INTO user3_id FROM public.users WHERE username = 'NightHunter';
    SELECT id INTO user4_id FROM public.users WHERE username = 'IronGuard';
    
    -- Get category IDs
    SELECT id INTO updates_cat FROM forum.categories WHERE slug = 'updates-patches';
    SELECT id INTO events_cat FROM forum.categories WHERE slug = 'events';
    SELECT id INTO general_cat FROM forum.categories WHERE slug = 'general-discussion';
    SELECT id INTO guides_cat FROM forum.categories WHERE slug = 'strategies-guides';
    SELECT id INTO buying_cat FROM forum.categories WHERE slug = 'buying';
    SELECT id INTO selling_cat FROM forum.categories WHERE slug = 'selling';

    IF admin_id IS NULL OR updates_cat IS NULL THEN
        RAISE NOTICE 'Required data not found, skipping forum content.';
        RETURN;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM forum.threads LIMIT 1) THEN
        
        -- Thread 1: Server Update (Announcements)
        INSERT INTO forum.threads (category_id, title, author_id, is_sticky, created_at)
        VALUES (updates_cat, 'Patch 2.5.0 - Winter Update Now Live!', admin_id, true, NOW() - INTERVAL '2 days')
        RETURNING id INTO thread_id;
        
        INSERT INTO forum.posts (thread_id, author_id, content, created_at) VALUES
        (thread_id, admin_id, 'We are excited to announce that Patch 2.5.0 is now live! This update brings new winter-themed content, balance changes, and bug fixes.

**New Features:**
- Winter Wonderland event zone
- 5 new winter costumes
- Ice Dragon world boss

**Balance Changes:**
- Warrior base HP increased by 10%
- Mage fireball damage reduced by 5%

See you in-game!', NOW() - INTERVAL '2 days'),
        (thread_id, user1_id, 'Finally! Been waiting for this update. The ice dragon looks amazing!', NOW() - INTERVAL '2 days' + INTERVAL '2 hours'),
        (thread_id, user2_id, 'Mage nerf? Really? We were already struggling in PvP...', NOW() - INTERVAL '2 days' + INTERVAL '3 hours'),
        (thread_id, user3_id, 'Love the new costumes! Already bought the Frost Assassin set.', NOW() - INTERVAL '1 day');

        -- Thread 2: Event Announcement
        INSERT INTO forum.threads (category_id, title, author_id, is_sticky, created_at)
        VALUES (events_cat, 'Double XP Weekend - Dec 20-22!', admin_id, true, NOW() - INTERVAL '1 day')
        RETURNING id INTO thread_id;
        
        INSERT INTO forum.posts (thread_id, author_id, content, created_at) VALUES
        (thread_id, admin_id, 'Get ready for our Double XP Weekend event!

**When:** December 20th - 22nd (All day)
**What:** 2x Experience from all sources

This is a great opportunity to level up your alts or push to max level. Stack with XP boosts for even more gains!', NOW() - INTERVAL '1 day'),
        (thread_id, user4_id, 'Perfect timing! I just started a new character.', NOW() - INTERVAL '1 day' + INTERVAL '1 hour'),
        (thread_id, user1_id, 'Does this stack with the premium XP boost from the store?', NOW() - INTERVAL '20 hours'),
        (thread_id, admin_id, 'Yes! All XP bonuses stack multiplicatively.', NOW() - INTERVAL '18 hours');

        -- Thread 3: General Discussion
        INSERT INTO forum.threads (category_id, title, author_id, created_at)
        VALUES (general_cat, 'Best class for solo play?', user3_id, NOW() - INTERVAL '5 days')
        RETURNING id INTO thread_id;
        
        INSERT INTO forum.posts (thread_id, author_id, content, created_at) VALUES
        (thread_id, user3_id, 'Hey everyone! I mostly play solo and wondering which class is best for that playstyle. I like being able to clear content without relying on groups.', NOW() - INTERVAL '5 days'),
        (thread_id, user1_id, 'Assassin is great for solo. High burst damage and good survivability with stealth.', NOW() - INTERVAL '5 days' + INTERVAL '30 minutes'),
        (thread_id, user2_id, 'I''d recommend Mage actually. Range + AoE makes farming super efficient. Just need to learn positioning.', NOW() - INTERVAL '5 days' + INTERVAL '1 hour'),
        (thread_id, user4_id, 'Warrior with lifesteal build. You can literally face-tank anything.', NOW() - INTERVAL '4 days'),
        (thread_id, user3_id, 'Thanks for the suggestions! Thinking I''ll try Assassin first.', NOW() - INTERVAL '4 days' + INTERVAL '2 hours');

        -- Thread 4: Strategy Guide
        INSERT INTO forum.threads (category_id, title, author_id, is_sticky, created_at)
        VALUES (guides_cat, '[Guide] Ice Dragon World Boss - Full Strategy', user1_id, false, NOW() - INTERVAL '1 day')
        RETURNING id INTO thread_id;
        
        INSERT INTO forum.posts (thread_id, author_id, content, created_at) VALUES
        (thread_id, user1_id, '# Ice Dragon World Boss Guide

After many attempts, my guild finally has this boss figured out. Here''s our strategy:

## Phase 1 (100% - 70%)
- Tank faces boss away from raid
- Avoid frost breath (frontal cone)
- Stack for heals

## Phase 2 (70% - 30%)
- Boss summons ice adds - kill them ASAP
- Spread out to avoid chain frost
- Use defensive cooldowns during Blizzard

## Phase 3 (30% - 0%)
- All mechanics from P1 and P2
- Enrage timer starts - pop all DPS cooldowns
- Healer focus on tank, others use potions

Good luck everyone!', NOW() - INTERVAL '1 day'),
        (thread_id, user2_id, 'Great guide! We wiped 10 times before figuring out the add phase.', NOW() - INTERVAL '20 hours'),
        (thread_id, user4_id, 'What''s the minimum gear score you''d recommend?', NOW() - INTERVAL '15 hours'),
        (thread_id, user1_id, 'We did it with average 4500 GS, but 5000+ makes it much smoother.', NOW() - INTERVAL '12 hours');

        -- Thread 5: Buying post
        INSERT INTO forum.threads (category_id, title, author_id, created_at)
        VALUES (buying_cat, 'WTB Dragon Scale x50 - Paying 500g each', user2_id, NOW() - INTERVAL '3 days')
        RETURNING id INTO thread_id;
        
        INSERT INTO forum.posts (thread_id, author_id, content, created_at) VALUES
        (thread_id, user2_id, 'Looking to buy Dragon Scales for crafting. Need 50 total, paying 500 gold each (25k total).

PM me in-game: MysticMage

Can also trade XP boost scrolls if you prefer.', NOW() - INTERVAL '3 days'),
        (thread_id, user3_id, 'I have 20 scales. Will PM you tonight.', NOW() - INTERVAL '3 days' + INTERVAL '2 hours'),
        (thread_id, user2_id, 'Sounds good!', NOW() - INTERVAL '3 days' + INTERVAL '3 hours');

        -- Thread 6: Selling post
        INSERT INTO forum.threads (category_id, title, author_id, created_at)
        VALUES (selling_cat, 'Selling Legendary Staff of Flames - 150k', user1_id, NOW() - INTERVAL '6 hours')
        RETURNING id INTO thread_id;
        
        INSERT INTO forum.posts (thread_id, author_id, content, created_at) VALUES
        (thread_id, user1_id, 'Got a duplicate legendary drop, selling my extra.

**Legendary Staff of Flames**
- +250 Magic Attack
- +15% Fire Damage
- +100 Critical Rating

Price: 150,000 gold (negotiable)

Whisper DragonSlayer in-game or reply here.', NOW() - INTERVAL '6 hours'),
        (thread_id, user2_id, 'Would you take 120k?', NOW() - INTERVAL '4 hours'),
        (thread_id, user1_id, 'Meet me at 135k and it''s yours.', NOW() - INTERVAL '3 hours');

        RAISE NOTICE 'Seeded forum threads and posts successfully!';
    ELSE
        RAISE NOTICE 'Forum threads already exist, skipping.';
    END IF;
END $$;
