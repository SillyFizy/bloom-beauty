'use client';

import React from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Bell, Search, User } from 'lucide-react';
import { useToastContext } from '@/components/providers/ToastProvider';

interface HeaderProps {
  title: string;
}

export function Header({ title }: HeaderProps) {
  const { showComingSoon } = useToastContext();

  return (
    <header className="border-b bg-white px-6 py-4">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">{title}</h1>
        </div>

        <div className="flex items-center space-x-4">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
            <Input
              placeholder="Search..."
              className="pl-10 w-64"
              onFocus={showComingSoon}
            />
          </div>

          <Button variant="ghost" size="icon" onClick={showComingSoon}>
            <Bell className="h-5 w-5" />
          </Button>

          <Button variant="ghost" size="icon" onClick={showComingSoon}>
            <User className="h-5 w-5" />
          </Button>
        </div>
      </div>
    </header>
  );
} 