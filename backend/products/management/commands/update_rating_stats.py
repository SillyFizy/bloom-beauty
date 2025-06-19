from django.core.management.base import BaseCommand
from django.db import transaction
from products.models import Product, ProductRating


class Command(BaseCommand):
    help = 'Recalculate all product rating statistics'

    def add_arguments(self, parser):
        parser.add_argument(
            '--recalculate-all',
            action='store_true',
            help='Recalculate all product ratings from scratch',
        )

    def handle(self, *args, **options):
        self.stdout.write(self.style.SUCCESS('Starting rating statistics update...'))

        with transaction.atomic():
            # Update product ratings
            products_updated = 0
            products_with_reviews = Product.objects.filter(reviews__isnull=False).distinct()
            
            self.stdout.write(f'Updating ratings for {products_with_reviews.count()} products...')
            
            for product in products_with_reviews:
                rating_stats = product.get_or_create_rating_stats()
                
                if options['recalculate_all']:
                    # Force recalculation
                    rating_stats.update_stats()
                else:
                    # Only update if stats are outdated or missing
                    if rating_stats.total_reviews == 0 or not rating_stats.last_calculated:
                        rating_stats.update_stats()
                
                products_updated += 1
                
                if products_updated % 100 == 0:
                    self.stdout.write(f'Updated {products_updated} products...')

            self.stdout.write(
                self.style.SUCCESS(
                    f'Successfully updated rating statistics for {products_updated} products!'
                )
            )

        # Display some example results
        self.stdout.write('\n--- Sample Product Ratings ---')
        sample_products = Product.objects.filter(
            rating_stats__total_reviews__gt=0
        ).order_by('-rating_stats__total_reviews')[:5]
        
        for product in sample_products:
            stats = product.rating_stats
            self.stdout.write(
                f'{product.name[:50]}... | '
                f'Reviews: {stats.total_reviews} | '
                f'Average: {stats.average_rating}'
            ) 