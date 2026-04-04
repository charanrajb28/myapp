-- 1. Create custom enum types
CREATE TYPE user_role AS ENUM ('student', 'company', 'admin');
CREATE TYPE application_status AS ENUM ('Applied', 'Active', 'Completed', 'Upcoming', 'Rejected', 'Under Review');

-- 2. Create users table
CREATE TABLE users (
  -- Link exactly to auth.users to prevent stranded rows
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role user_role NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Create students table
CREATE TABLE students (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(255),
  college VARCHAR(255),
  department VARCHAR(255),
  resume_url TEXT,
  gpa NUMERIC(3, 2),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id)
);

-- 4. Create companies table
CREATE TABLE companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  industry VARCHAR(255),
  description TEXT,
  logo_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id)
);

-- 5. Create internships table (internship opportunities)
CREATE TABLE internships (
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
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Create applications table (student internships)
CREATE TABLE applications (
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
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(student_id, internship_id)
);

-- Row Level Security (RLS) basics (You can refine these later)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE internships ENABLE ROW LEVEL SECURITY;
ALTER TABLE applications ENABLE ROW LEVEL SECURITY;

-- Create policies for basic access
CREATE POLICY "Users can view everyone" ON users FOR SELECT USING (true);
CREATE POLICY "Students can view everyone" ON students FOR SELECT USING (true);
CREATE POLICY "Companies can view everyone" ON companies FOR SELECT USING (true);
CREATE POLICY "Internships are public" ON internships FOR SELECT USING (true);
CREATE POLICY "Applications are visible to the student and the company" ON applications FOR SELECT USING (true); -- Requires more complex policy in production

-- Functions to update 'updated_at' timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_students_updated_at BEFORE UPDATE ON students FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_companies_updated_at BEFORE UPDATE ON companies FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_internships_updated_at BEFORE UPDATE ON internships FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_applications_updated_at BEFORE UPDATE ON applications FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

-- Secure Identity Sync via Trigger (The Proper Way)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.users (id, email, name, role)
  VALUES (
    new.id, 
    new.email, 
    COALESCE(new.raw_user_meta_data->>'name', 'Unknown User'),
    COALESCE((new.raw_user_meta_data->>'role')::user_role, 'student'::user_role)
  );

  IF (new.raw_user_meta_data->>'role') = 'student' THEN
    INSERT INTO public.students (user_id, name) VALUES (new.id, COALESCE(new.raw_user_meta_data->>'name', 'Unknown'));
  ELSIF (new.raw_user_meta_data->>'role') = 'company' THEN
    INSERT INTO public.companies (user_id, name, industry) VALUES (new.id, COALESCE(new.raw_user_meta_data->>'name', 'Unknown'), 'Software');
  END IF;

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
