'use client';

import React from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { cn } from '@/lib/utils';
import { Package, LayoutDashboard, ShoppingCart, Users, Truck, Folder, Tag, Star } from 'lucide-react';

const sidebarItems = [
  {
    title: 'Dashboard',
    href: '/dashboard',
    icon: LayoutDashboard,
  },
  {
    title: 'Products',
    href: '/products',
    icon: Package,
  },
  {
    title: 'Celebrities',
    href: '/celebrities',
    icon: Star,
  },
  {
    title: 'Orders',
    href: '/orders',
    icon: ShoppingCart,
  },
  {
    title: 'Customers',
    href: '/customers',
    icon: Users,
  },
  {
    title: 'Shipping',
    href: '/shipping',
    icon: Truck,
  },
  {
    title: 'Categories',
    href: '/categories',
    icon: Folder,
  },
  {
    title: 'Brands',
    href: '/brands',
    icon: Tag,
  },
];

export function Sidebar() {
  const pathname = usePathname();

  return (
    <div className="flex h-full w-64 flex-col bg-white shadow-lg border-r border-border">
      {/* Logo */}
      <div className="flex h-16 items-center justify-center border-b border-border bg-gradient-to-r from-primary to-primary/90">
        <div className="flex items-center space-x-2">
          <div className="w-8 h-8 bg-white/20 rounded-lg flex items-center justify-center backdrop-blur-sm">
            <span className="text-white font-bold text-sm">BB</span>
          </div>
          <h1 className="text-xl font-bold text-white">Bloom Beauty</h1>
        </div>
      </div>

      {/* Navigation */}
      <nav className="flex-1 space-y-1 p-4">
        {sidebarItems.map((item) => {
          const isActive = pathname === item.href || (item.href !== '/' && pathname.startsWith(item.href));

          return (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                'flex items-center rounded-lg px-3 py-2 text-sm font-medium transition-all duration-200',
                isActive
                  ? 'bg-primary text-white shadow-sm'
                  : 'text-muted-foreground hover:bg-primary/10 hover:text-primary'
              )}
            >
              <item.icon className="mr-3 h-5 w-5" />
              {item.title}
            </Link>
          );
        })}
      </nav>

      {/* User Info */}
      <div className="border-t border-border p-4">
        <div className="flex items-center">
          <div className="h-8 w-8 rounded-full bg-gradient-to-br from-primary to-primary/80 flex items-center justify-center">
            <span className="text-sm font-medium text-white">A</span>
          </div>
          <div className="ml-3">
            <p className="text-sm font-medium text-foreground">Admin User</p>
            <p className="text-xs text-muted-foreground">admin@bloombeauty.com</p>
          </div>
        </div>
      </div>
    </div>
  );
} 