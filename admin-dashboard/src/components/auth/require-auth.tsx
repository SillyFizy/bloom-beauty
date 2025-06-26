'use client';

import { useAuth } from './auth-context';
import { useRouter, usePathname } from 'next/navigation';
import { useEffect } from 'react';
import { Loader2 } from 'lucide-react';

export const RequireAuth: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { token, loading } = useAuth();
  const router = useRouter();
  const pathname = usePathname();

  useEffect(() => {
    if (!loading && !token) {
      router.replace(`/login?next=${encodeURIComponent(pathname)}`);
    }
  }, [token, loading, pathname, router]);

  if (loading || !token) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <Loader2 className="animate-spin w-8 h-8 text-slate-500" />
      </div>
    );
  }

  return <>{children}</>;
}; 