#!/usr/bin/env python
"""
Simple script to create test order data using Django's manage.py shell
Copy and paste the following code into Django shell:
python manage.py shell

Then paste this code:
"""

CREATE_TEST_ORDERS = """
from django.contrib.auth import get_user_model
from products.models import Product
from orders.models import Order, OrderItem, ShippingAddress
from decimal import Decimal
from datetime import datetime, timedelta
import random

User = get_user_model()

# Get or create test user
user, created = User.objects.get_or_create(
    username='testbuyer',
    defaults={
        'email': 'test@example.com',
        'first_name': 'Test',
        'last_name': 'Buyer'
    }
)
if created:
    user.set_password('testpass123')
    user.save()
    print(f"✅ Created test user: {user.username}")
else:
    print(f"✅ Using existing user: {user.username}")

# Get or create shipping address
shipping_address, created = ShippingAddress.objects.get_or_create(
    user=user,
    defaults={
        'full_name': 'Test Buyer',
        'phone_number': '1234567890',
        'address_line1': '123 Test Street',
        'city': 'Test City',
        'state': 'Test State',
        'country': 'Test Country',
        'postal_code': '12345',
        'is_default': True
    }
)

# Get active products
products = list(Product.objects.filter(is_active=True)[:10])
print(f"✅ Found {len(products)} active products")

if len(products) == 0:
    print("❌ No products found! Please add some products first.")
else:
    # Create 5 orders with different quantities to make some products bestsellers
    orders_data = [
        {'product_idx': 0, 'quantity': 10, 'days_ago': 1},  # Product 1: 10 sold
        {'product_idx': 1, 'quantity': 8, 'days_ago': 2},   # Product 2: 8 sold
        {'product_idx': 0, 'quantity': 5, 'days_ago': 3},   # Product 1: +5 = 15 total
        {'product_idx': 2, 'quantity': 7, 'days_ago': 4},   # Product 3: 7 sold
        {'product_idx': 1, 'quantity': 4, 'days_ago': 5},   # Product 2: +4 = 12 total
        {'product_idx': 3, 'quantity': 6, 'days_ago': 6},   # Product 4: 6 sold
        {'product_idx': 0, 'quantity': 3, 'days_ago': 7},   # Product 1: +3 = 18 total
    ]
    
    total_created = 0
    for order_data in orders_data:
        product = products[order_data['product_idx']]
        quantity = order_data['quantity']
        days_ago = order_data['days_ago']
        
        # Create order
        order_date = datetime.now() - timedelta(days=days_ago)
        unit_price = product.sale_price if product.sale_price else product.price
        subtotal = unit_price * quantity
        
        order = Order.objects.create(
            user=user,
            shipping_address=shipping_address,
            status='delivered',
            payment_method='cash_on_delivery',
            subtotal=subtotal,
            total_amount=subtotal,
            is_paid=True,
            created_at=order_date
        )
        
        # Create order item
        OrderItem.objects.create(
            order=order,
            product=product,
            quantity=quantity,
            unit_price=unit_price,
            subtotal=subtotal
        )
        
        total_created += 1
        print(f"📦 Order {total_created}: {product.name[:30]}... × {quantity} = ${subtotal}")
    
    print(f"\\n🎉 Created {total_created} orders!")
    
    # Show bestselling summary
    from django.db.models import Sum
    bestsellers = Product.objects.filter(
        is_active=True,
        orderitem__isnull=False
    ).annotate(
        total_sold=Sum('orderitem__quantity')
    ).order_by('-total_sold')[:5]
    
    print("\\n📊 BESTSELLING SUMMARY:")
    for i, product in enumerate(bestsellers, 1):
        print(f"{i}. {product.name[:40]}... - {product.total_sold} pieces sold")
    
    print("\\n✅ Test data created! You can now test the API:")
    print("   GET http://127.0.0.1:8000/api/v1/products/bestselling/")
    print("   GET http://127.0.0.1:8000/api/v1/products/bestselling/?limit=5")
"""

if __name__ == '__main__':
    print("🚀 DJANGO SHELL SCRIPT FOR CREATING TEST ORDERS")
    print("=" * 60)
    print("1. Run: python manage.py shell")
    print("2. Copy and paste the following code:")
    print("=" * 60)
    print(CREATE_TEST_ORDERS) 