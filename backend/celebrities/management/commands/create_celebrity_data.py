from django.core.management.base import BaseCommand
from django.db import transaction
from celebrities.models import Celebrity, CelebrityProductPromotion, CelebrityMorningRoutine, CelebrityEveningRoutine
from products.models import Product
import random


class Command(BaseCommand):
    help = 'Create sample celebrity data with product promotions'

    def add_arguments(self, parser):
        parser.add_argument(
            '--clear',
            action='store_true',
            help='Clear existing celebrity data before creating new ones'
        )

    def handle(self, *args, **options):
        if options['clear']:
            self.stdout.write('Clearing existing celebrity data...')
            Celebrity.objects.all().delete()

        # Celebrity data
        celebrities_data = [
            {
                'first_name': 'Emma',
                'last_name': 'Watson',
                'bio': 'Actress and activist known for her natural beauty routines and sustainable living.',
                'instagram_url': 'https://instagram.com/emmawatson',
                'facebook_url': 'https://facebook.com/emmawatson',
                'snapchat_url': ''
            },
            {
                'first_name': 'Zendaya',
                'last_name': '',
                'bio': 'Multi-talented actress and singer with a passion for skincare and beauty.',
                'instagram_url': 'https://instagram.com/zendaya',
                'facebook_url': '',
                'snapchat_url': 'https://snapchat.com/add/zendaya'
            },
            {
                'first_name': 'Priyanka',
                'last_name': 'Chopra',
                'bio': 'Global icon and beauty entrepreneur promoting inclusive beauty standards.',
                'instagram_url': 'https://instagram.com/priyankachopra',
                'facebook_url': 'https://facebook.com/priyankachopra',
                'snapchat_url': ''
            },
            {
                'first_name': 'Lupita',
                'last_name': "Nyong'o",
                'bio': 'Academy Award-winning actress and advocate for natural beauty.',
                'instagram_url': 'https://instagram.com/lupitanyongo',
                'facebook_url': '',
                'snapchat_url': ''
            },
            {
                'first_name': 'Gal',
                'last_name': 'Gadot',
                'bio': 'Wonder Woman actress known for her radiant skin and simple beauty routine.',
                'instagram_url': 'https://instagram.com/gal_gadot',
                'facebook_url': 'https://facebook.com/galgadot',
                'snapchat_url': ''
            }
        ]

        # Testimonials for products
        testimonials = [
            "This product has completely transformed my skin routine!",
            "I can't imagine my day without this amazing product.",
            "Perfect for my sensitive skin - gentle yet effective.",
            "This gives me that natural glow I've always wanted.",
            "A must-have in every beauty lover's collection.",
            "I've been using this for months and the results are incredible.",
            "Finally found a product that works with my busy lifestyle.",
            "This is the secret to my radiant complexion.",
            "Love how this makes my skin feel so smooth and hydrated.",
            "Perfect for both day and night routines."
        ]

        # Get available products
        products = list(Product.objects.filter(is_active=True))
        
        if not products:
            self.stdout.write(self.style.ERROR('No products found in database. Please create some products first.'))
            return

        with transaction.atomic():
            created_celebrities = []
            
            # Create celebrities
            for celeb_data in celebrities_data:
                celebrity, created = Celebrity.objects.get_or_create(
                    first_name=celeb_data['first_name'],
                    last_name=celeb_data['last_name'],
                    defaults=celeb_data
                )
                
                if created:
                    self.stdout.write(f'Created celebrity: {celebrity.full_name}')
                else:
                    self.stdout.write(f'Celebrity already exists: {celebrity.full_name}')
                
                created_celebrities.append(celebrity)

            # Track which products are already promoted
            promoted_products = set()
            
            # Assign products to celebrities (each product to only one celebrity)
            for celebrity in created_celebrities:
                # Get available products not yet promoted
                available_products = [p for p in products if p.id not in promoted_products]
                
                if not available_products:
                    self.stdout.write(f'No more products available for {celebrity.full_name}')
                    continue
                
                # Assign 3-5 products to each celebrity
                num_products = min(random.randint(3, 5), len(available_products))
                selected_products = random.sample(available_products, num_products)
                
                for i, product in enumerate(selected_products):
                    # Create product promotion
                    promotion = CelebrityProductPromotion.objects.create(
                        celebrity=celebrity,
                        product=product,
                        testimonial=random.choice(testimonials),
                        promotion_type=random.choice(['general', 'special_pick']),
                        is_featured=(i == 0)  # Make first product featured
                    )
                    
                    promoted_products.add(product.id)
                    self.stdout.write(f'  - {celebrity.full_name} promotes {product.name}')
                
                # Create morning routine (2-3 products from their promoted products)
                morning_products = random.sample(selected_products, min(3, len(selected_products)))
                for order, product in enumerate(morning_products, 1):
                    CelebrityMorningRoutine.objects.create(
                        celebrity=celebrity,
                        product=product,
                        order=order,
                        description=f"Step {order} in {celebrity.first_name}'s morning skincare routine"
                    )
                
                # Create evening routine (2-3 products from their promoted products)
                evening_products = random.sample(selected_products, min(3, len(selected_products)))
                for order, product in enumerate(evening_products, 1):
                    CelebrityEveningRoutine.objects.create(
                        celebrity=celebrity,
                        product=product,
                        order=order,
                        description=f"Step {order} in {celebrity.first_name}'s evening skincare routine"
                    )
                
                self.stdout.write(f'Created routines for {celebrity.full_name}')

        # Print summary
        self.stdout.write('\n' + '='*50)
        self.stdout.write(self.style.SUCCESS('CELEBRITY DATA CREATION COMPLETE'))
        self.stdout.write('='*50)
        
        total_celebrities = Celebrity.objects.count()
        total_promotions = CelebrityProductPromotion.objects.count()
        total_morning_items = CelebrityMorningRoutine.objects.count()
        total_evening_items = CelebrityEveningRoutine.objects.count()
        
        self.stdout.write(f'Total Celebrities: {total_celebrities}')
        self.stdout.write(f'Total Product Promotions: {total_promotions}')
        self.stdout.write(f'Total Morning Routine Items: {total_morning_items}')
        self.stdout.write(f'Total Evening Routine Items: {total_evening_items}')
        
        # Show celebrity summary
        self.stdout.write('\nCelebrity Summary:')
        for celebrity in Celebrity.objects.all():
            promotions_count = celebrity.product_promotions.count()
            morning_count = celebrity.morning_routine_items.count()
            evening_count = celebrity.evening_routine_items.count()
            featured_count = celebrity.product_promotions.filter(is_featured=True).count()
            
            self.stdout.write(
                f'{celebrity.full_name}: {promotions_count} promotions '
                f'({featured_count} featured), {morning_count} morning items, '
                f'{evening_count} evening items'
            ) 