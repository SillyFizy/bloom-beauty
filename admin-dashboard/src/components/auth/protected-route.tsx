'use client';

import { useAuth } from './auth-context';
import { useRouter } from 'next/navigation';
import { useEffect, ComponentType } from 'react';

interface WithAuthOptions {
  redirectTo?: string;
  requiredPermissions?: string[];
}

/**
 * Higher-order component that adds authentication protection to any component
 */
export function withAuth<P extends object>(
  WrappedComponent: ComponentType<P>,
  options: WithAuthOptions = {}
) {
  const { redirectTo = '/login', requiredPermissions = [] } = options;

  return function ProtectedComponent(props: P) {
    const { token, loading } = useAuth();
    const router = useRouter();

    useEffect(() => {
      if (!loading && !token) {
        router.replace(redirectTo);
      }
    }, [token, loading, router]);

    if (loading) {
      return <div>Loading...</div>;
    }

    if (!token) {
      return null;
    }

    // TODO: Add permission checking logic here if needed
    // if (requiredPermissions.length > 0) {
    //   const hasPermissions = checkUserPermissions(token, requiredPermissions);
    //   if (!hasPermissions) {
    //     return <div>Access denied</div>;
    //   }
    // }

    return <WrappedComponent {...props} />;
  };
}

/**
 * Hook for protecting individual components or sections
 */
export function useProtectedRoute(options: WithAuthOptions = {}) {
  const { token, loading } = useAuth();
  const router = useRouter();
  const { redirectTo = '/login' } = options;

  useEffect(() => {
    if (!loading && !token) {
      router.replace(redirectTo);
    }
  }, [token, loading, router, redirectTo]);

  return {
    isAuthenticated: !!token,
    isLoading: loading,
    token,
  };
} 