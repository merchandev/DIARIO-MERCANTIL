PRAGMA journal_mode=WAL;
CREATE TABLE IF NOT EXISTS files (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  size INTEGER NOT NULL,
  type TEXT NOT NULL,
  checksum TEXT,
  version INTEGER DEFAULT 1,
  status TEXT NOT NULL,
  owner TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS file_events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  file_id INTEGER NOT NULL,
  ts TEXT NOT NULL,
  type TEXT NOT NULL,
  message TEXT,
  FOREIGN KEY(file_id) REFERENCES files(id)
);
CREATE INDEX IF NOT EXISTS idx_events_file ON file_events(file_id);

-- Auth tables
CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  document TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  role TEXT DEFAULT 'user',
  phone TEXT,
  email TEXT,
  person_type TEXT DEFAULT 'natural',
  avatar_url TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS auth_tokens (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  token TEXT NOT NULL UNIQUE,
  expires_at TEXT NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY(user_id) REFERENCES users(id)
);
CREATE INDEX IF NOT EXISTS idx_tokens_token ON auth_tokens(token);

-- Editions
CREATE TABLE IF NOT EXISTS editions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT NOT NULL,
  status TEXT NOT NULL,
  date TEXT NOT NULL,
  edition_no INTEGER NOT NULL,
  orders_count INTEGER DEFAULT 0,
  file_id INTEGER,
  file_name TEXT,
  created_at TEXT NOT NULL
);

-- Link table Edition -> Legal Requests as orders
CREATE TABLE IF NOT EXISTS edition_orders (
  edition_id INTEGER NOT NULL,
  legal_request_id INTEGER NOT NULL,
  PRIMARY KEY (edition_id, legal_request_id),
  FOREIGN KEY(edition_id) REFERENCES editions(id) ON DELETE CASCADE,
  FOREIGN KEY(legal_request_id) REFERENCES legal_requests(id)
);

-- Payment methods
CREATE TABLE IF NOT EXISTS payment_methods (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type TEXT,
  bank TEXT,
  account TEXT,
  holder TEXT,
  rif TEXT,
  phone TEXT,
  created_at TEXT NOT NULL
);

-- Legal directory requests
CREATE TABLE IF NOT EXISTS legal_requests (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  status TEXT NOT NULL,
  name TEXT NOT NULL,
  document TEXT NOT NULL,
  date TEXT NOT NULL,
  order_no TEXT,
  publish_date TEXT,
  phone TEXT,
  email TEXT,
  address TEXT,
  folios INTEGER DEFAULT 1,
  comment TEXT,
  user_id INTEGER,
  pub_type TEXT DEFAULT 'Documento',
  meta TEXT,
  deleted_at TEXT,
  created_at TEXT NOT NULL
);

-- Payments linked to legal requests (history)
CREATE TABLE IF NOT EXISTS legal_payments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  legal_request_id INTEGER NOT NULL,
  ref TEXT,
  date TEXT NOT NULL,
  bank TEXT,
  type TEXT,
  amount_bs REAL NOT NULL,
  status TEXT,
  mobile_phone TEXT,
  comment TEXT,
  created_at TEXT NOT NULL,
  FOREIGN KEY(legal_request_id) REFERENCES legal_requests(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_legal_payments_req ON legal_payments(legal_request_id);

-- Files linked to legal requests (attachments)
CREATE TABLE IF NOT EXISTS legal_files (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  legal_request_id INTEGER NOT NULL,
  kind TEXT NOT NULL,
  file_id INTEGER NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY(legal_request_id) REFERENCES legal_requests(id) ON DELETE CASCADE,
  FOREIGN KEY(file_id) REFERENCES files(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_legal_files_req ON legal_files(legal_request_id);

-- Directory Legal profiles
CREATE TABLE IF NOT EXISTS directory_profiles (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  full_name TEXT NOT NULL,
  email TEXT,
  phones TEXT,
  state TEXT,
  areas TEXT,
  colegio TEXT,
  socials TEXT,
  inpre_photo_file_id INTEGER,
  profile_photo_file_id INTEGER,
  status TEXT DEFAULT 'pendiente',
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY(user_id) REFERENCES users(id)
);

-- Directory reference data: areas and colleges
CREATE TABLE IF NOT EXISTS directory_areas (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS directory_colleges (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

-- Publications
CREATE TABLE IF NOT EXISTS publications (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  slug TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  content TEXT,
  status TEXT NOT NULL DEFAULT 'published',
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

-- CMS Pages (editable header/body/footer + block-based body)
CREATE TABLE IF NOT EXISTS pages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  slug TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  header_html TEXT,
  body_json TEXT, -- JSON array of blocks
  footer_html TEXT,
  status TEXT NOT NULL DEFAULT 'published',
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

-- Key-value settings
CREATE TABLE IF NOT EXISTS settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

-- Seed defaults (idempotent)
INSERT OR IGNORE INTO settings(key,value,updated_at) VALUES
 ('bcv_rate','203.74',strftime('%Y-%m-%dT%H:%M:%SZ','now')),
 ('price_per_folio_usd','1.50',strftime('%Y-%m-%dT%H:%M:%SZ','now')),
 ('convocatoria_usd','10.00',strftime('%Y-%m-%dT%H:%M:%SZ','now')),
 ('iva_percent','16',strftime('%Y-%m-%dT%H:%M:%SZ','now')),
 ('raptor_mini_preview_enabled','1',strftime('%Y-%m-%dT%H:%M:%SZ','now'));
