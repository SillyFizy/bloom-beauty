from django.core.management.base import BaseCommand
from django.db import transaction
from products.models import Product
from celebrities.models import CelebrityProductPromotion


class Command(BaseCommand):
    help = 'Sync product is_featured field based on celebrity promotions'

    def add_arguments(self, parser):
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Show what would be updated without making changes',
        )

    def handle(self, *args, **options):
        dry_run = options['dry_run']
        
        if dry_run:
            self.stdout.write(
                self.style.WARNING('DRY RUN MODE - No changes will be made')
            )
        
        # Get all products that should be featured (have featured celebrity promotions)
        featured_product_ids = CelebrityProductPromotion.objects.filter(
            is_featured=True
        ).values_list('product_id', flat=True).distinct()
        
        # Get all products that should NOT be featured
        non_featured_product_ids = Product.objects.exclude(
            id__in=featured_product_ids
        ).values_list('id', flat=True)
        
        # Count current state
        currently_featured = Product.objects.filter(is_featured=True).count()
        should_be_featured = len(featured_product_ids)
        should_not_be_featured = len(non_featured_product_ids)
        
        self.stdout.write(f"Current state:")
        self.stdout.write(f"  - Products currently marked as featured: {currently_featured}")
        self.stdout.write(f"  - Products that should be featured: {should_be_featured}")
        self.stdout.write(f"  - Products that should NOT be featured: {should_not_be_featured}")
        
        if not dry_run:
            with transaction.atomic():
                # Set is_featured=True for products with featured celebrity promotions
                updated_to_featured = Product.objects.filter(
                    id__in=featured_product_ids,
                    is_featured=False
                ).update(is_featured=True)
                
                # Set is_featured=False for products without featured celebrity promotions
                updated_to_not_featured = Product.objects.filter(
                    id__in=non_featured_product_ids,
                    is_featured=True
                ).update(is_featured=False)
                
                self.stdout.write(
                    self.style.SUCCESS(
                        f'Successfully updated {updated_to_featured} products to featured'
                    )
                )
                self.stdout.write(
                    self.style.SUCCESS(
                        f'Successfully updated {updated_to_not_featured} products to not featured'
                    )
                )
                
                # Show featured products
                if updated_to_featured > 0:
                    featured_products = Product.objects.filter(
                        id__in=featured_product_ids
                    ).values_list('name', flat=True)
                    
                    self.stdout.write(f"\nFeatured products:")
                    for product_name in featured_products:
                        self.stdout.write(f"  - {product_name}")
        else:
            # Dry run - show what would be changed
            products_to_feature = Product.objects.filter(
                id__in=featured_product_ids,
                is_featured=False
            ).values_list('name', flat=True)
            
            products_to_unfeature = Product.objects.filter(
                id__in=non_featured_product_ids,
                is_featured=True
            ).values_list('name', flat=True)
            
            if products_to_feature:
                self.stdout.write(f"\nWould mark as FEATURED:")
                for product_name in products_to_feature:
                    self.stdout.write(f"  - {product_name}")
            
            if products_to_unfeature:
                self.stdout.write(f"\nWould mark as NOT FEATURED:")
                for product_name in products_to_unfeature:
                    self.stdout.write(f"  - {product_name}")
            
            if not products_to_feature and not products_to_unfeature:
                self.stdout.write(
                    self.style.SUCCESS("No changes needed - all products are correctly synced")
                ) 