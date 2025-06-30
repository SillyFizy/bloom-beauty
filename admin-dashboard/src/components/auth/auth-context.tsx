'use client';

import { createContext, useState, useContext, useEffect } from 'react';
import { login as apiLogin, LoginResponse, logout as apiLogout } from '@/services/auth';
import { useRouter } from 'next/navigation';
import { apiClient } from '@/lib/api';
import toast from 'react-hot-toast';

interface AuthContextProps {
  token: string | null;
  login: (username: string, password: string) => Promise<void>;
  logout: () => void;
  loading: boolean;
}

const AuthContext = createContext<AuthContextProps | undefined>(undefined);

// Optimized cookie functions
const setCookie = (name: string, value: string, days: number = 7) => {
  if (typeof window === 'undefined') return;
  const expires = new Date(Date.now() + days * 24 * 60 * 60 * 1000);
  document.cookie = `${name}=${value};expires=${expires.toUTCString()};path=/;SameSite=Lax`;
};

const getCookie = (name: string): string | null => {
  if (typeof window === 'undefined') return null;
  const match = document.cookie.match(new RegExp('(^| )' + name + '=([^;]+)'));
  return match ? match[2] : null;
};

const deleteCookie = (name: string) => {
  if (typeof window === 'undefined') return;
  document.cookie = `${name}=;expires=Thu, 01 Jan 1970 00:00:00 UTC;path=/;`;
};

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [token, setToken] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const router = useRouter();

  useEffect(() => {
    // Fast token check - prioritize cookies since middleware uses them
    if (typeof window !== 'undefined') {
      const storedToken = getCookie('auth_token') || localStorage.getItem('auth_token');
      if (storedToken) {
        setToken(storedToken);
        apiClient.updateTokenCache(storedToken);
        // Sync storage if needed
        if (!getCookie('auth_token')) setCookie('auth_token', storedToken);
        if (!localStorage.getItem('auth_token')) localStorage.setItem('auth_token', storedToken);
      }
    }
    setLoading(false);
  }, []);

  const login = async (username: string, password: string) => {
    try {
      const res: LoginResponse = await apiLogin(username, password);
      
      // Store tokens immediately
      if (typeof window !== 'undefined') {
        localStorage.setItem('auth_token', res.access);
        localStorage.setItem('refresh_token', res.refresh);
        setCookie('auth_token', res.access, 7);
        setCookie('refresh_token', res.refresh, 7);
      }
      
      setToken(res.access);
      apiClient.updateTokenCache(res.access);
      toast.success('Logged in successfully');
      
      // Simple redirect to dashboard - no complex URL parsing
      router.replace('/dashboard');
    } catch (err: any) {
      toast.error(err?.message || 'Invalid credentials');
      throw err;
    }
  };

  const logout = () => {
    apiLogout();
    setToken(null);
    apiClient.clearTokenCache();
    
    // Clear tokens
    if (typeof window !== 'undefined') {
      localStorage.removeItem('auth_token');
      localStorage.removeItem('refresh_token');
      deleteCookie('auth_token');
      deleteCookie('refresh_token');
    }
    
    toast.success('Logged out successfully');
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