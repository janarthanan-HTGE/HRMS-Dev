-- Create role enum
CREATE TYPE public.app_role AS ENUM ('admin', 'hr', 'employee');

-- Create status enums
CREATE TYPE public.leave_status AS ENUM ('pending', 'approved', 'rejected', 'cancelled');
CREATE TYPE public.task_status AS ENUM ('pending', 'in_progress', 'completed', 'cancelled');
CREATE TYPE public.training_status AS ENUM ('scheduled', 'in_progress', 'completed', 'cancelled');
CREATE TYPE public.goal_status AS ENUM ('not_started', 'in_progress', 'completed', 'on_hold');
CREATE TYPE public.employment_status AS ENUM ('active', 'fired', 'resigned', 'on_leave');

-- Create user_roles table (CRITICAL: roles separate from profiles)
CREATE TABLE public.user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  role public.app_role NOT NULL DEFAULT 'employee',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, role)
);

-- Create departments table
CREATE TABLE public.departments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  created_by UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create designations table
CREATE TABLE public.designations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  level INTEGER DEFAULT 1,
  created_by UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create profiles table
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
  employee_id TEXT UNIQUE,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  date_of_birth DATE,
  gender TEXT,
  address TEXT,
  city TEXT,
  state TEXT,
  country TEXT DEFAULT 'India',
  pincode TEXT,
  department_id UUID REFERENCES public.departments(id),
  designation_id UUID REFERENCES public.designations(id),
  joining_date DATE,
  employment_status public.employment_status DEFAULT 'active',
  avatar_url TEXT,
  emergency_contact_name TEXT,
  emergency_contact_phone TEXT,
  bank_name TEXT,
  bank_account_number TEXT,
  bank_ifsc TEXT,
  pan_number TEXT,
  aadhar_number TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create leave_types table
CREATE TABLE public.leave_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  default_days INTEGER DEFAULT 0,
  is_paid BOOLEAN DEFAULT true,
  requires_approval BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create leave_balances table
CREATE TABLE public.leave_balances (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  leave_type_id UUID REFERENCES public.leave_types(id) ON DELETE CASCADE NOT NULL,
  year INTEGER NOT NULL DEFAULT EXTRACT(YEAR FROM now()),
  total_days INTEGER DEFAULT 0,
  used_days INTEGER DEFAULT 0,
  remaining_days INTEGER GENERATED ALWAYS AS (total_days - used_days) STORED,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (profile_id, leave_type_id, year)
);

-- Create leaves table
CREATE TABLE public.leaves (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  leave_type_id UUID REFERENCES public.leave_types(id) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  total_days INTEGER NOT NULL,
  reason TEXT,
  status public.leave_status DEFAULT 'pending',
  approved_by UUID REFERENCES public.profiles(id),
  approved_at TIMESTAMPTZ,
  rejection_reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create attendance table
CREATE TABLE public.attendance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  attendance_date DATE NOT NULL DEFAULT CURRENT_DATE,
  check_in_time TIMESTAMPTZ,
  check_out_time TIMESTAMPTZ,
  check_in_ip TEXT,
  check_out_ip TEXT,
  total_hours NUMERIC(5,2),
  status TEXT DEFAULT 'present',
  notes TEXT,
  timesheet_completed BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (profile_id, attendance_date)
);

-- Create timesheets table
CREATE TABLE public.timesheets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  timesheet_date DATE NOT NULL DEFAULT CURRENT_DATE,
  status TEXT DEFAULT 'draft',
  total_hours NUMERIC(5,2) DEFAULT 0,
  submitted_at TIMESTAMPTZ,
  approved_by UUID REFERENCES public.profiles(id),
  approved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (profile_id, timesheet_date)
);

-- Create timesheet_entries table (10 entries per day)
CREATE TABLE public.timesheet_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  timesheet_id UUID REFERENCES public.timesheets(id) ON DELETE CASCADE NOT NULL,
  entry_number INTEGER NOT NULL CHECK (entry_number >= 1 AND entry_number <= 10),
  from_time TIME,
  to_time TIME,
  description TEXT,
  hours NUMERIC(4,2),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (timesheet_id, entry_number)
);

