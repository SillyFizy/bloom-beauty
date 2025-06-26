# Bloom Beauty Admin Dashboard

A modern, enterprise-level admin dashboard for managing Bloom Beauty's product catalog, built with Next.js 14, TypeScript, and Tailwind CSS.

![Bloom Beauty Admin Dashboard](https://via.placeholder.com/1200x600/c7a052/ffffff?text=Bloom+Beauty+Admin+Dashboard)

## ✨ Features

### 🎨 Design & UX
- **Modern UI** - Clean, professional interface matching the Flutter app's golden/pink theme
- **Responsive Design** - Works perfectly on desktop, tablet, and mobile devices
- **Smooth Animations** - Polished micro-interactions and transitions
- **Accessible** - WCAG AA compliant with proper ARIA labels and keyboard navigation

### 📦 Product Management
- **Complete CRUD Operations** - Create, read, update, and delete products
- **Advanced Search & Filtering** - Search by name, SKU, category, brand, and more
- **Bulk Operations** - Update or delete multiple products at once
- **Stock Management** - Track inventory levels with low-stock alerts
- **Image Management** - Upload and manage product images with optimization
- **Category & Brand Organization** - Hierarchical categorization system

### 🚀 Performance & Developer Experience
- **Next.js 14** - Latest React framework with App Router
- **TypeScript** - Full type safety and enhanced developer experience
- **React Query** - Efficient data fetching with caching and optimistic updates
- **Real-time Updates** - Automatic cache invalidation and UI updates
- **Error Handling** - Comprehensive error boundaries and user feedback
- **Loading States** - Skeleton screens and loading indicators

## 🛠 Tech Stack

- **Frontend Framework**: Next.js 14 with App Router
- **Language**: TypeScript
- **Styling**: Tailwind CSS with custom design system
- **State Management**: React Query (TanStack Query)
- **UI Components**: Radix UI primitives with custom styling
- **Forms**: React Hook Form with Zod validation
- **Icons**: Lucide React
- **Animations**: Framer Motion
- **Image Optimization**: Next.js Image component with Sharp

## 🚀 Getting Started

### Prerequisites

- Node.js 18+ 
- npm 8+
- Bloom Beauty Backend running on `http://192.168.68.127:8000`

### Installation

1. **Clone the repository**
   ```bash
   cd bloom-beauty/admin-dashboard
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Set up environment variables**
   ```bash
   cp .env.example .env.local
   ```
   
   Edit `.env.local` with your backend URL:
   ```env
   NEXT_PUBLIC_API_BASE_URL=http://192.168.68.127:8000/api/v1
   NEXT_PUBLIC_MEDIA_BASE_URL=http://192.168.68.127:8000/media
   ```

4. **Start the development server**
   ```bash
   npm run dev
   ```

5. **Open your browser**
   Navigate to [http://localhost:3000](http://localhost:3000)

## 📁 Project Structure

```
src/
├── app/                    # Next.js 14 App Router
│   ├── globals.css        # Global styles and Tailwind directives
│   ├── layout.tsx         # Root layout with providers
│   ├── page.tsx          # Home page (redirects to products)
│   └── products/         # Products management pages
│       ├── layout.tsx    # Products layout with sidebar
│       └── page.tsx      # Main products page
├── components/           # Reusable UI components
│   ├── layout/          # Layout components (Sidebar, Header)
│   ├── providers/       # React Query and other providers
│   └── ui/             # Base UI components (Button, etc.)
├── hooks/              # Custom React hooks
│   └── use-products.ts # Products data management hooks
├── lib/                # Utility libraries
│   ├── api.ts         # API client configuration
│   └── utils.ts       # Utility functions
├── services/          # API service classes
│   └── products.ts    # Products, Categories, Brands services
└── types/             # TypeScript type definitions
    └── product.ts     # Product-related types
```

## 🎨 Design System

The dashboard follows Bloom Beauty's design language:

### Colors
- **Primary**: Golden (`#c7a052`) - Main brand color
- **Accent**: Pink (`#e49eb1`) - Secondary brand color
- **Background**: Light gray (`#fafafa`) - Clean background
- **Surface**: White (`#ffffff`) - Card and surface color

### Typography
- **Font**: Inter - Modern, readable sans-serif
- **Hierarchy**: Clear heading and body text scales

### Components
- **Cards**: Rounded corners (12px) with subtle shadows
- **Buttons**: Golden primary, various sizes and states
- **Forms**: Consistent input styling with focus states
- **Tables**: Clean, sortable data presentation

## 🔧 Configuration

### API Integration
The dashboard connects to the Django backend through:
- **Base URL**: Configurable via environment variables
- **Authentication**: JWT token support (ready for implementation)
- **Image Handling**: Automatic media URL resolution
- **Error Handling**: Comprehensive error messages and retry logic

### Performance Optimizations
- **Image Optimization**: Next.js Image component with WebP/AVIF
- **Code Splitting**: Automatic route-based splitting
- **Caching**: React Query with intelligent cache invalidation
- **Bundle Optimization**: Tree shaking and minification

## 📊 Features Overview

### Products Page
- ✅ **Product Listing** - Paginated table with all product information
- ✅ **Search & Filter** - Real-time search with category/brand filters
- ✅ **Stats Dashboard** - Overview cards showing key metrics
- ✅ **Bulk Operations** - Select multiple products for batch actions
- ✅ **Status Management** - Active/inactive, featured, sale status
- ✅ **Stock Alerts** - Visual indicators for low stock items
- ✅ **Image Display** - Product thumbnails with fallback states
- ✅ **Responsive Design** - Mobile-friendly table and controls

### Planned Features
- 🔄 **Product Form** - Add/edit products with image upload
- 🔄 **Categories Management** - CRUD operations for categories
- 🔄 **Brands Management** - CRUD operations for brands
- 🔄 **Celebrity Management** - Celebrity endorsements and picks
- 🔄 **User Management** - Customer accounts and permissions
- 🔄 **Analytics Dashboard** - Sales insights and reporting
- 🔄 **Settings** - System configuration and preferences

## 🧪 Development

### Scripts
```bash
npm run dev          # Start development server
npm run build        # Build for production
npm run start        # Start production server
npm run lint         # Run ESLint
npm run type-check   # Run TypeScript checks
npm test             # Run tests (when implemented)
```

### Code Quality
- **ESLint** - Code linting with Next.js rules
- **Prettier** - Code formatting with Tailwind plugin
- **TypeScript** - Strict type checking
- **Git Hooks** - Pre-commit validation (when configured)

## 🚀 Deployment

### Production Build
```bash
npm run build
npm run start
```

### Environment Variables
Required for production:
```env
NEXT_PUBLIC_API_BASE_URL=https://your-backend-url.com/api/v1
NEXT_PUBLIC_MEDIA_BASE_URL=https://your-backend-url.com/media
NODE_ENV=production
```

### Deployment Platforms
- **Vercel** - Recommended for Next.js apps
- **Netlify** - Static site deployment
- **Docker** - Containerized deployment
- **AWS/GCP/Azure** - Cloud platform deployment

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is proprietary software for Bloom Beauty.

## 📞 Support

For support and questions:
- **Email**: admin@bloombeauty.com
- **Documentation**: [Internal Wiki](link-to-internal-docs)
- **Issue Tracker**: [GitHub Issues](link-to-issues)

---

Built with ❤️ for Bloom Beauty by the development team. 