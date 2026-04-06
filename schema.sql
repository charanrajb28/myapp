-- 1. Create custom enum types if they don't exist
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
        CREATE TYPE user_role AS ENUM ('student', 'company', 'admin');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'application_status') THEN
        CREATE TYPE application_status AS ENUM ('Applied', 'Active', 'Completed', 'Upcoming', 'Rejected', 'Under Review', 'Removed');
    END IF;
END $$;

-- 2. Create users table
CREATE TABLE IF NOT EXISTS users (
  -- Link exactly to auth.users to prevent stranded rows
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role user_role NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Create students table
CREATE TABLE IF NOT EXISTS students (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  enrollment_id VARCHAR(100),
  name VARCHAR(255),
  college VARCHAR(255) DEFAULT 'Sheshadri Institute of Technology',
  department VARCHAR(255),
  semester VARCHAR(50),
  contact_email TEXT,
  phone_number VARCHAR(20),
  parent_contact VARCHAR(20),
  parent_email VARCHAR(255),
  resume_url TEXT,
  document_urls JSONB DEFAULT '[]'::jsonb,
  gpa NUMERIC(10, 2),
  graduation_year INTEGER,
  is_blacklisted BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id)
);

-- 4. Create companies table
CREATE TABLE IF NOT EXISTS companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  industry VARCHAR(255),
  location TEXT,
  website TEXT,
  phone TEXT,
  contact_email TEXT,
  description TEXT,
  logo_url TEXT,
  mou_date DATE,
  partner_since INTEGER,
  is_blacklisted BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id)
);

-- 5. Create internships table (internship opportunities)
CREATE TABLE IF NOT EXISTS internships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  role VARCHAR(255) NOT NULL,
  industry VARCHAR(255) NOT NULL,
  location VARCHAR(255) NOT NULL,
  stipend VARCHAR(255),
  duration VARCHAR(255),
  deadline DATE,
  brand_color VARCHAR(50),
  logo_initial VARCHAR(10),
  about TEXT,
  requirements TEXT[],
  responsibilities TEXT[],
  status VARCHAR(50) DEFAULT 'INTERVIEWING',
  start_date DATE,
  end_date DATE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Create applications table (student internships)
CREATE TABLE IF NOT EXISTS applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  internship_id UUID NOT NULL REFERENCES internships(id) ON DELETE CASCADE,
  status application_status DEFAULT 'Applied',
  progress NUMERIC(3, 2) DEFAULT 0.0,
  start_date DATE,
  end_date DATE,
  mentor_name VARCHAR(255),
  mentor_email VARCHAR(255),
  offer_letter_id VARCHAR(255),
  alerts JSONB DEFAULT '[]'::jsonb,
  checkins JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(student_id, internship_id)
);

CREATE TABLE IF NOT EXISTS password_reset_otps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,
  otp_hash TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  consumed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS student_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  notification_type VARCHAR(50) DEFAULT 'general',
  is_read BOOLEAN DEFAULT false,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS student_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  public_url TEXT NOT NULL,
  source_type VARCHAR(50) DEFAULT 'google_drive',
  mime_type TEXT,
  is_resume BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Row Level Security (RLS) basics (You can refine these later)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE internships ENABLE ROW LEVEL SECURITY;
ALTER TABLE applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE password_reset_otps ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_documents ENABLE ROW LEVEL SECURITY;

-- Create policies for basic access
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON users;
CREATE POLICY "Public profiles are viewable by everyone" ON users FOR SELECT USING (true);

DROP POLICY IF EXISTS "Admins can update all users" ON users;
CREATE POLICY "Admins can update all users" ON users FOR UPDATE TO authenticated USING (
  (SELECT role FROM public.users WHERE id = auth.uid()) = 'admin'
);

DROP POLICY IF EXISTS "Users can update own profile" ON users;
CREATE POLICY "Users can update own profile" ON users FOR UPDATE TO authenticated USING (auth.uid() = id);

DROP POLICY IF EXISTS "Students are viewable by everyone" ON students;
CREATE POLICY "Students are viewable by everyone" ON students FOR SELECT USING (true);

DROP POLICY IF EXISTS "Admins can manage students" ON students;
CREATE POLICY "Admins can manage students" ON students FOR ALL TO authenticated USING (
  (SELECT role FROM public.users WHERE id = auth.uid()) = 'admin'
);

DROP POLICY IF EXISTS "Students can update own profile" ON students;
CREATE POLICY "Students can update own profile" ON students FOR UPDATE TO authenticated USING (
  user_id = auth.uid()
);

DROP POLICY IF EXISTS "Companies are viewable by everyone" ON companies;
CREATE POLICY "Companies are viewable by everyone" ON companies FOR SELECT USING (true);

DROP POLICY IF EXISTS "Admins can manage companies" ON companies;
CREATE POLICY "Admins can manage companies" ON companies FOR ALL TO authenticated USING (
  (SELECT role FROM public.users WHERE id = auth.uid()) = 'admin'
);

