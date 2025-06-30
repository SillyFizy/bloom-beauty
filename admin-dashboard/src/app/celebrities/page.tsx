'use client';

import { DashboardLayout } from '@/components/layout/dashboard-layout';
import { CelebrityTable } from '@/components/celebrities/celebrity-table';
import { Button } from '@/components/ui/button';
import { Plus } from 'lucide-react';
import { AddCelebrityDialog } from '@/components/celebrities/add-celebrity-dialog';
import React from 'react';

export default function CelebritiesPage() {
  const [showAddDialog, setShowAddDialog] = React.useState(false);

  return (
    <DashboardLayout title="Celebrities">
      <div className="flex flex-col gap-6">
        {/* Page header & actions */}
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-2xl font-bold tracking-tight">Celebrity Management</h2>
            <p className="text-muted-foreground max-w-prose">
              Manage celebrity profiles, their routines, and associated product promotions.
            </p>
          </div>

          <Button onClick={() => setShowAddDialog(true)}>
            <Plus className="h-4 w-4 mr-2" />
            Add Celebrity
          </Button>
        </div>

        {/* Main table */}
        <CelebrityTable />

        {/* Dialogs */}
        {showAddDialog && (
          <AddCelebrityDialog open={showAddDialog} onOpenChange={setShowAddDialog} />
        )}
      </div>
    </DashboardLayout>
  );
} 