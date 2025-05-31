# cart/models.py
from django.db import models
from django.conf import settings
from products.models import Product, ProductVariant
from django.db.models import Sum, F, ExpressionWrapper, DecimalField

class Cart(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='carts', null=True, blank=True)
    session_key = models.CharField(max_length=255, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    merged = models.BooleanField(default=False)  # Flag to indicate if cart has been merged 
    
    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=['user'], 
                condition=models.Q(user__isnull=False),
                name='unique_user_cart'
            ),
            models.UniqueConstraint(
                fields=['session_key'],
                condition=models.Q(session_key__isnull=False, user__isnull=True, merged=False),
                name='unique_session_cart'
            )
        ]
    
    def __str__(self):
        if self.user:
            return f"Cart {self.id} - {self.user.username}"
        return f"Cart {self.id} - Anonymous ({self.session_key})"
    
    @property
    def total(self):
        """Calculate total cart value"""
        # Get product items total
        product_total = self.items.annotate(
            item_total=ExpressionWrapper(
                F('product__price') * F('quantity'),
                output_field=DecimalField()
            )
        ).aggregate(total=Sum('item_total'))['total'] or 0
        
        # Get variant items total
        variant_total = self.variant_items.annotate(
            item_total=ExpressionWrapper(
                (F('variant__product__price') + F('variant__price_adjustment')) * F('quantity'),
                output_field=DecimalField()
            )
        ).aggregate(total=Sum('item_total'))['total'] or 0
        
        return product_total + variant_total
    
    @property
    def item_count(self):
        """Count total number of items in cart"""
        product_count = self.items.aggregate(total=Sum('quantity'))['total'] or 0
        variant_count = self.variant_items.aggregate(total=Sum('quantity'))['total'] or 0
        return product_count + variant_count
    
    def clear(self):
        """Remove all items from cart"""
        self.items.all().delete()
        self.variant_items.all().delete()

    def merge_with(self, session_cart):
        """Merge a session-based cart into this user cart"""
        if not session_cart:
            return
        
        # Merge regular product items
        for session_item in session_cart.items.all():
            existing_item = self.items.filter(product=session_item.product).first()
            if existing_item:
                existing_item.quantity += session_item.quantity
                existing_item.save()
            else:
                # Create a new cart item copying the session item
                session_item.pk = None  # Create a new item
                session_item.cart = self
                session_item.save()
        
        # Merge variant items
        for session_variant_item in session_cart.variant_items.all():
            existing_variant_item = self.variant_items.filter(variant=session_variant_item.variant).first()
            if existing_variant_item:
                existing_variant_item.quantity += session_variant_item.quantity
                existing_variant_item.save()
            else:
                # Create a new cart variant item copying the session item
                session_variant_item.pk = None  # Create a new item
                session_variant_item.cart = self
                session_variant_item.save()
        
        # Mark the session cart as merged
        session_cart.merged = True
        session_cart.save()

class CartItem(models.Model):
    cart = models.ForeignKey(Cart, on_delete=models.CASCADE, related_name='items')
    product = models.ForeignKey(Product, on_delete=models.CASCADE)
    quantity = models.PositiveIntegerField(default=1)
    added_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ['cart', 'product']
    
    def __str__(self):
        return f"{self.quantity} x {self.product.name}"
    
    @property
    def subtotal(self):
        return self.product.price * self.quantity

class CartVariantItem(models.Model):
    cart = models.ForeignKey(Cart, on_delete=models.CASCADE, related_name='variant_items')
    variant = models.ForeignKey(ProductVariant, on_delete=models.CASCADE)
    quantity = models.PositiveIntegerField(default=1)
    added_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ['cart', 'variant']
    
    def __str__(self):
        return f"{self.quantity} x {self.variant.product.name} - {self.variant.name}"
    
    @property
    def subtotal(self):
        return (self.variant.product.price + self.variant.price_adjustment) * self.quantity