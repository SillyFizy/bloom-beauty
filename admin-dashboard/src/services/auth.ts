import { apiClient } from '@/lib/api';

export interface LoginResponse {
  access: string;
  refresh: string;
}

export async function login(phoneNumber: string, password: string): Promise<LoginResponse> {
  return apiClient.post<LoginResponse>('users/login/', { phone_number: phoneNumber, password });
}

export function logout() {
  localStorage.removeItem('auth_token');
  localStorage.removeItem('refresh_token');
} 