-- =============================================================================
-- Resident Directory Management System - PostgreSQL Schema
-- Database: myapp
-- User: appuser
-- Port: 5000
-- =============================================================================

-- -----------------------------------------------------------------------------
-- TABLE: buildings
-- Stores building/complex information for multi-building support
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS buildings (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(255) NOT NULL,
    address     TEXT,
    description TEXT,
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- TABLE: users
-- Stores authentication credentials and role assignments
-- Roles: 'admin' or 'resident'
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id              SERIAL PRIMARY KEY,
    email           VARCHAR(255) UNIQUE NOT NULL,
    username        VARCHAR(100) UNIQUE NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    role            VARCHAR(20) NOT NULL DEFAULT 'resident'
                        CHECK (role IN ('admin', 'resident')),
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- TABLE: residents
-- Stores resident profile data linked to user accounts
-- One-to-one relationship with users via user_id
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS residents (
    id           SERIAL PRIMARY KEY,
    user_id      INTEGER UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    first_name   VARCHAR(100) NOT NULL,
    last_name    VARCHAR(100) NOT NULL,
    unit_number  VARCHAR(50),
    phone        VARCHAR(30),
    email        VARCHAR(255),
    photo_url    TEXT,
    building_id  INTEGER REFERENCES buildings(id) ON DELETE SET NULL,
    move_in_date DATE,
    move_out_date DATE,
    is_active    BOOLEAN NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at   TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- TABLE: privacy_settings
-- Controls which contact fields are visible in the public directory
-- One-to-one with residents
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS privacy_settings (
    id          SERIAL PRIMARY KEY,
    resident_id INTEGER UNIQUE NOT NULL REFERENCES residents(id) ON DELETE CASCADE,
    show_phone  BOOLEAN NOT NULL DEFAULT TRUE,
    show_email  BOOLEAN NOT NULL DEFAULT TRUE,
    show_unit   BOOLEAN NOT NULL DEFAULT TRUE,
    show_photo  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- TABLE: announcements
-- Building-wide or complex-wide announcements posted by admins
-- NULL building_id means the announcement applies to all buildings
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS announcements (
    id          SERIAL PRIMARY KEY,
    title       VARCHAR(255) NOT NULL,
    body        TEXT NOT NULL,
    author_id   INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    building_id INTEGER REFERENCES buildings(id) ON DELETE SET NULL,
    is_pinned   BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- TABLE: messages
-- Direct messages between residents
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS messages (
    id           SERIAL PRIMARY KEY,
    sender_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    recipient_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subject      VARCHAR(255),
    body         TEXT NOT NULL,
    is_read      BOOLEAN NOT NULL DEFAULT FALSE,
    created_at   TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- INDEXES for query performance
-- -----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_residents_building_id      ON residents(building_id);
CREATE INDEX IF NOT EXISTS idx_residents_user_id          ON residents(user_id);
CREATE INDEX IF NOT EXISTS idx_announcements_author_id    ON announcements(author_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id         ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_recipient_id      ON messages(recipient_id);

-- =============================================================================
-- SEED DATA
-- Default password for all seed users is handled via bcrypt hash in application
-- Admin credentials: admin@residency.com / (set via app)
-- =============================================================================

-- Seed buildings
INSERT INTO buildings (name, address, description) VALUES
    ('Maple Tower',     '123 Maple Street, Springfield, IL 62701', 'A modern 12-story residential tower with amenities including a rooftop garden and gym.'),
    ('Oak Residences',  '456 Oak Avenue, Springfield, IL 62702',   'A charming 6-story building with courtyard access and pet-friendly units.'),
    ('Pine Court',      '789 Pine Road, Springfield, IL 62703',     'Boutique 4-story complex with underground parking and concierge service.')
ON CONFLICT DO NOTHING;

-- Seed users (hashed_password is bcrypt hash of 'secret')
INSERT INTO users (email, username, hashed_password, role) VALUES
    ('admin@residency.com',      'admin',         '$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW', 'admin'),
    ('alice.johnson@email.com',  'alice_johnson', '$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW', 'resident'),
    ('bob.smith@email.com',      'bob_smith',     '$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW', 'resident'),
    ('carol.white@email.com',    'carol_white',   '$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW', 'resident'),
    ('david.brown@email.com',    'david_brown',   '$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW', 'resident'),
    ('eva.martinez@email.com',   'eva_martinez',  '$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW', 'resident')
ON CONFLICT (email) DO NOTHING;

-- Seed residents (linked to users and buildings)
INSERT INTO residents (user_id, first_name, last_name, unit_number, phone, email, building_id, move_in_date)
SELECT u.id, 'Alice', 'Johnson', '101', '555-201-1111', 'alice.johnson@email.com', 1, '2022-03-15'
FROM users u WHERE u.username = 'alice_johnson'
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO residents (user_id, first_name, last_name, unit_number, phone, email, building_id, move_in_date)
SELECT u.id, 'Bob', 'Smith', '205', '555-202-2222', 'bob.smith@email.com', 1, '2021-07-01'
FROM users u WHERE u.username = 'bob_smith'
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO residents (user_id, first_name, last_name, unit_number, phone, email, building_id, move_in_date)
SELECT u.id, 'Carol', 'White', '302', '555-203-3333', 'carol.white@email.com', 2, '2023-01-10'
FROM users u WHERE u.username = 'carol_white'
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO residents (user_id, first_name, last_name, unit_number, phone, email, building_id, move_in_date)
SELECT u.id, 'David', 'Brown', '410', '555-204-4444', 'david.brown@email.com', 2, '2020-11-20'
FROM users u WHERE u.username = 'david_brown'
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO residents (user_id, first_name, last_name, unit_number, phone, email, building_id, move_in_date)
SELECT u.id, 'Eva', 'Martinez', '103', '555-205-5555', 'eva.martinez@email.com', 3, '2023-06-05'
FROM users u WHERE u.username = 'eva_martinez'
ON CONFLICT (user_id) DO NOTHING;

-- Seed privacy settings (default visibility with some overrides)
INSERT INTO privacy_settings (resident_id, show_phone, show_email, show_unit, show_photo)
SELECT id, TRUE,  TRUE,  TRUE, TRUE FROM residents WHERE first_name='Alice' AND last_name='Johnson'
ON CONFLICT (resident_id) DO NOTHING;

INSERT INTO privacy_settings (resident_id, show_phone, show_email, show_unit, show_photo)
SELECT id, FALSE, TRUE,  TRUE, TRUE FROM residents WHERE first_name='Bob' AND last_name='Smith'
ON CONFLICT (resident_id) DO NOTHING;

INSERT INTO privacy_settings (resident_id, show_phone, show_email, show_unit, show_photo)
SELECT id, TRUE,  FALSE, TRUE, TRUE FROM residents WHERE first_name='Carol' AND last_name='White'
ON CONFLICT (resident_id) DO NOTHING;

INSERT INTO privacy_settings (resident_id, show_phone, show_email, show_unit, show_photo)
SELECT id, TRUE,  TRUE,  TRUE, TRUE FROM residents WHERE first_name='David' AND last_name='Brown'
ON CONFLICT (resident_id) DO NOTHING;

INSERT INTO privacy_settings (resident_id, show_phone, show_email, show_unit, show_photo)
SELECT id, FALSE, FALSE, TRUE, TRUE FROM residents WHERE first_name='Eva' AND last_name='Martinez'
ON CONFLICT (resident_id) DO NOTHING;

-- Seed announcements
INSERT INTO announcements (title, body, author_id, building_id, is_pinned)
SELECT
    'Welcome to Maple Tower',
    'Welcome to all our new and returning residents! We hope you enjoy living here.',
    u.id, 1, TRUE
FROM users u WHERE u.username = 'admin';

INSERT INTO announcements (title, body, author_id, building_id, is_pinned)
SELECT
    'Scheduled Maintenance: Water Shutdown',
    'Water will be shut off on Saturday, Dec 14 from 9am-12pm for routine pipe maintenance. Please plan accordingly.',
    u.id, NULL, FALSE
FROM users u WHERE u.username = 'admin';

INSERT INTO announcements (title, body, author_id, building_id, is_pinned)
SELECT
    'Community BBQ This Weekend!',
    'Join us for a community BBQ on Saturday afternoon in the Oak Residences courtyard. Food and drinks provided!',
    u.id, 2, FALSE
FROM users u WHERE u.username = 'admin';

-- Seed messages
INSERT INTO messages (sender_id, recipient_id, subject, body)
SELECT s.id, r.id,
    'Hello neighbor!',
    'Hi Bob, just wanted to introduce myself. I am Alice from unit 101. Hope we can be good neighbors!'
FROM users s, users r
WHERE s.username = 'alice_johnson' AND r.username = 'bob_smith';

INSERT INTO messages (sender_id, recipient_id, subject, body, is_read)
SELECT s.id, r.id,
    'Re: Hello neighbor!',
    'Hi Alice! Great to meet you. Looking forward to being neighbors. Feel free to knock if you ever need anything!',
    TRUE
FROM users s, users r
WHERE s.username = 'bob_smith' AND r.username = 'alice_johnson';
