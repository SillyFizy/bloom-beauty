import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

// All routes are considered protected by default. Add any publicly accessible route
// (that should bypass the auth check) to this set. Keep the list minimal to avoid
// accidental exposure of sensitive pages.
const PUBLIC_ROUTES = new Set<string>(['/login']);

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;
  
  // Skip processing for static files and API routes - fastest path
  if (
    pathname.startsWith('/_next/') ||
    pathname.startsWith('/api/') ||
    pathname.includes('.')
  ) {
    return NextResponse.next();
  }

  // Get token - prioritize cookies for SSR
  const token = request.cookies.get('auth_token')?.value;

  // Handle root path immediately
  if (pathname === '/') {
    const redirectUrl = token ? '/dashboard' : '/login';
    return NextResponse.redirect(new URL(redirectUrl, request.url));
  }

  // Public routes are always accessible. If an authenticated user visits /login,
  // we redirect them to /dashboard to avoid showing the login form again.
  if (PUBLIC_ROUTES.has(pathname)) {
    if (token && pathname === '/login') {
      return NextResponse.redirect(new URL('/dashboard', request.url));
    }
    return NextResponse.next();
  }

  // All remaining (non-public) routes require authentication. If no token is
  // found, immediately redirect to the login page **before** the route (layout
  // or page) is rendered on either the server or the client.
  if (!token) {
    return NextResponse.redirect(new URL('/login', request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: [
    /*
     * Match all request paths except static files
     * Optimized matcher for better performance
     */
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp|ico|css|js)$).*)',
  ],
}; 