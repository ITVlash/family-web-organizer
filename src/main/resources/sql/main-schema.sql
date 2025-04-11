-- Основная база данных
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_database WHERE datname = 'family_organizer_main') THEN
    CREATE DATABASE family_organizer_main;
  END IF;
END
$$;

\c family_organizer_main

-- Таблица профилей пользователей (ссылается на auth_db.users.id)
CREATE TABLE IF NOT EXISTS user_profiles (
    user_id INTEGER PRIMARY KEY,  -- Ссылка на users.id в auth DB
    name VARCHAR(100) NOT NULL,
    avatar_url VARCHAR(255),
    phone VARCHAR(20),
    birth_date DATE,
    mailing_enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Таблица семей (дублирование минимальной информации из auth DB)
CREATE TABLE IF NOT EXISTS families (
    id INTEGER PRIMARY KEY,  -- Ссылка на families.id в auth DB
    name VARCHAR(100) NOT NULL,
    description TEXT,
    avatar_url VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Таблица категорий для событий и задач
CREATE TABLE IF NOT EXISTS case_categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE
);

-- Таблица событий
CREATE TABLE IF NOT EXISTS events (
    id SERIAL PRIMARY KEY,
    family_id INTEGER NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    author_id INTEGER NOT NULL,  -- Ссылка на users.id в auth DB
    title VARCHAR(255) NOT NULL,
    description TEXT,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    is_private BOOLEAN DEFAULT FALSE,   -- При TRUE видят только доверенные участники
    location VARCHAR(255),
    category_id INTEGER REFERENCES case_categories(id),
    reminder_minutes_before INTEGER,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Таблица участников событий
CREATE TABLE IF NOT EXISTS event_participants (
    event_id INTEGER NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL,  -- Ссылка на users.id в auth DB
    PRIMARY KEY (event_id, user_id)
);

-- Таблица задач
CREATE TABLE IF NOT EXISTS tasks (
    id SERIAL PRIMARY KEY,
    family_id INTEGER NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    author_id INTEGER NOT NULL,  -- Ссылка на users.id в auth DB
    title VARCHAR(255) NOT NULL,
    description TEXT,
    is_completed BOOLEAN DEFAULT FALSE,
    is_priority BOOLEAN DEFAULT FALSE,
    due_date TIMESTAMPTZ,
    category_id INTEGER REFERENCES case_categories(id),
    is_private BOOLEAN DEFAULT FALSE,   -- При TRUE видят только доверенные участники
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Таблица участников задач
CREATE TABLE IF NOT EXISTS task_participants (
    task_id INTEGER NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL,  -- Ссылка на users.id в auth DB
    PRIMARY KEY (task_id, user_id)
);

-- Таблица рецептов
CREATE TABLE IF NOT EXISTS recipes (
    id SERIAL PRIMARY KEY,
    family_id INTEGER NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    author_id INTEGER NOT NULL,  -- Ссылка на users.id в auth DB
    title VARCHAR(255) NOT NULL,
    image_url VARCHAR(255),
    description TEXT,
    cooking_time INTEGER,
    servings INTEGER,   -- Количество порций
    is_private BOOLEAN DEFAULT FALSE,   -- При TRUE видят только доверенные участники
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Таблица ингредиентов рецептов
CREATE TABLE IF NOT EXISTS recipe_ingredients (
    id SERIAL PRIMARY KEY,
    recipe_id INTEGER NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    amount VARCHAR(100),
    unit VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Таблица участников рецептов
CREATE TABLE IF NOT EXISTS recipe_participants (
    recipe_id INTEGER NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL,  -- Ссылка на users.id в auth DB
    PRIMARY KEY (recipe_id, user_id)
);

-- Таблица постов в ленте
CREATE TABLE IF NOT EXISTS posts (
    id SERIAL PRIMARY KEY,
    family_id INTEGER NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    author_id INTEGER NOT NULL,  -- Ссылка на users.id в auth DB
    image_url VARCHAR(255),
    event_id INTEGER NULL REFERENCES events(id) ON DELETE CASCADE,
    task_id INTEGER NULL REFERENCES tasks(id) ON DELETE CASCADE,
    recipe_id INTEGER NULL REFERENCES recipes(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Таблица комментариев к постам
CREATE TABLE IF NOT EXISTS post_comments (
    id SERIAL PRIMARY KEY,
    post_id INTEGER NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    author_id INTEGER NOT NULL,  -- Ссылка на users.id в auth DB
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Таблица лайков к постам
CREATE TABLE IF NOT EXISTS post_likes (
    post_id INTEGER NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL,  -- Ссылка на users.id в auth DB
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (post_id, user_id)
);

-- Таблица чатов
CREATE TABLE IF NOT EXISTS chats (
    id SERIAL PRIMARY KEY,
    family_id INTEGER NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    name VARCHAR(255),
    is_group BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Таблица участников чатов
CREATE TABLE IF NOT EXISTS chat_participants (
    chat_id INTEGER NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL,  -- Ссылка на users.id в auth DB
    PRIMARY KEY (chat_id, user_id)
);

-- Таблица сообщений
CREATE TABLE IF NOT EXISTS messages (
    id SERIAL PRIMARY KEY,
    chat_id INTEGER NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
    sender_id INTEGER NOT NULL,  -- Ссылка на users.id в auth DB
    content TEXT NOT NULL,
    image_url VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Таблица фотографий в галерее
CREATE TABLE IF NOT EXISTS photos (
    id SERIAL PRIMARY KEY,
    family_id INTEGER NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    uploader_id INTEGER NOT NULL,  -- Ссылка на users.id в auth DB
    photo_url VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Индексы для ускорения запросов
CREATE INDEX IF NOT EXISTS idx_events_family_id ON events(family_id);
CREATE INDEX IF NOT EXISTS idx_events_author_id ON events(author_id);
CREATE INDEX IF NOT EXISTS idx_events_start_time ON events(start_time);
CREATE INDEX IF NOT EXISTS idx_events_end_time ON events(end_time);

CREATE INDEX IF NOT EXISTS idx_tasks_family_id ON tasks(family_id);
CREATE INDEX IF NOT EXISTS idx_tasks_author_id ON tasks(author_id);
CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON tasks(due_date);

CREATE INDEX IF NOT EXISTS idx_recipes_family_id ON recipes(family_id);
CREATE INDEX IF NOT EXISTS idx_recipe_ingredients_recipe_id ON recipe_ingredients(recipe_id);

CREATE INDEX IF NOT EXISTS idx_posts_family_id ON posts(family_id);
CREATE INDEX IF NOT EXISTS idx_posts_author_id ON posts(author_id);
CREATE INDEX IF NOT EXISTS idx_posts_created_at ON posts(created_at);
CREATE INDEX IF NOT EXISTS idx_post_comments_post_id ON post_comments(post_id);
CREATE INDEX IF NOT EXISTS idx_post_comments_author_id ON post_comments(author_id);

CREATE INDEX IF NOT EXISTS idx_messages_chat_id ON messages(chat_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at);

CREATE INDEX IF NOT EXISTS idx_photos_family_id ON photos(family_id);