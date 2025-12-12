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
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_users_username ON public.users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);

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

CREATE INDEX IF NOT EXISTS idx_threads_category ON forum.threads(category_id);
CREATE INDEX IF NOT EXISTS idx_threads_author ON forum.threads(author_id);
CREATE INDEX IF NOT EXISTS idx_posts_thread ON forum.posts(thread_id);
CREATE INDEX IF NOT EXISTS idx_posts_author ON forum.posts(author_id);

-- ============================================
-- DASHBOARD SCHEMA
-- ============================================
CREATE SCHEMA IF NOT EXISTS dashboard;

CREATE TABLE IF NOT EXISTS dashboard.characters (
    id SERIAL PRIMARY KEY,
    user_id TEXT NOT NULL,
    name TEXT NOT NULL,
    level INTEGER DEFAULT 1,
    class TEXT NOT NULL,
    experience INTEGER DEFAULT 0,
    gold INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_played TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE
);


CREATE TABLE IF NOT EXISTS dashboard.item_mall_purchases (
    id SERIAL PRIMARY KEY,
    user_id TEXT NOT NULL,
    item_id TEXT NOT NULL,
    quantity INTEGER DEFAULT 1,
    price_paid INTEGER NOT NULL,
    purchased_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_characters_user ON dashboard.characters(user_id);
CREATE INDEX IF NOT EXISTS idx_purchases_user ON dashboard.item_mall_purchases(user_id);
