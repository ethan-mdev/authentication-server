-- Example Badges (using CSS styles for dynamic colors/animations)
INSERT INTO forum.badges (name, bg_color, text_color) VALUES
('BETA TESTER', 'background: rgba(168, 85, 247, 0.2)', 'color: #c084fc'),
('VIP', 'background: linear-gradient(to right, #fbbf24, #f97316)', 'color: #000; font-weight: 700'),
('SUPPORTER', 'background: linear-gradient(to right, #3b82f6, #06b6d4)', 'color: #fff'),
('DEVELOPER', 'background: linear-gradient(to right, #ec4899, #a855f7)', 'color: #fff; font-weight: 700'),
('MODERATOR', 'background: linear-gradient(to right, #ef4444, #f97316)', 'color: #fff'),
('CONTENT CREATOR', 'background: linear-gradient(to right, #a855f7, #ec4899)', 'color: #fff'),
('EVENT WINNER', 'background: linear-gradient(to right, #10b981, #22c55e)', 'color: #fff')
ON CONFLICT (name) DO NOTHING;