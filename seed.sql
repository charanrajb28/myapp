-- RUN THIS SCRIPT IN YOUR SUPABASE SQL EDITOR

-- 1. Create a function to safely insert users into auth.users (Needed to let Admin create accounts directly)
CREATE OR REPLACE FUNCTION admin_create_user(
  user_email TEXT,
  user_password TEXT,
  user_role TEXT,
  user_name TEXT
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  new_user_id UUID;
  encrypted_pw TEXT;
BEGIN
  -- Verify that the caller is an admin (Optional extra check, but handled by app logic for now)
  -- IF NOT (SELECT role FROM public.users WHERE id = auth.uid()) = 'admin' THEN
  --   RAISE EXCEPTION 'Not authorized';
  -- END IF;

  new_user_id := gen_random_uuid();
  encrypted_pw := extensions.crypt(user_password, extensions.gen_salt('bf'));

  -- Insert into Supabase Auth
  INSERT INTO auth.users (
    id, instance_id, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, aud, role,
    created_at, updated_at
  )
  VALUES (
    new_user_id, '00000000-0000-0000-0000-000000000000', user_email, encrypted_pw, now(),
    '{"provider":"email","providers":["email"]}',
    jsonb_build_object('name', user_name, 'role', user_role),
    'authenticated', 'authenticated', now(), now()
  );

  INSERT INTO auth.identities (
    id, user_id, identity_data, provider, provider_id, created_at, updated_at
  )
  VALUES (
    gen_random_uuid(), new_user_id,
    format('{"sub":"%s","email":"%s"}', new_user_id::text, user_email)::jsonb,
    'email', user_email, now(), now()
  );

  -- Determine the enum value
  -- Insert into public.users
  INSERT INTO public.users (id, role, email, name)
  VALUES (new_user_id, user_role::user_role, user_email, user_name);

  -- Also populate the specific role table
  IF user_role = 'student' THEN
    INSERT INTO public.students (user_id, name) VALUES (new_user_id, user_name);
  ELSIF user_role = 'company' THEN
    INSERT INTO public.companies (user_id, name, industry) VALUES (new_user_id, user_name, 'Software');
  END IF;

  RETURN new_user_id;
END;
$$;


-- 2. Create the first Default Admin User natively
SELECT admin_create_user(
  'admin@scholarbridge.com', 
  'admin123', 
  'admin', 
  'System Admin'
);

-- Note: You can optionally create demo student/company users right now too!
SELECT admin_create_user(
  'student@college.edu', 
  'student123', 
  'student', 
  'Alex Demo'
);

SELECT admin_create_user(
  'hr@techcorp.com', 
  'company123', 
  'company', 
  'TechCorp HR'
);
