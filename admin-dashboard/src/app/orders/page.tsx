"use client";

import React, { useState } from 'react';
import { DashboardLayout } from '@/components/layout/dashboard-layout';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { useOrders } from '@/hooks/use-orders';
import { OrderTable } from '@/components/orders/order-table';
import { Loader2, Search } from 'lucide-react';

export default function OrdersPage() {
  const [search, setSearch] = useState('');
  const [debouncedSearch, setDebouncedSearch] = useState('');

  const filters = { search: debouncedSearch, page_size: 50 } as const;
  const { data, isLoading, isError, refetch } = useOrders(filters);

  const handleSearchChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    setSearch(value);
    if (typeof window !== 'undefined') {
      window.clearTimeout((handleSearchChange as any).timer);
      (handleSearchChange as any).timer = window.setTimeout(() => {
        setDebouncedSearch(value.trim());
      }, 400);
    }
  };

  return (
    <DashboardLayout title="Orders">
      <div className="space-y-6">
        <div className="flex items-center gap-3">
          <div className="relative w-full max-w-sm">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
            <Input
              placeholder="Search orders by id or customer name..."
              value={search}
              onChange={handleSearchChange}
              className="pl-9"
            />
          </div>
          <Button variant="outline" onClick={() => refetch()}>
            Refresh
          </Button>
        </div>

        {isLoading ? (
          <div className="flex items-center justify-center py-32">
            <Loader2 className="h-6 w-6 animate-spin text-slate-500" />
          </div>
        ) : isError || !data ? (
          <div className="flex items-center justify-center py-32 text-center">
            <p className="text-sm text-slate-500 max-w-xs">Failed to load orders. Please try again later.</p>
          </div>
        ) : data.results.length === 0 ? (
          <div className="flex items-center justify-center py-32 text-center">
            <p className="text-sm text-slate-500 max-w-xs">No orders found.</p>
          </div>
        ) : (
          <OrderTable orders={data.results} />
        )}
      </div>
    </DashboardLayout>
  );
} 