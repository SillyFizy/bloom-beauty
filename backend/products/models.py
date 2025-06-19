# products/models.py
from django.db import models
from django.utils.text import slugify
from django.core.validators import MinValueValidator, MaxValueValidator
from django.db.models import Avg, Count
import math
from datetime import datetime, timedelta

class Category(models.Model):
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True, null=True)
    parent = models.ForeignKey('self', on_delete=models.SET_NULL, null=True, blank=True, related_name='subcategories')
    image = models.ImageField(upload_to='categories/', blank=True, null=True)
    slug = models.SlugField(max_length=100, unique=True, null=True, blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name_plural = 'Categories'
        ordering = ['name']
    
    def __str__(self):
        return self.name
    
    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = slugify(self.name)
        super().save(*args, **kwargs)

class Brand(models.Model):
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True, null=True)
    logo = models.ImageField(upload_to='brands/', blank=True, null=True)
    slug = models.SlugField(max_length=100, unique=True, null=True, blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['name']
    
    def __str__(self):
        return self.name
    
    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = slugify(self.name)
        super().save(*args, **kwargs)

class ProductAttribute(models.Model):
    name = models.CharField(max_length=50)
    
    def __str__(self):
        return self.name

class ProductAttributeValue(models.Model):
    attribute = models.ForeignKey(ProductAttribute, on_delete=models.CASCADE, related_name='values')
    value = models.CharField(max_length=100)
    
    def __str__(self):
        return f"{self.attribute.name}: {self.value}"

class Product(models.Model):
    name = models.CharField(max_length=255)
    description = models.TextField()
    price = models.DecimalField(max_digits=10, decimal_places=2)
    sale_price = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    category = models.ForeignKey(Category, on_delete=models.CASCADE, related_name='products')
    brand = models.ForeignKey(Brand, on_delete=models.SET_NULL, null=True, blank=True, related_name='products')
    attributes = models.ManyToManyField(ProductAttributeValue, blank=True, related_name='products')
    featured_image = models.ImageField(upload_to='products/', blank=True, null=True)
    stock = models.PositiveIntegerField(default=0)
    sku = models.CharField(max_length=100, unique=True, null=True, blank=True)
    slug = models.SlugField(max_length=255, unique=True, null=True, blank=True)
    is_active = models.BooleanField(default=True)
    is_featured = models.BooleanField(default=False)
    weight = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    dimensions = models.CharField(max_length=100, null=True, blank=True)
    meta_keywords = models.CharField(max_length=255, null=True, blank=True, help_text="Comma separated keywords for SEO")
    meta_description = models.TextField(null=True, blank=True, help_text="Meta description for SEO")
    low_stock_threshold = models.PositiveIntegerField(default=10)
    beauty_points = models.PositiveIntegerField(default=0, help_text="Beauty points earned when purchasing this product")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return self.name
    
    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = slugify(self.name)
        super().save(*args, **kwargs)
    
    @property
    def is_on_sale(self):
        return bool(self.sale_price is not None and self.sale_price < self.price)
    
    @property
    def discount_percentage(self):
        if self.is_on_sale:
            return int(((self.price - self.sale_price) / self.price) * 100)
        return 0
    
    @property
    def is_low_stock(self):
        return self.stock <= self.low_stock_threshold
    
    def get_absolute_url(self):
        return f"/products/{self.slug}/"
    
    @property
    def rating(self):
        """Get the average rating for this product"""
        try:
            return self.rating_stats.average_rating
        except ProductRating.DoesNotExist:
            from decimal import Decimal
            return Decimal('0.00')
    
    @property 
    def review_count(self):
        """Get the total number of approved reviews"""
        try:
            return self.rating_stats.total_reviews
        except ProductRating.DoesNotExist:
            return 0
    
    @property
    def has_reviews(self):
        """Check if product has any reviews"""
        return self.review_count > 0
    
    def get_or_create_rating_stats(self):
        """Get or create rating stats for this product"""
        rating_stats, created = ProductRating.objects.get_or_create(product=self)
        if created or rating_stats.total_reviews == 0:
            rating_stats.update_stats()
        return rating_stats

class ProductImage(models.Model):
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='images')
    image = models.ImageField(upload_to='products/')
    alt_text = models.CharField(max_length=255, null=True, blank=True)
    is_feature = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['created_at']
    
    def __str__(self):
        return f"Image for {self.product.name}"

