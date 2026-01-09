-- Seed Forum Categories
-- Run this to set up forum category structure

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
