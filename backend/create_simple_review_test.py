# create_simple_review_test.py - Clean Review System Demo
import os
import sys
import django
from django.conf import settings

# Add the project root to Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'joulina_backend.settings')
django.setup()

from products.models import Product, Review, ProductRating
from users.models import User
from django.contrib.auth.hashers import make_password
import random
from decimal import Decimal


def create_simple_test_data():
    """Create simple test reviews to demonstrate the clean rating system"""
    print("🌟 CLEAN REVIEW & RATING SYSTEM DEMO")
    print("="*50)
    
    # Get or create a test user
    user, created = User.objects.get_or_create(
        username="test_reviewer",
        defaults={
            'email': 'test@example.com',
            'first_name': 'Test',
            'last_name': 'Reviewer',
            'password': make_password('testpass123')
        }
    )
    if created:
        print(f"✅ Created test user: {user.username}")
    
    # Get first few products
    products = Product.objects.filter(is_active=True)[:3]
    
    if not products:
        print("❌ No active products found. Please create some products first.")
        return
    
    print(f"📦 Found {products.count()} products to add reviews to")
    
    # Create different review scenarios
    review_scenarios = [
        {
            'product': products[0],
            'ratings': [5, 5, 4, 5, 4],
            'titles': ['Amazing product!', 'Love it!', 'Great quality', 'Highly recommend', 'Good value']
        },
        {
            'product': products[1],
            'ratings': [3, 3, 4, 2, 3],
            'titles': ['Okay product', 'Average', 'Not bad', 'Could be better', 'It\'s fine']
        },
        {
            'product': products[2] if len(products) > 2 else products[0],
            'ratings': [1, 2],
            'titles': ['Disappointed', 'Not good']
        }
    ]
    
    print("\n🔄 Creating test reviews...")
    
    for i, scenario in enumerate(review_scenarios):
        product = scenario['product']
        ratings = scenario['ratings']
        titles = scenario['titles']
        
        print(f"\n📝 Adding reviews for: {product.name}")
        
        # Clear existing reviews for this product from our test user
        Review.objects.filter(product=product, user=user).delete()
        
        # Create new review (only one per user per product due to unique constraint)
        if ratings:
            review = Review.objects.create(
                product=product,
                user=user,
                rating=ratings[0],
                title=titles[0],
                comment=f"This is a {ratings[0]}-star review for {product.name}. {titles[0]}",
                is_verified_purchase=random.choice([True, False]),
                is_approved=True
            )
            print(f"   ⭐ Added review: {review.rating} stars - {review.title}")
            
            # If we want multiple reviews, we need different users
            if len(ratings) > 1:
                for j, (rating, title) in enumerate(zip(ratings[1:], titles[1:]), 1):
                    # Create additional test users for multiple reviews
                    extra_user, _ = User.objects.get_or_create(
                        username=f"test_reviewer_{i}_{j}",
                        defaults={
                            'email': f'test{i}{j}@example.com',
                            'first_name': f'Test{i}',
                            'last_name': f'Reviewer{j}',
                            'password': make_password('testpass123')
                        }
                    )
                    
                    Review.objects.create(
                        product=product,
                        user=extra_user,
                        rating=rating,
                        title=title,
                        comment=f"This is a {rating}-star review for {product.name}. {title}",
                        is_verified_purchase=random.choice([True, False]),
                        is_approved=True
                    )
                    print(f"   ⭐ Added review: {rating} stars - {title}")
    
    print("\n🧮 Calculating rating statistics...")
    
    # Update all product ratings
    for product in products:
        rating_stats = product.get_or_create_rating_stats()
        print(f"   ✅ Updated ratings for {product.name}")
    
    print("\n📊 RATING RESULTS")
    print("="*60)
    print(f"{'Product Name':<30} {'Reviews':<8} {'Rating':<8} {'Distribution'}")
    print("-" * 60)
    
    for product in products:
        if hasattr(product, 'rating_stats'):
            stats = product.rating_stats
            # Create a simple distribution string
            dist = [stats.rating_1_count, stats.rating_2_count, stats.rating_3_count, 
                   stats.rating_4_count, stats.rating_5_count]
            dist_str = " ".join([f"{i+1}⭐:{count}" for i, count in enumerate(dist) if count > 0])
            
            print(f"{product.name[:27]+'...' if len(product.name) > 30 else product.name:<30} "
                  f"{stats.total_reviews:<8} {stats.average_rating:<8} {dist_str}")
        else:
            print(f"{product.name[:27]+'...' if len(product.name) > 30 else product.name:<30} "
                  f"{'0':<8} {'0.00':<8} No reviews")
    
    print("\n✨ SYSTEM FEATURES DEMONSTRATED:")
    print("="*40)
    print("✅ Reviews Table - Individual user reviews with ratings 1-5")
    print("✅ Product Ratings Table - Aggregated statistics per product")
    print("✅ Connected to Products - Easy access via product.rating and product.review_count")
    print("✅ No Voting System - Clean and simple (as requested)")
    print("✅ Auto-calculated - Ratings update automatically when reviews change")
    print("✅ Star Distribution - Shows breakdown of 1-5 star ratings")
    print("✅ Verified Purchases - Track which reviews are from actual buyers")
    print("✅ Admin Approval - Reviews can be approved/disapproved")
    
    print("\n🎯 USAGE EXAMPLES:")
    print("="*30)
    product = products[0]
    print(f"📦 Product: {product.name}")
    print(f"⭐ Rating: {product.rating}")
    print(f"📝 Review Count: {product.review_count}")
    print(f"✅ Has Reviews: {product.has_reviews}")
    
    if hasattr(product, 'rating_stats'):
        stats = product.rating_stats
        print(f"📊 Rating Distribution: {stats.rating_distribution}")
        print(f"📈 Rating Percentages: {stats.rating_percentages}")
    
    print("\n🚀 Ready for Backend API Integration!")


if __name__ == "__main__":
    create_simple_test_data() 