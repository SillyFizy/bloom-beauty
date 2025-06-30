import React from 'react';
import { render, screen } from '@testing-library/react';
import { useRouter, usePathname } from 'next/navigation';
import { AuthGuard } from '../auth-guard';
import { useAuth } from '../auth-context';

// Mock Next.js navigation
jest.mock('next/navigation', () => ({
  useRouter: jest.fn(),
  usePathname: jest.fn(),
}));

// Mock auth context
jest.mock('../auth-context', () => ({
  useAuth: jest.fn(),
}));

const mockPush = jest.fn();
const mockReplace = jest.fn();

beforeEach(() => {
  jest.clearAllMocks();
  (useRouter as jest.Mock).mockReturnValue({
    push: mockPush,
    replace: mockReplace,
  });
});

describe('AuthGuard', () => {
  it('renders children when user is authenticated', () => {
    (useAuth as jest.Mock).mockReturnValue({
      token: 'valid-token',
      loading: false,
    });
    (usePathname as jest.Mock).mockReturnValue('/dashboard');

    render(
      <AuthGuard>
        <div>Protected Content</div>
      </AuthGuard>
    );

    expect(screen.getByText('Protected Content')).toBeInTheDocument();
  });

  it('shows loading spinner when authentication is loading', () => {
    (useAuth as jest.Mock).mockReturnValue({
      token: null,
      loading: true,
    });
    (usePathname as jest.Mock).mockReturnValue('/dashboard');

    render(
      <AuthGuard>
        <div>Protected Content</div>
      </AuthGuard>
    );

    expect(screen.getByText('Loading...')).toBeInTheDocument();
    expect(screen.queryByText('Protected Content')).not.toBeInTheDocument();
  });

  it('redirects to login when user is not authenticated', () => {
    (useAuth as jest.Mock).mockReturnValue({
      token: null,
      loading: false,
    });
    (usePathname as jest.Mock).mockReturnValue('/dashboard');

    render(
      <AuthGuard>
        <div>Protected Content</div>
      </AuthGuard>
    );

    expect(mockReplace).toHaveBeenCalledWith('/login?next=%2Fdashboard');
  });

  it('allows access to excluded paths without authentication', () => {
    (useAuth as jest.Mock).mockReturnValue({
      token: null,
      loading: false,
    });
    (usePathname as jest.Mock).mockReturnValue('/login');

    render(
      <AuthGuard excludePaths={['/login']}>
        <div>Login Page</div>
      </AuthGuard>
    );

    expect(screen.getByText('Login Page')).toBeInTheDocument();
    expect(mockReplace).not.toHaveBeenCalled();
  });

  it('supports pattern matching for excluded paths', () => {
    (useAuth as jest.Mock).mockReturnValue({
      token: null,
      loading: false,
    });
    (usePathname as jest.Mock).mockReturnValue('/api/health');

    render(
      <AuthGuard excludePaths={['/api/*']}>
        <div>API Response</div>
      </AuthGuard>
    );

    expect(screen.getByText('API Response')).toBeInTheDocument();
    expect(mockReplace).not.toHaveBeenCalled();
  });

  it('does not redirect from root path', () => {
    (useAuth as jest.Mock).mockReturnValue({
      token: null,
      loading: false,
    });
    (usePathname as jest.Mock).mockReturnValue('/');

    render(
      <AuthGuard>
        <div>Root Content</div>
      </AuthGuard>
    );

    expect(mockReplace).toHaveBeenCalledWith('/login');
  });
}); 