DROP POLICY IF EXISTS "Companies can update own profile" ON companies;
CREATE POLICY "Companies can update own profile" ON companies FOR UPDATE TO authenticated USING (
  user_id = auth.uid()
);

DROP POLICY IF EXISTS "Internships are public" ON internships;
CREATE POLICY "Internships are public" ON internships FOR SELECT USING (true);

DROP POLICY IF EXISTS "Admins can manage internships" ON internships;
CREATE POLICY "Admins can manage internships" ON internships FOR ALL TO authenticated USING (
  (SELECT role FROM public.users WHERE id = auth.uid()) = 'admin'
);

DROP POLICY IF EXISTS "Companies can manage their own internships" ON internships;
CREATE POLICY "Companies can manage their own internships" ON internships FOR ALL TO authenticated USING (
  company_id IN (SELECT id FROM public.companies WHERE user_id = auth.uid())
) WITH CHECK (
  company_id IN (SELECT id FROM public.companies WHERE user_id = auth.uid())
);

DROP POLICY IF EXISTS "Applications are visible to students and companies" ON applications;
CREATE POLICY "Applications are visible to students and companies" ON applications FOR SELECT USING (true);

DROP POLICY IF EXISTS "Admins can manage applications" ON applications;
CREATE POLICY "Admins can manage applications" ON applications FOR ALL TO authenticated USING (
  (SELECT role FROM public.users WHERE id = auth.uid()) = 'admin'
);

