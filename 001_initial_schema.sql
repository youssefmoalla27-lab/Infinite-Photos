-- ============================================================
-- Infinite Photos - Database Schema
-- Run this in Supabase SQL Editor
-- ============================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ============================================================
-- PROFILES TABLE
-- ============================================================
CREATE TABLE public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  account_status TEXT NOT NULL DEFAULT 'pending'
    CHECK (account_status IN ('pending', 'active', 'suspended', 'disabled')),
  plan TEXT NOT NULL DEFAULT 'trial'
    CHECK (plan IN ('trial', 'premium')),
  trial_ends_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '7 days'),
  subscription_ends_at TIMESTAMPTZ,
  storage_used_bytes BIGINT NOT NULL DEFAULT 0,
  storage_limit_bytes BIGINT NOT NULL DEFAULT 10737418240, -- 10 GB
  is_admin BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- ALBUMS TABLE
-- ============================================================
CREATE TABLE public.albums (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  cover_photo_id UUID,
  photo_count INTEGER NOT NULL DEFAULT 0,
  is_public BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- PHOTOS TABLE
-- ============================================================
CREATE TABLE public.photos (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  album_id UUID REFERENCES public.albums(id) ON DELETE SET NULL,
  storage_path TEXT NOT NULL,
  thumbnail_path TEXT,
  original_name TEXT NOT NULL,
  file_size_bytes BIGINT NOT NULL DEFAULT 0,
  mime_type TEXT NOT NULL,
  width INTEGER,
  height INTEGER,
  title TEXT,
  description TEXT,
  tags TEXT[] DEFAULT '{}',
  taken_at TIMESTAMPTZ,
  location_name TEXT,
  is_favorite BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Full text search index on photos
CREATE INDEX photos_search_idx ON public.photos
  USING gin((
    to_tsvector('french', COALESCE(title, '') || ' ' || COALESCE(description, '') || ' ' || COALESCE(original_name, '') || ' ' || COALESCE(array_to_string(tags, ' '), ''))
  ));

CREATE INDEX photos_user_id_idx ON public.photos(user_id);
CREATE INDEX photos_album_id_idx ON public.photos(album_id);
CREATE INDEX photos_created_at_idx ON public.photos(created_at DESC);
CREATE INDEX albums_user_id_idx ON public.albums(user_id);

-- ============================================================
-- ADMIN AUDIT LOG
-- ============================================================
CREATE TABLE public.admin_audit_log (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  admin_id UUID REFERENCES public.profiles(id) NOT NULL,
  target_user_id UUID REFERENCES public.profiles(id) NOT NULL,
  action TEXT NOT NULL CHECK (action IN ('activate', 'suspend', 'disable', 'reset_storage')),
  previous_status TEXT,
  new_status TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- FUNCTIONS
-- ============================================================

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email)
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: create profile on new auth user
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Update storage used when photo is added
CREATE OR REPLACE FUNCTION public.update_storage_on_photo_insert()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.profiles
  SET storage_used_bytes = storage_used_bytes + NEW.file_size_bytes,
      updated_at = NOW()
  WHERE id = NEW.user_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_photo_inserted
  AFTER INSERT ON public.photos
  FOR EACH ROW EXECUTE FUNCTION public.update_storage_on_photo_insert();

-- Update storage used when photo is deleted
CREATE OR REPLACE FUNCTION public.update_storage_on_photo_delete()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.profiles
  SET storage_used_bytes = GREATEST(0, storage_used_bytes - OLD.file_size_bytes),
      updated_at = NOW()
  WHERE id = OLD.user_id;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_photo_deleted
  AFTER DELETE ON public.photos
  FOR EACH ROW EXECUTE FUNCTION public.update_storage_on_photo_delete();

-- Update album photo count
CREATE OR REPLACE FUNCTION public.update_album_photo_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.album_id IS NOT NULL THEN
    UPDATE public.albums SET photo_count = photo_count + 1, updated_at = NOW()
    WHERE id = NEW.album_id;
  ELSIF TG_OP = 'DELETE' AND OLD.album_id IS NOT NULL THEN
    UPDATE public.albums SET photo_count = GREATEST(0, photo_count - 1), updated_at = NOW()
    WHERE id = OLD.album_id;
  ELSIF TG_OP = 'UPDATE' THEN
    IF OLD.album_id IS NOT NULL AND OLD.album_id != COALESCE(NEW.album_id, '00000000-0000-0000-0000-000000000000'::uuid) THEN
      UPDATE public.albums SET photo_count = GREATEST(0, photo_count - 1), updated_at = NOW()
      WHERE id = OLD.album_id;
    END IF;
    IF NEW.album_id IS NOT NULL AND NEW.album_id != COALESCE(OLD.album_id, '00000000-0000-0000-0000-000000000000'::uuid) THEN
      UPDATE public.albums SET photo_count = photo_count + 1, updated_at = NOW()
      WHERE id = NEW.album_id;
    END IF;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_photo_album_change
  AFTER INSERT OR DELETE OR UPDATE OF album_id ON public.photos
  FOR EACH ROW EXECUTE FUNCTION public.update_album_photo_count();

-- Auto expire trial accounts
CREATE OR REPLACE FUNCTION public.check_account_expiry()
RETURNS VOID AS $$
BEGIN
  UPDATE public.profiles
  SET account_status = 'pending'
  WHERE account_status = 'active'
    AND plan = 'trial'
    AND trial_ends_at < NOW();

  UPDATE public.profiles
  SET account_status = 'pending'
  WHERE account_status = 'active'
    AND plan = 'premium'
    AND subscription_ends_at IS NOT NULL
    AND subscription_ends_at < NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Updated_at trigger function
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER profiles_updated_at BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER albums_updated_at BEFORE UPDATE ON public.albums
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER photos_updated_at BEFORE UPDATE ON public.photos
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.albums ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_audit_log ENABLE ROW LEVEL SECURITY;

-- Profiles RLS
CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id AND is_admin = false);

CREATE POLICY "Admins can view all profiles"
  ON public.profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND is_admin = true
    )
  );

