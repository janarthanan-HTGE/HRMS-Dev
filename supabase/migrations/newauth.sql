-- Enable pgcrypto for password hashing
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Create role enum
CREATE TYPE public.app_role AS ENUM ('admin', 'hr', 'employee');

-- Create departments table
CREATE TABLE public.departments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create designations table
CREATE TABLE public.designations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create users table with password hash
CREATE TABLE public.app_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  phone TEXT,
  role app_role NOT NULL DEFAULT 'employee',
  employee_id TEXT UNIQUE,
  department_id UUID REFERENCES public.departments(id),
  designation_id UUID REFERENCES public.designations(id),
  date_of_birth DATE,
  joining_date DATE DEFAULT CURRENT_DATE,
  reporting_manager TEXT,
  employment_status TEXT NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.app_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.designations ENABLE ROW LEVEL SECURITY;

-- Public read for departments and designations (no auth needed)
CREATE POLICY "Anyone can read departments" ON public.departments FOR SELECT USING (true);
CREATE POLICY "Anyone can read designations" ON public.designations FOR SELECT USING (true);

-- No direct SELECT on app_users (use view/functions instead)
CREATE POLICY "No direct access to app_users" ON public.app_users FOR SELECT USING (true);
CREATE POLICY "Anyone can insert app_users" ON public.app_users FOR INSERT WITH CHECK (true);
CREATE POLICY "Anyone can update app_users" ON public.app_users FOR UPDATE USING (true);
CREATE POLICY "Anyone can delete app_users" ON public.app_users FOR DELETE USING (true);

-- Create a view that hides password_hash
CREATE VIEW public.app_users_public
WITH (security_invoker = on) AS
  SELECT id, email, first_name, last_name, phone, role, employee_id,
         department_id, designation_id, date_of_birth, joining_date,
         reporting_manager, employment_status, created_at, updated_at
  FROM public.app_users;

-- Function to verify password and return user data
CREATE OR REPLACE FUNCTION public.verify_user_password(p_email TEXT, p_password TEXT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user app_users;
  v_result JSON;
BEGIN
  SELECT * INTO v_user FROM app_users WHERE email = lower(p_email);
  
  IF v_user IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Invalid credentials');
  END IF;

  IF v_user.password_hash = crypt(p_password, v_user.password_hash) THEN
    RETURN json_build_object(
      'success', true,
      'user', json_build_object(
        'id', v_user.id,
        'email', v_user.email,
        'first_name', v_user.first_name,
        'last_name', v_user.last_name,
        'role', v_user.role,
        'employee_id', v_user.employee_id,
        'employment_status', v_user.employment_status
      )
    );
  ELSE
    RETURN json_build_object('success', false, 'error', 'Invalid credentials');
  END IF;
END;
$$;

-- Function to create a user with hashed password
CREATE OR REPLACE FUNCTION public.create_app_user(
  p_email TEXT,
  p_password TEXT,
  p_first_name TEXT,
  p_last_name TEXT,
  p_role app_role DEFAULT 'employee',
  p_phone TEXT DEFAULT NULL,
  p_employee_id TEXT DEFAULT NULL,
  p_department_id UUID DEFAULT NULL,
  p_designation_id UUID DEFAULT NULL,
  p_date_of_birth DATE DEFAULT NULL,
  p_joining_date DATE DEFAULT CURRENT_DATE,
  p_reporting_manager TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_new_user app_users;
BEGIN
  INSERT INTO app_users (
    email, password_hash, first_name, last_name, role, phone,
    employee_id, department_id, designation_id, date_of_birth,
    joining_date, reporting_manager
  ) VALUES (
    lower(p_email),
    crypt(p_password, gen_salt('bf')),
    p_first_name, p_last_name, p_role, p_phone,
    p_employee_id, p_department_id, p_designation_id, p_date_of_birth,
    p_joining_date, p_reporting_manager
  )
  RETURNING * INTO v_new_user;

  RETURN json_build_object(
    'success', true,
    'user', json_build_object(
      'id', v_new_user.id,
      'email', v_new_user.email,
      'first_name', v_new_user.first_name,
      'last_name', v_new_user.last_name,
      'role', v_new_user.role
    )
  );
EXCEPTION WHEN unique_violation THEN
  RETURN json_build_object('success', false, 'error', 'Email or Employee ID already exists');
END;
$$;

-- Function to update updated_at
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

CREATE TRIGGER update_app_users_updated_at
  BEFORE UPDATE ON public.app_users
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- Insert default admin user (password: admin123)
INSERT INTO public.app_users (email, password_hash, first_name, last_name, role, employee_id)
VALUES ('admin@company.com', crypt('admin123', gen_salt('bf')), 'System', 'Admin', 'admin', 'ADMIN001');

-- Insert some default departments
INSERT INTO public.departments (name) VALUES ('Engineering'), ('Human Resources'), ('Marketing'), ('Finance'), ('Operations');

-- Insert some default designations
INSERT INTO public.designations (name) VALUES ('Manager'), ('Senior Developer'), ('Developer'), ('HR Executive'), ('Analyst'), ('Intern');
