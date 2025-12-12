-- Seed Data for Forum Categories
-- Run this after init.sql to populate initial categories

-- Generate UUIDs for parent categories (using gen_random_uuid())
DO $$
DECLARE
    announcements_id UUID := gen_random_uuid();
    game_discussion_id UUID := gen_random_uuid();
    trading_id UUID := gen_random_uuid();
BEGIN
    -- Only insert if categories table is empty
    IF NOT EXISTS (SELECT 1 FROM forum.categories LIMIT 1) THEN
        
        -- Parent categories
        INSERT INTO forum.categories (id, name, description, image, slug, is_locked, parent_id) VALUES
        (announcements_id::TEXT, 'Announcements', 'Official updates and important information.', '/assets/announcements.png', NULL, false, NULL),
        (game_discussion_id::TEXT, 'Game Discussion', 'General gameplay topics and strategies.', '/assets/gamediscussion.png', NULL, false, NULL),
        (trading_id::TEXT, 'Trading & Economy', 'Buy, sell, and trade in-game items.', '/assets/trading.png', NULL, false, NULL);

        -- Subcategories
        INSERT INTO forum.categories (id, name, description, image, slug, is_locked, parent_id) VALUES
        (gen_random_uuid()::TEXT, 'Server Updates', 'Latest server patches and updates.', NULL, 'updates-patches', false, announcements_id::TEXT),
        (gen_random_uuid()::TEXT, 'Events', 'Upcoming and ongoing events.', NULL, 'events', false, announcements_id::TEXT),
        (gen_random_uuid()::TEXT, 'General Discussion', 'Talk about anything game related.', NULL, 'general-discussion', true, game_discussion_id::TEXT),
        (gen_random_uuid()::TEXT, 'Strategies & Guides', 'Share your best strategies and tips.', NULL, 'strategies-guides', false, game_discussion_id::TEXT),
        (gen_random_uuid()::TEXT, 'Buying', 'Looking to purchase items or services.', NULL, 'buying', false, trading_id::TEXT),
        (gen_random_uuid()::TEXT, 'Selling', 'List items or services for sale.', NULL, 'selling', false, trading_id::TEXT);

        RAISE NOTICE 'Seeded forum categories successfully!';
    ELSE
        RAISE NOTICE 'Categories already exist, skipping seed.';
    END IF;
END $$;
