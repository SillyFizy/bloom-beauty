#!/usr/bin/env python
"""
Script to populate the database with products from final_products.json
Extracts: names, descriptions, photos, prices, quantities (skips variants)
"""

import os
import sys
import django
import json
from decimal import Decimal
from pathlib import Path

# Add the project directory to Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'joulina_backend.settings')
django.setup()

from products.models import Product, Category, Brand, ProductImage
from django.core.files.base import ContentFile
from django.utils.text import slugify
import requests
from urllib.parse import urljoin
import time

def create_default_category():
    """Create a default category for imported products"""
    category, created = Category.objects.get_or_create(
        name="Beauty Products",
        defaults={
            'description': 'Imported beauty products from JSON data',
            'slug': 'beauty-products'
        }
    )
    return category

def create_default_brand():
    """Create a default brand for imported products"""
    brand, created = Brand.objects.get_or_create(
        name="Beauty Creations",
        defaults={
            'description': 'Beauty Creations brand products',
            'slug': 'beauty-creations'
        }
    )
    return brand

def clean_price(price_value):
    """Convert price to Decimal, handling various input formats"""
    if price_value is None:
        return Decimal('0.00')
    
    # Handle string prices with currency formatting
    if isinstance(price_value, str):
        # Remove common currency symbols and formatting
        price_clean = price_value.replace(',', '').replace('$', '').replace('IQD', '').strip()
        try:
            return Decimal(price_clean)
        except:
            return Decimal('0.00')
    
    # Handle numeric prices
    try:
        return Decimal(str(price_value))
    except:
        return Decimal('0.00')

def clean_stock(quantity_value):
    """Convert quantity to integer, handling null values"""
    if quantity_value is None:
        return 0
    
    try:
        return int(quantity_value)
    except:
        return 0

def clean_name(name):
    """Clean product name"""
    if not name or name.strip() == "المنتج":
        return "Unnamed Product"
    return name.strip()

def clean_description(description):
    """Clean and format product description"""
    if not description:
        return "No description available"
    
    # Remove excessive whitespace and format
    cleaned = ' '.join(description.split())
    return cleaned[:2000]  # Limit description length

def download_and_save_image(image_url, product, index=0):
    """Download image from URL and create ProductImage instance"""
    try:
        # For local file paths, we'll just store the path
        if image_url.startswith('images/'):
            # Create ProductImage with the path
            product_image = ProductImage.objects.create(
                product=product,
                alt_text=f"{product.name} - Image {index + 1}",
                is_feature=(index == 0)  # First image is featured
            )
            # Note: In a real scenario, you'd want to copy the actual image file
            # For now, we're just storing the reference
            print(f"  - Linked image: {image_url}")
            return product_image
    except Exception as e:
        print(f"  - Failed to process image {image_url}: {e}")
        return None

def import_products_from_json(json_file_path):
    """Import products from JSON file"""
    
    # Load JSON data
    try:
        with open(json_file_path, 'r', encoding='utf-8') as f:
            products_data = json.load(f)
    except Exception as e:
        print(f"Error loading JSON file: {e}")
        return
    
    # Create default category and brand
    default_category = create_default_category()
    default_brand = create_default_brand()
    
    print(f"Starting import of {len(products_data)} products...")
    
    imported_count = 0
    skipped_count = 0
    
    for product_data in products_data:
        try:
            # Extract basic product information
            name = clean_name(product_data.get('name', ''))
            description = clean_description(product_data.get('description', ''))
            price = clean_price(product_data.get('price'))
            stock = clean_stock(product_data.get('available_quantity'))
            images = product_data.get('images', [])
            
            # Skip products with invalid names
            if name == "Unnamed Product" and not description:
                print(f"Skipping invalid product (ID: {product_data.get('id', 'unknown')})")
                skipped_count += 1
                continue
            
            # Create unique slug
            base_slug = slugify(name)
            slug = base_slug
            counter = 1
            while Product.objects.filter(slug=slug).exists():
                slug = f"{base_slug}-{counter}"
                counter += 1
            
            # Create product
            product = Product.objects.create(
                name=name,
                description=description,
                price=price,
                category=default_category,
                brand=default_brand,
                stock=stock,
                slug=slug,
                is_active=True,
                is_featured=False,
                meta_keywords=', '.join(product_data.get('beauty_keywords', [])),
                meta_description=description[:160] if description else f"{name} - Beauty product"
            )
            
            print(f"Created product: {name} (ID: {product.id})")
            print(f"  - Price: {price}")
            print(f"  - Stock: {stock}")
            print(f"  - Images: {len(images)}")
            
            # Process images
            for index, image_url in enumerate(images):
                if image_url:  # Skip empty image URLs
                    download_and_save_image(image_url, product, index)
            
            imported_count += 1
            
            # Add a small delay to avoid overwhelming the system
            if imported_count % 10 == 0:
                print(f"Progress: {imported_count} products imported...")
                time.sleep(0.1)
                
        except Exception as e:
            print(f"Error importing product {product_data.get('name', 'unknown')}: {e}")
            skipped_count += 1
            continue
    
    print(f"\nImport completed!")
    print(f"Successfully imported: {imported_count} products")
    print(f"Skipped: {skipped_count} products")
    print(f"Total products in database: {Product.objects.count()}")

def main():
    """Main function"""
    # Path to the JSON file
    json_file_path = Path(__file__).parent.parent / 'dataExtraction' / 'final_products.json'
    
    if not json_file_path.exists():
        print(f"JSON file not found: {json_file_path}")
        print("Please ensure the final_products.json file exists in the dataExtraction directory")
        return
    
    print(f"Found JSON file: {json_file_path}")
    print(f"Current products in database: {Product.objects.count()}")
    
    # Ask for confirmation
    response = input("\nDo you want to proceed with importing products? (y/N): ")
    if response.lower() != 'y':
        print("Import cancelled.")
        return
    
    # Clear existing products if user wants to start fresh
    clear_response = input("Do you want to clear existing products first? (y/N): ")
    if clear_response.lower() == 'y':
        Product.objects.all().delete()
        ProductImage.objects.all().delete()
        print("Cleared existing products.")
    
    # Start import
    import_products_from_json(json_file_path)

if __name__ == "__main__":
    main() 