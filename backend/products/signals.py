# products/signals.py - Simplified Review Signals
from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from .models import Review, ProductRating


@receiver(post_save, sender=Review)
def update_product_rating_on_review_save(sender, instance, created, **kwargs):
    """Update product rating stats when a review is created or updated"""
    # Get or create rating stats for the product
    rating_stats, _ = ProductRating.objects.get_or_create(product=instance.product)
    rating_stats.update_stats()


@receiver(post_delete, sender=Review)
def update_product_rating_on_review_delete(sender, instance, **kwargs):
    """Update product rating stats when a review is deleted"""
    try:
        rating_stats = ProductRating.objects.get(product=instance.product)
        rating_stats.update_stats()
    except ProductRating.DoesNotExist:
        # Rating stats don't exist, nothing to update
        pass 