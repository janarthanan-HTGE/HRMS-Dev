-- Add reporting_manager column to profiles table for storing manager name
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS reporting_manager text;