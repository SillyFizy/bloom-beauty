#!/usr/bin/env python
"""
Script to create test orders and order items for testing the bestselling endpoint
Run this from the backend directory: python create_test_orders.py
"""

import os
import sys
import django
from decimal import Decimal
from datetime import datetime, timedelta
import random

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'joulina_backend.settings')
django.setup()

from django.contrib.auth import get_user_model
from products.models import Product
from orders.models import Order, OrderItem, ShippingAddress

User = get_user_model()

def create_test_orders():
    print("🚀 Creating test orders and order items...")
    
    # Get or create a test user
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
    if created:
        print("✅ Created test shipping address")
    else:
        print("✅ Using existing shipping address")
    
    # Get active products
    products = list(Product.objects.filter(is_active=True)[:10])
    if not products:
        print("❌ No active products found! Please create some products first.")
        return
    
    print(f"✅ Found {len(products)} active products to use")
    
    # Create 5 test orders with 15 total order items
    order_data = [
        {'items': 4, 'date_offset': 1},   # Order 1: 4 items, 1 day ago
        {'items': 3, 'date_offset': 2},   # Order 2: 3 items, 2 days ago  
        {'items': 3, 'date_offset': 5},   # Order 3: 3 items, 5 days ago
        {'items': 2, 'date_offset': 7},   # Order 4: 2 items, 7 days ago
        {'items': 3, 'date_offset': 10},  # Order 5: 3 items, 10 days ago
    ]
    
    # Products with different popularity (some will be bestsellers)
    product_weights = {
        products[0].id: 8,  # This will be the bestseller
        products[1].id: 6,  # Second best
        products[2].id: 4,  # Third best
    }
    
    total_items_created = 0
    
    for order_idx, order_info in enumerate(order_data, 1):
        # Create order
        order_date = datetime.now() - timedelta(days=order_info['date_offset'])
        
        order = Order.objects.create(
            user=user,
            shipping_address=shipping_address,
            status='delivered',  # Use delivered status so they count as real sales
            payment_method='cash_on_delivery',
            subtotal=Decimal('0.00'),
            total_amount=Decimal('0.00'),
            is_paid=True,
            created_at=order_date
        )
        
        print(f"📦 Created Order #{order.id} ({order_info['items']} items)")
        
        # Create order items for this order
        order_total = Decimal('0.00')
        
        for item_idx in range(order_info['items']):
            # Select product with weighted randomness (some products more likely)
            if random.random() < 0.6 and products[0].id in product_weights:
                # 60% chance for bestseller
                product = products[0]
                quantity = random.randint(2, 5)  # Higher quantities for bestseller
            elif random.random() < 0.4 and products[1].id in product_weights:
                # 40% chance for second best
                product = products[1] 
                quantity = random.randint(1, 3)
            else:
                # Random product
                product = random.choice(products)
                quantity = random.randint(1, 2)
            
            unit_price = product.sale_price if product.sale_price else product.price
            subtotal = unit_price * quantity
            
            order_item = OrderItem.objects.create(
                order=order,
                product=product,
                quantity=quantity,
                unit_price=unit_price,
                subtotal=subtotal
            )
            
            order_total += subtotal
            total_items_created += 1
            
            print(f"  📝 Item {total_items_created}: {product.name[:30]}... × {quantity} = ${subtotal}")
        
        # Update order total
        order.subtotal = order_total
        order.total_amount = order_total
        order.save()
        
        print(f"  💰 Order total: ${order_total}")
        print()
    
    print(f"🎉 Successfully created {total_items_created} order items across {len(order_data)} orders!")
    
    # Show bestselling summary
    print("\n📊 BESTSELLING SUMMARY:")
    from django.db.models import Sum
    bestsellers = Product.objects.filter(
        is_active=True,
        orderitem__isnull=False
    ).annotate(
        total_sold=Sum('orderitem__quantity')
    ).order_by('-total_sold')[:5]
    
    for i, product in enumerate(bestsellers, 1):
        print(f"{i}. {product.name[:40]}... - {product.total_sold} pieces sold")
    
    print(f"\n✅ Test data created! You can now test the API:")
    print(f"   GET http://127.0.0.1:8000/api/v1/products/bestselling/")
    print(f"   GET http://127.0.0.1:8000/api/v1/products/bestselling/?limit=5")
    print(f"   GET http://127.0.0.1:8000/api/v1/products/bestselling/?days=7")

if __name__ == '__main__':
    create_test_orders() 