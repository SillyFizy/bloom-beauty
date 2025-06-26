'use client';

import { createContext, useState, useContext, useEffect } from 'react';
import { login as apiLogin, LoginResponse, logout as apiLogout } from '@/services/auth';
import { useRouter } from 'next/navigation';
import toast from 'react-hot-toast';

interface AuthContextProps {
  token: string | null;
  login: (username: string, password: string) => Promise<void>;
  logout: () => void;
  loading: boolean;
}

const AuthContext = createContext<AuthContextProps | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [token, setToken] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const router = useRouter();

  useEffect(() => {
    const stored = localStorage.getItem('auth_token');
    if (stored) setToken(stored);
    setLoading(false);
  }, []);

  const login = async (username: string, password: string) => {
    try {
      const res: LoginResponse = await apiLogin(username, password);
      localStorage.setItem('auth_token', res.access);
      localStorage.setItem('refresh_token', res.refresh);
      setToken(res.access);
      toast.success('Logged in');
      router.replace('/products');
    } catch (err: any) {
      toast.error(err?.message || 'Invalid credentials');
      throw err;
    }
  };

  const logout = () => {
    apiLogout();
    setToken(null);
    router.replace('/login');
  };

  return (
    <AuthContext.Provider value={{ token, login, logout, loading }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}; 