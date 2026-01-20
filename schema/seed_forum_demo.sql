-- Seed Demo Forum Posts and Users
-- Run this to populate the forum with demo content
-- These are demo users that don't need to be signable (no valid passwords)

DO $$
DECLARE
    -- Demo user IDs
    admin_id UUID := gen_random_uuid();
    mod_id UUID := gen_random_uuid();
    user1_id UUID := gen_random_uuid();
    user2_id UUID := gen_random_uuid();
    user3_id UUID := gen_random_uuid();
    user4_id UUID := gen_random_uuid();
    user5_id UUID := gen_random_uuid();
    
    -- Category IDs (fetch from existing categories)
    updates_cat TEXT;
    events_cat TEXT;
    general_cat TEXT;
    guides_cat TEXT;
    buying_cat TEXT;
    selling_cat TEXT;
    
    -- Thread IDs
    welcome_thread INTEGER;
    update_thread INTEGER;
    event_thread INTEGER;
    general_thread1 INTEGER;
    general_thread2 INTEGER;
    guide_thread INTEGER;
    buying_thread INTEGER;
    selling_thread INTEGER;
    
    -- Badge IDs
    beta_badge INTEGER;
    vip_badge INTEGER;
    supporter_badge INTEGER;
    dev_badge INTEGER;
    mod_badge INTEGER;
    creator_badge INTEGER;
