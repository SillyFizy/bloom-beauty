'use client';

import { useForm } from 'react-hook-form';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { useAuth } from '@/components/auth/auth-context';
import { Loader2, Eye, EyeOff } from 'lucide-react';
import React, { useState } from 'react';

interface LoginForm {
  phone_number: string;
  password: string;
}

export default function LoginPage() {
  const { login } = useAuth();
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<LoginForm>();

  const [showPassword, setShowPassword] = useState(false);

  const onSubmit = async (values: LoginForm) => {
    await login(values.phone_number, values.password);
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-primary-50 via-primary-100 to-primary-200 p-4">
      <div className="w-full max-w-md bg-card shadow-xl rounded-2xl p-8 space-y-6 border border-border">
        <div className="text-center space-y-2">
          <div className="flex items-center justify-center space-x-2">
            <div className="bg-primary p-2 rounded-lg shadow-md">
              <span className="text-primary-foreground font-bold text-lg">BB</span>
            </div>
            <h1 className="text-3xl font-extrabold text-foreground tracking-tight">Bloom Beauty</h1>
          </div>
          <p className="text-sm text-muted-foreground">Admin Portal</p>
        </div>
        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
          <div className="space-y-1">
            <label htmlFor="phone" className="text-sm font-medium text-foreground">
              Phone Number
            </label>
            <Input
              id="phone"
              {...register('phone_number', { required: 'Required' })}
              placeholder="e.g. +9647712345678"
              disabled={isSubmitting}
            />
            {errors.phone_number && <p className="text-xs text-destructive mt-1">{errors.phone_number.message}</p>}
          </div>
          <div className="space-y-1">
            <label htmlFor="password" className="text-sm font-medium text-foreground">
              Password
            </label>
            <div className="relative">
              <Input
                id="password"
                type={showPassword ? 'text' : 'password'}
                {...register('password', { required: 'Required' })}
                placeholder="••••••••"
                disabled={isSubmitting}
                className="pr-10"
              />
              <button
                type="button"
                onClick={() => setShowPassword((prev) => !prev)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground focus:outline-none"
                aria-label={showPassword ? 'Hide password' : 'Show password'}
              >
                {showPassword ? <EyeOff className="h-5 w-5" /> : <Eye className="h-5 w-5" />}
              </button>
            </div>
            {errors.password && <p className="text-xs text-destructive mt-1">{errors.password.message}</p>}
          </div>
          <Button type="submit" className="w-full" disabled={isSubmitting}>
            {isSubmitting && <Loader2 className="animate-spin h-4 w-4 mr-2" />}
            Login
          </Button>
        </form>
      </div>
    </div>
  );
} 