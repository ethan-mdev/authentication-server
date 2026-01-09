-- Seed Store Items
-- Run this to populate the item mall

DO $$
DECLARE
    -- Item IDs
    shadow_cloak_id INTEGER;
    golden_armor_id INTEGER;
    phoenix_wings_id INTEGER;
    frost_knight_id INTEGER;
    xp_boost_1h_id INTEGER;
    xp_boost_24h_id INTEGER;
    gold_boost_id INTEGER;
    drop_boost_id INTEGER;
    starter_bundle_id INTEGER;
    premium_bundle_id INTEGER;
    ultimate_bundle_id INTEGER;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dashboard.items LIMIT 1) THEN
        -- Insert items
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

        -- Get item IDs for mapping contents
        SELECT id INTO shadow_cloak_id FROM dashboard.items WHERE name = 'Shadow Cloak';
        SELECT id INTO xp_boost_1h_id FROM dashboard.items WHERE name = 'XP Boost (1 Hour)';
        SELECT id INTO xp_boost_24h_id FROM dashboard.items WHERE name = 'XP Boost (24 Hours)';
        SELECT id INTO gold_boost_id FROM dashboard.items WHERE name = 'Gold Boost (1 Hour)';
        SELECT id INTO golden_armor_id FROM dashboard.items WHERE name = 'Golden Armor Set';
        SELECT id INTO phoenix_wings_id FROM dashboard.items WHERE name = 'Phoenix Wings';
        SELECT id INTO starter_bundle_id FROM dashboard.items WHERE name = 'Starter Bundle';
        SELECT id INTO premium_bundle_id FROM dashboard.items WHERE name = 'Premium Bundle';
        SELECT id INTO ultimate_bundle_id FROM dashboard.items WHERE name = 'Ultimate Bundle';

        -- Map items to game goods numbers
        -- NOTE: Replace these game_goods_no values with actual game's item IDs
        
        -- Single items (example mappings - adjust to game)
        INSERT INTO dashboard.item_contents (item_id, game_goods_no, quantity) VALUES
        (shadow_cloak_id, 10013, 1),    -- Shadow Cloak = goodsNo 1001
        (golden_armor_id, 1002, 1),    -- Golden Armor = goodsNo 1002
        (phoenix_wings_id, 1003, 1),   -- Phoenix Wings = goodsNo 1003
        (xp_boost_1h_id, 2001, 1),     -- XP Boost 1h = goodsNo 2001
        (xp_boost_24h_id, 2002, 1),    -- XP Boost 24h = goodsNo 2002
        (gold_boost_id, 2003, 1),      -- Gold Boost = goodsNo 2003
        
        -- Starter Bundle (multiple items)
        (starter_bundle_id, 2001, 1),  -- XP Boost 1h
        (starter_bundle_id, 1001, 1),  -- Shadow Cloak
        
        -- Premium Bundle (multiple items)
        (premium_bundle_id, 10001, 1),  -- XP Boost 24h
        (premium_bundle_id, 10002, 1),  -- Gold Boost
        (premium_bundle_id, 10003, 1),  -- Golden Armor
        
        -- Ultimate Bundle (multiple items)
        (ultimate_bundle_id, 2002, 2),  -- XP Boost 24h x2
        (ultimate_bundle_id, 2003, 2),  -- Gold Boost x2
        (ultimate_bundle_id, 1003, 1);  -- Phoenix Wings

        RAISE NOTICE 'Seeded store items and contents successfully!';
    ELSE
        RAISE NOTICE 'Store items already exist, skipping.';
    END IF;
END $$;
