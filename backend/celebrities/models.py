from django.db import models
from django.core.validators import URLValidator


class Celebrity(models.Model):
    # Basic Information
    first_name = models.CharField(max_length=100)
    last_name = models.CharField(max_length=100)
    image = models.ImageField(upload_to='celebrities/', blank=True, null=True)
    bio = models.TextField(blank=True, null=True, help_text="Celebrity biography/description")
    
    # Social Media Links
    instagram_url = models.URLField(
        blank=True, 
        null=True, 
        validators=[URLValidator()],
        help_text="Instagram profile URL"
    )
    facebook_url = models.URLField(
        blank=True, 
        null=True, 
        validators=[URLValidator()],
        help_text="Facebook profile URL"
    )
    snapchat_url = models.URLField(
        blank=True, 
        null=True, 
        validators=[URLValidator()],
        help_text="Snapchat profile URL"
    )
    
    # Status and metadata
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    # Product relationships will be defined through separate models below
    
    class Meta:
        verbose_name_plural = 'Celebrities'
        ordering = ['first_name', 'last_name']
        indexes = [
            models.Index(fields=['first_name', 'last_name']),
            models.Index(fields=['is_active']),
        ]
    
    def __str__(self):
        return f"{self.first_name} {self.last_name}"
    
    @property
    def full_name(self):
        return f"{self.first_name} {self.last_name}"
    

    
    @property
    def social_media_links(self):
        """Returns a dictionary of social media links"""
        links = {}
        if self.instagram_url:
            links['instagram'] = self.instagram_url
        if self.facebook_url:
            links['facebook'] = self.facebook_url
        if self.snapchat_url:
            links['snapchat'] = self.snapchat_url
        return links


class CelebrityProductPromotion(models.Model):
    """
    Many-to-many relationship between celebrities and products they promote.
    A product can be promoted by multiple celebrities, and a celebrity can promote multiple products.
    """
    celebrity = models.ForeignKey(
        Celebrity, 
        on_delete=models.CASCADE, 
        related_name='product_promotions'
    )
    product = models.ForeignKey(
        'products.Product', 
        on_delete=models.CASCADE, 
        related_name='celebrity_promotions'
    )
    testimonial = models.TextField(
        blank=True, 
        null=True,
        help_text="Celebrity's testimonial about this product"
    )
    promotion_type = models.CharField(
        max_length=50,
        choices=[
            ('general', 'General Promotion'),
            ('morning_routine', 'Morning Routine'),
            ('evening_routine', 'Evening Routine'),
            ('special_pick', 'Special Pick'),
        ],
        default='general'
    )
    is_featured = models.BooleanField(
        default=False,
        help_text="Is this a featured promotion?"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ('celebrity', 'product', 'promotion_type')
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['celebrity', 'promotion_type']),
            models.Index(fields=['product', 'is_featured']),
        ]
    
    def __str__(self):
        return f"{self.celebrity.full_name} promotes {self.product.name} ({self.promotion_type})"


class CelebrityMorningRoutine(models.Model):
    """
    Products that celebrities use in their morning routine.
    This is a separate model to allow for ordering and additional metadata.
    """
    celebrity = models.ForeignKey(
        Celebrity, 
        on_delete=models.CASCADE, 
        related_name='morning_routine_items'
    )
    product = models.ForeignKey(
        'products.Product', 
        on_delete=models.CASCADE, 
        related_name='celebrity_morning_routines'
    )
    order = models.PositiveIntegerField(
        default=1,
        help_text="Order in the morning routine (1, 2, 3, etc.)"
    )
    description = models.TextField(
        blank=True, 
        null=True,
        help_text="How the celebrity uses this product in their morning routine"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ('celebrity', 'product')
        ordering = ['celebrity', 'order']
        indexes = [
            models.Index(fields=['celebrity', 'order']),
        ]
    
    def __str__(self):
        return f"{self.celebrity.full_name} - Morning Routine Step {self.order}: {self.product.name}"


class CelebrityEveningRoutine(models.Model):
    """
    Products that celebrities use in their evening routine.
    This is a separate model to allow for ordering and additional metadata.
    """
    celebrity = models.ForeignKey(
        Celebrity, 
        on_delete=models.CASCADE, 
        related_name='evening_routine_items'
    )
    product = models.ForeignKey(
        'products.Product', 
        on_delete=models.CASCADE, 
        related_name='celebrity_evening_routines'
    )
    order = models.PositiveIntegerField(
        default=1,
        help_text="Order in the evening routine (1, 2, 3, etc.)"
    )
    description = models.TextField(
        blank=True, 
        null=True,
        help_text="How the celebrity uses this product in their evening routine"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ('celebrity', 'product')
        ordering = ['celebrity', 'order']
        indexes = [
            models.Index(fields=['celebrity', 'order']),
        ]
    
    def __str__(self):
        return f"{self.celebrity.full_name} - Evening Routine Step {self.order}: {self.product.name}" 