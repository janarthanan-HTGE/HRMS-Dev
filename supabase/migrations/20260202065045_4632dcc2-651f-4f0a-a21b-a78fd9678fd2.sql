-- Create target_types table for predefined targets
CREATE TABLE public.target_types (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name text NOT NULL UNIQUE,
  description text,
  is_active boolean DEFAULT true,
  sort_order integer DEFAULT 0,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.target_types ENABLE ROW LEVEL SECURITY;

-- Everyone can view target types
CREATE POLICY "Everyone can view target types" 
ON public.target_types 
FOR SELECT 
USING (true);

-- Only admin can manage target types
CREATE POLICY "Only admin can manage target types" 
ON public.target_types 
FOR ALL 
USING (is_admin());

-- Insert default target types
INSERT INTO public.target_types (name, description, sort_order) VALUES
  ('HTVP', 'High Value Target Projects', 1),
  ('New Clients Target', 'New client acquisition targets', 2),
  ('KT', 'Knowledge Transfer', 3),
  ('VP Documentation', 'Vice President Documentation', 4),
  ('Internal Promotions', 'Internal promotion activities', 5),
  ('Weekly Work Plan', 'Weekly work planning', 6),
  ('Weekly Report', 'Weekly reporting', 7),
  ('Out Of Box', 'Out of box thinking initiatives', 8);

-- Add new columns to goal_items for weekly entries
ALTER TABLE public.goal_items 
  ADD COLUMN IF NOT EXISTS target_type_id uuid REFERENCES public.target_types(id),
  ADD COLUMN IF NOT EXISTS week1_value text,
  ADD COLUMN IF NOT EXISTS week2_value text,
  ADD COLUMN IF NOT EXISTS week3_value text,
  ADD COLUMN IF NOT EXISTS week4_value text,
  ADD COLUMN IF NOT EXISTS week1_submitted boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS week2_submitted boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS week3_submitted boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS week4_submitted boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS overall_value text,
  ADD COLUMN IF NOT EXISTS overall_percentage numeric DEFAULT 0;

-- Add reporting_manager to goalsheets
ALTER TABLE public.goalsheets 
  ADD COLUMN IF NOT EXISTS reporting_manager_id uuid REFERENCES public.profiles(id),
  ADD COLUMN IF NOT EXISTS month integer,
  ADD COLUMN IF NOT EXISTS year integer;