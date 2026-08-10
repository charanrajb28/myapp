-- SQLite / Turso DB Schema for Aaroha Platform

-- 1. Users Table
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY, -- Firebase Auth UID
  role TEXT NOT NULL CHECK(role IN ('student', 'company', 'admin', 'sub_admin')),
  email TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- 2. Students Table
CREATE TABLE IF NOT EXISTS students (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  enrollment_id TEXT,
  name TEXT,
  college TEXT DEFAULT 'Sheshadri Institute of Technology',
  department TEXT,
  semester TEXT,
  contact_email TEXT,
  phone_number TEXT,
  avatar_url TEXT,
  parent_contact TEXT,
  parent_email TEXT,
  resume_url TEXT,
  document_urls TEXT DEFAULT '[]',
  gpa REAL,
  graduation_year INTEGER,
  is_blacklisted INTEGER DEFAULT 0,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- 3. Companies Table
CREATE TABLE IF NOT EXISTS companies (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  industry TEXT,
  location TEXT,
  website TEXT,
  phone TEXT,
  contact_email TEXT,
  description TEXT,
  logo_url TEXT,
  banner_url TEXT,
  mou_date TEXT,
  partner_since INTEGER,
  is_blacklisted INTEGER DEFAULT 0,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- 4. Internships Table
CREATE TABLE IF NOT EXISTS internships (
  id TEXT PRIMARY KEY,
  company_id TEXT REFERENCES companies(id) ON DELETE CASCADE,
  role TEXT NOT NULL,
  industry TEXT,
  location TEXT NOT NULL,
  location_address TEXT,
  location_lat REAL,
  location_lng REAL,
  stipend TEXT,
  duration TEXT,
  deadline TEXT,
  brand_color TEXT,
  logo_initial TEXT,
  about TEXT,
  requirements TEXT DEFAULT '[]',
  responsibilities TEXT DEFAULT '[]',
  status TEXT DEFAULT 'UNDER_REVIEW',
  start_date TEXT,
  end_date TEXT,
  application_duration_days INTEGER DEFAULT 7,
  vacancies INTEGER DEFAULT 1,
  eligible_departments TEXT DEFAULT '[]',
  eligible_years TEXT DEFAULT '[]',
  active_days TEXT DEFAULT '[]',
  notes TEXT DEFAULT '',
  feedback_form_schema TEXT DEFAULT '[]',
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- 5. Applications Table
CREATE TABLE IF NOT EXISTS applications (
  id TEXT PRIMARY KEY,
  student_id TEXT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  internship_id TEXT NOT NULL REFERENCES internships(id) ON DELETE CASCADE,
  status TEXT DEFAULT 'Applied' CHECK(status IN ('Applied', 'Accepted', 'Active', 'Completed', 'Upcoming', 'Rejected', 'Under Review', 'Removed')),
  applied_at TEXT DEFAULT CURRENT_TIMESTAMP,
  progress REAL DEFAULT 0.0,
  checkins TEXT DEFAULT '[]',
  feedback_data TEXT DEFAULT '{}',
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- 6. Student Documents Table
CREATE TABLE IF NOT EXISTS student_documents (
  id TEXT PRIMARY KEY,
  student_id TEXT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  url TEXT NOT NULL,
  type TEXT,
  size INTEGER,
  uploaded_at TEXT DEFAULT CURRENT_TIMESTAMP,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- 7. Password Reset OTPs Table
CREATE TABLE IF NOT EXISTS password_reset_otps (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL,
  otp_hash TEXT NOT NULL,
  expires_at TEXT NOT NULL,
  consumed_at TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- 8. User Device Sessions Table
CREATE TABLE IF NOT EXISTS user_device_sessions (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  device_token TEXT NOT NULL,
  device_info TEXT NOT NULL,
  is_active INTEGER NOT NULL DEFAULT 1,
  logged_in_at TEXT DEFAULT CURRENT_TIMESTAMP,
  logged_out_at TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- 9. Student Notifications Table
CREATE TABLE IF NOT EXISTS student_notifications (
  id TEXT PRIMARY KEY,
  student_id TEXT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT,
  is_read INTEGER DEFAULT 0,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- 10. Feedbacks Table
CREATE TABLE IF NOT EXISTS feedbacks (
  id TEXT PRIMARY KEY,
  user_id TEXT REFERENCES users(id) ON DELETE SET NULL,
  category TEXT,
  message TEXT NOT NULL,
  rating INTEGER,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- 11. Sub Admins Table
CREATE TABLE IF NOT EXISTS sub_admins (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  created_by TEXT REFERENCES users(id) ON DELETE SET NULL,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Triggers for updated_at timestamps
CREATE TRIGGER IF NOT EXISTS trg_users_updated_at AFTER UPDATE ON users
BEGIN
  UPDATE users SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS trg_students_updated_at AFTER UPDATE ON students
BEGIN
  UPDATE students SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS trg_companies_updated_at AFTER UPDATE ON companies
BEGIN
  UPDATE companies SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS trg_internships_updated_at AFTER UPDATE ON internships
BEGIN
  UPDATE internships SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS trg_applications_updated_at AFTER UPDATE ON applications
BEGIN
  UPDATE applications SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS trg_student_documents_updated_at AFTER UPDATE ON student_documents
BEGIN
  UPDATE student_documents SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;
