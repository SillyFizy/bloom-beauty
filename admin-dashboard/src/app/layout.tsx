import type { Metadata, Viewport } from 'next';
import { Inter } from 'next/font/google';
import './globals.css';
import { Providers } from '@/components/providers/providers';

const inter = Inter({ 
  subsets: ['latin'],
  display: 'swap',
  variable: '--font-inter',
});

export const metadata: Metadata = {
  title: 'Bloom Beauty Admin Dashboard',
  description: 'Modern admin dashboard for managing Bloom Beauty products, celebrities, and orders',
  keywords: ['admin', 'dashboard', 'beauty', 'e-commerce', 'management'],
  authors: [{ name: 'Bloom Beauty Team' }],
};

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  themeColor: '#fafafa',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className={`${inter.variable} bg-[#fafafa]`}>
      <head>
        <link rel="icon" href="/favicon.ico" />
        <link rel="apple-touch-icon" href="/apple-touch-icon.png" />
      </head>
      <body className={`${inter.className} antialiased bg-background min-h-screen`}>
        <Providers>
          {children}
        </Providers>
      </body>
    </html>
  );
} 