class ProductVariant(models.Model):
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='variants')
    name = models.CharField(max_length=255)
    sku = models.CharField(max_length=100, unique=True)
    price_adjustment = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    stock = models.PositiveIntegerField(default=0)
    attributes = models.ManyToManyField(ProductAttributeValue, related_name='variants')
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.product.name} - {self.name}"
    
    @property
    def price(self):
        return self.product.price + self.price_adjustment

class InventoryLog(models.Model):
    ADJUSTMENT_TYPES = (
        ('stock_in', 'Stock In'),
        ('stock_out', 'Stock Out'),
        ('adjustment', 'Adjustment'),
        ('returned', 'Returned'),
    )
    
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='inventory_logs')
    variant = models.ForeignKey(ProductVariant, on_delete=models.CASCADE, null=True, blank=True, related_name='inventory_logs')
    quantity = models.IntegerField()
    adjustment_type = models.CharField(max_length=20, choices=ADJUSTMENT_TYPES)
    reference = models.CharField(max_length=255, null=True, blank=True, help_text="Reference number or reason for adjustment")
    created_at = models.DateTimeField(auto_now_add=True)
    user = models.ForeignKey('users.User', on_delete=models.SET_NULL, null=True, blank=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.adjustment_type} - {self.quantity} - {self.product.name}"

class Review(models.Model):
    """User reviews for products - Clean and Simple"""
    
    # Core fields
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='reviews')
    user = models.ForeignKey('users.User', on_delete=models.CASCADE, related_name='reviews')
    rating = models.PositiveIntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(5)],
        help_text="Rating from 1 to 5 stars"
    )
    
    # Review content
    title = models.CharField(max_length=255, blank=True, null=True)
    comment = models.TextField(blank=True, null=True)
    
    # Status fields
    is_verified_purchase = models.BooleanField(default=False, help_text="User purchased this product")
    is_approved = models.BooleanField(default=True, help_text="Review is approved for display")
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ('product', 'user')  # One review per user per product
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['product', '-created_at']),
            models.Index(fields=['user', '-created_at']),
            models.Index(fields=['is_approved', '-created_at']),
            models.Index(fields=['rating', '-created_at']),
        ]
    
    def __str__(self):
        return f"{self.user.username} - {self.product.name} - {self.rating} stars"



class ProductRating(models.Model):
    """Aggregated rating statistics for products - Simple and Clean"""
    
    product = models.OneToOneField(Product, on_delete=models.CASCADE, related_name='rating_stats')
    
    # Basic statistics
    total_reviews = models.PositiveIntegerField(default=0)
    average_rating = models.DecimalField(max_digits=3, decimal_places=2, default=0.00)
    
    # Rating distribution (for showing star breakdown)
    rating_1_count = models.PositiveIntegerField(default=0)
    rating_2_count = models.PositiveIntegerField(default=0) 
    rating_3_count = models.PositiveIntegerField(default=0)
    rating_4_count = models.PositiveIntegerField(default=0)
    rating_5_count = models.PositiveIntegerField(default=0)
    
    # Metadata
    last_calculated = models.DateTimeField(auto_now=True)
    
    class Meta:
        indexes = [
            models.Index(fields=['-average_rating']),
            models.Index(fields=['-total_reviews']),
        ]
    
    def __str__(self):
        return f"{self.product.name} - {self.average_rating} ({self.total_reviews} reviews)"
    
    def update_stats(self):
        """Update rating statistics from approved reviews"""
        from decimal import Decimal
        
        approved_reviews = self.product.reviews.filter(is_approved=True)
        
        # Update total count
        self.total_reviews = approved_reviews.count()
        
        if self.total_reviews > 0:
            # Calculate average rating
            avg_result = approved_reviews.aggregate(avg=Avg('rating'))
            self.average_rating = Decimal(str(avg_result['avg'] or 0))
            
            # Update rating distribution
            for i in range(1, 6):
                count = approved_reviews.filter(rating=i).count()
                setattr(self, f'rating_{i}_count', count)
        else:
            # No reviews
            self.average_rating = Decimal('0.00')
            for i in range(1, 6):
                setattr(self, f'rating_{i}_count', 0)
        
        self.save()
    
    @property
    def rating_distribution(self):
        """Get rating distribution as a list"""
        return [
            self.rating_1_count,
            self.rating_2_count, 
            self.rating_3_count,
            self.rating_4_count,
            self.rating_5_count
        ]
    
    @property
    def rating_percentages(self):
        """Get rating distribution as percentages"""
        if self.total_reviews == 0:
            return [0, 0, 0, 0, 0]
        
        return [
            round((count / self.total_reviews) * 100, 1) 
            for count in self.rating_distribution
        ]