BEGIN
    -- Only seed if demo users don't already exist
    IF NOT EXISTS (SELECT 1 FROM public.users WHERE username = 'GameMaster' LIMIT 1) THEN
        
        -- ============================================
        -- CREATE DEMO USERS
        -- ============================================
        -- These use invalid password hashes so they can't be logged into
        INSERT INTO public.users (id, username, email, password, role, profile_image, balance, created_at) VALUES
        (admin_id::TEXT, 'GameMaster', 'demo-gm@example.com', 'DEMO_INVALID_HASH', 'admin', 'avatar-5.png', 50000, NOW() - INTERVAL '180 days'),
        (mod_id::TEXT, 'CommunityMod', 'demo-mod@example.com', 'DEMO_INVALID_HASH', 'user', 'avatar-3.png', 25000, NOW() - INTERVAL '150 days'),
        (user1_id::TEXT, 'DragonSlayer99', 'demo-user1@example.com', 'DEMO_INVALID_HASH', 'user', 'avatar-2.png', 12500, NOW() - INTERVAL '120 days'),
        (user2_id::TEXT, 'MagicMaster', 'demo-user2@example.com', 'DEMO_INVALID_HASH', 'user', 'avatar-4.png', 8000, NOW() - INTERVAL '90 days'),
        (user3_id::TEXT, 'TradingKing', 'demo-user3@example.com', 'DEMO_INVALID_HASH', 'user', 'avatar-7.png', 45000, NOW() - INTERVAL '60 days'),
        (user4_id::TEXT, 'NewbieHelper', 'demo-user4@example.com', 'DEMO_INVALID_HASH', 'user', 'avatar-6.png', 3500, NOW() - INTERVAL '45 days'),
        (user5_id::TEXT, 'PvPChampion', 'demo-user5@example.com', 'DEMO_INVALID_HASH', 'user', 'avatar-8.png', 18000, NOW() - INTERVAL '30 days');

        -- ============================================
        -- FETCH CATEGORY IDs
        -- ============================================
        SELECT id INTO updates_cat FROM forum.categories WHERE slug = 'updates-patches' LIMIT 1;
        SELECT id INTO events_cat FROM forum.categories WHERE slug = 'events' LIMIT 1;
        SELECT id INTO general_cat FROM forum.categories WHERE slug = 'general-discussion' LIMIT 1;
        SELECT id INTO guides_cat FROM forum.categories WHERE slug = 'strategies-guides' LIMIT 1;
        SELECT id INTO buying_cat FROM forum.categories WHERE slug = 'buying' LIMIT 1;
        SELECT id INTO selling_cat FROM forum.categories WHERE slug = 'selling' LIMIT 1;

        -- ============================================
        -- FETCH BADGE IDs
        -- ============================================
        SELECT id INTO beta_badge FROM forum.badges WHERE name = 'BETA TESTER' LIMIT 1;
        SELECT id INTO vip_badge FROM forum.badges WHERE name = 'VIP' LIMIT 1;
        SELECT id INTO supporter_badge FROM forum.badges WHERE name = 'SUPPORTER' LIMIT 1;
        SELECT id INTO dev_badge FROM forum.badges WHERE name = 'DEVELOPER' LIMIT 1;
        SELECT id INTO mod_badge FROM forum.badges WHERE name = 'MODERATOR' LIMIT 1;
        SELECT id INTO creator_badge FROM forum.badges WHERE name = 'CONTENT CREATOR' LIMIT 1;

        -- ============================================
        -- ASSIGN BADGES TO DEMO USERS
        -- ============================================
        IF beta_badge IS NOT NULL THEN
            INSERT INTO forum.user_badges (user_id, badge_id) VALUES
            (admin_id::TEXT, beta_badge),
            (user1_id::TEXT, beta_badge),
            (user2_id::TEXT, beta_badge);
        END IF;

        IF dev_badge IS NOT NULL THEN
            INSERT INTO forum.user_badges (user_id, badge_id) VALUES (admin_id::TEXT, dev_badge);
        END IF;

        IF mod_badge IS NOT NULL THEN
            INSERT INTO forum.user_badges (user_id, badge_id) VALUES (mod_id::TEXT, mod_badge);
        END IF;

        IF vip_badge IS NOT NULL THEN
            INSERT INTO forum.user_badges (user_id, badge_id) VALUES
            (user1_id::TEXT, vip_badge),
            (user3_id::TEXT, vip_badge);
        END IF;

        IF supporter_badge IS NOT NULL THEN
            INSERT INTO forum.user_badges (user_id, badge_id) VALUES
            (user2_id::TEXT, supporter_badge),
            (user4_id::TEXT, supporter_badge);
        END IF;

        IF creator_badge IS NOT NULL THEN
            INSERT INTO forum.user_badges (user_id, badge_id) VALUES (user5_id::TEXT, creator_badge);
        END IF;

        -- ============================================
        -- CREATE THREADS AND POSTS
        -- ============================================

        -- WELCOME THREAD (Updates/Announcements)
        IF updates_cat IS NOT NULL THEN
            INSERT INTO forum.threads (category_id, title, author_id, is_sticky, created_at, updated_at, view_count)
            VALUES (updates_cat, 'Welcome to Our Community!', admin_id::TEXT, true, NOW() - INTERVAL '180 days', NOW() - INTERVAL '5 days', 2847)
            RETURNING id INTO welcome_thread;

            INSERT INTO forum.posts (thread_id, author_id, content, created_at) VALUES
            (welcome_thread, admin_id::TEXT, E'[color=#ffd700][b]Welcome to the Official Community Forum![/b][/color]\n\nHey everyone! 👋\n\nWe''re thrilled to have you here in our growing community. This forum is your place to:\n\n• Share your adventures and achievements\n• Get help from experienced players\n• Trade items and find party members\n• Stay updated on the latest news and events\n• Connect with fellow players\n\n[b]Forum Rules:[/b]\n1. Be respectful to all members\n2. No spam or advertising\n3. Keep discussions on-topic\n4. Use the search function before posting\n5. Have fun and help each other!\n\nIf you have any questions, feel free to reach out to our moderation team. Happy posting!\n\n[color=#00ff00]- The Team[/color]', NOW() - INTERVAL '180 days'),
            
            (welcome_thread, user1_id::TEXT, 'Thanks for the warm welcome! Excited to be part of this community! 🎮', NOW() - INTERVAL '179 days'),
            
            (welcome_thread, user2_id::TEXT, E'This looks like a great place to hang out! Quick question - where should I post if I''m looking for a guild?', NOW() - INTERVAL '178 days'),
            
            (welcome_thread, mod_id::TEXT, E'@MagicMaster You can post in the General Discussion section or wait for our Guild Recruitment subforum coming soon! 😊', NOW() - INTERVAL '178 days'),
            
            (welcome_thread, user4_id::TEXT, 'Glad to be here! Looking forward to learning from everyone! 🚀', NOW() - INTERVAL '5 days');

            -- Add reactions to welcome thread posts
            INSERT INTO forum.post_reactions (post_id, user_id, reaction_type, created_at) VALUES
            ((SELECT id FROM forum.posts WHERE thread_id = welcome_thread ORDER BY id LIMIT 1), user1_id::TEXT, 'heart', NOW() - INTERVAL '179 days'),
            ((SELECT id FROM forum.posts WHERE thread_id = welcome_thread ORDER BY id LIMIT 1), user2_id::TEXT, 'like', NOW() - INTERVAL '178 days'),
            ((SELECT id FROM forum.posts WHERE thread_id = welcome_thread ORDER BY id LIMIT 1), user3_id::TEXT, 'celebrate', NOW() - INTERVAL '177 days'),
            ((SELECT id FROM forum.posts WHERE thread_id = welcome_thread ORDER BY id OFFSET 1 LIMIT 1), admin_id::TEXT, 'like', NOW() - INTERVAL '179 days');
        END IF;

        -- SERVER UPDATE THREAD
        IF updates_cat IS NOT NULL THEN
            INSERT INTO forum.threads (category_id, title, author_id, is_sticky, created_at, updated_at, view_count)
            VALUES (updates_cat, 'Version 2.4.0 - New Content Update!', admin_id::TEXT, true, NOW() - INTERVAL '14 days', NOW() - INTERVAL '2 days', 5421)
            RETURNING id INTO update_thread;

            INSERT INTO forum.posts (thread_id, author_id, content, created_at) VALUES
            (update_thread, admin_id::TEXT, E'[b][color=#ff6600]🎉 Version 2.4.0 is Now Live! 🎉[/color][/b]\n\n[b]New Features:[/b]\n• New dungeon: [b]Crimson Fortress[/b] (Level 85+)\n• 15 new legendary items\n• Pet system overhaul with new evolution mechanics\n• Guild vs Guild tournament system\n• Quality of life improvements\n\n[b]Balance Changes:[/b]\n• Warrior: Shield Bash damage increased by 15%\n• Mage: Fireball mana cost reduced by 10%\n• Rogue: Critical strike chance cap increased to 45%\n\n[b]Bug Fixes:[/b]\n• Fixed inventory duplication exploit\n• Resolved party invite issues\n• Fixed quest marker disappearing bug\n\nFull patch notes: [url]https://example.com/patch-2.4.0[/url]\n\nEnjoy the update! 🎮', NOW() - INTERVAL '14 days'),
            
            (update_thread, user1_id::TEXT, E'Finally! The warrior buffs we''ve been waiting for! Time to dominate PvP again! 💪', NOW() - INTERVAL '14 days'),
            
            (update_thread, user5_id::TEXT, 'That new dungeon looks insane! Anyone want to form a party later? Need tank and healer!', NOW() - INTERVAL '14 days'),
            
            (update_thread, user2_id::TEXT, E'The pet evolution system is AMAZING! Just evolved my dragon and it''s so much stronger now! 🐉', NOW() - INTERVAL '13 days'),
            
            (update_thread, user3_id::TEXT, E'Great update but anyone else experiencing lag in the new dungeon? My FPS drops to 20 in certain areas...', NOW() - INTERVAL '12 days'),
            
            (update_thread, mod_id::TEXT, E'@TradingKing We''re aware of some performance issues and the dev team is working on a hotfix. Should be out within 24-48 hours!', NOW() - INTERVAL '12 days'),
            
            (update_thread, user3_id::TEXT, 'Thanks for the quick response! Looking forward to the hotfix. 👍', NOW() - INTERVAL '12 days'),
            
            (update_thread, user4_id::TEXT, E'Is the new dungeon soloable or do you need a full party? I''m still learning the game!', NOW() - INTERVAL '2 days'),
            
            (update_thread, user1_id::TEXT, E'@NewbieHelper You''ll definitely need a party of at least 3-4 players for Crimson Fortress. Feel free to add me in-game and I can help you run it!', NOW() - INTERVAL '2 days');

            -- Add reactions
            INSERT INTO forum.post_reactions (post_id, user_id, reaction_type, created_at) VALUES
            ((SELECT id FROM forum.posts WHERE thread_id = update_thread ORDER BY id LIMIT 1), user1_id::TEXT, 'celebrate', NOW() - INTERVAL '14 days'),
            ((SELECT id FROM forum.posts WHERE thread_id = update_thread ORDER BY id LIMIT 1), user2_id::TEXT, 'heart', NOW() - INTERVAL '14 days'),
            ((SELECT id FROM forum.posts WHERE thread_id = update_thread ORDER BY id LIMIT 1), user5_id::TEXT, 'wow', NOW() - INTERVAL '14 days'),
            ((SELECT id FROM forum.posts WHERE thread_id = update_thread ORDER BY id OFFSET 2 LIMIT 1), user1_id::TEXT, 'like', NOW() - INTERVAL '14 days');
        END IF;

        -- EVENT THREAD
        IF events_cat IS NOT NULL THEN
            INSERT INTO forum.threads (category_id, title, author_id, is_sticky, created_at, updated_at, view_count)
            VALUES (events_cat, '🎃 Halloween Event 2026 - Double XP Weekend!', admin_id::TEXT, true, NOW() - INTERVAL '7 days', NOW() - INTERVAL '1 day', 3892)
            RETURNING id INTO event_thread;

            INSERT INTO forum.posts (thread_id, author_id, content, created_at) VALUES
            (event_thread, admin_id::TEXT, E'[color=#ff8c00][b]🎃 HALLOWEEN EVENT IS HERE! 🎃[/b][/color]\n\n[b]Event Duration:[/b]\nOctober 25th - November 1st\n\n[b]Special Features:[/b]\n• [b]Double XP[/b] all weekend (Oct 26-27)\n• Spooky boss spawns every 2 hours in all major zones\n• Exclusive [b]Pumpkin King[/b] mount (rare drop)\n• Halloween-themed cosmetics in the shop\n• Special quests with unique rewards\n\n[b]Boss Schedule:[/b]\nThe [b]Headless Horror[/b] will spawn at:\n- 12:00 PM\n- 2:00 PM\n- 4:00 PM\n- 6:00 PM\n- 8:00 PM\n- 10:00 PM\n(Server time - EST)\n\n[b]Rewards:[/b]\n• Pumpkin King Mount (0.5% drop rate)\n• Spooky Armor Set (5% drop rate)\n• Halloween Weapon Skins (10% drop rate)\n• Candy Currency (guaranteed - use in event shop)\n\nGood luck hunters! 🎃👻', NOW() - INTERVAL '7 days'),
            
            (event_thread, user5_id::TEXT, E'YES! Finally a reason to grind this weekend! That mount looks sick! 🎃', NOW() - INTERVAL '7 days' + INTERVAL '5 minutes'),
            
            (event_thread, user2_id::TEXT, E'The boss spawns look fun! Should we organize raid groups here or in-game?', NOW() - INTERVAL '7 days' + INTERVAL '30 minutes'),
            
            (event_thread, mod_id::TEXT, 'Feel free to organize here! We can create a separate thread for boss raid groups if there''s enough interest. 😊', NOW() - INTERVAL '6 days'),
            
            (event_thread, user1_id::TEXT, E'Just got the armor set! Took about 15 boss kills but totally worth it! The stats are insane! 💪', NOW() - INTERVAL '5 days'),
            
            (event_thread, user3_id::TEXT, E'Anyone selling candy currency? I missed a few days and want to buy everything from the shop...', NOW() - INTERVAL '3 days'),
            
            (event_thread, user4_id::TEXT, E'This is my first event and I''m having a blast! The community has been so helpful with the boss fights! Thanks everyone! 🙏', NOW() - INTERVAL '1 day');

            -- Add reactions
            INSERT INTO forum.post_reactions (post_id, user_id, reaction_type, created_at) VALUES
            ((SELECT id FROM forum.posts WHERE thread_id = event_thread ORDER BY id LIMIT 1), user1_id::TEXT, 'celebrate', NOW() - INTERVAL '7 days'),
            ((SELECT id FROM forum.posts WHERE thread_id = event_thread ORDER BY id LIMIT 1), user5_id::TEXT, 'wow', NOW() - INTERVAL '7 days'),
            ((SELECT id FROM forum.posts WHERE thread_id = event_thread ORDER BY id OFFSET 4 LIMIT 1), user2_id::TEXT, 'celebrate', NOW() - INTERVAL '5 days'),
            ((SELECT id FROM forum.posts WHERE thread_id = event_thread ORDER BY id OFFSET 4 LIMIT 1), user5_id::TEXT, 'like', NOW() - INTERVAL '5 days');
        END IF;

        -- GENERAL DISCUSSION THREAD 1
        IF general_cat IS NOT NULL THEN
            INSERT INTO forum.threads (category_id, title, author_id, created_at, updated_at, view_count)
            VALUES (general_cat, 'What''s your favorite class and why?', user2_id::TEXT, NOW() - INTERVAL '20 days', NOW() - INTERVAL '8 days', 1847)
            RETURNING id INTO general_thread1;

            INSERT INTO forum.posts (thread_id, author_id, content, created_at) VALUES
            (general_thread1, user2_id::TEXT, E'Hey everyone! 👋\n\nI''ve been playing for a few months now and I''m curious - what''s your favorite class to play and why?\n\nPersonally, I love playing Mage because of the spell variety and the massive AoE damage in dungeons. The glass cannon playstyle is risky but so rewarding! 🔥⚡\n\nWhat about you all?', NOW() - INTERVAL '20 days'),
            
            (general_thread1, user1_id::TEXT, E'Warrior all the way! 💪\n\nI love being the frontline tank, protecting my party and soaking up damage. Plus, the new shield bash buffs made us even more viable in PvP. Nothing beats the feeling of an epic shield block saving your team!', NOW() - INTERVAL '20 days'),
            
            (general_thread1, user5_id::TEXT, E'Rogue for life! 🗡️\n\nThe mobility and burst damage is unmatched. Sneaking up on enemies in PvP and taking them out before they can react never gets old. Plus, the high skill ceiling keeps things interesting!\n\nPros: High damage, great mobility, fun rotation\nCons: Squishy, requires good positioning', NOW() - INTERVAL '19 days'),
            
            (general_thread1, user4_id::TEXT, E'I''m still trying to decide! I''ve been playing Priest as my first character because I heard support classes are always needed. It''s fun keeping everyone alive but sometimes I wish I could deal more damage...\n\nMaybe I should try DPS next?', NOW() - INTERVAL '18 days'),
            
            (general_thread1, user1_id::TEXT, E'@NewbieHelper Priest is a great choice! Support classes are always in demand for parties and raids. But if you want more damage, you could always create an alt character to try DPS without abandoning your main. 😊', NOW() - INTERVAL '18 days'),
            
            (general_thread1, user3_id::TEXT, E'I main Ranger and it''s perfect for me. Good balance of damage and utility, plus the ranged playstyle means I can avoid most mechanics in boss fights lol 🏹\n\nThe pet system is great too - having a companion makes solo content much easier!', NOW() - INTERVAL '8 days');

            -- Add reactions
            INSERT INTO forum.post_reactions (post_id, user_id, reaction_type, created_at) VALUES
            ((SELECT id FROM forum.posts WHERE thread_id = general_thread1 ORDER BY id OFFSET 1 LIMIT 1), user2_id::TEXT, 'like', NOW() - INTERVAL '20 days'),
            ((SELECT id FROM forum.posts WHERE thread_id = general_thread1 ORDER BY id OFFSET 2 LIMIT 1), user1_id::TEXT, 'celebrate', NOW() - INTERVAL '19 days'),
            ((SELECT id FROM forum.posts WHERE thread_id = general_thread1 ORDER BY id OFFSET 3 LIMIT 1), user1_id::TEXT, 'heart', NOW() - INTERVAL '18 days');
        END IF;

        -- GENERAL DISCUSSION THREAD 2
        IF general_cat IS NOT NULL THEN
            INSERT INTO forum.threads (category_id, title, author_id, created_at, updated_at, view_count)
            VALUES (general_cat, 'Best farming spots for gold?', user4_id::TEXT, NOW() - INTERVAL '5 days', NOW() - INTERVAL '3 hours', 892)
            RETURNING id INTO general_thread2;

            INSERT INTO forum.posts (thread_id, author_id, content, created_at) VALUES
            (general_thread2, user4_id::TEXT, E'Hi friends! 👋\n\nI''m trying to save up for some new gear but gold farming is taking forever. Where are the best spots to farm gold efficiently?\n\nI''m level 65 if that matters. Thanks in advance!', NOW() - INTERVAL '5 days'),
            
            (general_thread2, user3_id::TEXT, E'At level 65, here are your best options:\n\n[b]1. Shadowfen Swamp[/b] - Mobs drop decent gold and the spawn rate is high\n[b]2. Crystal Caves[/b] - Lower gold but gems sell well on marketplace\n[b]3. Daily Quests[/b] - Don''t skip these! Easy 5-10k gold per day\n\nAlso, consider farming materials and selling them rather than just grinding mobs. Herbs and ores are in high demand! 💰', NOW() - INTERVAL '5 days'),
            
            (general_thread2, user1_id::TEXT, E'Great advice from TradingKing! 👍\n\nI''d also add: join dungeon runs if you can. The boss drops can be worth 50k+ if you''re lucky. Plus you get gear that you can either use or sell!', NOW() - INTERVAL '4 days'),
            
            (general_thread2, user2_id::TEXT, E'Pro tip: Use the double XP weekends to farm! You level up faster which means better farming spots unlock sooner. Also, higher level mobs = more gold per kill. 🎮', NOW() - INTERVAL '4 days'),
            
            (general_thread2, user4_id::TEXT, E'Wow, thank you all so much! This is super helpful! I''ll try Shadowfen Swamp tonight. Appreciate the advice! 🙏', NOW() - INTERVAL '3 days'),
            
            (general_thread2, user5_id::TEXT, E'If you want to min-max, there''s a route in Shadowfen that lets you chain pull 15-20 mobs at once. I can share the map coordinates if you want! Makes farming way faster. ⚡', NOW() - INTERVAL '3 hours');

            -- Add reactions
            INSERT INTO forum.post_reactions (post_id, user_id, reaction_type, created_at) VALUES
            ((SELECT id FROM forum.posts WHERE thread_id = general_thread2 ORDER BY id OFFSET 1 LIMIT 1), user4_id::TEXT, 'heart', NOW() - INTERVAL '5 days'),
            ((SELECT id FROM forum.posts WHERE thread_id = general_thread2 ORDER BY id OFFSET 1 LIMIT 1), user1_id::TEXT, 'like', NOW() - INTERVAL '5 days'),
            ((SELECT id FROM forum.posts WHERE thread_id = general_thread2 ORDER BY id OFFSET 4 LIMIT 1), user1_id::TEXT, 'like', NOW() - INTERVAL '3 days');
        END IF;

        -- GUIDE THREAD
        IF guides_cat IS NOT NULL THEN
            INSERT INTO forum.threads (category_id, title, author_id, created_at, updated_at, view_count)
            VALUES (guides_cat, '[GUIDE] Beginner''s Guide to Crimson Fortress', user1_id::TEXT, NOW() - INTERVAL '10 days', NOW() - INTERVAL '6 days', 4256)
            RETURNING id INTO guide_thread;

            INSERT INTO forum.posts (thread_id, author_id, content, created_at) VALUES
            (guide_thread, user1_id::TEXT, E'[b][color=#ff0000]🏰 Crimson Fortress - Complete Beginner Guide 🏰[/color][/b]\n\n[b]Requirements:[/b]\n• Level 85+\n• Recommended iLevel: 350+\n• Party Size: 4-6 players\n• Duration: 45-60 minutes\n\n[b]Party Composition:[/b]\nIdeal setup:\n• 1-2 Tanks\n• 1-2 Healers\n• 2-3 DPS\n\n[b]Boss 1: Crimson Knight[/b]\n\n[b]Mechanics:[/b]\n• [b]Flame Slash[/b] - Frontal cone attack. Tank should face boss away from party.\n• [b]Crimson Charge[/b] - Boss charges at random player. Dodge by moving sideways.\n• [b]Sword Spin[/b] - 360° AoE. Everyone should back away when boss raises sword.\n\n[b]Strategy:[/b]\nPretty straightforward boss. Keep tank alive, DPS from behind, dodge the obvious attacks. Good warmup for the dungeon!\n\n[b]Boss 2: Twin Sorcerers[/b]\n\n[b]Mechanics:[/b]\n• [b]Lightning Bolt[/b] - Random target, interruptible\n• [b]Fire Prison[/b] - Traps player in circle, party must break them out\n• [b]Twin Resonance[/b] - If bosses are close together, they buff each other. Keep them separated!\n\n[b]Strategy:[/b]\nThis is where coordination matters. Assign one tank to each boss and keep them far apart. When someone gets trapped in Fire Prison, ALL DPS should switch to breaking them out immediately. Don''t let them channel Lightning Bolt - always interrupt!\n\n[b]Boss 3: The Crimson Lord (Final Boss)[/b]\n\n[b]Mechanics:[/b]\n• [b]Shadow Realm[/b] - At 75%, 50%, and 25% HP, boss pulls everyone to shadow realm\n• [b]Blood Orbs[/b] - Collect these in shadow realm or raid wipes\n• [b]Crimson Beam[/b] - Line attack, dodge sideways\n• [b]Add Spawns[/b] - Small minions spawn every 30 seconds, kill quickly\n\n[b]Strategy:[/b]\nThis is the DPS check. When pulled to shadow realm, collect ALL blood orbs before timer expires. Back in main realm, kill adds ASAP while dodging beams. At 10% HP boss goes berserk, so save cooldowns for final burn phase.\n\n[b]Recommended Loot:[/b]\n• [b]Crimson Blade[/b] (Sword) - Best in slot for Warriors\n• [b]Staff of the Fortress[/b] (Staff) - Best in slot for Mages\n• [b]Shadow Cloak[/b] (Back) - Great for all classes\n• [b]Lord''s Ring[/b] (Ring) - +50 all stats\n\nGood luck everyone! Feel free to ask questions below! 🎮', NOW() - INTERVAL '10 days'),
            
            (guide_thread, user4_id::TEXT, E'This is exactly what I needed! Thank you so much for taking the time to write this! 🙏', NOW() - INTERVAL '10 days'),
            
            (guide_thread, user2_id::TEXT, E'Great guide! One thing to add: Mages should save their AoE for the add spawns in phase 3. Makes the fight much easier! 🔥', NOW() - INTERVAL '9 days'),
            
            (guide_thread, user5_id::TEXT, E'Can confirm this strat works! Just cleared it with my guild following this guide. Twin Sorcerers were tough but we got it after a few tries! 💪', NOW() - INTERVAL '8 days'),
            
            (guide_thread, user3_id::TEXT, E'Question: What''s the best way to handle the shadow realm phase? Do we split up or stick together for the blood orbs?', NOW() - INTERVAL '7 days'),
            
            (guide_thread, user1_id::TEXT, E'@TradingKing Good question! Stick together as a group and move in a circle pattern. The orbs spawn predictably so you can collect them efficiently. Don''t split up or you might miss some!', NOW() - INTERVAL '7 days'),
            
            (guide_thread, mod_id::TEXT, E'Excellent guide @DragonSlayer99! I''m going to pin this for visibility. Great contribution to the community! 👏', NOW() - INTERVAL '6 days');

            -- Add reactions
            INSERT INTO forum.post_reactions (post_id, user_id, reaction_type, created_at) VALUES
            ((SELECT id FROM forum.posts WHERE thread_id = guide_thread ORDER BY id LIMIT 1), user4_id::TEXT, 'heart', NOW() - INTERVAL '10 days'),
            ((SELECT id FROM forum.posts WHERE thread_id = guide_thread ORDER BY id LIMIT 1), user2_id::TEXT, 'celebrate', NOW() - INTERVAL '10 days'),
            ((SELECT id FROM forum.posts WHERE thread_id = guide_thread ORDER BY id LIMIT 1), user5_id::TEXT, 'like', NOW() - INTERVAL '10 days'),
            ((SELECT id FROM forum.posts WHERE thread_id = guide_thread ORDER BY id LIMIT 1), mod_id::TEXT, 'heart', NOW() - INTERVAL '6 days');
        END IF;

        -- BUYING THREAD
        IF buying_cat IS NOT NULL THEN
            INSERT INTO forum.threads (category_id, title, author_id, created_at, updated_at, view_count)
            VALUES (buying_cat, '[WTB] Shadow Cloak +10 or higher', user2_id::TEXT, NOW() - INTERVAL '3 days', NOW() - INTERVAL '1 day', 234)
            RETURNING id INTO buying_thread;

            INSERT INTO forum.posts (thread_id, author_id, content, created_at) VALUES
            (buying_thread, user2_id::TEXT, E'[b]Buying:[/b] Shadow Cloak +10 or better\n[b]Offering:[/b] 150k gold or trade\n\nI have these items for trade:\n• Crimson Blade +8\n• Staff of the Fortress +7\n• 50x Superior Health Potions\n\nContact me in-game: MagicMaster\nOr reply here! 💰', NOW() - INTERVAL '3 days'),
            
            (buying_thread, user3_id::TEXT, E'I have a Shadow Cloak +11 but looking for 180k. Let me know if interested!', NOW() - INTERVAL '2 days'),
            
            (buying_thread, user2_id::TEXT, E'@TradingKing Would you take 165k + 20 potions?', NOW() - INTERVAL '2 days'),
            
            (buying_thread, user3_id::TEXT, E'Deal! I''ll be online tonight around 8pm EST. Send me a message when you''re on! 👍', NOW() - INTERVAL '1 day');

            -- Add reactions
            INSERT INTO forum.post_reactions (post_id, user_id, reaction_type, created_at) VALUES
            ((SELECT id FROM forum.posts WHERE thread_id = buying_thread ORDER BY id OFFSET 3 LIMIT 1), user2_id::TEXT, 'celebrate', NOW() - INTERVAL '1 day');
        END IF;

        -- SELLING THREAD
        IF selling_cat IS NOT NULL THEN
            INSERT INTO forum.threads (category_id, title, author_id, created_at, updated_at, view_count)
            VALUES (selling_cat, '[WTS] Event Items & Rare Drops - Updated Daily!', user3_id::TEXT, NOW() - INTERVAL '15 days', NOW() - INTERVAL '4 hours', 3128)
            RETURNING id INTO selling_thread;

            INSERT INTO forum.posts (thread_id, author_id, content, created_at) VALUES
            (selling_thread, user3_id::TEXT, E'[b][color=#ffd700]💎 TradingKing''s Item Shop 💎[/color][/b]\n\n[b]Currently In Stock:[/b]\n\n[b]Weapons:[/b]\n• Crimson Blade +12 - 300k\n• Staff of Elements +10 - 250k\n• Dragon Bow +11 - 280k\n\n[b]Armor:[/b]\n• Full Legendary Set (iLevel 370) - 800k\n• Shadow Cloak +13 - 200k\n• Titanium Shield +10 - 150k\n\n[b]Materials:[/b]\n• Dragon Scales x50 - 50k\n• Rare Herbs x100 - 25k\n• Enhancement Stones x20 - 100k\n\n[b]Event Items:[/b]\n• Halloween Armor Set - 400k\n• Pumpkin King Mount - SOLD OUT\n• Spooky Weapon Skins - 75k each\n\n[b]Payment Options:[/b]\n• Gold (preferred)\n• Trade for items I need\n• Combination of both\n\n[b]Contact:[/b]\nReply here or message me in-game: TradingKing\nOnline daily 6pm-11pm EST\n\nBulk discounts available! 💰', NOW() - INTERVAL '15 days'),
            
            (selling_thread, user5_id::TEXT, E'Do you have any more Pumpkin King mounts coming in stock? I''ll pay premium! 🎃', NOW() - INTERVAL '14 days'),
            
            (selling_thread, user3_id::TEXT, E'@PvPChampion Sorry, those sold out fast! I''m farming for more but the drop rate is brutal. If I get another one, you''re first on the list!', NOW() - INTERVAL '14 days'),
            
            (selling_thread, user1_id::TEXT, E'Interested in the Dragon Bow +11. Would you take 250k + some rare materials?', NOW() - INTERVAL '10 days'),
            
            (selling_thread, user3_id::TEXT, E'@DragonSlayer99 What materials do you have? I''m always looking for Dragon Scales and Enhancement Stones!', NOW() - INTERVAL '10 days'),
            
            (selling_thread, user1_id::TEXT, E'I have 30 Dragon Scales and 10 Enhancement Stones. Would that work with 200k gold?', NOW() - INTERVAL '9 days'),
            
            (selling_thread, user3_id::TEXT, E'Perfect! That works for me. I''ll hold the bow for you. Message me when you''re online! ✅', NOW() - INTERVAL '9 days'),
            
            (selling_thread, user4_id::TEXT, E'What''s the cheapest way to get started with decent gear? I only have about 100k gold saved up...', NOW() - INTERVAL '4 hours'),
            
            (selling_thread, user3_id::TEXT, E'@NewbieHelper For 100k I can put together a starter set! Let me know your class and I''ll make you a custom bundle. I remember being new too - happy to help! 😊', NOW() - INTERVAL '4 hours');

            -- Add reactions
            INSERT INTO forum.post_reactions (post_id, user_id, reaction_type, created_at) VALUES
            ((SELECT id FROM forum.posts WHERE thread_id = selling_thread ORDER BY id LIMIT 1), user1_id::TEXT, 'like', NOW() - INTERVAL '15 days'),
            ((SELECT id FROM forum.posts WHERE thread_id = selling_thread ORDER BY id OFFSET 6 LIMIT 1), user1_id::TEXT, 'celebrate', NOW() - INTERVAL '9 days'),
            ((SELECT id FROM forum.posts WHERE thread_id = selling_thread ORDER BY id OFFSET 8 LIMIT 1), user4_id::TEXT, 'heart', NOW() - INTERVAL '4 hours');
        END IF;

        RAISE NOTICE 'Successfully seeded demo forum posts and users!';
        RAISE NOTICE 'Created % demo users', 7;
        RAISE NOTICE 'Created % threads with multiple posts', 8;
        RAISE NOTICE 'Note: Demo users cannot be logged into (invalid passwords)';
    ELSE
        RAISE NOTICE 'Demo users already exist, skipping demo seed.';
    END IF;
END $$;
