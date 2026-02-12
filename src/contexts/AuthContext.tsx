import React, { createContext, useContext, useState, useCallback, useEffect } from 'react';
import { supabase } from '@/integrations/supabase/client';

export type AppRole = 'admin' | 'hr' | 'employee';

export interface AuthUser {
  id: string;
  email: string;
  first_name: string;
  last_name: string;
  role: AppRole;
  employee_id?: string;
  employment_status: string;
}

interface AuthContextType {
  user: AuthUser | null;
  loading: boolean;
  signIn: (email: string, password: string) => Promise<void>;
  signOut: () => void;
}

const AuthContext = createContext<AuthContextType>({
  user: null,
  loading: true,
  signIn: async () => {},
  signOut: () => {},
});

const SESSION_KEY = 'hrms_session';

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<AuthUser | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const stored = localStorage.getItem(SESSION_KEY);
    if (stored) {
      try {
        setUser(JSON.parse(stored));
      } catch {
        localStorage.removeItem(SESSION_KEY);
      }
    }
    setLoading(false);
  }, []);

  const signIn = useCallback(async (email: string, password: string) => {
    const { data, error } = await supabase.rpc('verify_user_password', {
      p_email: email,
      p_password: password,
    });

    if (error) throw new Error('Login failed');

    const result = data as any;
    if (!result.success) throw new Error(result.error || 'Invalid credentials');

    const authUser: AuthUser = {
      id: result.user.id,
      email: result.user.email,
      first_name: result.user.first_name,
      last_name: result.user.last_name,
      role: result.user.role,
      employee_id: result.user.employee_id,
      employment_status: result.user.employment_status,
    };

    setUser(authUser);
    localStorage.setItem(SESSION_KEY, JSON.stringify(authUser));
  }, []);

  const signOut = useCallback(() => {
    setUser(null);
    localStorage.removeItem(SESSION_KEY);
  }, []);

  return (
    <AuthContext.Provider value={{ user, loading, signIn, signOut }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAuth must be used within AuthProvider');
  return context;
}