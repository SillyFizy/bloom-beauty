import * as React from 'react';
import { Slot } from '@radix-ui/react-slot';
import { cva, type VariantProps } from 'class-variance-authority';
import { cn } from '@/lib/utils';

const buttonVariants = cva(
  'inline-flex items-center justify-center whitespace-nowrap text-sm font-medium transition-all duration-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 active:scale-95',
  {
    variants: {
      variant: {
        default: 'bg-white text-slate-700 border border-slate-200 hover:bg-primary hover:text-white hover:border-primary',
        destructive: 'bg-white text-red-600 border border-red-200 hover:bg-destructive hover:text-white hover:border-destructive',
        outline: 'bg-white text-slate-700 border border-slate-200 hover:bg-primary hover:text-white hover:border-primary',
        secondary: 'bg-white text-slate-700 border border-slate-200 hover:bg-secondary hover:text-white hover:border-secondary',
        ghost: 'text-slate-700 hover:bg-slate-100',
        link: 'text-primary underline-offset-4 hover:underline',
        success: 'bg-white text-green-600 border border-green-200 hover:bg-success hover:text-white hover:border-success',
        warning: 'bg-white text-orange-600 border border-orange-200 hover:bg-warning hover:text-white hover:border-warning',
        pagination: 'bg-white text-slate-700 border border-slate-200 hover:bg-primary hover:text-white hover:border-primary min-w-[40px] justify-center',
      },
      size: {
        default: 'h-10 px-4 py-2 rounded-lg',
        sm: 'h-9 px-3 rounded-md',
        lg: 'h-11 px-8 rounded-lg',
        xl: 'h-12 px-10 text-base rounded-lg',
        icon: 'h-10 w-10 rounded-lg',
      },
    },
    defaultVariants: {
      variant: 'default',
      size: 'default',
    },
  }
);

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  asChild?: boolean;
  loading?: boolean;
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, asChild = false, loading = false, children, disabled, ...props }, ref) => {
    const Comp = asChild ? Slot : 'button';
    
    return (
      <Comp
        className={cn(buttonVariants({ variant, size, className }))}
        ref={ref}
        disabled={disabled || loading}
        {...props}
      >
        {loading && (
          <svg
            className="mr-2 h-4 w-4 animate-spin"
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
          >
            <circle
              className="opacity-25"
              cx="12"
              cy="12"
              r="10"
              stroke="currentColor"
              strokeWidth="4"
            />
            <path
              className="opacity-75"
              fill="currentColor"
              d="m4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
            />
          </svg>
        )}
        {children}
      </Comp>
    );
  }
);

Button.displayName = 'Button';

export { Button, buttonVariants }; 