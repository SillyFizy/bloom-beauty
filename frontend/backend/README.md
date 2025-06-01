# Joulina E-commerce Backend

This is the backend API for the Joulina luxury e-commerce platform.

## Features

- **User Authentication System**
  - User registration with email verification
  - JWT authentication for secure API access
  - User profile management
  - User tier management (Normal, Celebrity, Pointz Tiers)

- **Product Management**
  - Product catalog with categories
  - Product details (name, description, price, images, stock)
  - Filtering and searching capabilities
  - Admin product inventory management

- **Shopping Cart System**
  - Add/remove products from cart
  - Update quantities and calculate totals
  - Cart persistence for registered users

- **Checkout Process**
  - Shipping address management
  - Order creation from cart items
  - Multiple payment method support
  - Order confirmation with email notifications

- **User Account Management**
  - Profile editing
  - Order history and tracking
  - Tier-based benefits system

## Technology Stack

- Django & Django REST Framework
- JWT Authentication
- PostgreSQL (production) / SQLite (development fallback)
- RESTful API architecture

## Database Setup

### Option 1: Docker PostgreSQL (Recommended)

1. Install Docker Desktop
2. Start PostgreSQL with Docker Compose:
   ```bash
   docker-compose up -d postgres
   ```
3. The database will be available at `localhost:5432`
4. Default credentials:
   - Database: `bloom_beauty`
   - User: `joulina_user`
   - Password: `joulina_password`

### Option 2: Local PostgreSQL Installation

1. Download and install PostgreSQL from https://www.postgresql.org/download/
2. During installation, remember the password for the `postgres` user
3. Run the setup script:
   ```bash
   python setup_postgres.py
   ```
4. Follow the prompts to create the database and user

### Option 3: SQLite Fallback

If you can't set up PostgreSQL, you can temporarily use SQLite by:
1. Commenting out the PostgreSQL configuration in `settings.py`
2. Uncommenting the SQLite configuration

## Setup Instructions

1. Clone the repository
2. Create a virtual environment: `python -m venv venv`
3. Activate the virtual environment:
   - Windows: `venv\Scripts\activate`
   - Mac/Linux: `source venv/bin/activate`
4. Install dependencies: `pip install -r requirements.txt`
5. Set up PostgreSQL (see Database Setup above)
6. Run migrations: `python manage.py migrate`
7. Create a superuser: `python manage.py createsuperuser`
8. Start the development server: `python manage.py runserver`

## Migration from SQLite

If you have existing data in SQLite and want to migrate to PostgreSQL:

1. Set up PostgreSQL (see Database Setup above)
2. Run the migration script:
   ```bash
   python migrate_to_postgres.py
   ```
3. Follow the prompts to backup SQLite data and migrate to PostgreSQL

## Environment Variables

You can customize database settings using environment variables:

```bash
# Database Configuration
DB_NAME=bloom_beauty
DB_USER=joulina_user
DB_PASSWORD=joulina_password
DB_HOST=localhost
DB_PORT=5432
```

See `env.example` for a complete list of available environment variables.

## API Documentation

API documentation is available at:
- Swagger UI: `/swagger/`
- ReDoc: `/redoc/`

## API Endpoints

### Authentication
- `POST /api/users/register/`: Register new user
- `POST /api/users/login/`: Login and get JWT token
- `POST /api/users/token/refresh/`: Refresh JWT token
- `GET /api/users/profile/`: Get user profile
- `PUT /api/users/profile/`: Update user profile
- `POST /api/users/change-password/`: Change password
- `GET /api/users/verify-email/?token=<token>`: Verify email

### Products
- `GET /api/products/`: List all products
- `GET /api/products/<id>/`: Get specific product
- `GET /api/products/categories/`: List all categories
- `GET /api/products/search/?q=<query>`: Search products

### Cart
- `GET /api/cart/`: Get user's cart
- `POST /api/cart/add_item/`: Add item to cart
- `POST /api/cart/remove_item/`: Remove item from cart
- `POST /api/cart/update_item/`: Update item quantity
- `POST /api/cart/clear/`: Clear cart

### Orders
- `GET /api/orders/`: List user's orders
- `GET /api/orders/<id>/`: Get specific order
- `POST /api/orders/checkout/`: Create order from cart

### Payments
- `GET /api/payments/`: List user's payments
- `GET /api/payments/<id>/`: Get specific payment
- `POST /api/payments/process_payment/`: Process payment for an order

## License

Proprietary. All rights reserved. 