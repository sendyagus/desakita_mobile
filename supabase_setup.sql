-- ============================================
-- SETUP DATABASE DESAKITA - SUPABASE
-- Jalankan di: Dashboard > SQL Editor > New Query
-- ============================================

-- ============================================
-- 0. TABEL USERS (Profile pengguna)
-- Terhubung ke auth.users via trigger otomatis
-- ============================================
CREATE TABLE IF NOT EXISTS public.users (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name   VARCHAR(255),
  email       VARCHAR(255) NOT NULL,
  phone       VARCHAR(20),
  avatar_url  TEXT,
  role        VARCHAR(20) NOT NULL DEFAULT 'user'
                CHECK (role IN ('user', 'admin')),
  is_active   BOOLEAN NOT NULL DEFAULT true,
  created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 1. TABEL DESTINATIONS
-- ============================================
CREATE TABLE IF NOT EXISTS public.destinations (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name        VARCHAR(255) NOT NULL,
  category    VARCHAR(50)  NOT NULL
                CHECK (category IN ('Alam','Budaya','Kuliner','Penginapan')),
  location    VARCHAR(255) NOT NULL,
  description TEXT,
  rating      DECIMAL(2,1) DEFAULT 0.0 CHECK (rating >= 0 AND rating <= 5),
  price       VARCHAR(100) NOT NULL,
  image_url   TEXT,
  status      BOOLEAN NOT NULL DEFAULT true,
  created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 2. TABEL BOOKINGS
-- ============================================
CREATE TABLE IF NOT EXISTS public.bookings (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  destination_id  UUID REFERENCES public.destinations(id) ON DELETE CASCADE,
  user_id         UUID REFERENCES public.users(id) ON DELETE CASCADE,
  check_in        DATE NOT NULL,
  check_out       DATE NOT NULL,
  guest_count     INTEGER NOT NULL DEFAULT 1,
  total_price     VARCHAR(100) NOT NULL,
  status          VARCHAR(50) NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending','confirmed','cancelled','completed')),
  created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 3. TABEL REVIEWS
-- ============================================
CREATE TABLE IF NOT EXISTS public.reviews (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  destination_id  UUID REFERENCES public.destinations(id) ON DELETE CASCADE,
  user_id         UUID REFERENCES public.users(id) ON DELETE CASCADE,
  rating          INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment         TEXT,
  created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 4. TABEL FAVORITES
-- ============================================
CREATE TABLE IF NOT EXISTS public.favorites (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id         UUID REFERENCES public.users(id) ON DELETE CASCADE,
  destination_id  UUID REFERENCES public.destinations(id) ON DELETE CASCADE,
  created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, destination_id)
);

-- ============================================
-- 5. TABEL EVENTS
-- ============================================
CREATE TABLE IF NOT EXISTS public.events (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title       VARCHAR(255) NOT NULL,
  description TEXT,
  event_date  DATE NOT NULL,
  event_time  VARCHAR(50),
  location    VARCHAR(255) NOT NULL,
  image_url   TEXT,
  status      BOOLEAN NOT NULL DEFAULT true,
  created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_users_email       ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_role        ON public.users(role);
CREATE INDEX IF NOT EXISTS idx_dest_category     ON public.destinations(category);
CREATE INDEX IF NOT EXISTS idx_dest_status       ON public.destinations(status);
CREATE INDEX IF NOT EXISTS idx_bookings_user     ON public.bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_dest     ON public.bookings(destination_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status   ON public.bookings(status);
CREATE INDEX IF NOT EXISTS idx_reviews_dest      ON public.reviews(destination_id);
CREATE INDEX IF NOT EXISTS idx_favorites_user    ON public.favorites(user_id);

-- ============================================
-- FUNCTIONS & TRIGGERS
-- ============================================

-- Function: auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers updated_at
CREATE TRIGGER trg_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_destinations_updated_at
  BEFORE UPDATE ON public.destinations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_bookings_updated_at
  BEFORE UPDATE ON public.bookings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_reviews_updated_at
  BEFORE UPDATE ON public.reviews
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_events_updated_at
  BEFORE UPDATE ON public.events
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- TRIGGER: Auto-insert ke public.users
-- saat user baru register via Supabase Auth
-- ============================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  BEGIN
    -- Jika ada data lama dengan email sama (stale row), hapus supaya tidak bikin 500
    DELETE FROM public.users
    WHERE email = NEW.email AND id <> NEW.id;

    INSERT INTO public.users (id, full_name, email, phone, role, is_active)
    VALUES (
      NEW.id,
      COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
      NEW.email,
      COALESCE(NEW.raw_user_meta_data->>'phone', ''),
      COALESCE(NEW.raw_user_meta_data->>'role', 'user'),
      true
    )
    ON CONFLICT (id) DO UPDATE SET
      full_name = EXCLUDED.full_name,
      email = EXCLUDED.email,
      phone = EXCLUDED.phone,
      role = EXCLUDED.role,
      is_active = EXCLUDED.is_active,
      updated_at = NOW();
  EXCEPTION
    WHEN others THEN
      -- Jangan gagalkan proses signup auth hanya karena insert profile error
      RETURN NEW;
  END;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Pasang trigger ke auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================
ALTER TABLE public.users        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.destinations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorites    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events       ENABLE ROW LEVEL SECURITY;

-- ── USERS policies ──────────────────────────
-- Penting: izinkan INSERT agar upsert profile dari client bisa berjalan
-- (dan tidak mengganggu proses registrasi)
DROP POLICY IF EXISTS "Enable insert for authentication" ON public.users;
CREATE POLICY "Enable insert for authentication"
  ON public.users
  FOR INSERT
  WITH CHECK (true);

-- User bisa melihat profil sendiri
CREATE POLICY "users_select_own"
  ON public.users FOR SELECT
  USING (auth.uid() = id);

-- User bisa update profil sendiri
CREATE POLICY "users_update_own"
  ON public.users FOR UPDATE
  USING (auth.uid() = id);

-- Admin bisa melihat semua user
CREATE POLICY "admin_select_all_users"
  ON public.users FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid() AND u.role = 'admin'
    )
  );

-- Admin bisa update semua user
CREATE POLICY "admin_update_all_users"
  ON public.users FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid() AND u.role = 'admin'
    )
  );

-- Admin bisa hapus user
CREATE POLICY "admin_delete_users"
  ON public.users FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid() AND u.role = 'admin'
    )
  );

