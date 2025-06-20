from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from django.db import transaction
from .models import CelebrityProductPromotion


@receiver(post_save, sender=CelebrityProductPromotion)
def update_product_featured_status_on_save(sender, instance, created, **kwargs):
    """
    Update product is_featured status when a celebrity promotion is created or updated
    """
    update_product_featured_status(instance.product)


@receiver(post_delete, sender=CelebrityProductPromotion)
def update_product_featured_status_on_delete(sender, instance, **kwargs):
    """
    Update product is_featured status when a celebrity promotion is deleted
    """
    update_product_featured_status(instance.product)


def update_product_featured_status(product):
    """
    Update the is_featured status of a product based on its celebrity promotions
    """
    # Check if the product has any featured celebrity promotions
    has_featured_promotions = CelebrityProductPromotion.objects.filter(
        product=product,
        is_featured=True
    ).exists()
    
    # Update the product's is_featured status if it's different
    if product.is_featured != has_featured_promotions:
        with transaction.atomic():
            product.is_featured = has_featured_promotions
            product.save(update_fields=['is_featured'])
            
            print(f"Updated product '{product.name}' is_featured to {has_featured_promotions}") 