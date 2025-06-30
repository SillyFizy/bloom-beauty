import { useMemo } from 'react';
import { useAuth } from '@/components/auth/auth-context';

interface CurrentUser {
  firstName: string;
  lastName: string;
  fullName: string;
  phoneNumber: string;
  initials: string;
}

function decodeJWT(token: string): any {
  try {
    const [, payload] = token.split('.');
    const base64 = payload.replace(/-/g, '+').replace(/_/g, '/');
    const jsonPayload = decodeURIComponent(
      atob(base64)
        .split('')
        .map((c) => {
          return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2);
        })
        .join('')
    );
    return JSON.parse(jsonPayload);
  } catch (e) {
    return null;
  }
}

export function useCurrentUser(): CurrentUser {
  const { token } = useAuth();

  return useMemo(() => {
    if (!token) {
      return {
        firstName: 'Guest',
        lastName: '',
        fullName: 'Guest',
        phoneNumber: '',
        initials: 'G',
      };
    }

    const payload = decodeJWT(token);
    const firstName = payload?.first_name || 'User';
    const lastName = payload?.last_name || '';
    const phoneNumber = payload?.phone_number || '';
    const fullName = `${firstName}${lastName ? ' ' + lastName : ''}`;
    const initials = `${firstName.charAt(0)}${lastName.charAt(0) || ''}`.toUpperCase();

    return {
      firstName,
      lastName,
      fullName,
      phoneNumber,
      initials,
    };
  }, [token]);
} 