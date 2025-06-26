"use client";

import React from "react";
import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { AlertTriangle } from "lucide-react";

export default function CustomersPage() {
  return (
    <DashboardLayout title="Customers">
      <div className="flex flex-1 items-center justify-center">
        <div className="text-center space-y-2">
          <AlertTriangle className="mx-auto h-10 w-10 text-muted-foreground" />
          <h2 className="text-lg font-semibold text-slate-900">No data available</h2>
          <p className="text-sm text-slate-600 max-w-xs mx-auto">
            The customers feature is not yet connected to the backend. Please check back later.
          </p>
        </div>
      </div>
    </DashboardLayout>
  );
} 