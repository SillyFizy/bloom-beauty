/** @type {import('next').NextConfig} */
const nextConfig = {
  // Optimize for speed
  experimental: {
    optimizePackageImports: ['lucide-react', '@tanstack/react-query'],
  },
  
  // Faster builds
  typescript: {
    // Only type-check in production builds
    ignoreBuildErrors: process.env.NODE_ENV === 'development',
  },
  
  // Optimize images
  images: {
    remotePatterns: [
      {
        protocol: 'http',
        hostname: 'localhost',
        port: '8000',
        pathname: '/media/**',
      },
      {
        protocol: 'http',
        hostname: '127.0.0.1',
        port: '8000',
        pathname: '/media/**',
      },
      {
        protocol: 'http',
        hostname: '192.168.68.127',
        port: '8000',
        pathname: '/media/**',
      },
    ],
    formats: ['image/webp'],
  },
  
  // Reduce bundle size
  compiler: {
    removeConsole: process.env.NODE_ENV === 'production',
  },
  
  // Faster development
  reactStrictMode: false, // Disable for faster development
  
  // Optimize webpack
  webpack: (config, { dev }) => {
    if (dev) {
      // Faster development builds
      config.optimization.splitChunks = false;
    }
    return config;
  },
  
  swcMinify: true,
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: [
          {
            key: 'Content-Security-Policy',
            value: [
              "default-src 'self'",
              "script-src 'self' 'unsafe-inline' 'unsafe-eval'",
              "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
              "font-src 'self' https://fonts.gstatic.com",
              "img-src 'self' data: blob: http://192.168.68.127:8000 http://localhost:8000 http://127.0.0.1:8000",
              "connect-src 'self' http://192.168.68.127:8000 http://localhost:8000 http://127.0.0.1:8000",
              "frame-src 'none'",
              "object-src 'none'",
              "base-uri 'self'",
              "form-action 'self'",
            ].join('; '),
          },
        ],
      },
    ];
  },
  async rewrites() {
    return [
      {
        source: '/api/v1/:path*',
        destination: 'http://192.168.68.127:8000/api/v1/:path*',
      },
    ];
  },
  env: {
    BACKEND_URL: process.env.BACKEND_URL || 'http://192.168.68.127:8000',
    API_BASE_URL: process.env.API_BASE_URL || 'http://192.168.68.127:8000/api/v1',
  },
};

module.exports = nextConfig; 