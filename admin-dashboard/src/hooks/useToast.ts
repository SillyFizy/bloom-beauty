import { useState, useCallback } from 'react';

interface Toast {
  id: string;
  title?: string;
  description?: string;
  message?: string;
  type: 'success' | 'error' | 'info' | 'warning' | 'destructive';
  variant?: 'default' | 'destructive';
  duration?: number;
}

interface ToastOptions {
  title?: string;
  description?: string;
  variant?: 'default' | 'destructive';
  duration?: number;
}

export function useToast() {
  const [toasts, setToasts] = useState<Toast[]>([]);

  const toast = useCallback(
    (options: ToastOptions | string) => {
      const id = Math.random().toString(36).substr(2, 9);
      
      let toastConfig: Toast;
      
      if (typeof options === 'string') {
        // Simple string message
        toastConfig = {
          id,
          message: options,
          type: 'info',
          duration: 3000,
        };
      } else {
        // Object with title, description, variant
        const type = options.variant === 'destructive' ? 'error' : 'success';
        toastConfig = {
          id,
          title: options.title,
          description: options.description,
          type,
          variant: options.variant || 'default',
          duration: options.duration || 3000,
        };
      }

      setToasts((prev) => [...prev, toastConfig]);

      if (toastConfig.duration && toastConfig.duration > 0) {
        setTimeout(() => {
          setToasts((prev) => prev.filter((t) => t.id !== id));
        }, toastConfig.duration);
      }

      return id;
    },
    []
  );

  const showToast = useCallback(
    (message: string, type: Toast['type'] = 'info', duration = 3000) => {
      return toast({ description: message, variant: type === 'error' ? 'destructive' : 'default', duration });
    },
    [toast]
  );

  const hideToast = useCallback((id: string) => {
    setToasts((prev) => prev.filter((t) => t.id !== id));
  }, []);

  const showComingSoon = useCallback(() => {
    return toast({ description: 'Coming Soon', variant: 'default' });
  }, [toast]);

  return {
    toast,
    toasts,
    showToast,
    hideToast,
    showComingSoon,
  };
} 