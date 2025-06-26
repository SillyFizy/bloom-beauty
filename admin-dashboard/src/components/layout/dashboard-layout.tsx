'use client';

import React from 'react';
import { Sidebar } from './sidebar';
import { Header } from './header';
import { RequireAuth } from '@/components/auth/require-auth';
import { Toaster } from 'react-hot-toast';

interface DashboardLayoutProps {
  children: React.ReactNode;
  title: string;
}

export function DashboardLayout({ children, title }: DashboardLayoutProps) {
  return (
    <RequireAuth>
      <div className="flex h-screen bg-background">
        <Sidebar />

        <div className="flex flex-1 flex-col overflow-hidden">
          <Header title={title} />

          <main className="flex-1 overflow-x-hidden overflow-y-auto bg-background p-6">
            {children}
          </main>
        </div>

        {/* Toast notifications */}
        <Toaster
          position="top-right"
          toastOptions={{
            duration: 4000,
            style: {
              background: 'hsl(var(--card))',
              color: 'hsl(var(--foreground))',
              border: '1px solid hsl(var(--border))',
            },
            success: {
              style: {
                background: 'hsl(var(--primary))',
                color: 'hsl(var(--primary-foreground))',
              },
            },
            error: {
              style: {
                background: 'hsl(var(--destructive))',
                color: 'hsl(var(--destructive-foreground))',
              },
            },
          }}
        />
      </div>
    </RequireAuth>
  );
} 