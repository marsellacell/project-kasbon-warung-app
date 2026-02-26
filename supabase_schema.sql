-- SQL Script untuk membuat table di Supabase
-- Jalankan ini di Supabase SQL Editor

-- 1. Table users (untuk akun user/owner warung)
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  email TEXT NOT NULL,
  nama TEXT NOT NULL,
  role TEXT DEFAULT 'owner',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Table customers (untuk pelanggan)
CREATE TABLE IF NOT EXISTS public.customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nama TEXT NOT NULL,
  hp TEXT,
  alamat TEXT,
  limit_kredit DECIMAL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Table transactions (untuk kasbon)
CREATE TABLE IF NOT EXISTS public.transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID REFERENCES public.customers(id) ON DELETE CASCADE,
  nama_barang TEXT NOT NULL,
  nominal DECIMAL NOT NULL,
  deskripsi TEXT,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'paid', 'overdue')),
  tanggal TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  tenggat TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Table payments (untuk pembayaran)
CREATE TABLE IF NOT EXISTS public.payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID REFERENCES public.customers(id) ON DELETE CASCADE,
  transaction_id UUID REFERENCES public.transactions(id) ON DELETE SET NULL,
  jumlah DECIMAL NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

-- Policy untuk users (hanya owner bisa akses)
CREATE POLICY "Users are viewable by authenticated users" ON public.users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users are updatable by authenticated users" ON public.users
  FOR UPDATE USING (auth.uid() = id);

-- Policy untuk customers (semua user terautentikasi bisa akses)
CREATE POLICY "Customers are viewable by authenticated users" ON public.customers
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Customers are insertable by authenticated users" ON public.customers
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Customers are updatable by authenticated users" ON public.customers
  FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Customers are deletable by authenticated users" ON public.customers
  FOR DELETE USING (auth.role() = 'authenticated');

-- Policy untuk transactions
CREATE POLICY "Transactions are viewable by authenticated users" ON public.transactions
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Transactions are insertable by authenticated users" ON public.transactions
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Transactions are updatable by authenticated users" ON public.transactions
  FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Transactions are deletable by authenticated users" ON public.transactions
  FOR DELETE USING (auth.role() = 'authenticated');

-- Policy untuk payments
CREATE POLICY "Payments are viewable by authenticated users" ON public.payments
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Payments are insertable by authenticated users" ON public.payments
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Payments are updatable by authenticated users" ON public.payments
  FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Payments are deletable by authenticated users" ON public.payments
  FOR DELETE USING (auth.role() = 'authenticated');

-- Trigger untuk auto-create user profile saat signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, nama, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'nama', NEW.email),
    COALESCE(NEW.raw_user_meta_data->>'role', 'owner')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