-- Create tasks table
CREATE TABLE public.tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  assigned_to UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  assigned_by UUID REFERENCES public.profiles(id),
  status public.task_status DEFAULT 'pending',
  priority TEXT DEFAULT 'medium',
  progress INTEGER DEFAULT 0 CHECK (progress >= 0 AND progress <= 100),
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create training table
CREATE TABLE public.training (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  domain TEXT,
  trainer_name TEXT,
  trainer_organization TEXT,
  start_date DATE,
  end_date DATE,
  duration_hours INTEGER,
  status public.training_status DEFAULT 'scheduled',
  outcome TEXT,
  certificate_url TEXT,
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create goalsheets table
CREATE TABLE public.goalsheets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  status public.goal_status DEFAULT 'not_started',
  overall_progress INTEGER DEFAULT 0 CHECK (overall_progress >= 0 AND overall_progress <= 100),
  reviewed_by UUID REFERENCES public.profiles(id),
  reviewed_at TIMESTAMPTZ,
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create goal_items table
CREATE TABLE public.goal_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  goalsheet_id UUID REFERENCES public.goalsheets(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  target_value TEXT,
  achieved_value TEXT,
  weight INTEGER DEFAULT 1,
  progress INTEGER DEFAULT 0 CHECK (progress >= 0 AND progress <= 100),
  status public.goal_status DEFAULT 'not_started',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create payroll table (Indian Standard Structure)
CREATE TABLE public.payroll (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  month INTEGER NOT NULL CHECK (month >= 1 AND month <= 12),
  year INTEGER NOT NULL,
  -- Earnings
  basic_salary NUMERIC(12,2) DEFAULT 0,
  hra NUMERIC(12,2) DEFAULT 0,
  da NUMERIC(12,2) DEFAULT 0,
  conveyance_allowance NUMERIC(12,2) DEFAULT 0,
  medical_allowance NUMERIC(12,2) DEFAULT 0,
  special_allowance NUMERIC(12,2) DEFAULT 0,
  bonus NUMERIC(12,2) DEFAULT 0,
  other_earnings NUMERIC(12,2) DEFAULT 0,
  gross_earnings NUMERIC(12,2) GENERATED ALWAYS AS (
    basic_salary + hra + da + conveyance_allowance + medical_allowance + special_allowance + bonus + other_earnings
  ) STORED,
  -- Deductions
  pf NUMERIC(12,2) DEFAULT 0,
  esi NUMERIC(12,2) DEFAULT 0,
  professional_tax NUMERIC(12,2) DEFAULT 0,
  tds NUMERIC(12,2) DEFAULT 0,
  loan_deduction NUMERIC(12,2) DEFAULT 0,
  other_deductions NUMERIC(12,2) DEFAULT 0,
  total_deductions NUMERIC(12,2) GENERATED ALWAYS AS (
    pf + esi + professional_tax + tds + loan_deduction + other_deductions
  ) STORED,
  -- Net
  net_salary NUMERIC(12,2) GENERATED ALWAYS AS (
    (basic_salary + hra + da + conveyance_allowance + medical_allowance + special_allowance + bonus + other_earnings) -
    (pf + esi + professional_tax + tds + loan_deduction + other_deductions)
  ) STORED,
  payment_date DATE,
  payment_status TEXT DEFAULT 'pending',
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (profile_id, month, year)
);

-- Create payslips table
CREATE TABLE public.payslips (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payroll_id UUID REFERENCES public.payroll(id) ON DELETE CASCADE NOT NULL,
  profile_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  payslip_number TEXT UNIQUE,
  generated_at TIMESTAMPTZ DEFAULT now(),
  pdf_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create announcements table
CREATE TABLE public.announcements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  target_roles TEXT[] DEFAULT ARRAY['admin', 'hr', 'employee'],
  priority TEXT DEFAULT 'normal',
  is_active BOOLEAN DEFAULT true,
  published_at TIMESTAMPTZ DEFAULT now(),
  expires_at TIMESTAMPTZ,
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Add foreign key for departments and designations created_by
ALTER TABLE public.departments ADD CONSTRAINT fk_departments_created_by FOREIGN KEY (created_by) REFERENCES public.profiles(id);
ALTER TABLE public.designations ADD CONSTRAINT fk_designations_created_by FOREIGN KEY (created_by) REFERENCES public.profiles(id);

-- Enable RLS on all tables
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.designations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leave_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leave_balances ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leaves ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.timesheets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.timesheet_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.training ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goalsheets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goal_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payroll ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payslips ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;

-- Create helper functions
CREATE OR REPLACE FUNCTION public.has_role(_user_id uuid, _role public.app_role)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.user_roles
    WHERE user_id = _user_id
      AND role = _role
  )
$$;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.has_role(auth.uid(), 'admin')
$$;

CREATE OR REPLACE FUNCTION public.is_hr()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.has_role(auth.uid(), 'hr')
$$;

CREATE OR REPLACE FUNCTION public.is_admin_or_hr()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.is_admin() OR public.is_hr()
$$;

CREATE OR REPLACE FUNCTION public.get_profile_id_for_user(_user_id uuid)
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT id FROM public.profiles WHERE user_id = _user_id LIMIT 1
$$;

CREATE OR REPLACE FUNCTION public.is_own_profile(_profile_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = _profile_id
      AND user_id = auth.uid()
  )
$$;

CREATE OR REPLACE FUNCTION public.has_access_to_timesheet(_timesheet_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.timesheets t
    WHERE t.id = _timesheet_id
      AND t.profile_id IN (SELECT id FROM public.profiles WHERE user_id = auth.uid())
  )
$$;

CREATE OR REPLACE FUNCTION public.has_access_to_goalsheet(_goalsheet_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.goalsheets g
    WHERE g.id = _goalsheet_id
      AND g.profile_id IN (SELECT id FROM public.profiles WHERE user_id = auth.uid())
  )
$$;

-- RLS Policies for user_roles
CREATE POLICY "Users can view own role" ON public.user_roles
  FOR SELECT USING (user_id = auth.uid() OR public.is_admin());

CREATE POLICY "Only admins can manage roles" ON public.user_roles
  FOR ALL USING (public.is_admin());

-- RLS Policies for departments
CREATE POLICY "Everyone can view departments" ON public.departments
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Admin and HR can create departments" ON public.departments
  FOR INSERT TO authenticated WITH CHECK (public.is_admin_or_hr());

CREATE POLICY "Admin and HR can update departments" ON public.departments
  FOR UPDATE TO authenticated USING (public.is_admin_or_hr());

CREATE POLICY "Only admin can delete departments" ON public.departments
  FOR DELETE TO authenticated USING (public.is_admin());

-- RLS Policies for designations
CREATE POLICY "Everyone can view designations" ON public.designations
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Admin and HR can create designations" ON public.designations
  FOR INSERT TO authenticated WITH CHECK (public.is_admin_or_hr());

CREATE POLICY "Admin and HR can update designations" ON public.designations
  FOR UPDATE TO authenticated USING (public.is_admin_or_hr());

CREATE POLICY "Only admin can delete designations" ON public.designations
  FOR DELETE TO authenticated USING (public.is_admin());

-- RLS Policies for profiles
CREATE POLICY "Users can view all profiles" ON public.profiles
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Admin and HR can create profiles" ON public.profiles
  FOR INSERT TO authenticated WITH CHECK (public.is_admin_or_hr());

CREATE POLICY "Admin HR or self can update profile" ON public.profiles
  FOR UPDATE TO authenticated USING (
    public.is_admin_or_hr() OR user_id = auth.uid()
  );

CREATE POLICY "Only admin can delete profiles" ON public.profiles
  FOR DELETE TO authenticated USING (public.is_admin());

-- RLS Policies for leave_types
CREATE POLICY "Everyone can view leave types" ON public.leave_types
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Only admin can manage leave types" ON public.leave_types
  FOR ALL TO authenticated USING (public.is_admin());

-- RLS Policies for leave_balances
CREATE POLICY "View own or admin/hr can view all balances" ON public.leave_balances
  FOR SELECT TO authenticated USING (
    public.is_admin_or_hr() OR public.is_own_profile(profile_id)
  );

CREATE POLICY "Admin and HR can manage leave balances" ON public.leave_balances
  FOR ALL TO authenticated USING (public.is_admin_or_hr());

-- RLS Policies for leaves
CREATE POLICY "View own or admin/hr can view all leaves" ON public.leaves
  FOR SELECT TO authenticated USING (
    public.is_admin_or_hr() OR public.is_own_profile(profile_id)
  );

CREATE POLICY "Users can apply for leave" ON public.leaves
  FOR INSERT TO authenticated WITH CHECK (
    public.is_own_profile(profile_id) OR public.is_admin_or_hr()
  );

CREATE POLICY "Admin HR can update any leave or self pending" ON public.leaves
  FOR UPDATE TO authenticated USING (
    public.is_admin_or_hr() OR (public.is_own_profile(profile_id) AND status = 'pending')
  );

CREATE POLICY "Admin can delete leaves" ON public.leaves
  FOR DELETE TO authenticated USING (public.is_admin());

-- RLS Policies for attendance
CREATE POLICY "View own or admin/hr can view all attendance" ON public.attendance
  FOR SELECT TO authenticated USING (
    public.is_admin_or_hr() OR public.is_own_profile(profile_id)
  );

CREATE POLICY "Users can create own attendance" ON public.attendance
  FOR INSERT TO authenticated WITH CHECK (
    public.is_own_profile(profile_id) OR public.is_admin_or_hr()
  );

CREATE POLICY "Admin HR or self can update attendance" ON public.attendance
  FOR UPDATE TO authenticated USING (
    public.is_admin_or_hr() OR public.is_own_profile(profile_id)
  );

CREATE POLICY "Only admin can delete attendance" ON public.attendance
  FOR DELETE TO authenticated USING (public.is_admin());

-- RLS Policies for timesheets
CREATE POLICY "View own or admin/hr can view all timesheets" ON public.timesheets
  FOR SELECT TO authenticated USING (
    public.is_admin_or_hr() OR public.is_own_profile(profile_id)
  );

CREATE POLICY "Users can create own timesheet" ON public.timesheets
  FOR INSERT TO authenticated WITH CHECK (
    public.is_own_profile(profile_id) OR public.is_admin_or_hr()
  );

CREATE POLICY "Admin or self can update timesheet" ON public.timesheets
  FOR UPDATE TO authenticated USING (
    public.is_admin() OR public.is_own_profile(profile_id)
  );

CREATE POLICY "Only admin can delete timesheets" ON public.timesheets
  FOR DELETE TO authenticated USING (public.is_admin());

-- RLS Policies for timesheet_entries
CREATE POLICY "View entries for accessible timesheets" ON public.timesheet_entries
  FOR SELECT TO authenticated USING (
    public.is_admin_or_hr() OR public.has_access_to_timesheet(timesheet_id)
  );

CREATE POLICY "Create entries for own timesheet" ON public.timesheet_entries
  FOR INSERT TO authenticated WITH CHECK (
    public.has_access_to_timesheet(timesheet_id) OR public.is_admin_or_hr()
  );

CREATE POLICY "Update entries for own or admin" ON public.timesheet_entries
  FOR UPDATE TO authenticated USING (
    public.is_admin() OR public.has_access_to_timesheet(timesheet_id)
  );

CREATE POLICY "Only admin can delete entries" ON public.timesheet_entries
  FOR DELETE TO authenticated USING (public.is_admin());

-- RLS Policies for tasks
CREATE POLICY "View assigned tasks or all for admin/hr" ON public.tasks
  FOR SELECT TO authenticated USING (
    public.is_admin_or_hr() OR 
    assigned_to IN (SELECT id FROM public.profiles WHERE user_id = auth.uid())
  );

CREATE POLICY "Admin and HR can create tasks" ON public.tasks
  FOR INSERT TO authenticated WITH CHECK (public.is_admin_or_hr());

CREATE POLICY "Assignee or admin/hr can update tasks" ON public.tasks
  FOR UPDATE TO authenticated USING (
    public.is_admin_or_hr() OR 
    assigned_to IN (SELECT id FROM public.profiles WHERE user_id = auth.uid())
  );

CREATE POLICY "Only admin can delete tasks" ON public.tasks
  FOR DELETE TO authenticated USING (public.is_admin());

-- RLS Policies for training
CREATE POLICY "View own or admin/hr can view all training" ON public.training
  FOR SELECT TO authenticated USING (
    public.is_admin_or_hr() OR public.is_own_profile(profile_id)
  );

CREATE POLICY "Admin and HR can create training" ON public.training
  FOR INSERT TO authenticated WITH CHECK (public.is_admin_or_hr());

CREATE POLICY "Admin and HR can update training" ON public.training
  FOR UPDATE TO authenticated USING (public.is_admin_or_hr());

CREATE POLICY "Only admin can delete training" ON public.training
  FOR DELETE TO authenticated USING (public.is_admin());

-- RLS Policies for goalsheets
CREATE POLICY "View own or admin/hr can view all goalsheets" ON public.goalsheets
  FOR SELECT TO authenticated USING (
    public.is_admin_or_hr() OR public.is_own_profile(profile_id)
  );

CREATE POLICY "Admin and HR can create goalsheets" ON public.goalsheets
  FOR INSERT TO authenticated WITH CHECK (public.is_admin_or_hr());

CREATE POLICY "Admin HR or self can update goalsheets" ON public.goalsheets
  FOR UPDATE TO authenticated USING (
    public.is_admin_or_hr() OR public.is_own_profile(profile_id)
  );

CREATE POLICY "Only admin can delete goalsheets" ON public.goalsheets
  FOR DELETE TO authenticated USING (public.is_admin());

-- RLS Policies for goal_items
CREATE POLICY "View items for accessible goalsheets" ON public.goal_items
  FOR SELECT TO authenticated USING (
    public.is_admin_or_hr() OR public.has_access_to_goalsheet(goalsheet_id)
  );

CREATE POLICY "Create items for own goalsheet or admin/hr" ON public.goal_items
  FOR INSERT TO authenticated WITH CHECK (
    public.has_access_to_goalsheet(goalsheet_id) OR public.is_admin_or_hr()
  );

CREATE POLICY "Update items for own or admin/hr" ON public.goal_items
  FOR UPDATE TO authenticated USING (
    public.is_admin_or_hr() OR public.has_access_to_goalsheet(goalsheet_id)
  );

CREATE POLICY "Only admin can delete goal items" ON public.goal_items
  FOR DELETE TO authenticated USING (public.is_admin());

-- RLS Policies for payroll
CREATE POLICY "Admin and HR can view all payroll" ON public.payroll
  FOR SELECT TO authenticated USING (
    public.is_admin_or_hr() OR public.is_own_profile(profile_id)
  );

CREATE POLICY "Only admin can manage payroll" ON public.payroll
  FOR ALL TO authenticated USING (public.is_admin_or_hr());

-- RLS Policies for payslips
CREATE POLICY "View own or admin/hr can view payslips" ON public.payslips
  FOR SELECT TO authenticated USING (
    public.is_admin_or_hr() OR public.is_own_profile(profile_id)
  );

CREATE POLICY "Only admin can manage payslips" ON public.payslips
  FOR ALL TO authenticated USING (public.is_admin_or_hr());

-- RLS Policies for announcements
CREATE POLICY "Everyone can view active announcements" ON public.announcements
  FOR SELECT TO authenticated USING (is_active = true);

CREATE POLICY "Admin and HR can create announcements" ON public.announcements
  FOR INSERT TO authenticated WITH CHECK (public.is_admin_or_hr());

CREATE POLICY "Admin and HR can update announcements" ON public.announcements
  FOR UPDATE TO authenticated USING (public.is_admin_or_hr());

CREATE POLICY "Only admin can delete announcements" ON public.announcements
  FOR DELETE TO authenticated USING (public.is_admin());

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers
CREATE TRIGGER update_departments_updated_at BEFORE UPDATE ON public.departments FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_designations_updated_at BEFORE UPDATE ON public.designations FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_leave_types_updated_at BEFORE UPDATE ON public.leave_types FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_leave_balances_updated_at BEFORE UPDATE ON public.leave_balances FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_leaves_updated_at BEFORE UPDATE ON public.leaves FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_attendance_updated_at BEFORE UPDATE ON public.attendance FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_timesheets_updated_at BEFORE UPDATE ON public.timesheets FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_timesheet_entries_updated_at BEFORE UPDATE ON public.timesheet_entries FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON public.tasks FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_training_updated_at BEFORE UPDATE ON public.training FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_goalsheets_updated_at BEFORE UPDATE ON public.goalsheets FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_goal_items_updated_at BEFORE UPDATE ON public.goal_items FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_payroll_updated_at BEFORE UPDATE ON public.payroll FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_announcements_updated_at BEFORE UPDATE ON public.announcements FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Insert default leave types
INSERT INTO public.leave_types (name, description, default_days, is_paid) VALUES
('Sick Leave', 'Leave for medical reasons', 12, true),
('Casual Leave', 'Leave for personal reasons', 12, true),
('Earned Leave', 'Paid leave earned based on service', 15, true),
('Unpaid Leave', 'Leave without pay', 0, false);

-- Create function to handle new user profile creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (user_id, first_name, last_name, email)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'first_name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
    NEW.email
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Create trigger for new user signup
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();