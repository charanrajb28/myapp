-- Run this in Supabase Dashboard → SQL Editor

-- Allow authenticated users to insert their own row into public.users
DROP POLICY IF EXISTS "Users can insert own row" ON users;
CREATE POLICY "Users can insert own row" ON users FOR INSERT TO authenticated
WITH CHECK (auth.uid() = id);

-- Allow authenticated users to insert their own row into public.students
DROP POLICY IF EXISTS "Students can insert own profile" ON students;
CREATE POLICY "Students can insert own profile" ON students FOR INSERT TO authenticated
WITH CHECK (user_id = auth.uid());
