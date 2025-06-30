'use client';

import React from 'react';
import { Sidebar } from './sidebar';
import { Header } from './header';
import { Toaster } from 'react-hot-toast';
import { withAuth } from '@/components/auth/protected-route';

interface DashboardLayoutProps {
  children: React.ReactNode;
  title: string;
}

function RawDashboardLayout({ children, title }: DashboardLayoutProps) {
  return (
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
  );
}

export const DashboardLayout = withAuth<DashboardLayoutProps>(RawDashboardLayout);

export type { DashboardLayoutProps }; 