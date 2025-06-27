'use client';

import React from 'react';
import { RequireAuth } from '@/components/auth/require-auth';
import { DashboardLayout } from '@/components/layout/dashboard-layout';
import { CelebrityTable } from '@/components/celebrities/celebrity-table';

export default function CelebritiesPage() {
  return (
    <RequireAuth>
      <DashboardLayout title="Celebrities">
        <div className="space-y-6">
          {/* Page Header */}
          <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <h1 className="text-3xl font-bold tracking-tight text-foreground">
                Celebrity Management
              </h1>
              <p className="text-muted-foreground">
                Manage celebrity profiles, routines, and product endorsements
              </p>
            </div>
          </div>

          {/* Main Content */}
          <CelebrityTable />
        </div>
      </DashboardLayout>
    </RequireAuth>
  );
} 