# Bloom Beauty - Flutter Ecommerce App

A beautiful and modern Flutter ecommerce application for beauty products with a comprehensive feature set including product browsing, cart management, user authentication, and more.

## 📱 Features

- **User Authentication** - Login, Register, Forgot Password
- **Product Catalog** - Browse products by categories, search, filter, and sort
- **Shopping Cart** - Add to cart, manage quantities, checkout
- **User Profile** - Profile management, order history, wishlist
- **Reviews & Ratings** - Product reviews with photos
- **Influencer Integration** - Influencer recommendations and content
- **Localization** - Multi-language support (English, Spanish)
- **Modern UI** - Beautiful Material Design with animations

## 🏗️ Project Structure

```
lib/
├── constants/          # App constants, colors, strings
│   ├── app_constants.dart
│   └── string_constants.dart
├── l10n/              # Localization files
│   └── app_localizations.dart
├── models/            # Data models
│   ├── user_model.dart
│   ├── product_model.dart
│   ├── cart_item_model.dart
│   └── category_model.dart
├── screens/           # App screens
│   ├── auth/          # Authentication screens
│   ├── home/          # Home and discovery
│   ├── products/      # Product listing and details
│   ├── cart/          # Shopping cart
│   └── profile/       # User profile
├── services/          # API and business logic
│   ├── api_service.dart
│   ├── auth_service.dart
│   └── storage_service.dart
├── utils/             # Utility functions
│   ├── validators.dart
│   ├── formatters.dart
│   └── extensions.dart
├── widgets/           # Reusable UI components
│   ├── common/        # Common widgets (buttons, text fields)
│   ├── product/       # Product-specific widgets
│   └── cart/          # Cart-specific widgets
└── main.dart         # App entry point
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.5.3)
- Dart SDK
- Android Studio / VS Code
- Android/iOS device or emulator

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd bloom_beauty
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## 📦 Dependencies

### Core Dependencies
- **http & dio** - API communication
- **provider & flutter_riverpod** - State management
- **shared_preferences & hive** - Local storage
- **go_router** - Navigation
- **intl** - Internationalization

### UI Dependencies
- **cached_network_image** - Image caching
- **shimmer** - Loading animations
- **carousel_slider** - Image carousels
- **flutter_staggered_grid_view** - Grid layouts

### Utility Dependencies
- **email_validator** - Form validation
- **image_picker** - Image selection
- **uuid** - Unique ID generation

## 🎨 Key Components

### Models
- **User**: User authentication and profile data
- **Product**: Product information, pricing, ratings
- **CartItem**: Shopping cart items with quantities
- **Category**: Product categories and subcategories

### Services
- **ApiService**: HTTP API communication
- **AuthService**: User authentication management
- **StorageService**: Local data persistence

### Widgets
- **CustomButton**: Reusable button component
- **CustomTextField**: Styled text input fields
- **ProductCard**: Product display card
- **CartItemWidget**: Shopping cart item display

## 🔧 Development Setup

### State Management
The app uses Provider for state management. Key providers include:
- AuthProvider - User authentication state
- CartProvider - Shopping cart state
- ProductsProvider - Product data management

### API Integration
- Base URL configured in `constants/app_constants.dart`
- RESTful API endpoints for products, auth, orders
- Error handling and network status management

### Localization
- English and Spanish language support
- Localized strings in `l10n/app_localizations.dart`
- Add new languages by extending the localizations

## 📱 Screens Overview

### Authentication Flow
- **SplashScreen** - App intro and loading
- **LoginScreen** - User login with validation
- **RegisterScreen** - New user registration

### Main App Flow
- **HomeScreen** - Featured products, categories, offers
- **ProductListScreen** - Product browsing with filters
- **ProductDetailScreen** - Detailed product information
- **CartScreen** - Shopping cart management
- **ProfileScreen** - User account management

## 🔮 Next Steps

1. **Implement State Management** - Add Provider/Riverpod logic
2. **Add Real API Integration** - Connect to backend services
3. **Implement Navigation** - Set up GoRouter routing
4. **Add Image Assets** - Include app logo and placeholder images
5. **Implement Authentication** - Add Firebase Auth or custom auth
6. **Add Payment Integration** - Integrate payment gateways
7. **Add Push Notifications** - Real-time order updates
8. **Implement Offline Support** - Local data caching

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