DROP POLICY IF EXISTS "Students can create own applications" ON applications;
CREATE POLICY "Students can create own applications" ON applications
FOR INSERT TO authenticated
WITH CHECK (
  student_id IN (
    SELECT id FROM public.students WHERE user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Students can update own applications" ON applications;
CREATE POLICY "Students can update own applications" ON applications
FOR UPDATE TO authenticated
USING (
  student_id IN (
    SELECT id FROM public.students WHERE user_id = auth.uid()
  )
)
WITH CHECK (
  student_id IN (
    SELECT id FROM public.students WHERE user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Companies can update applications for their internships" ON applications;
CREATE POLICY "Companies can update applications for their internships" ON applications
FOR UPDATE TO authenticated
USING (
  internship_id IN (
    SELECT id FROM public.internships WHERE company_id IN (
      SELECT id FROM public.companies WHERE user_id = auth.uid()
    )
  )
)
WITH CHECK (
  internship_id IN (
    SELECT id FROM public.internships WHERE company_id IN (
      SELECT id FROM public.companies WHERE user_id = auth.uid()
    )
  )
);

DROP POLICY IF EXISTS "No direct access to password reset otps" ON password_reset_otps;
CREATE POLICY "No direct access to password reset otps" ON password_reset_otps
FOR ALL TO authenticated USING (false) WITH CHECK (false);

DROP POLICY IF EXISTS "Students can view own notifications" ON student_notifications;
CREATE POLICY "Students can view own notifications" ON student_notifications
FOR SELECT TO authenticated USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Students can update own notifications" ON student_notifications;
CREATE POLICY "Students can update own notifications" ON student_notifications
FOR UPDATE TO authenticated USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Admins can manage notifications" ON student_notifications;
CREATE POLICY "Admins can manage notifications" ON student_notifications
FOR ALL TO authenticated USING (
  (SELECT role FROM public.users WHERE id = auth.uid()) = 'admin'
)
WITH CHECK (
  (SELECT role FROM public.users WHERE id = auth.uid()) = 'admin'
);

DROP POLICY IF EXISTS "Students can view own documents" ON student_documents;
CREATE POLICY "Students can view own documents" ON student_documents
FOR SELECT TO authenticated USING (
  student_id IN (
    SELECT id FROM public.students WHERE user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Students can insert own documents" ON student_documents;
CREATE POLICY "Students can insert own documents" ON student_documents
FOR INSERT TO authenticated
WITH CHECK (
  student_id IN (
    SELECT id FROM public.students WHERE user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Students can update own documents" ON student_documents;
CREATE POLICY "Students can update own documents" ON student_documents
FOR UPDATE TO authenticated
USING (
  student_id IN (
    SELECT id FROM public.students WHERE user_id = auth.uid()
  )
)
WITH CHECK (
  student_id IN (
    SELECT id FROM public.students WHERE user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Students can delete own documents" ON student_documents;
CREATE POLICY "Students can delete own documents" ON student_documents
FOR DELETE TO authenticated
USING (
  student_id IN (
    SELECT id FROM public.students WHERE user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Admins can manage student documents" ON student_documents;
CREATE POLICY "Admins can manage student documents" ON student_documents
FOR ALL TO authenticated USING (
  (SELECT role FROM public.users WHERE id = auth.uid()) = 'admin'
)
WITH CHECK (
  (SELECT role FROM public.users WHERE id = auth.uid()) = 'admin'
);

-- Functions to update 'updated_at' timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ language 'plpgsql';

CREATE OR REPLACE FUNCTION public.create_password_reset_otp(
  p_email TEXT,
  p_otp TEXT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = p_email) THEN
    RAISE EXCEPTION 'No account found for this email';
  END IF;

  DELETE FROM public.password_reset_otps
  WHERE expires_at < NOW()
     OR consumed_at IS NOT NULL;

  DELETE FROM public.password_reset_otps WHERE email = p_email;

  INSERT INTO public.password_reset_otps (
    email,
    otp_hash,
    expires_at
  )
  VALUES (
    p_email,
    extensions.crypt(p_otp, extensions.gen_salt('bf')),
    NOW() + INTERVAL '10 minutes'
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.complete_password_reset(
  p_email TEXT,
  p_otp TEXT,
  p_new_password TEXT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  otp_record public.password_reset_otps%ROWTYPE;
BEGIN
  SELECT *
  INTO otp_record
  FROM public.password_reset_otps
  WHERE email = p_email
    AND consumed_at IS NULL
  ORDER BY created_at DESC
  LIMIT 1;

  IF otp_record.id IS NULL THEN
    RAISE EXCEPTION 'No active OTP found';
  END IF;

  IF otp_record.expires_at < NOW() THEN
    RAISE EXCEPTION 'OTP has expired';
  END IF;

  IF otp_record.otp_hash <> extensions.crypt(p_otp, otp_record.otp_hash) THEN
    RAISE EXCEPTION 'Invalid OTP';
  END IF;

  UPDATE auth.users
  SET encrypted_password = extensions.crypt(p_new_password, extensions.gen_salt('bf')),
      updated_at = NOW()
  WHERE email = p_email;

  DELETE FROM public.password_reset_otps
  WHERE id = otp_record.id;
END;
$$;

CREATE OR REPLACE FUNCTION public.verify_password_reset_otp(
  p_email TEXT,
  p_otp TEXT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  otp_record public.password_reset_otps%ROWTYPE;
BEGIN
  SELECT *
  INTO otp_record
  FROM public.password_reset_otps
  WHERE email = p_email
    AND consumed_at IS NULL
  ORDER BY created_at DESC
  LIMIT 1;

  IF otp_record.id IS NULL THEN
    RAISE EXCEPTION 'No active OTP found';
  END IF;

  IF otp_record.expires_at < NOW() THEN
    DELETE FROM public.password_reset_otps
    WHERE id = otp_record.id;
    RAISE EXCEPTION 'OTP has expired';
  END IF;

  IF otp_record.otp_hash <> extensions.crypt(p_otp, otp_record.otp_hash) THEN
    RAISE EXCEPTION 'Invalid OTP';
  END IF;

  DELETE FROM public.password_reset_otps
  WHERE id = otp_record.id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_password_reset_otp(TEXT, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.complete_password_reset(TEXT, TEXT, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.verify_password_reset_otp(TEXT, TEXT) TO anon, authenticated;

DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

DROP TRIGGER IF EXISTS update_students_updated_at ON students;
CREATE TRIGGER update_students_updated_at BEFORE UPDATE ON students FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

DROP TRIGGER IF EXISTS update_companies_updated_at ON companies;
CREATE TRIGGER update_companies_updated_at BEFORE UPDATE ON companies FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

DROP TRIGGER IF EXISTS update_internships_updated_at ON internships;
CREATE TRIGGER update_internships_updated_at BEFORE UPDATE ON internships FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

DROP TRIGGER IF EXISTS update_applications_updated_at ON applications;
CREATE TRIGGER update_applications_updated_at BEFORE UPDATE ON applications FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

DROP TRIGGER IF EXISTS update_student_documents_updated_at ON student_documents;
CREATE TRIGGER update_student_documents_updated_at BEFORE UPDATE ON student_documents FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

-- Secure Identity Sync via Trigger (The Proper Way)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  -- Insert into public.users if not exists
  INSERT INTO public.users (id, email, name, role)
  VALUES (
    new.id, 
    new.email, 
    COALESCE(new.raw_user_meta_data->>'name', 'Unknown User'),
    COALESCE((new.raw_user_meta_data->>'role')::user_role, 'student'::user_role)
  ) ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    name = EXCLUDED.name,
    role = EXCLUDED.role;

  IF (new.raw_user_meta_data->>'role') = 'student' THEN
    INSERT INTO public.students (user_id, name) VALUES (new.id, COALESCE(new.raw_user_meta_data->>'name', 'Unknown'))
    ON CONFLICT (user_id) DO NOTHING;
  ELSIF (new.raw_user_meta_data->>'role') = 'company' THEN
    INSERT INTO public.companies (user_id, name, industry) VALUES (new.id, COALESCE(new.raw_user_meta_data->>'name', 'Unknown'), 'Software')
    ON CONFLICT (user_id) DO NOTHING;
  END IF;

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Check-ins are stored inside applications.checkins as JSONB entries.
-- Example item:
-- {
--   "checkin_date": "2026-04-06",
--   "status": "Present",
--   "check_in_at": "2026-04-06T09:05:00Z",
--   "check_out_at": "2026-04-06T17:10:00Z",
--   "notes": ""
-- }
