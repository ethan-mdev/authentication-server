-- Seed vouchers for testing
-- Database: postgres (dashboard schema)

-- Insert sample vouchers
INSERT INTO dashboard.vouchers (code, description, max_total_redemptions) VALUES
('WELCOME2024', 'Welcome package with starter items', NULL), -- Unlimited uses (one per user)
('FREEGOLD100', '100 gold coins voucher', 100), -- First 100 users only
('MEGABUNDLE', 'Mega bundle with multiple premium items', 1), -- Only 1 user total can redeem
('TESTCODE123', 'Test voucher for development', 50) -- First 50 users
ON CONFLICT (code) DO NOTHING;

-- Insert voucher contents (mapping to game goods)

-- WELCOME2024: Starter package
INSERT INTO dashboard.voucher_contents (voucher_id, game_goods_no, quantity)
SELECT v.id, 10001, 1 FROM dashboard.vouchers v WHERE v.code = 'WELCOME2024'
UNION ALL
SELECT v.id, 10002, 5 FROM dashboard.vouchers v WHERE v.code = 'WELCOME2024'
UNION ALL
SELECT v.id, 10003, 3 FROM dashboard.vouchers v WHERE v.code = 'WELCOME2024'
ON CONFLICT DO NOTHING;

-- FREEGOLD100: Single gold item
INSERT INTO dashboard.voucher_contents (voucher_id, game_goods_no, quantity)
SELECT v.id, 10001, 100 FROM dashboard.vouchers v WHERE v.code = 'FREEGOLD100'
ON CONFLICT DO NOTHING;

-- MEGABUNDLE: Multiple premium items
INSERT INTO dashboard.voucher_contents (voucher_id, game_goods_no, quantity)
SELECT v.id, 10001, 1 FROM dashboard.vouchers v WHERE v.code = 'MEGABUNDLE'
UNION ALL
SELECT v.id, 10002, 1 FROM dashboard.vouchers v WHERE v.code = 'MEGABUNDLE'
UNION ALL
SELECT v.id, 10003, 10 FROM dashboard.vouchers v WHERE v.code = 'MEGABUNDLE'
UNION ALL
SELECT v.id, 10004, 5 FROM dashboard.vouchers v WHERE v.code = 'MEGABUNDLE'
ON CONFLICT DO NOTHING;

-- TESTCODE123: Single test item
INSERT INTO dashboard.voucher_contents (voucher_id, game_goods_no, quantity)
SELECT v.id, 10001, 1 FROM dashboard.vouchers v WHERE v.code = 'TESTCODE123'
ON CONFLICT DO NOTHING;
