-- Example Badges
INSERT INTO forum.badges (name, bg_color, text_color) VALUES
('BETA TESTER', 'bg-purple-500/20', 'text-purple-400'),
('VIP', 'bg-gradient-to-r from-yellow-400 to-orange-500', 'text-black font-bold'),
('SUPPORTER', 'bg-gradient-to-r from-blue-500 to-cyan-500', 'text-white'),
('DEVELOPER', 'bg-gradient-to-r from-pink-500 to-purple-500 animate-pulse', 'text-white'),
('MODERATOR', 'bg-gradient-to-r from-red-500 to-orange-500', 'text-white'),
('CONTENT CREATOR', 'bg-gradient-to-r from-purple-500 to-pink-500', 'text-white'),
('EVENT WINNER', 'bg-gradient-to-r from-emerald-500 to-green-500', 'text-white')
ON CONFLICT (name) DO NOTHING;