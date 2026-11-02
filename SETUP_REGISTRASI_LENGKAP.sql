-- ============================================
-- SETUP REGISTRASI - COPY PASTE SEMUA INI
-- ============================================

-- STEP 1: Buat tabel users
CREATE TABLE IF NOT EXISTS public.users (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name   VARCHAR(255),
  email       VARCHAR(255) NOT NULL,
  phone       VARCHAR(20),
  avatar_url  TEXT,
  role        VARCHAR(20) NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin')),
  is_active   BOOLEAN NOT NULL DEFAULT true,
  created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index email (unique sudah dijamin oleh auth.users)
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);

-- STEP 2: Buat function untuk auto-insert user
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
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
$$;

-- STEP 3: Hapus trigger lama (jika ada)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- STEP 4: Buat trigger baru
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- STEP 5: Enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- STEP 6: Drop policies lama (jika ada)
DROP POLICY IF EXISTS "users_select_own" ON public.users;
DROP POLICY IF EXISTS "users_update_own" ON public.users;
DROP POLICY IF EXISTS "users_insert_own" ON public.users;
DROP POLICY IF EXISTS "admin_select_all_users" ON public.users;
DROP POLICY IF EXISTS "admin_update_all_users" ON public.users;
DROP POLICY IF EXISTS "admin_delete_users" ON public.users;
DROP POLICY IF EXISTS "Enable insert for authentication" ON public.users;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.users;

-- STEP 7: Buat policies baru
-- Policy untuk INSERT (diperlukan oleh trigger)
CREATE POLICY "Enable insert for authentication"
  ON public.users
  FOR INSERT
  WITH CHECK (true);

-- Policy untuk SELECT own profile
CREATE POLICY "users_select_own"
  ON public.users
  FOR SELECT
  USING (auth.uid() = id);

-- Policy untuk UPDATE own profile
CREATE POLICY "users_update_own"
  ON public.users
  FOR UPDATE
  USING (auth.uid() = id);

-- Policy untuk admin SELECT all
CREATE POLICY "admin_select_all_users"
  ON public.users
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid() AND u.role = 'admin'
    )
  );

-- Policy untuk admin UPDATE all
CREATE POLICY "admin_update_all_users"
  ON public.users
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid() AND u.role = 'admin'
    )
  );

-- Policy untuk admin DELETE
CREATE POLICY "admin_delete_users"
  ON public.users
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid() AND u.role = 'admin'
    )
  );

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Cek tabel users
SELECT 'Tabel users' as item, 
       CASE WHEN EXISTS (
         SELECT 1 FROM information_schema.tables 
         WHERE table_name = 'users' AND table_schema = 'public'
       ) THEN '✅ Ada' ELSE '❌ Tidak ada' END as status;

-- Cek trigger
SELECT 'Trigger on_auth_user_created' as item,
       CASE WHEN EXISTS (
         SELECT 1 FROM pg_trigger 
         WHERE tgname = 'on_auth_user_created'
       ) THEN '✅ Ada' ELSE '❌ Tidak ada' END as status;

-- Cek function
SELECT 'Function handle_new_user' as item,
       CASE WHEN EXISTS (
         SELECT 1 FROM pg_proc 
         WHERE proname = 'handle_new_user'
       ) THEN '✅ Ada' ELSE '❌ Tidak ada' END as status;

-- Cek RLS
SELECT 'RLS enabled' as item,
       CASE WHEN EXISTS (
         SELECT 1 FROM pg_tables 
         WHERE tablename = 'users' 
         AND schemaname = 'public' 
         AND rowsecurity = true
       ) THEN '✅ Enabled' ELSE '❌ Disabled' END as status;

-- Cek policies
SELECT 'Policies count' as item,
       COUNT(*)::text || ' policies' as status
FROM pg_policies 
WHERE tablename = 'users';

-- ============================================
-- SELESAI!
-- Jika semua verification menunjukkan ✅, 
-- registrasi siap digunakan!
-- ============================================
