-- Unified Database Schema for All Services
-- Database: postgres

-- ============================================
-- PUBLIC SCHEMA (Auth tables)
-- ============================================
-- Ensure public schema exists
CREATE SCHEMA IF NOT EXISTS public;

-- Central-auth library creates these in public schema by default

CREATE TABLE IF NOT EXISTS public.users (
    id VARCHAR(36) PRIMARY KEY,
    username VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password TEXT NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'user',
    profile_image TEXT DEFAULT NULL,
    balance INTEGER DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- Game account linking (NULL = unverified)
    game_account_id INTEGER DEFAULT NULL,
    game_api_key TEXT DEFAULT NULL,
    -- Discord account linking (NULL = unverified)
    discord_id VARCHAR(255) DEFAULT NULL,
    discord_username VARCHAR(255) DEFAULT NULL
);

CREATE INDEX IF NOT EXISTS idx_users_username ON public.users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_game_account ON public.users(game_account_id);
CREATE INDEX IF NOT EXISTS idx_users_discord_id ON public.users(discord_id);
CREATE TABLE IF NOT EXISTS public.refresh_tokens (
    token VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user ON public.refresh_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_expires ON public.refresh_tokens(expires_at);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update updated_at
DROP TRIGGER IF EXISTS update_users_timestamp ON public.users;
CREATE TRIGGER update_users_timestamp
BEFORE UPDATE ON public.users
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

CREATE TABLE IF NOT EXISTS public.discord_verifications (
    token VARCHAR(255) PRIMARY KEY,
    discord_id VARCHAR(255) NOT NULL,
    discord_username VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMP NOT NULL,
    used BOOLEAN DEFAULT false,
    used_at TIMESTAMP DEFAULT NULL,
    used_by VARCHAR(36) DEFAULT NULL,
    FOREIGN KEY (used_by) REFERENCES public.users(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_discord_verifications_discord_id ON public.discord_verifications(discord_id);
CREATE INDEX IF NOT EXISTS idx_discord_verifications_expires ON public.discord_verifications(expires_at);

-- ============================================
-- FORUM SCHEMA
-- ============================================
CREATE SCHEMA IF NOT EXISTS forum;

CREATE TABLE IF NOT EXISTS forum.categories (
    id TEXT PRIMARY KEY,
    parent_id TEXT,
    name TEXT NOT NULL,
    description TEXT,
    image TEXT,
    slug TEXT UNIQUE,
    is_locked BOOLEAN DEFAULT false,
    FOREIGN KEY (parent_id) REFERENCES forum.categories(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS forum.threads (
    id SERIAL PRIMARY KEY,
    category_id TEXT NOT NULL,
    title TEXT NOT NULL,
    author_id TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_locked BOOLEAN DEFAULT false,
    is_sticky BOOLEAN DEFAULT false,
    is_deleted BOOLEAN DEFAULT false,
    view_count INTEGER DEFAULT 0,
    FOREIGN KEY (category_id) REFERENCES forum.categories(id) ON DELETE CASCADE,
    FOREIGN KEY (author_id) REFERENCES public.users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS forum.posts (
    id SERIAL PRIMARY KEY,
    thread_id INTEGER NOT NULL,
    author_id TEXT NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_deleted BOOLEAN DEFAULT false,
    FOREIGN KEY (thread_id) REFERENCES forum.threads(id) ON DELETE CASCADE,
    FOREIGN KEY (author_id) REFERENCES public.users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS forum.post_reactions (
    id SERIAL PRIMARY KEY,
    post_id INTEGER NOT NULL,
    user_id TEXT NOT NULL,
    reaction_type TEXT NOT NULL CHECK (reaction_type IN ('like', 'heart', 'laugh', 'sad', 'wow', 'angry', 'celebrate')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES forum.posts(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE,
    UNIQUE(post_id, user_id, reaction_type)
);

CREATE TABLE IF NOT EXISTS forum.badges (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    bg_color TEXT NOT NULL,
    text_color TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS forum.user_badges (
    id SERIAL PRIMARY KEY,
    user_id TEXT NOT NULL,
    badge_id INTEGER NOT NULL,
    awarded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE,
    FOREIGN KEY (badge_id) REFERENCES forum.badges(id) ON DELETE CASCADE,
    UNIQUE(user_id, badge_id)
);


CREATE INDEX IF NOT EXISTS idx_user_badges_user ON forum.user_badges(user_id);
CREATE INDEX IF NOT EXISTS idx_user_badges_badge ON forum.user_badges(badge_id);
CREATE INDEX IF NOT EXISTS idx_post_reactions_post ON forum.post_reactions(post_id);
CREATE INDEX IF NOT EXISTS idx_post_reactions_user ON forum.post_reactions(user_id);
CREATE INDEX IF NOT EXISTS idx_threads_category ON forum.threads(category_id);
CREATE INDEX IF NOT EXISTS idx_threads_author ON forum.threads(author_id);
CREATE INDEX IF NOT EXISTS idx_posts_thread ON forum.posts(thread_id);
CREATE INDEX IF NOT EXISTS idx_posts_author ON forum.posts(author_id);

-- ============================================
-- DASHBOARD SCHEMA
-- ============================================
CREATE SCHEMA IF NOT EXISTS dashboard;

CREATE TABLE IF NOT EXISTS dashboard.items (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    type TEXT NOT NULL,
    price INTEGER NOT NULL,
    image TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Maps items to game goods (supports bundles with multiple goods)
CREATE TABLE IF NOT EXISTS dashboard.item_contents (
    id SERIAL PRIMARY KEY,
    item_id INTEGER NOT NULL,
    game_goods_no INTEGER NOT NULL,
    quantity INTEGER DEFAULT 1,
    FOREIGN KEY (item_id) REFERENCES dashboard.items(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_item_contents_item ON dashboard.item_contents(item_id);

CREATE TABLE IF NOT EXISTS dashboard.item_mall_purchases (
    id SERIAL PRIMARY KEY,
    user_id TEXT NOT NULL,
    item_id INTEGER NOT NULL,
    quantity INTEGER DEFAULT 1,
    price_paid INTEGER NOT NULL,
    purchased_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE,
    FOREIGN KEY (item_id) REFERENCES dashboard.items(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS dashboard.credit_purchases (
    id SERIAL PRIMARY KEY,
    user_id TEXT NOT NULL,
    credits INTEGER NOT NULL,
    amount_paid DECIMAL(10,2) NOT NULL,
    payment_id TEXT,
    status TEXT DEFAULT 'completed',
    purchased_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS dashboard.vouchers (
    id SERIAL PRIMARY KEY,
    code TEXT UNIQUE NOT NULL,
    description TEXT,
    max_total_redemptions INTEGER DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS dashboard.voucher_contents (
    id SERIAL PRIMARY KEY,
    voucher_id INTEGER NOT NULL,
    game_goods_no INTEGER NOT NULL,
    quantity INTEGER DEFAULT 1,
    FOREIGN KEY (voucher_id) REFERENCES dashboard.vouchers(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS dashboard.voucher_redemptions (
    id SERIAL PRIMARY KEY,
    user_id TEXT NOT NULL,
    voucher_id INTEGER NOT NULL,
    redeemed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE,
    FOREIGN KEY (voucher_id) REFERENCES dashboard.vouchers(id) ON DELETE CASCADE,
    UNIQUE(user_id, voucher_id)
);

CREATE INDEX IF NOT EXISTS idx_credit_purchases_user ON dashboard.credit_purchases(user_id);
CREATE INDEX IF NOT EXISTS idx_credit_purchases_status ON dashboard.credit_purchases(status);
CREATE INDEX IF NOT EXISTS idx_purchases_user ON dashboard.item_mall_purchases(user_id);
CREATE INDEX IF NOT EXISTS idx_vouchers_code ON dashboard.vouchers(code);
CREATE INDEX IF NOT EXISTS idx_voucher_contents_voucher ON dashboard.voucher_contents(voucher_id);
CREATE INDEX IF NOT EXISTS idx_voucher_redemptions_user ON dashboard.voucher_redemptions(user_id);
CREATE INDEX IF NOT EXISTS idx_voucher_redemptions_voucher ON dashboard.voucher_redemptions(voucher_id);