-- ── DESTINATIONS policies ────────────────────
CREATE POLICY "dest_select_active"
  ON public.destinations FOR SELECT
  USING (status = true);

CREATE POLICY "admin_all_destinations"
  ON public.destinations FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid() AND u.role = 'admin'
    )
  );

-- ── BOOKINGS policies ────────────────────────
CREATE POLICY "bookings_select_own"
  ON public.bookings FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "bookings_insert_own"
  ON public.bookings FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "bookings_update_own"
  ON public.bookings FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "admin_all_bookings"
  ON public.bookings FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid() AND u.role = 'admin'
    )
  );

-- ── REVIEWS policies ─────────────────────────
CREATE POLICY "reviews_select_all"
  ON public.reviews FOR SELECT USING (true);

CREATE POLICY "reviews_insert_own"
  ON public.reviews FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "reviews_update_own"
  ON public.reviews FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "reviews_delete_own"
  ON public.reviews FOR DELETE
  USING (auth.uid() = user_id);

-- ── FAVORITES policies ───────────────────────
CREATE POLICY "favorites_own"
  ON public.favorites FOR ALL
  USING (auth.uid() = user_id);

-- ── EVENTS policies ──────────────────────────
CREATE POLICY "events_select_active"
  ON public.events FOR SELECT
  USING (status = true);

CREATE POLICY "admin_all_events"
  ON public.events FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid() AND u.role = 'admin'
    )
  );

-- ============================================
-- SAMPLE DATA
-- ============================================

-- Destinations
INSERT INTO public.destinations (name, category, location, description, rating, price, status) VALUES
  ('Bukit Sakura',        'Alam',        'Langkapura', 'Pemandangan perbukitan dengan bunga sakura.',          4.3, 'Rp 50.000',  true),
  ('Camp 91 Outbound',    'Alam',        'Kemiling',   'Camping dengan fasilitas lengkap di tengah alam.',     4.3, 'Rp 75.000',  true),
  ('Rumah Adat Lampung',  'Budaya',      'Desa Pujon', 'Kekayaan budaya Lampung melalui rumah adat.',          4.6, 'Rp 25.000',  true),
  ('Warung Mbok Darmi',   'Kuliner',     'Pasar Desa', 'Masakan tradisional yang autentik.',                   4.4, 'Rp 35.000',  true),
  ('Jukung Villa Lampung','Penginapan',  'Langkapura', 'Penginapan nyaman dengan pemandangan perbukitan.',     4.8, 'Rp 450.000', true)
ON CONFLICT DO NOTHING;

-- Events
INSERT INTO public.events (title, description, event_date, event_time, location, status) VALUES
  ('Festival Panen Raya',      'Perayaan panen raya dengan kegiatan budaya dan kuliner.', '2025-10-24', '08:00 - Selesai', 'Desa Pujon Kidul, Malang', true),
  ('Pasar Budaya Nusantara',   'Pasar budaya dengan produk kerajinan tradisional.',       '2025-11-05', '09:00 - 17:00',  'Desa Sade, Lombok',        true),
  ('Festival Kuliner Desa',    'Festival makanan khas desa dari seluruh Indonesia.',      '2025-11-12', '10:00 - Selesai','Desa Penglipuran, Bali',   true)
ON CONFLICT DO NOTHING;

-- ============================================
-- SELESAI
-- Langkah selanjutnya:
-- 1. Isi SUPABASE_URL di lib/services/supabase_config.dart
-- 2. flutter pub get
-- 3. Test register → cek tabel public.users terisi otomatis
-- ============================================