CREATE POLICY "Admins can update all profiles"
  ON public.profiles FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND is_admin = true
    )
  );

-- Albums RLS
CREATE POLICY "Users can manage own albums"
  ON public.albums FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Photos RLS
CREATE POLICY "Users can manage own photos"
  ON public.photos FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Admin audit log RLS
CREATE POLICY "Admins can view audit log"
  ON public.admin_audit_log FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND is_admin = true
    )
  );

CREATE POLICY "Admins can insert audit log"
  ON public.admin_audit_log FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND is_admin = true
    )
  );

-- ============================================================
-- STORAGE BUCKETS
-- ============================================================

-- Create photos bucket (private)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'photos',
  'photos',
  false,
  52428800, -- 50MB per file
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/heic', 'image/heif']
) ON CONFLICT (id) DO NOTHING;

-- Create thumbnails bucket (private)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'thumbnails',
  'thumbnails',
  false,
  5242880, -- 5MB per thumbnail
  ARRAY['image/jpeg', 'image/png', 'image/webp']
) ON CONFLICT (id) DO NOTHING;

-- Storage RLS: photos bucket
CREATE POLICY "Users can upload own photos"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'photos' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can view own photos"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'photos' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can delete own photos"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'photos' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Storage RLS: thumbnails bucket
CREATE POLICY "Users can upload own thumbnails"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'thumbnails' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can view own thumbnails"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'thumbnails' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can delete own thumbnails"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'thumbnails' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- ============================================================
-- INITIAL ADMIN USER (update email after creation)
-- ============================================================
-- After running this script, create your admin account via the app,
-- then run: UPDATE public.profiles SET is_admin = true WHERE email = 'your-admin@email.com';
