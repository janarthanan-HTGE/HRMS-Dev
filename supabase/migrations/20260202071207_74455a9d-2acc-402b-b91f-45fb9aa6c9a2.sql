-- Add out_of_box column to goal_items table
ALTER TABLE public.goal_items 
ADD COLUMN IF NOT EXISTS out_of_box text;

-- Add week column to goalsheets table
ALTER TABLE public.goalsheets 
ADD COLUMN IF NOT EXISTS week integer;