#!/usr/bin/env python3
"""
Generate test data for Joulina Beauty backend.
Run this script to quickly populate your database with test data.
"""
import os
import sys
import random
import django
from datetime import datetime, timedelta

# Set up Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'joulina_backend.settings')
django.setup()

from django.contrib.auth import get_user_model
from products.models import Category, Brand, Product, ProductImage
from django.utils.text import slugify

User = get_user_model()

def create_superuser():
    """Create a superuser if one doesn't exist"""
    if not User.objects.filter(is_superuser=True).exists():
        User.objects.create_superuser(
            'admin', 
            'admin@joulina.com', 
            'adminpassword',
            first_name='Admin',
            last_name='User'
        )
        print("✓ Created superuser: admin / adminpassword")
    else:
        print("✓ Superuser already exists")

def create_categories():
    """Create product categories"""
    if Category.objects.count() > 0:
        print("✓ Categories already exist")
        return

    categories = [
        {
            'name': 'Skincare',
            'description': 'Products for skin health and appearance',
            'subcategories': [
                'Cleansers', 'Toners', 'Serums', 'Moisturizers', 'Masks'
            ]
        },
        {
            'name': 'Makeup',
            'description': 'Cosmetic products to enhance appearance',
            'subcategories': [
                'Foundation', 'Concealer', 'Eyeshadow', 'Mascara', 'Lipstick'
            ]
        },
        {
            'name': 'Haircare',
            'description': 'Products for hair health and styling',
            'subcategories': [
                'Shampoo', 'Conditioner', 'Styling', 'Treatments', 'Hair Color'
            ]
        },
        {
            'name': 'Fragrances',
            'description': 'Perfumes and scented products',
            'subcategories': [
                'Women\'s Perfume', 'Men\'s Cologne', 'Unisex Fragrances'
            ]
        }
    ]
    
    for category_data in categories:
        # Create main category
        main_category = Category.objects.create(
            name=category_data['name'],
            description=category_data['description'],
            slug=slugify(category_data['name']),
            is_active=True
        )
        
        # Create subcategories
        for subcategory_name in category_data['subcategories']:
            Category.objects.create(
                name=subcategory_name,
                description=f"{subcategory_name} in {category_data['name']} category",
                slug=slugify(subcategory_name),
                parent=main_category,
                is_active=True
            )
    
    print(f"✓ Created {Category.objects.count()} categories")

def create_brands():
    """Create product brands"""
    if Brand.objects.count() > 0:
        print("✓ Brands already exist")
        return

    brands = [
        {
            'name': 'Luminous',
            'description': 'Premium skincare with natural ingredients',
            'country_of_origin': 'France'
        },
        {
            'name': 'EverGlow',
            'description': 'Innovative makeup solutions for all skin types',
            'country_of_origin': 'USA'
        },
        {
            'name': 'Pure Essence',
            'description': 'Organic and vegan beauty products',
            'country_of_origin': 'Germany'
        },
        {
            'name': 'Royal Scent',
            'description': 'Luxury fragrances with lasting impression',
            'country_of_origin': 'Italy'
        },
        {
            'name': 'Silk Strands',
            'description': 'Professional haircare for salon-quality results',
            'country_of_origin': 'Australia'
        }
    ]
    
    for brand_data in brands:
        Brand.objects.create(
            name=brand_data['name'],
            description=brand_data['description'],
            country_of_origin=brand_data['country_of_origin'],
            slug=slugify(brand_data['name']),
            is_active=True
        )
    
    print(f"✓ Created {Brand.objects.count()} brands")

def create_products(count=20):
    """Create sample products"""
    if Product.objects.count() > 0:
        print("✓ Products already exist")
        return
        
    categories = list(Category.objects.all())
    brands = list(Brand.objects.all())
    
    if not categories or not brands:
        print("Error: Need categories and brands before creating products")
        return
    
    for i in range(1, count + 1):
        # Randomize attributes
        category = random.choice(categories)
        brand = random.choice(brands)
        
        # Generate price and maybe sale price
        price = random.uniform(10.0, 100.0)
        has_sale = random.choice([True, False])
        sale_price = round(price * 0.8, 2) if has_sale else None
        
        # Other attributes
        is_featured = random.choice([True, False])
        stock = random.randint(0, 100)
        
        # Create product
        product_name = f"{brand.name} {category.name} #{i}"
        product = Product.objects.create(
            name=product_name,
            slug=slugify(product_name),
            description=f"This is a premium {category.name.lower()} product from {brand.name}.",
            price=price,
            sale_price=sale_price,
            category=category,
            brand=brand,
            sku=f"SKU{i:04d}",
            stock=stock,
            is_featured=is_featured,
            is_active=True,
            meta_title=product_name,
            meta_description=f"Buy {product_name} at the best price from Joulina Beauty",
            meta_keywords=f"{category.name.lower()}, {brand.name.lower()}, beauty, luxury"
        )
        
        # Create placeholder image for the product
        ProductImage.objects.create(
            product=product,
            image="placeholder.jpg",
            alt_text=f"Image of {product_name}",
            is_primary=True
        )
    
    print(f"✓ Created {Product.objects.count()} products")

def main():
    """Main function to create all test data"""
    print("=== Creating Test Data for Joulina Beauty ===")
    
    create_superuser()
    create_categories()
    create_brands()
    create_products()
    
    print("\n=== Test Data Creation Complete ===")
    print("\nYou can now log in to the admin interface with:")
    print("Username: admin")
    print("Password: adminpassword")
    print("\nAPI is now populated with test data!")

if __name__ == "__main__":
    main() 