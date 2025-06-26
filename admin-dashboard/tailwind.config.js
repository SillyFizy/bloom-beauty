/** @type {import('tailwindcss').Config} */
module.exports = {
  darkMode: ['class'],
  content: [
    './pages/**/*.{ts,tsx}',
    './components/**/*.{ts,tsx}',
    './app/**/*.{ts,tsx}',
    './src/**/*.{ts,tsx}',
  ],
  theme: {
    container: {
      center: true,
      padding: '2rem',
      screens: {
        '2xl': '1400px',
      },
    },
    extend: {
      colors: {
        // Brand colors matching Flutter app
        primary: {
          DEFAULT: 'hsl(var(--primary))',
          50: '#fdfcf8',
          100: '#faf7ee',
          200: '#f3edda',
          300: '#e9dfc1',
          400: '#dccba0',
          500: '#c7a052', // Golden - C7A052
          600: '#b8944a',
          700: '#9a7b3e',
          800: '#7c6234',
          900: '#65512b',
          950: '#382e18',
          foreground: 'hsl(var(--primary-foreground))',
        },
        accent: {
          DEFAULT: 'hsl(var(--accent))',
          50: '#fdf2f5',
          100: '#fce7ed',
          200: '#f9d0dc',
          300: '#f4a8be',
          400: '#ec7599',
          500: '#e49eb1', // Pink - E49EB1
          600: '#d6557a',
          700: '#c23d63',
          800: '#a23554',
          900: '#87304a',
          950: '#4f1728',
          foreground: 'hsl(var(--accent-foreground))',
        },
        // New colors from the palette
        blush: {
          50: '#fefcfc',
          100: '#fdf7f7',
          200: '#fbecec',
          300: '#f8e1e1',
          400: '#f5d6d6',
          500: '#f8e7e7', // Light Pink - F8E7E7
          600: '#e6d4d4',
          700: '#d3c1c1',
          800: '#c0aeae',
          900: '#ad9b9b',
        },
        sage: {
          50: '#f7f9f7',
          100: '#eff3ef',
          200: '#dfe7df',
          300: '#cfdbcf',
          400: '#bfcfbf',
          500: '#aabd9d', // Sage Green - AABD9D
          600: '#9aab8e',
          700: '#8a997f',
          800: '#7a8770',
          900: '#6a7561',
        },
        cream: {
          50: '#fefdfb',
          100: '#fdfbf7',
          200: '#fbf7ef',
          300: '#f9f3e7',
          400: '#f7efdf',
          500: '#e9d8c6', // Cream - E9D8C6
          600: '#d6c5b3',
          700: '#c3b2a0',
          800: '#b09f8d',
          900: '#9d8c7a',
        },
        background: 'hsl(var(--background))',
        surface: '#ffffff',
        border: 'hsl(var(--border))',
        input: 'hsl(var(--input))',
        ring: 'hsl(var(--ring))',
        muted: {
          DEFAULT: 'hsl(var(--muted))',
          foreground: 'hsl(var(--muted-foreground))',
        },
        card: {
          DEFAULT: 'hsl(var(--card))',
          foreground: 'hsl(var(--card-foreground))',
        },
        popover: {
          DEFAULT: 'hsl(var(--popover))',
          foreground: 'hsl(var(--popover-foreground))',
        },
        foreground: 'hsl(var(--foreground))',
        secondary: {
          DEFAULT: 'hsl(var(--secondary))',
          foreground: 'hsl(var(--secondary-foreground))',
        },
        destructive: {
          DEFAULT: 'hsl(var(--destructive))',
          foreground: 'hsl(var(--destructive-foreground))',
        },
        success: {
          DEFAULT: '#4caf50',
          foreground: '#ffffff',
        },
        warning: {
          DEFAULT: '#ff9800',
          foreground: '#ffffff',
        },
      },
      borderRadius: {
        lg: '12px',
        md: '8px',
        sm: '6px',
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
      animation: {
        'fade-in': 'fadeIn 0.2s ease-out',
        'slide-in': 'slideIn 0.4s ease-out',
        'scale-in': 'scaleIn 0.2s ease-out',
        'shimmer': 'shimmer 2s linear infinite',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        slideIn: {
          '0%': { transform: 'translateY(10px)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
        scaleIn: {
          '0%': { transform: 'scale(0.95)', opacity: '0' },
          '100%': { transform: 'scale(1)', opacity: '1' },
        },
        shimmer: {
          '0%': { transform: 'translateX(-100%)' },
          '100%': { transform: 'translateX(100%)' },
        },
      },
      boxShadow: {
        'card': '0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06)',
        'elevated': '0 8px 25px -5px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)',
      },
    },
  },
  plugins: [require('tailwindcss-animate')],
}; 