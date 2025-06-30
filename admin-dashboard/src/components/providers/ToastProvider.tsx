'use client';

import React, { createContext, useContext } from 'react';
import { ToastContainer } from '@/components/ui/toast';
import { useToast } from '@/hooks/useToast';

interface ToastOptions {
  title?: string;
  description?: string;
  variant?: 'default' | 'destructive';
  duration?: number;
}

interface ToastContextType {
  toast: (options: ToastOptions | string) => string;
  showToast: (
    message: string,
    type?: 'success' | 'error' | 'info' | 'warning',
    duration?: number
  ) => string;
  showComingSoon: () => string;
}

const ToastContext = createContext<ToastContextType | null>(null);

export function ToastProvider({ children }: { children: React.ReactNode }) {
  const { toasts, hideToast, toast, showToast, showComingSoon } = useToast();

  return (
    <ToastContext.Provider value={{ toast, showToast, showComingSoon }}>
      {children}
      <ToastContainer toasts={toasts} onClose={hideToast} />
    </ToastContext.Provider>
  );
}

export function useToastContext() {
  const context = useContext(ToastContext);
  if (!context) {
    throw new Error('useToastContext must be used within a ToastProvider');
  }
  return context;
} 