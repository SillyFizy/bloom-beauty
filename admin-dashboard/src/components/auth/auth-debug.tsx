'use client';

import { useAuth } from './auth-context';
import { usePathname } from 'next/navigation';
import { useEffect, useState } from 'react';

export function AuthDebug() {
  const { token, loading } = useAuth();
  const pathname = usePathname();
  const [localStorageToken, setLocalStorageToken] = useState<string | null>(null);

  useEffect(() => {
    if (typeof window !== 'undefined') {
      setLocalStorageToken(localStorage.getItem('auth_token'));
    }
  }, [token]);

  if (process.env.NODE_ENV !== 'development') {
    return null;
  }

  return (
    <div className="fixed bottom-4 right-4 bg-black text-white p-3 rounded text-xs font-mono z-50 max-w-xs">
      <div className="space-y-1">
        <div>Path: {pathname}</div>
        <div>Loading: {loading ? 'true' : 'false'}</div>
        <div>Token: {token ? 'present' : 'null'}</div>
        <div>LocalStorage Token: {localStorageToken ? 'present' : 'null'}</div>
      </div>
    </div>
  );
} 